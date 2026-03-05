#!/bin/bash

# Set the PATH variable
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Program information
program_name="frpc"
version="1.0.0"
str_program_dir="/usr/local/${program_name}"
program_init="/etc/init.d/${program_name}"
program_config_file="frpc.toml"
ver_file="/tmp/.frp_ver.sh"
str_install_shell="https://raw.githubusercontent.com/HiMenma/frps-onekey/master/install-frpc.sh"

# Download URLs
export gitee_download_url="https://gitee.com/mvscode/frps-onekey/releases/download"
export github_download_url="https://github.com/fatedier/frp/releases/download"
export gitee_latest_version_api="https://gitee.com/api/v5/repos/mvscode/frps-onekey/releases/latest"
export github_latest_version_api="https://api.github.com/repos/fatedier/frp/releases/latest"

# Global variables for proxy configuration
proxy_count=0
proxy_configs=""

# Function to display program banner
fun_frpc(){
    local clear_flag=""
    clear_flag=$1
    if [[ ${clear_flag} == "clear" ]]; then
        clear
    fi
    echo ""
    echo "+------------------------------------------------------------+"
    echo "|    frpc for Linux Client, Author Clang, Mender HiMenma     |" 
    echo "|      A tool to auto-compile & install frpc on Linux        |"
    echo "+------------------------------------------------------------+"
    echo ""
}

# Set text colors
fun_set_text_color(){
    COLOR_RED='\E[1;31m'
    COLOR_GREEN='\E[1;32m'
    COLOR_YELOW='\E[1;33m'
    COLOR_BLUE='\E[1;34m'
    COLOR_PINK='\E[1;35m'
    COLOR_PINKBACK_WHITEFONT='\033[45;37m'
    COLOR_GREEN_LIGHTNING='\033[32m \033[05m'
    COLOR_END='\E[0m'
}

# Check if user is root
rootness(){
    if [[ $EUID -ne 0 ]]; then
        fun_frpc
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}

# Get single character input
get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

