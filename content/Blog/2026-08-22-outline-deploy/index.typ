#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *
#import "@preview/theorion:0.6.0": quote-block

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "Outline 部署、使用与备份下载",
  description: "用 Docker、Caddy 与 Cloudflare Tunnel 部署 Outline 知识库，并介绍基本使用与备份下载。",
  date: datetime(year: 2026, month: 8, day: 22),
  lang: "zh",
)

= Outline 部署、使用与备份下载

#quote-block[
更新日期：2026-08-25

部署目录：`D:\YL2026\launch\Outline`
适用场景：Windows 个人电脑 + Docker Desktop + Cloudflare Tunnel。

本文共三部分：

+ Outline 部署
+ Outline 基本使用
+ 从 Hugging Face 下载 Outline 备份笔记
]

#line()

== 第一部分：Outline 部署

=== 1. 架构

#tablem[
  | 组件 | 作用 | 容器/进程 |
  | :--- | :--- | :--- |
  | `outlinewiki/outline:latest` | Outline 主服务 | `outline-outline-1` |
  | `postgres:15-alpine` | 文档、用户、分享元数据 | `outline-postgres-1` |
  | `redis:alpine` | 缓存与队列 | `outline-redis-1` |
  | `minio/minio:latest` | 图片与附件对象存储 | `outline-minio-1` |
  | Caddy | 本地 HTTPS 反向代理、分享子域名 | `caddy.exe` |
  | Cloudflared | 公网隧道，转发到本机 443 | Windows 服务 |
]

数据链路：

```text
访客 -> Cloudflare Tunnel -> localhost:443 Caddy -> localhost:3000 Outline
                                               -> localhost:9000 MinIO
```

=== 2. 环境准备

+ 安装 Docker Desktop，启用 WSL 2 后端。
+ 安装 Caddy，放在 `caddy\extracted\caddy.exe`。
+ Cloudflare Tunnel 配置通配主机名 `*.20211003.xyz`：
   - Service Type：`HTTPS`
   - URL：`localhost:443`
   - 开启 *No TLS Verify*
+ Cloudflare DNS 添加通配记录 `*.20211003.xyz`，指向 Cloudflare Tunnel。
+ 准备邮箱登录，并在需要时配置 Google/Discord OAuth，写入 `env.outline`。

=== 3. GitHub 仓库文件与用途

仓库地址：

```text
https://github.com/Helloxiaolaodi/Outline_local.git
```

本机部署目录为 `D:\YL2026\launch\Outline`。仓库只提交可复现的配置、脚本和说明文件；本地密钥、日志、备份和下载的二进制文件均不入库。

==== 3.1 根目录文件

