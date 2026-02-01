-- test_singbox_controller.lua

-- 模拟全局变量和函数
_M = {}
module = function(name, ...)
    package.loaded[name] = _M
    return _M
end

-- 模拟 nixio.fs
nixio = {
    fs = {
        _mock_root = "/tmp/singbox_mock_root",
        _active_config_link = "/etc/singbox/config.json", -- 这个路径是LuCI内部使用的，不是实际文件系统路径
        _singbox_configs_dir = "/etc/singbox/configs", -- 模拟的配置文件目录

        -- 辅助函数，将 LuCI 路径转换为模拟文件系统路径
        _to_mock_path = function(luci_path)
            return nixio.fs._mock_root .. luci_path
        end,

        -- 模拟 readdir
        readdir = function(path)
            local target_path = nixio.fs._to_mock_path(path)
            print(string.format("MOCK: readdir('%s') -> real: '%s'", path, target_path))
            local files = {}
            local p = io.popen("ls -1 " .. target_path .. " 2>/dev/null")
            if p then
                for line in p:lines() do
                    if line ~= "config.json" then -- 排除软链接本身
                        table.insert(files, line)
                    end
                end
                p:close()
            end
            return files
        end,

        -- 模拟 readfile
        readfile = function(path)
            local target_path = nixio.fs._to_mock_path(path)
            print(string.format("MOCK: readfile('%s') -> real: '%s'", path, target_path))
            local f = io.open(target_path, "r")
            if f then
                local content = f:read("*a")
                f:close()
                return content
            end
            return nil
        end,

        -- 模拟 writefile
        writefile = function(path, content)
            local target_path = nixio.fs._to_mock_path(path)
            print(string.format("MOCK: writefile('%s', ...) -> real: '%s'", path, target_path))
            -- 确保目标目录存在
            local dir = target_path:match("(.*/)[^/]*$")
            if dir then os.execute(string.format("mkdir -p '%s'", dir)) end

            local f = io.open(target_path, "w")
            if f then
                f:write(content)
                f:close()
                return true
            end
            return false
        end,

        -- 模拟 link (硬链接，这里我们用软链接模拟)
        link = function(oldpath, newpath)
            -- 这个函数在 LuCI 应用中可能不直接使用，更常用 symlink
            -- 如果 singbox.lua 中使用了 hard link，这里也用 symlink 模拟
            print(string.format("MOCK: link('%s', '%s')", oldpath, newpath))
            return nixio.fs.symlink(oldpath, newpath) -- 简单地重定向到 symlink 模拟
        end,

        -- 模拟 symlink
        symlink = function(oldpath, newpath)
            local target_oldpath_real = nixio.fs._to_mock_path(oldpath) -- 实际指向的文件
            local target_newpath_real = nixio.fs._to_mock_path(newpath) -- 链接文件本身
            print(string.format("MOCK: symlink('%s', '%s') -> real: ln -sf '%s' '%s'", oldpath, newpath, target_oldpath_real, target_newpath_real))

            -- 确保目标链接文件所在的目录存在
            local newpath_dir = target_newpath_real:match("(.*/)[^/]*$")
            if newpath_dir then
                os.execute(string.format("mkdir -p '%s'", newpath_dir))
            end

            -- 如果旧链接存在，先删除
            os.execute(string.format("rm -f '%s'", target_newpath_real))
            os.execute(string.format("ln -sf '%s' '%s'", target_oldpath_real, target_newpath_real))
            return true
        end,

        -- 模拟 readlink
        readlink = function(path)
            local target_path_real = nixio.fs._to_mock_path(path)
            print(string.format("MOCK: readlink('%s') -> real: '%s'", path, target_path_real))
            local p = io.popen("readlink -f " .. target_path_real .. " 2>/dev/null")
            if p then
                local link_target_real = p:read("*l")
                p:close()
                if link_target_real then
                    -- 移除 mock root 路径前缀，使其符合 LuCI 内部的路径表示
                    link_target_real = link_target_real:gsub(nixio.fs._mock_root, "")
                    return link_target_real
                end
            end
            return nil
        end,

        -- 模拟 unlink
        unlink = function(path)
            local target_path = nixio.fs._to_mock_path(path)
            print(string.format("MOCK: unlink('%s') -> real: '%s'", path, target_path))
            return os.execute(string.format("rm -f '%s'", target_path))
        end,

        -- 模拟 stat
        stat = function(path)
            local target_path = nixio.fs._to_mock_path(path)
            -- print(string.format("MOCK: stat('%s') -> real: '%s'", path, target_path))
            local p = io.popen("stat -c '%F %s' " .. target_path .. " 2>/dev/null")
            if p then
                local res = p:read("*l")
                p:close()
                if res then
                    local type, size = res:match("^(%S+) (%d+)$")
                    if type == "regular file" or type == "symbolic link" or type == "directory" then
                        return {type = type, size = tonumber(size)}
                    end
                end
            end
            return nil
        end,
    }
}

