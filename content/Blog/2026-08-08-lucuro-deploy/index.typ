#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *
#import "@preview/theorion:0.6.0": quote-block

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "Lucuro 仓库部署解读",
  description: "逐层拆解 Lucuro（鹿客司南）浏览器扩展的架构、部署流程、仓库文件职责与运维排错。",
  date: datetime(year: 2026, month: 8, day: 8),
  lang: "zh",
)

= Lucuro 仓库部署解读

=== I. 项目概述与架构原理

- 1. 项目定位
- 2. 术语说明
- 3. 架构概览
- 4. 数据模型与运行逻辑

=== II. 完整部署指南

- 5. 克隆后优先检查的文件
- 6. 部署前准备
- 7. 部署流程
- 8. 验证清单

=== III. 仓库代码与工程管理

- 9. 仓库文件说明
- 10. 更细的逐文件职责图谱

=== IV. 运维、维护与故障排查

- 11. 维护建议
- 12. 按真实故障场景组织的排错章节
- 13. 安全强化与隐私保护
- 14. 结论

== I. 项目概述与架构原理

=== 1. 项目定位

Lucuro - 鹿客司南 是一个基于 Vue 3 的 Manifest V3 浏览器扩展，用于接管浏览器新标签页并提供一个轻量、美观、本地优先的个人导航工作台。工具栏弹窗用于开启或关闭 Lucuro 对新标签页的接管，主页面会恢复用户上次明确选择的数据源。浏览器书签只会在用户明确选择“浏览器书签”后导入；“本地 JSON”作为互斥替代方案，并会持久化到扩展存储中。

项目的核心设计原则可以概括为四点：

- 核心功能保持纯前端和本地优先，即使网络不可用，书签、设置、语录与今日手记仍然可用。
- 用户数据同时写入 `chrome.storage.local` 与 `chrome.storage.sync`，让配置保持轻量、适合浏览器原生跨设备同步，同时保留本地副本。
- 使用浏览器原生书签捕获：只有用户明确选择“浏览器书签”后，才通过内置的 `bookmarks` 权限读取本地书签树；选择“本地 JSON”时恢复已保存的 JSON 数据，不导入 Mock 数据，也不依赖后端。
- 权限面保持最小：`storage`、`unlimitedStorage`、`activeTab` 与内置的 `bookmarks` 权限，并仅为反馈表单声明 `host_permissions`。

==== 1.1 名字的由来：琉璃司南

“司南”是中国古代最早的指南工具，指向明确、形态简洁；而“鹿客”既保留了 Lucuro 的读音节奏，又带有祥瑞与探索者的东方意象。Lucuro 将“司南”的导航含义转化为现代数字罗盘：它帮助用户在新标签页快速找到网址、工具与灵感。

*为什么是琉璃司南？*

- *方向 → 数字导航*：司南指向方向，浏览器起始页则指向网址、任务与每日灵感。
- *琉璃 → 现代界面*：半透明面板、毛玻璃模糊和微光高光，把古代器物转化为现代玻璃质感界面。
- *武侠 → 默认皮肤*：中国古典武侠风是默认视觉方案，但数据模型、设置和主题都允许用户自定义，并不把用户锁死在单一风格里。

#quote-block[
*Slogan*：Stay lucky, stay curious. / 指引数字世界的琉璃司南。
]

=== 2. 术语说明

- *新标签页*：用户新建浏览器标签页时打开的页面，Lucuro 通过 `chrome_url_overrides.newtab` 接管。
- *弹窗*：工具栏上的扩展菜单，用于开启或关闭 Lucuro 对新标签页的接管；关闭后恢复浏览器默认新标签页。
- *本地优先数据*：网址、设置、统计、语录和今日手记首先写入浏览器扩展存储。
- *原生同步*：通过 `chrome.storage.sync` 由浏览器账号完成的跨设备同步，需要多台设备登录同一浏览器账号。
- *浏览器书签*：用户浏览器中的原生书签树；当数据源为“浏览器书签”时，通过 `chrome.bookmarks.getTree()` 自动在本地读取。
- *布局锁定*：防止拖拽排序时误改网址卡片的 UI 状态。
- *琉璃司南*：内联 SVG 品牌标识，用于工具栏、扩展管理页、新标签页与商店图标。
- *内置权限*：例如 `bookmarks`，随 manifest 安装时声明，用于在用户明确选择“浏览器书签”后读取浏览器原生书签。

