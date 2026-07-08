<h3 align="center">CHFS v3.x - 单文件部署的轻量私有文件服务</h3>

<p align="center">
  <a href="https://github.com/0594/chfs/releases">
    <img src="https://img.shields.io/github/v/release/your-repo/chfs?color=blue&label=Latest%20Version" alt="Latest Version">
  </a>
  <a href="https://github.com/0594/chfs/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
  </a>
  <a href="https://github.com/0594/chfs/stargazers">
    <img src="https://img.shields.io/github/stars/your-repo/chfs?style=social" alt="GitHub Stars">
  </a>
</p>

<p align="center">
  无需依赖 · 单二进制文件运行 · 30秒搭建私有文件共享服务
</p>

---

🚀 30秒快速启动

方式1：直接运行

下载对应平台二进制（以Linux x64为例），一键启动，共享当前目录
```bash
wget https://github.com/0594/chfs/releases/download/v3.1/chfs-linux-amd64-v3.1.zip
unzip chfs-linux-amd64-v3.1.zip
chmod +x chfs
./chfs -port=8080 -path=./share
```

方式2：一键部署脚本（推荐）

> 执行我们提供的自动化部署脚本
```bash
curl -sL https://raw.githubusercontent.com/0594/chfs/refs/heads/main/cf6.sh -o /root/chfs.sh && chmod +x /root/chfs.sh && sudo /root/chfs.sh install
```
> 脚本自动完成安装、配置Systemd服务、创建共享目录，执行完成后直接访问 `http://你的IP:8080` 即可使用。

---

三、核心特性区（突出v3.x版本亮点）
```markdown
✨ 核心特性
- 📦 零依赖单文件：仅一个可执行程序，无需Java/PHP等运行环境，解压即跑
- 🔐 灵活权限控制：支持自定义上传/删除/创建目录权限，可配置基础认证保护
- 🌐 全平台兼容：支持Linux/Windows/macOS/ARM等几乎所有主流架构
- 📂 WebDAV支持：v3.x原生集成WebDAV协议，可直接挂载为本地磁盘
- 🔒 HTTPS加密：一键配置证书启用SSL，公网访问更安全
- 📝 自定义界面：支持自定义网页标题、首页公告，适配内部部署场景
- 📊 轻量低耗：内存占用<20MB，老旧设备也能流畅运行
```

---

四、配置参考区（直接复用之前整理的v3.x完整参数）

⚙️ v3.x 完整配置示例
创建 `chfs.ini` 即可自定义所有参数：
```ini
网络配置
port=8080
root=/opt/chfs/share
auth-type=basic
username=admin
password=your_strong_password

权限开关
allow-upload=true
allow-delete=false
allow-create-dir=true

高级功能
webdav=true
max-upload-size=0
log-path=/opt/chfs/log/chfs.log
```
修改后执行 `systemctl restart chfs` 即可生效。


---

五、常见问题区（提前覆盖用户高频疑问）
```markdown
❓ 常见问题
1. 启动后无法访问？
   检查服务器防火墙是否开放8080端口，确认配置文件中`root`路径存在且CHFS有读写权限。
2. 如何配置HTTPS？
   在配置文件中添加`cert`和`key`参数，指定你的SSL证书路径即可，无需额外反向代理。
3. 忘记密码怎么办？
   直接编辑`chfs.ini`修改`password`字段，重启服务即可生效。
```

---