-- 模拟 luci.http
luci = {
    http = {
        _formvalues = {},
        _headers = {},
        _redirect_url = nil,
        _output = "",

        formvalue = function(key)
            print(string.format("MOCK: formvalue('%s') = '%s'", key, luci.http._formvalues[key]))
            return luci.http._formvalues[key]
        end,

        header = function(key, value)
            print(string.format("MOCK: header('%s', '%s')", key, value))
            luci.http._headers[key] = value
        end,

        redirect = function(url)
            print(string.format("MOCK: redirect('%s')", url))
            luci.http._redirect_url = url
        end,

        write = function(content)
            luci.http._output = luci.http._output .. tostring(content)
        end,

        status = function(code, message)
            print(string.format("MOCK: status(%s, '%s')", code, message))
        end
    }
}

-- 模拟 luci.sys
luci.sys = {
    -- 模拟 luci.sys.call
    call = function(command)
        print(string.format("MOCK: luci.sys.call('%s')", command))
        if command == "/etc/init.d/singbox restart" then
            print("MOCK: sing-box service restarted.")
            return 0 -- 成功
        end
        return os.execute(command) -- 其他命令实际执行
    end
}

-- 模拟 luci.template
luci.template = {
    render = function(template_path, data)
        print(string.format("MOCK: luci.template.render('%s', ...)", template_path))
        -- 简单模拟渲染，输出数据
        luci.http.write("<!-- MOCK Rendered: " .. template_path .. " -->\n")
        if data then
            for k, v in pairs(data) do
                luci.http.write(string.format("<!-- Data: %s = %s -->\n", k, tostring(v)))
            end
        end
        return luci.http._output
    end
}


-- 加载控制器
dofile("controller/singbox.lua") -- 注意：这里是相对路径，确保在 app/luci-app-singbox 目录下执行

-- 测试用例
function run_test(name, func, form_values)
    print("\n--- Running Test: " .. name .. " ---")
    luci.http._formvalues = form_values or {}
    luci.http._headers = {}
    luci.http._redirect_url = nil
    luci.http._output = ""

    local success, err = pcall(func)
    if not success then
        print("TEST FAILED: " .. tostring(err))
    else
        print("TEST PASSED.")
    end

    print("HTTP Output:\n" .. luci.http._output)
    if luci.http._redirect_url then
        print("Redirected to: " .. luci.http._redirect_url)
    end
    print("---------------------------------")
end

-- 清理模拟环境
function cleanup_mock_root()
    print("Cleaning up mock root...")
    os.execute("rm -rf " .. nixio.fs._mock_root)
    os.execute("mkdir -p " .. nixio.fs._mock_root .. "/etc/singbox/configs/")
    -- 重新创建示例配置文件
    io.open(nixio.fs._mock_root .. "/etc/singbox/configs/singbox-config-example1.json", "w"):write([[{"log": {"level": "info"}}]]):close()
    io.open(nixio.fs._mock_root .. "/etc/singbox/configs/singbox-config-example2.json", "w"):write([[{"log": {"level": "debug"}}]]):close()
    print("Mock root cleaned and re-initialized.")
end

-- 初始清理和设置
cleanup_mock_root()

-- Test 1: do_config_manager (initial load)
run_test("do_config_manager - Initial", _M.do_config_manager)

-- Test 2: do_activate (activate example1)
run_test("do_activate - example1", _M.do_activate, {filename = "singbox-config-example1.json"})

-- Verify activation
run_test("do_config_manager - After activate example1", _M.do_config_manager)
print("Current active link target (simulated): " .. tostring(nixio.fs.readlink("/etc/singbox/config.json")))

-- Test 3: do_activate (activate example2)
run_test("do_activate - example2", _M.do_activate, {filename = "singbox-config-example2.json"})

-- Verify activation
run_test("do_config_manager - After activate example2", _M.do_config_manager)
print("Current active link target (simulated): " .. tostring(nixio.fs.readlink("/etc/singbox/config.json")))

-- Test 4: do_delete (delete example1)
run_test("do_delete - example1", _M.do_delete, {filename = "singbox-config-example1.json"})

-- Verify deletion
run_test("do_config_manager - After delete example1", _M.do_config_manager)
print("Current active link target (simulated): " .. tostring(nixio.fs.readlink("/etc/singbox/config.json")))


-- Test 5: do_upload (simulate upload of a new file)
-- 为了简化模拟，这里直接在模拟的文件系统创建文件，而不是模拟HTTP POST上传过程
-- 假设上传的文件名为 'singbox-config-new.json'
local new_file_content = [[{"log": {"level": "warn"}}]]
nixio.fs.writefile("/tmp_upload/singbox-config-new.json", new_file_content) -- 模拟文件上传到临时目录
run_test("do_upload - new config", _M.do_upload, {filename = "singbox-config-new.json", filepath = "/tmp_upload/singbox-config-new.json"}) -- 注意这里 filepath 使用 /tmp_upload 而不是 /upload_tmp

-- Verify upload
run_test("do_config_manager - After upload", _M.do_config_manager)


-- Test 6: do_download (simulate download of example2)
-- do_download 会直接写入 HTTP body，这里验证输出内容
run_test("do_download - example2", _M.do_download, {filename = "singbox-config-example2.json"})

-- 清理
cleanup_mock_root()