外部标识应保持真实值，包括 GitHub 账号名、仓库 URL、商店名称、Ko-fi 链接和微信收款码资源路径。

=== 3. 架构概览

==== 3.1 扩展外壳

- `index.html` 是新标签页主应用入口。
- `popup.html` 是工具栏弹窗入口，用于开启或关闭 Lucuro 新标签页接管。
- `src/` 包含 Vue 组件、store、composable 与应用逻辑。
- `public/manifest.json` 是构建时复制到 `dist/` 的扩展清单。

==== 3.2 本地数据层

- `lucuro_links_v1`：网址树、分类、卡片、图标与排序信息。
- `lucuro_settings_v1`：主题、语录、搜索引擎、布局锁定等偏好。
- `lucuro_stats_v1`：点击频率，用于按使用频率排序。
- `lucuro_data_source`：用户上次明确选择的数据源（`browser` 或 `json`）。
- `lucuro_local_json_data`：导入的本地 JSON 网址树，用于下次打开新标签页时恢复。

扩展不包含 Cloudflare Worker、取件码分享服务或外部数据服务器。唯一的外部端点是可选的 Formspree 反馈表单。

==== 3.3 同步层

- 普通跨设备同步使用浏览器原生 `chrome.storage.sync`，同时把本地副本写入 `chrome.storage.local`。
- 如果同步存储不可用，本地副本仍然可用。
- 扩展没有 Worker 域名，也没有分享端点。唯一的 `host_permissions` 是 `https://formspree.io/*`，用于可选的反馈表单。

==== 3.4 弹窗与新标签页行为

- 弹窗提供 Lucuro 新标签页接管的开启/关闭开关。开启时由 Lucuro 接管新标签页，关闭时恢复浏览器默认新标签页。
- 当 `newTabEnabled` 为 `false` 时，`index.html` 会优先调用浏览器扩展 `tabs.create({})` 直接打开浏览器原生默认新标签页，并关闭 Lucuro 接管页；仅当创建失败时，Firefox 才尝试 `about:newtab`，Edge 依次尝试 `edge://newtab/`、`chrome://newtab/` 与 `chrome://new-tab-page/`，Chrome 依次尝试 `chrome://newtab/` 与 `chrome://new-tab-page/`；不会跳转到 `chrome-search://local-ntp/local-ntp.html` 或插件内空白页。
- 弹窗与主页面使用同一套存储键，不需要独立后端。

==== 3.5 为什么是这种架构

浏览器起始页的核心价值是打开快、数据可靠、隐私边界清晰。Lucuro 选择纯前端架构，不引入账号、数据库或专用服务器。核心导航保持本地优先，安装后即可使用，也避免不必要的数据上传。可选书签流程只在本地读取浏览器原生书签树，不把书签数据发送到服务器。

=== 4. 数据模型与运行逻辑

==== 4.1 本地存储键

#tablem[
  | 键名 | 用途 | 体积建议 |
  | :--- | :--- | :--- |
  | `lucuro_links_v1` | 分类、卡片、图标与排序 | 小型 JSON |
  | `lucuro_settings_v1` | 主题、语录、搜索引擎、锁定状态 | 小型 JSON |
  | `lucuro_stats_v1` | 按使用频率排序所需的点击统计 | 小型 JSON |
  | `lucuro_data_source` | 上次明确选择的数据源：`browser` 或 `json` | 极短字符串 |
  | `lucuro_local_json_data` | 导入的本地 JSON 网址树，启动时恢复 | 小型 JSON |
]

数据以纯 JSON 保存。图标优先使用 Favicon CDN URL，避免把图片 Base64 塞进存储，因此配置体积适合原生同步。

==== 4.2 新标签页运行逻辑

启动时主页面会：

+ 从扩展存储读取设置、网址、统计与已保存的数据源；
+ 检查 `newTabEnabled`，关闭接管时跳转到浏览器默认新标签页；
+ 恢复上次的数据源：只有用户明确选择“浏览器书签”时才导入书签，“本地 JSON”从 `lucuro_local_json_data` 恢复，未选择数据源时渲染空状态且不读取书签；
+ 渲染自动隐藏侧边栏、搜索框、一言、今日手记与网址网格；
+ 监听键盘快捷键；
+ 对高频编辑做防抖写入，避免拖拽排序触发大量存储请求。

