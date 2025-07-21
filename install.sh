#!/bin/bash
# ==============================================================================
# SSH Login Notifier for Bark - Installation Script (Self-Cleaning & Idempotent)
# Author: Your Name
# GitHub: https://github.com/your-username/your-repo
# Description: 安装/更新后，每次 SSH 登录都会推送 Bark 通知。
# ==============================================================================

# --- 颜色定义 ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# --- 脚本变量 ---
NOTIFY_SCRIPT_PATH="/usr/local/bin/ssh_login_notify.sh"
PAM_SSHD_CONFIG="/etc/pam.d/sshd"
BACKUP_SUFFIX=".bak-$(date +%Y%m%d%H%M%S)"

# 1. 权限检查
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}错误：此脚本必须以 root 用户权限运行。${NC}"
  echo -e "请尝试：${YELLOW}sudo ./install.sh${NC}"
  exit 1
fi

# 2. 依赖检查
for cmd in curl python3; do
  if ! command -v $cmd &> /dev/null; then
    echo -e "${RED}错误：依赖 '$cmd' 未安装。${NC}"
    exit 1
  fi
done

# 3. 交互式输入
echo -e "${GREEN}=== SSH 登录 Bark 推送通知 安装程序 ===${NC}"
read -p "请输入您的 Bark Key (例如: abcdefg123456): " BARK_KEY
[ -z "$BARK_KEY" ] && { echo -e "${RED}错误：Bark Key 不能为空。${NC}"; exit 1; }

read -p "请输入您的 Bark 服务器 URL [留空则使用官方]: " BARK_URL
if [ -z "$BARK_URL" ]; then
  BARK_URL="https://api.day.app/"
  echo -e "${YELLOW}使用官方 Bark 服务器: ${NC}${BARK_URL}"
else
  [[ "$BARK_URL" != */ ]] && BARK_URL="${BARK_URL}/"
  echo -e "${GREEN}使用私有 Bark 服务器: ${NC}${BARK_URL}"
fi
echo ""

# 4. 清理旧安装
echo -e "${YELLOW}>> 清理旧的通知脚本与 PAM 配置...${NC}"
[ -f "$NOTIFY_SCRIPT_PATH" ] && rm -f "$NOTIFY_SCRIPT_PATH" && echo "已删除：${NOTIFY_SCRIPT_PATH}"
if [ -f "$PAM_SSHD_CONFIG" ]; then
  cp "$PAM_SSHD_CONFIG" "${PAM_SSHD_CONFIG}${BACKUP_SUFFIX}"
  echo "已备份 PAM 配置：${PAM_SSHD_CONFIG}${BACKUP_SUFFIX}"
  # 删除旧的 pam_exec 调用
  sed -i '\|ssh_login_notify.sh|d' "$PAM_SSHD_CONFIG"
  echo "已移除旧的 PAM 条目"
fi
echo ""

# 5. 创建推送脚本
echo -e "${YELLOW}>> 写入新的通知脚本...${NC}"
cat > "$NOTIFY_SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Bark SSH 登录通知脚本

BARK_KEY="$1"
BARK_URL="$2"

USER="$PAM_USER"
IP="$PAM_RHOST"
HOSTNAME="$(hostname)"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

TITLE="SSH 登录: ${USER}@${HOSTNAME}"
MESSAGE="来源：${IP}  时间：${TIMESTAMP}"

urlencode() {
  python3 - <<PYCODE
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1]))
PYCODE
}

TITLE_ENC=$(urlencode "$TITLE")
MSG_ENC=$(urlencode "$MESSAGE")

curl -s "${BARK_URL}${BARK_KEY}/${TITLE_ENC}/${MSG_ENC}" > /dev/null
EOF

chmod +x "$NOTIFY_SCRIPT_PATH"
echo "已创建并赋予执行权限：${NOTIFY_SCRIPT_PATH}"
echo ""

# 6. 更新 PAM 配置
echo -e "${YELLOW}>> 添加 pam_exec.so 到 PAM 配置...${NC}"
cat >> "$PAM_SSHD_CONFIG" << EOF

# —— SSH 登录 Bark 通知 —— 
session optional pam_exec.so /usr/local/bin/ssh_login_notify.sh ${BARK_KEY} ${BARK_URL}
EOF
echo "PAM 配置已更新：${PAM_SSHD_CONFIG}"
echo ""

# 7. 完成提示
echo -e "${GREEN}🎉 安装/更新完成！${NC}"
echo -e "请执行 ${YELLOW}systemctl restart sshd${NC} 以使更改生效。"
echo -e "下一次 SSH 登录时，您将收到 Bark 通知。"
