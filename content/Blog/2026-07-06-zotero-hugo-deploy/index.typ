#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *
#import "@preview/theorion:0.6.0": quote-block

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "科研江湖之 Zotero-Hugo 文献库部署秘笈",
  description: "从 Zotero 群组同步、GitHub Actions 自动构建到 Cloudflare Pages 部署，搭建带认领追踪与密码保护的文献库。",
  date: datetime(year: 2026, month: 7, day: 6),
  lang: "zh",
)

= 科研江湖之 Zotero-Hugo 文献库部署秘笈

#quote-block[
*卷首小引*

科研之路，文献浩如烟海；组会汇报，认领追踪，若无系统统御，必陷混乱泥沼。

此时，*Zotero + Hugo + GitHub + Cloudflare* 四大神器联手，筑起一座文献库的自动化长城——从 Zotero 群组同步、GitHub Actions 自动构建，到 Cloudflare Pages 部署上线，环环相扣，行云流水。

而 *Zotero-Hugo* 这套方案，便是将文献管理、认领追踪、补传文献、自动同步，全部化为一条龙的部署秘笈——让文献库从此告别手动搬运，拥抱自动化。

通过此方案，你可以方便地实现：
- 📚 *文献同步*：Zotero 群组数据自动拉取并生成 JSON
- 🏷️ *认领追踪*：汇报人、汇报日期、认领状态一目了然
- 🔒 *密码保护*：Staticrypt 加密，组内成员专享
- 🚀 *自动部署*：GitHub Actions 构建 + Cloudflare Pages 上线

*分门别类，纳入自动化流程*，从此告别"这篇文献到底谁认领了"的噩梦！

此卷者，乃在下部署 Zotero-Hugo 文献库所积之心法也。愿诸位同道展卷有得：文献有序，认领清晰，科研顺遂。

——杨某顿首
]

#line()

== 📜 总纲

- 第一章 目录布局·兵马驻扎
- 第二章 页面功能·界面解读
- 第三章 Zotero 端要求·前置心法
- 第四章 GitHub Actions 配置·自动运转
  - 4.1 sync\_zotero\_hugo.yml
  - 4.2 publish.yaml
- 第五章 Cloudflare Pages Functions·云端剑法
- 第六章 Python 版本·内功根基
- 第七章 Hugo 页面文件·阵法布局
- 第八章 本地测试流程·闭关修炼
  - 8.1 生成静态站点
  - 8.2 临时生成 Pages Functions 目录
  - 8.3 启动本地 Pages 调试
- 第九章 清理建议·善后收招
- 第十章 Zotero API Key 权限建议·最小权限
- 第十一章 通知边界·江湖规矩
- 附录一 常见问题与排查
- 附录二 Zotero API Key 权限速查

== 🗂️ 第一章 目录布局·兵马驻扎

#quote-block[
💡 *引言*

兵马未动，粮草先行。本章详解 Zotero-Hugo 相关源码在仓库中的驻扎位置。
]

*公元 2026 年 7 月 5 日｜初探阵地*

本文档对应当前仓库 `D:\YL2025\vscode\github\lab-github\lab.github.io` 的最新实现。

Zotero-Hugo 相关新增文件只放在 `layouts`、`content`、`config`、`assets`、`.github` 这 5 个既有顶级目录的子目录下，保持上游仓库根目录简洁。

Zotero-Hugo 相关源码位于以下位置：

```text
lab.github.io/
├─ .github/
│  ├─ cloudflare-pages/
│  │  └─ functions/
│  │     └─ api/
│  │        └─ zotero-hugo/
│  │           ├─ zotero-add.js
│  │           └─ zotero-claim.js
│  ├─ scripts/
│  │  └─ zotero-hugo/
│  │     ├─ README.md
│  │     ├─ requirements.txt
│  │     ├─ zotero-hugo-deploy-guide.md
│  │     ├─ zotero_move_claims.py
│  │     └─ zotero_to_json.py
│  └─ workflows/
│     ├─ publish.yaml
│     └─ sync_zotero_hugo.yml
├─ assets/
│  └─ zotero-hugo/
│     └─ papers.json
├─ content/
│  ├─ en/
│  │  └─ post/
│  │     └─ Literature for Group Meeting/
│  │        └─ index.md
│  └─ zh/
│     └─ post/
│        └─ Literature for Group Meeting/
│           └─ index.md
└─ layouts/
   └─ shortcodes/
      └─ zotero-hugo/
         └─ zotero_library.html
```

*各文件职责*：