#tablem[
  | 文件 | 作用 |
  | :--- | :--- |
  | `README.md` | Outline 本地部署仓库的说明，包含启动、备份、公开分享、Hugging Face 同步等常用命令。 |
  | `.gitignore` | 排除 `hf.env`、Redis 备份、日志、桌面客户端、Caddy 二进制、分享页快照等不应入库的文件。 |
  | `docker-compose.yml` | 定义 `outline`、`postgres`、`redis`、`minio` 四个容器；挂载本地前端补丁，并给 Redis 增加 AOF 尾部容错参数。 |
  | `env.outline` | Outline 主程序环境变量，包含主域名、数据库、MinIO、SMTP、OAuth 等配置。 |
  | `start_outline.ps1` | 一键启动脚本：启动 Docker Desktop、等待 Docker 就绪、启动容器、启动 Caddy、写入代理直连规则，并可同时启动桌面客户端。 |
  | `stop_outline.ps1` | 一键停止脚本：关闭桌面客户端、停止容器、退出 Docker Desktop；加 `-KeepDocker` 参数时保留 Docker Desktop 运行。 |
  | `backup_to_github.ps1` | 把部署仓库文件提交并推送到 GitHub，用于配置版本备份。 |
  | `pull_oci_image.py` | 在 Docker Hub 拉取受限或失败时，从镜像源下载 OCI 镜像并打包为 `docker load` 可用的 tar。 |
  | `sync_share_domains.py` | 查询 Outline 中已公开分享的笔记，为每个分享生成独立子域名，写入 `shares` 表，并重新生成 Caddy 路由。 |
  | `auto_share_domains.ps1` | 分享域名同步的 PowerShell 包装脚本，供计划任务调用。 |
  | `run_auto_share_domains_hidden.vbs` | 隐藏窗口启动 `auto_share_domains.ps1` 的 VBScript，用于每 2 分钟自动同步分享域名。 |
  | `run_start_outline_hidden.vbs` | 隐藏窗口启动 `start_outline.ps1` 的 VBScript，可放入 Windows 启动文件夹实现开机自动启动。 |
  | `run_stop_outline_hidden.vbs` | 隐藏窗口启动 `stop_outline.ps1` 的 VBScript，供桌面快捷方式调用。 |
  | `create_desktop_shortcuts.ps1` | 在桌面创建 `Outline`、`Outline Start`、`Outline Stop` 三个快捷方式，分别对应直接打开桌面软件、一键启动、一键停止。 |
  | `add_s3_hosts.ps1` | 以管理员身份维护 hosts，把 `outline.20211003.xyz`、`s3.20211003.xyz` 和当前活动分享子域映射到 `127.0.0.1`，使本机图片与分享页直接走 Caddy/MinIO，避免绕公网。 |
  | `ensure_proxy_bypass.ps1` | 把 `*.20211003.xyz` 写入 Windows 系统代理直连列表，并写入 Clash 直连规则和 DNS hosts，避免图片上传和加载被代理软件绕回公网而变慢。 |
  | `optimize_cloudflare_route.ps1` | 管理员身份运行：为 Cloudflare 边缘网段添加绑定 Intel 校园网卡（`WLAN`）的持久路由，让 Outline 公网隧道走快链路，其他软件的路由不受影响；校园网网关变化后重新运行即可。 |
]

==== 3.2 Caddy 配置

#tablem[
  | 文件 | 作用 |
  | :--- | :--- |
  | `caddy\Caddyfile` | 本地 HTTPS 入口：`https://localhost` 反代 Outline，`/outline` 路径反代 MinIO，并导入 `share-domains.caddy`。 |
  | `caddy\share-domains.caddy` | 由 `sync_share_domains.py` 自动生成的公网子域名路由，不要手动编辑；下次同步会被覆盖。 |
]

说明：`caddy\extracted\caddy.exe` 是本地下载的可执行文件，已被 `.gitignore` 排除，新机器需重新下载 Caddy 并放在该目录。

==== 3.3 前端

说明：

#tablem[
  | 文件 | 作用 |
  | :--- | :--- |
  | `patches\README.md` | 前端补丁说明：修复复制、移动、归档文档后侧边栏不能立即刷新的问题，并说明镜像升级后如何重建补丁。 |
  | `patches\index.B2Khpv-E.js` | 当前 Outline 前端 bundle，包含侧边栏刷新修复；由 `docker-compose.yml` 只读挂载进容器。 |
  | `patches\original-index.B2Khpv-E.js` | 官方原版前端 bundle，是补丁的源文件，镜像升级后用它重新生成补丁。 |
  | `patches\apply-sidebar-fix.js` | 重建补丁的脚本：读取 `original-index.B2Khpv-E.js`，应用 4 处侧边栏刷新修复，输出 `index.B2Khpv-E.js`，并校验每处替换恰好命中一次。 |
]

如客户端仍保留旧 Service Worker 或浏览器缓存，需清理站点缓存后重开。

==== 3.4 Hugging Face 同步