==== 4.3 弹窗运行逻辑

弹窗会：

+ 读取当前的 `newTabEnabled` 设置；
+ 让用户开启或关闭 Lucuro 新标签页接管；
+ 将开关状态写入同一套扩展存储键；
+ 保存成功后关闭弹窗。

==== 4.4 书签捕获运行逻辑

书签捕获跟随数据源：

- 初始数据源为 `null`；扩展不会在用户明确选择“浏览器书签”前读取浏览器书签。
- 数据源为“浏览器书签”时，主页挂载后以及用户选择该数据源后调用 `chrome.bookmarks.getTree()`。
- 树结构被转换为 Lucuro 分类与卡片，并按 URL 去重合并。
- 数据源为“本地 JSON”时，恢复已保存的 JSON，不再读取浏览器书签。

该过程中书签数据不会离开浏览器。

==== 4.5 同步运行逻辑

原生同步由浏览器管理：

- 写入会同时发送到 `chrome.storage.local` 与 `chrome.storage.sync`；同步写入会做防抖，避免频繁消耗配额。
- 同步不可用时，本地副本仍然可用。
- 没有手动上传/拉取界面，也没有云端分享端点。

==== 4.6 隐私边界

- 核心功能不依赖账号、分析或遥测。
- 扩展只为 `https://formspree.io/*` 声明 `host_permissions`，用于用户提交可选的反馈表单。
- 内置的 `bookmarks` 权限用于在用户明确选择“浏览器书签”后本地导入书签。
- 用户的笔记、Token 和私有配置不会上传到第三方服务；反馈表单只发送用户自愿填写的姓名、邮箱和反馈内容到 Formspree。
- 支持链接、用户配置的远程 Favicon 或背景图片，只会在用户主动使用对应功能时访问外部地址。

== II. 完整部署指南

=== 5. 克隆后优先检查的文件

开始修改前先检查：

- `public/manifest.json`：扩展身份、权限、图标、新标签页接管与弹窗路径。
- `vite.config.js`：构建入口、输出目录、别名与 `rollup-plugin-visualizer` 配置。
- `src/`：应用源码与功能实现。
- `public/`：静态资源、图标、清单与微信收款码。
- `package.json`：构建脚本与依赖版本。
- 产品仓库 `docs/`：部署与维护说明。
- `README.md` 与 `README.zh-CN.md`：本地安装与调试说明、社区链接和许可证信息。

=== 6. 部署前准备

==== 6.1 账号与基础依赖

+ 安装 Node.js 与 npm。
+ 打开 `D:\YL2026\Vue\Lucuro-vue`。
+ 运行 `npm install`。
+ 准备要发布到的 Chrome Web Store、Microsoft Edge Add-ons 或 Firefox AMO 开发者账号。

==== 6.2 构建与打包检查

执行构建：

```bash
npm run build
```

`dist/` 中应包含 `index.html`、`popup.html`、`manifest.json`、`assets/` 与 `icons/`。

Vite 构建还会通过 `rollup-plugin-visualizer` 生成 `stats.html`，显示 gzip 与 brotli 体积。发布前应检查该报告，避免第三方依赖或组件意外增大插件包。

==== 6.3 Manifest 与图标检查

验证 `public/manifest.json`：

- `manifest_version: 3`
- `chrome_url_overrides.newtab: index.html`
- `action.default_popup: popup.html`
- `icons` 包含 16、32、48、128 像素 PNG。
- `action.default_icon` 包含工具栏尺寸图标。
- `permissions` 包含 `storage`、`unlimitedStorage`、`activeTab` 与 `bookmarks`。
- `host_permissions` 只包含 `https://formspree.io/*`，用于可选的反馈表单。
- CSP 只允许本地脚本、本地对象与配置好的图片来源。

==== 6.4 隐私与商店上架准备

上架前准备以下内容：

- 隐私政策：说明数据保存在 `chrome.storage` 中，并由用户登录的浏览器账号进行原生同步。
- 商店简介：使用官方描述 `A minimalist glassmorphism startpage guiding your digital exploration.`。
- 截图：新标签页浅色模式、深色模式、侧边栏导航、语录自定义、今日手记、设置与弹窗。
- 权限说明：书签捕获使用内置 `bookmarks` 权限，只在用户明确选择“浏览器书签”后读取本地书签。
- 隐私说明：可选的反馈表单只把用户自愿填写的姓名、邮箱和反馈内容发送到 Formspree。

