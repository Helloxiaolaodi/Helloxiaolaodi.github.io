#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *
#import "@preview/theorion:0.6.0": quote-block

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "科研江湖之服务器的 Git 使用",
  description: "在 HPC 服务器上使用老旧 Git、无 root 配置 SSH 密钥、多分支协作与日常 push/pull 的完整方案。",
  date: datetime(year: 2026, month: 7, day: 17),
  lang: "zh",
)

= 科研江湖之服务器的 Git 使用

这篇手册记录的是在科研服务器上使用 Git 进行版本控制的完整方案。它围绕 HPC（如 `cu01`）的真实使用场景来做取舍：老旧 Git 版本（1.8.3.1）的兼容性处理、无需 root 权限的 SSH 密钥配置、多分支协作与代码同步、以及日常 push/pull 的高效工作流。

整套方案聚焦真正高频且稳定的操作：SSH 密钥认证、HTTPS/SSL 报错的解决、Personal Access Token 的替代方案、分支切换与查看、以及最核心的 `git status` → `git add` → `git commit` → `git push` 四步工作流。

=== 1. 最终效果与适用场景

这套 Git 配置适合以下场景：

- 在 Linux 服务器或 HPC 集群（如 `cu01`）上维护科研项目的代码仓库
- 服务器上的 Git 版本老旧（如 CentOS 7 自带的 Git 1.8.3.1），无法直接通过 HTTPS 克隆 GitHub 仓库
- 需要在服务器端修改脚本，并定期推送到 GitHub 进行备份和多端同步
- 需要在服务器上切换多分支（`main`、开发分支、个人分支）
- 不想每次 push/pull 都输入密码

配置完成后可以实现的效果：

- SSH 密钥认证：一次配置，终生免密 push/pull
- 安全绕过老旧 Git 的 HTTPS/SSL 报错
- 多分支无缝切换与同步
- 完整的 daily workflow：`git status` → `git add` → `git commit` → `git push`

=== 2. 预先检查：先确认哪些已安装、哪些还没配

在做任何修改之前，建议先盘点当前 Git 环境。

==== 2.1 检查 Git 版本

```bash
git --version
```

如果输出类似 `git version 1.8.3.1`，说明是 CentOS 7 的默认老旧版本。这个版本在通过 HTTPS 克隆 GitHub 仓库时会遇到 SSL 报错（见第 5.1 节和第 9.1 节），推荐使用 SSH 方案绕过。

==== 2.2 检查 SSH 密钥是否已存在

```bash
ls -la ~/.ssh/
```

如果看到 `id_rsa` 和 `id_rsa.pub` 两个文件，说明已经生成过密钥。如果没有，需要按第 5.2 节生成。

==== 2.3 检查 Git 身份配置

```bash
git config --global user.name
git config --global user.email
```

如果返回空或不是你期望的值，需要按第 5.4 节配置。

==== 2.4 检查远程仓库 URL（如果已经克隆过）

进入仓库目录后运行：

```bash
git remote -v
```

如果远程 URL 以 `https://` 开头，且你的服务器 Git 版本 ≤ 1.8.3.1，强烈建议改为 SSH 格式（见第 3 节）。

=== 3. 完整的 SSH 密钥认证 + Git 仓库配置方案

下面是从零开始在服务器上完整配置 Git + SSH 的标准流程。如果你服务器上还没有任何配置，直接按顺序执行即可。

*第一步：生成 SSH 密钥对*

在终端运行以下命令（一路按回车，不需要设置 passphrase）：

```bash
ssh-keygen -t rsa -b 4096 -C "你的GitHub注册邮箱"
```

当提示 `Enter file in which to save the key` 时，直接按回车使用默认路径（`~/.ssh/id_rsa`）。接着提示 `Enter passphrase` 时，直接再按两次回车（留空即可，这样以后 push/pull 不会反复要求输入密码）。当屏幕上出现 Randomart image 矩形图案时，说明密钥生成成功。

*第二步：复制公钥内容*

```bash
cat ~/.ssh/id_rsa.pub
```

将终端打印的全部内容（以 `ssh-rsa` 开头，以你的邮箱结尾）完整复制。

*第三步：将公钥添加到 GitHub*

