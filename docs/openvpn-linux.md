# Linux Mint 上的 OpenVPN 3 使用记录

本文记录在 Linux Mint Desktop 上使用 OpenVPN 3 Linux 的排查过程、尝试过的命令、最终方案和日常使用方式。

本文中的配置示例名称是：

```text
hefei@34.204.18.69
```

请替换成自己的 OpenVPN 3 配置名称。用户名和密码不应写入本文、脚本或 Git 仓库。

## 1. 环境和目标

- 操作系统：Linux Mint 22.x Desktop
- 桌面：Cinnamon
- VPN 客户端：OpenVPN 3 Linux
- OpenVPN 配置已经预先导入 OpenVPN 3 Configuration Manager
- 目标：缩短连接和断开命令，并避免每次输入用户名和密码

## 2. 导入并定义 OpenVPN 3 Profile

OpenVPN 3 使用 Configuration Manager 管理 profile。不要直接把 `.ovpn` 文件路径当作日常连接配置；建议导入时同时指定稳定的 profile 名称，并设置为持久化配置。

假设下载的配置文件是 `~/Downloads/hefei.ovpn`：

```bash
chmod 600 "$HOME/Downloads/hefei.ovpn"
openvpn3 config-import \
  --config "$HOME/Downloads/hefei.ovpn" \
  --name 'hefei@34.204.18.69' \
  --persistent
```

其中：

- `--config`：待导入的 `.ovpn` 文件。
- `--name`：定义以后传给 `--config` 的 profile 名称。
- `--persistent`：让 profile 在 OpenVPN 3 服务重启后仍然存在。

确认导入结果：

```bash
openvpn3 configs-list
```

查看 profile 的路径、持久化状态和 override：

```bash
openvpn3 config-manage \
  --config 'hefei@34.204.18.69' \
  --show
```

本次使用的 profile 最终显示为：

```text
Name: hefei@34.204.18.69
Persistent config: Yes
```

如果服务端地址需要覆盖 `.ovpn` 文件中的 `remote`，可以对已导入 profile 设置 server override：

```bash
openvpn3 config-manage \
  --config 'hefei@34.204.18.69' \
  --server-override 3.93.176.244
```

这会修改 OpenVPN 3 管理器中的 profile override，不会修改原始 `.ovpn` 文件。设置后可再次执行 `config-manage --show` 检查。

如果 profile 名称或文件导入错误，先确认没有活动会话，再删除 profile：

```bash
openvpn3 sessions-list
openvpn3 config-remove \
  --config 'hefei@34.204.18.69' \
  --force
```

然后重新执行 `config-import`。`config-remove` 只删除 OpenVPN 3 Configuration Manager 中的 profile，不会删除磁盘上的 `.ovpn` 文件。

## 3. 最初使用的长命令

连接 VPN：

```bash
openvpn3 session-start --config 'hefei@34.204.18.69'
```

断开 VPN：

```bash
openvpn3 session-manage \
  --config 'hefei@34.204.18.69' \
  --disconnect
```

查看当前会话：

```bash
openvpn3 sessions-list
```

查看单个配置的统计信息：

```bash
openvpn3 session-stats --config 'hefei@34.204.18.69'
```

## 4. `tun0` 问题的排查结论

曾经根据 `openvpn3 sessions-list` 中的：

```text
Device: tun0
```

尝试调整 MTU：

```bash
sudo ip link set dev tun0 mtu 1280
```

但系统返回：

```text
Cannot find device "tun0"
```

这说明“会话输出里出现 Device 名称”和“当前 Linux 内核里确实存在该网络接口”不能简单等同。尤其是在以下状态下不能直接操作 `tun0`：

- 会话正在连接或断开
- 认证失败
- 会话已经结束但输出尚未刷新
- Wi-Fi 切换过程中连接状态正在变化

应先查看完整状态：

```bash
openvpn3 sessions-list
ip link show
```

只有当会话明确显示类似下面的状态时，才适合进一步检查 VPN 接口：

```text
Status: Connection, Client connected
```

因此最终快捷工具没有把 `tun0` 写死，也没有自动执行 MTU 修改。需要调 MTU 时，应先确认实际存在的接口：

```bash
ip -o link show
```

### 本次实际排查过程

本次实测经历了以下几个阶段：

1. 直接使用 `openvpn3 session-start` 和 `session-manage --disconnect`，命令过长且每次需要处理认证输入。
2. 看到会话信息里的 `Device: tun0` 后尝试修改 MTU，但内核返回设备不存在，因此确认不能只依据会话文本操作接口。
3. 增加 `vpn setup`、`vpn-up` 和 `vpn-down` helper，并将凭据保存到系统密钥环。
4. 第一次 `vpn-up` 能够启动后台会话，但状态显示 `Client authentication failed`。同时，早期 helper 因为没有兼容 `Config name:` 前面的空格，`vpn-down` 误报没有会话。
5. 修正会话解析后，`vpn-down` 可以正常清理失败会话；重新执行 `vpn setup` 录入正确密码后，连接流程恢复正常。

因此，遇到“后台启动成功但不能访问网络”时，必须继续查看 `vpn-status` 的具体状态，不能仅依据 `Session is running in the background` 判断连接已经成功。

