#import "../index.typ": template, tufted

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "科研利器之 Zotero 在 Google Docs 中的文献引用",
  description: "在 Google Docs 中用 Zotero 插入文内引用并生成参考文献列表的完整流程，以 Nature Communications 样式为例。",
  date: datetime(year: 2026, month: 11, day: 13),
  lang: "zh",
)

= 科研利器之 Zotero 在 Google Docs 中的文献引用

本文介绍在 Google Docs 中用 Zotero 插入引用、生成参考文献的完整流程，以 Nature Communications 样式为例。

#line()

== 一、安装 Zotero Connector

Zotero 桌面端管理文献，Zotero Connector 浏览器扩展负责抓取网页文献。

=== 1.1 从 Chrome 应用商店安装

搜索 `zotero`，点击 Zotero Connector 的“添加至 Chrome”。

#figure(
  image("imgs/03-chrome-toolbar-extensions.png"),
  caption: [浏览器工具栏中的 Zotero Connector 扩展],
)

=== 1.2 确认已启用

打开 `chrome://extensions`，确认 Zotero Connector 已开启。

#figure(
  image("imgs/02-chrome-extensions-page.png"),
  caption: [扩展程序页中的应用商店入口与已启用的 Connector],
)

#line()

== 二、整理待引用的文献

=== 2.1 归入同一分类

左侧选择分类（如 Periodontics），右侧列表即为待引用条目。

#figure(
  image("imgs/13-zotero-document-preferences.png"),
  caption: [Document Preferences 对话框],
)

=== 2.2 核对元数据

选中条目，右侧 Info 面板显示标题、作者、期刊、年份、卷期页码；参考文献的准确性取决于此。

#figure(
  image("imgs/18-gdocs-reference-list.png"),
  caption: [自动生成的 1–6 号参考文献],
)

#line()

== 三、安装引用样式

=== 3.1 打开设置

Zotero 菜单栏 Edit → Settings。

#figure(
  image("imgs/11-google-authorize.png"),
  caption: [确认授权并 Continue],
)

=== 3.2 获取更多样式

Settings → Cite → Get Additional Styles...

#figure(
  image("imgs/12-gdocs-document-preferences.png"),
  caption: [选样式、语言后点 OK],
)

=== 3.3 搜索并安装

Style Search 输入 `Nature Com`，点击结果中的 Nature Communications。

#figure(
  image("imgs/14-gdocs-zotero-menu.png"),
  caption: [Zotero 菜单中的 Add/edit citation],
)

#line()

== 四、授权 Google Docs

首次使用需关联 Google 账号，仅需一次。

=== 4.1 选择账号

在账号选择页选中要使用的账号。

#figure(
  image("imgs/09-zotero-cite-style-list.png"),
  caption: [Cite 列表与 Style Preview],
)

=== 4.2 授予权限

阅读权限说明后点击 Continue。

#figure(
  image("imgs/06-zotero-edit-menu.png"),
  caption: [Edit → Settings],
)

#line()

== 五、设置文档样式

=== 5.1 Document Preferences

Zotero → Document preferences：Citation Style 选 Nature Communications，Language 选 English (UK)，点 OK。建议保持 Automatically update citations 勾选，文献库变动时自动同步。

#line()

== 六、插入文内引用

=== 6.1 Add/edit citation

光标置于引用处，Zotero → Add/edit citation...

=== 6.2 批量选择

搜索并勾选文献，本例 6 条，点 Add all；单篇文献的引用，鼠标单击该文献条目即可。

#figure(
  image("imgs/15-zotero-add-all.png"),
  caption: [选中 6 条后点 Add all],
)

=== 6.3 确认插入

上方列出 6 条已选引用，确认后点插入按钮，文中出现成组编号（如 1–6）。

#figure(
  image("imgs/16-zotero-citation-chips.png"),
  caption: [确认已选引用并插入],
)

#line()

== 七、生成参考文献列表

=== 7.1 定位并插入

文末写好 Reference 标题，光标置于其下，Zotero → Add/edit bibliography。

#figure(
  image("imgs/17-gdocs-add-bibliography.png"),
  caption: [在 Reference 下插入文献列表],
)

=== 7.2 查看结果

列表按 Nature Communications 样式自动排版，编号 1–6，信息取自 2.2 核对的元数据。

#figure(
  image("imgs/05-zotero-item-info.png"),
  caption: [Info 面板中的作者、期刊、年份等字段],
)

#line()

== 八、更新与维护

=== 8.1 手动刷新

修改文献库后，Zotero → Refresh 同步引用与列表。

#figure(
  image("imgs/19-gdocs-refresh-bibliography.png"),
  caption: [用 Refresh 同步引用与列表],
)

=== 8.2 切换样式

Zotero → Document preferences 可随时更换样式，全文自动重排。

#figure(
  image("imgs/20-gdocs-document-preferences-menu.png"),
  caption: [通过 Document preferences 更换样式],
)

#line()

== 九、小结

分两端管理：Zotero 端整理条目、装样式；Google Docs 端装 Connector、设样式、插引用、生成列表、刷新。此后每篇稿件只需“选样式 → 插引用 → 生成列表 → 刷新”四步，编号与格式由 Zotero 自动维护。