+ 浏览器打开 GitHub → 点击右上角头像 → *Settings*
+ 左侧点击 *SSH and GPG keys* → 点击绿色的 *New SSH key*
+ Title 随便填（例如 `HPC-cu01`），Key type 保持默认的 Authentication Key
+ 将刚才复制的公钥粘贴到大文本框里，点击 Add SSH key 保存

*第四步：设置 Git 身份信息*

```bash
git config --global user.name "你的GitHub用户名"
git config --global user.email "你的GitHub注册邮箱"
```

*第五步：使用 SSH 链接克隆仓库*

将原 HTTPS 链接替换为 SSH 格式：

```bash
git clone git@github.com:用户名/仓库名.git /目标/路径/
```

#quote-block[
*首次连接 GitHub 的重要提醒：* 终端会弹出一长串提示询问是否信任该主机：
`Are you sure you want to continue connecting (yes/no)?`
*请务必键盘敲入完整的 `yes` 三个字母再按回车*（不要只输 `y` 或直接回车）。只要这一次成功输入了 `yes`，以后对 GitHub 的任何 Git 操作都不会再弹出提示。
]

=== 4. 最小改动版：已有 SSH 密钥，只需克隆和配置

如果你的服务器已经配好了 SSH 密钥（即 `~/.ssh/id_rsa.pub` 的公钥已添加到 GitHub），只需要两步即可开始工作：

*第一步：设置 Git 身份（仅需执行一次）*

告诉 Git 你是谁，否则提交代码时会报错：

```bash
git config --global user.name "你的GitHub用户名"
git config --global user.email "你的GitHub注册邮箱"
```

*第二步：使用 SSH 链接克隆仓库*

```bash
git clone git@github.com:用户名/仓库名.git /目标/路径/
```

到此为止就可以正常使用了。之后所有 `git push`、`git pull` 都不需要输入密码。

=== 5. 各操作的详解、配置、验证与使用

=== 5.1 Git Clone：HTTPS 与 SSH 的差异 & 老旧 Git 的 SSL 坑

`git clone` 有两种方式：

#tablem[
  | 方式 | 命令示例 | 优点 | 缺点 |
  | :--- | :--- | :--- | :--- |
  | HTTPS | `git clone https://github.com/...` | 无需额外配置 | Git 1.8.3.1 有 SSL 报错；2021 年起必须用 Token 替代密码 |
  | SSH | `git clone git@github.com:...` | 一次配置终生免密；绕过 SSL 问题 | 需要生成密钥并添加到 GitHub |
]

*功能优势*

- SSH 方式不需要每次输入密码
- SSH 方式完全绕开 Git 1.8.3.1 的 TLS/SSL 兼容性问题
- 克隆时可以指定目标路径，无需提前 cd 到目标目录

*HTTPS 方式的基本用法*

```bash
git clone https://github.com/用户名/仓库名.git /目标/路径/
```

如果目标目录不存在，需要先创建前置目录：

```bash
mkdir -p /目标/路径的父目录/
```

*SSH 方式的基本用法*

```bash
git clone git@github.com:用户名/仓库名.git /目标/路径/
```

#quote-block[
*⚠️ Git 1.8.3.1 的 SSL 报错：* CentOS 7 自带的 Git 1.8.3.1 在使用 HTTPS 克隆 GitHub 时，大概率会报 `fatal: unable to access 'https://github.com/...': SSL connect error`。这是因为 GitHub 多年前已禁用了旧版 TLS 加密协议。*强烈推荐直接改用 SSH 方式克隆*，一劳永逸。
]

=== 5.2 SSH 密钥认证：生成、添加、验证

*功能优势*

- 一次配置，永久生效，后续所有 `git push`/`git pull` 都不需要输入账号密码
- 完全绕过老旧 Git 版本的 HTTPS/SSL 兼容性问题
- 适合在 HPC 和服务器上长期维护代码仓库

*生成密钥（服务器端）*

```bash
ssh-keygen -t rsa -b 4096 -C "你的邮箱"
```

当出现：
- `Enter file in which to save the key (/home/用户名/.ssh/id_rsa):` → 直接按回车
- `Enter passphrase (empty for no passphrase):` → 直接按回车（留空）
- `Enter same passphrase again:` → 再次直接按回车

当屏幕上出现 Randomart image 后说明生成成功。

*复制公钥*

```bash
cat ~/.ssh/id_rsa.pub
```

