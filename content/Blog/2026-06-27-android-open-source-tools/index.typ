#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *
#import "@preview/theorion:0.6.0": quote-block

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "Android 开源江湖兵器谱",
  description: "一份 Android 开源免费应用清单：应用商店、输入法、影音、密码与财务、效率自动化、隐私学习与终端工具的用法与告诫。",
  date: datetime(year: 2026, month: 6, day: 27),
  lang: "zh",
)

= Android 开源江湖兵器谱

#quote-block[
*卷首小引*

今之安卓江湖，表面繁华，实则暗潮汹涌：广告如雨，权限如网，追踪如影。少侠若误入其间，轻则界面臃肿，重则隐私失守，乃至更新失序、文件失散、手势失灵，日用之苦，不一而足。

仆素喜开源之道，向来以「能本地则本地，能开源则开源，能自控则自控」为择器之先。故将所见所用之 Android 开源免费良器，辑为一卷，名曰*Android 开源江湖兵器谱*。

此卷不谈虚名，只论实用：每器皆附*下载地址*、*用法要领*与*江湖告诫*，务求少侠一卷在手，少走弯路，少碰雷区。

——杨某顿首
]

#line()

== 📜 总纲

- 第一章 卷首江湖论
- 第二章 总览速查表
- 第三章 开源应用商店与更新兵器
  - 3.1 Droid-ify
  - 3.2 Obtainium
- 第四章 输入法与系统调用
  - 4.1 Fcitx5
  - 4.2 Shizuku
  - 4.3 Key Mapper
- 第五章 影音与内容兵器
  - 5.1 mpv
  - 5.2 VLC
  - 5.3 YTDLnis
- 第六章 账户、密码与财务
  - 6.1 Bitwarden
  - 6.2 Paisa
  - 6.3 Thunderbird
- 第七章 效率、自动化与界面清静
  - 7.1 GKD
  - 7.2 Native Alpha
  - 7.3 Auxio
- 第八章 隐私、学习与代理
  - 8.1 Photok
  - 8.2 AnkiDroid
  - 8.3 Clash Meta
- 第九章 终端与移动开发
  - 9.1 Termux
- 第十章 兵器总览速查表
- 第十一章 江湖结语

#line()

== ⚔️ 第一章 卷首江湖论

#quote-block[
💡 *引言*

安卓之患，往往不在硬件，而在软件。许多人手机越用越慢，不是机器不行，是装了一堆不对路的东西：广告过密、权限乱飞、更新断档、数据外泄、工具臃肿。

真正的高手，不是装得多，而是装得准。开源免费之物，胜在三点：*可见其源、可控其行、可迁其器*。少侠若能把应用商店、更新器、输入法、播放器、密码管家、自动化工具、终端环境一并收拢，则手机便不再是消遣之具，而是可随身携带的一套小型生产力系统。

本卷所录诸器，皆围绕一个核心：*让 Android 回到干净、可控、少打扰的状态*。
]

#line()

== 📋 第二章 总览速查表

#tablem[
  | 谱系 | 兵器 | 作用 | 官方 / 下载入口 |
  | :--- | :--- | :--- | :--- |
  | 开源商店 | Droid-ify | F-Droid 现代化客户端 | \<https://github.com/Droid-ify/client\> |
  | 更新神器 | Obtainium | 直连 GitHub/GitLab Releases 监控更新 | \<https://github.com/ImranR98/Obtainium\> |
  | 输入法 | Fcitx5 | 开源输入法引擎 Android 端 | \<https://github.com/fcitx5-android/fcitx5-android\> |
  | 播放器 | mpv | 强力本地播放器 | \<https://github.com/mpv-android/mpv-android\> |
  | 密码管家 | Bitwarden | 开源跨平台密码管理 | \<https://bitwarden.com\> / \<https://github.com/bitwarden/android\> |
  | 按键重映射 | Key Mapper | 音量键/组合键自动化 | \<https://github.com/keymapperorg/KeyMapper\> |
  | 视频下载 | YTDLnis | yt-dlp 图形前端 | \<https://github.com/deniscerri/ytdlnis\> |
  | 跳广告 | GKD | 无障碍自动跳过广告 | \<https://github.com/gkd-kit/gkd\> |
  | 网页壳 | Native Alpha | Web App 封装工具 | \<https://github.com/djtech44/NativeAlpha\> |
  | 私密相册 | Photok | 本地加密相册 | \<https://github.com/Kr0oked/Photok\> |
  | 系统桥 | Shizuku | 给第三方 App 更高系统权限 | \<https://github.com/RikkaApps/Shizuku\> |
  | 记账 | Paisa | 简洁 Ledger 风格记账 | \<https://github.com/ganeshrvel/paisa\> |
  | 音乐播放器 | Auxio | 本地音乐播放 | \<https://github.com/auxio-project/auxio\> |
  | 影音播放器 | VLC | 老牌开源播放器 | \<https://www.videolan.org/vlc/download-android.html\> |
  | 背诵学习 | AnkiDroid | 闪卡学习工具 | \<https://github.com/ankidroid/Anki-Android\> |
  | 代理客户端 | Clash Meta | 代理工具客户端 | \<https://github.com/MetaCubeX/ClashMetaForAndroid\> |
  | 邮件客户端 | Thunderbird | 开源邮件客户端 | \<https://www.thunderbird.net\> / \<https://github.com/thunderbird/thunderbird-android\> |
  | 终端 | Termux | Android 上的 Linux 终端 | \<https://github.com/termux/termux-app\> |
]