# Check Server OS
checkos(){
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        OS=CentOS
    elif grep -Eqi "Red Hat Enterprise Linux" /etc/issue || grep -Eq "Red Hat Enterprise Linux" /etc/*-release; then
        OS=RHEL
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        OS=Fedora
    elif grep -Eqi "Rocky" /etc/issue || grep -Eq "Rocky" /etc/*-release; then
        OS=Rocky
    elif grep -Eqi "AlmaLinux" /etc/issue || grep -Eq "AlmaLinux" /etc/*-release; then
        OS=AlmaLinux
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OS=Debian
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OS=Ubuntu
    else
        echo "Unsupported OS. Please use a supported Linux distribution and retry!"
        exit 1
    fi
}

# Get OS version
getversion(){
    local version
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        version="$VERSION_ID"
    elif [[ -f /etc/redhat-release ]]; then
        version=$(grep -oE "[0-9.]+" /etc/redhat-release)
    else
        version=$(grep -oE "[0-9.]+" /etc/issue)
    fi

    if [[ -z "$version" ]]; then
        echo "Unable to determine version" >&2
        return 1
    else
        echo "$version"
    fi
}

# Check OS version
check_os_version(){
    local required_version=$1
    local current_version=$(getversion)
    
    if [[ "$(echo -e "$current_version\n$required_version" | sort -V | head -n1)" == "$required_version" ]]; then
        return 0
    else
        return 1
    fi
}

# Check OS architecture
check_os_bit() {
    local arch
    arch=$(uname -m)

    case $arch in
        x86_64)      Is_64bit='y'; ARCHS="amd64";;
        i386|i486|i586|i686) Is_64bit='n'; ARCHS="386"; FRPS_VER="$FRPS_VER_32BIT";;
        aarch64)     Is_64bit='y'; ARCHS="arm64";;
        arm*|armv*)  Is_64bit='n'; ARCHS="arm"; FRPS_VER="$FRPS_VER_32BIT";;
        mips)        Is_64bit='n'; ARCHS="mips"; FRPS_VER="$FRPS_VER_32BIT";;
        mips64)      Is_64bit='y'; ARCHS="mips64";;
        mips64el)    Is_64bit='y'; ARCHS="mips64le";;
        mipsel)      Is_64bit='n'; ARCHS="mipsle"; FRPS_VER="$FRPS_VER_32BIT";;
        riscv64)     Is_64bit='y'; ARCHS="riscv64";;
        *)           echo "Unknown architecture";;
    esac
}

# Disable selinux
disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

# Install required packages
pre_install_packs(){
    local wget_flag=''
    local killall_flag=''
    local netstat_flag=''
    wget --version > /dev/null 2>&1
    wget_flag=$?
    killall -V >/dev/null 2>&1
    killall_flag=$?
    netstat --version >/dev/null 2>&1
    netstat_flag=$?
    if [[ ${wget_flag} -gt 1 ]] || [[ ${killall_flag} -gt 1 ]] || [[ ${netstat_flag} -gt 6 ]];then
        echo -e "${COLOR_GREEN} Install support packs...${COLOR_END}"
        if [ "${OS}" == 'CentOS' ] || [ "${OS}" == 'RHEL' ] || [ "${OS}" == 'Fedora' ] || [ "${OS}" == 'Rocky' ] || [ "${OS}" == 'AlmaLinux' ]; then
            yum install -y wget psmisc net-tools
        else
            apt-get -y update && apt-get -y install wget psmisc net-tools
        fi
    fi
}

# Generate random string
fun_randstr(){
    strNum=$1
    [ -z "${strNum}" ] && strNum="16"
    strRandomPass=""
    strRandomPass=`tr -cd '[:alnum:]' < /dev/urandom | fold -w ${strNum} | head -n1`
    echo ${strRandomPass}
}

# Select download server
fun_getServer(){
    def_server_url="github"
    echo ""
    echo -e "Please select ${COLOR_PINK}${program_name} download${COLOR_END} url:"
    echo -e "[1].gitee"
    echo -e "[2].github (default)"
    read -e -p "Enter your choice (1, 2 or exit. default [${def_server_url}]): " set_server_url
    [ -z "${set_server_url}" ] && set_server_url="${def_server_url}"
    case "${set_server_url}" in
        1|[Ga][Ii][Tt][Ee][Ee])
            program_download_url=${gitee_download_url};
            choice=1
            ;;
        2|[Gg][Ii][Tt][Hh][Uu][Bb])
            program_download_url=${github_download_url};
            choice=2
            ;;
        [eE][xX][iI][tT])
            exit 1
            ;;
        *)
            program_download_url=${github_download_url}
            ;;
    esac
    echo    "-----------------------------------"
    echo -e "       Your select: ${COLOR_YELOW}${set_server_url}${COLOR_END}    "
    echo    "-----------------------------------"
}

# Get latest version
fun_getVer(){
    echo -e "Loading network version for ${program_name}, please wait..."
    case $choice in
        1)  LATEST_RELEASE=$(curl -s ${gitee_latest_version_api} | grep -oP '"tag_name":\Kv[^"]+' | cut -c2-);;
        2)  LATEST_RELEASE=$(curl -s ${github_latest_version_api} | grep '"tag_name":' | cut -d '"' -f 4 | cut -c 2-);;
    esac
    if [[ ! -z "$LATEST_RELEASE" ]]; then
        FRPC_VER="$LATEST_RELEASE"
        echo "FRPC_VER set to: $FRPC_VER"
    else
        echo "Failed to retrieve the latest version."
    fi
    program_latest_filename="frp_${FRPC_VER}_linux_${ARCHS}.tar.gz"
    program_latest_file_url="${program_download_url}/v${FRPC_VER}/${program_latest_filename}"
    if [ -z "${program_latest_filename}" ]; then
        echo -e "${COLOR_RED}Load network version failed!!!${COLOR_END}"
    else
        echo -e "${program_name} Latest release file ${COLOR_GREEN}${program_latest_filename}${COLOR_END}"
    fi
}

# Download progress bar
show_progress() {
    local TOTAL_SIZE=1000000
    local CURRENT_SIZE=0
    local GREEN='\033[1;32m'
    local NC='\033[0m'

    while [ $CURRENT_SIZE -lt $TOTAL_SIZE ] || [ $PERCENTAGE -lt 100 ]; do
        PERCENTAGE=$(awk "BEGIN {printf \"%.0f\", $CURRENT_SIZE*100/$TOTAL_SIZE}")

        if ! [[ "$PERCENTAGE" =~ ^[0-9]+$ ]] ; then
            PERCENTAGE=0
        fi

        local completed=$((PERCENTAGE / 2))
        local remaining=$((50 - completed))

        if [ $PERCENTAGE -eq 100 ]; then
            completed=50
            remaining=0
        fi

        printf "\r${GREEN}%2d%% [" "$PERCENTAGE"
        for ((i = 0; i < completed; i++)); do
            if [ $i -eq $((completed - 1)) ]; then
                printf ">"
            else
                printf "="
            fi
        done
        for ((i = 0; i < remaining; i++)); do
            printf " "
        done
        printf "]${NC}"

        CURRENT_SIZE=$((CURRENT_SIZE + $((RANDOM % 50000 + 1))))
        sleep 0.05
    done

    echo -e "\nDownload complete!"
}

# Download frpc files
fun_download_file(){
    if [ ! -s ${str_program_dir}/${program_name} ]; then
        rm -fr ${program_latest_filename} frp_${FRPC_VER}_linux_${ARCHS}
        echo -e "Downloading ${program_name}..."
        echo ""
        curl -L --progress-bar "${program_latest_file_url}" -o "${program_latest_filename}" 2>&1 | show_progress
        echo ""        
        if [ $? -ne 0 ]; then
            echo -e " ${COLOR_RED}Download failed${COLOR_END}"
            exit 1
        fi
        
        if [ ! -s ${program_latest_filename} ]; then
            echo -e " ${COLOR_RED}Downloaded file is empty or not found${COLOR_END}"
            exit 1
        fi
        
        echo -e "Extracting ${program_name}..."
        echo ""
        
        tar xzf ${program_latest_filename}
        mv frp_${FRPC_VER}_linux_${ARCHS}/frpc ${str_program_dir}/${program_name}
        rm -fr ${program_latest_filename} frp_${FRPC_VER}_linux_${ARCHS}
    fi
    
    chown root:root -R ${str_program_dir}
    if [ -s ${str_program_dir}/${program_name} ]; then
        [ ! -x ${str_program_dir}/${program_name} ] && chmod 755 ${str_program_dir}/${program_name}
    else
        echo -e " ${COLOR_RED}failed${COLOR_END}"
        exit 1
    fi
}

# Check port availability
fun_check_port(){
    port_flag=""
    strCheckPort=""
    input_port=""
    port_flag="$1"
    strCheckPort="$2"
    if [ ${strCheckPort} -ge 1 ] && [ ${strCheckPort} -le 65535 ]; then
        checkServerPort=`netstat -ntulp | grep "\b:${strCheckPort}\b"`
        if [ -n "${checkServerPort}" ]; then
            echo ""
            echo -e "${COLOR_RED}Error:${COLOR_END} Port ${COLOR_GREEN}${strCheckPort}${COLOR_END} is ${COLOR_PINK}used${COLOR_END},view relevant port:"
            netstat -ntulp | grep "\b:${strCheckPort}\b"
            fun_input_${port_flag}_port
        else
            input_port="${strCheckPort}"
        fi
    else
        echo "Input error! Please input correct numbers."
        fun_input_${port_flag}_port
    fi
}

# Check number input
fun_check_number(){
    num_flag=""
    strMaxNum=""
    strCheckNum=""
    input_number=""
    num_flag="$1"
    strMaxNum="$2"
    strCheckNum="$3"
    if [ ${strCheckNum} -ge 1 ] && [ ${strCheckNum} -le ${strMaxNum} ]; then
        input_number="${strCheckNum}"
    else
        echo "Input error! Please input correct numbers."
        fun_input_${num_flag}
    fi
}

#========================================
# Interactive input functions for server connection
#========================================

fun_input_server_addr(){
    echo ""
    echo -n -e "Please input ${COLOR_GREEN}frps server address${COLOR_END}"
    read -e -p "(Example: 1.2.3.4 or domain.com): " input_server_addr
    [ -z "${input_server_addr}" ] && fun_input_server_addr
    set_server_addr="${input_server_addr}"
    echo -e "Server address: ${COLOR_YELOW}${set_server_addr}${COLOR_END}"
}

fun_input_server_port(){
    def_server_port="5443"
    echo ""
    echo -n -e "Please input ${COLOR_GREEN}frps server port${COLOR_END} [1-65535]"
    read -e -p "(Default Server Port: ${def_server_port}):" input_server_port
    [ -z "${input_server_port}" ] && input_server_port="${def_server_port}"
    set_server_port="${input_server_port}"
    echo -e "Server port: ${COLOR_YELOW}${set_server_port}${COLOR_END}"
}

fun_input_token(){
    def_token=`fun_randstr 16`
    echo ""
    echo -n -e "Please input ${COLOR_GREEN}token${COLOR_END} (same as server)"
    read -e -p "(Default : ${def_token}):" input_token
    [ -z "${input_token}" ] && input_token="${def_token}"
    set_token="${input_token}"
    echo -e "Token: ${COLOR_YELOW}${set_token}${COLOR_END}"
}

fun_input_log_max_days(){
    def_max_days="15"
    def_log_max_days="3"
    echo ""
    echo -e "Please input ${COLOR_GREEN}log_max_days${COLOR_END} [1-${def_max_days}]"
    read -e -p "(Default : ${def_log_max_days} day):" input_log_max_days
    [ -z "${input_log_max_days}" ] && input_log_max_days="${def_log_max_days}"
    fun_check_number "log_max_days" "${def_max_days}" "${input_log_max_days}"
    [ -n "${input_number}" ] && set_log_max_days="${input_number}"
    echo -e "log_max_days: ${COLOR_YELOW}${set_log_max_days}${COLOR_END}"
}

#========================================
# Interactive input functions for proxy configuration
#========================================

# Proxy type selection menu
fun_select_proxy_type(){
    echo ""
    echo -e "Please select ${COLOR_GREEN}proxy type${COLOR_END}"
    echo    "1: tcp    (TCP port forwarding)"
    echo    "2: udp    (UDP port forwarding)"
    echo    "3: http   (HTTP protocol)"
    echo    "4: https  (HTTPS protocol)"
    echo    "5: stcp   (Secret TCP, need visitor)"
    echo    "6: xtcp   (P2P TCP, need visitor)"
    echo    "7: sudp   (Secret UDP, need visitor)"
    echo    "-------------------------"
    read -e -p "Enter your choice (1-7, or exit. default [1]): " str_proxy_type
    case "${str_proxy_type}" in
        1|[Tt][Cc][Pp])
            proxy_type="tcp"
            ;;
        2|[Uu][Dd][Pp])
            proxy_type="udp"
            ;;
        3|[Hh][Tt][Tt][Pp])
            proxy_type="http"
            ;;
        4|[Hh][Tt][Tt][Pp][Ss])
            proxy_type="https"
            ;;
        5|[Ss][Tt][Cc][Pp])
            proxy_type="stcp"
            ;;
        6|[Xx][Tt][Cc][Pp])
            proxy_type="xtcp"
            ;;
        7|[Ss][Uu][Dd][Pp])
            proxy_type="sudp"
            ;;
        [eE][xX][iI][tT])
            exit 1
            ;;
        *)
            proxy_type="tcp"
            ;;
    esac
    echo -e "Proxy type: ${COLOR_YELOW}${proxy_type}${COLOR_END}"
}

# Input proxy name
fun_input_proxy_name(){
    def_proxy_name="${proxy_type}_proxy_${proxy_count}"
    echo ""
    echo -n -e "Please input ${COLOR_GREEN}proxy name${COLOR_END}"
    read -e -p "(Default : ${def_proxy_name}):" input_proxy_name
    [ -z "${input_proxy_name}" ] && input_proxy_name="${def_proxy_name}"
    proxy_name="${input_proxy_name}"
    echo -e "Proxy name: ${COLOR_YELOW}${proxy_name}${COLOR_END}"
}

# Input local IP
fun_input_local_ip(){
    def_local_ip="127.0.0.1"
    echo ""
    echo -n -e "Please input ${COLOR_GREEN}local IP${COLOR_END}"
    read -e -p "(Default : ${def_local_ip}):" input_local_ip
    [ -z "${input_local_ip}" ] && input_local_ip="${def_local_ip}"
    local_ip="${input_local_ip}"
    echo -e "Local IP: ${COLOR_YELOW}${local_ip}${COLOR_END}"
}

# Input local port
fun_input_local_port(){
    echo ""
    echo -n -e "Please input ${COLOR_GREEN}local port${COLOR_END} [1-65535]"
    read -e -p ":" input_local_port
    [ -z "${input_local_port}" ] && fun_input_local_port
    local_port="${input_local_port}"
    echo -e "Local port: ${COLOR_YELOW}${local_port}${COLOR_END}"
}

# Input remote port (for TCP/UDP)
fun_input_remote_port(){
    echo ""
    echo -n -e "Please input ${COLOR_GREEN}remote port${COLOR_END} [1-65535]"
    read -e -p "(port on frps server):" input_remote_port
    [ -z "${input_remote_port}" ] && fun_input_remote_port
    remote_port="${input_remote_port}"
    echo -e "Remote port: ${COLOR_YELOW}${remote_port}${COLOR_END}"
}

# Input custom domain (for HTTP/HTTPS)
fun_input_custom_domain(){
    echo ""
    echo -n -e "Please input ${COLOR_GREEN}custom domain${COLOR_END}"
    read -e -p "(Example: www.example.com):" input_custom_domain
    [ -z "${input_custom_domain}" ] && fun_input_custom_domain
    custom_domain="${input_custom_domain}"
    echo -e "Custom domain: ${COLOR_YELOW}${custom_domain}${COLOR_END}"
}

# Input subdomain (for HTTP/HTTPS)
fun_input_subdomain(){
    echo ""
    echo -n -e "Please input ${COLOR_GREEN}subdomain${COLOR_END}"
    read -e -p "(Example: myapp, will be myapp.server_domain):" input_subdomain
    subdomain="${input_subdomain}"
    echo -e "Subdomain: ${COLOR_YELOW}${subdomain}${COLOR_END}"
}

# Input secret key (for STCP/XTCP/SUDP)
fun_input_secret_key(){
    def_secret_key=`fun_randstr 16`
    echo ""
    echo -n -e "Please input ${COLOR_GREEN}secret key${COLOR_END}"
    read -e -p "(Default : ${def_secret_key}):" input_secret_key
    [ -z "${input_secret_key}" ] && input_secret_key="${def_secret_key}"
    secret_key="${input_secret_key}"
    echo -e "Secret key: ${COLOR_YELOW}${secret_key}${COLOR_END}"
}

# Configure a single proxy
fun_configure_proxy(){
    echo ""
    echo -e "${COLOR_PINK}========== Configure Proxy #$((${proxy_count}+1)) ==========${COLOR_END}"
    
    fun_select_proxy_type
    fun_input_proxy_name
    fun_input_local_ip
    fun_input_local_port
    
    case "${proxy_type}" in
        tcp|udp)
            fun_input_remote_port
            proxy_config=$'\n[[proxies]]\n'"name = \"${proxy_name}\""$'\n'"type = \"${proxy_type}\""$'\n'"localIP = \"${local_ip}\""$'\n'"localPort = ${local_port}"$'\n'"remotePort = ${remote_port}"$'\n'
            ;;
        http|https)
            echo ""
            echo -e "Please select ${COLOR_GREEN}domain type${COLOR_END}"
            echo    "1: custom domain"
            echo    "2: subdomain"
            read -e -p "Enter your choice (1 or 2, default [1]): " domain_type
            case "${domain_type}" in
                2)
                    fun_input_subdomain
                    domain_config="subdomain = \"${subdomain}\""
                    ;;
                *)
                    fun_input_custom_domain
                    domain_config="customDomains = [\"${custom_domain}\"]"
                    ;;
            esac
            proxy_config=$'\n[[proxies]]\n'"name = \"${proxy_name}\""$'\n'"type = \"${proxy_type}\""$'\n'"localIP = \"${local_ip}\""$'\n'"localPort = ${local_port}"$'\n'"${domain_config}"$'\n'
            ;;
        stcp|xtcp|sudp)
            fun_input_secret_key
            proxy_config=$'\n[[proxies]]\n'"name = \"${proxy_name}\""$'\n'"type = \"${proxy_type}\""$'\n'"localIP = \"${local_ip}\""$'\n'"localPort = ${local_port}"$'\n'"secretKey = \"${secret_key}\""$'\n'
            ;;
    esac
    
    proxy_configs="${proxy_configs}${proxy_config}"
    proxy_count=$((${proxy_count}+1))
    
    echo ""
    echo -e "${COLOR_GREEN}Proxy '${proxy_name}' added successfully!${COLOR_END}"
}

# Ask if user wants to add more proxies
fun_ask_add_more(){
    echo ""
    echo -n -e "${COLOR_GREEN}Add another proxy?${COLOR_END} [y/N]"
    read -e -p ": " add_more
    case "${add_more}" in
        y|Y|yes|YES)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Main proxy configuration loop
fun_configure_proxies(){
    echo ""
    echo -e "${COLOR_PINK}========== Proxy Configuration ==========${COLOR_END}"
    echo -e "You can configure one or more proxies now."
    echo -e "Supported types: ${COLOR_GREEN}TCP, UDP, HTTP, HTTPS, STCP, XTCP, SUDP${COLOR_END}"
    echo ""
    
    while true; do
        fun_configure_proxy
        if ! fun_ask_add_more; then
            break
        fi
    done
    
    echo ""
    echo -e "${COLOR_GREEN}Total ${proxy_count} proxy(s) configured.${COLOR_END}"
}

#========================================
# Configuration file generation
#========================================

fun_generate_config(){
    echo -n "Generating ${program_name} config file..."
    
    # Generate main configuration
    cat << EOF > "${str_program_dir}/${program_config_file}"
# frpc client configuration file
# Generated by install-frpc.sh

# Server connection settings
serverAddr = "${set_server_addr}"
serverPort = ${set_server_port}

# Authentication
auth.method = "token"
auth.token = "${set_token}"

# Transport settings
transport.tcpMux = true
transport.tcpMuxKeepaliveInterval = 60

# Log settings
log.to = "./frpc.log"
log.level = "${str_log_level}"
log.maxDays = ${set_log_max_days}

# ========================================
# Proxy configurations
# ========================================
${proxy_configs}
# ========================================
# More proxy examples (uncomment to use):
# ========================================

# TCP proxy example:
# [[proxies]]
# name = "ssh-tcp"
# type = "tcp"
# localIP = "127.0.0.1"
# localPort = 22
# remotePort = 6000

# UDP proxy example:
# [[proxies]]
# name = "dns-udp"
# type = "udp"
# localIP = "127.0.0.1"
# localPort = 53
# remotePort = 6053

# HTTP proxy example (with custom domain):
# [[proxies]]
# name = "web-http"
# type = "http"
# localIP = "127.0.0.1"
# localPort = 80
# customDomains = ["www.example.com"]

# HTTP proxy example (with subdomain):
# [[proxies]]
# name = "web-http-sub"
# type = "http"
# localIP = "127.0.0.1"
# localPort = 80
# subdomain = "myapp"

# HTTPS proxy example:
# [[proxies]]
# name = "web-https"
# type = "https"
# localIP = "127.0.0.1"
# localPort = 443
# customDomains = ["www.example.com"]

# STCP proxy example (secret TCP, visitor needed):
# [[proxies]]
# name = "secret-ssh"
# type = "stcp"
# localIP = "127.0.0.1"
# localPort = 22
# secretKey = "your_secret_key"

# STCP visitor example (run on visitor side):
# [[visitors]]
# name = "secret-ssh-visitor"
# type = "stcp"
# serverName = "secret-ssh"
# secretKey = "your_secret_key"
# bindAddr = "127.0.0.1"
# bindPort = 6000

# XTCP proxy example (P2P TCP, visitor needed):
# [[proxies]]
# name = "p2p-ssh"
# type = "xtcp"
# localIP = "127.0.0.1"
# localPort = 22
# secretKey = "your_secret_key"

# XTCP visitor example:
# [[visitors]]
# name = "p2p-ssh-visitor"
# type = "xtcp"
# serverName = "p2p-ssh"
# secretKey = "your_secret_key"
# bindAddr = "127.0.0.1"
# bindPort = 6000

# SUDP proxy example (secret UDP, visitor needed):
# [[proxies]]
# name = "secret-dns"
# type = "sudp"
# localIP = "127.0.0.1"
# localPort = 53
# secretKey = "your_secret_key"

# SUDP visitor example:
# [[visitors]]
# name = "secret-dns-visitor"
# type = "sudp"
# serverName = "secret-dns"
# secretKey = "your_secret_key"
# bindAddr = "127.0.0.1"
# bindPort = 6053

EOF
    
    echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
}

#========================================
# Installation functions
#========================================

# Pre-installation configuration
pre_install_frpc(){
    fun_frpc
    echo -e "Check your server setting, please wait..."
    echo ""
    disable_selinux

    # Check if frpc is already installed
    if pgrep -x "${program_name}" >/dev/null; then
        echo -e "${COLOR_GREEN}${program_name} is already installed and running.${COLOR_END}"
    else
        echo -e "${COLOR_YELOW}${program_name} is not running or not installed.${COLOR_END}"
    fi
    echo ""
    read -p "Do you want to continue? (y/n) " choice
    echo ""
    case "$choice" in
        y|Y)
            echo -e "${COLOR_GREEN} Starting installation...${COLOR_END}"
            ;;
        n|N)
            echo -e "${COLOR_YELOW} Installation cancelled.${COLOR_END}"
            echo ""
            exit 1
            ;;
        *)
            echo -e "${COLOR_YELOW}Invalid choice. Installation cancelled.${COLOR_END}"
            echo ""
            exit 1
            ;;
    esac
    
    clear
    fun_frpc
    fun_getServer
    fun_getVer
    echo ""
    
    # Server connection configuration
    echo -e "————————————————————————————————————————————"
    echo -e "     ${COLOR_RED}Please input server connection settings:${COLOR_END}"
    echo -e "————————————————————————————————————————————"
    fun_input_server_addr
    echo ""
    fun_input_server_port
    echo ""
    fun_input_token
    echo ""
    
    # Log settings
    echo -e "Please select ${COLOR_GREEN}log_level${COLOR_END}"
    echo    "1: info (default)"
    echo    "2: warn"
    echo    "3: error"
    echo    "4: debug"
    echo    "5: trace"
    echo    "-------------------------"
    read -e -p "Enter your choice (1, 2, 3, 4, 5 or exit. default [1]): " str_log_level
    case "${str_log_level}" in
        1|[Ii][Nn][Ff][Oo])
            str_log_level="info"
            ;;
        2|[Ww][Aa][Rr][Nn])
            str_log_level="warn"
            ;;
        3|[Ee][Rr][Rr][Oo][Oo])
            str_log_level="error"
            ;;
        4|[Dd][Ee][Bb][Uu][Gg])
            str_log_level="debug"
            ;;
        5|[Tt][Rr][Aa][Cc][Ee])
            str_log_level="trace"
            ;;
        [eE][xX][iI][tT])
            exit 1
            ;;
        *)
            str_log_level="info"
            ;;
    esac
    echo -e "log_level: ${COLOR_YELOW}${str_log_level}${COLOR_END}"
    echo ""
    
    fun_input_log_max_days
    echo ""
    
    # Proxy configuration
    echo ""
    echo -e "————————————————————————————————————————————"
    echo -e "     ${COLOR_RED}Configure your proxies:${COLOR_END}"
    echo -e "————————————————————————————————————————————"
    
    read -p "Do you want to configure proxies now? [Y/n] " config_now
    case "${config_now}" in
        n|N|no|NO)
            echo -e "${COLOR_YELOW}Skipping proxy configuration. You can edit config file later.${COLOR_END}"
            ;;
        *)
            fun_configure_proxies
            ;;
    esac
    
    # Confirmation
    echo ""
    echo "============== Check your input =============="
    echo -e "Server address     : ${COLOR_GREEN}${set_server_addr}${COLOR_END}"
    echo -e "Server port        : ${COLOR_GREEN}${set_server_port}${COLOR_END}"
    echo -e "Token              : ${COLOR_GREEN}${set_token}${COLOR_END}"
    echo -e "Log level          : ${COLOR_GREEN}${str_log_level}${COLOR_END}"
    echo -e "Log max days       : ${COLOR_GREEN}${set_log_max_days}${COLOR_END}"
    echo -e "Proxies configured : ${COLOR_GREEN}${proxy_count}${COLOR_END}"
    echo "=============================================="
    echo ""
    echo "Press any key to start...or Press Ctrl+c to cancel"
    
    char=`get_char`
    install_program_client_frpc
}

# Main installation function
install_program_client_frpc(){
    [ ! -d ${str_program_dir} ] && mkdir -p ${str_program_dir}
    cd ${str_program_dir}
    echo "${program_name} install path:$PWD"
    
    # Download frpc binary
    fun_download_file
    
    # Download init script
    echo -n "Downloading ${program_name} init script..."
    if ! wget --no-check-certificate -qO ${program_init} "https://raw.githubusercontent.com/HiMenma/frps-onekey/master/frpc.init"; then
        echo -e " [${COLOR_RED}failed${COLOR_END}]"
        echo "Failed to download init script, creating local one..."
        fun_create_init_script
    else
        echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
    fi
    
    # Generate config file
    fun_generate_config
    
    # Set permissions and register service
    echo -n "setting ${program_name} boot..."
    
    [ ! -x ${program_init} ] && chmod +x ${program_init}
    
    if [ "${OS}" == 'CentOS' ] || [ "${OS}" == 'RHEL' ] || [ "${OS}" == 'Fedora' ] || [ "${OS}" == 'Rocky' ] || [ "${OS}" == 'AlmaLinux' ]; then
        chmod +x ${program_init}
        chkconfig --add ${program_name}
    else
        chmod +x ${program_init}
        update-rc.d -f ${program_name} defaults
    fi
    
    [ -s ${program_init} ] && ln -sf ${program_init} /usr/bin/${program_name}
    
    echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
    echo ""
    
    # Start service
    ${program_init} start
    
    if pgrep -x "${program_name}" >/dev/null; then
        echo ""
        echo -e "${COLOR_GREEN}${program_name} service started successfully.${COLOR_END}"
        echo ""
        echo "+---------------------------------------------------------+"
        echo "|     ${program_name} installation completed successfully!    |"
        echo "+---------------------------------------------------------+"
        echo ""
        echo -e "Config file: ${COLOR_GREEN}${str_program_dir}/${program_config_file}${COLOR_END}"
        echo ""
        echo -e "Usage: ${COLOR_GREEN}${program_name}${COLOR_END} {start|stop|restart|status|config|version}"
        echo ""
        if [ ${proxy_count} -gt 0 ]; then
            echo -e "${COLOR_YELOW}You have configured ${proxy_count} proxy(s).${COLOR_END}"
            echo -e "You can edit the config file to add more proxies:"
            echo -e "${COLOR_GREEN}vi ${str_program_dir}/${program_config_file}${COLOR_END}"
            echo ""
        fi
    else
        echo ""
        echo -e "${COLOR_RED}${program_name} service failed to start.${COLOR_END}"
        echo ""
        echo "Please check the configuration and logs:"
        echo -e "Config: ${str_program_dir}/${program_config_file}"
        echo -e "Log: ${str_program_dir}/frpc.log"
        echo ""
        # Clean up
        if [ "${OS}" == 'CentOS' ] || [ "${OS}" == 'RHEL' ] || [ "${OS}" == 'Fedora' ] || [ "${OS}" == 'Rocky' ] || [ "${OS}" == 'AlmaLinux' ]; then
            chkconfig --del ${program_name}
        else
            update-rc.d -f ${program_name} remove
        fi
        exit 1
    fi
}

# Create init script locally if download fails
fun_create_init_script(){
    cat << 'INITEOF' > ${program_init}
#! /bin/bash
# chkconfig: 2345 55 25
# Description: Startup script for frpc on Debian. Place in /etc/init.d and
# run 'update-rc.d -f frpc defaults', or use the appropriate command on your
# distro. For CentOS/Redhat run: 'chkconfig --add frpc'
#=========================================================
#   System Required:  CentOS/Debian/Ubuntu/Fedora (32bit/64bit)
#   Description:  Manager for frpc, Written by Clang, Mender HiMenma
#=========================================================
### BEGIN INIT INFO
# Provides:          frpc
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the frpc
# Description:       starts frpc using start-stop
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
ProgramName="frpc"
ProgramPath="/usr/local/frpc"
NAME=frpc
BIN=${ProgramPath}/${NAME}
CONFIGFILE=${ProgramPath}/frpc.toml
SCRIPTNAME=/etc/init.d/${NAME}
version="2024"
program_version=`${BIN} --version`
RET_VAL=0

[ -x ${BIN} ] || exit 0
strLog=""

fun_frpc()
{
    echo ""
    echo "+---------------------------------------------------------+"
    echo "|     Manager for ${ProgramName}, Author Clang, Mender HiMenma     |"
    echo "+---------------------------------------------------------+"
    echo ""
}

fun_check_run(){
    PID=`ps -ef | grep -v grep | grep -i "${BIN}" | awk '{print $2}'`
    if [ ! -z $PID  ]; then
        return 0
    else
        return 1
    fi
}

fun_load_config(){
    if [ ! -r ${CONFIGFILE} ]; then
        echo "config file ${CONFIGFILE} not found"
        return 1
    fi
}

fun_start()
{
    if [ "${arg1}" = "start" ]; then
      fun_frpc
    fi
    if fun_check_run; then
        echo "${ProgramName} (pid $PID) already running."
        return 0
    fi
    fun_load_config
    echo -n "Starting ${ProgramName}(${program_version})..."
    ${BIN} -c ${CONFIGFILE} >/dev/null 2>&1 &
    sleep 1
    if ! fun_check_run; then
        echo "start failed"
        return 1
    fi
    echo " done"
    echo "${ProgramName} (pid $PID) is running."
    return 0
}

fun_stop(){
    if [ "${arg1}" = "stop" ] || [ "${arg1}" = "restart" ]; then
      fun_frpc
    fi
    if fun_check_run; then
        echo -n "Stoping ${ProgramName} (pid $PID)... "
        kill $PID
        if [ "$?" != 0 ] ; then
            echo " failed"
            return 1
        else
            echo " done"
        fi
    else
        echo "${ProgramName} is not running."
    fi
    return 0
}

fun_restart(){
    fun_stop
    fun_start
}

fun_status(){
    PID=`ps -ef | grep -v grep | grep -i "${BIN}" | awk '{print $2}'`
    if [ ! -z $PID ]; then
        echo "${ProgramName} (pid $PID) is running..."
    else
        echo "${ProgramName} is stopped"
        exit 0
    fi
}

fun_config(){
    if [ -s ${CONFIGFILE} ]; then
        vi ${CONFIGFILE}
    else
        echo "${ProgramName} configuration file not found!"
        return 1
    fi
}

fun_version(){
    echo "${ProgramName} version ${program_version}"
    return 0
}

fun_help(){
    ${BIN} --help
    return 0
}

arg1=$1
[  -z ${arg1} ]
case "${arg1}" in
    start|stop|restart|status|config)
        fun_${arg1}
    ;;
    [vV][eE][rR][sS][iI][oO][nN]|-[vV][eE][rR][sS][iI][oO][nN]|--[vV][eE][rR][sS][iI][oO][nN]|-[vV]|--[vV])
        fun_version
    ;;
    [Cc]|[Cc][Oo][Nn][Ff]|[Cc][Oo][Nn][Ff][Ii][Gg]|-[Cc]|-[Cc][Oo][Nn][Ff]|-[Cc][Oo][Nn][Ff][Ii][Gg]|--[Cc]|--[Cc][Oo][Nn][Ff]|--[Cc][Oo][Nn][Ff][Ii][Gg])
        fun_config
    ;;
    [Hh]|[Hh][Ee][Ll][Pp]|-[Hh]|-[Hh][Ee][Ll][Pp]|--[Hh]|--[Hh][Ee][Ll][Pp])
        fun_help
    ;;
    *)
        fun_frpc
        echo "Usage: $SCRIPTNAME {start|stop|restart|status|config|version}"
        RET_VAL=1
    ;;
esac
exit $RET_VAL
INITEOF
    chmod +x ${program_init}
}

#========================================
# Uninstall function
#========================================

uninstall_program_client_frpc(){
    fun_frpc
    echo ""
    
    if fun_check_run; then
        echo -n "Stopping ${program_name}..."
        kill $PID
        sleep 1
        echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
    fi
    
    # Remove service
    echo -n "Removing ${program_name} service..."
    if [ "${OS}" == 'CentOS' ] || [ "${OS}" == 'RHEL' ] || [ "${OS}" == 'Fedora' ] || [ "${OS}" == 'Rocky' ] || [ "${OS}" == 'AlmaLinux' ]; then
        chkconfig --del ${program_name}
    else
        update-rc.d -f ${program_name} remove
    fi
    echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
    
    # Remove files
    echo -n "Removing ${program_name} files..."
    rm -f /usr/bin/${program_name}
    rm -f ${program_init}
    rm -fr ${str_program_dir}
    echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
    
    echo ""
    echo -e "${COLOR_GREEN}${program_name} uninstalled successfully!${COLOR_END}"
    echo ""
}

#========================================
# Update function
#========================================

update_program_client_frpc(){
    fun_frpc
    echo ""
    
    # Check current version
    if [ -s ${str_program_dir}/${program_name} ]; then
        current_version=$(${str_program_dir}/${program_name} --version)
        echo -e "Current ${program_name} version: ${COLOR_GREEN}${current_version}${COLOR_END}"
    else
        echo -e "${COLOR_RED}${program_name} is not installed.${COLOR_END}"
        exit 1
    fi
    
    # Get latest version
    fun_getServer
    fun_getVer
    
    echo ""
    echo -e "Latest ${program_name} version: ${COLOR_GREEN}v${FRPC_VER}${COLOR_END}"
    echo ""
    
    if [ "v${current_version}" == "v${FRPC_VER}" ]; then
        echo -e "${COLOR_YELOW}You are already running the latest version.${COLOR_END}"
        read -p "Do you want to reinstall? [y/N] " reinstall
        case "${reinstall}" in
            y|Y)
                ;;
            *)
                exit 0
                ;;
        esac
    fi
    
    # Backup config
    if [ -s ${str_program_dir}/${program_config_file} ]; then
        echo -n "Backing up config file..."
        cp ${str_program_dir}/${program_config_file} /tmp/${program_config_file}.bak
        echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
    fi
    
    # Stop service
    if fun_check_run; then
        echo -n "Stopping ${program_name}..."
        kill $PID
        sleep 1
        echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
    fi
    
    # Download new version
    rm -f ${str_program_dir}/${program_name}
    fun_download_file
    
    # Restore config
    if [ -s /tmp/${program_config_file}.bak ]; then
        echo -n "Restoring config file..."
        cp /tmp/${program_config_file}.bak ${str_program_dir}/${program_config_file}
        rm -f /tmp/${program_config_file}.bak
        echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
    fi
    
    # Start service
    ${program_init} start
    
    if pgrep -x "${program_name}" >/dev/null; then
        echo ""
        echo -e "${COLOR_GREEN}${program_name} updated successfully!${COLOR_END}"
        echo -e "New version: ${COLOR_GREEN}v${FRPC_VER}${COLOR_END}"
        echo ""
    else
        echo ""
        echo -e "${COLOR_RED}${program_name} failed to start after update.${COLOR_END}"
        exit 1
    fi
}

#========================================
# Config management function
#========================================

configure_program_client_frpc(){
    if [ -s ${str_program_dir}/${program_config_file} ]; then
        fun_frpc
        echo "Opening ${program_name} configuration file..."
        echo ""
        vi ${str_program_dir}/${program_config_file}
        
        # Ask to restart
        if fun_check_run; then
            echo ""
            read -p "Configuration modified. Restart ${program_name}? [Y/n] " restart_now
            case "${restart_now}" in
                n|N|no|NO)
                    echo -e "${COLOR_YELOW}Please restart manually: ${program_name} restart${COLOR_END}"
                    ;;
                *)
                    ${program_init} restart
                    ;;
            esac
        fi
    else
        echo -e "${COLOR_RED}${program_name} configuration file not found!${COLOR_END}"
        echo "Please run: ./install-frpc.sh install"
        exit 1
    fi
}

# Check if frpc is running
fun_check_run(){
    PID=`ps -ef | grep -v grep | grep -i "${str_program_dir}/${program_name}" | awk '{print $2}'`
    if [ ! -z $PID ]; then
        return 0
    else
        return 1
    fi
}

#========================================
# Main entry point
#========================================

# Set colors first
fun_set_text_color

# Check root
rootness

# Check OS
checkos

# Check architecture
check_os_bit

# Install required packages
pre_install_packs

# Parse arguments
frpc_action=$1
[ -z ${frpc_action} ] && frpc_action="install"

case "${frpc_action}" in
    install)
        pre_install_frpc
        ;;
    uninstall)
        uninstall_program_client_frpc
        ;;
    update)
        update_program_client_frpc
        ;;
    config)
        configure_program_client_frpc
        ;;
    *)
        fun_frpc
        echo "Usage: $0 {install|uninstall|update|config}"
        echo ""
        echo "Commands:"
        echo "  install   - Install frpc and configure interactively"
        echo "  uninstall - Remove frpc from system"
        echo "  update    - Update frpc to latest version"
        echo "  config    - Edit frpc configuration file"
        ;;
esac
