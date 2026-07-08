#!/bin/bash
# chfs-deploy.sh - CHFS v3.1 一键部署与管理脚本 (含 cf 命令自动配置)
# 用法: sudo bash chfs-deploy.sh [install|uninstall|restart|status]

set -e

# --- 配置区域 ---
APP_NAME="chfs"
VERSION="3.1"
INSTALL_DIR="/opt/${APP_NAME}"
BIN_FILE="${INSTALL_DIR}/${APP_NAME}"
INI_FILE="${INSTALL_DIR}/${APP_NAME}.ini"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
MANAGE_SCRIPT_PATH="/opt/chfs/manage.sh" # 管理脚本自身路径
CF_CMD_PATH="/usr/local/bin/cf"          # cf 命令路径
DOWNLOAD_URL="https://github.com/0594/chfs/releases/download/v${VERSION}/chfs-linux-amd64-${VERSION}.zip"

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- 前置检查 ---
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行，请使用 sudo 执行。"
    fi
}

# --- 核心功能函数 ---

setup_cf_command() {
    log_info "正在配置 cf 快捷命令..."
    
    # 1. 创建 cf 包装脚本
    cat > "${CF_CMD_PATH}" <<EOF
#!/bin/bash
# CF Command Wrapper for CHFS
exec sudo ${MANAGE_SCRIPT_PATH} "\$@"
EOF
    
    # 2. 赋予执行权限
    chmod +x "${CF_CMD_PATH}"
    
    log_info "cf 命令已就绪: ${CF_CMD_PATH}"
}

install_service() {
    log_info "正在安装 CHFS v${VERSION}..."
    
    # 1. 确保安装目录存在
    mkdir -p ${INSTALL_DIR}

    # 2. 下载并解压 (如果二进制文件不存在)
    if [[ ! -f "${BIN_FILE}" ]]; then
        local zip_file="/tmp/chfs-${VERSION}.zip"
        log_info "正在下载安装包..."
        curl -L -o "${zip_file}" "${DOWNLOAD_URL}"
        
        log_info "正在解压..."
        unzip -o "${zip_file}" -d "${INSTALL_DIR}"
        rm -f "${zip_file}"
        
        # 智能重命名二进制文件
        if [[ ! -f "${BIN_FILE}" ]]; then
            local found_bin=$(find ${INSTALL_DIR} -maxdepth 1 -type f -executable -name "chfs*" | head -n 1)
            if [[ -n "$found_bin" ]]; then
                mv "$found_bin" "${BIN_FILE}"
            else
                log_error "解压后未找到可执行文件。"
            fi
        fi
        chmod +x "${BIN_FILE}"
    fi

    # 3. 创建运行时目录
    mkdir -p ${INSTALL_DIR}/{share,log}
    chmod 755 ${INSTALL_DIR}/share

    # 4. 生成配置文件
    if [[ ! -f "${INI_FILE}" ]]; then
        cat > "${INI_FILE}" <<EOF
port=8080
root=${INSTALL_DIR}/share
allow-upload=true
EOF
    fi

    # 5. 创建 Systemd 服务
    cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Cute Http File Server
After=network.target

[Service]
Type=simple
ExecStart=${BIN_FILE} --config=${INI_FILE}
Restart=on-failure
WorkingDirectory=${INSTALL_DIR}

[Install]
WantedBy=multi-user.target
EOF

    # 6. 启动服务
    systemctl daemon-reload
    systemctl enable ${APP_NAME}
    systemctl restart ${APP_NAME}
    
    # 7. 【新增】自动配置 cf 命令
    setup_cf_command
    
    log_info "安装完成！现在您可以直接使用 'cf' 命令进行管理。"
    log_info "示例: cf status, cf restart"
}

uninstall_service() {
    log_info "正在卸载 CHFS..."
    
    # 1. 停止服务
    systemctl stop ${APP_NAME} 2>/dev/null || true
    systemctl disable ${APP_NAME} 2>/dev/null || true
    rm -f "${SERVICE_FILE}"
    systemctl daemon-reload

    # 2. 删除文件
    if [[ "${INSTALL_DIR}" == "/opt/${APP_NAME}" ]]; then
        rm -rf "${INSTALL_DIR}"
    fi
    
    # 3. 【新增】删除 cf 命令
    if [[ -f "${CF_CMD_PATH}" ]]; then
        rm -f "${CF_CMD_PATH}"
        log_info "cf 命令已移除。"
    fi
    
    log_info "卸载完成。"
}

show_status() {
    systemctl status ${APP_NAME} --no-pager
}

# --- 主逻辑 ---
check_root

case "${1}" in
    install)
        install_service
        ;;
    uninstall)
        uninstall_service
        ;;
    restart)
        systemctl restart ${APP_NAME}
        log_info "服务已重启。"
        ;;
    status)
        show_status
        ;;
    *)
        echo "用法: $0 {install|uninstall|restart|status}"
        exit 1
        ;;
esac