#line()

== ⚔️ 第三章 开源应用商店与更新兵器

=== 3.1 🏮 Droid-ify

#quote-block[
📜 *古文小记*：此器如同小巧精致之药柜，专收 F-Droid 百家药方，界面清爽，取药极快。

💬 *白话直说*：F-Droid 的现代化客户端，适合想要一个更好看、更顺手、更像“商店”的开源应用入口。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | F-Droid 客户端 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/Droid-ify/client\> |
  | *下载方式* | GitHub Releases / F-Droid 生态 |
]

*🔥 独门绝技*

- 界面现代，分类清晰，找应用比原版 F-Droid 更顺手；
- 支持仓库管理，适合把常用开源源统一收拢；
- 更新提示明确，装一堆开源工具时不容易漏更；
- 适合长期做“开源 App 基座”的少侠。

*⚙️ 使用要领*

```text
① 安装后先加仓库
② 搜索常用开源 App
③ 统一管理更新
④ 把它当作开源应用的主入口
```

#quote-block[
⚠️ *江湖告诫*：仓库不要乱加，来源不明者慎入，免得药方虽多，杂质更甚。
]

#line()

=== 3.2 🧭 Obtainium

#quote-block[
📜 *古文小记*：此器不做商店，只做盯梢。凡 GitHub、GitLab、Codeberg 之类 Releases 有新动静，它便替你第一时间探得风声。

💬 *白话直说*：开源应用更新神器，适合直接追踪项目官方 Release 并下载更新包。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 更新监控 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/ImranR98/Obtainium\> |
  | *下载方式* | GitHub Releases |
]

*🔥 独门绝技*

- 直接盯官方仓库，不必再靠应用商店转手；
- 支持多平台项目更新源，适合装在手机里的开源工具大军；
- 版本提醒非常直白，适合“我只想装最新版”的少侠；
- 对 GitHub Releases 依赖高的应用尤其好用。

*⚙️ 使用要领*

```text
① 添加应用仓库链接
② 选择 Release 监控规则
③ 让它自动追踪版本
④ 有新包时直接安装
```

#quote-block[
⚠️ *江湖告诫*：若项目发行页命名混乱，务必核对作者与签名，别把旁门左道当成正宗传承。
]

#line()

== ⚔️ 第四章 输入法与系统调用

=== 4.1 🀄 Fcitx5

#quote-block[
📜 *古文小记*：此乃“写字之剑”。轻灵、干净、少扰人，专为重视输入体验与隐私者所备。

💬 *白话直说*：开源输入法方案，Android 版适合需要拼音、键盘扩展、纯净输入体验的用户。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 输入法 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/fcitx5-android/fcitx5-android\> |
  | *下载方式* | GitHub Releases / F-Droid 生态 |
]

*🔥 独门绝技*

- 输入界面简洁，不带多余花活；
- 可配合词库与布局使用，适合习惯 Fcitx 生态的少侠；
- 本地优先，隐私负担较轻；
- 对中文输入、符号输入、键盘布局切换较友好。

#quote-block[
💡 *上手建议*：装好后先把默认输入法切过去，再慢慢调词库与布局，别一上来就追求全功能，否则容易把自己绕进去。
]

#line()

=== 4.2 🛡️ Shizuku

#quote-block[
📜 *古文小记*：此物非兵刃，乃兵符。借 ADB 或 Root 之力，为众器开一扇更高的门。

💬 *白话直说*：核心系统桥接工具，许多高级 Android 工具都靠它获得更强能力。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 系统能力桥接 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/RikkaApps/Shizuku\> |
  | *下载方式* | GitHub Releases / 官方文档 |
]

*🔥 独门绝技*

