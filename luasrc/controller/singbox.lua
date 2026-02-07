-- Copyright (C) 2024 frazy
-- This is free software, licensed under the Apache License, Version 2.0.

module("luci.controller.singbox", package.seeall)

local config_dir = "/etc/sing-box/configs/"
local active_config_symlink = "/etc/sing-box/config.json"

function index()
    entry({"admin", "services", "singbox"}, alias("admin", "services", "singbox", "config_manager"), _("Sing-Box"), 60).dependent = true
    entry({"admin", "services", "singbox", "config_manager"}, call("do_config_manager"), _("Configuration Manager"), 1)
    entry({"admin", "services", "singbox", "config_manager", "upload"}, call("do_upload"), nil).leaf = true
    entry({"admin", "services", "singbox", "config_manager", "activate"}, call("do_activate"), nil).leaf = true
    entry({"admin", "services", "singbox", "config_manager", "delete"}, call("do_delete"), nil).leaf = true
    entry({"admin", "services", "singbox", "config_manager", "download"}, call("do_download"), nil).leaf = true
end

local function get_config_files()
    local fs = require "nixio.fs"
    local files = {}
    local stat = fs.stat(config_dir)
    if stat and stat.type == "dir" then
        for file in fs.dir(config_dir) do
            if file:match("%.json$") then
                table.insert(files, file)
            end
        end
    end
    table.sort(files)
    return files
end

local function get_active_config()
    local fs = require "nixio.fs"
    local target = fs.readlink(active_config_symlink)
    if target then
        if target:sub(1, #config_dir) == config_dir then
            return target:sub(#config_dir + 1)
        end
    end
    return nil
end

function do_config_manager()
    local fs = require "nixio.fs"
    local http = require "luci.http"
    local tpl = require "luci.template"

    fs.mkdirr(config_dir)

    local files = get_config_files()
    local active_file = get_active_config()
    local err = http.formvalue("error")

    tpl.render("singbox/config_manager", {
        config_files = files,
        active_config = active_file,
        error_msg = err
    })
end

function do_upload()
    local fs = require "nixio.fs"
    local http = require "luci.http"
    local dispatcher = require "luci.dispatcher"

    local file_content = nil
    local file_name = nil

    http.setfilehandler(function(meta, chunk, eof)
        if not file_name and meta and meta.file then
            file_name = meta.file
        end
        if chunk then
            file_content = (file_content or "") .. chunk
        end
    end)

    local _ = http.formvalue("singbox_config_file")
    local filename_form = http.formvalue("filename")

    local filename = (filename_form and #filename_form > 0) and filename_form or file_name

    fs.mkdirr(config_dir)

    if file_content and filename then
        if filename:match("%.json$") then
            local path = config_dir .. filename
            local outfile = io.open(path, "w")
            if outfile then
                outfile:write(file_content)
                outfile:close()
                http.redirect(dispatcher.build_url("admin", "services", "singbox", "config_manager"))
                return
            else
                http.redirect(dispatcher.build_url("admin", "services", "singbox", "config_manager") .. "?error=upload_failed")
                return
            end
        else
            http.redirect(dispatcher.build_url("admin", "services", "singbox", "config_manager") .. "?error=invalid_file_type")
            return
        end
    end
    http.redirect(dispatcher.build_url("admin", "services", "singbox", "config_manager") .. "?error=no_file")
end

function do_activate()
    local fs = require "nixio.fs"
    local http = require "luci.http"
    local dispatcher = require "luci.dispatcher"
    local sys = require "luci.sys"

    local filename = http.formvalue("filename")
    if filename and filename:match("%.json$") then
        local target_path = config_dir .. filename
        if fs.access(target_path) then
            if fs.access(active_config_symlink) then
                fs.unlink(active_config_symlink)
            end
            fs.symlink(target_path, active_config_symlink)
            sys.call("/etc/init.d/sing-box restart &>/dev/null &")
            http.redirect(dispatcher.build_url("admin", "services", "singbox", "config_manager"))
            return
        end
    end
    http.redirect(dispatcher.build_url("admin", "services", "singbox", "config_manager") .. "?error=activate_failed")
end

function do_delete()
    local fs = require "nixio.fs"
    local http = require "luci.http"
    local dispatcher = require "luci.dispatcher"

    local filename = http.formvalue("filename")
    if filename and filename:match("%.json$") then
        local path = config_dir .. filename
        if fs.access(path) then
            fs.unlink(path)
            if get_active_config() == filename then
                fs.unlink(active_config_symlink)
            end
            http.redirect(dispatcher.build_url("admin", "services", "singbox", "config_manager"))
            return
        end
    end
    http.redirect(dispatcher.build_url("admin", "services", "singbox", "config_manager") .. "?error=delete_failed")
end

function do_download()
    local fs = require "nixio.fs"
    local http = require "luci.http"
    local dispatcher = require "luci.dispatcher"

    local filename = http.formvalue("filename")
    if filename and filename:match("%.json$") then
        local path = config_dir .. filename
        if fs.access(path) then
            local content = fs.readfile(path)
            if content then
                http.header("Content-Type", "application/json")
                http.header("Content-Disposition", 'attachment; filename="' .. filename .. '"')
                http.write(content)
                return
            end
        end
    end
    http.redirect(dispatcher.build_url("admin", "services", "singbox", "config_manager") .. "?error=download_failed")
end