将输出内容完整复制，以 `ssh-rsa` 开头、邮箱结尾。

*添加到 GitHub（浏览器端操作）*

Settings → SSH and GPG keys → New SSH key → 粘贴公钥 → Add SSH key

*验证是否配置成功*

```bash
ssh -T git@github.com
```

如果看到 `Hi 用户名! You've successfully authenticated...` 说明配置成功。

=== 5.3 Personal Access Token：当必须使用 HTTPS 时的替代方案

如果你因为某些原因无法使用 SSH，只能通过 HTTPS 克隆和推送，你需要一个 *Personal Access Token (PAT)* 来替代密码。

#quote-block[
*背景：* GitHub 已于 2021 年完全废除使用账户登录密码进行 HTTPS 认证的方式。当你用 HTTPS clone 后执行 `git push`，终端提示输入 Password 时，如果你输入的是 GitHub 账户密码，会直接报 `Authentication failed`。
]

*生成 Token 的步骤*

+ 浏览器登录 GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
+ 点击 *Generate new token (classic)*
+ Note 随便填（如 "HPC\_Clone"），Expiration 选有效期
+ *Select scopes 中勾选 `repo`*（控制私有仓库的全部权限）
+ 点击生成，*立即复制那一长串 Token*（通常以 `ghp_` 开头，关闭页面后无法再查看）

*在服务器上使用 Token*

当 `git clone` 或 `git push` 提示输入用户名和密码时：

- *Username*: 输入你的 GitHub 用户名
- *Password*: 粘贴你刚才复制的 Token（Linux 终端粘贴时屏幕不会回显任何字符，粘贴完直接按回车即可）

#quote-block[
注意：Token 方式每次 push 都要输入，且只适用于 Git 版本较新、SSL 库正常的服务器。如果服务器是 Git 1.8.3.1，SSL 报错仍然无法避免，此时必须使用 SSH 方案。
]

=== 5.4 Git 身份配置

*功能优势*

- 每次 commit 时 Git 需要知道是谁提交的
- 不配置时会直接报错，拒绝提交

*检查是否已配置*

```bash
git config --global user.name
git config --global user.email
```

*配置操作*

```bash
git config --global user.name "你的GitHub用户名"
git config --global user.email "你的GitHub注册邮箱"
```

*检查配置成功*

```bash
git config --global --list | grep user
```

=== 5.5 分支管理：查看、切换、创建

*功能优势*

- 在多个开发线之间独立工作，互不干扰
- 克隆时默认只显示仓库的默认分支内容，但所有分支数据均已下载

*查看当前所在分支*

```bash
git branch
```

_屏幕上列出本地分支，前面带星号（`*`）并标绿的就是当前分支。_

*查看所有分支（含远程分支）*

```bash
git branch -a
```

*切换分支*

```bash
git checkout 目标分支名
```

_注：由于服务器 Git 版本较旧（1.8.3.1），切换分支必须使用 `checkout` 命令。新版本的 `git switch` 命令不可用。_

*创建新分支并切换过去*

```bash
git checkout -b 新分支名
```

*检查配置成功*

```bash
git branch
git log --oneline -5
```

=== 5.6 日常 Push 工作流：将服务器修改推送到 GitHub

当你在服务器上修改了脚本或数据，需要备份到 GitHub 时，按顺序执行以下 4 步：

*第一步：查看文件修改状态*

```bash
git status
```

_屏幕上会用红色字体列出所有被修改或新建的文件。_

*第二步：将所有修改添加到暂存区*

```bash
git add .
```

_注意 `add` 后面有一个空格和一个点 `.`，代表当前目录下的所有文件。如果只想上传单个文件，可以写成 `git add your_script.R`。_

*第三步：提交更改并添加备注*

```bash
git commit -m "更新了数据过滤逻辑，优先保留P-前缀样本"
```

_引号内替换为你本次修改的具体内容，方便日后溯源。_

*第四步：推送到 GitHub*

```bash
git push
```

_因为已经配置了 SSH，敲击回车后会自动上传，无需再输入密码。_

*检查配置成功*

```bash
git log --oneline -3
```

=== 5.7 日常 Pull 同步：从 GitHub 拉取代码到服务器

*功能优势*

- 将笔记本电脑或 GitHub 网页端的修改同步到服务器
- 保持所有端代码一致，避免冲突

