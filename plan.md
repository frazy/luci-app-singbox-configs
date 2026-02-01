# 旺财的 Sing-Box LuCI 应用开发计划

**目标：** 在 OpenWrt LuCI 界面上实现 sing-box 配置 JSON 文件的管理（上传、激活、下载、删除）和切换。

**当前状态：**
1.  `app/luci-app-singbox` 目录结构已创建。
2.  `Makefile` 已生成。
3.  `controller/singbox.lua` 已更新，包含文件管理逻辑和路由。
4.  `view/singbox/config_manager.htm` 已创建，提供用户界面。
5.  `model/cbi/singbox/general.lua` 已删除。

**执行计划：**

**阶段 1: 识别环境局限性并确定模拟方案**
*   **问题：** 当前操作环境是一个沙盒，不是标准的 OpenWrt 编译环境。这意味着直接执行 `make package/luci-app-singbox/compile` 等命令无法工作，因为缺少 `TOPDIR`、`rules.mk` 等 OpenWrt 构建系统所需的文件。
*   **方案：** 无法在沙盒中进行完整的 OpenWrt 软件包编译。我的“编译”将局限于验证 Lua 脚本的逻辑，并准备好完整的 LuCI 应用目录供 Boss 在其真正的 OpenWrt 编译环境中部署。

**阶段 2: 模拟环境和验证逻辑**
*   创建模拟的 `/etc/singbox/` 和 `/etc/singbox/configs/` 目录结构，以模拟路由器上的文件系统。
*   创建几个示例的 `singbox-config-*.json` 文件到模拟的 `configs` 目录。
*   编写一个简单的 Lua 脚本，模拟 LuCI 环境中 `nixio.fs` 和 `luci.http` 的关键函数，并调用 `singbox.lua` 控制器中的函数进行逻辑验证。
*   验证 `do_config_manager` 能正确读取文件列表和活动配置。
*   验证 `do_upload`, `do_activate`, `do_delete`, `do_download` 的模拟文件系统操作是否正确。
*   （可选）尝试模拟 `config_manager.htm` 的渲染结果，以验证视图逻辑。

**阶段 3: 准备交付物**
*   确保 `app/luci-app-singbox` 目录完整且所有文件正确无误。
*   撰写详细的 `app/luci-app-singbox/README.md` 文档，解释如何将此 LuCI 应用集成到 OpenWrt 编译系统并生成 `.ipk`，并包含必要的配置步骤和依赖说明。
*   明确指出在当前沙盒环境下无法进行完整的 OpenWrt 软件包编译，并提供 Boss 需自行编译的指导。
*   设置定时检查任务，明天早上向 Boss 汇报最终结果。

**预期结果：** 明天早上，Boss 将收到一个完整的 `luci-app-singbox` 目录，以及详细的部署和编译说明，并且我能够展示其核心逻辑（配置文件管理）在模拟环境下的行为验证。