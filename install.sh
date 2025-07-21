#!/bin/bash

# ==============================================================================
# SSH Login Notifier for Bark - Installation Script
# Author: Your Name
# GitHub: https://github.com/your-username/your-repo
# ==============================================================================

# --- 颜色定义 ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- 脚本变量 ---
NOTIFY_SCRIPT_PATH="/usr/local/bin/ssh_login_notify.sh"
PAM_SSHD_CONFIG="/etc/pam.d/sshd"

# 1. 权限检查：必须以 root 用户运行
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}错误：此脚本必须以 root 用户权限运行。${NC}"
  echo -e "请尝试使用: ${YELLOW}curl ... | sudo bash${NC}"
  exit 1
fi

# 2. 依赖检查：检查 curl 是否安装
if ! command -v curl &> /dev/null; then
  echo -e "${RED}错误：依赖 'curl' 未安装。${NC}"
  echo -e "请先安装 curl: ${YELLOW}sudo apt update && sudo apt install -y curl${NC}"
  exit 1
fi

# 3. 欢迎信息与交互式输入
echo -e "${GREEN}=== SSH 登录 Bark 推送通知安装程序 ===${NC}"
echo "此脚本将配置系统，在每次 SSH 成功登录时发送一条 Bark 通知。"
echo ""

read -p "请输入您的 Bark Key (例如: abcdefg123456): " BARK_KEY

if [ -z "$BARK_KEY" ]; then
  echo -e "${RED}错误：Bark Key 不能为空。安装已中止。${NC}"
  exit 1
fi

echo -e "${GREEN}配置信息确认完毕，正在安装...${NC}"

# 4. 创建推送脚本
# 使用 here document 创建脚本文件，并动态插入用户提供的 BARK_KEY
# 注意：$PAM_USER 等变量需要转义，以便它们在最终脚本中保持原样
tee "$NOTIFY_SCRIPT_PATH" > /dev/null <<EOF
#!/bin/bash
BARK_KEY="${BARK_KEY}"

if [[ "\$PAM_TYPE" != "open_session" ]]; then
  exit 0
fi

TITLE="✅ SSH 登录成功"
HOSTNAME=\$(hostname)
DATE=\$(date "+%Y-%m-%d %H:%M:%S")
BODY="用户: \${PAM_USER}\n来源IP: \${PAM_RHOST}\n主机: \${HOSTNAME}\n时间: \${DATE}"

curl --silent --output /dev/null \\
  -G "https://api.day.app/\${BARK_KEY}" \\
  --data-urlencode "title=\${TITLE}" \\
  --data-urlencode "body=\${BODY}" \\
  -d "icon=https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/terminal.png" \\
  -d "group=服务器登录"

exit 0
EOF

# 5. 设置脚本权限
chmod +x "$NOTIFY_SCRIPT_PATH"

# 6. 配置 PAM
# 检查是否已存在配置，避免重复添加
if grep -q "pam_exec.so ${NOTIFY_SCRIPT_PATH}" "${PAM_SSHD_CONFIG}"; then
  echo -e "${YELLOW}警告：PAM 配置已存在，无需重复添加。${NC}"
else
  # 创建备份
  cp "${PAM_SSHD_CONFIG}" "${PAM_SSHD_CONFIG}.bak.$(date +%F-%T)"
  # 在文件末尾添加配置
  echo "" >> "${PAM_SSHD_CONFIG}"
  echo "# SSH Login Notifier for Bark - 由安装脚本自动添加" >> "${PAM_SSHD_CONFIG}"
  echo "session    optional     pam_exec.so ${NOTIFY_SCRIPT_PATH}" >> "${PAM_SSHD_CONFIG}"
  echo -e "${GREEN}PAM 配置已成功更新。${NC}"
fi

# 7. 完成提示
echo ""
echo -e "${GREEN}🎉 恭喜！安装已成功完成！${NC}"
echo "现在，每次通过 SSH 登录此服务器时，您都会收到一条 Bark 通知。"
echo -e "要卸载此功能，请运行卸载脚本。"

exit 0