#tablem[
  | 文件 | 作用 |
  | :--- | :--- |
  | `sync-hf\README.md` | Hugging Face 备份与恢复的完整说明。 |
  | `sync-hf\sync_outline_to_huggingface.ps1` | 主备份/恢复脚本：导出 Postgres、MinIO 附件、嵌套 Markdown 笔记，并上传到 Hugging Face；也支持从 Hugging Face 恢复。 |
  | `sync-hf\export_outline_docs.py` | 把 Postgres 中的文档元数据按 `文档集/文档/子文档/子子文档/同名.md` 递归导出为 UTF-8 Markdown。 |
  | `sync-hf\upload_to_huggingface.py` | 把稳定镜像或历史快照上传到 Hugging Face dataset。 |
  | `sync-hf\download_from_huggingface.py` | 从 Hugging Face 下载稳定镜像或历史快照。 |
  | `sync-hf\auto_sync_outline_to_huggingface.ps1` | 自动备份入口：启动必要容器、调用主同步脚本、写日志和每小时托盘摘要。 |
  | `sync-hf\run_auto_sync_hidden.vbs` | 隐藏窗口调用自动同步脚本，供 Windows 计划任务使用。 |
  | `sync-hf\hf.env.example` | Hugging Face 配置模板，复制为 `hf.env` 后填写 token 和仓库 ID。 |
]

==== 3.5 不在 GitHub 仓库中的本地文件

#tablem[
  | 本地路径/文件 | 原因 |
  | :--- | :--- |
  | `hf.env` | 包含 Hugging Face token，已加入 `.gitignore`，必须保密。 |
  | `OutlineDesktop\` | Outline 桌面客户端二进制，从官方下载，不入库。 |
  | `caddy\extracted\` | Caddy 二进制和许可证，从官方下载，不入库。 |
  | `redis-backup\` | Redis 数据备份目录，不入库，不要删除。 |
  | `sync-hf\logs\` | 自动同步日志，不入库。 |
  | `sync-hf\_snapshots\`、`sync-hf\.cache\` | 本地下载缓存，不入库。 |
  | `alpehuez-page.html`、`share-*.html` | 分享页验证快照，不入库。 |
]

=== 4. docker-compose.yml

```yaml
services:
  outline:
    image: outlinewiki/outline:latest
    env_file: ./env.outline
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
      - minio
    restart: always

  redis:
    image: redis:alpine
    command: redis-server --appendonly yes --aof-load-corrupt-tail-max-size 4194304
    volumes:
      - redisdata:/data
    restart: always

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: outline
      POSTGRES_PASSWORD: outlinepassword
      POSTGRES_DB: outline
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: always

  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: miniopassword
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - miniodata:/data
    restart: always

volumes:
  pgdata:
  redisdata:
  miniodata:
```

说明：

- `outline` 容器挂载 `patches\index.B2Khpv-E.js` 为只读前端文件，用于修复复制、移动、归档后侧边栏不立即刷新的问题。
- Redis 使用 `aof-load-corrupt-tail-max-size` 容错，异常关机后的小段 AOF 尾部损坏可自动跳过。

=== 5. env.outline 关键配置

```dotenv
NODE_ENV=production
FORCE_HTTPS=false
URL=https://outline.20211003.xyz
PORT=3000

SECRET_KEY=替换为64位十六进制
UTILS_SECRET=替换为另一串64位十六进制

PGSSLMODE=disable
DATABASE_URL=postgres://outline:outlinepassword@postgres:5432/outline
REDIS_URL=redis://redis:6379

FILE_STORAGE=s3
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=miniopassword
AWS_REGION=us-east-1
AWS_S3_UPLOAD_BUCKET_NAME=outline
AWS_S3_UPLOAD_BUCKET_URL=https://s3.20211003.xyz
AWS_S3_FORCE_PATH_STYLE=true

DEFAULT_LANGUAGE=zh_CN
ENABLE_EMAIL_AUTH=true
SMTP_HOST=smtp.qq.com
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USERNAME=你的QQ邮箱
SMTP_PASSWORD=邮箱授权码
SMTP_FROM_EMAIL=你的QQ邮箱
SMTP_REPLY_EMAIL=你的QQ邮箱
```

注意：

- `URL` 使用公网主域名，不使用 `https://localhost`。
- `AWS_S3_UPLOAD_BUCKET_URL` 使用 `https://s3.20211003.xyz`，不要拼接 `/outline`。

OAuth 回调：

