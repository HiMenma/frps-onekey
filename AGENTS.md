# AGENTS.md - 项目上下文文档

## 项目概述

**frps-onekey** 是一个用于 Linux 服务器的 FRP (Fast Reverse Proxy) 服务端一键安装配置脚本。该项目通过自动化脚本简化了 FRP 服务端的部署流程，支持自动获取最新版本的 FRP 并进行交互式配置。

- **项目类型**: Shell 脚本项目（Linux 系统管理工具）
- **主要用途**: 内网穿透、反向代理服务端部署
- **支持系统**: CentOS、Debian、Ubuntu、Fedora、RHEL、Rocky、AlmaLinux（32位/64位）
- **当前版本**: 1.0.7

### 核心技术

- **FRP (Fast Reverse Proxy)**: 高性能反向代理应用，支持 TCP、HTTP、HTTPS、QUIC、KCP 等协议
- **Shell Script (Bash)**: 自动化安装和配置脚本
- **TOML 配置格式**: FRP 服务端配置文件使用 TOML 格式（frps.toml）

## 目录结构

```
frps-onekey/
├── install-frps.sh      # 主安装脚本（核心文件）
├── frps.init            # FRP 服务管理脚本（init.d 服务脚本）
├── generate-certs.sh    # TLS 证书生成脚本
├── README.md            # 项目说明文档
├── LICENSE              # 许可证文件
└── CODE_OF_CONDUCT.md   # 行为准则
```

## 核心文件说明

### 1. install-frps.sh（主安装脚本）

脚本版本：1.0.7

**主要功能**：
- 自动检测服务器操作系统和架构
- 从 GitHub 或 Gitee 下载最新版 FRP
- 交互式配置 FRP 服务参数
- 安装 FRP 服务并配置开机自启
- 支持更新和卸载功能

**关键变量**：
```bash
program_name="frps"
str_program_dir="/usr/local/frps"          # FRP 安装目录
program_init="/etc/init.d/frps"            # 服务脚本路径
program_config_file="frps.toml"            # 配置文件名
```

**使用方法**：
```bash
# 安装
./install-frps.sh install

# 卸载
./install-frps.sh uninstall

# 更新
./install-frps.sh update
```

### 2. frps.init（服务管理脚本）

**功能**：管理 FRP 服务的启动、停止、重启等操作

**使用方法**：
```bash
/etc/init.d/frps {start|stop|restart|status|config|version}
```

**关键路径**：
- 程序路径：`/usr/local/frps/frps`
- 配置文件：`/usr/local/frps/frps.toml`

### 3. generate-certs.sh（证书生成脚本）

**功能**：生成 FRP TLS 加密通信所需的证书

**生成的证书存放位置**：
```
/etc/pki/tls/frp/
├── ca/           # CA 证书
│   ├── ca.key
│   └── ca.crt
├── frps/         # 服务端证书
│   ├── server.key
│   ├── server.csr
│   └── server.crt
└── frpc/         # 客户端证书
    ├── client.key
    ├── client.csr
    └── client.crt
```

## 配置参数说明

安装时可配置的主要参数（带默认值）：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| bind_port | 5443 | FRP 服务绑定端口 |
| vhost_http_port | 80 | HTTP 虚拟主机端口 |
| vhost_https_port | 443 | HTTPS 虚拟主机端口 |
| dashboard_port | 6443 | 控制面板端口 |
| dashboard_user | admin | 控制面板用户名 |
| dashboard_pwd | 随机8位 | 控制面板密码 |
| token | 随机16位 | 客户端连接令牌 |
| subdomain_host | 服务器IP | 子域名主机 |
| max_pool_count | 5 | 最大连接池数量 |
| log_level | info | 日志级别 |
| log_max_days | 3 | 日志保留天数 |
| tcp_mux | true | TCP 多路复用 |
| kcp_bind_port | 同 bind_port | KCP 协议端口 |
| quic_bind_port | 同 vhost_https_port | QUIC 协议端口 |

## 支持的操作系统

- CentOS
- Debian
- Ubuntu
- Fedora
- RHEL (Red Hat Enterprise Linux)
- Rocky Linux
- AlmaLinux

## 支持的 CPU 架构

- x86_64 (amd64)
- i386/i486/i586/i686 (386)
- aarch64 (arm64)
- arm/armv*
- mips/mips64/mips64el/mipsel
- riscv64

## 开发规范

### Shell 脚本风格

1. **变量命名**：使用下划线命名法（snake_case）
   ```bash
   def_server_port="5443"
   input_dashboard_port=""
   ```

2. **函数命名**：使用 `fun_` 前缀表示函数
   ```bash
   fun_frps() { ... }
   fun_check_port() { ... }
   ```

3. **颜色输出**：定义颜色变量用于终端输出美化
   ```bash
   COLOR_RED='\E[1;31m'
   COLOR_GREEN='\E[1;32m'
   COLOR_END='\E[0m'
   ```

4. **错误处理**：关键操作需要检查返回值
   ```bash
   if [ $? -ne 0 ]; then
       echo -e " ${COLOR_RED}failed${COLOR_END}"
       exit 1
   fi
   ```

### 配置文件格式

FRP 配置文件使用 TOML 格式，示例：
```toml
bindAddr = "0.0.0.0"
bindPort = 5443

webServer.addr = "0.0.0.0"
webServer.port = 6443
webServer.user = "admin"
webServer.password = "your_password"
```

## 常用命令

### 服务管理
```bash
# 启动服务
/etc/init.d/frps start

# 停止服务
/etc/init.d/frps stop

# 重启服务
/etc/init.d/frps restart

# 查看状态
/etc/init.d/frps status

# 编辑配置
/etc/init.d/frps config

# 查看版本
/etc/init.d/frps version
```

### 安装和更新
```bash
# 从 GitHub 安装
wget https://raw.githubusercontent.com/mvscode/frps-onekey/master/install-frps.sh -O ./install-frps.sh
chmod 700 ./install-frps.sh
./install-frps.sh install

# 从 Gitee 安装（国内用户）
wget https://gitee.com/mvscode/frps-onekey/raw/master/install-frps.sh -O ./install-frps.sh
chmod 700 ./install-frps.sh
./install-frps.sh install
```

## 项目来源

- **原作者**: clangcn
- **维护者**: MvsCode (HiMenma)
- **FRP 核心项目**: [fatedier/frp](https://github.com/fatedier/frp)
- **脚本仓库**: [mvscode/frps-onekey](https://github.com/mvscode/frps-onekey)

## 注意事项

1. **权限要求**：脚本必须以 root 用户运行
2. **网络要求**：需要能够访问 GitHub 或 Gitee 下载 FRP 程序
3. **防火墙配置**：确保相关端口（bind_port、dashboard_port 等）已开放
4. **SELinux**：脚本会自动禁用 SELinux
5. **依赖工具**：需要 wget、killall、netstat 等工具（脚本会自动安装）
