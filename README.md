# FRP 一键配置脚本

[![GitHub Repo][repo-shield]][repo-url]
[![Stars][stars-shield]][stars-url]
[![Forks][forks-shield]][forks-url]
[![License][license-shield]][license-url]

[repo-shield]: https://img.shields.io/badge/GitHub-HiMenma%2Ffrps--onekey-brightgreen?style=flat-square&logo=github
[repo-url]: https://github.com/HiMenma/frps-onekey
[stars-shield]: https://img.shields.io/github/stars/HiMenma/frps-onekey.svg?style=flat-square&logo=github&color=yellow
[stars-url]: https://github.com/HiMenma/frps-onekey/stargazers
[forks-shield]: https://img.shields.io/github/forks/HiMenma/frps-onekey.svg?style=flat-square&logo=github&color=green
[forks-url]: https://github.com/HiMenma/frps-onekey/network/members
[license-shield]: https://img.shields.io/github/license/HiMenma/frps-onekey.svg?style=flat-square
[license-url]: https://github.com/HiMenma/frps-onekey/blob/master/LICENSE

**Frp** 是一个高性能的反向代理应用，可以帮助您轻松地进行内网穿透，对外网提供服务，支持 TCP、UDP、HTTP、HTTPS 等协议类型，并且 Web 服务支持根据域名进行路由转发。

本项目提供 **服务端** 和 **客户端** 一键配置脚本，自动获取 Frp 最新版本，支持交互式配置。

## 目录