- Discord：在 Discord Developer Portal 的 OAuth2 Redirects 中添加 `https://outline.20211003.xyz/auth/discord.callback`。
- Google：在 Google Cloud Console 的 Authorized redirect URIs 中添加 `https://outline.20211003.xyz/auth/google.callback`。
- 不要使用 `https://localhost` 作为回调地址；保存 OAuth 配置后重启 Outline 容器生效。

=== 6. 图片与附件直连

`add_s3_hosts.ps1` 会自动维护 hosts 中的 `outline.20211003.xyz`、`s3.20211003.xyz` 以及活动分享子域，例如：

```text
127.0.0.1 outline.20211003.xyz
127.0.0.1 s3.20211003.xyz
127.0.0.1 alpehuez-tutorial.20211003.xyz
```

管理员 PowerShell 执行：

```powershell
.\add_s3_hosts.ps1
```

Caddy 配置：

```caddyfile
https://s3.20211003.xyz {
    tls internal
    handle /outline {
        reverse_proxy localhost:9000 {
            header_up Host {host}
        }
    }
    handle /outline/* {
        reverse_proxy localhost:9000 {
            header_up Host {host}
        }
    }
}
```

=== 7. 公网访问加速（隧道走校园网快链路）

如果电脑同时连接多个 Wi-Fi（例如 USB 网卡 + 校园网），打开公网分享链接可能很慢。原因是 Windows 会把默认路由按权重分摊到多个网卡，隧道流量一旦被分到差链路（丢包、高延迟），分享页面就会反复重传。

查看当前默认路由，确认是否存在多条：

```powershell
route print -4 | findstr "0.0.0.0"
```

把 Outline 隧道固定到快链路（只影响发往 Cloudflare 的流量）：

+ 右键开始菜单，选择"终端（管理员）"。
+ 执行：

```powershell
cd D:\YL2026\launch\Outline
.\optimize_cloudflare_route.ps1
```

脚本功能：

- 自动识别校园网卡（别名 `WLAN`）及其 IPv4/IPv6 网关。
- 为 Cloudflare 官方发布的 15 个 IPv4 网段和 7 个 IPv6 网段添加持久路由（metric=1，绑定校园网卡），使 Outline 公网隧道走快链路。
- 只影响目的地是 Cloudflare 的流量（隧道与公开分享），其他软件的路由、网卡和代理设置均不变。
- 隧道到 Cloudflare 是普通 HTTPS/QUIC 直连，不经过任何代理软件，不违反校园网禁止使用代理的规定。
- 校园网网关变化后，重新运行脚本即可自动重建路由。

验证效果：

```powershell
ping.exe -n 10 104.16.16.16
```

修复前若丢包、延迟高，修复后通常接近 0% 丢包、几十毫秒，公网分享页面加载时间也会从数秒降到几十毫秒。

==== 7.1 访客访问提速：Cloudflare 边缘缓存（免费）

路由固定解决的是丢包；但每个访客请求仍要走「访客 → Cloudflare 边缘 → 隧道 → 你的电脑」一整趟，实测单趟往返约 1 秒，分享页面首次打开约 3 秒。原因是 Cloudflare 免费套餐默认对动态页面不缓存（`cf-cache-status: DYNAMIC`），对静态资源也不缓存（`BYPASS`）。

给域名添加缓存规则（Cache Rules）后，常用内容缓存在 Cloudflare 边缘，访客不再每次都连到你的电脑。Cache Rules 免费套餐可用，上限 10 条，本方案只用到 3 条，不产生任何费用。

#tablem[
  | 规则 | 作用范围 | 边缘缓存时长 | 说明 |
  | :--- | :--- | :--- | :--- |
  | 前端静态资源 | `/static/*` | 1 年 | 文件名带哈希、不可变，缓存 1 年安全 |
  | 分享页 HTML | `/s/*` | 60 秒 | 笔记修改后最多 60 秒内生效 |
  | 分享子域名根路径 | 根路径 `/`（排除 `outline`、`s3` 子域） | 60 秒 | 访客打开分享链接时的 302 重定向 |
]

配置后效果：缓存命中时页面加载约 0.5 秒；缓存刚过期重新回源时约 1~1.5 秒，相比原来的 3 秒明显提升。