=== 7. 部署流程

==== 7.1 本地初始化

```powershell
cd D:\YL2026\Vue\Lucuro-vue
npm install
```

==== 7.2 构建插件

```bash
npm run build
```

检查 `dist/` 是否完整，并确认 `stats.html` 已重新生成。

==== 7.3 Windows 本地测试

===== Chrome 或 Edge（Chromium 内核）

+ Chrome 在地址栏打开 `chrome://extensions/`，Edge 在地址栏打开 `edge://extensions/`。
+ 打开页面右上角或左侧的“开发者模式”（Developer mode）。
+ 点击“加载已解压的扩展程序”（Load unpacked）。
+ 选择 `dist/` 目录，目录根位置必须直接包含 `manifest.json`。
+ 按 `Ctrl+T` 新建标签页。如果浏览器询问是否保留更改，选择“保留更改”（Keep it）。
+ 确认新标签页已经渲染 Lucuro 琉璃毛玻璃主页。
+ 打开工具栏弹窗，确认开启/关闭开关可以保存并读取。
+ 测试浅色/深色模式、一言轮换、今日手记、拖拽排序、布局锁定和自动隐藏侧边栏。
+ 在设置中确认初始数据源为空，只有明确选择“浏览器书签”后才导入书签；切换到“本地 JSON”后恢复已保存的 JSON 数据。
+ 在弹窗中关闭 Lucuro，确认新标签页会打开浏览器默认主页，而不是 Lucuro。

===== Firefox

+ 在地址栏打开 `about:debugging#/setups/this-firefox`。
+ 点击“临时载入附加组件...”（Load Temporary Add-on...）。
+ 选择 `dist/` 目录中的 `manifest.json`。
+ 新建标签页，确认 Lucuro 正常接管并渲染。
+ 继续验证工具栏弹窗、开启/关闭开关、设置面板和明确选择后的书签导入。

Firefox 临时加载的扩展在浏览器重启后会失效，下次测试需要重新加载。

===== 修改代码后的调试

- 如果只修改了 `index.html`、`popup.html`、CSS 或页面级 JavaScript，在 Lucuro 新标签页或弹窗中按 `F5` 刷新即可；需要强制刷新时可使用 `Ctrl+F5`。
- 如果修改了 `manifest.json`、权限或扩展级脚本，需要回到扩展管理页，点击 Lucuro 的“刷新/重新加载”（Reload）按钮。
- 如果按钮无响应，在 Lucuro 页面或弹窗中按 `F12` 打开开发者工具，检查 *Console（控制台）* 与 *Network（网络）* 标签页的报错信息。

==== 7.4 创建商店包

只打包构建产物：

```powershell
Compress-Archive -Path dist\* -DestinationPath D:\YL2026\Vue\lucuro-edge-v0.1.0.zip -Force
Compress-Archive -Path dist\* -DestinationPath D:\YL2026\Vue\lucuro-firefox-v0.1.0.zip -Force
```

本仓库已把这两个商店包放在 `D:\YL2026\Vue\`：Chrome 与 Edge 使用 `lucuro-edge-v0.1.0.zip`，Firefox 使用 `lucuro-firefox-v0.1.0.zip`。上传包中不要包含 `node_modules`、source map 或本地开发文件。ZIP 根目录必须直接包含 `manifest.json`。

- 先执行 `npm run build`，确保 `dist/` 中是最新生产代码。
- 打开 `dist/`，选中里面的所有文件和文件夹，包括 `assets`、`icons` 和 `manifest.json`。
- 将选中的内容压缩成一个 ZIP，例如 `lucuro-edge-v0.1.0.zip` 或 `lucuro-firefox-v0.1.0.zip`。
- 不要压缩外层的 `dist/` 文件夹本身，也不要上传 `src/`、`node_modules/` 或 `package.json`。

==== 7.5 打包上传 Chrome Web Store

+ 登录 #link("https://chrome.google.com/webstore/devconsole")[Chrome Web Store Developer Dashboard]。
+ 首次提交时完成开发者注册并填写开发者信息。
+ 点击 *New item*，上传 `lucuro-edge-v0.1.0.zip`，等待仪表盘校验包结构。
+ 填写扩展名称 `Lucuro - 鹿客司南`、英文简介、分类、语言和联系方式。
+ 上传 128x128 PNG 商店图标，以及展示新标签页、弹窗、设置与深色模式真实界面的截图。
+ 提供隐私政策 URL，说明本地存储、浏览器原生同步、浏览器书签数据源、Ko-fi 与微信收款码支持。
+ 确认权限声明与 manifest 一致：`storage`、`unlimitedStorage`、`activeTab`、内置的 `bookmarks`，以及用于反馈表单的 `https://formspree.io/*`。
+ 提交审核。Chrome Web Store 会执行自动包检查，并可能要求人工审核。

