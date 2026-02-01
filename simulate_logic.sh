# simulate_logic.sh

MOCK_ROOT="/tmp/singbox_mock_root"
SINGBOX_CONFIG_DIR="/etc/singbox"
SINGBOX_CONFIGS_SUBDIR="${SINGBOX_CONFIG_DIR}/configs"
ACTIVE_CONFIG_LINK="${SINGBOX_CONFIG_DIR}/config.json" # 实际的软链接文件

echo "--- 模拟 LuCI sing-box 配置文件管理逻辑 ---"
echo "模拟根目录: ${MOCK_ROOT}"
echo ""

# 1. 初始化模拟文件系统
echo "--- 步骤 1: 初始化模拟文件系统 ---"
rm -rf "${MOCK_ROOT}"
mkdir -p "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}"
mkdir -p "${MOCK_ROOT}/tmp_upload" # 模拟上传临时目录

echo '{"log": {"level": "info", "config_name": "example1"}}' > "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}/singbox-config-example1.json"
echo '{"log": {"level": "debug", "config_name": "example2"}}' > "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}/singbox-config-example2.json"
echo '{"log": {"level": "warn", "config_name": "new_upload"}}' > "${MOCK_ROOT}/tmp_upload/singbox-config-new.json"

echo "当前模拟文件系统状态:"
ls -l "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}"
ls -l "${MOCK_ROOT}${SINGBOX_CONFIG_DIR}" 2>/dev/null || echo "  (无活动配置软链接)"
echo ""

# 2. 模拟 do_config_manager (列出文件和当前活动配置)
# LuCI 的 do_config_manager 会读取 /etc/singbox/configs/ 目录并检查 /etc/singbox/config.json 软链接
echo "--- 步骤 2: 模拟 do_config_manager (列出配置文件) ---"
echo "模拟 LuCI 读取 /etc/singbox/configs/ 目录:"
find "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}" -type f -name "*.json" | xargs -n 1 basename
echo "模拟 LuCI 检查活动配置 (/etc/singbox/config.json 软链接):"
readlink -f "${MOCK_ROOT}${ACTIVE_CONFIG_LINK}" 2>/dev/null | sed "s|^${MOCK_ROOT}||" || echo "  (无活动配置)"
echo ""

# 3. 模拟 do_activate (激活 singbox-config-example1.json)
# LuCI 的 do_activate 会创建或更新软链接，并重启服务
echo "--- 步骤 3: 模拟 do_activate (激活 singbox-config-example1.json) ---"
TARGET_CONFIG="singbox-config-example1.json"
ln -sf "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}/${TARGET_CONFIG}" "${MOCK_ROOT}${ACTIVE_CONFIG_LINK}"
echo "模拟 sing-box 服务重启: /etc/init.d/singbox restart" # 实际不会执行，只是模拟
echo "服务重启完成。"

echo "当前模拟文件系统状态:"
ls -l "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}"
ls -l "${MOCK_ROOT}${ACTIVE_CONFIG_LINK}"
echo "活动配置内容:"
cat "${MOCK_ROOT}${ACTIVE_CONFIG_LINK}"
echo ""

# 4. 模拟 do_activate (激活 singbox-config-example2.json)
echo "--- 步骤 4: 模拟 do_activate (激活 singbox-config-example2.json) ---"
TARGET_CONFIG="singbox-config-example2.json"
ln -sf "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}/${TARGET_CONFIG}" "${MOCK_ROOT}${ACTIVE_CONFIG_LINK}"
echo "模拟 sing-box 服务重启: /etc/init.d/singbox restart" # 实际不会执行，只是模拟
echo "服务重启完成。"

echo "当前模拟文件系统状态:"
ls -l "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}"
ls -l "${MOCK_ROOT}${ACTIVE_CONFIG_LINK}"
echo "活动配置内容:"
cat "${MOCK_ROOT}${ACTIVE_CONFIG_LINK}"
echo ""

# 5. 模拟 do_delete (删除 singbox-config-example1.json)
echo "--- 步骤 5: 模拟 do_delete (删除 singbox-config-example1.json) ---"
TARGET_CONFIG="singbox-config-example1.json"
rm -f "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}/${TARGET_CONFIG}"
# 如果删除的是当前活动配置，软链接会失效，或者需要额外处理（singbox.lua 中有逻辑处理）
if [ ! -e "${MOCK_ROOT}${ACTIVE_CONFIG_LINK}" ]; then
    echo "  (注意: 活动配置软链接已失效或被移除)"
fi

echo "当前模拟文件系统状态:"
ls -l "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}"
ls -l "${MOCK_ROOT}${ACTIVE_CONFIG_LINK}" 2>/dev/null || echo "  (无活动配置软链接)"
echo ""

# 6. 模拟 do_upload (上传 singbox-config-new.json)
echo "--- 步骤 6: 模拟 do_upload (上传 singbox-config-new.json) ---"
UPLOAD_FILENAME="singbox-config-new.json"
UPLOAD_TMP_PATH="${MOCK_ROOT}/tmp_upload/${UPLOAD_FILENAME}"
DEST_PATH="${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}/${UPLOAD_FILENAME}"

if [ -f "${UPLOAD_TMP_PATH}" ]; then
    mv "${UPLOAD_TMP_PATH}" "${DEST_PATH}"
    echo "文件 '${UPLOAD_FILENAME}' 已从临时目录上传并移动到目标目录。"
else
    echo "错误: 模拟上传文件 '${UPLOAD_TMP_PATH}' 不存在。"
fi

echo "当前模拟文件系统状态:"
ls -l "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}"
echo ""

# 7. 模拟 do_download (下载 singbox-config-example2.json)
echo "--- 步骤 7: 模拟 do_download (下载 singbox-config-example2.json) ---"
DOWNLOAD_FILENAME="singbox-config-example2.json"
echo "模拟 LuCI 提供文件下载，内容如下:"
cat "${MOCK_ROOT}${SINGBOX_CONFIGS_SUBDIR}/${DOWNLOAD_FILENAME}"
echo ""

# 清理
echo "--- 步骤 8: 清理模拟环境 ---"
rm -rf "${MOCK_ROOT}"
echo "模拟环境已清理。"