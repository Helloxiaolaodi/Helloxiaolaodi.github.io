#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *
#import "@preview/theorion:0.6.0": quote-block

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "科研江湖之 Rebased 版本控制秘笈",
  description: "从安装、快捷键、PowerShell 自动化到插件增强与拉取远程更新工作流，系统整理 Rebased Git 客户端的使用心法。",
  date: datetime(year: 2026, month: 6, day: 14),
  lang: "zh",
)

= 科研江湖之 Rebased 版本控制秘笈

#quote-block[
*卷首小引*

科研路上，数据纷繁，文件众多——输入文件、结果文件、代码脚本，若无妥善管理，必将陷入混乱泥沼。

此时，*Git 版本控制*横空出世，如同为科研工作者递上一把"时光倒流之剑"：可追溯任意时刻的文件状态、对比不同版本的差异、在多个分支间自由切换、防止误删误改的悲剧。

而 *Rebased* 神器，便是这把剑的趁手剑鞘——让版本控制变得简洁、直观、高效。

通过 Rebased，你可以方便地将：
- 📥 *输入文件*（原始数据、参数配置）
- 📊 *结果文件*（分析输出、图表报告）
- 💻 *工作文件*（代码脚本、处理流程）

*分门别类，纳入版本控制*，从此告别"final\_v2\_真的最终版\_这次一定是.docx"的噩梦！

此卷者，乃在下游历科研江湖所积之使用心法也。愿诸位同道展卷有得：文件有序，版本清晰，科研顺遂。

——杨某顿首
]

#line()

== 📜 总纲

- 第一章 神器缘起
  - 1.1 神器四大特点
- 第二章 安装入门
  - 2.1 Winget 快速入门（推荐）
  - 2.2 手动安装之道
- 第三章 快捷键心法
  - 3.1 三大心法传承途径
  - 3.2 快捷键速查表
- 第四章 PowerShell 自动化
  - 4.1 心法原理
  - 4.2 修炼步骤·四步成神
  - 4.3 实战演练
  - 4.4 此法六大优势
  - 4.5 常见劫难·破解之法
- 第五章 界面布局
  - 5.1 五大区域
- 第六章 基本操作
  - 6.1 初始操作
  - 6.2 仓库核心操作
  - 6.3 进阶操作
- 第七章 配置调教
  - 7.1 Git 配置·设定门规
- 第八章 插件增强
  - 8.1 BashSupport Pro — Shell 脚本炼丹炉
  - 8.2 GitToolBox — Git 状态千里眼
  - 8.3 Key Promoter X — 快捷键速成秘籍
  - 8.4 Rainbow Brackets — 括号配对慧眼
  - 8.5 插件安装总结·一键武装
  - 8.6 插件维护·定期保养
- 第九章 常见疑难
  - 9.1 疑难一：Rebased 会创建 .idea 目录吗？
  - 9.2 疑难二：Rebased 支持哪些操作系统？
  - 9.3 疑难三：如何更新 Rebased？
  - 9.4 疑难四：为何 Rebased Terminal 中无法更改窗口标题？
- 第十章 资源宝库
  - 10.1 官方资源·正宗门派
  - 10.2 学习资源·江湖秘笈
  - 10.3 其他 DetachHead 大侠之作
- 附录一 优势对比
  - 附1.1 相比命令行 Git
  - 附1.2 相比其他 Git 客户端
- 附录二 Quicker 正则清洗术·终端代码净化
  - 附2.1 基础写法
  - 附2.2 保留缩进的升级版
  - 附2.3 精准去掉行首 2 个空格
  - 附2.4 报错 Failed to paste image 的根因与处理
  - 附2.5 到底去哪里填正则
  - 附2.6 进阶方案：新建终端智能拼接组合动作
- 附录三 拉取远程仓库更新备忘录
  - 附3.1 场景一：日常简单更新
  - 附3.2 场景二：开源协作终极工作流

== 🎯 第一章 神器缘起

#quote-block[
💡 *引言*

工欲善其事，必先利其器。本章介绍 Rebased 的由来与特点。
]

*公元 2026 年 6 月 14 日｜初识神器*

话说这 *Rebased*，乃是基于 *IntelliJ 平台*（即 JetBrains 诸位大侠所铸之基业）开发的一款 Git 客户端神器。

其创造者 #link("https://github.com/DetachHead")[DetachHead] 大侠，取 JetBrains 强大的 IDE 基础设施之精华，剔除冗杂功能，专注于版本控制核心要务，打造出这款简洁高效的利器。

=== 1.1 神器四大特点

- 🚀 *根基深厚*：基于成熟的 IntelliJ 平台构建，稳如泰山
- 🎯 *专注核心*：界面简洁，直指 Git 操作要害
- 💪 *功能强大*：继承 JetBrains IDE 的优秀交互体验
- 🆓 *侠之大者*：开源项目，完全免费，为国为民

*项目地址*：#link("https://github.com/DetachHead/rebased")[https://github.com/DetachHead/rebased]


#line()

== 📦 第二章 安装入门

#quote-block[
💡 *引言*

神器降临，须得正确安装之法。本章介绍两种安装方式：快速入门与手动安装。
]

*公元 2026 年 6 月 14 日｜安装心法*

=== 2.1 Winget 快速入门（推荐）

若阁下之 Windows 系统已装有 *Winget 包管理器*，可运使以下口诀，瞬间召唤 Rebased：

```bash
winget install detachhead.rebased
```

#quote-block[
此法如同江湖中的"传送符"，一令既出，神器自至。
]

=== 2.2 手动安装之道

若阁下偏好亲力亲为，可按此步骤行事：

+ 前往 #link("https://github.com/DetachHead/rebased/releases")[Rebased GitHub Releases] 宝库
+ 寻得最新版本之安装包，下载之
+ 根据阁下之操作系统，选择对应安装文件
+ 运行安装程序，依提示完成大业

#quote-block[
古法虽繁，然掌控感十足，适合追求"眼见为实"的同道。
]

#line()

== ⌨️ 第三章 快捷键心法

#quote-block[
💡 *引言*

江湖传言：掌握快捷键者，如练成上乘轻功，键指之间，事半功倍！
]

*公元 2026 年 6 月 14 日｜键指如飞之术*

=== 3.1 三大心法传承途径

欲知 Rebased 全部快捷键，可循以下三条明路：

*心法一：设置界面探秘（推荐）*

+ 启动 Rebased 神器
+ 按下 `Ctrl + Alt + S`（此乃"开启秘籍"之咒）
+ 导航至 *Keymap* 区域（快捷键宝库）
+ 于此可览全部快捷键，更可搜索特定招式

#quote-block[
此法最为直观，如同翻阅武林秘笈，一览无余。
]

*心法二：帮助菜单寻宝*

+ 点击顶部菜单栏 *Help* → *Keyboard Shortcuts PDF*
+ 或选 *Help* → *Keymap Reference*

#quote-block[
若有现成的快捷键参考文档，此法最为便捷。
]

*心法三：快速查找大法*

按下 `Ctrl + Shift + A` 开启"查找操作"（Find Action）神功，搜索任何命令，即可见其对应快捷键。

#quote-block[
此法如同江湖中的"千里眼"，想找什么招式，一搜便知。
]

#line()

=== 3.2 快捷键速查表