在 Cloudflare 后台 *Caching → Cache Rules* 可手动创建这些规则，也可以用自动化脚本（见下文办法一）直接调用 API 创建。

==== 7.2 办法一：直接把 Zone ID 手动喂给自动化脚本（最快、推荐）

自动化脚本通过 Cloudflare API 配置上面的缓存规则时需要定位你的域名。如果脚本自己查不到 Zone ID，直接把 ID 提供给脚本，脚本就能跳过查询继续配置：

+ 回到 Cloudflare 后台，点击进入你的 `20211003.xyz` 域名主页（Overview / 概述）。
+ 在该页面的右侧边栏稍微往下滚一点，会看到一栏叫 *API*。
+ 里面有一个 *Zone ID*，点击下方的 *Click to copy* 复制那串代码。
+ 回到你运行自动化脚本的对话框，直接告诉它：「我的 Zone ID 是 [粘贴你刚才复制的字符]」。

#quote-block[
注意：调用 Cloudflare API 需要在后台创建 API Token，权限包含 `Zone → Zone → Read` 和 `Zone → Zone Settings → Edit`，资源范围只选 `20211003.xyz` 这一个域名；配置完成后如不需要，可在后台删除该 Token。
]

=== 8. 启动与验证

```powershell
.\start_outline.ps1
```

只启动 Web 服务：

```powershell
.\start_outline.ps1 -NoDesktop
```

验证：

```powershell
docker compose ps
curl.exe --insecure -s -o NUL -w "%{http_code}" https://outline.20211003.xyz
curl.exe --insecure -s -o NUL -w "%{http_code}" https://s3.20211003.xyz/outline
```

=== 9. 公网分享

在 Outline 中启用“Anyone with the link”分享后：

```powershell
python .\sync_share_domains.py
```

效果：

- 主程序固定为 `https://outline.20211003.xyz`。
- 每个公开分享自动分配独立子域名。
- 分享删除后，旧子域名返回 404。
- 活动分享的标题域名优先；笔记更名后，标题域名会指向当前同名笔记，旧别名仅在无冲突时保留。
- 同名笔记通过分享 ID 区分：`sync_share_domains.py` 会为主域分配唯一子域，必要时追加短 ID 后缀，避免撞名。

每 2 分钟自动同步：

```powershell
schtasks /Create /F /SC MINUTE /MO 2 /TN "Outline Share Domains" /TR "wscript.exe D:\YL2026\launch\Outline\run_auto_share_domains_hidden.vbs"
```

=== 10. GitHub 备份

```powershell
.\backup_to_github.ps1
```

仓库：

```text
https://github.com/Helloxiaolaodi/Outline_local.git
```

#line()

== 第二部分：Outline 基本使用

=== 1. 电脑开机后

日常启动流程：

+ 打开 Docker Desktop，等待状态变为 `Running`。
+ 启动 Outline 桌面软件，操作见下一节。

`docker-compose.yml` 中的 Outline、PostgreSQL、Redis、MinIO 均配置了 `restart: always`，打开 Docker Desktop 后容器会自动恢复，日常不需要手动执行容器启动命令。

如果容器没有自动恢复，或需要同时启动 Caddy，再执行完整启动脚本：

```powershell
cd D:\YL2026\launch\Outline
.\start_outline.ps1
```

`start_outline.ps1` 会依次完成：启动 Docker Desktop、等待 Docker 就绪、启动 Outline/PostgreSQL/Redis/MinIO 容器、启动 Caddy、最后自动打开 Outline 桌面软件。

=== 2. 启动 Outline 桌面软件

桌面有三个快捷方式（由 `create_desktop_shortcuts.ps1` 创建）：

- `Outline`：直接打开桌面软件，适合服务已启动时使用。
- `Outline Start`：一键完整启动（Docker Desktop、容器、Caddy、桌面软件）。
- `Outline Stop`：一键停止（关闭桌面软件、停止容器、退出 Docker Desktop）。

有两种方式：

==== 方式一：直接启动桌面软件

+ 双击桌面上的 `Outline` 图标，或运行：