Chrome 开发者注册需要支付一次性费用。因为 Lucuro 声明了 `bookmarks` 权限，商店页面必须提供公开隐私政策 URL。在 GitHub 仓库中提供 `PRIVACY.md` 即可，内容应明确说明书签与设置只保存在本地，不会上传到 Lucuro 服务器。

==== 7.6 上架 Microsoft Edge Add-ons

+ 登录 #link("https://partner.microsoft.com/dashboard/microsoftedge")[Microsoft Edge Add-ons Partner Center]。
+ 创建新的扩展提交。
+ 上传同一份 `lucuro-edge-v0.1.0.zip`，ZIP 根目录包含 `manifest.json`。
+ 复用 Lucuro 的名称、截图、描述、分类和隐私政策。
+ 确认权限列表与 manifest 一致。
+ 提交审核并等待通知。

Microsoft 允许 Chromium 扩展直接复用同一个 ZIP，无需改写代码。Edge 开发者注册完全免费，Edge Add-ons 的审核通常只需要 1 到 2 个工作日。

==== 7.7 上架 Firefox AMO（可选）

+ 登录 #link("https://addons.mozilla.org/")[Firefox Add-ons]。
+ 上传 `lucuro-firefox-v0.1.0.zip` 构建包，或在商店要求时提交源码审核包。
+ 确认 `browser_specific_settings.gecko.id` 保持稳定。
+ 按页面要求填写隐私与源码信息。
+ 提交审核。

如果 Mozilla 因为 Vite 输出的是压缩后的 JavaScript 而要求源码审核包，请把 `src/`、`vite.config.js`、`package.json` 等构建输入文件打包，并排除 `node_modules/` 和 `.git/`，同时明确说明构建命令是 `npm run build`。

==== 7.8 发布版本更新

发布新版本时：

+ 在 `manifest.json` 中递增 `version`。
+ 运行 `npm run build`。
+ 检查 `stats.html` 中的体积变化。
+ 在本地重新测试新标签页和弹窗。
+ 创建新的 ZIP 包。
+ 把包上传到各商店并提交审核。

==== 7.9 发布后验证

商店接受更新后至少验证：

- 从商店安装发布版本。
- 新标签页接管仍然生效。
- 工具栏弹窗仍然可用。
- 浏览器原生同步仍然可用。
- 已保存的数据源可以恢复，浏览器书签只在明确选择后导入。
- 16、32、48、128 像素图标都正确显示。

==== 7.10 商店发布物料检查清单

向任一商店提交前准备好以下物料：

- 无背景透明的 128x128 PNG 图标。
- 能展示真实界面的商店截图，包括浅色模式、深色模式、侧边栏导航、弹窗、一言自定义、今日手记和设置界面。
- 商店名称与简介使用 `Lucuro - 鹿客司南` 和 `A minimalist glassmorphism startpage guiding your digital exploration.`。
- 隐私政策页面或仓库文档，说明本地存储、浏览器原生同步、明确选择后的书签捕获、Formspree 反馈表单与第三方赞助链接。
- 根目录直接包含 `manifest.json` 的 ZIP 包，且不含调试文件、源码或依赖目录。

=== 8. 验证清单

==== 8.1 新标签页

- 安装后 Lucuro 会在新标签页渲染。
- 首次未选择数据源时保持空状态，不自动读取浏览器书签。
- 已保存的数据源会在新标签页打开时恢复并渲染对应网址。
- 关闭 `newTabEnabled` 后打开浏览器默认新标签页。
- 自动隐藏侧边栏、搜索框、一言、今日手记和网址网格可见。
- 浅色与深色模式符合设计。
- 键盘快捷键正常工作。

==== 8.2 弹窗

