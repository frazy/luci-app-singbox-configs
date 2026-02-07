-- Copyright (C) 2024 frazy
-- This is free software, licensed under the Apache License, Version 2.0.

module("luci.controller.singbox", package.seeall)

function index()
    -- Ensure /etc/config/singbox exists, if not, create a dummy one or handle gracefully
    -- For now, we assume singbox config file might exist.
    -- If singbox service is running from a specific config, we need to know its path.
    -- Let's define a base path for singbox configurations that our LuCI app will manage.
    local conf_base_path = "/etc/sing-box/" -- This should be where singbox looks for its main config or where we put a symlink

    entry({"admin", "services", "singbox"}, alias("admin", "services", "singbox", "config_manager"), _("Sing-Box"), 60).dependent = true

    entry({"admin", "services", "singbox", "config_manager"}, call("do_config_manager"), _("Configuration Manager"), 1).leaf = true
    entry({"admin", "services", "singbox", "config_manager", "upload"}, call("do_upload"), nil).leaf = true
    entry({"admin", "services", "singbox", "config_manager", "activate"}, call("do_activate"), nil).leaf = true
    entry({"admin", "services", "singbox", "config_manager", "delete"}, call("do_delete"), nil).leaf = true
    entry({"admin", "services", "singbox", "config_manager", "download"}, call("do_download"), nil).leaf = true
end

local config_dir = "/etc/sing-box/configs/"
local active_config_symlink = "/etc/sing-box/config.json" -- Sing-box reads from /etc/sing-box/config.json

local function get_config_files()
    local files = {}
    local stat = nixio.fs.stat(config_dir)
    if stat and stat.type == "directory" then
        for entry in nixio.fs.dir(config_dir) do
            if entry ~= "." and entry ~= ".." and nixio.fs.is_file(nixio.fs.join(config_dir, entry)) and entry:match("%.json$") then
                table.insert(files, entry)
            end
        end
    end
    table.sort(files)
    return files
end

local function get_active_config()
    local target = nixio.fs.readlink(active_config_symlink)
    if target then
        -- Extract just the filename if the target is in our config_dir
        if target:sub(1, #config_dir) == config_dir then
            return target:sub(#config_dir + 1)
        end
    end
    return nil
end

function do_config_manager()
    -- Ensure config directory exists
    nixio.fs.mkdir(config_dir)

    local files = get_config_files()
    local active_file = get_active_config()

    luci.template.render("singbox/config_manager", {
        config_files = files,
        active_config = active_file
    })
end

function do_upload()
    local f = luci.http.form_file("singbox_config_file")
    if f then
        local filename = luci.http.form_value("filename") or f.name
        if filename:match("%.json$") then
            local path = nixio.fs.join(config_dir, filename)
            local outfile = io.open(path, "w")
            if outfile then
                outfile:write(f:read_all())
                outfile:close()
                luci.http.redirect(luci.dispatcher.build_url("admin", "services", "singbox", "config_manager"))
                return
            else
                luci.http.redirect(luci.dispatcher.build_url("admin", "services", "singbox", "config_manager") .. "?error=upload_failed")
                return
            end
        else
            luci.http.redirect(luci.dispatcher.build_url("admin", "services", "singbox", "config_manager") .. "?error=invalid_file_type")
            return
        end
    end
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "singbox", "config_manager") .. "?error=no_file")
end


function do_activate()
    local filename = luci.http.form_value("filename")
    if filename and filename:match("%.json$") then
        local target_path = nixio.fs.join(config_dir, filename)
        if nixio.fs.access(target_path) then
            -- Remove old symlink if exists
            if nixio.fs.access(active_config_symlink) then
                nixio.fs.unlink(active_config_symlink)
            end
            -- Create new symlink
            nixio.fs.symlink(target_path, active_config_symlink)

            -- Restart singbox service (this command might vary depending on actual singbox init script)
            luci.sys.call("/etc/init.d/sing-box restart &>/dev/null &")

            luci.http.redirect(luci.dispatcher.build_url("admin", "services", "singbox", "config_manager"))
            return
        end
    end
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "singbox", "config_manager") .. "?error=activate_failed")
end

function do_delete()
    local filename = luci.http.form_value("filename")
    if filename and filename:match("%.json$") then
        local path = nixio.fs.join(config_dir, filename)
        if nixio.fs.access(path) then
            nixio.fs.unlink(path)
            -- If the deleted file was the active one, remove the symlink
            if get_active_config() == filename then
                nixio.fs.unlink(active_config_symlink)
            end
            luci.http.redirect(luci.dispatcher.build_url("admin", "services", "singbox", "config_manager"))
            return
        end
    end
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "singbox", "config_manager") .. "?error=delete_failed")
end

function do_download()
    local filename = luci.http.form_value("filename")
    if filename and filename:match("%.json$") then
        local path = nixio.fs.join(config_dir, filename)
        if nixio.fs.access(path) then
            luci.http.header("Content-Type", "application/json")
            luci.http.header("Content-Disposition", "attachment; filename=\"" .. filename .. "\"")
            luci.sys.write_file(path)
            return
        end
    end
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "singbox", "config_manager") .. "?error=download_failed")
end