- 让第三方工具获得更高级的系统 API 调用能力；
- 常与按键工具、文件工具、系统优化工具联动；
- 无需 root 也能做很多“原本得 root 才能做的事”；
- 是 Android 工具链里的关键枢纽。

#quote-block[
⚠️ *江湖告诫*：Shizuku 不是装上就完事，通常还要配合 ADB 启动流程或配套授权；此处须按官方文档一步一步来。
]

#line()

=== 4.3 🎛️ Key Mapper

#quote-block[
📜 *古文小记*：此器专管“指尖暗门”。音量键、组合键、长按短按，皆可化作机关。

💬 *白话直说*：按键重映射工具，适合把硬件键变成快捷开关、脚本入口或自动化触发器。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 按键重映射 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/keymapperorg/KeyMapper\> |
  | *下载方式* | GitHub Releases |
]

*🔥 独门绝技*

- 把音量键、侧键、耳机键等重新定义；
- 组合键可触发 App 启动、动作执行；
- 适合做“单手操作流”；
- 与 Shizuku 配合时，能力更完整。

#quote-block[
💡 *实战用法*：把“音量上 + 音量下”设成截屏，把“长按音量下”设成开手电，日常会顺很多。
]

#line()

== ⚔️ 第五章 影音与内容兵器

=== 5.1 🎬 mpv

#quote-block[
📜 *古文小记*：此器其貌不扬，内力极深。万般格式，到它手里往往都能安稳落地。

💬 *白话直说*：基于 mpv 内核的 Android 播放器，主打强解码、少广告、纯播放。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 本地播放器 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/mpv-android/mpv-android\> |
  | *下载方式* | GitHub Releases |
]

*🔥 独门绝技*

- 兼容面广，播放许多奇怪格式都不虚；
- 适合本地视频、字幕文件、离线素材；
- 干净无广告，专注播放；
- 对爱折腾播放参数的人非常友好。

#quote-block[
⚠️ *江湖告诫*：它不是“傻瓜播放器”。若想发挥威力，字幕、音轨、解码选项最好稍作了解。
]

#line()

=== 5.2 📼 VLC

#quote-block[
📜 *古文小记*：此器是老江湖，名声在外，万流归宗，几乎什么都敢播。

💬 *白话直说*：开源老牌播放器，稳，杂食，Android 端也十分能打。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 通用播放器 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://www.videolan.org/vlc/download-android.html\> |
  | *下载方式* | 官方站 / Google Play / F-Droid 生态 |
]

*🔥 独门绝技*

- 解码能力强，兼容性好；
- 本地视频、音频、字幕一并处理；
- 适合“装一个，兜底一切”的思路；
- 老牌稳定，少折腾。

#line()

=== 5.3 ⬇️ YTDLnis

#quote-block[
📜 *古文小记*：此器善于“取材”。凡公开视频中之可下者，多能借 yt-dlp 之力收入囊中。

💬 *白话直说*：基于 yt-dlp 的 Android 图形端下载器，适合抓取公开视频、音频与媒体资源。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 媒体下载 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/deniscerri/ytdlnis\> |
  | *下载方式* | GitHub Releases |
]

*🔥 独门绝技*

- 图形界面更适合手机操作；
- 依托 yt-dlp，能力面广；
- 适合保存公开讲座、公开视频、音频素材；
- 可与本地播放器联动，形成闭环。

#quote-block[
⚠️ *江湖告诫*：版权内容、平台条款、地区限制都得自己掂量，别把下载工具当成无差别通行证。
]

#line()

== ⚔️ 第六章 账户、密码与财务

=== 6.1 🔐 Bitwarden

#quote-block[
📜 *古文小记*：此乃钥匙匣。天下账号如沙海，若无匣收之，转眼便散。

💬 *白话直说*：开源跨平台密码管理器，适合把密码、卡片、备注统一收拢。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 密码管理 |
  | *适用系统* | Android / 全平台 |
  | *官方秘籍* | \<https://bitwarden.com\> |
  | *代码仓库* | \<https://github.com/bitwarden/android\> |
]

*🔥 独门绝技*

- 多端同步，手机电脑都能接；
- 密码、身份信息、安全备注一并管理；
- 自动填充体验成熟；
- 开源方案里最稳的一批。

#quote-block[
💡 *上手建议*：主密码要足够强，2FA 能开就开。密码管家最怕的不是工具弱，而是主密码自己太随意。
]

#line()

=== 6.2 📒 Paisa

#quote-block[
📜 *古文小记*：记账之道，贵在清简。此器不求花哨，只求账本明白、收支清楚。

💬 *白话直说*：偏简洁现代的开源个人财务工具，适合喜欢 Ledger/纯文本思路的少侠。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 个人记账 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/ganeshrvel/paisa\> |
  | *下载方式* | GitHub Releases |
]

