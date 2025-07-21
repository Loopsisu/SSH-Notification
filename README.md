# SSH 登录通知 for Bark (SSH Login Notifier for Bark)

一个自动化脚本，用于在 Debian/Ubuntu 等 Linux 服务器上设置 SSH 登录成功时的 [Bark](https://github.com/Finb/Bark) 推送通知。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

### ✨ 功能特性

*   **一键安装**: 只需一行命令即可完成所有配置。
*   **交互式配置**: 脚本会自动提示您输入 Bark Key，无需手动修改任何文件。
*   **安全可靠**: 使用标准的 PAM 机制，实时触发，不影响正常登录。
*   **信息丰富**: 推送内容包含登录用户名、来源 IP、服务器主机名和时间。
*   **轻松卸载**: 提供一键卸载脚本，干净地移除所有配置。

### 📱 通知效果预览

当有新的 SSH 登录时，您的手机将收到如下通知：

> **[终端图标] ✅ SSH 登录成功**
>
> **用户: root**
>
> **来源IP: 123.45.67.89**
>
> **主机: MyDebianServer**
>
> **时间: 2025-07-21 10:30:00**

### 🚀 快速开始 (一键安装)

在您的服务器上，以 `root` 用户或拥有 `sudo` 权限的用户执行以下命令：

```bash
curl -sSL -o install.sh https://raw.githubusercontent.com/Loopsisu/SSH-Notification/main/install.sh && chmod +x install.sh && sudo ./install.sh
```

> **注意**: 请将 `你的用户名/你的仓库名` 替换为您自己的 GitHub 地址。

脚本将引导您完成安装过程。

### 卸载

如果您想移除此功能，请执行卸载脚本：

```bash
curl -sSL https://raw.githubusercontent.com/Loopsisu/SSH-Notification/main/uninstall.sh | sudo bash
```

### ⚙️ 工作原理

本脚本利用了 Linux 的 **PAM (Pluggable Authentication Modules)** 机制。

1.  `install.sh` 会在 `/usr/local/bin/` 目录下创建一个名为 `ssh_login_notify.sh` 的推送脚本。
2.  然后，它会在 SSH 的 PAM 配置文件 `/etc/pam.d/sshd` 的末尾添加一行规则。
3.  该规则会在用户成功建立 SSH 会话 (`session`) 时，调用 `ssh_login_notify.sh` 脚本。
4.  脚本从 PAM 提供的环境变量中获取登录用户 (`$PAM_USER`) 和来源 IP (`$PAM_RHOST`)，然后通过 `curl` 调用 Bark API 发送通知。

### ⚠️ 注意事项

*   **系统兼容性**: 已在 **Debian 12/11** 和 **Ubuntu 22.04/20.04** 上测试通过。理论上支持所有使用 PAM 的现代 Linux 发行版。
*   **依赖**: 脚本会自动检测 `curl` 是否已安装。
*   **安全性**: PAM 配置中使用了 `optional` 关键字，确保即使推送脚本执行失败（例如网络问题），也**不会**影响用户的正常 SSH 登录。

---
希望你喜欢这个工具！
