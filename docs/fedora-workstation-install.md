# Fedora Workstation 分步安装手册

本手册记录本项目在原生 Fedora Workstation 上使用过的安装步骤。以普通用户执行，系统软件包安装时按提示输入 `sudo` 密码。需要联网下载软件包和工具。niri 与 DMS 应已安装；本项目不安装或配置它们。

先进入仓库根目录：

```bash
cd ~/dev/linux-dev-template
```

按下列顺序逐步执行。前一步成功后再执行下一步。

## 1. 基础工具与 zsh

```bash
./scripts/common/00-base.sh
./scripts/common/10-shell.sh --install-zshrc-template --set-default-shell
```

`00-base.sh` 安装 Git、curl、编译工具和各模块共用的命令，并创建工作目录。`10-shell.sh` 安装 zsh、Oh My Zsh、Powerlevel10k 与 zsh 插件；已有 `~/.zshrc` 会先备份，再安装项目模板。`--set-default-shell` 使用 `chsh` 将 zsh 设为永久登录 shell。执行完毕后退出当前登录会话，重新登录，再进入仓库目录继续。

## 2. 字体、终端配置与剪贴板

```bash
./scripts/common/12-nerd-font.sh
```

该脚本安装 JetBrainsMono Nerd Font。

如果 Alacritty 或 Ghostty 已经安装，可按需运行相应配置脚本；它们只安装配置，不安装终端程序：

```bash
./scripts/common/14-alacritty.sh
./scripts/common/14-ghostty.sh
```

运行过终端配置脚本后，重新打开相应终端以应用设置。

安装 Wayland 剪贴板命令 `wl-copy`、`wl-paste`：

```bash
./scripts/common/13-clipboard.sh
```

## 3. 终端工具

```bash
./scripts/common/15-tmux.sh
./scripts/common/16-zellij.sh
./scripts/common/17-herdr.sh
./scripts/common/18-yazi.sh
./scripts/common/20-direnv.sh
```

这些脚本依次安装并配置 tmux（含 TPM 和配置声明的插件）、Zellij、Herdr、Yazi，以及 direnv。Yazi 脚本还安装预览和导航所需的软件包。direnv 的 zsh 钩子由项目的 `~/.zshrc` 加载。

## 4. 开发运行时与数据库客户端

```bash
./scripts/common/30-python.sh
./scripts/common/40-node.sh
./scripts/common/50-db-clients.sh
./scripts/common/80-devtools.sh
```

这些脚本依次安装 Python、pipx、uv 和 Python 工具；nvm、当前 LTS Node.js、npm 和全局 Node 工具；SQLite、PostgreSQL、MySQL、Valkey 命令行工具；以及 yamllint、shfmt、gh、ShellCheck。数据库客户端脚本不会启用或启动数据库服务。

以上步骤不包括可选的 PostgreSQL 服务、nginx 服务或 OpenVPN 辅助脚本。各脚本明确请求的软件包和其他安装内容见[逐脚本安装清单](installation-inventory.md)。
