#!/bin/bash
# chfs-deploy.sh - CHFS v3.1 一键部署与管理脚本 (Systemd)
# 用法: sudo bash chfs-deploy.sh [install|uninstall|restart|status]

set -e

# --- 配置区域 ---
APP_NAME="chfs"
VERSION="3.1"
INSTALL_DIR="/opt/${APP_NAME}"
BIN_FILE="${INSTALL_DIR}/${APP_NAME}"
INI_FILE="${INSTALL_DIR}/${APP_NAME}.ini"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
DOWNLOAD_URL="https://github.com/0594/chfs/releases/download/v${VERSION}/chfs-linux-amd64-${VERSION}.zip"

# --- 颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- 前置检查 ---
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行，请使用 sudo 执行。"
    fi
}

# --- 核心功能函数 ---

install_service() {
    log_info "正在安装 CHFS v${VERSION}..."
    
    # 1. 创建目录
    mkdir -p ${INSTALL_DIR}/{share,log}
    chmod 755 ${INSTALL_DIR}/share

    # 2. 下载并解压 (如果二进制文件不存在)
    if [[ ! -f "${BIN_FILE}" ]]; then
        local zip_file="/tmp/chfs-${VERSION}.zip"
        log_info "正在下载安装包..."
        curl -L -o "${zip_file}" "${DOWNLOAD_URL}"
        
        log_info "正在解压..."
        unzip -o "${zip_file}" -d "${INSTALL_DIR}"
        rm -f "${zip_file}"
        
        # 确保二进制文件存在并赋权
        if [[ ! -f "${BIN_FILE}" ]]; then
            # 尝试查找解压后的实际文件名（防止版本命名差异）
            local found_bin=$(find ${INSTALL_DIR} -maxdepth 1 -type f -executable -name "chfs*" | head -n 1)
            if [[ -n "$found_bin" ]]; then
                mv "$found_bin" "${BIN_FILE}"
            else
                log_error "解压后未找到可执行文件，请检查下载包。"
            fi
        fi
        chmod +x "${BIN_FILE}"
    fi

    # 3. 生成配置文件 (如果不存在)
    if [[ ! -f "${INI_FILE}" ]]; then
        cat > "${INI_FILE}" <<EOF
# CHFS Config
port=8080
root=${INSTALL_DIR}/share
allow-upload=true
EOF
        log_info "已生成默认配置文件: ${INI_FILE}"
    fi

    # 4. 创建 Systemd 服务
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

    # 5. 启动服务
    systemctl daemon-reload
    systemctl enable ${APP_NAME}
    systemctl restart ${APP_NAME}
    
    log_info "安装完成！服务已启动。"
    log_info "访问地址: http://<服务器IP>:8080"
}

uninstall_service() {
    log_info "正在卸载 CHFS..."
    
    # 1. 停止并禁用服务
    systemctl stop ${APP_NAME} 2>/dev/null || true
    systemctl disable ${APP_NAME} 2>/dev/null || true
    rm -f "${SERVICE_FILE}"
    systemctl daemon-reload

    # 2. 安全检查后删除文件
    if [[ "${INSTALL_DIR}" == "/opt/${APP_NAME}" ]]; then
        rm -rf "${INSTALL_DIR}"
        log_info "文件目录已删除: ${INSTALL_DIR}"
    else
        log_error "安全拦截：非标准安装目录，拒绝自动删除。"
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