- 可以从工具栏打开弹窗。
- 弹窗用于启用或禁用 Lucuro 的新标签页接管。
- 启用状态在浏览器重启后仍然保存。
- 弹窗保存后会自动关闭，不包含当前页面添加或书签捕获控制。

==== 8.3 设置

- 外观、语言、搜索引擎、布局锁定和数据源设置可以持久化。
- 一言自定义可以保存并刷新，默认语录每 10 秒自动轮换。
- 背景模糊与背景选区裁剪可以保存，背景图在日间/夜间模式下保持一致。
- 上传背景默认模糊为 0，背景选区比例与视口一致。
- 头像上传可以保存，默认头像使用 Lucuro 标识；头像入口位于左侧侧边栏。
- 设置窗口固定尺寸，内容区域内部滚动。
- 搜索引擎仅保留 Google、Bing、Baidu 与 GitHub。
- 卡片编辑不包含描述字段，分类编辑不包含副标题字段。

==== 8.4 数据与同步

- 编辑操作经过防抖并写入存储。
- 本地 JSON 数据源下的编辑会自动写入 `lucuro_local_json_data`。
- 原生同步写入没有错误。
- 同步不可用时本地回退正常。
- 浏览器书签捕获合并时不会重复已有卡片。

==== 8.5 构建产物

- `npm run build` 成功。
- `dist/` 包含所有必需文件。
- `stats.html` 已生成，并显示 gzip 与 brotli 体积。
- ZIP 包不包含源码目录和依赖目录。

==== 8.6 商店审核

- 商店名称与 `Lucuro - 鹿客司南` 一致。
- 简介与官方品牌文案一致。
- 截图展示真实产品状态。
- 隐私政策覆盖本地存储、原生同步、浏览器书签数据源、Formspree 反馈表单和支持入口。
- 权限声明与 manifest 一致。

== III. 仓库代码与工程管理

=== 9. 仓库文件说明

==== 9.1 根目录

- `package.json`：npm 脚本与依赖。
- `vite.config.js`：Vite 构建配置与体积分析插件。
- `index.html`：新标签页入口。
- `popup.html`：工具栏弹窗入口。
- `README.md` 与 `README.zh-CN.md`：仓库与构建文档。
- `public/`：构建时复制的静态资源。

==== 9.2 Vue 源码

- `src/`：Vue 组件、store、composable、语言包与样式。
- `src/main.js`：应用启动入口。
- `src/App.vue`：新标签页主组件。
- `src/popup.js` 与 `src/Popup.vue`：弹窗入口与组件。
- `src/utils/`：存储、书签与浏览器 API 封装。

==== 9.3 静态资源

- `public/icons/icon-16.png`、`icon-32.png`、`icon-48.png` 与 `icon-128.png`：商店与浏览器图标。
- `public/qrcode-wechat.png`：国内微信赞赏收款码。
- 背景由用户在设置中自定义，头像由用户在左侧侧边栏上传，`public/` 中不需要固定个人图片。

==== 9.4 Manifest 与 Vite 配置

- `public/manifest.json`：Manifest V3 身份与权限。
- `vite.config.js`：构建输入、别名、输出目录与 `rollup-plugin-visualizer`。

==== 9.5 文档与维护文件

- Chrome、Edge 与可选 Firefox 的部署指南。
- README 用户文档。
- 商店上架文案。

=== 10. 更细的逐文件职责图谱

==== 10.1 应用外壳与状态编排

- `src/App.vue`：组装侧边栏、主内容、设置和浮动面板。
- 主 store：管理网址、设置、统计与书签导入。
- 工具模块：存储读写和浏览器 API 封装。

==== 10.2 弹窗与新标签页开关

- `popup.html` 与弹窗入口文件：工具栏 UI。
- `src/main.js`：渲染完整仪表盘前检查 `newTabEnabled`。
- 关闭接管时优先用 `tabs.create({})` 打开浏览器原生默认新标签页，失败时才按浏览器回退到 `about:newtab`、`edge://newtab/`、`chrome://newtab/` 或 `chrome://new-tab-page/`，避免 `chrome-search://local-ntp/local-ntp.html`。

==== 10.3 设置与主题

- 主题定义：浅色毛玻璃渐变与深色玄黑/夜空蓝。
- 设置面板：链接、外观、指南与快捷键、反馈与支持；包含语言、网址、一言、今日手记、布局锁定、背景模糊与裁剪、头像、数据源与支持。
- CSS 变量：毛玻璃模糊度和响应式布局值。