*基本用法*

```bash
git pull
```

_这会自动把 GitHub 上的最新进展下载并合并到你服务器的当前目录中。_

*只查看不合并（安全预览远程变更）*

```bash
git fetch
git diff origin/当前分支名
```

*检查配置成功*

```bash
git log --oneline -5
```

=== 5.8 查看历史与状态

*功能优势*

- 随时了解代码的演变历史
- 在排查问题时快速定位改动时间点和责任人

*查看提交历史*

```bash
git log --oneline
git log --oneline -10
```

*查看某次提交的详细改动*

```bash
git show 提交哈希值
```

*查看已暂存但未提交的改动*

```bash
git diff --cached
```

*查看未暂存的改动*

```bash
git diff
```

*查看当前状态*

```bash
git status
```

=== 6. 新服务器从零到一的完整配置命令

如果拿到一台全新的服务器账号，只需要按顺序执行以下命令，即可完成从零开始的完整 Git + SSH 配置：

```bash
# 第一步：生成 SSH 密钥（全部回车即可）
ssh-keygen -t rsa -b 4096 -C "你的邮箱"

# 第二步：查看公钥（复制全部输出内容，添加到 GitHub）
cat ~/.ssh/id_rsa.pub

# 第三步：设置 Git 身份
git config --global user.name "你的GitHub用户名"
git config --global user.email "你的GitHub注册邮箱"

# 第四步：使用 SSH 克隆仓库
git clone git@github.com:用户名/仓库名.git /目标/路径/

# 第五步：进入项目目录
cd /目标/路径/

# 第六步：查看并切换到目标分支（如需要）
git branch -a
git checkout 目标分支名
```

配置完后验证：

```bash
# 验证 SSH 连接
ssh -T git@github.com

# 验证 Git 配置
git config --global --list

# 验证远程仓库
git remote -v
```

=== 7. 高频使用姿势

配置完成后，平时最常用的通常就是下面这些动作。

==== 7.1 每日开始工作：先拉取最新代码

```bash
cd /项目/路径/
git pull
```

_养成习惯：每次在服务器上开始写新代码前，先 `git pull` 确保代码是最新的。_

==== 7.2 每日结束工作：推送到 GitHub 备份

```bash
git status
git add .
git commit -m "描述今天的修改"
git push
```

_每天工作结束准备关掉终端前，顺手走一遍这四步，相当于把 GitHub 当成了最安全的云端备份。_

==== 7.3 在多分支之间切换

```bash
# 查看所有分支
git branch -a

# 切换到开发分支
git checkout Yanglun_v2

# 确认切换成功
git branch
```

_切换到某个分支后，文件夹里的文件会自动变成该分支的内容。之后的 `git push` 也只会推送到该分支。_

==== 7.4 查看当前改了哪些文件

```bash
git status
git diff
```

==== 7.5 查看最近的提交记录

```bash
git log --oneline -5
```

==== 7.6 常见排错：Push 推送失败 (Rejected)

```bash
# 如果你在执行推送时报错退出，且提示 [rejected]：
# 推送失败的原因是：远程 GitHub 仓库的 Yanglun_v2 分支里，包含你当前本地服务器（cu01）上没有的更新。 这通常是因为你之前在网页端、其他电脑上修改过这个仓库，或者合并过其他内容。Git 为了防止你意外覆盖掉远程已有的数据，强制要求你先拉取（pull）最新进度，合并后再推送。
# 你可以按照以下顺序解决这个问题：

# (01). 配置默认推送模式（消除上方的一长串 warning 警告）
# 运行以下命令让 Git 默认只推送当前分支，这样以后的界面会更清爽：

git config --global push.default simple

# (02). 拉取远程更新并合并（将 GitHub 上的最新修改同步到本地）

git pull origin Yanglun_v2
# 注意：Git 可能会自动生成一个合并记录，并弹出一个文本编辑器（nano 或 vim）让你确认提交信息。
# 如果进入了 vim 界面，直接输入 :wq 然后按回车即可保存退出。
# 如果提示有“冲突 (conflict)”，说明远程和你本地修改了同一个文件的同一部分（不过对于 .biom 这样的数据文件，通常只是新增了历史记录，不会直接代码冲突）。

# (03). 重新推送本地提交
# 合并完成后，再次执行推送命令，输入你的 SSH 密钥密码即可：

git push origin Yanglun_v2
```