- `assets/zotero-hugo/papers.json` — Zotero 同步后的文献数据文件，如同"粮草清单"
- `layouts/shortcodes/zotero-hugo/zotero_library.html` — Hugo shortcode，如同"阵法核心"
- `content/en/post/...` 和 `content/zh/post/...` — 帖子只出现在 `post/博客` 模块
- `.github/cloudflare-pages/functions/...` — Cloudflare Pages Functions 源码；部署或本地调试时再临时生成仓库根目录 `functions/`，不把它作为长期源码目录保留

#quote-block[
如同行军布阵，各路兵马各有驻扎之地，井然有序方能决胜千里。
]

#line()

== 🖥️ 第二章 页面功能·界面解读

#quote-block[
💡 *引言*

界面是用户与系统之间的桥梁。本章解读文献库页面的中英文差异与交互规则。
]

*公元 2026 年 7 月 5 日｜界面心法*

当前页面标题统一为：`Literature for Group Meeting`

*中英文界面差异*：

#tablem[
  | 元素 | 英文 (EN) | 中文 (ZH) |
  | :--- | :--- | :--- |
  | 密码提示 | `Enter password to access the library` | `请输入密码访问文献库` |
  | 提交按钮 | `Submit` | `确认` |
  | 标签页 1 | `Reported` | `已汇报` |
  | 标签页 2 | `Assigned` | `已认领` |
  | 标签页 3 | `Unread` | `待阅读` |
]

*当前交互规则*：

- DOI 仅显示纯文本，不再链接到外部站点
- 原文访问通过 `View source / 查看原文` 按钮完成
- 只有一个全局筛选框，对 `已汇报 + 已认领 + 待阅读` 的全部文献统一筛选
- 命中筛选条件的文献卡片黄色高亮
- `已汇报 / 已认领 / 待阅读` 中的文献可显示：汇报人姓名、汇报日期
- 这些信息来自 Zotero item tags：
  - `claimant:姓名`
  - `report-date:YYYY-MM-DD`
- 补传文献会带 `external-claim` 标签
- 认领、撤销认领、撤销补传会调用 Cloudflare Pages Functions 更新 Zotero；前端成功后会立即更新当前页面显示

#quote-block[
如同江湖中的令牌，每个标签对应一种状态，一目了然。
]

#line()

== 📚 第三章 Zotero 端要求·前置心法

#quote-block[
💡 *引言*

欲练此功，必先备齐法器。本章说明 Zotero 群组的必备配置。
]

*公元 2026 年 7 月 5 日｜前置心法*

Zotero 群组中需要有这三个 collection：

- `已汇报`
- `已认领`
- `待阅读`

并准备以下密钥：

- `ZOTERO_API_KEY`
- `ZOTERO_GROUP_ID`

#quote-block[
⚠️ `ZOTERO_API_KEY` 需要对目标群组至少具备读写权限，如同进入藏经阁的通行令牌。
]

#line()

== ⚙️ 第四章 GitHub Actions 配置·自动运转

#quote-block[
💡 *引言*

自动化是这套方案的核心引擎。本章详解两个关键 Workflow。
]

*公元 2026 年 7 月 5 日｜自动运转*

=== 4.1 sync\_zotero\_hugo.yml

*作用*：

+ 使用 Python 3.11 运行脚本
+ 调用 `zotero_move_claims.py` 将已过汇报日期的文献从 `已认领` 移到 `已汇报`
+ 调用 `zotero_to_json.py` 拉取 Zotero 文献并生成 `assets/zotero-hugo/papers.json`
+ 自动提交更新后的 `papers.json`

*相关 Secrets*：

#tablem[
  | Secret 名称 | 说明 |
  | :--- | :--- |
  | `ZOTERO_API_KEY` | Zotero API 密钥 |
  | `ZOTERO_GROUP_ID` | Zotero 群组 ID |
  | `ZOTERO_DEPLOY_TOKEN` | 部署令牌 |
  | `ZOTERO_CATEGORIES` | 分类配置（可留空，默认 `已汇报,已认领,待阅读`） |
]

=== 4.2 publish.yaml

*作用*：

+ 构建 Hugo 站点
+ 处理站点中已有的 Staticrypt 页面
+ 将 `.github/cloudflare-pages/functions` 临时复制为根目录 `functions`
+ 调用 `wrangler pages deploy public --project-name=xulab`

#quote-block[
如同机关连弩，一环扣一环，从拉取到构建到部署，全自动运转。
]

#line()

== ☁️ 第五章 Cloudflare Pages Functions·云端剑法

#quote-block[
💡 *引言*

云端函数是文献库交互的枢纽。本章解读两个核心函数的职责与配置。
]

*公元 2026 年 7 月 5 日｜云端剑法*

当前函数源码位置：

- `.github/cloudflare-pages/functions/api/zotero-hugo/zotero-add.js`
- `.github/cloudflare-pages/functions/api/zotero-hugo/zotero-claim.js`