```powershell
Start-Process -FilePath "D:\YL2026\launch\Outline\OutlineDesktop\Outline.exe" -ArgumentList "--ignore-certificate-errors"
```

+ 在桌面客户端输入服务器地址：

```text
localhost
```

+ 点击连接，使用邮箱或已配置的 OAuth 登录。

#quote-block[
如果桌面客户端提示无法连接，先确认 Docker Desktop 状态为 `Running`，再确认容器已恢复；仍无法连接时再执行 `start_outline.ps1`。
]

==== 方式二：通过启动脚本

```powershell
cd D:\YL2026\launch\Outline
.\start_outline.ps1
```

脚本会自动启动 Docker Desktop、等待 Docker 就绪、恢复容器、启动 Caddy、写入代理直连规则，并打开 Outline 桌面软件。

若只启动 Web 服务：

```powershell
.\start_outline.ps1 -NoDesktop
```

=== 3. 启动 Outline 浏览器访问

+ 打开浏览器。
+ 访问：

```text
https://localhost
```

+ 公网访问时使用：

```text
https://outline.20211003.xyz
```

=== 4. 笔记结构

Outline 层级：

```text
文档集 Collection
└── 文档 Document
    ├── 子文档 Subdocument
    │   └── 子子文档 Sub-subdocument
    └── 子文档
```

建议：

- 按主题建立文档集。
- 文档集下按大纲组织文档。
- 层级不要超过 4 层，便于导航和搜索。

=== 5. 创建和编辑笔记

创建文档：

+ 进入文档集。
+ 点击 `New document`。
+ 输入标题和正文。

创建子文档：

+ 打开父文档。
+ 点击右上角 `...`。
+ 选择 `New nested document`。

编辑：

- 支持 Markdown。
- 支持 `/` 插入表格、代码块、图片等。
- 支持拖拽图片到正文上传。

=== 6. 复制笔记

+ 打开要复制的笔记。
+ 点击右上角 `...`。
+ 选择 `Duplicate`。
+ 侧边栏应立即显示复制结果。

如果未显示，先清理旧前端缓存并刷新页面：

```powershell
curl.exe --insecure -s -o NUL -w "%{http_code}" https://localhost
```

浏览器清除 Service Worker 与站点缓存后重新加载。桌面客户端可完全退出后重新打开。

注意：侧栏未刷新不是后端未保存，刷新页面后内容仍在。当前容器挂载了本地前端补丁 `patches\index.B2Khpv-E.js`，复制、移动、归档操作会主动刷新受影响文档集的侧边栏；镜像升级后需按 `patches\README.md` 重建补丁。

=== 7. 公开分享

==== 分享文档

+ 打开文档。
+ 点击 `Share`。
+ 选择 `Anyone with the link`。
+ 复制分享链接。

公开后：

- 自动生成独立子域名。
- 子文档也随父文档可见。

==== 分享文档集

+ 打开文档集。
+ 点击 `Share collection`。
+ 选择 `Anyone with the link`。

公开后，文档集下所有文档、子文档均可见。

=== 8. 每日关闭

最快捷操作：双击桌面 `Outline Stop`，或执行：

```powershell
cd D:\YL2026\launch\Outline
.\stop_outline.ps1
```

脚本会依次：关闭桌面客户端（保存前请先手动保存编辑内容）、停止容器、退出 Docker Desktop；加 `-KeepDocker` 参数可保留 Docker Desktop 运行。

以下为手动分步操作：

==== 关闭 Outline 桌面软件

+ 保存所有编辑内容。
+ 关闭 Outline 桌面窗口。
+ 确认桌面进程已退出：

```powershell
Get-Process Outline -ErrorAction SilentlyContinue
```

==== 关闭浏览器中的 Outline

+ 退出登录。
+ 关闭浏览器标签页。
+ 如果使用专用浏览器，退出浏览器。

==== 关闭 Docker Desktop

+ 在系统托盘右键单击 Docker Desktop 图标，选择 `Quit Docker Desktop`；或在 PowerShell 中执行：

```powershell
docker desktop stop
```

+ 确认 Docker Desktop 已退出。