- [支持系统](#支持系统)
- [服务端配置 (frps)](#服务端配置-frps)
- [客户端配置 (frpc)](#客户端配置-frpc)
- [代理类型说明](#代理类型说明)
- [配置文件示例](#配置文件示例)
- [更新日志](#更新日志)

---

## 支持系统

| 操作系统 | 支持状态 |
|---------|---------|
| CentOS | ✅ |
| RHEL | ✅ |
| Fedora | ✅ |
| Rocky Linux | ✅ |
| AlmaLinux | ✅ |
| Debian | ✅ |
| Ubuntu | ✅ |

**支持架构**: x86_64, i386, arm64, arm, mips, mips64, riscv64

---

## 服务端配置 (frps)

### 安装

**从 GitHub 安装:**
```bash
wget https://raw.githubusercontent.com/HiMenma/frps-onekey/master/install-frps.sh -O ./install-frps.sh
chmod 700 ./install-frps.sh
./install-frps.sh install
```

**从 Gitee 安装 (国内用户推荐):**
```bash
wget https://gitee.com/mvscode/frps-onekey/raw/master/install-frps.sh -O ./install-frps.sh
chmod 700 ./install-frps.sh
./install-frps.sh install
```

### 卸载
```bash
./install-frps.sh uninstall
```

### 更新
```bash
./install-frps.sh update
```

### 服务管理
```bash
# 方式一：使用 init.d 脚本
/etc/init.d/frps {start|stop|restart|status|config|version}

# 方式二：使用快捷命令
frps {start|stop|restart|status|config|version}
```

### 默认端口说明

| 配置项 | 默认值 | 说明 |
|-------|--------|------|
| bind_port | 5443 | Frp 服务端口 |
| vhost_http_port | 80 | HTTP 虚拟主机端口 |
| vhost_https_port | 443 | HTTPS 虚拟主机端口 |
| dashboard_port | 6443 | 控制面板端口 |
| kcp_bind_port | 5443 | KCP 协议端口 |
| quic_bind_port | 443 | QUIC 协议端口 |

---

## 客户端配置 (frpc)

### 安装

**从 GitHub 安装:**
```bash
wget https://raw.githubusercontent.com/HiMenma/frps-onekey/master/install-frpc.sh -O ./install-frpc.sh
chmod 700 ./install-frpc.sh
./install-frpc.sh install
```

### 安装交互流程

1. 选择下载源 (GitHub)
2. 输入服务器地址 (frps 服务器 IP 或域名)
3. 输入服务器端口 (默认: 5443)
4. 输入认证 Token (与服务端一致)
5. 选择日志级别 (info / warn / error / debug / trace)
6. 配置代理 (可选，支持配置多个代理)

### 卸载
```bash
./install-frpc.sh uninstall
```

### 更新
```bash
./install-frpc.sh update
```

### 编辑配置
```bash
./install-frpc.sh config
```

### 服务管理
```bash
# 方式一：使用 init.d 脚本
/etc/init.d/frpc {start|stop|restart|status|config|version}

# 方式二：使用快捷命令
frpc {start|stop|restart|status|config|version}
```

---

## 代理类型说明

客户端支持以下代理类型：

| 类型 | 说明 | 适用场景 |
|------|------|---------|
| **TCP** | TCP 端口转发 | SSH 远程连接、数据库访问等 |
| **UDP** | UDP 端口转发 | DNS 服务、游戏服务器等 |
| **HTTP** | HTTP 协议代理 | Web 网站、API 服务 |
| **HTTPS** | HTTPS 协议代理 | 安全 Web 服务 |
| **STCP** | 密钥 TCP | 需要访问密钥的安全 TCP 连接 |
| **XTCP** | P2P TCP | 点对点传输，降低服务器流量 |
| **SUDP** | 密钥 UDP | 需要访问密钥的安全 UDP 连接 |

---

## 配置文件示例

### 服务端配置 (frps.toml)

```toml
bindAddr = "0.0.0.0"
bindPort = 5443

# KCP 协议端口
kcpBindPort = 5443

# QUIC 协议端口
quicBindPort = 443

# HTTP/HTTPS 虚拟主机端口
vhostHTTPPort = 80
vhostHTTPSPort = 443

# 控制面板
webServer.addr = "0.0.0.0"
webServer.port = 6443
webServer.user = "admin"
webServer.password = "your_password"

# 认证
auth.method = "token"
auth.token = "your_token"

# 子域名
subDomainHost = "your-domain.com"

# 日志
log.to = "./frps.log"
log.level = "info"
log.maxDays = 3
```

### 客户端配置 (frpc.toml)

```toml
serverAddr = "your-server-ip"
serverPort = 5443

auth.method = "token"
auth.token = "your_token"

log.to = "./frpc.log"
log.level = "info"
log.maxDays = 3

# TCP 代理示例 - SSH 远程连接
[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6000

# HTTP 代理示例 - Web 服务
[[proxies]]
name = "web"
type = "http"
localIP = "127.0.0.1"
localPort = 80
customDomains = ["www.example.com"]

# STCP 代理示例 - 安全 TCP
[[proxies]]
name = "secret-ssh"
type = "stcp"
localIP = "127.0.0.1"
localPort = 22
secretKey = "your_secret_key"
```

### STCP/XTCP 访问端配置

对于 STCP 和 XTCP 类型，需要在访问端运行 frpc 并配置 visitor：

```toml
serverAddr = "your-server-ip"
serverPort = 5443

auth.method = "token"
auth.token = "your_token"

# STCP 访问端
[[visitors]]
name = "secret-ssh-visitor"
type = "stcp"
serverName = "secret-ssh"
secretKey = "your_secret_key"
bindAddr = "127.0.0.1"
bindPort = 6000
```

访问端连接后，通过 `127.0.0.1:6000` 即可访问远程 SSH。

---

## 相关链接

- **FRP 官方项目**: [fatedier/frp](https://github.com/fatedier/frp)
- **脚本原作者**: [clangcn/onekey-install-shell](https://github.com/clangcn/onekey-install-shell)
- **本项目**: [HiMenma/frps-onekey](https://github.com/HiMenma/frps-onekey)

---

## 更新日志

### [1.0.7] - 2024-07-24
#### Added
- 添加下载进度条显示 [Issue #101](https://github.com/mvscode/frps-onekey/issues/101)
#### Fixed
- 修复拼写错误

### [1.0.6] - 2024-06-25
#### Added
- 新增支持 RHEL、Rocky、AlmaLinux 操作系统
- 更新 frps.init 支持新系统

### [1.0.5] - 2024-06-19
#### Added
- 添加 QUIC 传输协议支持
- 添加用户自定义 KCP 绑定端口功能
#### Fixed
- 修复服务启动失败仍显示安装成功的 bug

### [1.0.4] - 2024-06-18
#### Updated
- 日志级别新增 trace 选项，默认为 info
- 更新脚本更新功能，询问用户是否更新
#### New
- frps 支持 transport.heartbeatTimeout = 90，默认启用

### [1.0.3] - 2024-06-16
#### Changed
- 修改函数名称为 frps
- 使用 wget 命令获取服务器 IP [Issue #117](https://github.com/mvscode/frps-onekey/issues/117)

### [1.0.2] - 2024-06-13
#### Updated
- 更新配置文件格式以适配最新 FRP 版本
  - `bind_addr` → `bindAddr`
  - `bind_port` → `bindPort`
  - `kcp_bind_port` → `kcpBindPort`
  - 等等...

### [1.0.1] - 2024-06-07
#### Changed
- 配置文件格式从 frps.ini 更改为 frps.toml

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.