运行时 API 路径：

- `/api/zotero-hugo/zotero-add`
- `/api/zotero-hugo/zotero-claim`

*说明*：

- 这两个函数不会因为运行成功或失败给仓库作者发邮件
- `zotero-add.js` 调用 Crossref 和 Zotero API 创建补传文献
- `zotero-claim.js` 负责认领、撤销认领、删除补传条目

*Cloudflare Pages 环境变量需要配置*：

#tablem[
  | 环境变量 | 说明 |
  | :--- | :--- |
  | `ZOTERO_API_KEY` | Zotero API 密钥 |
  | `ZOTERO_GROUP_ID` | Zotero 群组 ID |
]

#quote-block[
这两个云端函数如同江湖中的飞鸽传书，认领与补传的指令由此发出，静默无声，却精准到位。
]

#line()

== 🐍 第六章 Python 版本·内功根基

#quote-block[
💡 *引言*

内功根基不可忽视。本章确认 Python 版本要求。
]

*公元 2026 年 7 月 5 日｜内功根基*

当前流程使用并支持 *Python 3.11*：

- `sync_zotero_hugo.yml` 已固定 `python-version: '3.11'`
- 本地已确认仓库里的 Zotero 同步脚本语法可在 Python 3.11 下运行

#quote-block[
如同武学内功，版本一致方能气血畅通。
]

#line()

== 📄 第七章 Hugo 页面文件·阵法布局

#quote-block[
💡 *引言*

Hugo 页面是文献库的门面。本章展示中英文页面的路径与 shortcode 调用方式。
]

*公元 2026 年 7 月 5 日｜阵法布局*

*英文页面*：

- `content/en/post/Literature for Group Meeting/index.md`

*中文页面*：

- `content/zh/post/Literature for Group Meeting/index.md`

*shortcode 调用方式*：

```markdown
{{< zotero-hugo/zotero_library lang="en" repo="Helloxiaolaodi/lab.github.io" >}}
```

或：

```markdown
{{< zotero-hugo/zotero_library lang="zh" repo="Helloxiaolaodi/lab.github.io" >}}
```

#quote-block[
shortcode 如同阵法中的口诀，一声令下，文献库便在中英文界面间自如切换。
]

#line()

== 🧪 第八章 本地测试流程·闭关修炼

#quote-block[
💡 *引言*

上线之前，先在本地闭关修炼。本章详述完整的本地测试流程。
]

*公元 2026 年 7 月 5 日｜闭关修炼*

=== 8.1 生成静态站点

在仓库根目录执行：

```powershell
hugo --minify --baseURL "http://127.0.0.1:8788/"
```

=== 8.2 临时生成 Pages Functions 目录

```powershell
Copy-Item -Recurse -Force .github\cloudflare-pages\functions .\functions
```

=== 8.3 启动本地 Pages 调试

```powershell
wrangler pages dev public --port 8788
```

如果要测试 Functions 访问 Zotero，需要仓库根目录已有 `.dev.vars`，例如：

```text
ZOTERO_API_KEY=你的Zotero_API_Key
ZOTERO_GROUP_ID=你的Zotero_Group_ID
```

*访问示例*：

#tablem[
  | 语言 | 地址 |
  | :--- | :--- |
  | 英文页 | `http://127.0.0.1:8788/en/post/literature-for-group-meeting/` |
  | 中文页 | `http://127.0.0.1:8788/zh/post/literature-for-group-meeting/` |
]

#quote-block[
闭关修炼，先在本地验证无误，再出关上线，方为稳妥之道。
]

#line()

== 🧹 第九章 清理建议·善后收招

#quote-block[
💡 *引言*

行军之后，善后收招同样重要。本章给出保持仓库简洁的清理建议。
]

*公元 2026 年 7 月 5 日｜善后收招*

为了尽量符合上游仓库作者对简洁结构的要求：

- 不把 Zotero-Hugo 源码放到新的根级目录
- 不长期保留根目录 `functions/`
- 将根目录 `functions/` 仅视为部署或本地调试时的临时产物
- `.gitignore` 已忽略：
  - `.dev.vars`
  - `.wrangler/`
  - `functions/`
  - `.github/scripts/zotero-hugo/__pycache__/`

#quote-block[
如同高手出招，来去无痕，不留冗余。
]

#line()

== 🔑 第十章 Zotero API Key 权限建议·最小权限

#quote-block[
💡 *引言*

权限如门禁，宁小勿大。本章给出最小权限配置建议。
]

*公元 2026 年 7 月 5 日｜最小权限*

建议最小权限配置：

