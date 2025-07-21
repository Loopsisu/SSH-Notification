#!/bin/bash
# ==============================================================================
# SSH Login Notifier for Bark - Installation Script (Self-Cleaning & Idempotent)
# Author: Loopsisu
# GitHub: https://github.com/Loopsisu/SSH-Notification
# Description: 安装/更新后，每次 SSH 登录都会推送 Bark 通知。
# ==============================================================================

# --- 颜色定义 ---
#!/bin/bash
# ==============================================================================
# SSH Login Notifier for Bark - 安装/更新脚本（POST JSON 格式）
# ==============================================================================
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

NOTIFY_SCRIPT_PATH="/usr/local/bin/ssh_login_notify.sh"
PAM_SSHD_CONFIG="/etc/pam.d/sshd"
BACKUP_SUFFIX=".bak-$(date +%Y%m%d%H%M%S)"

# 1. 权限 & 依赖检查
[ "$(id -u)" -ne 0 ] && echo -e "${RED}请以 root 运行脚本${NC}" && exit 1
for cmd in curl python3; do
  command -v $cmd &>/dev/null || { echo -e "${RED}缺少依赖：$cmd${NC}"; exit 1; }
done

# 2. 交互输入
echo -e "${GREEN}=== SSH 登录 Bark 通知 安装程序 ===${NC}"
read -p "请输入 Bark Key: " BARK_KEY
[ -z "$BARK_KEY" ] && echo -e "${RED}Key 不能为空${NC}" && exit 1
read -p "请输入 Bark 服务器 URL [回车使用官方]: " BARK_URL
if [ -z "$BARK_URL" ]; then
  BARK_URL="https://api.day.app/"
  echo -e "${YELLOW}使用官方服务器：${BARK_URL}${NC}"
else
  [[ "$BARK_URL" != */ ]] && BARK_URL="${BARK_URL}/"
  echo -e "${YELLOW}使用私有服务器：${BARK_URL}${NC}"
fi
echo ""

# 3. 清理旧文件 & 备份 PAM
echo -e "${YELLOW}>> 清理旧安装...${NC}"
[ -f "$NOTIFY_SCRIPT_PATH" ] && rm -f "$NOTIFY_SCRIPT_PATH" && echo "已删除旧脚本"
cp "$PAM_SSHD_CONFIG" "${PAM_SSHD_CONFIG}${BACKUP_SUFFIX}"
sed -i '\|ssh_login_notify.sh|d' "$PAM_SSHD_CONFIG"
echo "已备份并清理 PAM 配置(${BACKUP_SUFFIX})"
echo ""

# 4. 写入新通知脚本
echo -e "${YELLOW}>> 创建 /usr/local/bin/ssh_login_notify.sh ...${NC}"
cat > "$NOTIFY_SCRIPT_PATH" << 'EOF'
#!/bin/bash
# Bark SSH 登录通知脚本 (POST JSON)

# 参数
KEY="$1"
URL="$2"

# 获取 PAM 环境
USER="${PAM_USER:-$(whoami)}"
IP="${PAM_RHOST_IP:-${PAM_RHOST:-unknown}}"
HOST="$(hostname)"
TIME="$(date '+%Y-%m-%d %H:%M:%S')"

# —— 构造 JSON Payload —— 
read -r -d '' PAYLOAD <<JSON
{
  "title":    "✅ SSH 登录成功",
  "subtitle": "${USER}@${HOST}",
  "body":     "Source IP: ${IP}\\nLogin Date: ${TIME}"
}
JSON


# 发送 POST 请求
curl -s -X POST "${URL}${KEY}" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d "${PAYLOAD}" > /dev/null
EOF

chmod +x "$NOTIFY_SCRIPT_PATH"
echo "脚本已创建并赋予执行权限"
echo ""

# 5. 更新 PAM 配置
echo -e "${YELLOW}>> 更新 PAM: 添加 pam_exec.so ...${NC}"
cat >> "$PAM_SSHD_CONFIG" << EOF

# —— SSH 登录 Bark 通知 —— 
session optional pam_exec.so ${NOTIFY_SCRIPT_PATH} ${BARK_KEY} ${BARK_URL}
EOF
echo "PAM 配置已更新"
echo ""

# 6. 完成
echo -e "${GREEN}🎉 安装完成！${NC}"
echo -e "请执行 ${YELLOW}systemctl restart sshd${NC} 以使配置生效。"
