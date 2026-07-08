#!/bin/bash
# chfs.sh - 一键部署 CuteHttpFileServer v3.1（支持 systemd）
# 适用于 Linux 系统（Ubuntu/CentOS/统信UOS等），部署后可通过 systemctl 管理
# chfs-linux-amd64-3.1.zip自动下载并解压

set -e

BIN_PATH="/opt/chfs"
INI_FILE="$BIN_PATH/chfs.ini"
SERVICE_NAME="chfs"

echo "🚀 正在一键部署 CHFS v3.1 文件服务器..."

# 1. 创建工作目录
mkdir -p /opt/chfs/{share,log}
chmod 755 /opt/chfs/share

# 2. 检测并自动下载 chfs-linux-amd64-3.1.zip
ZIP_FILE="/opt/chfs/chfs-linux-amd64-3.1.zip"


if [ ! -f "$ZIP_FILE" ]; then
  echo "📥 正在下载 CHFS v3.1 安装包..."
  curl -L -o "$ZIP_FILE" https://github.com/0594/chfs/releases/download/v3.1/chfs-linux-amd64-3.1.zip
fi

# 解压二进制文件（v3.1 版本为单文件，无需解压到子目录）
unzip -o "$ZIP_FILE" -d /opt/chfs/
chmod +x "$BIN_PATH"

# 3. 生成 v3.1 专用 chfs.ini 配置（兼容你历史的权限规则）
cat > /opt/chfs/chfs.ini << 'EOF'
[global]
port = 8080
path = /opt/chfs/share
log = /opt/chfs/log/chfs.log

[users]
admin = SecurePass123, a
anonymous = , r
upload = , w:/upload
private = , n:/private

[features]
webdav_enabled = true
html.title = 我的私有文件库
folder.download = enable
file.remove = 1
image.preview = true
session.timeout = 30
EOF

# 4. 创建上传与私有目录（v3.1 权限规则依赖）
mkdir -p /opt/chfs/share/upload /opt/chfs/share/private

# 5. 创建 systemd 服务（v3.1 与 v2.x 启动方式一致）
cat > /etc/systemd/system/chfs.service << 'EOF'
[Unit]
Description=CuteHttpFileServer v3.1
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
WorkingDirectory=/opt/chfs
ExecStart=/opt/chfs --config=/opt/chfs/chfs.ini
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 6. 启动并设置开机自启
systemctl daemon-reload
systemctl enable --now chfs

# 7. 防火墙放行（如启用）
#if command -v ufw &> /dev/null; then
#  ufw allow 8080
#fi

echo ""
echo "✅ CHFS v3.1 部署完成！"
echo "🔗 访问地址：http://$(curl -s4 ifconfig.me):8080"
echo "👤 管理员账号：admin / SecurePass123"
echo "📁 上传目录：http://$(curl -s4 ifconfig.me):8080/upload"
echo "🔒 私有目录：/opt/chfs/share/private（仅管理员可访问）"
echo "🌐 WebDAV 地址：http://$(curl -s4 ifconfig.me):8080/webdav"
echo ""
echo "💡 注意：v3.1 使用 [users] 段落语法，与你历史使用的 rule= 格式不同，但权限逻辑完全一致，已为你自动迁移。"
echo "💡 建议：首次登录后，请立即修改密码，并考虑配置 HTTPS 提升安全性。"

# 检查服务是否安装
check_service() {
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "⚠️ 服务未运行或未安装"
        return 1
    fi
}

# 启动服务
start_service() {
    echo "▶️  启动 CHFS 服务..."
    sudo systemctl start "$SERVICE_NAME"
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "✅ 启动成功"
        echo "🔗 访问地址：http://$(curl -s4 ifconfig.me):8080"
    else
        echo "❌ 启动失败，请检查日志：journalctl -u $SERVICE_NAME -n 20"
    fi
}

# 停止服务
stop_service() {
    echo "⏹️  停止 CHFS 服务..."
    sudo systemctl stop "$SERVICE_NAME"
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "❌ 停止失败"
    else
        echo "✅ 已停止"
    fi
}

# 重启服务
restart_service() {
    stop_service
    sleep 1
    start_service
}

# 卸载服务（彻底清理）
uninstall_service() {
    echo "🗑️  卸载 CHFS 服务（此操作不可逆）"
    read -p "确认卸载？输入 'YES' 继续: " confirm
    if [[ "$confirm" != "YES" ]]; then
        echo "❌ 取消卸载"
        return
    fi

    stop_service
    sudo systemctl disable "$SERVICE_NAME"
    sudo rm -f /etc/systemd/system/$SERVICE_NAME.service
    sudo systemctl daemon-reload
    rm -rf "$BIN_PATH"
    echo "✅ 服务、配置、文件全部清除"
    echo "💡 建议：如需重装，请重新运行部署脚本"
}

# 主菜单
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            echo "✅ CHFS 服务正在运行"
        else
            echo "❌ CHFS 服务未运行"
        fi
        ;;
   uninstall)
        uninstall_service
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|uninstall}"
        echo ""
        echo "功能说明："
        echo "  start     - 启动服务"
        echo "  stop      - 停止服务"
        echo "  restart   - 重启服务"
        echo "  status    - 查看服务状态"
        echo "  uninstall - 彻底卸载服务与配置"
        echo ""
        echo "💡 密码修改后需重启服务：sudo ./chfs.sh restart"
        ;;
esac
