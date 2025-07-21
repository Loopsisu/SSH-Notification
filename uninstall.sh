#!/bin/bash

# ==============================================================================
# SSH Login Notifier for Bark - Uninstallation Script
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
  echo -e "请尝试使用: ${YELLOW}curl ... | sudo bash${NC}"
  exit 1
fi

echo -e "${GREEN}=== SSH 登录 Bark 推送通知卸��程序 ===${NC}"

# 2. 移除 PAM 配置
# 使用 sed 直接删除包含脚本路径的行
if grep -q "pam_exec.so ${NOTIFY_SCRIPT_PATH}" "${PAM_SSHD_CONFIG}"; then
  sed -i "/pam_exec.so ${NOTIFY_SCRIPT_PATH}/d" "${PAM_SSHD_CONFIG}"
  sed -i "/# SSH Login Notifier for Bark/d" "${PAM_SSHD_CONFIG}"
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