#tablem[
  | 快捷键 | 功能 | 白话注解 |
  | :--- | :--- | :--- |
  | `Ctrl + K` | 打开提交窗口 | 查看和提交本地更改，如同"整理包袱准备出发" |
  | `Ctrl + Shift + K` | 推送 | 将本地提交推送到远程仓库，如同"飞鸽传书" |
  | `Ctrl + T` | 更新项目 | 从远程仓库拉取最新更改，如同"接收武林快报" |
  | `Alt + 9` | 打开 Git 工具窗口 | 显示/隐藏版本控制面板，如同"翻开武功秘笈" |
  | `Alt + ` \` | VCS 操作弹窗 | 快速访问所有 Git 命令的菜单 ⭐ 此乃神键！ |
  | `Ctrl + Alt + Z` | 回滚更改 | 撤销对文件的修改，如同"时光倒流术" |
  | `Alt + F` | Fetch 拉取远程更新 | 从远程仓库下载最新代码到本地缓存，如同"接收远方飞鸽" |
]

#quote-block[
*🔥 江湖秘传*：`Alt + ` \`（反引号）乃是最重要的快捷键之一，按下此键，VCS 操作弹窗现世，所有 Git 招式尽在掌握！
]

#quote-block[
*🔑 快捷键绑定指南*：在 IntelliJ 系软件中搜索"Fetch"会显示好几个同名条目，它们底层调用的都是同一个 Git 命令，不用担心。推荐绑定方式：展开 *Main Menu → Git*，找到带有斜向下箭头图标的 *Fetch*（通常是第二个），右键点击选择 *Add Keyboard Shortcut*，按下 `Alt + F`，点击 OK 保存。绑定后回主界面按一下，如果右下角弹出 `Fetch Successful` 提示框，就说明设置完美生效！
]

*搜索与导航·轻功身法*

#tablem[
  | 快捷键 | 功能 | 白话注解 |
  | :--- | :--- | :--- |
  | `Shift + Shift` | 全局搜索 | 搜索文件、类、符号、操作等任何内容（双击 Shift 键） |
  | `Ctrl + Shift + E` | 最近位置 | 导航到最近编辑的位置，如同"记忆回溯术" |
  | `Alt + Home` | 导航栏 | 聚焦到导航栏，如同"鸟瞰地图" |
  | `Ctrl + E` | 最近文件 | 显示最近打开的文件列表 |
  | `Ctrl + N` | 查找类 | 按名称搜索类或文件 |
  | `Ctrl + Shift + N` | 查找文件 | 按文件名搜索项目中的文件 |
]

#quote-block[
*💡 秘诀*：双击 `Shift` 键（连续按两次）是 IntelliJ 平台最强大的搜索功能，被称为"*Search Everywhere*"（搜遍天下），可搜索几乎所有内容。
]

*编辑操作·剑法招式*

#tablem[
  | 快捷键 | 功能 | 白话注解 |
  | :--- | :--- | :--- |
  | `Ctrl + D` | 复制当前行 | 复制光标所在行或选中内容，如同"分身术" |
  | `Ctrl + W` | 扩展选择 | 智能扩展当前选择范围，如同"气功扩散" |
  | `Ctrl + Shift + W` | 收缩选择 | 与 Ctrl+W 相反，收缩选择范围 |
  | `Alt + Shift + ↑/↓` | 移动行 | 向上或向下移动当前行，如同"乾坤大挪移" |
  | `Ctrl + Shift + J` | 合并行 | 将下一行合并到当前行 |
  | `Ctrl + /` | 行注释 | 注释/取消注释当前行 |
  | `Ctrl + Shift + /` | 块注释 | 块注释/取消块注释 |
]

*工具窗口·机关术*

#tablem[
  | 快捷键 | 功能 | 白话注解 |
  | :--- | :--- | :--- |
  | `Alt + 1` | 项目窗口 | 打开/关闭项目文件树，如同"打开宝箱" |
  | `Alt + 9` | Git 窗口 | 打开/关闭版本控制面板 |
  | `Alt + F12` | 终端 | 打开/关闭集成终端，如同"召唤令牌" |
  | `Ctrl + ` \` | 快速切换 | 快速切换布局或视图模式 |
  | `Shift + Esc` | 关闭工具窗口 | 关闭当前活动的工具窗口 |
]

*通用操作·江湖常识*

#tablem[
  | 快捷键 | 功能 | 白话注解 |
  | :--- | :--- | :--- |
  | `Ctrl + Alt + S` | 打开设置 | 访问 IDE 设置和配置，如同"翻阅门规" |
  | `Ctrl + Shift + A` | 查找操作 | 搜索并执行任何 IDE 操作 |
  | `Ctrl + F4` | 关闭标签页 | 关闭当前编辑器标签 |
  | `Alt + ← / →` | 切换标签页 | 在打开的编辑器标签之间切换 |
  | `F11` | 切换书签 | 为当前行添加/移除书签 |
]

#quote-block[
此诸般快捷键，乃是 Rebased 之根基武学。熟练掌握后，操作如行云流水，事半功倍也！
]
#line()

== 🤖 第四章 PowerShell 自动化

#quote-block[
💡 *引言*

江湖传言：真正的高手，从不做重复的事！本章介绍如何通过 PowerShell 自动化快速启动项目。
]

*公元 2026 年 6 月 14 日｜自动化之道*

话说这 Rebased 虽为神器，然作为精简版 IDE，某些高级终端特性已被削去。吾遂另辟蹊径，修炼 *PowerShell 自动化心法*，将繁琐的路径切换与工具启动，浓缩为几个字母的快捷命令。

此法一旦练成，*指尖轻点，瞬息千里*！

=== 4.1 心法原理

通过配置 PowerShell 的 `$PROFILE` 文件（此乃 PowerShell 启动时自动加载之秘籍），创建自定义函数，将长如九曲回肠的项目路径与启动命令，炼化为极简口诀。

#quote-block[
用现代白话讲：把 `cd "D:\很长\很长\的路径"` 和 `启动命令` 打包成一个短命令，比如 `tc-ps-cl`，一敲回车，自动完成所有操作！
]

#line()

=== 4.2 修炼步骤·四步成神

==== 4.2.1 第一步：开启秘籍之门

在 PowerShell 中运行以下口诀：

```powershell
if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force } ; notepad $PROFILE
```

#quote-block[
*白话翻译*：这条命令会检查你的 PowerShell 配置文件是否存在，若无则自动创建，然后用记事本打开它。

此如同江湖中寻得一本空白武功秘笈，正待吾等挥毫泼墨！
]

==== 4.2.2 第二步：书写中转符咒

在弹出的记事本窗口中，添加以下内容（若文件已有内容，*务必添加到末尾另起一行*）：

```powershell
# 加载自定义配置脚本
. "D:\YL2025\2026\Scripts-github\scripts-template\powershell-profile.ps1"
```

保存文件并关闭记事本。

#quote-block[
*白话翻译*：这是一条"中转加载指令"，让系统默认的 `$PROFILE` 去调用你自定义路径的脚本文件。

如同设置"传送门"，一道门开，直达宝库！
]

#quote-block[
⚠️ *江湖警示·切莫贪图便捷*

切勿使用 `Add-Content` 等命令行方式追加此指令！如下命令看似便捷：

```powershell
Add-Content -Path $PROFILE -Value "`n# 加载自定义配置脚本`n. `"D:\...\powershell-profile.ps1`""
```

但 PowerShell 在终端中输入多行字符串时，*反引号换行符 #raw(" `n ") 可能被错误地拆分*，导致 profile 文件中 `.` 与路径被分置两行：

```powershell
.
"D:\YL2025\2026\Scripts-github\scripts-template\powershell-profile.ps1"
```

下次 `. $PROFILE` 加载时即报错：`管道元素中的"."后面缺少表达式`。

*正道*：老老实实用记事本手动粘贴，一行一行确认，方为稳妥之法！
]

==== 4.2.3 第三步：炼制绝技秘笈

在 `D:\YL2025\2026\Scripts-github\scripts-template\` 路径下创建 `powershell-profile.ps1` 文件，录入以下心法：

```powershell
# PowerShell Custom Configuration File
# Created: 2026-06-14
# Purpose: Quick shortcuts to launch project tools

# Launch Claude-TargetC-phenotypes
function tc-ps-cl {
    Clear-Host
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "  => Starting: Claude-TargetC-phenotypes" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host ""
    Set-Location "D:\YL2025\2026\Scripts-github\TargetC"
    claude
}

# Launch Codex-TargetC-phenotypes
function tc-ps-co {
    Clear-Host
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "  => Starting: Codex-TargetC-phenotypes" -ForegroundColor Magenta
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host ""
    Set-Location "D:\YL2025\2026\Scripts-github\TargetC"
    codex
}