=== 8. 注意事项

这套配置虽然已经比较稳，但在服务器环境里仍然有几条边界需要明确。

- *Git 1.8.3.1 的 HTTPS/SSL 问题无解，必须用 SSH。* 不要尝试在 CentOS 7 的 Git 1.8.3.1 上使用 HTTPS 克隆 GitHub 仓库，除非你有 root 权限升级 `nss` 和 `curl` 库（`sudo yum update -y nss curl libcurl`）。
- *GitHub 已于 2021 年废弃密码认证。* 如果用 HTTPS 方式，`Password` 栏必须填写 Personal Access Token，而不是你的 GitHub 登录密码。
- *首次 SSH 连接 GitHub 必须完整输入 `yes`。* 终端弹出 `Are you sure you want to continue connecting (yes/no)?` 时，只输 `y` 会卡住。务必敲入 `yes` 再回车。
- *不要在有未提交修改时切换分支。* 切换分支前先用 `git status` 确认工作区干净，或者先 `git stash` 暂存。
- *Push 前先 Pull。* 避免因为远程有新提交而导致 push 被拒绝。
- *`.gitignore` 要配好。* 不要把大型数据文件（如 `.biom`、`.fastq`、中间结果）提交到 Git。
- *每次操作前务必确认所在目录和分支。* 用 `pwd` 和 `git branch` 确认你在正确的仓库和分支中，避免误操作。

=== 9. 常见故障排查

==== 9.1 HTTPS 克隆时报 `SSL connect error`

原因：Git 1.8.3.1 不支持 GitHub 要求的新版 TLS 协议。

解决方案（优先级从高到低）：

+ *改用 SSH 方式克隆*（最推荐，见第 3 节）
+ 如果有 sudo 权限，升级加密库：`sudo yum update -y nss curl libcurl`

==== 9.2 `git push` 时报 `Permission denied (publickey)`

检查步骤：

```bash
# 确认密钥文件存在
ls -la ~/.ssh/id_rsa ~/.ssh/id_rsa.pub

# 确认 GitHub 能识别你的密钥
ssh -T git@github.com
```

如果 `ssh -T` 报 Permission denied，说明公钥没有正确添加到 GitHub。重新执行第 5.2 节的步骤，确保公钥完整复制并添加到了 GitHub。

==== 9.3 `git push` 时报 `Authentication failed`

如果你用的是 HTTPS 远程 URL，这个报错说明你输入了 GitHub 登录密码而不是 Personal Access Token。解决方案：

+ 改用 SSH（推荐，永久解决）
+ 或者在 `git push` 提示输入密码时使用 Token（见第 5.3 节）

==== 9.4 分支切换时报错 `error: Your local changes would be overwritten`

这说明你有未提交的修改。先处理修改再切换：

```bash
# 方案1：提交修改
git add . && git commit -m "保存当前修改"

# 方案2：暂存修改（稍后可通过 git stash pop 恢复）
git stash

# 然后切换分支
git checkout 目标分支
```

==== 9.5 `git push` 被拒绝（远程有新提交）

```bash
# 先拉取最新代码
git pull

# 解决冲突后重新推送
git push
```

==== 9.6 终端弹出 `gnome-ssh-askpass` 警告

这是因为服务器没有图形界面，Git 试图弹窗叫你输密码失败了，属于表面现象。解决方案：

```bash
unset SSH_ASKPASS
```

可以将这行加入 `~/.bashrc` 以永久生效。

=== 10. 最终结论

一套真正适合科研服务器的 Git 配置，关键不在于花哨的 GUI 工具，而在于把最核心的几个动作做到极致稳定：

- *SSH 密钥认证* 负责一劳永逸地消除密码输入和 SSL 兼容性问题
- *`git status` → `git add` → `git commit` → `git push`* 这个四步工作流负责日常的代码备份和多端同步
- *`git pull`* 负责保持代码最新
- *`git checkout`* 负责在多个开发分支之间灵活切换
- *Personal Access Token* 作为当 SSH 不可用时的备用方案

如果后续需要进一步优化，我的建议顺序是：先补 `.gitignore` 的精细配置（避免大文件误提交），再学习 `git stash` 和 `git rebase`，最后考虑 `git hooks` 等自动化流程。

== Hello World