#tablem[
  | 配置项 | 建议 |
  | :--- | :--- |
  | `Key name` | `xulab_hugo` |
  | `Personal Library` | 不勾选，除非确实需要访问个人库 |
  | `Default Group Permissions` | 不授予所有群组默认写权限 |
  | `Specific Groups` | 只给目标群组 `Read/Write` |
]

原因是这套流程需要对目标群组进行读取、认领、撤销、补传和自动移动条目，但不需要更大范围权限。

#quote-block[
如同江湖令牌，权限越小越安全，只开必要的门。
]

#line()

== 🔔 第十一章 通知边界·江湖规矩

#quote-block[
💡 *引言*

此套方案自有其边界。本章明确通知的边界在哪里。
]

*公元 2026 年 7 月 5 日｜江湖规矩*

这套新增代码本身不会主动：

- 给仓库作者发邮件
- 在 GitHub issue / PR 自动留言
- 发送 Slack / Discord / Webhook 通知

但 GitHub / Cloudflare 平台级通知是否出现，取决于平台账户和项目设置，而不是仓库代码本身。

#quote-block[
如同江湖规矩，各人自扫门前雪。代码只做分内之事，不越界传信。
]

#line()

== 📋 附录一 常见问题与排查

#quote-block[
💡 *引言*

江湖行走，疑难重重，且听在下一一道来。
]

=== 附1.1 问：papers.json 没有更新怎么办？

*答*：检查 GitHub Actions 中 `sync_zotero_hugo.yml` 的运行日志，确认 Zotero API Key 和 Group ID 是否正确配置为 Repository Secrets。

=== 附1.2 问：本地测试时 Cloudflare Functions 不工作？

*答*：确认是否已执行 `Copy-Item` 将 `.github/cloudflare-pages/functions` 复制为根目录 `functions`，以及 `.dev.vars` 中是否配置了 `ZOTERO_API_KEY` 和 `ZOTERO_GROUP_ID`。

=== 附1.3 问：认领/撤销操作没有实时反映？

*答*：Cloudflare Pages Functions 需要正确配置环境变量。检查 Wrangler 本地调试时是否加载了 `.dev.vars`。

=== 附1.4 问：如何添加新的文献分类？

*答*：在 Zotero 群组中创建对应 collection，然后在 `ZOTERO_CATEGORIES` Secret 中追加分类名称（英文逗号分隔），同时更新 shortcode 中的标签页配置。

#line()

== 🔐 附录二 Zotero API Key 权限速查

#tablem[
  | 操作 | 所需权限 | 说明 |
  | :--- | :--- | :--- |
  | 拉取文献 | Read | 读取群组文献数据 |
  | 认领/撤销认领 | Write | 修改 item tags |
  | 补传文献 | Write | 创建新 item |
  | 自动移动条目 | Write | 在 collections 间移动 item |
]

#quote-block[
最小权限原则：只给目标群组 `Read/Write`，不勾选 Personal Library。
]

#line()

== 📝 跋文

*公元 2026 年 7 月 5 日｜收笔感怀*

#quote-block[
长路漫漫，文献浩繁，唯有自动化与吾同行。
]

这套 Zotero-Hugo 部署方案，虽步骤繁多，然环环相扣，一旦配好，便是"一次配置，永久受益"。

从 Zotero 群组的文献同步，到 GitHub Actions 的自动构建，再到 Cloudflare Pages 的全球部署，每一步都有章可循、有据可查。

若阁下正为组会文献管理而头疼，或正在寻找一套*从 Zotero 到网站的全自动文献库方案*，此秘笈值得一试。

#line()

多年以后，当阁下回首这段文献库部署之旅，或许会感慨：

#quote-block[
*幸得 Zotero-Hugo 相伴，文献管理不再是噩梦，而成为了科研路上的得力助手！*
]

江湖路远，吾等皆为过客。愿诸位同道在文献的江湖中，*执剑前行，不负韶华*！


#line()

== 文档信息

- *作者*：杨三多（Yangsanduo）
- *江湖称号*：别看我只是一只 🐏
- *创建时间*：公元 2026 年 7 月 5 日（丙午年 六月十一）
- *文档版本*：v1.0
- *对应仓库*：`lab仓库`
- *编辑器格式*：Markdown（支持 editor.md）

#line()

== 版权声明

本文档基于实际部署经验整理，融合北宋古文与现代白话之风，部分内容参考 Zotero、Hugo 及 Cloudflare 官方文档。

*欢迎转载和分享，但需注明出处*：

#quote-block[
《Zotero-Hugo 文献库部署秘笈》
作者：杨三多
原文链接：[待补充博客园链接]
]

#line()

\<strong\>— 全文完 —\</strong\>

江湖路远，后会有期 🎋