Wi-Fi 切换时，推荐先断开，再切换网络，最后重新连接：

```bash
vpn-down
# 切换 Wi-Fi
vpn-up
```

## 5. 用户名和密码的处理方式

OpenVPN 3 Linux 的 `session-start` 不提供适合直接写进脚本的用户名/密码参数，也不推荐使用 OpenVPN 2 风格的明文凭据文件。

最终方案使用 Linux Mint 的 Secret Service/GNOME Keyring：

- 配置名称保存在：`~/.config/openvpn3-helper/profile`
- 配置文件权限：`0600`
- 用户名和密码保存在桌面系统密钥环
- 仓库、脚本和普通文本配置中不保存密码
- `vpn up` 时从密钥环读取凭据，并通过标准输入交给 OpenVPN 3

项目中的实现文件：

- [`bin/vpn`](../bin/vpn)
- [`scripts/common/19-openvpn-helper.sh`](../scripts/common/19-openvpn-helper.sh)

## 6. 安装快捷工具

在项目根目录执行：

```bash
./scripts/common/19-openvpn-helper.sh
```

该脚本会：

1. 检查 `openvpn3` 是否已安装。
2. 安装 `libsecret-tools`，提供 `secret-tool` 命令。
3. 将 `vpn` 安装到 `~/.local/bin/vpn`。
4. 创建以下快捷入口：
   - `~/.local/bin/vpn-up`
   - `~/.local/bin/vpn-down`
   - `~/.local/bin/vpn-restart`
   - `~/.local/bin/vpn-status`

确保 `~/.local/bin` 已经在 zsh 的 PATH 中：

```bash
command -v vpn
```

如果当前终端尚未刷新 PATH，可以重新打开终端，或执行：

```bash
source ~/.zshrc
```

## 7. 首次保存凭据

只需执行一次：

```bash
vpn setup
```

当只有一个 OpenVPN 配置时，脚本会自动选择它。对于本例，默认用户名会从配置名 `hefei@34.204.18.69` 推导为 `hefei`：

```text
VPN username [hefei]:
VPN password:
```

用户名直接按 Enter 即可使用默认值；密码只在这一步输入一次。

如果系统中有多个配置，可以显式指定：

```bash
vpn setup 'hefei@34.204.18.69'
```

也可以显式指定用户名：

```bash
vpn setup 'hefei@34.204.18.69' hefei
```

## 8. 日常使用

连接：

```bash
vpn-up
```

等价写法：

```bash
vpn up
```

断开：

```bash
vpn-down
```

等价写法：

```bash
vpn down
```

查看状态：

```bash
vpn-status
```

重启连接：

```bash
vpn-restart
```

等价写法：

```bash
vpn restart
```

删除已保存的配置名称和密钥环凭据：

```bash
vpn forget
```

删除后再次连接前需要重新执行 `vpn setup`。

## 9. 常见输出和处理方式

### 8.1 已经有连接

```text
[vpn] a session already exists for hefei@34.204.18.69
```

这是保护逻辑，避免重复创建相同配置的会话。用下面的命令查看现有会话：

```bash
vpn-status
```

### 8.2 没有会话

```text
[vpn] no session exists for hefei@34.204.18.69
```

表示当前没有匹配该配置的 OpenVPN 3 会话，通常不需要额外处理。

### 8.3 认证失败

```text
Client authentication failed: Authentication failed
```

重新输入凭据：

```bash
vpn setup
vpn-up
```

认证失败时，不要通过修改脚本或把密码写入命令行来排查。

### 8.4 密钥环被锁定

如果 `secret-tool` 无法读取凭据，先在桌面环境中解锁 Login Keyring，再执行：

```bash
vpn-up
```

如果需要完全重置：

```bash
vpn forget
vpn setup
```

### 8.5 `vpn-down` 找不到已有会话

早期版本按 `Config name:` 行必须从行首开始匹配，但 OpenVPN 3 实际输出会在该字段前保留空格，例如：

```text
 Config name: hefei@34.204.18.69
```

当前版本已经兼容前导空格。如果本机仍使用旧版本 helper，重新运行：

```bash
./scripts/common/19-openvpn-helper.sh
```

## 10. 最终推荐工作流

日常连接：

```bash
vpn-up
vpn-status
```

切换 Wi-Fi：

```bash
vpn-down
# 完成 Wi-Fi 切换
vpn-up
```

确认不再使用 VPN：

```bash
vpn-down
```

不建议把下面这类长命令继续写入 shell 历史或复制到多个脚本中：

```bash
openvpn3 session-start --config 'hefei@34.204.18.69'
```

统一使用 helper 可以集中处理配置名、密钥环凭据、重复连接和会话状态。

## 11. 相关官方资料

- [OpenVPN 3 Linux Quick Start](https://github.com/OpenVPN/openvpn3-linux/blob/master/QUICK-START.md)
- [OpenVPN 3 Linux 与 `auth-user-pass`](https://blog.openvpn.net/openvpn-3-linux-and-auth-user-pass/)
- [OpenVPN 3 Linux systemd session 管理](https://github.com/OpenVPN/openvpn3-linux/blob/master/docs/man/openvpn3-systemd.8.rst)