# 更多自定义命令可依此格式添加...
```

#line()

#quote-block[
*心法解读*：
- `Clear-Host`：清屏，如同扫净桌面准备练功
- `Write-Host` 配合颜色参数：显示彩色横幅，标识项目身份
- `Set-Location`：切换到项目目录，如同瞬移至目标位置
- `claude` / `codex`：启动工具命令
]

==== 4.2.4 第四步：运功生效

回到 PowerShell 窗口，运行以下口诀：

```powershell
. $PROFILE
```

#quote-block[
*注意*：命令开头有一个点（`.`）和一个空格，这是 PowerShell 加载脚本的特殊语法。

此如同念动咒语，激活心法！若一切顺利，你会看到彩色的欢迎信息浮现。
]

=== 4.3 实战演练

配置完成后，你只需在 PowerShell 中轻敲短命令：

```powershell
tc-ps-cl  # 启动 Claude-TargetC-phenotypes 项目
```

瞬间，系统会自动：
+ *清屏*——扫净战场
+ *显示彩色横幅*——标识项目身份
+ *切换目录*——瞬移至项目文件夹
+ *启动工具*——召唤 Claude 助手

#quote-block[
整个过程行云流水，一气呵成！如同剑客拔剑出鞘，剑气纵横！
]

=== 4.4 此法六大优势

- ✅ *极简操作*：只需输入 2-5 个字符，无需记忆长如经文的路径
- ✅ *一次配置*：永久生效，重启系统也不会丢失，如同刻入骨髓的武学记忆
- ✅ *易于维护*：所有配置集中在一个文件，方便管理和修改
- ✅ *版本控制*：配置文件可纳入 Git 管理，随时同步至其他设备
- ✅ *高度灵活*：可为任意项目和工具创建自定义别名
- ✅ *视觉识别*：彩色横幅显示项目名称，多窗口工作一目了然

#line()

=== 4.5 常见劫难·破解之法

*劫难一：提示"无法加载，因为在此系统上禁止运行脚本"*

#quote-block[
此乃 Windows 系统对脚本的防护机制，需手动解除封印。
]

*破解之法*：
+ 以*管理员身份*运行 PowerShell（右键选择"以管理员身份运行"）
+ 执行以下咒语：

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

+ 确认后（输入 `Y`），重新运行 `. $PROFILE`

#quote-block[
此法如同向系统请得"免死金牌"，之后便可畅行无阻。
]

*劫难二：函数定义后不生效*

#quote-block[
此多为配置未保存或未重新加载所致。
]

*检查要点*：
- ✓ 确保配置文件已保存（记事本关闭前点击"保存"）
- ✓ 确认已运行 `. $PROFILE` 重新加载配置
- ✓ 检查函数名是否与系统命令冲突（可尝试换个名字）
- ✓ 尝试关闭 PowerShell 窗口重新打开

*劫难三：Rebased 的 Terminal 默认不是 PowerShell*

#quote-block[
若 Rebased 的集成终端默认使用 Bash 或 CMD，需手动切换。
]

*破解之法*：
+ 打开 Rebased，进入 *Settings* → *Tools* → *Terminal*
+ 将 *Shell path* 修改为：`powershell.exe` 或 `pwsh.exe`（PowerShell 7+）
+ 重启 Terminal 标签页

#line()

*劫难四：报错"管道元素中的'.'后面缺少表达式"*

#quote-block[
此乃使用 `Add-Content` 命令行追加加载指令时，换行符被错误解析所致。Profile 文件中的 `.` 与脚本路径被分置两行，PowerShell 解析失败。
]

*诊断之法*：

运行以下命令查看 profile 文件实际内容：

```powershell
Get-Content $PROFILE
```

若看到类似以下内容，即为此症：

```powershell
.
"D:\YL2025\2026\Scripts-github\scripts-template\powershell-profile.ps1"
```

*破解之法*：

+ 用记事本打开 profile 文件：

```powershell
   notepad $PROFILE
```

+ 找到错误的两行，将其合并为一行：

```powershell
   . "D:\YL2025\2026\Scripts-github\scripts-template\powershell-profile.ps1"
```

注意：`.`、空格、引号、路径必须在*同一行*。

+ 保存关闭，重新运行 `. $PROFILE` 验证。

#line()

*劫难五：如何验证配置是否真正生效？*

#quote-block[
修炼完毕，需以试金石检验功力。
]

*三步验证法*：

```powershell
# 1. 查看 profile 路径
$PROFILE

# 2. 查看 profile 文件内容（确认含有加载指令且格式正确）
Get-Content $PROFILE

# 3. 验证自定义命令是否已加载（应显示 Function 类型）
Get-Command tc-ps-cl
```

若第 3 步显示 `CommandType: Function, Name: tc-ps-cl`，即为大功告成！

#quote-block[
切记：*每次重新打开 Rebased Terminal 后，无需再手动运行 `. $PROFILE`*——profile 会自动加载。若仍需手动运行，说明 Rebased Terminal 启动时使用了 `-NoProfile` 参数，需检查 Rebased 的 Terminal 设置。
]

#line()

== 🖼️ 第五章 界面布局

#quote-block[
💡 *引言*

识得地形，方能运筹帷幄。本章介绍 Rebased 的界面组成。
]

Rebased 基于 IntelliJ 平台，界面布局清晰直观，主要由以下几大区域构成：

=== 5.1 五大区域

*编辑器区域（Editor）*
- 位于窗口*中央*，是查看和编辑文件的主战场
- 支持多标签页，可同时打开多个文件，如同"分身术"
- 提供差异对比视图，方便查看文件变更

#quote-block[
此如同剑客的演武场，刀光剑影皆在此处！
]

#line()

*工具窗口（Tool Windows）*

工具窗口是附加在主窗口边缘的辅助面板，如同江湖侠客随身携带的百宝囊：

- *Project*：项目文件树，显示仓库的目录结构，如同"地图册"
- *Commit*：提交工具窗口，用于暂存和提交更改，如同"行囊整理台"
- *Git*（或 *Version Control*）：显示提交历史、分支、远程仓库等信息，如同"江湖通讯录"
- *Terminal*：集成终端，可直接执行命令行 Git 操作，如同"令牌传讯台"
- *Problems*：显示代码问题和警告，如同"侦察兵报告"

#quote-block[
*提示*：工具窗口可通过快捷键或点击窗口边缘的按钮打开/关闭，也可拖动调整大小或位置。
]

*导航栏（Navigation Bar）*
- 显示当前文件在项目中的位置，如同"面包屑路径"
- 快速导航到父目录或同级文件
- 快捷键：`Alt + Home` 聚焦到导航栏

*状态栏（Status Bar）*
- 位于窗口*底部*，显示项目和 IDE 的状态信息
- 显示当前分支名称、Git 状态、编码格式等
- 点击状态栏的各个区域可快速访问相关设置

#quote-block[
此如同武林高手的"气息感知"，随时掌握自身状态。
]

*主题选择*

Rebased 继承了 IntelliJ 平台的主题系统，提供多种配色方案：

- *Light*：明亮主题，适合白天使用，如同"朝阳初照"
- *Dark*：暗色主题，减少眼睛疲劳，如同"月夜潜行"
- *Light with Light Header*：浅色变体，标题栏也使用浅色

#quote-block[
依个人喜好选择，如同剑客挑选趁手兵器。
]

#line()

== 🎮 第六章 基本操作

#quote-block[
💡 *引言*

纸上得来终觉浅，绝知此事要躬行。本章介绍 Git 常用操作。
]

=== 6.1 初始操作

+ 安装完成后，启动 Rebased 应用
+ 若是首次使用，需配置 Git 用户信息：
   - 用户名（User Name）：如同江湖中的"名号"
   - 邮箱地址（Email）：如同江湖中的"信鸽地址"

#line()

*打开现有仓库·进入据点*

+ 点击 *File* → *Open* 或使用快捷键
+ 选择包含 `.git` 文件夹的项目目录
+ Rebased 会自动识别并加载 Git 仓库

#quote-block[
此如同侠客推开客栈大门，自有店小二迎接。
]

=== 6.2 仓库核心操作

+ 点击 *File* → *Clone Repository*
+ 输入远程仓库的 URL（如同"宝藏地图坐标"）
+ 选择本地存储路径
+ 点击 *Clone* 开始克隆

#quote-block[
此如同"千里取首级"，虽远必达！
]

*提交更改·整装待发*

+ 在工作区修改文件后，变更会自动显示在 *Changes* 面板
+ 勾选要提交的文件（如同"整理行囊，选择携带之物"）
+ 在提交信息框中输入提交说明（如同"书写任务纪要"）
+ 点击 *Commit* 按钮完成提交

#quote-block[
每一次提交，皆是一次江湖留痕。切记言简意赅，清晰明了！
]

*推送到远程仓库·飞鸽传书*

+ 完成本地提交后，点击 *Push* 按钮
+ 选择要推送的分支和远程仓库
+ 确认推送操作

#quote-block[
此如同将密信传至远方总舵，让天下同道共知。
]

=== 6.3 进阶操作

- *创建分支*：右键点击提交历史中的某个提交，选择 *New Branch*
#quote-block[
如同武林高手修炼分身术，一身化多身
]

- *切换分支*：在分支列表中双击要切换的分支
#quote-block[
如同江湖侠客易容换装
]

- *合并分支*：在目标分支上右键，选择 *Merge into Current*
#quote-block[
如同武学融会贯通，取百家之长
]

#line()

*查看提交历史·翻阅武功谱*

+ 打开 *Log* 或 *History* 视图
+ 可以看到图形化的提交历史树（如同"武林谱系图"）
+ 点击任意提交可查看详细信息和文件变更

#quote-block[
历史如镜，鉴古知今。每一次提交都是江湖留痕，不可轻慢。
]

*解决合并冲突·调停江湖纷争*

+ 当出现合并冲突时，Rebased 会高亮显示冲突文件
+ 双击冲突文件打开*三方合并工具*（如同"调停三方会谈"）
+ 手动选择保留的内容或编辑合并结果
+ 完成后标记为已解决，继续合并流程

#quote-block[
江湖纷争在所难免，关键在于如何化解。冲突解决得当，便是一次武学融汇。
]

#line()

== ⚙️ 第七章 配置调教

#quote-block[
💡 *引言*

如同初入江湖，先立下门规，方能行事有序。本章介绍 Git、主题和 Terminal 配置。
]

=== 7.1 Git 配置·设定门规

+ 打开 *File* → *Settings*（或 *Preferences*）
+ 导航到 *Version Control* → *Git*
+ 可配置：
   - Git 可执行文件路径
   - 默认分支名称
   - 自动更新设置
   - SSH 密钥配置

#quote-block[
如同初入江湖，先立下门规，方能行事有序。
]

*主题与外观·易容换装*

Rebased 支持多种主题，包括亮色和暗色模式：

+ 打开 *Settings* → *Appearance & Behavior* → *Appearance*
+ 选择偏好的主题
+ 重启应用生效

#quote-block[
白天用 Light 主题如沐春风，夜晚用 Dark 主题护目养神，各有所宜。
]

*Terminal 设置·更换兵器*

若需将 Rebased 的 Terminal 默认 Shell 改为 PowerShell：

+ 打开 *Settings* → *Tools* → *Terminal*
+ 将 *Shell path* 修改为：`powershell.exe` 或 `pwsh.exe`
+ 重启 Terminal 标签页

#quote-block[
如同剑客更换趁手兵器，PowerShell 乃是自动化利器，不可或缺！
]

#line()

== 🔌 第八章 插件增强

#quote-block[
💡 *引言*

神器虽强，若加以插件辅佐，更可如虎添翼。本章介绍四大实用插件，助力版本控制更上层楼。
]

*公元 2026 年 6 月 14 日｜插件修炼之道*

Rebased 基于 IntelliJ 平台，天然支持丰富的插件生态。以下四款插件，乃是版本控制江湖中的神兵利器。

#line()

=== 8.1 BashSupport Pro — Shell 脚本炼丹炉

#quote-block[
若阁下科研项目中涉及大量 Shell 脚本（数据处理管道、批量分析流程），此插件堪称必备。
]

==== 8.1.1 插件简介

*BashSupport Pro* 是一款专业的 Bash/Shell 脚本开发插件，提供智能补全、语法检查、重构支持等高级特性。

==== 8.1.2 核心功能·五大神通

#tablem[
  | 功能 | 说明 | 江湖妙喻 |
  | :--- | :--- | :--- |
  | *智能补全* | 变量名、命令、路径自动补全 | 如同"心有灵犀"，未说先知 |
  | *语法检查* | 实时检测语法错误和潜在问题 | 如同"火眼金睛"，明察秋毫 |
  | *代码导航* | 跳转到函数定义、变量声明 | 如同"瞬移术"，意念即达 |
  | *重构支持* | 重命名变量/函数时自动更新所有引用 | 如同"牵一发而动全身"之术 |
  | *ShellCheck 集成* | 集成业界标准 ShellCheck 静态分析工具 | 如同"名师指点"，避免江湖陷阱 |
]

==== 8.1.3 安装方法

+ 打开 Rebased，按 `Ctrl + Alt + S` 进入设置
+ 导航至 *Plugins*
+ 搜索 *BashSupport Pro*
+ 点击 *Install* 安装
+ 重启 Rebased 生效

==== 8.1.4 实战应用场景

*场景一：生信数据处理管道*

```bash
#!/bin/bash
# 示例：批量处理 FASTQ 文件

