-- Mock LuCI environment for testing singbox.lua controller

-- Mock nixio.fs
nixio = { fs = {} }
local MOCK_FS_ROOT = "/etc" -- Using a real path in the sandbox to simulate /etc
local MOCK_CONFIG_DIR = MOCK_FS_ROOT .. "/singbox/configs/"
local MOCK_ACTIVE_CONFIG_SYMLINK = MOCK_FS_ROOT .. "/singbox/config.json"

function nixio.fs.stat(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return { type = "file" }
    end
    local d = io.open(path, "r")
    if d then
        d:close()
        return { type = "directory" }
    end
    -- Fallback to actual stat for sandbox environment
    local success, result = pcall(function() return os.execute("test -e " .. path) end)
    if success and result == 0 then
      local is_dir = os.execute("test -d " .. path) == 0
      local is_file = os.execute("test -f " .. path) == 0
      if is_dir then return { type = "directory" } end
      if is_file then return { type = "file" } end
    end
    return nil
end

function nixio.fs.dir(path)
    local success, output = pcall(function()
        local handle = io.popen("ls -1 " .. path)
        local result = handle:read("*all")
        handle:close()
        return result
    end)
    if success and output then
        local entries = {}
        for entry in output:gmatch("[^\n]+") do
            table.insert(entries, entry)
        end
        return function(t, i)
            i = i + 1
            local v = entries[i]
            return i, v
        end, nil, 0
    end
    return function() end -- Return empty iterator on error
end

function nixio.fs.is_file(path)
    return nixio.fs.stat(path) and nixio.fs.stat(path).type == "file"
end

function nixio.fs.join(...)
    local args = { ... }
    return table.concat(args, "/")
end

function nixio.fs.access(path)
    return nixio.fs.stat(path) ~= nil
end

function nixio.fs.readlink(path)
    local f = io.open(path, "r") -- In simulation, we store symlink target as content
    if f then
        local target = f:read("*all")
        f:close()
        return target
    end
    return nil
end

function nixio.fs.symlink(target, link_path)
    local f = io.open(link_path, "w") -- In simulation, write target to link_path
    if f then
        f:write(target)
        f:close()
        return true
    end
    return false
end

function nixio.fs.unlink(path)
    return os.remove(path)
end

function nixio.fs.mkdir(path)
    return os.execute("mkdir -p " .. path) == 0
end

-- Mock luci.http
luci = { http = {}, dispatcher = {}, template = {}, sys = {} }
luci.http.mock_form_values = {}
luci.http.mock_form_files = {}

function luci.http.form_value(key)
    return luci.http.mock_form_values[key]
end

function luci.http.form_file(key)
    return luci.http.mock_form_files[key]
end

function luci.http.redirect(url)
    print("HTTP Redirect to: " .. url)
end

function luci.http.header(key, value)
    print("HTTP Header: " .. key .. ": " .. value)
end

-- Mock luci.dispatcher
function luci.dispatcher.build_url(...)
    local args = { ... }
    return "http://localhost/cgi-bin/luci/" .. table.concat(args, "/")
end

-- Mock luci.template
function luci.template.render(template_name, data)
    print("--- Rendering Template: " .. template_name .. " ---")
    if template_name == "singbox/config_manager" then
        print("Config Files: ")
        for _, file in ipairs(data.config_files) do
            print("  - " .. file .. (file == data.active_config and " (Active)" or ""))
        end
        print("Active Config: " .. tostring(data.active_config))
    end
    print("---------------------------------------")
end

-- Mock luci.sys
function luci.sys.call(cmd)
    print("System Call: " .. cmd)
    return 0 -- Simulate success
end

function luci.sys.write_file(path)
    print("Writing file content to HTTP response: " .. path)
    -- In a real scenario, this would stream the file content.
    -- Here, we just acknowledge.
end

-- Load the actual singbox controller
dofile("app/luci-app-singbox/files/usr/lib/lua/luci/controller/singbox.lua")

-- Now, define test cases
print("\n--- Test Case 1: Initial load (do_config_manager) ---")
do_config_manager()

print("\n--- Test Case 2: Upload a new config ---")
luci.http.mock_form_files.singbox_config_file = { name = "new-config.json", read_all = function() return '{ "test": "upload" }' end }
luci.http.mock_form_values.filename = "new-config.json"
do_upload()
luci.http.mock_form_files.singbox_config_file = nil
luci.http.mock_form_values.filename = nil
do_config_manager() -- Reload to see new file

print("\n--- Test Case 3: Activate config-proxy.json ---")
luci.http.mock_form_values.filename = "config-proxy.json"
do_activate()
luci.http.mock_form_values.filename = nil
do_config_manager() -- Reload to see active file

print("\n--- Test Case 4: Activate config-direct.json ---")
luci.http.mock_form_values.filename = "config-direct.json"
do_activate()
luci.http.mock_form_values.filename = nil
do_config_manager() -- Reload to see active file

print("\n--- Test Case 5: Download new-config.json ---")
luci.http.mock_form_values.filename = "new-config.json"
do_download()
luci.http.mock_form_values.filename = nil

print("\n--- Test Case 6: Delete new-config.json ---")
luci.http.mock_form_values.filename = "new-config.json"
do_delete()
luci.http.mock_form_values.filename = nil
do_config_manager() -- Reload to confirm deletion

print("\n--- Test Case 7: Delete active config-direct.json (should also remove symlink) ---")
luci.http.mock_form_values.filename = "config-direct.json"
do_delete()
luci.http.mock_form_values.filename = nil
do_config_manager() -- Reload to confirm deletion and no active config

print("\n--- Test Complete ---")
