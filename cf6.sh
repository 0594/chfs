#!/bin/bash
# chfs-deploy.sh - CHFS v3.1 终极稳定版 (修复引号报错)
# 用法: sudo bash chfs-deploy.sh [install|uninstall|restart|status]

set -e

# --- 配置区域 ---
APP_NAME="chfs"
VERSION="3.1"
INSTALL_DIR="/opt/${APP_NAME}"
BIN_FILE="${INSTALL_DIR}/${APP_NAME}"
INI_FILE="${INSTALL_DIR}/${APP_NAME}.ini"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
MANAGE_SCRIPT_PATH="${INSTALL_DIR}/chfs-deploy.sh"
CF_CMD_PATH="/usr/local/bin/cf"
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
    
    # 【修复】使用单引号包裹 heredoc 内容，防止变量提前展开导致引号混乱
    # 注意：这里我们直接写入固定的路径，因为 MANAGE_SCRIPT_PATH 是固定的
    cat > "${CF_CMD_PATH}" <<'ENDOFSCRIPT'
#!/bin/bash
# CF Command Wrapper for CHFS
exec sudo /opt/chfs/chfs-deploy.sh "$@"
ENDOFSCRIPT
    
    chmod +x "${CF_CMD_PATH}"
    log_info "cf 命令已就绪: ${CF_CMD_PATH}"
}

install_service() {
    log_info "正在安装 CHFS v${VERSION}..."
    
    # 0. 将当前脚本复制到安装目录
    mkdir -p ${INSTALL_DIR}
    cp "$0" "${MANAGE_SCRIPT_PATH}"
    chmod +x "${MANAGE_SCRIPT_PATH}"
    log_info "管理脚本已安装至: ${MANAGE_SCRIPT_PATH}"

    # 1. 确保安装目录存在
    mkdir -p ${INSTALL_DIR}

    # 2. 下载并解压
    if [[ ! -f "${BIN_FILE}" ]]; then
        local zip_file="/tmp/chfs-${VERSION}.zip"
        log_info "正在下载安装包..."
        curl -L -o "${zip_file}" "${DOWNLOAD_URL}"
        
        log_info "正在解压..."
        unzip -o "${zip_file}" -d "${INSTALL_DIR}"
        rm -f "${zip_file}"
        
        # 智能重命名二进制文件
        if [[ ! -f "${BIN_FILE}" ]]; then
            local found_bin=$(find ${INSTALL_DIR} -maxdepth 1 -type f -name "chfs*" | head -n 1)
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
        # 【修复】使用单引号 'EOF' 防止变量被 Shell 解释
        cat > "${INI_FILE}" <<'EOF'
port=8080
root=/opt/chfs/share
allow-upload=true
EOF
    fi

    # 5. 创建 Systemd 服务
    # 【修复】使用单引号 'EOF' 确保变量 ${BIN_FILE} 等不被当前 Shell 展开，而是写入文件
    # 但这里我们需要写入实际路径，所以不能用单引号，必须确保双引号配对正确
    cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Cute Http File Server
After=network.target

[Service]
Type=simple
ExecStart=${BIN_FILE} -file=${INI_FILE}
Restart=on-failure
WorkingDirectory=${INSTALL_DIR}

[Install]
WantedBy=multi-user.target
EOF

    # 6. 启动服务
    systemctl daemon-reload
    systemctl enable ${APP_NAME}
    systemctl restart ${APP_NAME}
    
    # 7. 配置 cf 命令
    setup_cf_command
    
    log_info "安装完成！现在您可以直接使用 'cf' 命令进行管理。"
    log_info "用法[install|uninstall|restart|status]"
    log_info "配置文件路径：${INSTALL_DIR}/${APP_NAME}.ini"
}

uninstall_service() {
    log_info "正在卸载 CHFS..."
    systemctl stop ${APP_NAME} 2>/dev/null || true
    systemctl disable ${APP_NAME} 2>/dev/null || true
    rm -f "${SERVICE_FILE}"
    systemctl daemon-reload
    
    if [[ "${INSTALL_DIR}" == "/opt/${APP_NAME}" ]]; then
        rm -rf "${INSTALL_DIR}"
    fi
    
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
    install) install_service ;;
    uninstall) uninstall_service ;;
    restart) systemctl restart ${APP_NAME}; log_info "服务已重启。" ;;
    status) show_status ;;
    *) echo "用法: $0 {install|uninstall|restart|status}"; exit 1 ;;
esac