input_dir="/data/raw"
output_dir="/data/processed"

for file in "$input_dir"/*.fastq; do
    # BashSupport Pro 会自动补全变量和路径
    base_name=$(basename "$file" .fastq)
    trimmomatic SE "$file" "$output_dir/${base_name}_trimmed.fastq"
done
```

#quote-block[
使用 BashSupport Pro 时，输入 `$in` 会自动提示 `$input_dir`，输入 `bas` 会提示 `basename`，极大提升编写效率！
]

*场景二：语法错误实时提醒*

```bash
# 错误写法（缺少闭合引号）
echo "Processing file: $file

# BashSupport Pro 会立即标红提示：Unclosed string literal
```

#quote-block[
如同江湖前辈耳提面命，避免低级失误！
]

==== 8.1.5 江湖评价

- ✅ *科研脚本必备*：处理生信数据、批量文件操作时的得力助手
- ✅ *学习曲线平缓*：安装即用，无需额外配置
- ⚠️ *付费插件*：提供 30 天试用，之后需购买许可证（约 \$79/年）

#quote-block[
若阁下是重度 Shell 用户，此插件物超所值；若仅偶尔编写脚本，可考虑免费的 Shell Script 插件。
]

#line()

=== 8.2 GitToolBox — Git 状态千里眼

#quote-block[
版本控制之道，贵在实时掌握项目状态。此插件如同江湖中的"千里眼"，让一切尽在掌握。
]

==== 8.2.1 插件简介

*GitToolBox* 增强了 Rebased 的 Git 功能，提供内联提示、自动拉取、状态栏增强等实用特性。

==== 8.2.2 核心功能·五大神通

#tablem[
  | 功能 | 说明 | 江湖妙喻 |
  | :--- | :--- | :--- |
  | *内联 Blame* | 在编辑器中显示每行代码的最后修改者和时间 | 如同"追根溯源术"，知晓来龙去脉 |
  | *提交计数* | 显示当前分支领先/落后远程仓库的提交数 | 如同"算无遗策"，胸中有数 |
  | *自动拉取* | 定时自动从远程仓库拉取更新 | 如同"顺风耳"，时刻知晓江湖动态 |
  | *状态栏增强* | 在状态栏显示分支信息、未推送提交数等 | 如同"罗盘指南"，方向清晰 |
  | *Commit 完成提示* | 提交信息自动补全（基于历史提交） | 如同"经验传承"，避免重复造轮子 |
]

==== 8.2.3 安装方法

+ `Ctrl + Alt + S` 打开设置
+ *Plugins* → 搜索 *GitToolBox*
+ 点击 *Install* 安装
+ 重启 Rebased

==== 8.2.4 实战应用场景

*场景一：代码追溯（Inline Blame）*

当你在 Rebased 中打开文件时，每行代码末尾会显示灰色的注释：

```python
def calculate_score(data):    # 张三, 3 days ago: 优化算法性能
    result = sum(data) / len(data)    # 李四, 2 weeks ago: 修复除零错误
    return result
```

#quote-block[
如同武林谱系，每招每式皆有出处！遇到疑惑代码，一眼即知何人所写、何时所改。
]

*场景二：同步状态实时监控*

状态栏显示：

```
main ↑2 ↓3
```

- `↑2`：本地领先远程仓库 2 个提交（需推送）
- `↓3`：远程仓库领先本地 3 个提交（需拉取）

#quote-block[
如同江湖消息灵通人士，随时告知你与"总舵"的同步状况。
]

==== 8.2.5 常用配置建议

打开 *Settings* → *Other Settings* → *GitToolBox Global*：

- ✅ 启用 *Inline Blame*：`Show inline blame`
- ✅ 启用 *Auto Fetch*：`Automatic fetch` 设为 `Every 15 minutes`
- ✅ 状态栏显示：`Show project location on status bar`

#quote-block[
根据个人喜好调整，过多提示反而扰乱心神，适度即可。
]

==== 8.2.6 江湖评价

- ✅ *完全免费开源*：无需付费，功能全面
- ✅ *多人协作利器*：实时掌握团队成员的提交动态
- ✅ *科研项目适用*：追溯数据处理脚本的修改历史

#line()

=== 8.3 Key Promoter X — 快捷键速成秘籍

#quote-block[
武林高手，招式纯熟，无需思考即可施展。此插件便是助你修炼"快捷键本能"的秘籍。
]

==== 8.3.1 插件简介

*Key Promoter X* 是一款快捷键学习辅助工具。每当你用鼠标点击菜单或按钮时，它会弹出提示，告诉你对应的快捷键，帮你逐步养成"键指如飞"的习惯。

==== 8.3.2 核心功能·三大妙用

#tablem[
  | 功能 | 说明 | 江湖妙喻 |
  | :--- | :--- | :--- |
  | *快捷键提示* | 鼠标操作后弹出对应快捷键提示 | 如同"师傅点拨"，每次操作皆有指引 |
  | *统计报告* | 记录你的鼠标操作次数和建议快捷键 | 如同"武学心得"，量化进步轨迹 |
  | *创建快捷键* | 对没有快捷键的操作，可一键创建自定义快捷键 | 如同"自创武学"，量身定制 |
]

==== 8.3.3 安装方法

+ `Ctrl + Alt + S` → *Plugins*
+ 搜索 *Key Promoter X*
+ 点击 *Install*，重启 Rebased

==== 8.3.4 实战应用场景

*场景一：鼠标点击即刻提醒*

当你用鼠标点击 *Commit* 按钮时，右下角会弹出气泡提示：

```
Key Promoter X
You could use Ctrl+K instead of clicking 'Commit'
```

#quote-block[
如同师傅轻敲你的头："徒儿，这招可以这样用，记住了吗？"
]

*场景二：统计你的"陋习"*

点击 *Help* → *Key Promoter X* → *Statistics*，可查看报告：

```
Top 5 mouse actions (this week):
1. Commit button clicked: 47 times (use Ctrl+K)
2. Push button clicked: 32 times (use Ctrl+Shift+K)
3. Open Settings clicked: 18 times (use Ctrl+Alt+S)
```

#quote-block[
如同武学修炼日志，让你清楚认识自己的"短板"。
]

*场景三：为常用操作创建快捷键*

对于频繁使用但没有快捷键的操作（如某个插件功能），Key Promoter X 会提示：

```
This action has no shortcut. Create one?
```

点击确认即可跳转到快捷键设置页面，快速绑定。

#quote-block[
如同"无招胜有招"，自创武学填补空白！
]

*场景四：Terminal 重命名快捷键（实战案例）*

在 Rebased 中，Terminal 的 *Rename Session* 功能默认没有快捷键。当你多次用鼠标右键点击 Terminal 标签页选择 "Rename Session" 时，Key Promoter X 会提示：

```
This action has no shortcut. Create one?
```

按照提示，可以为此操作设置快捷键 *Shift+M*（M = Modify/Name）：

+ 点击提示中的 *Create shortcut* 链接
+ 或手动进入 `Settings` → `Keymap`
+ 搜索 `Rename Session`
+ 右键点击 → *Add Keyboard Shortcut*
+ 按下 `Shift+M`，点击 *OK*

设置完成后，在 Terminal 窗口中按 `Shift+M` 即可快速重命名当前会话：

```
比如：
原标题: "Local"
按 Shift+M 后输入: "Claude-TargetC"
保存后标签页显示: "Claude-TargetC"
```

#quote-block[
此招虽小，却能大幅提升多窗口工作时的识别效率！如同江湖中为每位弟子挂上名牌，一目了然。
]

*应用场景*：
- 同时运行多个 Terminal 会话（不同项目、不同任务）
- 通过重命名快速识别每个会话的用途
- 配合 PowerShell 自动化脚本（见第四章），标识不同项目的终端

#quote-block[
💡 *举一反三*：除了 `Shift+M`，你还可以为其他常用操作创建快捷键，比如：
- Split Terminal Right: `Ctrl+Shift+\`
- Close Terminal: `Ctrl+Shift+W`
- New Terminal Session: `Ctrl+Shift+T`

Key Promoter X 正是帮你发现这些"空白武学"，量身定制专属招式的神器！
]

==== 8.3.5 江湖评价

- ✅ *完全免费*：开源项目，无任何限制
- ✅ *学习曲线加速器*：新手快速上手 IntelliJ 系快捷键
- ✅ *无干扰模式*：提示不会遮挡工作区，仅在右下角短暂显示

#quote-block[
初入 Rebased 江湖者，此插件堪称"新手村导师"，装上它，一个月内即可脱离鼠标依赖！
]

#line()

=== 8.4 Rainbow Brackets — 括号配对慧眼

#quote-block[
代码深似海，括号层层嵌套，肉眼难辨。此插件赋予你"五彩慧眼"，一眼识破配对关系。
]

==== 8.4.1 插件简介

*Rainbow Brackets* 为不同层级的括号（`()`, `[]`, `{}`）赋予不同颜色，让嵌套结构一目了然。

==== 8.4.2 核心功能·三大特色

#tablem[
  | 功能 | 说明 | 江湖妙喻 |
  | :--- | :--- | :--- |
  | *彩虹着色* | 不同层级括号显示不同颜色 | 如同"五行八卦"，各有归属 |
  | *高亮匹配* | 光标位于括号时，配对括号高亮显示 | 如同"心灵感应"，彼此呼应 |
  | *缩进参考线* | 显示代码块的垂直参考线 | 如同"阵法指引"，结构清晰 |
]

==== 8.4.3 安装方法

+ `Ctrl + Alt + S` → *Plugins*
+ 搜索 *Rainbow Brackets*
+ 点击 *Install*，无需重启（部分版本可能需要）

==== 8.4.4 实战应用场景

*场景一：JSON 配置文件解读*

```json
{
  "database": {
    "host": "localhost",
    "credentials": {
      "user": "admin",
      "password": "secret"
    }
  }
}
```

安装 Rainbow Brackets 后：
- 最外层 `{}` 显示为*红色*
- 第二层 `{}` 显示为*绿色*
- 第三层 `{}` 显示为*蓝色*

#quote-block[
如同五彩丝线，将复杂结构层次分明地呈现！
]

*场景二：Python 列表推导式*

```python
matrix = [
    [
        item * 2 for item in row
    ]
    for row in data
]
```

彩虹括号让你瞬间看清：
- 外层 `[]` 是整个 matrix
- 内层 `[]` 是每个 row 的处理

#quote-block[
如同"庖丁解牛"，游刃有余！
]

*场景三：Shell 脚本嵌套*

```bash
if [[ $(grep "pattern" file.txt | wc -l) -gt 0 ]]; then
    echo "Found"
fi
```

括号着色后，`$()` 的起止、`[[]]` 的配对，一目了然。

#quote-block[
再也不会出现"少写一个括号找半天"的窘境！
]

==== 8.4.5 配置建议

打开 *Settings* → *Editor* → *Color Scheme* → *Rainbow Brackets*：

- 可自定义每层括号的颜色
- 建议保持默认配色（经过专业设计，护眼且区分度高）

==== 8.4.6 江湖评价

- ✅ *完全免费*：开源项目，持续维护
- ✅ *适用所有语言*：Python、Shell、JSON、R、Perl 等全支持
- ✅ *科研脚本利器*：处理复杂嵌套的生信管道脚本时尤其有用

#quote-block[
此插件虽小，却能大幅提升代码阅读效率，堪称"四两拨千斤"！
]

#line()

=== 8.5 插件安装总结·一键武装

若阁下决心四款全装，可按以下顺序操作：

+ `Ctrl + Alt + S` 打开设置
+ 点击左侧 *Plugins*
+ 在搜索框依次输入并安装：
   - *BashSupport Pro*（付费，可试用）
   - *GitToolBox*（免费）
   - *Key Promoter X*（免费）
   - *Rainbow Brackets*（免费）
+ 安装完成后，点击 *Restart IDE* 重启 Rebased

#quote-block[
四大神兵一旦装备齐全，版本控制与脚本编写效率将成倍提升！
]

=== 8.6 插件维护·定期保养

插件虽好，也需定期维护：

- *更新插件*：`Settings` → `Plugins` → `Installed` → 点击插件旁的 *Update* 按钮
- *禁用/卸载不用的插件*：插件过多会拖慢启动速度，用不到的果断禁用
- *查看冲突*：若出现异常，检查 `Help` → `Show Log in Explorer` 中的日志

#quote-block[
如同武器保养，定期擦拭，方能长久锋利！
]

#line()

== ❓ 第九章 常见疑难

#quote-block[
💡 *引言*

江湖行走，疑难重重，且听在下一一道来。
]

=== 9.1 疑难一：Rebased 会创建 `.idea` 目录吗？

*答*：有江湖同道反馈，Rebased 可能会创建 `.idea` 目录（此乃 IntelliJ 项目配置目录）。项目开发者正在考虑是否提供选项来阻止这一行为。详见 #link("https://github.com/DetachHead/rebased/issues/27")[Issue \#27]。

#quote-block[
若阁下不希望此目录出现，可将其加入 `.gitignore`，使之不纳入版本控制。
]

=== 9.2 疑难二：Rebased 支持哪些操作系统？

*答*：Rebased 基于跨平台的 IntelliJ 平台，理论上支持 *Windows、macOS 和 Linux* 三大阵营。具体平台支持请查看项目发布页面。

#quote-block[
如同武学不分南北，代码不分系统。
]

=== 9.3 疑难三：如何更新 Rebased？

*答*：
- 若通过 *Winget* 安装，运行：`winget upgrade detachhead.rebased`
- 若手动安装，需从 GitHub Releases 页面下载新版本

#quote-block[
神器虽好，也需常常打磨，保持锋利。
]

=== 9.4 疑难四：为何 Rebased Terminal 中无法更改窗口标题？

*答*：Rebased 作为 IDE 会锁定工具窗口的标题为固定值（如 "Local"），这是 IDE 类工具窗口的常见限制，类似情况也见于 VS Code、IntelliJ IDEA 等。

#quote-block[
虽无法更改窗口标题，但可通过彩色提示信息在终端内部标识项目（参考卷四 PowerShell 自动化心法）。

江湖之大，总有变通之法！
]

#line()

== 📚 第十章 资源宝库

#quote-block[
💡 *引言*

武林秘籍与官方资源汇总，助力进阶修炼。
]

=== 10.1 官方资源·正宗门派

- 📦 #link("https://github.com/DetachHead/rebased")[GitHub 项目主页] — 神器本源
- 📥 #link("https://winget.ragerworks.com/package/detachhead.rebased")[Winget 安装页面] — 快速入门
- 📚 #link("https://www.jetbrains.com/help/idea/settings-version-control-git.html")[JetBrains Git 文档] — 武学总纲

#line()

=== 10.2 学习资源·江湖秘笈

- 📖 #link("https://www.jetbrains.com/help/idea/guided-tour-around-the-user-interface.html")[IntelliJ IDEA 界面概览] — 地形详解
- ⌨️ #link("https://jetbrains.com/help/idea/main-version-control-shortcuts.html")[IntelliJ IDEA 版本控制快捷键] — 招式速查
- 📋 #link("https://www.jetbrains.com/help/idea/reference-keymap-win-default.html")[IntelliJ IDEA 键盘快捷键参考] — 武功全谱
- 🧭 #link("https://jetbrains.com/guide/java/tutorials/getting-started-intellij-idea/navigating-code/")[代码导航教程] — 轻功身法

=== 10.3 其他 DetachHead 大侠之作

DetachHead 大侠除了 Rebased，还铸造了其他江湖利器：

- *#link("https://github.com/DetachHead/basedpyright")[basedpyright]*：Python 类型检查器，是 pyright 的改进版本，如同"火眼金睛术"
- *#link("https://github.com/DetachHead/dtach")[dtach]*：tach 项目的分支（原项目已停止维护），如同"失传武学的复原"

#line()

== 📊 附录一 优势对比

#quote-block[
💡 *引言*

知己知彼，百战不殆。本章对比 Rebased 与其他工具的优劣。
]

=== 附1.1 相比命令行 Git

#tablem[
  | 对比项 | 命令行 Git | Rebased |
  | :--- | :--- | :--- |
  | 学习门槛 | 较高，需记忆大量命令 | 较低，可视化操作 ✅ |
  | 冲突解决 | 手动编辑，易出错 | 三方合并工具，直观 ✅ |
  | 提交历史 | 纯文本，难以理解 | 图形化展示，清晰 ✅ |
  | 误操作风险 | 较高，一失足成千古恨 | 较低，有确认机制 ✅ |
  | 灵活性 | 极高，命令行无所不能 | 中等，覆盖常用场景 |
]

#quote-block[
命令行如同"千斤巨剑"，威力无穷但需深厚内力；Rebased 如同"轻灵细剑"，上手快捷且不易伤己。
]

=== 附1.2 相比其他 Git 客户端（Sourcetree、GitKraken）

#tablem[
  | 对比项 | Sourcetree / GitKraken | Rebased |
  | :--- | :--- | :--- |
  | 稳定性 | 中等 | 高，基于成熟 IntelliJ 平台 ✅ |
  | 商业模式 | 免费/付费混合 | 完全免费，开源 ✅ |
  | 界面风格 | 功能丰富，略显繁琐 | 简洁专注，核心功能 ✅ |
  | 性能 | 大仓库略慢 | 优秀，适合大型仓库 ✅ |
]

#line()

== 📝 跋文

*公元 2026 年 6 月 14 日｜收笔感怀*

#quote-block[
长路漫漫，拔剑四顾心茫然时，唯有工具与吾同行。
]

这 Rebased 神器，虽出世不久，然潜力巨大。它充分利用了 IntelliJ 平台的强大能力，为开发者提供了简洁高效的版本控制体验。

配合 PowerShell 自动化心法，更可极大提升科研工作中的代码管理效率。

若阁下习惯使用 JetBrains 系列 IDE，或正在寻找一款*轻量级但功能完整*的 Git 客户端，Rebased 值得一试。

#line()

多年以后，当阁下回首这段科研代码之旅，或许会感慨：

#quote-block[
*幸得 Rebased 相伴，版本控制不再是噩梦，而成为了科研路上的得力助手！*
]

江湖路远，吾等皆为过客。愿诸位同道在代码的江湖中，*执剑前行，不负韶华*！


#line()

== 文档信息

- *作者*：杨三多（Yangsanduo）
- *江湖称号*：别看我只是一只 🐏
- *创建时间*：公元 2026 年 6 月 14 日（丙午年 五月初十）
- *文档版本*：v1.0
- *适用 Rebased 版本*：请查看 #link("https://github.com/DetachHead/rebased/releases")[GitHub Releases] 获取最新版本信息
- *编辑器格式*：Markdown（支持 editor.md）

#line()

== 版权声明

本文档基于实际使用经验整理，融合北宋古文与现代白话之风，部分内容参考 JetBrains 官方文档。

*欢迎转载和分享，但需注明出处*：

#quote-block[
《科研利器 Rebased 使用秘笈》
作者：杨三多
原文链接：[待补充博客园链接]
]

#line()

\<strong\>— 全文完 —\</strong\>

江湖路远，后会有期 🎋

#line()

== 🧹 附录二 Quicker 正则清洗术·终端代码净化

终端复制出来的代码，常混有竖线、制表符和多余空格。用 Quicker 的“正则替换”动作即可快速清洗。

=== 附2.1 基础写法：^[ \|\t]+

适用场景：直接删除每一行行首的空格、竖线和 Tab。

- *查找*：^[ \|\t]+
- *替换*：留空
- *选项*：必须勾选“多行模式”

说明：^ 只匹配行首；不勾选“多行模式”时，往往只处理整段文本的第一行。另请避免把 | 当普通字符做全局替换，否则可能误删代码本身的管道符。

=== 附2.2 保留缩进的升级版：^([│|└] ?| )

适用场景：去掉终端前缀符号，但尽量保留代码原有缩进层级。

- 若行首是 │、| 或 └，删除该符号及其后最多 1 个空格。
- 若行首只有空格，则只删除最前面 1 个空格。
- *替换*仍留空，*多行模式*仍必须勾选。

=== 附2.3 精准去掉行首 2 个空格：^([│|└][ \t]{0,2}|[ \t]{2})

适用场景：既要去掉终端前缀，又要精准删掉行首 2 个空格，同时保留更深层缩进。

- [│|└][ \t]{0,2}：若行首有终端竖线或拐角符，则删除该符号及其后 0 到 2 个空格或 Tab。
- [ \t]{2}：若行首没有竖线，则只删除正好 2 个空格或 Tab；只有 1 个空格时不会误删，若有 4 个则只删前 2 个。
- 如果终端前缀需要清掉 4 个空格，可改为：^([│|└][ \t]{0,4}|[ \t]{4})。
- *替换*留空，*多行模式*仍必须勾选。
- 若要在保留目录树清理功能的同时删除换行，可改用：`^([|│└][\t]{0,2}|[\t]{2})|\s*[\r\n]+\s*`。前半段继续清理目录树符号和 Tab 缩进，后半段删除换行及其前后的空白，可把多行路径直接拼接成一行。
- 若要只合并终端自动截断的长路径，同时保留反斜杠 `\` 续行，可改用：`^[ \t]+|(?<!\\[ \t]*)[\r\n]+[ \t]*`。其中 `^[ \t]+` 用于清理首行多余空格，`(?<!\\[ \t]*)[\r\n]+[ \t]*` 会在删除换行前先检查前面是否为反斜杠；若是人为续行，则保留原有换行和缩进。

=== 附2.4 报错 Failed to paste image 的根因与处理

这通常不是正则错误，而是 Quicker 动作在处理完成后，自动向当前窗口发送粘贴指令；终端有时会把这次自动粘贴误判为“粘贴图片”。

处理方法：关闭动作末尾的自动粘贴，只保留“写入剪贴板”。

- 在 Quicker 中右键“正则替换”动作，进入编辑界面。
- 找到最后的“发送文本到窗口”“粘贴”或模拟 Ctrl+V 步骤，将其禁用或删除。
- 保留或新增“写入剪贴板”步骤，并将内容设为 \$={context}。
- 保存后，运行动作时结果只写入剪贴板，再手动 Ctrl+V 即可。

=== 附2.5 到底去哪里填正则

正则公式应填写在动作*运行时弹出的交互窗口*里，而不是底层流程编辑界面里。

若只是临时处理文本，可直接在该弹窗中切换不同规则。例如：

- 清理目录树并顺带删除换行：`^([|│└][\t]{0,2}|[\t]{2})|\s*[\r\n]+\s*`
- 只合并终端截断的长路径，同时保留反斜杠续行：`^[ \t]+|(?<!\\[ \t]*)[\r\n]+[ \t]*`

正确流程如下：

+ 正常运行“正则替换”动作。
+ 在弹窗中填写“查找”“替换”和“多行模式”。
+ 需要时保存为自己的规则。
+ 底层编辑界面只负责改流程步骤，例如关闭自动粘贴、改成写入剪贴板。

=== 附2.6 进阶方案：新建“终端智能拼接”组合动作

如果不想每次都弹窗手填正则，可以直接在 Quicker 中新建一个专属组合动作，把“读取选中文本”“两次正则替换”“发送结果”串成一套固定流程。这里推荐固化的是“只合并终端自动截断的长路径，同时保留反斜杠续行”这一套规则，更适合高频处理终端长命令。

+ 在 Quicker 面板空白格右键新建动作，名称可设为“终端智能拼接”，类型选“组合动作”，保存后进入编辑器。

+ 插入“获取选中文本”模块。在右侧属性面板的“输出到变量”区域，找到“内容”，通过下拉箭头或 `+` 新建变量 `text`，变量类型选“文本”，再将“内容”绑定到该变量并保存。

+ 在左侧组件库插入“替换文本”模块；Quicker 中它就是正则替换模块。勾选“使用正则表达式”，内容选择 `text`，查找内容填写 `(['"}\]])[ \t]*[\r\n]+[ \t]*`，替换为填写 `$1 `。注意 `$1` 后面必须保留一个空格，用于补回参数之间应有的分隔；在“输出到变量 -\> 结果”中继续选择 `text`，把结果覆盖写回。

+ 再插入一个“替换文本”模块，同样勾选“使用正则表达式”。内容仍选 `text`，查找内容填写 `^[ \t]+|(?<!\\[ \t]*)[\r\n]+[ \t]*`，替换为完全留空，在“输出到变量 -\> 结果”中依然选择 `text`。这一步会合并终端自动截断的路径，同时保留反斜杠续行。

+ 更推荐插入“写入剪贴板”模块，输入内容选择处理后的 `text`，并可附加提示语，如“代码清洗完成，已复制！”。这种做法比直接发送到终端更安全，尤其适合复杂长命令：先写入剪贴板，再手动到目标窗口粘贴，可在回车前最后确认一次，避免误运行。若确实需要自动输出，也可改用“发送文本到窗口”或“粘贴文本”。

+ 保存整个组合动作后，日常使用时只需先选中跨行长命令，再执行该动作。完整流程就是：获取选中文本，第一次正则修正参数间换行并补空格，第二次正则合并被截断的路径同时保留 `\` 续行，最后写入剪贴板并弹出成功提示。这样常用规则就被固化进动作里，后续无需再手动弹窗填写正则，适合高频处理终端长命令。
#line()

== 🔄 附录三 Rebased 拉取远程仓库更新备忘录

#quote-block[
这份备忘录总结了两种最常用的拉取远程仓库更新的工作流，建议收藏，以后遇到任何更新操作都可以直接对照！
]

#line()

=== 附3.1 场景一：日常简单更新（适用于单仓库 / 组内常规共享协作）

_这种场景适用于：你们团队共用一个仓库，或者你只是想拉取自己托管在云端的最新代码。_

*快捷操作步骤：*

+ *触发更新*：
   - 方式 A：点击顶部工具栏的 *Update Project* 图标（带有向左下方指的斜箭头 ↙）。
   - 方式 B：使用快捷键 *Ctrl + T*（macOS 为 Cmd + T）。

+ *选择更新策略（极其重要）*：
   - 选择 *Merge (合并)*：如果你和同事都在向这个分支推代码（多人共享分支），*必须*选这个，最安全，绝不会搞崩同事的代码。
   - 选择 *Rebase (变基)*：如果这个分支*只有你一个人*在用，推荐选这个，能让代码历史保持完美的一条直线。

+ *完成*：点击 *OK* 即可自动完成拉取和代码合并。

#line()

=== 附3.2 场景二：开源协作终极工作流（适用于 Fork 仓库 + 提 PR）

_这种场景适用于：你 Fork 了别人的仓库（例如 research-lab），并需要拉取原作者最新的 main 分支来更新你自己的特性分支（如 sanduo\_v2），以保证提交的 Pull Request 历史干净无冲突。_

*前提准备（只需配置一次）：*

+ 点击顶部菜单栏 *Git -\> Manage Remotes...*。
+ 点击 *+* 号，Name 填入 *upstream*，URL 填入原作者仓库的 *SSH 链接*（推荐）或 HTTPS 链接。
+ 勾选 *Fetch remote* 后保存。

*日常更新三步曲（以后每次更新只做这三步）：*

*第一步：静默抓取最新代码 (Fetch)*

- 点击顶部菜单栏 *Git -\> Fetch*（或顶部的云朵/刷新图标），也可使用已绑定的快捷键 *Alt + F* 一键触发。
- _作用：让软件把原作者（upstream）的最新代码下载到本地缓存，暂时不改变你当前的代码。_

#quote-block[
⚠️ *重要提醒：Fetch 只是"下载"，不是"更新"！*

*不，这个操作并没有更新你自己账号下的 GitHub 仓库（`sanduo_v2` 分支）。*

`Fetch`（抓取）在 Git 中是一个纯粹的*"只读"*和*"下载"*操作。

当你点击 `Git -> Fetch` 时，实际上只发生了一件事：软件去原作者的仓库（`upstream`）看了一眼，把最新的代码下载到了你*本地电脑的隐藏缓存*中。

- 它*没有*改变你本地电脑上当前正在看到和编辑的代码。
- 它*更没有*把这些更新同步到你自己的 GitHub 账号（`origin`）上。

既然你提到了"日常更新三步曲"，要真正完成更新并同步到你的 GitHub，你需要继续完成剩下的两步：

*通俗的比喻：*

- *Fetch* = 你去快递柜把原作者寄来的包裹拿回了家，放在桌上（没拆）。
- *Rebase/Merge* = 你拆开包裹，把里面的东西和自己现在手头的东西整合在了一起。
- *Push* = 你把整合好的最新成果打包，发快递寄给了你自己的 GitHub 云端仓库。
]

*第二步：执行变基 (Rebase)*

+ 在软件右下角点击当前分支名（或展开分支面板）。
+ 在列表中向下滚动，找到 *Remote* 目录下的 *upstream* 文件夹。
+ 展开后找到原作者的 *⭐ main* 分支，并*单击*它。
+ 在弹出的菜单中选择：*Rebase '你的分支名' onto 'upstream/main'*。

- _作用：将你这段时间新写的代码，重新"嫁接"到原作者最新代码的顶端。_

#quote-block[
📝 *详细说明：将最新代码融合到你的本地分支*

- *目的*：把你刚刚下载在缓存里的原作者最新代码，合并到你本地正在写的 `sanduo_v2` 分支里。
- *操作*：
  + 确保你当前正处在本地的 `sanduo_v2` 分支上。
  + 打开 IDE 底部的 Git 面板（或按 `Alt + 9`）。
  + 找到远程分支列表中的 `upstream/main`。
  + 右键点击它，选择 *Rebase Current onto Selected*（既然你提到要保证 PR 历史干净无冲突，强烈建议用 Rebase 而不是 Merge）。

- *状态*：此时，你*本地电脑*上的 `sanduo_v2` 代码已经是最新的了。
]

*第三步：解决冲突并强制推送 (Force Push)*

+ 如果弹出冲突解决窗口（Merge Conflicts），点击 \>\> 箭头选择要保留的代码，最后点击 *Apply*。如果没有冲突，则直接进入下一步。
+ 按快捷键 *Ctrl + Shift + K* 打开推送窗口。
+ *关键操作：* 点击底部的 Push 按钮旁边的下拉小箭头，选择 *Force Push (强制推送)*。

- _作用：把你整理好的完美直线代码同步到你的个人 GitHub 账号上，你的 Pull Request 也会随之自动更新完毕。_

#quote-block[
📝 *详细说明：将更新后的分支推送到你的 GitHub*

- *目的*：把你本地更新好的代码，同步到你自己账号下的 GitHub 仓库。
- *操作*：
  + 点击顶部菜单栏 `Git -> Push`（或使用快捷键 `Ctrl + Shift + K` / `Cmd + Shift + K`）。
  + 确认是将本地的 `sanduo_v2` 推送到 `origin/sanduo_v2`。
  + 点击 *Push*（如果在第二步使用了 Rebase 且你之前已经 push 过，这里可能需要选择 *Force Push* 来覆盖云端历史）。

- *状态*：*直到这一步完成，你自己账号下的 GitHub 才会真正被更新。*
]


== 🔄 Fork软件-附录三 Rebase 拉取远程仓库更新备忘录（Fork 软件版）

#quote-block[
这份备忘录总结了两种最常用的拉取远程仓库更新的工作流，建议收藏，以后在 Fork 客户端中遇到任何更新操作都可以直接对照！
]

#line()

=== 附3.1 场景一：日常简单更新（适用于单仓库 / 组内常规共享协作）

_这种场景适用于：你们团队共用一个仓库，或者你只是想拉取自己托管在云端的最新代码。_

*快捷操作步骤：*

+ *触发更新*：
- 方式 A：点击顶部工具栏的 *Pull* 图标（带有向下拉取的箭头 ⤵）。
- 方式 B：使用快捷键 *Ctrl + Shift + P*（macOS 为 *Cmd + Shift + P*）。


+ *选择更新策略（极其重要）*：
- 选择 *Merge*（默认）：如果你和同事都在向这个分支推代码（多人共享分支），*必须*保持默认合并方式，最安全，绝不会搞乱同事的代码。
- 勾选 *Rebase*（变基）：如果这个分支*只有你一个人*在用，在弹窗中勾选 *Rebase* 选项，能让本地代码历史保持完美的一条直线。


+ *完成*：点击 *Pull* 按钮即可自动完成远程拉取与本地代码合并。

#line()

=== 附3.2 场景二：开源协作终极工作流（适用于 Fork 仓库 + 提 PR）

_这种场景适用于：你 Fork 了别人的仓库（例如 research-lab），并需要拉取原作者最新的 main 分支来更新你自己的特性分支（如 sanduo\_v2），以保证提交的 Pull Request 历史干净无冲突。_

*前提准备（只需配置一次）：*

+ 在左侧侧边栏找到 *Remotes*，*右键点击*并选择 *Add New Remote...*（或点击顶部菜单栏 `Repository` -\> `Remotes...` -\> `+` 号）。
+ 在弹出窗口中，Name 填入 *upstream*，URL 填入原作者仓库的 *SSH 链接*（推荐）或 HTTPS 链接。
+ 点击 *Add* 保存，Fork 会自动抓取原作者仓库的分支列表。

*日常更新三步曲（以后每次更新只做这三步）：*

*第一步：静默抓取最新代码 (Fetch)*

- 点击顶部工具栏的 *Fetch* 图标（向上弯曲的箭头 ⤴），也可使用快捷键 *Ctrl + Shift + F*（macOS 为 *Cmd + Shift + F*），在弹窗中直接点击 *Fetch*。
- _作用：让软件把原作者（upstream）的最新代码下载到本地缓存，暂时不改变你当前的代码。_

#quote-block[
⚠️ *重要提醒：Fetch 只是"下载"，不是"更新"！*
*不，这个操作并没有更新你自己账号下的 GitHub 仓库（`sanduo_v2` 分支）。*
`Fetch`（抓取）在 Git 中是一个纯粹的*"只读"*和*"下载"*操作。
当你点击 `Fetch` 时，实际上只发生了一件事：软件去原作者的仓库（`upstream`）看了一眼，把最新的代码下载到了你*本地电脑的隐藏缓存*中。
- 它*没有*改变你本地电脑上当前正在看到和编辑的代码。
- 它*更没有*把这些更新同步到你自己的 GitHub 账号（`origin`）上。


既然你提到了"日常更新三步曲"，要真正完成更新并同步到你的 GitHub，你需要继续完成剩下的两步：
*通俗的比喻：*
- *Fetch* = 你去快递柜把原作者寄来的包裹拿回了家，放在桌上（没拆）。
- *Rebase/Merge* = 你拆开包裹，把里面的东西和自己现在手头的东西整合在了一起。
- *Push* = 你把整合好的最新成果打包，发快递寄给了你自己的 GitHub 云端仓库。


]

*第二步：执行变基 (Rebase)*

+ 确认左侧 `Branches` 中当前检出的是你的特性分支（名称前带有 *✔* 勾选标志，如 `sanduo_v2`）。
+ 在左侧面板向下滚动，展开 *Remotes* 目录下的 *upstream* 文件夹。
+ 找到原作者的 *main* 分支，*右键点击*它。
+ 在弹出的菜单中选择：*Rebase 'sanduo\_v2' onto 'upstream/main'*。

- _作用：将你这段时间新写的代码，重新"嫁接"到原作者最新代码的顶端。_

#quote-block[
📝 *详细说明：将最新代码融合到你的本地分支*
- *目的*：把你刚刚下载在缓存里的原作者最新代码，合并到你本地正在写的 `sanduo_v2` 分支里。
- *操作*：
+ 确保左侧面板中当前正打勾处在本地的 `sanduo_v2` 分支上。
+ 展开左侧 `Remotes -> upstream` 列表。
+ 右键点击 `main` 分支。
+ 选择 *Rebase 'sanduo\_v2' onto 'upstream/main'*（既然你提到要保证 PR 历史干净无冲突，强烈建议用 Rebase 而不是 Merge）。


- *状态*：此时，你*本地电脑*上的 `sanduo_v2` 代码已经是最新的了。


]

*第三步：解决冲突并强制推送 (Force Push)*

+ 如果弹出冲突提示，在 Fork 弹出的冲突列表中点击文件进入*内置三方合并工具*解决冲突，完成后点击 *Resolve*，最后点击顶部的 *Continue Rebase*。如果没有冲突，则直接进入下一步。
+ 点击顶部工具栏的 *Push* 图标（或按快捷键 *Ctrl + P* / macOS 为 *Cmd + P*）打开推送窗口。
+ *关键操作：* 确认 Remote 为 `origin`，Branch 为 `sanduo_v2`，勾选弹窗左下角的 *Force Push (force-with-lease)* 复选框，最后点击 *Push*。

- _作用：把你整理好的完美直线代码同步到你的个人 GitHub 账号上，你的 Pull Request 也会随之自动更新完毕。_

#quote-block[
📝 *详细说明：将更新后的分支推送到你的 GitHub*
- *目的*：把你本地更新好的代码，同步到你自己账号下的 GitHub 仓库。
- *操作*：
+ 点击顶部工具栏 `Push`（或使用快捷键 `Ctrl + P` / `Cmd + P`）。
+ 确认是将本地的 `sanduo_v2` 推送到 `origin/sanduo_v2`。
+ 勾选 *Force Push* 复选框后点击 *Push*（Rebase 后本地提交历史已被重写，必须使用 Force Push 覆盖云端历史）。


- *状态*：*直到这一步完成，你自己账号下的 GitHub 才会真正被更新。*


]