*🔥 独门绝技*

- 界面清爽，记账流程短；
- 适合日常收支、预算、分类统计；
- 偏向“少即是多”的风格；
- 适合从杂乱 Excel 迁入移动端。

#line()

=== 6.3 🦅 Thunderbird

#quote-block[
📜 *古文小记*：此物本在桌面江湖声名赫赫，如今飞入 Android，仍是信札来往之利器。

💬 *白话直说*：Mozilla 旗下的开源邮件客户端，适合重视隐私、账户管理与统一收件的人。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 邮件管理 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://www.thunderbird.net\> |
  | *代码仓库* | \<https://github.com/thunderbird/thunderbird-android\> |
]

*🔥 独门绝技*

- 多账户收信，界面统一；
- 适合把工作邮箱、个人邮箱分层管理；
- 开源路线更利于长期使用；
- 与桌面端 Thunderbird 用户可形成习惯统一。

#quote-block[
⚠️ *江湖告诫*：邮件同步方式与服务器策略要先看清，别一股脑全删本地缓存，回头找不到旧信。
]

#line()

== ⚔️ 第七章 效率、自动化与界面清静

=== 7.1 🧹 GKD

#quote-block[
📜 *古文小记*：此器名虽俗，功却奇。它不与广告论理，只与广告分胜负。

💬 *白话直说*：基于无障碍的自动跳广告工具，常用于跳过开屏、弹窗、无意义确认页。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 自动跳广告 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/gkd-kit/gkd\> |
  | *下载方式* | GitHub Releases |
]

*🔥 独门绝技*

- 自动处理各种开屏与弹窗；
- 规则可扩展，适合长期打磨；
- 对“每天都要点同一个按钮”的场景极省心；
- 相当于给手指请了一位替班。

#quote-block[
⚠️ *江湖告诫*：无障碍权限权重大，务必只给可信工具；规则也要按需维护，别让它误伤正常流程。
]

#line()

=== 7.2 🪟 Native Alpha

#quote-block[
📜 *古文小记*：此器擅长“化网页为壳”。网页若可常驻，便不必每次都从浏览器重开。

💬 *白话直说*：把网页封装成独立应用外壳的工具，适合 Web App 常用入口。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | Web App 封装 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/djtech44/NativeAlpha\> |
  | *下载方式* | GitHub Releases |
]

*🔥 独门绝技*

- 把网页变成“像原生应用一样”的入口；
- 适合常用论坛、文档、后台系统、轻量工具站；
- 图标、启动方式更接近本地 App；
- 比反复切浏览器标签更顺手。

#line()

=== 7.3 🎵 Auxio

#quote-block[
📜 *古文小记*：此器不喧哗，只听本地曲库。你若珍惜手机里的离线音乐，它便是清净之选。

💬 *白话直说*：开源本地音乐播放器，界面漂亮，专注本地播放。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 本地音乐播放 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/auxio-project/auxio\> |
  | *下载方式* | GitHub Releases |
]

*🔥 独门绝技*

- 本地曲库管理清晰；
- 界面克制，适合长期听歌；
- 不靠广告撑场面；
- 适合厌倦臃肿音乐软件的人。

#line()

== ⚔️ 第八章 隐私、学习与代理

=== 8.1 🔒 Photok

#quote-block[
📜 *古文小记*：相册之器，最怕云端乱飞。此器主打本地加密，照片在自己手里。

💬 *白话直说*：开源且本地加密的私密相册工具，适合存放不愿外泄的图片。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 私密相册 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/Kr0oked/Photok\> |
  | *下载方式* | GitHub Releases |
]

*🔥 独门绝技*

- 本地加密，减少云端风险；
- 适合敏感照片、证件照、私密资料；
- 逻辑清楚，目标单一；
- 比“顺手装个大厂相册”更安稳。

#line()

=== 8.2 📚 AnkiDroid

#quote-block[
📜 *古文小记*：此器乃“背诵之鼎”。能把零散知识熬成可重复咀嚼之药。

💬 *白话直说*：开源闪卡学习工具，背单词、背概念、背法条、背教材都能用。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 闪卡学习 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/ankidroid/Anki-Android\> |
  | *下载方式* | GitHub Releases / F-Droid 生态 |
]

*🔥 独门绝技*

- 间隔重复机制成熟；
- 很适合碎片时间复习；
- 与桌面端 Anki 配合，形成完整学习闭环；
- 学语言、考证、背知识点都很合适。

#line()

=== 8.3 🕸️ Clash Meta