#quote-block[
说明：日常关闭只执行以上两步。`docker compose down` 只会停止并移除 Outline 的容器，不会退出 Docker Desktop，也不清除数据卷；数据仍保留在 Docker 数据卷中。当 Docker Desktop 已经退出后再执行 `docker compose ps`，会提示 `cannot connect to the docker API ... daemon is running`，这是正常现象，不代表关闭命令有错误。
]

==== 可选：关闭 Caddy 和 Cloudflare Tunnel

日常关闭只需要退出 Outline 桌面软件和 Docker Desktop。需要彻底停止本地代理与公网入口时，再执行：

```powershell
Stop-Process -Name caddy
Stop-Service Cloudflared
```

#quote-block[
注意：关闭 Docker Desktop 后公网已经无法访问 Outline，属于正常现象。
]

#line()

== 第三部分：从 Hugging Face 下载 Outline 备份笔记

=== 1. Hugging Face 镜像结构

备份仓库：

```text
Helloxiaolaodi/Outline
```

笔记导出目录：

```text
outline_docs/<collection>/<document>/<subdocument>/<title>.md
```

结构规则：

- 有子笔记的父笔记是文件夹，自己的笔记为同名 Markdown 文件，例如 `English/English.md`。
- 无子笔记的叶子笔记直接输出为 `Title.md`，不额外套一层文件夹。
- 每个 Markdown 文件包含 YAML 元信息，中文标题保持 UTF-8。

```text
outline_docs/
├── AlpeHuez-Tutorial/
│   └── Software/
│       ├── English/
│       │   ├── 1. Notes, Knowledge & Mind Maps.md
│       │   └── English.md
│       └── 中文/
│           └── 1. 笔记、知识库与思维导图.md
└── README.md
```

=== 2. Windows 下载

==== 方法一：网页下载

+ 打开浏览器。
+ 访问：

```text
https://huggingface.co/datasets/Helloxiaolaodi/Outline/tree/main/outline_docs
```

+ 进入 `outline_docs`。
+ 进入 `collection` 文件夹。
+ 进入文档文件夹。
+ 下载笔记对应的同名 `.md` 文件。

==== 方法二：Git 下载

+ 安装 Git。
+ 执行：

```powershell
git clone https://huggingface.co/datasets/Helloxiaolaodi/Outline
```

+ 进入目录：

```powershell
cd Outline
```

+ 打开 `outline_docs`。

=== 3. macOS 下载

+ 安装 Git。
+ 打开 Terminal。
+ 执行：

```bash
git clone https://huggingface.co/datasets/Helloxiaolaodi/Outline
```

+ 进入目录：

```bash
cd Outline
```

+ 打开 `outline_docs`。

=== 4. Linux 下载

+ 安装 Git。

```bash
sudo apt update && sudo apt install -y git
```

+ 执行：

```bash
git clone https://huggingface.co/datasets/Helloxiaolaodi/Outline
```

+ 进入目录：

```bash
cd Outline
```

+ 打开 `outline_docs`。

=== 5. 下载单个笔记

网页访问：

```text
https://huggingface.co/datasets/Helloxiaolaodi/Outline/blob/main/outline_docs/<collection>/<document>.md
```

点击 `Download` 按钮。

=== 6. 恢复备份

本地恢复完整备份：

```powershell
cd D:\YL2026\launch\Outline
.\sync-hf\sync_outline_to_huggingface.ps1 -Restore -Snapshot latest
```

#quote-block[
恢复会覆盖当前 Outline 数据，请先确认备份已保存。
]

#line()

=== 附录：常用命令

```powershell
# 启动
.\start_outline.ps1

# 停止
.\stop_outline.ps1

# 查看容器
docker compose ps

# 查看日志
docker compose logs -f outline

# 重建 Outline
docker compose up -d --force-recreate outline

# 同步分享子域名
python .\sync_share_domains.py

# 优化公网分享网络（管理员运行）
.\optimize_cloudflare_route.ps1

# Hugging Face 同步
.\sync-hf\sync_outline_to_huggingface.ps1

# GitHub 推送
.\backup_to_github.ps1
```
