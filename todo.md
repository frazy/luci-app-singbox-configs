# 旺财的 Sing-Box LuCI 应用待办事项

**优先事项：**

*   **当前环境限制：** 在当前沙盒环境中无法执行完整的 OpenWrt 软件包编译。需要向 Boss 明确说明这一点。
*   **逻辑验证：** 编写模拟脚本，验证 `singbox.lua` 中文件管理（上传、激活、删除、下载）和 `config_manager.htm` 页面渲染的逻辑正确性。
*   **部署说明：** 提供清晰的 `README.md`，指导 Boss 如何在其 OpenWrt 编译环境中集成和编译此 LuCI 应用。

**详细待办：**

- [x] 创建 `plan.md` 和 `todo.md`。
- [x] 创建模拟的 `/etc/singbox/configs/` 目录及软链接目标目录 (`/etc/singbox/`)。
- [x] 放置 2-3 个示例 `singbox-config-*.json` 文件到模拟的 `configs` 目录。
- [x] 编写一个 Lua 脚本来模拟 LuCI 环境和 HTTP 请求，测试 `singbox.lua` 中的各项功能（`do_config_manager`, `do_upload`, `do_activate`, `do_delete`, `do_download`）。
- [x] 确保 `config_manager.htm` 可以在模拟环境下正确渲染（或至少验证其生成逻辑），可能通过输出 HTML 片段。
- [x] 撰写 `app/luci-app-singbox/README.md`，详细说明编译和部署步骤。
- [x] 设置定时检查任务，明天早上向 Boss 汇报。