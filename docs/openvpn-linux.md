# OpenVPN 3 辅助工具

本项目保留一个可选的 OpenVPN 3 命令行辅助工具。它要求系统已经安装
`openvpn3`，并且当前用户会话中存在可用、已解锁的 Secret Service 密钥环。
它不负责安装 VPN 客户端或配置密钥环服务，也不会由 bootstrap 默认安装。

在 WSL 或 OrbStack 中，应先确认客户机中的用户会话能访问该密钥环；宿主机
上的密钥环不能直接视为客户机的凭据存储。

## 安装

在受支持的 Ubuntu 客户机中执行：

```bash
./scripts/common/19-openvpn-helper.sh
```

安装器检查已有的 OpenVPN 3，必要时安装提供 `secret-tool` 的
`libsecret-tools`，然后将 `vpn` 和快捷入口安装到 `~/.local/bin`。

## 配置与凭据

先导入自己的 VPN 配置：

```bash
openvpn3 config-import --config /path/to/client.ovpn --name work-vpn --persistent
openvpn3 configs-list
vpn setup work-vpn YOUR_USERNAME
```

当只有一个已导入配置时，也可以直接执行 `vpn setup`。用户名和密码通过
交互输入保存到系统密钥环；配置名称保存在
`~/.config/openvpn3-helper/profile`，文件权限为 `0600`。

连接时，辅助工具从密钥环读取凭据，再通过标准输入交给 OpenVPN 3。
密码不会保存在仓库或普通文本配置中。

项目更名为 `linux-dev-template` 后，配置路径和密钥环存储标识继续沿用原值，
已有凭据可以继续读取，无需因更名重新执行 `vpn setup`。

## 日常命令

| 操作 | 命令 | 快捷入口 |
|---|---|---|
| 连接 | `vpn up` | `vpn-up` |
| 断开 | `vpn down` | `vpn-down` |
| 查看状态 | `vpn status` | `vpn-status` |
| 重启连接 | `vpn restart` | `vpn-restart` |

修改凭据时重新执行 `vpn setup`。使用 `vpn forget` 删除保存的配置名称和
密钥环凭据；它不会删除 OpenVPN 3 已导入的 VPN 配置。

如果提示已有会话，可用 `vpn status` 检查；如果认证失败，重新运行
`vpn setup`。如果无法读取凭据，先检查同一用户会话中的 Secret Service
是否可访问、密钥环是否已解锁。

实现位于 [bin/vpn](../bin/vpn) 和
[安装脚本](../scripts/common/19-openvpn-helper.sh)。
