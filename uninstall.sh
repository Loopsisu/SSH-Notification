#!/bin/bash

# ==============================================================================
# SSH Login Notifier for Bark - Uninstallation Script (Enhanced Version)
# ==============================================================================

# --- 颜色定义 ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- 脚本变量 ---
NOTIFY_SCRIPT_PATH="/usr/local/bin/ssh_login_notify.sh"
PAM_SSHD_CONFIG="/etc/pam.d/sshd"

# 1. 权限检查
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}错误：此脚本必须以 root 用户权限运行。${NC}"
  echo -e "请尝试使用: ${YELLOW}sudo ./uninstall.sh${NC}"
  exit 1
fi

echo -e "${GREEN}=== SSH 登录 Bark 推送通知卸载程序 ===${NC}"

# 2. 移除 PAM 配置
# [改进] 使用 grep -q 来安静地检查，避免输出匹配的行
if grep -q "pam_exec.so.*${NOTIFY_SCRIPT_PATH}" "${PAM_SSHD_CONFIG}"; then
  # [改进] 在修改前创建备份，更加安全
  cp "${PAM_SSHD_CONFIG}" "${PAM_SSHD_CONFIG}.bak.uninstall.$(date +%F_%T)"
  echo "PAM 配置文件备份已创建。"

  # [关键修复] 使用 '#' 作为 sed 的分隔符，避免与路径中的 '/' 冲突
  # [改进] 将两个删除命令合并为一条，提高效率
  sed -i \
    -e "#pam_exec.so.*${NOTIFY_SCRIPT_PATH}#d" \
    -e "/# SSH Login Notifier for Bark/d" \
    "${PAM_SSHD_CONFIG}"
  
  echo -e "${GREEN}PAM 配置已成功移除。${NC}"
else
  echo -e "${YELLOW}未找到相关的 PAM 配置，无需操作。${NC}"
fi

# 3. 移除推送脚本
if [ -f "$NOTIFY_SCRIPT_PATH" ]; then
  rm -f "$NOTIFY_SCRIPT_PATH"
  echo -e "${GREEN}推送脚本 '${NOTIFY_SCRIPT_PATH}' 已被删除。${NC}"
else
  echo -e "${YELLOW}未找到推送脚本，无需操作。${NC}"
fi

echo ""
echo -e "${GREEN}✅ 卸载完成。SSH 登录将不再发送通知。${NC}"

exit 0
