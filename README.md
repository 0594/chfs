✅ 使用说明

一键脚本： 
```bash
curl -sL https://raw.githubusercontent.com/0594/chfs/refs/heads/main/cf6.sh -o /root/chfs.sh && chmod +x /root/chfs.sh && sudo /root/chfs.sh install
```
1. 准备文件  
   将你仓库中的 `chfs-linux-amd64-3.1.zip` 解压，确保得到 `chfs-linux-amd64-3.1` 可执行文件，并与本脚本放在同一目录。

2. 赋予执行权限
   ```bash
   chmod +x chfs-v3.1-deploy.sh
   ```

3. 执行命令（需 root）
   ```bash
   仅生成配置（不启动）
   sudo ./chfs-v3.1-deploy.sh setup

   一键部署并启动（推荐）
   sudo ./chfs-v3.1-deploy.sh start

   停止服务
   sudo ./chfs-v3.1-deploy.sh stop

   彻底卸载（删除所有文件和服务）
   sudo ./chfs-v3.1-deploy.sh uninstall
   ```

🔐 默认配置说明（v3.1 语法）

| 用户名 | 权限 | 路径 | 说明 |
|--------|------|------|------|
| `admin` | `full` | 全局 | 管理员，可读写删改 |
| `anonymous` | `read` | 全局 | 匿名访客，仅可浏览下载 |
| `upload` | `write` | `/opt/chfs/share/upload` | 匿名上传专用（投递箱） |
| `private` | `none` | `/opt/chfs/share/private` | 禁止所有访问 |

> ⚠️ 注意：v3.1 不再支持 `rule=` 语法，必须使用 `[user]` 段落定义权限，本脚本已严格遵循官方规范。

📁 文件结构（部署后）
```
/opt/chfs/
├── chfs-linux-amd64-3.1     可执行文件
├── chfs.ini                 配置文件（v3.1 格式）
├── logs/                    日志目录
└── share/
    ├── upload/              匿名上传目录
    └── private/             私有目录（仅管理员可访问）
```