==== 10.4 一言与手记

- 一言组件：自定义语录轮换与刷新，默认每 10 秒自动轮换。
- 今日手记组件：支持 Markdown 工具栏、自动保存、撤销与清空。

==== 10.5 同步

- 原生同步适配：`chrome.storage.sync` 加本地回退。
- 设置 UI：不提供手动上传、拉取或取件码输入。

==== 10.6 书签捕获

- 数据源为“浏览器书签”时，仅在用户明确选择后读取。
- manifest 内置 `bookmarks` 权限。
- `chrome.bookmarks.getTree()` 解析。
- 转换为 Lucuro 分类与卡片。

==== 10.7 图标与品牌资源

- 琉璃司南 SVG 标识。
- 浏览器与商店使用的 PNG 图标集。
- 工具栏图标变体。

==== 10.8 构建与体积分析

- `rollup-plugin-visualizer` 生成 `stats.html`。
- `sharp` 可用于图标处理工作流。
- Vite 多页面入口处理 `index.html` 与 `popup.html`。

==== 10.9 当前功能模块

- 默认浅色模式与深色玄黑/夜空蓝模式。
- 自定义每日语录“一言”功能。
- 今日手记支持 Markdown 工具栏、自动保存、撤销与清空。
- 自动隐藏侧边栏。
- 浏览器书签仅在用户明确选择后导入，且与本地 JSON 数据源互斥。
- 弹窗用于启用或禁用 Lucuro 的新标签页接管。
- 浏览器原生同步与本地回退。
- 顶部搜索框支持 Google、Bing、Baidu 与 GitHub 四个搜索引擎。
- 本地图片背景与左侧侧边栏头像上传。
- 背景选区比例与视口一致，上传背景默认模糊为 0。
- 设置面板包含 Formspree 反馈表单。
- 海外支持使用 Ko-fi，国内支持微信收款码。
- `rollup-plugin-visualizer` 用于构建体积分析。

== IV. 运维、维护与故障排查

=== 11. 维护建议

==== 11.1 保持本地优先

核心导航不应依赖外部服务器。网络不可用时，本地网址、设置、语录、今日手记和书签数据仍然可用。

==== 11.2 保持存储轻量

优先使用 Favicon CDN URL，不存储图片载荷。点击统计保持有界，避免把大型二进制数据写入扩展存储。

==== 11.3 保持权限诚实

不要随意添加 `bookmarks` 或 `<all_urls>`。商店审核者和用户都会把权限声明视为信任信号。`bookmarks` 只在用户明确选择浏览器书签数据源后使用，反馈表单仅向 Formspree 提交用户自愿填写的内容。

==== 11.4 同时测试弹窗与新标签页

弹窗写入的数据会被新标签页消费。修改任一界面后都要走完整用户路径验证。

==== 11.5 说明同步行为

原生同步由浏览器管理，可能不是即时生效。扩展同时写入本地存储和同步存储，让本地使用在浏览器同步期间保持可用。

==== 11.6 发布前检查体积

运行 `npm run build` 并查看 `stats.html`。如果依赖或组件体积异常，先重构再发布。

==== 11.7 保持商店包干净

ZIP 应小、可复现、不包含开发文件。

==== 11.8 回归检查按用户路径组织

每次发布后至少走一遍：

+ 从商店安装；
+ 打开新标签页；
+ 在弹窗中启用 Lucuro 新标签页接管；
+ 自定义一言与外观；
+ 写入今日手记；
+ 在设置中明确选择浏览器书签或本地 JSON 数据源；
+ 在弹窗中禁用 Lucuro 新标签页接管；
+ 重新开启并确认数据完整；
+ 检查 `stats.html` 中的体积变化。

==== 11.9 后续维护者应保留的能力

- 纯前端核心。
- 最小权限面。
- 防抖存储写入。
- 内置书签权限，浏览器书签仅在用户明确选择后导入。
- 本地数据与浏览器原生同步的清晰边界。

=== 12. 按真实故障场景组织的排错章节

==== 12.1 新标签页打开空白

检查：

- `chrome_url_overrides.newtab` 指向 `index.html`。
- `dist/index.html` 存在于已加载包。
- `newTabEnabled` 不是 `false`。
- manifest 修改后扩展已重新加载。
- 没有其他扩展抢占新标签页。

