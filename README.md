# luci-app-singbox - Sing-Box 配置文件管理器

这是一个用于 OpenWrt LuCI 界面的应用程序，旨在提供对 sing-box 配置文件进行管理的功能，包括上传、激活、下载和删除配置文件。

## 功能特性

*   **配置文件列表：** 显示 `/etc/singbox/configs/` 目录下所有可用的 sing-box 配置文件。
*   **当前活动配置：** 标识当前被 `singbox` 服务使用的配置文件（通过软链接 `/etc/singbox/config.json` 指向）。
*   **上传新配置：** 允许用户上传新的 sing-box 配置文件到指定目录。
*   **激活配置：** 将选定的配置文件设置为当前活动的 `singbox` 配置，并通过重启 `singbox` 服务使其生效。
*   **下载配置：** 允许用户下载现有配置文件。
*   **删除配置：** 允许用户删除不再需要的配置文件。

## 目录结构

```
app/luci-app-singbox/
├── files/
│   └── etc/
│       └── singbox/
│           ├── config.json  # 软链接，指向当前活动的配置文件
│           └── configs/     # 存储所有 sing-box 配置文件的目录
│               ├── singbox-config-1.json
│               └── singbox-config-2.json
├── controller/
│   └── singbox.lua          # LuCI 控制器，处理后端逻辑和路由
├── view/
│   └── singbox/
│       └── config_manager.htm # LuCI 视图，提供前端用户界面
├── Makefile                 # OpenWrt 包编译规则
└── README.md                # 本文件
```

## 编译和安装

**注意：** 本项目需要在 OpenWrt SDK 或完整的 OpenWrt 编译环境中进行编译。当前的沙盒环境无法进行完整的 `.ipk` 包编译。

### 1. 将项目添加到 OpenWrt 源码

将 `luci-app-singbox` 目录复制到 OpenWrt 源码的 `package/luci/applications/` 目录下。

```bash
cp -r luci-app-singbox /path/to/openwrt/source/package/luci/applications/
```

### 2. 配置和编译

进入 OpenWrt 源码根目录，更新 feeds 并安装 LuCI 相关的软件包：

```bash
cd /path/to/openwrt/source
./scripts/feeds update -a
./scripts/feeds install -a
```

运行 `make menuconfig`，在菜单中导航到 `LuCI -> Applications`，然后选择 `luci-app-singbox`。

```bash
make menuconfig
```

保存配置并退出。然后开始编译：

```bash
make V=s
```

编译完成后，`.ipk` 包将在 `bin/packages/<ARCH>/luci/` 目录下生成。

### 3. 安装到 OpenWrt 路由器

将生成的 `luci-app-singbox_*.ipk` 包复制到您的 OpenWrt 路由器上，并通过 `opkg` 命令安装：

```bash
opkg install luci-app-singbox_*.ipk
```

安装完成后，刷新 LuCI 界面，您将在菜单中找到 "Sing-Box 配置管理" 页面。

## 后端逻辑 (controller/singbox.lua) 概述

`singbox.lua` 控制器提供了以下 API 端点：

*   **`_CBI(name)`:** 提供 LuCI 配置界面的通用模型，但在此应用中主要通过 `config_manager.htm` 直接管理。
*   **`do_config_manager()`:** 用于渲染配置管理页面，列出所有配置文件，并标识当前活动配置。
*   **`do_upload()`:** 处理配置文件上传。
*   **`do_activate()`:** 激活选定的配置文件，更新软链接 `/etc/singbox/config.json`，并重启 sing-box 服务。
*   **`do_delete()`:** 删除指定的配置文件。
*   **`do_download()`:** 提供指定配置文件的下载。

## 前端界面 (view/singbox/config_manager.htm) 概述

`config_manager.htm` 文件使用 LuCI 模板语法来构建用户界面，包括：

*   一个文件上传表单。
*   一个显示配置文件列表的表格，包含文件名、状态（是否激活）、以及激活、下载、删除操作按钮。
*   JavaScript 代码用于处理 AJAX 请求和界面交互。

## 依赖

*   `singbox` 服务必须已安装并运行在 OpenWrt 系统上。
*   需要 `uci` 命令来管理 OpenWrt 配置。
*   需要 `nixio.fs` 模块来进行文件系统操作。

## 许可证

[待定，可添加许可证信息]