#quote-block[
📜 *古文小记*：此乃行走四方之术，借规则而通达外界。江湖险峻，路由亦需章法。

💬 *白话直说*：开源代理客户端，适合需要规则化网络访问的场景。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 代理客户端 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/MetaCubeX/ClashMetaForAndroid\> |
  | *下载方式* | GitHub Releases |
]

*🔥 独门绝技*

- 规则分流思路成熟；
- 适合有明确网络策略需求的少侠；
- 兼容多种配置思路；
- 能把“能连”与“该走哪条路”分开处理。

#quote-block[
⚠️ *江湖告诫*：此类工具涉及网络策略与地区合规，配置请遵守当地法律、学校或公司规定。
]

#line()

== ⚔️ 第九章 终端与移动开发

=== 9.1 🐚 Termux

#quote-block[
📜 *古文小记*：此器乃袖中乾坤。虽在手机之上，却可开出一个极像 Linux 的天地。

💬 *白话直说*：Android 上的高级终端环境，能装包、跑脚本、做开发、做自动化。
]

*📌 兵器属性*

#tablem[
  | 项目 | 内容 |
  | :--- | :--- |
  | *核心定位* | 终端 / Linux 环境 |
  | *适用系统* | Android |
  | *官方秘籍* | \<https://github.com/termux/termux-app\> |
  | *下载方式* | GitHub Releases / F-Droid 生态 |
]

*🔥 独门绝技*

- `pkg` / `apt` 可装大量命令行工具；
- 可做轻量开发、脚本跑批、远程连接；
- 适合随身维护服务器、处理文本、跑小工具；
- 对 Linux 用户几乎是“手机上的第二个家”。

*⚙️ 初入门三式*

```bash
pkg update
pkg upgrade
pkg install git python curl
```

#quote-block[
⚠️ *江湖告诫*：Termux 不是传统手机 App，而是一个真正的命令行世界。初装就乱删乱改，容易把自己困住。
]

#line()

== 📋 第十章 兵器总览速查表

#tablem[
  | 谱系 | 兵器 | 适合做什么 | 推荐入口 |
  | :--- | :--- | :--- | :--- |
  | 开源商店 | Droid-ify | 找开源 App、管仓库 | GitHub / F-Droid |
  | 更新神器 | Obtainium | 跟踪 GitHub Release 更新 | GitHub Releases |
  | 输入法 | Fcitx5 | 纯净输入 | GitHub Releases |
  | 系统桥 | Shizuku | 赋予工具更强能力 | GitHub Releases |
  | 按键重映射 | Key Mapper | 单手操作、快捷触发 | GitHub Releases |
  | 播放器 | mpv | 本地视频、字幕、强解码 | GitHub Releases |
  | 播放器 | VLC | 万能兜底播放 | 官方站 / 商店 |
  | 视频下载 | YTDLnis | 抓公开媒体 | GitHub Releases |
  | 密码管家 | Bitwarden | 密码与敏感信息管理 | 官网 / GitHub |
  | 记账 | Paisa | 收支记录、预算管理 | GitHub Releases |
  | 邮件 | Thunderbird | 多邮箱统一管理 | 官网 / GitHub |
  | 自动化 | GKD | 跳广告、去打扰 | GitHub Releases |
  | 网页壳 | Native Alpha | 网页封装成 App | GitHub Releases |
  | 音乐 | Auxio | 本地音乐播放 | GitHub Releases |
  | 相册 | Photok | 私密图片加密 | GitHub Releases |
  | 学习 | AnkiDroid | 闪卡记忆 | GitHub / F-Droid |
  | 代理 | Clash Meta | 规则化网络访问 | GitHub Releases |
  | 终端 | Termux | Linux 命令行环境 | GitHub / F-Droid |
]

#line()

== 🏯 第十一章 江湖结语

#quote-block[
*江湖传言*

```
诸器在手，安卓自清。
更新有门，广告可避。
文字有法，音乐有声。
密码有匣，学习有程。
```

开源之美，不在“免费”二字，而在*可被理解、可被替换、可被长期信任*。少侠若愿在 Android 江湖里少受折腾，不妨从这几柄兵器开始：先立应用入口，再定更新路径；先守输入与系统权限，再管账户与隐私；余下影音、记忆、终端、代理，按需取用即可。

兵器再利，终究只是兵器。真正决定日常顺不顺手的，仍是你如何安排它们、裁剪它们、长期维护它们。愿此卷能给你一条更清净、更稳妥的路。

——杨某再拜，谨以此谱奉诸同道
]

#line()

#quote-block[
📅 *撰于* 2026.06.27 · 仿《科研江湖之绝世兵器谱》体例
]