==== 12.2 弹窗无法启用或禁用新标签页接管

检查：

- 弹窗能读取并保存 `lucuro_settings_v1`。
- “启用 Lucuro”与“禁用 Lucuro”两个状态都能显示。
- 保存成功后弹窗正常关闭。
- 弹窗与新标签页使用相同存储键。

==== 12.3 设置或网址不持久化

检查：

- 浏览器扩展存储可用。
- `chrome.storage.sync` 未超出配额。
- 本地回退路径未被拦截。
- 页面关闭前防抖保存已经完成。

==== 12.4 原生同步没有更新另一台设备

检查：

- 两台设备使用同一浏览器账号。
- 扩展存储同步已开启。
- 载荷未超过同步配额。
- 用户已经等待浏览器原生同步完成。

==== 12.5 浏览器书签未在明确选择后导入

检查：

- manifest 已包含 `bookmarks` 权限，扩展已重新加载。
- `chrome.bookmarks.getTree()` 可用。
- 设置中的数据源是“浏览器书签”，而不是“本地 JSON”。
- 用户已在设置中明确选择“浏览器书签”数据源。
- 扩展不会在首次安装或未选择数据源时自动读取书签。
- 浏览器没有阻止 `bookmarks` API。

==== 12.6 拖拽排序误改卡片

检查：

- 设置中已开启布局锁定。
- 锁定状态已持久化。
- SortableJS 初始化尊重锁定标志。

==== 12.7 包体积意外变大

检查：

- 重新运行 `npm run build` 后的 `stats.html`。
- 大型依赖的使用方式。
- 重复导入。
- 意外包含的 source map。
- 未使用的 locale 或资源。

==== 12.8 浏览器商店拒绝包

检查：

- ZIP 只包含 `dist/` 文件。
- `manifest.json` 是合法 JSON。
- 图标尺寸齐全且有效。
- 没有远程代码。
- 权限与隐私政策一致。
- CSP 不允许无关域名。
- `host_permissions` 仅包含 Formspree 反馈表单域名。

==== 12.9 Ko-fi 或微信收款码不生效

检查：

- `public/qrcode-wechat.png` 在构建包中存在。
- Ko-fi URL 为 `https://ko-fi.com/helloxiaolaodi`。
- 弹窗或设置面板使用可信的 `window.open` 流程。
- 不依赖第三方支付 SDK。

=== 13. 安全强化与隐私保护

==== 13.1 本地存储边界

用户数据保存在扩展存储中。不把笔记、Token 或私有配置镜像到服务器。

==== 13.2 最小权限

只使用：

- `storage`
- `unlimitedStorage`
- `activeTab`
- 可选的 `bookmarks`
- `https://formspree.io/*`（仅用于反馈表单）

不要添加 `<all_urls>` 或无关权限。

==== 13.3 host 权限仅限反馈表单

扩展只声明 `https://formspree.io/*` 作为 `host_permissions`。浏览器书签只在用户明确选择后导入，原生同步和本地存储都不需要远程主机。

==== 13.4 CSP

保持 Manifest V3 CSP 严格：

- 只允许本地脚本。
- 禁止远程代码执行。
- 不依赖外部 `connect-src` 地址。

==== 13.5 商店审核就绪

- 发布隐私政策。
- 说明原生同步、明确选择后的浏览器书签导入与 Formspree 反馈表单。
- 避免隐藏权限。
- 包中不包含密钥和开发路径。

=== 14. 结论

Lucuro - 鹿客司南 是一个包含新标签页、弹窗、本地存储、浏览器原生同步、浏览器书签仅在用户明确选择后导入与商店级构建产物的浏览器扩展。对维护者而言，最值得守住的是边界：数据默认留在本地，权限保持最小；构建可复现；每次发布都走真实用户路径验证。

仓库价值不体现在某个组件上，而体现在核心本地优先能力、轻量体积、清晰权限和可信任的商店提交流程上。守住这些边界后，后续修改主题、网址、同步或支持渠道时，都只是配置层或功能层工作，而不是架构重写。

\<div style="text-align: center; margin: 2em 0;"\>
\<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 10" width="200" height="10"\>
\<rect x="0" y="0" width="200" height="10" rx="5" fill="currentColor" opacity="0.1"/\>
\</svg\>
\</div\>
