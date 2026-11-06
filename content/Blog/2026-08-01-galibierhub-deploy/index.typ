#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *
#import "@preview/theorion:0.6.0": quote-block

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "GalibierHub 网站部署详细解读",
  description: "系统解读 GalibierHub 科研数据库模板的架构原理、部署流程、代码组织与故障排查。",
  date: datetime(year: 2026, month: 8, day: 1),
  lang: "zh",
)

= GalibierHub 网站部署详细解读

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
- 13. 安全强化与反爬虫防御
- 14. 结论

== I. 项目概述与架构原理


=== 1. 项目定位

GalibierHub 是一个面向科研数据库工作流的 Next.js 模板工程。当前版本围绕 `Overview`、`Records`、`Genome Browser`、`Downloads`、`Discussion`、`World Clock`、`/settings/preferences`、`/user/[username]` 以及管理员端 `Admin` / `Badges` 等工作台组织。它不是营销页，也不是单纯的静态展示模板，而是一套偏研究工作台形态的网站骨架。

这个项目的核心设计思路可以概括为四点：

- 页面外壳尽量交给边缘网络和静态资源分发，以保证首屏稳定可达。
- 结构化元数据进入 Supabase / PostgreSQL，便于查询、筛选、排序和统计。
- 大文件留在 Hugging Face、Cloudflare R2 或其他对象存储，通过公开 URL 或签名 URL 读取。
- 浏览器只按需加载真正需要的记录和区间，避免把所有数据都塞进前端。

==== 1.1 名字的由来：Col du Galibier

GalibierHub 的名字源自*加利比耶山口 (Col du Galibier)*，法国阿尔卑斯山脉中海拔 2,642 米的传奇山口。过去一个世纪中，这个被列为 HC 级（"不可分级"）的魔鬼赛段始终是环法自行车赛中对人类极限的终极考验——稀薄的空气和残酷的坡度将顶级运动员推向崩溃的边缘。

*为什么是 Galibier？*

- *稀薄空气 → 高通量算力*：在海拔两千六百米的高山，空气极度稀薄，哪怕最顶级的运动员也会遭遇引擎"爆缸"的危险。这正如处理数万份口腔与肠道微生物样本时所面临的算力高压——庞大的特征矩阵和内存消耗正是系统面临的"稀薄空气"。Galibier 代表着本平台在应对极大规模队列分析和高通量数据分发时，极其强悍的性能底盘与抗压能力。
- *爬坡手 → 科研探索者*：科研本身就是一场孤独且极具消耗的"爬坡"。从极其原始粗糙的下机序列，到最终精细如艺术品的系统发育树与热图，中间是无数次的数据清洗、除噪与模型迭代。Galibier 致敬那些在枯燥的数据流中默默承受"死死咬住轮流拉扯"、最终在山顶迎来突破的学术攀登者。
- *Hub → 探索者的大本营*：后缀 Hub（枢纽）意味着科学不该是一场孤军奋战。正如加利比耶山顶为所有完赛者设立的丰碑，GalibierHub 被设计为一个高度互联的基础设施——不仅沉淀了标准化的代码管道与高质量的参考数据集，更为全球的生信开发者提供了一个下载、交流与协同突围的集散中心。

#quote-block[
*口号 / Slogan*："征服微生态数据的海拔极高点。" ( _Conquering the High Altitude of Microbiome Data._ )
]

这也是 GalibierHub 能在较轻部署模型下保持可用的关键原因。Vercel 主站负责 Next.js 的标准构建与交付，Cloudflare 可作为镜像或代理补充；Discussion、下载弹窗、JBrowse 和批量下载则在这个基础上逐层叠加。换句话说，GalibierHub 当前已经不是一个只演示界面布局的模板仓库，而是一套可以被继续部署、替换数据并长期维护的研究数据库底盘。

对 fork 维护者而言，还有几件值得尽早意识到的事情。第一，GalibierHub 的每一层都是可以在不重写整体的前提下独立替换的。如果你只需要换物种数据，不需要改架构；如果你只需要改下载策略，也不需要改数据库结构。这种独立性不是偶然设计出来的，而是因为数据边界、权限边界和交付边界从一开始就被有意识地分开了。第二，GalibierHub 当前覆盖的交互深度——从浏览、筛选、讨论到命令行级批量拉取——在同类模板中并不常见。这意味着接手者不仅要关注页面能不能正常渲染，还要确保每一条完整用户路径（包括 CLI、manifest 和校验导出）都能走通。第三，这个仓库的维护价值不在于某个组件的实现有多精巧，而在于配置入口、数据流向和验证路径是否一直保持明确。只要边界还在，换数据、换物种、换部署平台都只是配置层的工作；一旦边界被模糊，再小的改动都可能引发连锁回归。



=== 2. 术语说明

- `Administrator` 指当前界面文案、部署说明和 moderation 流程中的网站管理员。
- GitHub 登录名、外部数据集路径、仓库 URL 和署名等对外标识应保持真实值，不要替换成泛化称呼。
- 面向用户和维护者的当前文案应统一使用 `discussion` 作为标准术语。

- *Discussion*：当前站点的站内交流功能标准术语。界面、API 路由、数据库表、文档和代码注释中应统一使用 discussion，而不是 	hread、	opic 或 post。这种统一不仅是为了用语一致，更是为了后续维护时能全局搜索到同一个关键词，而不需要在多个变体之间来回切换。
- *Administrator*：指当前界面文案、部署说明和 moderation 流程中的网站管理员。管理员身份通过 GitHub 登录名识别，而不是前端徽标或本地开关。
- *Featured download*：指在 site-config.ts 中配置的、直接出现在 Overview 页面或下载目录顶部的精选下载项。它和样本级下载（sample-linked download）是两种不同的来源，合并后才是完整目录。
- *Sample-linked download*：指从 genome\_samples 表中动态读取的、按样本关联的文件入口。它的可见性可以被 download\_metadata 中的隐藏状态叠加控制。
- *Resolve URL / Raw URL*：指 Hugging Face 或其他托管源上直接指向原始文件的地址（通常是 
esolve/main/ 形式），与 blob/main/ 形式的页面浏览地址相对。GalibierHub 的大文件下载和 JBrowse 引用都依赖 resolve URL，而不是页面地址。
- *Service role*：指 Supabase 的 service\_role 密钥对应的身份，它绕过 RLS 策略直接操作数据库。当前只有管理员回复更新、访客去重写入等少数操作需要此身份。环境变量中必须同时配置 SUPABASE\_SERVICE\_ROLE\_KEY 和 NEXT\_PUBLIC\_SUPABASE\_ANON\_KEY，前者仅在服务端 API 路由中使用，后者在浏览器端暴露。
- *Manifest*：指从下载目录导出的结构化清单（CSV），包含 Directory\_Path、File\_Name、File\_Type、Size\_Bytes、Direct\_URL 和 SHA-256 六个字段。它的设计目标不是给人阅读，而是让下游流水线直接消费。
- *RLS (Row-Level Security)*：指 Supabase / PostgreSQL 的行级安全策略。当前站点依赖 RLS 来区分匿名用户可读、可插入、管理员可更新或删除的边界。任何 schema.sql 修改都应同步检查相关 RLS 策略是否仍然匹配。
- *GitHub 登录名、外部数据集路径、仓库 URL 和署名等对外标识应保持真实值*，不要替换成泛化称呼。这既是为了文档可验证性，也是为了让搜索、索引和引用能直接定位到正确的资源。



=== 3. 架构概览

==== 3.1 前端工作台

- `src/app/page.tsx` 负责主工作台和各主要界面的切换。
- `src/components` 下的组件负责筛选表单、记录表格、详情浮层、嵌入式基因组浏览器、下载弹窗、Discussion 面板和使用指南。
- `src/site-config.ts` 是站点级配置中心，控制站点标题、Overview 文案、下载卡片、Discussion 描述、浏览器默认区间和联系信息等内容。

从使用体验看，当前站点已经不是“一个页面堆四个区块”的阶段，而是明确区分了四条用户路径：看摘要、查记录、做讨论、取文件。后续维护时也应尽量保留这种职责分层，而不是把所有功能重新塞回首页。研究型站点最怕的是功能不断增加，但入口不断混乱；GalibierHub 当前的结构正好相反，功能增加的同时把角色边界也做得更清楚了。

==== 3.2 无服务器接口层

- `src/app/api/*` 提供统计、记录查询、样本查询、变异查询、Discussion、下载目录、下载解析、批量下载和图片上传等接口。
- 站点默认不依赖独立的长驻后端服务，Next.js Route Handlers 承担轻网关角色。
- 这些接口的职责是验证前端参数、补齐默认值、连接 Supabase 或对象存储，并把结果转换成前端稳定可消费的格式。

这类轻后端模式非常适合 GalibierHub，因为当前业务更多是读多写少的数据库查询、公开文件分发和少量管理员操作，而不是高事务复杂度的业务系统。研究数据库不一定需要重后端，但一定需要把参数边界、回退路径和数据出口组织清楚。GalibierHub 目前正是沿这个思路实现的。

==== 3.3 数据与文件层

- `genome_samples`、`predicted_promoters`、`variant_index` 等结构化信息保存在 Supabase / PostgreSQL。
- 参考序列、注释文件、打包归档和大体积下载文件通常保存在 Hugging Face Datasets、Cloudflare R2 或其他对象存储中。
- 下载相关元数据、Discussion 记录、回复、互动状态和访客统计也在数据库中管理，以保证站点能显示统一的统计和操作界面。

这里最重要的工程判断是把元数据与大文件分开处理。元数据适合数据库，大文件适合直接 URL、Range 请求和对象存储。强行让二者走同一条数据通路，后面几乎一定会在性能、成本或可维护性上出问题。

==== 3.4 浏览器与记录联动

- `Records` 页面负责把筛选条件转换成数据库查询。
- 用户点击一条记录后，页面会同步详情浮层和 JBrowse 目标区间。
- JBrowse 参考文件优先走外部代理，其次是内置 `/api/hf-proxy` 回退，最后才尝试直接访问公开 URL。

这意味着表格不只是一个静态列表，而是浏览器定位入口。记录页的价值不在于把行展示出来，而在于让用户可以直接从行跳到具体坐标上下文。表格如果不能把用户带到空间上下文，它只是信息堆积；一旦能和浏览器联动，它才成为研究工作流的一部分。

==== 3.5 为什么是这种架构

研究型数据库最怕“样样都做一点，但没有一层做稳”。GalibierHub 当前的架构取舍比较明确：

- 先保证页面可以到达，再保证数据可以逐步加载。
- 先保证数据库查询边界清晰，再扩展下载与互动能力。
- 先让大文件通过公共存储或签名路径稳定交付，再谈更复杂的缓存和调度。

对准备 fork 这个仓库的人来说，理解这种取舍比记住某一个组件的具体实现细节更重要。因为后续不管是替换物种、调整字段、扩展下载策略还是接入新的数据源，本质上都要沿着这些边界进行，而不是重新发明一套完全不同的站点结构。



=== 4. 数据模型与运行逻辑

==== 4.1 核心表

- `genome_samples`：样本元数据、样本级下载入口和部分展示信息。
- `predicted_promoters`：核心记录表，支撑 `Records` 页面。
- `variant_index`：变异索引与相关查询。
- `site_feedback`：Discussion 顶层条目。
- `feedback_comments`：discussion 回复。
- `site_reactions`：点赞、收藏等互动状态。
- `download_metadata`：下载文件的显示名称、描述、校验码、隐藏状态、访问模式和签名下载配置。
- `download_events`：下载计数与事件记录。

这些表共同组成了两个相互配合的子系统：一套是科研数据检索与展示子系统，另一套是站内互动与下载治理子系统。前者决定网站有没有数据工作台的基本能力，后者决定网站能不能从“只读展示”走到“可协作、可运维”的阶段。

从维护角度看，还可以进一步把这些表按“变化节奏”分类。`genome_samples`、`predicted_promoters` 和 `variant_index` 往往是批量导入、读多写少的表。`site_feedback`、`feedback_comments`、`site_reactions` 和 `download_events` 则是持续小规模变化的表。`download_metadata` 处在中间，更像管理员维护的控制表。理解这种差异，有助于后续安排迁移、回填和验证的重点。

==== 4.2 Overview 运行逻辑

`Overview` 主要读取 `/api/stats` 返回的统计结果，并展示 StatsChart 仪表盘（物种分布饼图）和四张 FlipCard 导航卡片（检索发现、基因组浏览器、文件分发、社区讨论）作为主要功能入口。它承担的是“快速判断这个站点是否加载正常”和“让用户先看到数据规模轮廓”的职责，而不是展开所有数据操作。

Overview 不应该变成一切功能的堆放区，而应该是研究用户进入站点后的第一层定向信息。也就是说，它的价值在于快速建立数据规模、分布和可下载资源的轮廓，而不是替代 Records 或 Downloads 页面本身。

对维护者而言，`Overview` 还是一个很好的早期预警面。如果摘要卡片为空、数值明显不对，问题通常不在图表组件本身，而在 `/api/stats`、schema 结构或部署指向了空项目。也正因为如此，Overview 保持紧凑反而更有利，它既是用户的第一屏，也是维护者的第一层健康检查。

==== 4.3 Records 运行逻辑

当前记录页的逻辑并不是一次简单 SQL。用户填写的一部分筛选条件会先命中 `genome_samples`，得到一组 `sample_id`；随后这组结果再用于限制 `predicted_promoters` 的查询范围。这样可以同时支持样本元数据筛选和记录级字段筛选。

这也是为什么需要先理解两跳查询，再去改筛选表单。如果直接在前端增加字段，却没有理解它应该落在哪一跳上，就很容易把查询逻辑改乱。对于后续要扩充物种、样本属性或实验条件字段的人来说，这一条尤其关键。

新增筛选条件时，最安全的做法通常都一样：先判断字段属于 `genome_samples` 还是 `predicted_promoters`，再更新 route 参数解析和类型定义，确认 SQL 仍然落在正确的一跳上，最后再把这个输入暴露给 UI。如果跳过中间这些推理，直接先改表单，最容易出现的就是“界面看起来正常，但结果永远为空”的静默故障。

==== 4.4 Discussion 运行逻辑

Discussion 已从单页内嵌标签升级为独立页面体系：

- /discussions 列表页：展示作者头像、分类标签、正文预览、回复数和活跃时间
- /discussions/[id] 独立详情页：带悬浮时间轴侧边栏、回复间隔线、点赞/分享按钮、底部数据摘要和注册引导
- 站内通知铃铛：GitHub 登录用户实时收到回复提醒
- 公共 discussion 列表读取、新留言提交、互动状态更新、管理员回复与 discussion 状态管理

- 公共 discussion 列表读取
- 新留言提交
- 互动状态更新
- 管理员回复与 discussion 状态管理

当前编辑器采用 Markdown 输入框、可视化工具栏以及 `Write` / `Preview` 双标签页，既适合熟悉 Markdown 的用户快速输入，也适合新用户通过点击按钮完成格式化。管理员在 GitHub 登录后可以对 discussion 执行置顶、取消置顶、隐藏、显示、删除等操作，也可以对单条回复执行隐藏、显示和删除。管理员回复能力同时依赖前端显示权限和后端身份校验。也就是说，只改前端文字或按钮状态是不够的，后端 `/api/feedback` 与管理员登录判断必须保持一致。更进一步说，Discussion 不是一个“附加小功能”，而是站点对外沟通和收集反馈的正式入口，因此它的权限、图片上传和状态字段都应被当成正式业务流来维护。

`In Progress` 和 `Completed` 的划分也不只是视觉分组。按当前逻辑，它反映的是是否已经存在正式的管理员回复。因此，后续任何涉及回复结构、隐藏状态默认值或分页逻辑的调整，都应把“列表归属是否仍然一致”当成派生状态来验证。一旦这个关系断掉，moderation 看起来就会变得很混乱，即便数据库写入本身其实成功了。

2026-07-31 修订后，Discussion 已经成为实时协作界面：每条单独回复的点赞只显示数值，红心图标已移除，浏览量读取服务端真实数值，头像悬浮卡片展示在线状态并支持关注/取消关注，时间线滑条可按住拖动滚动整篇讨论并保持与浏览器滚动同步，同时显示主帖与每条回复的发布日期。分类筛选改为 `All Categories` / `Issue` / `Tutorials`，Tutorials 仅管理员可发布，富文本 ordered-list 按钮会依次插入 `1.`、`2.`、`3.`，徽章触发在数据库层完成，奖励与通知无需依赖前端权限判断。

由于 Discussion 现在更像一个轻量 issue tracker，而不只是访客留言板，所以建议用接近业务流的标准去测试它。也就是说，不要只测“能不能发出来”，还要测可见性规则、回复管理、图片链接和 mutation 后的列表刷新是否保持一致。

==== 4.5 Downloads 运行逻辑

`Downloads` 页面提供的是目录级浏览，而不是单个文件列表的平铺复制。其运行逻辑通常分为三段：

+ `download-catalog` 返回按目录层级组织的结构。
+ 用户打开具体文件后，前端读取 `download_metadata`。
+ `/api/download-metadata/resolve` 将该文件解析为公开 URL 或短时签名 URL。

当前页面已经补齐标准面包屑导航、紧凑控制栏、网格/表格双视图、可排序表格列、目录级 CLI 复制、Manifest CSV 导出、分页显示、批量选择下载以及 README 按钮。Manifest 导出字段固定为 `Directory_Path`、`File_Name`、`File_Type`、`Size_Bytes`、`Direct_URL`、`SHA-256`，便于下游脚本直接消费。批量下载功能只为公开文件生成 `.sh` 与 `.bat` 脚本。对于依赖短时签名 URL 的私有文件，当前设计不会把它们直接写进可复用脚本里，因为那样会破坏访问控制边界。

这也意味着后续排查下载问题时，最好先问清楚问题发生在目录发现、元数据补全，还是最终 URL 解析这三个阶段中的哪一段。它们是三个不同的运行阶段，也对应三组不同的职责边界。界面完全可能把文件展示对了，但 resolve 路由仍然解析到了错误的原始文件；这种问题的修复点和用户看到的症状并不在同一层。

最新 Downloads 构建还从目录元数据解析 SHA-256，CSV manifest 导出和 CLI/checksum 弹窗都不再显示 `NA` 或 `N/A`；一个统一的 `Tutorials` 菜单提供 `View all Tutorials` 与 `Download & CLI Usage Guide`，其中下载指南位于独立 `/docs/download-cli` 页面。

当前 `Downloads > Records` 是文件夹列表中的第一个目录，用于集中展示 Records 界面的全部文件，并在内部按 `Reference_Genomes`、`Variant_Calling_VCF`、`ML_Ready_FASTA` 三个子目录组织：`Reference_Genomes` 存放参考 FASTA 与 GFF3，`Variant_Calling_VCF` 存放 12 个样本 VCF，`ML_Ready_FASTA` 存放 12 个样本 FASTA。这个目录与 Downloads 中其他文件夹完全一致，支持浏览、排序、选择、manifest 导出、`Download to Browser`、CLI 和 Cluster Batch Download。

Records 到 Downloads 的跨页面选择也已完成：单条记录的 `Download` 下拉按钮可选择 VCF 或 FASTA，选中多行后的批量按钮会写入 `sessionStorage`，再切换到 Downloads；`download-catalog-panel.tsx` 读取待选文件列表后自动展开对应子目录、勾选文件、高亮目标行并滚动到可见位置。

==== 4.6 JBrowse 与页面联动

记录列表、详情浮层和 JBrowse 的联动是当前站点最重要的研究型交互之一。点击记录时，页面会：

- 设置当前选中记录
- 计算目标区间及其上下游 padding
- 同步更新浏览器定位
- 让详情面板与页面上下文保持一致

如果参考序列路径不通、索引丢失或代理不可达，最先暴露问题的通常就是这条联动链，而不是纯文本界面。换句话说，JBrowse 是站点技术可信度的最终验证层：只看表格和统计卡片，很多问题都还藏着；一旦联动浏览器，路径、索引、跨域和对象存储的真实状态就会全部暴露出来。

这也是为什么 fork 时最好把 assembly 标识、参考文件名和默认 locus 一起改，而不是一次只改一个变量。浏览器即使指向了错误 assembly，也可能看上去“能打开”，但后续每一次 locus 跳转都会变得有误导性。对科研站点来说，一个看似正常但坐标错位的浏览器，往往比直接报错更危险。

==== 4.7 下载与访问控制的真实边界

如果底层文件仍然放在公开可读的 Hugging Face 数据集仓库中，那么站内的“隐藏文件”和“下载密码”更多只是 UI 层面的约束，而不是真正的文件级访问控制。

只有当 `download_metadata.storage_provider = 'supabase_private'`，并由后端签发短时有效的 Supabase signed URL 时，这些控制才构成真正的受限访问路径。

因此，维护者要明确区分两种模式：

- 公开文件模式：更适合公开数据集、断点续传和镜像分发。
- 私有签名模式：更适合真正需要访问控制的文件。

如果忽略这个边界，就会在文档和界面中制造一种“已经私有保护”的错觉，实际上底层文件仍然可能被公开直链访问。对科研资源站而言，这类边界判断必须写清楚，否则后续维护者很容易在错误假设上继续开发。

因此在维护说明里最好把这件事写得非常直白。对公开文件做隐藏，只是展示策略；对私有文件签发短时链接，才是访问控制策略。两者都可以存在，但不能混成同一个概念，否则后来的人很容易误判安全边界。


== II. 完整部署指南


=== 5. 克隆后优先检查的文件

+ `src/site-config.ts`
站点标题、Overview 文案、Discussion 说明、下载卡片、联系信息、浏览器默认配置和部分功能开关都从这里读取。对 fork 用户来说，这通常是最先修改、也最应该集中维护的文件。

+ `.env.local.example`
这是部署所需环境变量模板。任何新环境上线前，都应先核对这里的变量是否与当前代码保持一致。很多“代码没问题但站点打不开”的情况，本质上都是变量模板和真实部署环境脱节。

+ `schema.sql`
数据库表、下载元数据、Discussion 表、互动表和存储 bucket 相关设置都在这里定义。它直接决定 Supabase 是否能支撑当前站点功能。

+ `README.md` 与 `README.zh-CN.md`
这两份是仓库内的快速部署说明，适合用来核对最小部署路径是否仍然正确。它们负责“先让站点跑起来”，而本文负责“让你理解跑起来之后怎么维护”。

+ `src/app/api`
如果你要替换数据源、修改权限、改变下载逻辑、调整记录查询行为，通常先看 API 路由，而不是先改组件。因为绝大多数行为变化最终都要落在网关层完成。

+ `src/components/site-feedback.tsx`、`download-actions.tsx`、`download-catalog-panel.tsx`

这六个入口并不要求从头到尾顺序读完，但它们共同构成了一个快速接手的最小认知闭环：配置入口 -\> 数据边界 -\> 行为网关 -\> 交互表面。只要这四个层面都走通了，fork 后续的大部分定制工作就可以安全地展开，而不需要先通读整个仓库。反过来，如果跳过这个闭环直接改组件，最常见的后果就是改了 UI 但行为没跟上，或者改了路由但配置没有同步。

还有一个容易被忽略的检查点：克隆之后、修改之前，建议先完整跑一次本地开发服务器，确认各主要界面至少在默认数据下都能正常渲染。这个步骤听起来多余，但它是后面所有定制工作的锚点。如果默认状态就跑不通，后续任何问题都很难判断是新改动引入的还是原本就没跑通。
Discussion 和下载体验的大部分交互行为集中在这几个组件里，也是最容易被二次开发影响的区域。管理员回复、下载可见性、批量脚本生成和按钮状态都和这里直接相关。



=== 6. 部署前准备

==== 6.1 账号与基础依赖

完成一套可用部署，至少需要以下资源：

- Node.js 20 或更高版本
- npm
- 一个 Supabase 项目
- 一个 GitHub OAuth 应用，或通过 Supabase 配置 GitHub 登录
- 一个用于公开参考文件和发布归档的存储位置，推荐 Hugging Face Datasets 或 Cloudflare R2
- 如需邮件提醒，可选配一个 Resend 账号

如果只追求最小可用版本，Supabase + Vercel + Hugging Face 三者已经足够让主站跑起来。真正需要额外补的是登录回复、图片上传和邮件通知这类协作能力，而不是再先引入一套更重的后端。

对新的维护者来说，更稳妥的接手顺序通常是：先让页面成功连接到一个真实的 Supabase 项目，再让 `Overview` 和 `Records` 基于一小批真实数据跑通，最后再去打开 Discussion moderation、图片上传和更复杂的下载能力。很多人正好反过来，一开始就先打磨按钮和权限入口，结果底层数据边界还没稳住，后面就很容易反复返工。

还可以把这些前置条件拆成三层来理解。第一层是“站点能用起来”所必需的内容：Node.js、npm、Supabase 和公开匿名访问配置。第二层是“站点看起来像 GalibierHub 而不是空壳”所必需的内容：参考文件、样本数据和浏览器可读的文件路径。第三层才是协作增强项：GitHub 登录、回复通知、图片上传和私有下载治理。按这三层去交接，会比把所有依赖混成一团更清楚。

==== 6.2 Supabase 初始化

+ 在 Supabase SQL Editor 中执行 `schema.sql`。
+ 确认核心表已经创建，包括 `genome_samples`、`predicted_promoters`、`variant_index`、`site_feedback`、`feedback_comments`、`site_reactions`、`download_metadata` 和 `download_events`。
+ 检查 `feedback-images` bucket 是否存在，且为 public。
+ 如果图片上传策略没有自动创建成功，可单独在 SQL Editor 中重建 bucket 与 policy。

当前站点的一个常见误区是：数据库表建好了，但存储 bucket 权限没配对，结果 Discussion 文本能提交，图片却无法上传。因此数据库和存储必须一起验证，而不是只看 SQL 是否执行成功。

另一个很常见的问题是环境混用。维护者可能把 `schema.sql` 执行在了一个 Supabase 项目里，把 bucket 建在了第二个项目里，最后又让 Vercel 指向了第三个旧项目。页面在这种漂移状态下仍然可能打开，但写入行为会变得很难解释。比较稳妥的做法是在导入任何真实数据之前，就先记清楚本地开发、Vercel 和镜像部署各自使用的 Supabase 项目引用。

在真正导入大量数据之前，最好先准备一小批但具有代表性的种子数据。几条 `genome_samples`、几条关联的 `predicted_promoters`、一两条 `download_metadata` 记录，再加一条 Discussion 留言，就足够证明主要路径是否接通。这种小规模种子数据往往比一次性导入一大堆表更有诊断价值，因为你可以更清楚地看出每一条路径到底通没通。

==== 6.3 GitHub OAuth 与管理员身份

Discussion 页面中的管理员回复能力依赖 GitHub 登录，而不是旧式的共享口令。

推荐配置步骤如下：

+ 在 Supabase Dashboard 的 `Authentication -> Sign In / Providers` 中启用 GitHub。
+ 在 GitHub `Developer settings -> OAuth Apps` 中创建 OAuth App。
+ 将 GitHub 提供的 Client ID 和 Client Secret 填回 Supabase。
+ 在 Supabase `Authentication -> URL Configuration` 中填写生产域名与本地域名。
+ 在环境变量中同时配置：
   - `GITHUB_ADMIN_USERNAME`
   - `NEXT_PUBLIC_GITHUB_ADMIN_USERNAME`

这两个变量都应填写 GitHub 登录名，而不是展示昵称。前端会据此决定哪些管理员控件应该显示，后端也会据此校验回复权限。对二次开发者而言，最需要记住的是：管理员能力同时依赖前端显示逻辑与后端身份校验，只改其中一边一定会留下问题。

在配置时，最好把回调矩阵显式记下来。实际维护中通常至少要支持本地开发和生产环境两个入口。如果本地回调没问题、生产回调却失效，表面看上去往往像是 Discussion 的 UI 问题，但真实原因其实是 redirect 配置不一致。把每个环境的站点 URL、redirect URL 和 Supabase callback 明确写下来，会比事后靠记忆排查高效很多。

同时还要注意，GitHub 会暴露多种看起来都像“用户名”的字段。GalibierHub 的管理员边界应持续绑定到稳定的 login name，而不是 profile 展示名。这个区别看起来很小，但一旦维护者修改了公开资料里的显示名称，就很容易误以为管理员识别逻辑突然坏掉了。

==== 6.4 邮件通知与 Resend

如果希望管理员回复后向留言者发送邮件通知，可以配置 Resend：

- 测试模式下可直接使用 `onboarding@resend.dev` 发件，不要求自有域名。
- 生产模式下建议接入自己的域名，并配置 SPF / DKIM / Return-path。

最常用的变量如下：

```bash
FEEDBACK_EMAIL_API_URL=https://api.resend.com/emails
FEEDBACK_EMAIL_API_KEY=re_xxxxxxxxxxxx
FEEDBACK_EMAIL_TO=owner@example.org
```

这部分不是站点可运行的硬前提，但如果你打算把 Discussion 当作真实协作入口，邮件通知会显著提高回复闭环的完成度。留言功能不是“能提交就算完成”，而是能否让管理员及时看到、及时回复并形成可追踪记录。

==== 6.5 参考文件与下载文件准备

JBrowse 至少需要以下参考文件：

- `*.fa` / `*.fasta`
- `*.fa.fai`
- `*.bed`
- `*.gff3`

如果你切换到新的物种或新的装配版本，除了替换文件本身，还需要同步检查：

- `NEXT_PUBLIC_REFERENCE_ASSEMBLY`
- `NEXT_PUBLIC_REFERENCE_DEFAULT_LOCUS`
- `NEXT_PUBLIC_REFERENCE_FASTA`
- `NEXT_PUBLIC_REFERENCE_FASTA_INDEX`
- `NEXT_PUBLIC_REFERENCE_BED`
- `NEXT_PUBLIC_REFERENCE_GFF3`

建议把这些文件放在一个结构清楚的公共目录下，并使用 `resolve/main` 风格的原始地址，而不是 Hugging Face 页面地址中的 `blob/main` 形式。能否稳定使用 Range 请求读取这些原始对象文件，是浏览器能否正常工作的基础前提。

对 fork 者而言，文件命名和目录组织最好保持朴素、直白。只要路径本身就能看出 `assembly`、`fasta`、`index`、`bed` 和 `gff3` 的关系，后面 manifest、checksum、代理路径和用户可复制的 CLI 命令都会更容易保持一致。相反，如果文件名全靠临时缩写或个人习惯堆出来，后面任何自动推导都会越来越脆弱。

如果你要替换新的 assembly，建议先把索引文件生成并验证成功，再去改前端配置。很多维护者是先改了 `NEXT_PUBLIC_REFERENCE_FASTA`，等 JBrowse 运行时报错后才发现配套的 `*.fai` 或注释文件其实还没有准备好。

==== 6.6 推荐环境变量

```bash
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

NEXT_PUBLIC_STORAGE_BASE_URL=https://huggingface.co/datasets/<user>/<repo>/resolve/main/<optional-subdir>
NEXT_PUBLIC_REFERENCE_ASSEMBLY=NC_045512.2
NEXT_PUBLIC_REFERENCE_DEFAULT_LOCUS=NC_045512.2:1-5000
NEXT_PUBLIC_REFERENCE_FASTA=Records/Reference_Genomes/reference.fasta
NEXT_PUBLIC_REFERENCE_FASTA_INDEX=Records/Reference_Genomes/reference.fasta.fai
NEXT_PUBLIC_REFERENCE_BED=Records/Reference_Genomes/reference.bed
NEXT_PUBLIC_REFERENCE_GFF3=Records/Reference_Genomes/annotation.gff3

NEXT_PUBLIC_HF_PROXY_URL=https://galibierhub-hf-proxy.your-account.workers.dev
NEXT_PUBLIC_RELEASE_ARCHIVE_URL=https://huggingface.co/datasets/<user>/<repo>/resolve/main/releases/galibierhub-release.tar.gz
NEXT_PUBLIC_RELEASE_ARCHIVE_MODE=cli

GITHUB_ADMIN_USERNAME=your-github-login
NEXT_PUBLIC_GITHUB_ADMIN_USERNAME=your-github-login
FEEDBACK_EMAIL_API_URL=https://api.resend.com/emails
FEEDBACK_EMAIL_API_KEY=re_xxxxxxxxxxxx
FEEDBACK_EMAIL_TO=owner@example.org
```

如果当前只想快速验证站点能跑起来，最小集合通常包括 Supabase 三项和 GitHub 管理员登录名两项。下载卡片和邮件通知可以后补，但参考文件路径必须尽早配对好。很多部署失败并不是功能复杂，而是基础变量没有在构建阶段注入到位。

可以把这些环境变量分成三类去管理。第一类是身份与数据边界变量，例如 Supabase URL、anon key 和 service role key。第二类是浏览器直接消费的公开内容变量，例如存储基地址和参考文件名。第三类才是流程增强项，例如邮件通知和发布归档相关变量。知道一个变量属于哪一类，往往就能更快判断它缺失时的优先级。

如果你同时维护本地开发、Vercel 和 Cloudflare，最好额外整理一份纯文本环境矩阵，记录三个环境分别有哪些值。GalibierHub 很容易因为某个平台少了一个 `NEXT_PUBLIC_*` 变量而表现出完全不同的故障形式，这种矩阵虽然简单，但能显著减少后续排错时的猜测。

==== 6.7 HF官方上传与验证

有一部分实操经验尤其适用于大文件：

- 上传时推荐使用 `hf upload`，它支持断点续传。

- 下载时推荐向用户同时提供浏览器下载、`wget -c`、`curl -L -C -` 和 `hf download`。

- 如果网络环境对 Xet 端点不稳定，可考虑临时设置 `HF_HUB_DISABLE_XET=1` 后再进行上传或下载。

- 对外暴露文件时应优先保存 `resolve/main/...` 直链，而不是页面浏览地址。

从零开始把 `Extracurricular-reading-materials` 文件夹上传到 `Helloxiaolaodi/seqedge-data` 的完整步骤如下，按操作系统分开。三种系统都遵循同一个流程：先检查 Python，再安装 `huggingface_hub[cli]`，登录 Hugging Face，执行 `hf upload`，最后下载验证。

===== Windows（PowerShell）

+ 检查 Python：

```powershell
python --version
```

如果提示找不到 `python`，先安装 Python，并勾选 `Add python.exe to PATH`，然后重开 PowerShell。

+ 安装 Hugging Face CLI：

```powershell
python -m pip install -U "huggingface_hub[cli]"
```

+ 验证 CLI：

```powershell
hf --version
```

如果 `hf` 找不到，关闭并重开 PowerShell；仍找不到时使用 `huggingface-cli --version`。

+ 登录并确认账号：

```powershell
hf auth login
hf auth whoami
```

按提示粘贴一个对该 dataset 有写权限的 token。`hf auth whoami` 应显示 `Helloxiaolaodi`。

+ 上传 `Extracurricular-reading-materials` 文件夹：

```powershell
hf upload Helloxiaolaodi/seqedge-data "D:\YL2026\html-deploy\deploy-notes\新建文件夹\hf-downloads-files-260801\Extracurricular-reading-materials" Extracurricular-reading-materials --repo-type dataset --commit-message "Upload Extracurricular-reading-materials"
```

这会把这个文件夹整体上传为 dataset 下的 `Extracurricular-reading-materials/` 子目录。当前文件夹包含 `Unbroken_ A World War II Story of Survival.mobi`、`Way of the Peaceful Warrior.pdf`、`三言二拍.pdf`。如果希望这 3 个文件（1 个 MOBI + 2 个 PDF）直接位于 dataset 根目录，把最后一个参数 `Extracurricular-reading-materials` 改成 `.`。

+ 验证：

```powershell
hf download Helloxiaolaodi/seqedge-data Extracurricular-reading-materials --repo-type dataset --local-dir .\hf-verify
```

===== macOS（Terminal）

+ 检查 Python：

```bash
python3 --version
```

+ 安装 CLI：

```bash
python3 -m pip install -U "huggingface_hub[cli]"
```

+ 验证并登录：

```bash
hf --version
hf auth login
hf auth whoami
```

+ 上传：

```bash
hf upload Helloxiaolaodi/seqedge-data ~/Desktop/hf-downloads-files-260801/Extracurricular-reading-materials Extracurricular-reading-materials --repo-type dataset --commit-message "Upload Extracurricular-reading-materials"
```

+ 验证：

```bash
hf download Helloxiaolaodi/seqedge-data Extracurricular-reading-materials --repo-type dataset --local-dir ./hf-verify
```

===== Linux（Bash）

+ 检查 Python：

```bash
python3 --version
```

+ 安装 CLI：

```bash
python3 -m pip install -U "huggingface_hub[cli]"
```

+ 验证并登录：

```bash
hf --version
hf auth login
hf auth whoami
```

+ 上传：

```bash
hf upload Helloxiaolaodi/seqedge-data /path/to/hf-downloads-files-260801/Extracurricular-reading-materials Extracurricular-reading-materials --repo-type dataset --commit-message "Upload Extracurricular-reading-materials"
```

+ 验证：

```bash
hf download Helloxiaolaodi/seqedge-data Extracurricular-reading-materials --repo-type dataset --local-dir ./hf-verify
```

==== 6.8 HF镜像与上传的正确用法

`hf-mirror.com` 适合加速下载，不适合作为上传端点。上传时如果设置 `HF_ENDPOINT=https://hf-mirror.com`，CLI 会向镜像站查询仓库，镜像站可能返回 `Dataset 'Helloxiaolaodi/seqedge-data' not found`，即使该仓库在 Hugging Face 官方站已经存在。

因此正确做法是：上传使用官方端点 `https://huggingface.co`，下载需要加速时再临时切换到 `https://hf-mirror.com`。

===== Windows PowerShell 正确组合

```powershell
# 1. 上传必须使用官方端点；不要使用 hf-mirror.com 上传
$env:HF_ENDPOINT = "https://huggingface.co"

# 2. 如果 Xet 传输假死，可临时禁用 Xet
$env:HF_HUB_DISABLE_XET = "1"

# 3. 不要设置已废弃的 HF_HUB_ENABLE_HF_TRANSFER
#    若想启用 Xet 高速传输，则不要禁用 Xet，并设置：
#    $env:HF_XET_HIGH_PERFORMANCE = "1"

# 4. 执行上传
hf upload Helloxiaolaodi/seqedge-data "D:\YL2026\html-deploy\deploy-notes\新建文件夹\hf-downloads-files-260801\Extracurricular-reading-materials" Extracurricular-reading-materials --repo-type dataset --commit-message "Upload Extracurricular-reading-materials"
```

下载时再切换到镜像：

```powershell
$env:HF_ENDPOINT = "https://hf-mirror.com"
hf download Helloxiaolaodi/seqedge-data Extracurricular-reading-materials --repo-type dataset --local-dir .\hf-verify
```

===== macOS / Linux 正确组合

上传：

```bash
export HF_ENDPOINT="https://huggingface.co"
export HF_HUB_DISABLE_XET=1

hf upload Helloxiaolaodi/seqedge-data \
  /path/to/hf-downloads-files-260801/Extracurricular-reading-materials \
  Extracurricular-reading-materials \
  --repo-type dataset \
  --commit-message "Upload Extracurricular-reading-materials"
```

下载时再切换到镜像：

```bash
export HF_ENDPOINT="https://hf-mirror.com"
hf download Helloxiaolaodi/seqedge-data Extracurricular-reading-materials --repo-type dataset --local-dir ./hf-verify
```

===== 上传单个文件

上传单个文件时，远端路径（第三个参数）必须明确写出文件名及其后缀，不能只写到文件夹级别：

```bash
hf upload Helloxiaolaodi/seqedge-data \
  /path/to/local_directory/your_file.fasta \
  Extracurricular-reading-materials/your_file.fasta \
  --repo-type dataset \
  --commit-message "Upload single file"
```
```bash
hf upload Helloxiaolaodi/seqedge-data "E:\ncu2025\NCU-tutorials-YL\NCU-tutorials-YL260902.zip" Learning-Resources/NCU-tutorials-YL260902.zip --repo-type dataset --commit-message "Upload single file"
```

===== 排查 `Dataset not found`

+ 先确认 `HF_ENDPOINT` 是 `https://huggingface.co`，不是 `https://hf-mirror.com`。

+ 用 `hf auth whoami` 确认当前登录账号是 `Helloxiaolaodi`，且 token 对该 dataset 有写权限。`hf auth login` 提示 `already logged in` 不是错误，不需要强制重新登录。

+ 确认命令带 `--repo-type dataset`，仓库 ID 是 `Helloxiaolaodi/seqedge-data`。

+ 如果仓库确实不存在，先创建：

```bash
hf repos create Helloxiaolaodi/seqedge-data --type dataset
```

+ 如果 `HF_ENDPOINT` 被持久化到了用户或系统环境变量，需要清除后再上传：

```powershell
[Environment]::SetEnvironmentVariable('HF_ENDPOINT', $null, 'User')
[Environment]::SetEnvironmentVariable('HF_ENDPOINT', $null, 'Machine')
```

==== 6.9 强制走NCU流量上传/下载HF

当前电脑有两张已连接网卡：

- `WLAN`：NCU，IPv4 `10.210.114.168`，网关 `10.210.255.254`
- `WLAN 2`：Yangsanduo 热点，IPv4 `10.78.171.124`，网关 `10.78.171.154`

HF 官方域名不一定总解析到 Cloudflare。当前 `huggingface.co` 和 `cdn-lfs.huggingface.co` 可能解析到 Facebook CDN 的 `199.59.149.x`、`108.160.x` 以及 IPv6 `2a03:2880::/32`，这些网段不在 NCU 的 Cloudflare 持久路由里。同时热点网卡的 IPv6 默认路由优先级更低（metric 61），所以 IPv6 流量会优先走 Yangsanduo 热点。这就是 800MB 上传消耗热点流量的原因。

推荐做法：上传/下载前临时禁用热点网卡，或把热点网卡 metric 调高，确保所有 HF 流量走 NCU。

===== 方案 A：临时禁用热点网卡（最可靠）

以管理员身份打开 PowerShell：

```powershell
# 1. 确认网卡名称
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object Name,InterfaceDescription,Status

# 2. 禁用 Yangsanduo 热点网卡
Disable-NetAdapter -Name 'WLAN 2' -Confirm:$false

# 3. 确认只剩 NCU
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object Name,InterfaceDescription,Status

# 4. 上传前设置 HF 环境变量
$env:HF_ENDPOINT = "https://huggingface.co"
$env:HF_HUB_DISABLE_XET = "1"

# 5. 上传
hf upload Helloxiaolaodi/seqedge-data "D:\YL2026\html-deploy\deploy-notes\新建文件夹\hf-downloads-files-260801\Extracurricular-reading-materials" Extracurricular-reading-materials --repo-type dataset --commit-message "Upload Extracurricular-reading-materials"

# 6. 下载验证
hf download Helloxiaolaodi/seqedge-data Extracurricular-reading-materials --repo-type dataset --local-dir .\hf-verify

# 7. 完成后恢复热点
Enable-NetAdapter -Name 'WLAN 2'
```

如果网卡名称不是 `WLAN 2`，以第 1 步查到的实际名称为准。

===== 方案 B：调高热点网卡 metric（不用断网）

以管理员身份打开 PowerShell：

```powershell
# 1. 让热点网卡的 IPv4 和 IPv6 路由优先级都低于 NCU
Set-NetIPInterface -InterfaceAlias 'WLAN 2' -AddressFamily IPv4 -InterfaceMetric 1000
Set-NetIPInterface -InterfaceAlias 'WLAN 2' -AddressFamily IPv6 -InterfaceMetric 1000

# 2. 确认 NCU 的默认路由 metric 更低
Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Sort-Object RouteMetric,InterfaceMetric | Format-Table InterfaceAlias,NextHop,RouteMetric,InterfaceMetric
Get-NetRoute -DestinationPrefix '::/0' | Sort-Object RouteMetric,InterfaceMetric | Format-Table InterfaceAlias,NextHop,RouteMetric,InterfaceMetric

# 3. 上传
$env:HF_ENDPOINT = "https://huggingface.co"
$env:HF_HUB_DISABLE_XET = "1"
hf upload Helloxiaolaodi/seqedge-data "D:\YL2026\html-deploy\deploy-notes\新建文件夹\hf-downloads-files-260801\Extracurricular-reading-materials" Extracurricular-reading-materials --repo-type dataset --commit-message "Upload Extracurricular-reading-materials"

# 4. 下载验证
hf download Helloxiaolaodi/seqedge-data Extracurricular-reading-materials --repo-type dataset --local-dir .\hf-verify

# 5. 完成后恢复自动 metric
Set-NetIPInterface -InterfaceAlias 'WLAN 2' -AddressFamily IPv4 -InterfaceMetric Auto
Set-NetIPInterface -InterfaceAlias 'WLAN 2' -AddressFamily IPv6 -InterfaceMetric Auto
```

===== 方案 C：强制 IPv4 并添加 HF CDN 路由（备选）

如果不想禁用热点，也不想改 metric，可以强制 HF 相关网段走 NCU 网关。此方案依赖当前 DNS 解析结果，HF 更换 CDN IP 后需要重新添加。

以管理员身份打开 PowerShell：

```powershell
# 1. 添加当前 HF 使用的 Facebook CDN IPv4 网段到 NCU
route add 199.59.148.0 mask 255.255.252.0 10.210.255.254 metric 1 if 5
route add 108.160.0.0 mask 255.248.0.0 10.210.255.254 metric 1 if 5

# 2. 添加当前 HF 使用的 Facebook CDN IPv6 网段到 NCU
netsh interface ipv6 add route 2a03:2880::/32 interface=5 nexthop=fe80::c607:78ff:fe08:2002

# 3. 上传
$env:HF_ENDPOINT = "https://huggingface.co"
$env:HF_HUB_DISABLE_XET = "1"
hf upload Helloxiaolaodi/seqedge-data "D:\YL2026\html-deploy\deploy-notes\新建文件夹\hf-downloads-files-260801\Extracurricular-reading-materials" Extracurricular-reading-materials --repo-type dataset --commit-message "Upload Extracurricular-reading-materials"

# 4. 下载验证
hf download Helloxiaolaodi/seqedge-data Extracurricular-reading-materials --repo-type dataset --local-dir .\hf-verify
```

===== 验证流量是否真的走 NCU

上传或下载过程中，另开一个 PowerShell 窗口执行：

```powershell
Get-NetTCPConnection -State Established | Where-Object { $_.RemoteAddress -match '^(199\.59\.|108\.160\.|104\.|172\.64|162\.158|108\.156\.)' } | Select-Object LocalAddress,RemoteAddress,OwningProcess | Format-Table -AutoSize
```

如果 `LocalAddress` 是 `10.210.114.168`，说明走 NCU；如果是 `10.78.171.124`，说明走 Yangsanduo 热点。

另外，上传/下载前应保持 Clash Verge 的 TUN 和系统代理关闭，或临时退出 Clash Verge，并确认没有设置代理环境变量：

```powershell
Remove-Item Env:HTTP_PROXY, Env:HTTPS_PROXY, Env:ALL_PROXY -ErrorAction SilentlyContinue
```



===== SLURM + Python


===== 常用 Hugging Face 环境变量一览：

#tablem[
  | 变量 | 作用 | 示例 |
  | :--- | :--- | :--- |
  | `HF_HUB_ENABLE_HF_TRANSFER` | 启用 hf\_transfer 加速上传/下载 | `1` |
  | `HF_HUB_DISABLE_XET` | 禁用 Xet 存储传输 | `1` |
  | `HF_ENDPOINT` | 使用镜像站点，亚太区推荐配置 | `https://hf-mirror.com` |
  | `HF_TOKEN` | 读写私有仓库时的认证令牌 | `hf_xxx...` |
  | `HF_HUB_DISABLE_PROGRESS_BAR` | 关闭进度条 | `1` |
  | `HF_HOME` | 自定义缓存和配置目录 | `D:\hf_cache` |
]



=== 7. 部署流程

==== 7.1 本地初始化

```bash
git clone <your-fork-or-repo-url>
cd GalibierHub
npm install
```

随后复制环境变量模板：

```bash
cp .env.local.example .env.local
```

如果是 Windows PowerShell 环境，可以直接手动复制一份 `.env.local`，关键是确保本地开发时使用的是独立变量文件，而不是直接改模板。

对一个全新的 fork 来说，先不要急着改品牌和文案。更快的路径通常是先保留默认站点标识，把真实数据边界接通，再验证默认导航能完整跑通。只有在这一步成立后，再去替换物种名称、项目介绍和精选下载，返工成本才会低得多。

==== 7.2 初始化 Supabase

+ 执行 `schema.sql`。
+ 导入最小测试数据，或至少保证关键表中有可查询记录。
+ 检查 `feedback-images` bucket。
+ 确认 `anon`、`service_role` 和项目 URL 已准备好。

在这一阶段最常见的问题不是 SQL 无法执行，而是表建好了但 bucket、policy 或 service role 权限没有配套，导致站点一半功能可用、一半功能失败。稳妥做法是把数据库和存储一起联调，而不是分开假设它们都已经正确。

如果可以，建议先导入一个很小但真实的切片，而不是一开始就导入全量数据。只要有一条记录能在 `Overview` 出现，一条记录能在 JBrowse 中定位，一个文件能在 Downloads 里正确解析，你就已经拥有了足够强的最小验证闭环。GalibierHub 这类站点更适合渐进式验证，而不是一次性“全量揭幕”。

==== 7.3 配置 GitHub 登录与管理员身份

+ 在 Supabase 启用 GitHub Provider。
+ 在 GitHub 创建 OAuth App。
+ 配置站点 URL 和 Redirect URLs。
+ 设置管理员用户名环境变量。

建议在本地先完成一次完整登录测试，再部署生产环境。否则 Discussion 页面最容易在上线后才暴露权限问题。登录跳转、回调地址和管理员登录名一致性都应在这里一次性验证清楚。

这里真正要验证的，不只是按钮能否完成登录，而是同一个登录会话是否既能让前端显示管理员控件，又能让 `/api/feedback` 接受管理员回复和 moderation 操作。只有这两边都同时成立，才能算是真正登录成功，而不是“看起来像成功”。

==== 7.4 准备参考文件与下载资源

+ 上传 FASTA、FAI、BED、GFF3 到公共存储。
+ 如需 Overview 下载卡片，准备归档文件并填好环境变量。
+ 如需样本级下载入口，更新 `genome_samples` 中对应下载 URL。
+ 如需完整下载弹窗元数据，在 `download_metadata` 中补齐记录。

这一步的重点是让“数据库中的元数据”和“对象存储中的真实文件”保持一一对应。如果只是先填了数据库，却没有保证真实对象存在或索引完整，后面 JBrowse 与 Downloads 都会出问题。

准备新数据集时，建议保持一个严格顺序：先上传文件，再验证原始直链和索引可达，然后再写数据库元数据，最后才在 Overview 或 Downloads 中把它们暴露出去。顺序如果反过来，就会出现“页面已经宣传了文件，但存储层还拿不出来”的尴尬阶段。

==== 7.5 本地联调

```bash
npm run dev
```

本地重点验证四件事：

- Overview 是否能加载真实统计值
- Records 是否能筛选并联动到 JBrowse
- Discussion 是否能发帖、登录、回复
- Downloads 是否能解析文件并生成正确链接

在这里就把关键路径跑通，比部署后再逐项排查更省时间。能本地闭环的功能，到了线上通常只需要补环境；本地都没有闭环的功能，线上往往只会更难查。

这些检查最好按一条完整用户路径来跑，而不是零散地点几个组件。建议从一个干净浏览器标签页开始，先看 Overview，再进入 Records，跳到 JBrowse，然后打开 Discussion、管理员登录回复，最后再测试一个公开下载路径和一个私有路径（如果有）。这种按路径演练的方式更容易发现跨功能状态假设是否成立。

==== 7.6 部署到 Vercel

Vercel 适合作为主站。部署时应确保所有 `NEXT_PUBLIC_*` 变量和 Supabase 相关变量都已经在项目后台配置完成，并在构建阶段可见。如果构建完成后页面仍然表现为空数据或路径错误，第一优先级永远是复核变量，而不是立即怀疑业务代码本身。

第一次成功部署到 Vercel 后，最好顺手记一份很短的发布日志，记录 Git 提交、后台改过哪些变量，以及当前部署预期对应的数据集或 schema 版本。等到未来某一次“仓库里没明显代码差异，但线上行为变了”时，这类小日志会非常有价值。

==== 7.7 部署到 Cloudflare（可选）

如需镜像或更友好的区域访问，可使用：

```bash
npm run build:cf
npm run preview:cf
npm run deploy:cf
```

Cloudflare 构建失败时，应优先检查 OpenNext 兼容性、环境变量注入和 `wrangler.toml` / `open-next.config.ts` 的同步状态，而不是先怀疑业务逻辑。因为镜像站最常见的故障点恰恰发生在平台适配层，而不是发生在页面本身。

如果 Vercel 和 Cloudflare 两边都长期保留，那么“环境一致性”就应被当成一项明确的维护任务。不能默默让某个平台变成唯一真正可用的环境。至少在每次涉及数据访问、登录或下载的改动后，都应对两边做一次最小烟测并比对环境矩阵。

==== 7.8 部署后回填验证

生产环境部署完成后，建议立刻回到 Supabase 和对象存储后台检查：

- 新留言是否成功写入表
- 上传图片是否成功落入 bucket
- 下载计数是否记录
- 公开文件直链是否有效
- 私有文件签名链接是否按预期过期

这一步经常被忽略，但它决定你拿到的是“页面能打开的站点”，还是“功能闭环真的成立的站点”。真正可维护的站点不是只看前端能否打开，而是要看数据库、对象存储、登录回复和下载计数是否都能回填到正确的位置。

这里最有价值的不是口头确认，而是留下几条具体证据：一条成功写入的 `site_feedback`，一个真实上传到 bucket 的图片对象，一条 `download_events` 记录，以及一个可用的公开或签名下载地址。后续维护时，这些具体样例会比抽象描述更适合当作回归参照。



==== 7.9 双平台部署应被视为两套构建验证

GalibierHub 目前可以采用 Vercel 主站加 Cloudflare 镜像或补充代理的方式运行，但这并不意味着两边天然等价。Vercel 更接近标准 Next.js 路径，Cloudflare 往往还涉及 OpenNext、Worker 适配和平台差异处理。

因此同一套代码在两个平台上都能稳定运行，并不是一个构建按钮自动保证的结果，而应被看成两次单独验证：

- 两边环境变量是否都完整；
- 两边部署的是否是同一个提交；
- 动态路由和 API 行为是否一致；
- 下载、JBrowse 和代理路径在镜像平台上是否也没有静默退化。

这样做的好处很直接：一旦两个平台表现不一致，维护者可以更快判断问题是在业务代码、平台适配层还是部署配置本身，而不是盲目回滚一整批改动。


=== 8. 验证清单

==== 8.1 Overview

- 统计卡片返回真实数值，而不是占位值或空值。
- 图表正常绘制，没有因为字段缺失而报错。
- 精选下载卡片能打开正确的下载弹窗。
- 页脚中的访客计数会对新的浏览器配置文件增长，对同一配置文件的简单刷新保持稳定。

通过这一项时，最好同时保留两种证据：至少一次使用全新浏览器配置文件或无痕窗口让 Visitors 增长，以及一次在同一配置文件里刷新页面却不重复增长。只有同时满足这两点，才能证明它统计的是浏览器访客，而不是刷新量。

==== 8.2 Records

- 样本元数据筛选和记录级筛选都可用。
- 排序、分页、行点击和详情浮层正常。
- 记录总数与页面统计逻辑一致。

验证 Records 时，不要只跑一条最顺手的查询。至少应测试一次样本级缩小、一次 promoter 级缩小，以及一次两者叠加筛选。只有这样才能证明两跳查询边界仍然成立。

==== 8.3 JBrowse

- 参考序列能够加载。
- 至少有一条注释轨道正常激活。
- 点击记录后浏览器能跳到对应区间。
- 缺失部分轨道时，浏览器应降级而不是整体崩溃。

JBrowse 的通过标准应该强于“面板能显示出来”。维护者最好证明三件事：参考序列能加载，点击记录后 locus 会变化，以及缺少某条可选轨道时浏览器仍然可用。只有这三者一起成立，才算真正稳。

==== 8.4 Discussion

- 公共用户可以提交新留言。
- GitHub 登录流程可用。
- Markdown 工具栏以及 `Write` / `Preview` 双标签页可用。
- 管理员登录后可回复、置顶、隐藏、显示、删除 discussion，并能管理回复。
- 图片上传和图片访问都正常。
- 每条单独回复的点赞数值实时更新，不再显示红心图标。
- 浏览量显示服务端真实数值，不再显示 `-`。
- 头像悬浮卡片显示在线状态，支持关注/取消关注。
- 时间线滑条可拖动，并与浏览器滚动同步；显示主帖和每条回复的发布日期。
- 分类筛选提供 `All Categories` / `Issue` / `Tutorials`，且只有管理员可新建 Tutorials；Downloads 下载指南位于 `/docs/download-cli`。
- 通知中心能收到关注、取消关注、回复、\@提及和评论点赞等实时事件。

对维护者来说，最有价值的是跑一遍完整 moderation 路径，而不只是测试发帖。建议新建一条 discussion，管理员登录后回复它、置顶它、隐藏它、再显示出来，并对其中一条回复做管理。这一轮操作能覆盖掉当前最容易漂移的大部分状态边界。

==== 8.5 Downloads

- 面包屑导航和目录级浏览正常。
- 默认表格视图正常，排序和分页正确。网格视图切换正常。
- 文件元数据展示正确。
- 浏览器下载按钮可用。
- `wget -c`、`curl -L -C -`、`hf download` 等命令可复制且路径正确。
- Manifest TSV/CSV 导出字段正确。
- Manifest CSV 导出中的 SHA-256 值正确。
- Manifest CSV 与 CLI/checksum 弹窗中的 SHA-256 均来自目录元数据，不出现 `NA` / `N/A`。
- 统一 `Tutorials` 菜单提供 `View all Tutorials` 和 `Download & CLI Usage Guide`，下载指南位于 `/docs/download-cli`。
- `Records` 是 Downloads 的第一个文件夹，包含 `Reference_Genomes`、`Variant_Calling_VCF`、`ML_Ready_FASTA` 三个子目录，并提供与其他 Downloads 文件夹一致的浏览、选择、导出、浏览器下载、CLI 与集群批量下载能力。
- Records 中的 12 个样本各有 `.vcf.gz` 与 `.fasta`，共 24 个样本文件，外加参考 FASTA 与 GFF3；点击单条 `Download` 列或执行 `Send Selected to Downloads` 后，Downloads 会自动展开对应子目录并勾选、高亮、滚动到目标文件。
- 批量下载脚本不会错误包含私有签名文件。

如果当前部署同时有公开和私有资源，最好把两种行为都显式验证一次：先导出 batch script，确认里面只包含公开文件；再单独解析一个私有文件，确认签名链接确实有时效。这样才能真正证明访问控制边界还在。

==== 8.6 运维检查

- Vercel 与 Cloudflare（若启用）都能独立构建。
- 所有构建变量在后台有明确定义。
- README、部署文档和 `src/site-config.ts` 没有明显脱节。

这一项很容易被忽略，因为它不像产品功能那样直观。但它其实是抵御未来维护债务的重要手段。一个 fork 最难接手的时候，通常不是代码坏了，而是代码已经更新了，说明文档却还停留在另一个版本。

这份清单的意义不是追求形式完整，而是帮维护者把最容易出问题的链路在最短时间内复核一遍。科研站点往往不是某一个组件坏掉，而是“某条完整路径在中途断了”，所以验证要按路径看，而不是按文件看。


== III. 仓库代码与工程管理


=== 9. 仓库文件说明

以下列表覆盖当前上传到 GitHub 仓库中的主要跟踪文件。构建输出目录、依赖目录和本地私有变量文件不在此列。

==== 9.1 根目录

- `.env.local.example`：本地开发与部署的环境变量模板。
- `.gitignore`：Git 忽略规则。
- `AGENTS.md`：协作代理说明。
- `CLAUDE.md`：辅助代理说明。
- `LICENSE`：项目许可证。
- `README.md`：英文部署说明。
- `README.zh-CN.md`：中文部署说明。
- `eslint.config.mjs`：ESLint 配置。
- `next.config.ts`：Next.js 运行配置。
- `open-next.config.ts`：OpenNext / Cloudflare 构建配置。
- `package-lock.json`：npm 锁文件。
- `package.json`：依赖、脚本与项目元数据。
- `postcss.config.mjs`：PostCSS 配置。
- `schema.sql`：数据库、Discussion、下载与存储相关结构定义。
- `tsconfig.json`：TypeScript 编译配置。
- `wrangler.toml`：Cloudflare 运行时配置。

对维护者而言，根目录并不是一堆杂项文件的堆放区，而是项目边界假设最集中的地方。这里的文件通常在回答三类问题：应用怎么构建、应用怎么配置、以及下一位维护者应该从哪里进入。

==== 9.2 文档、静态资源与脚本

- `docs/architecture.gif`：架构示意图。
- `docs/data-compression-guide.md`：大文件压缩、索引与上传说明。
- `public/galibierhub-banner.svg`：站点横幅资源。
- `scripts/build-cloudflare.mjs`：Cloudflare 构建整理脚本。

当一个 fork 在代码层面还像 GalibierHub，但在某个部署平台上已经不像 GalibierHub 时，通常就应该先回到这一组文件，而不是先去改某个组件。很多“线上不对、本地没问题”的情况，本质上都发生在这里。

==== 9.3 Cloudflare 代理模板

- `cloudflare-templates/hf-proxy/README.md`：Hugging Face 代理 Worker 的部署说明。
- `cloudflare-templates/hf-proxy/worker.js`：代理 Worker 源码。
- `cloudflare-templates/hf-proxy/wrangler.toml`：代理 Worker 配置模板。

==== 9.4 API 路由

- `src/app/api/download-catalog/route.ts`：按目录层级返回下载目录。
- `src/app/api/download-metadata/inc/route.ts`：记录下载事件与计数。
- `src/app/api/download-metadata/resolve/route.ts`：将下载元数据解析为真实可用的下载地址。
- `src/app/api/download-metadata/route.ts`：下载元数据的读取与保存接口。
- `src/app/api/download-metadata/verify/route.ts`：验证受保护下载的访问条件。
- `src/app/api/feedback/route.ts`：Discussion 主条目、留言提交和管理员回复接口。
- `src/app/api/hf-proxy/[...path]/route.ts`：内置 Hugging Face 回退代理。
- `src/app/api/promoters/route.ts`：记录筛选、排序、分页查询接口。
- `src/app/api/reactions/route.ts`：点赞与收藏接口。
- `src/app/api/samples/[id]/route.ts`：单样本元数据查询接口。
- `src/app/api/samples/batch/route.ts`：批量样本解析与脚本生成接口。
- `src/app/api/stats/route.ts`：Overview 统计接口。
- `src/app/api/upload-image/route.ts`：Discussion 图片上传接口。
- `src/app/api/variants/route.ts`：变异查询接口。

这些路由文件是真正把产品意图落成可执行行为的地方。后续维护者如果要改权限、改文件解析规则、改查询语义，通常都应优先从这里看起，因为它们明确保留了“UI 动作”和“数据读写”之间的边界。

==== 9.5 页面与样式

- `src/app/favicon.ico`：站点图标。
- `src/app/globals.css`：全局样式。
- `src/app/layout.tsx`：页面布局与元信息容器。
- `src/app/page.tsx`：主页面与各主要界面的入口。
- `src/app/promoter-id-page.tsx`：记录详情页的共享逻辑。
- `src/app/promoter/[id]/page.tsx`：基于记录 ID 的独立详情路由。

后续维护者只有在页面外壳、路由结构或全局呈现契约真的要变化时，才应该优先动这一组文件。很多看起来像页面 bug 的问题，其实是数据或路由问题，过早在这里动手通常只会增加噪音。

==== 9.6 组件层

- `src/components/discussion-comments.ts`：Discussion 条目与评论的共享辅助定义。
- `src/components/download-actions.tsx`：单文件下载弹窗和管理员编辑能力。
- `src/components/download-catalog-panel.tsx`：`Downloads` 目录浏览面板。
- `src/components/exportable-chart.tsx`：图表导出包装组件。
- `src/components/feedback-composer.tsx`：可拖动的留言提交面板。
- `src/components/genome-browser.tsx`：嵌入式基因组浏览器容器。
- `src/components/jbrowse-viewer.tsx`：JBrowse 初始化、装配配置和代理回退逻辑。
- `src/components/promoter-detail.tsx`：记录详情浮层。
- `src/components/promoter-table.tsx`：记录表格、排序、分页和批量选择逻辑。
- `src/components/search-filters.tsx`：筛选表单组件。
- `src/components/site-feedback.tsx`：Discussion 主界面和管理员回复交互。
- `src/components/site-uptime.tsx`：站点运行时长组件。
- `src/components/stats-chart.tsx`：Overview 摘要卡片与图表。
- `src/components/user-guide.tsx`：站内用户指南抽屉。

组件层是最容易诱发“看见什么就先改什么”的地方，但通常应在路由和数据边界搞清楚之后再动。GalibierHub 的很多组件都依赖 API 返回形态、管理员身份或存储路径假设，不理解这些前提就先改组件，回归问题会更难查。

==== 9.7 Hook、库、配置、类型与工具

- `src/hooks/use-download-visibility.ts`：下载项显隐规则 Hook。
- `src/lib/admin-login.ts`：管理员 GitHub 登录名解析。
- `src/lib/download-info.ts`：浏览器下载与命令行命令生成功能。
- `src/lib/feedback-admin.ts`：管理员身份校验逻辑。
- `src/lib/sample-exclusions.ts`：样本排除规则。
- `src/lib/storage.ts`：存储 URL 与路径工具函数。
- `src/site-config.ts`：站点配置中心。
- `src/types/genome.ts`：记录、统计和样本相关共享类型。
- `src/utils/supabase-browser.ts`：浏览器端 Supabase 客户端。
- `src/utils/supabase.ts`：服务端 Supabase 客户端。

这一组文件里有很多本来就应该被优先复用的抽象面。后续如果要新增常量、身份判断或存储解析逻辑，通常最安全的做法是扩展现有工具层或配置层，而不是在某个组件里临时再造一套。

这一章的价值在于让后来接手仓库的人能先从文件职责建立认知，而不是一上来就在整个仓库里盲目搜索。对模板型项目而言，明确文件分工本身就是降低维护成本的一部分。



==== 9.8 JBrowse 必须维持在感知存储边界的实现方式上

JBrowse 是最容易被误改坏的区域之一，因为它同时跨越了页面状态、代理策略、远程文件托管以及 Range 请求能力。很多维护者会先验证“链接能不能打开”，但真正影响浏览体验的，往往是“能否按区间读取、能否正常 seek、能否及时返回索引”。

GalibierHub 当前之所以相对稳定，是因为没有假设所有浏览器资源都能被前端直接稳定访问。它的优先级是：先尝试外部代理，再走内置 `/api/hf-proxy` 回退，最后才直接访问公开资源地址。

这个顺序的意义在于，浏览器资源和普通下载文件并不完全一样。它们更依赖 Range 支持、索引配套和头信息稳定性，也更容易受区域网络差异影响。因此，后续只要更换浏览器文件托管方式或参考数据位置，就应测试“能否加载目标区间并正确渲染”，而不是只测试 URL 在浏览器里是否能打开。

同样地，这类路径最好继续保持显式配置或元数据驱动，而不是在组件深处通过临时字符串拼接构造出来。否则一旦换数据源，问题会散落在很多文件里。


=== 10. 更细的逐文件职责图谱

==== 10.1 应用外壳与各主要界面的调度入口

对大多数后续维护者来说，最现实的起点还是 `src/app/page.tsx`，因为它不仅负责切换各主要界面，更是当前运行时很多跨界面假设的汇合点。按当前实现，它至少负责这些事情：

- 从 `/api/stats` 拉取 Overview 所需统计；
- 从 `/api/promoters` 拉取 Records 数据；
- 维护当前被选中的记录，并把它转成 JBrowse 所需的 locus；
- 从浏览器侧 Supabase 会话里同步 GitHub 登录状态；
- 把管理员提示和 access token 传给 `SiteFeedback` 与 `DownloadCatalogPanel`；
- 在 Supabase 未配置或数据为空时，把配置错误提示抛给主界面。

这意味着一个经验判断：只要某个问题跨越了不止一个 tab，就不应只盯某个子组件，通常先看 `src/app/page.tsx` 是否把跨界面状态或身份边界组织对了。

进一步说，`src/app/page.tsx` 最适合继续承担“调度层”而不是“细节实现层”的职责。后续 fork 如果还要增加新 tab、更多跨界面状态或更重的权限逻辑，最好把具体行为继续下沉到 route、lib 或独立组件中，而不要把所有业务都堆进这个入口文件。因为一旦它开始同时承载筛选语义、存储规则和权限细节，后面任何一个跨界面 bug 都会变得更难隔离。

==== 10.2 配置、环境变量与管理员身份边界

GalibierHub 当前的配置和身份边界并不只存在于一个文件里，而是一组需要一起理解的文件：

- `src/site-config.ts`：控制站点名称、对外文案、特色下载项、浏览器默认区间和联系信息，是最核心的可配置入口；
- `.env.local.example`：说明全新部署到底需要哪些环境变量；
- `src/utils/supabase.ts` 与 `src/utils/supabase-browser.ts`：分别定义服务端和浏览器端的 Supabase 客户端边界；
- `src/lib/admin-login.ts`：解析界面层预期的管理员 GitHub 登录名；
- `src/lib/feedback-admin.ts`：负责服务端真正用于校验管理员身份的帮助函数。

维护者最好把这些文件当成一个配置簇来读。因为管理员身份如果只在其中一个地方改了，前端显示、服务端校验和真实权限很快就会漂移。

站点身份的其他字段也有同样风险。项目名称、联系邮箱、管理员登录名、下载根路径、JBrowse 默认区间，这些值看似分散，实际上都属于同一组“站点自我定义”。一个 fork 版本如果只在某处文案里改了名字，却没有把配置簇一起对齐，后续最常见的结果就是页面上看起来换了站，但真正的登录边界、下载边界和默认浏览器行为仍然停留在旧配置上。

==== 10.3 Discussion 的前端交互面与 moderation 文件群

当前 `Discussion` 能力分布在一组虽小但职责明确的文件中：

- `src/components/site-feedback.tsx`：主交互面板，负责 `In Progress` / `Completed` 列表、Markdown 编辑器、`Write` / `Preview`、图片上传、reaction 加载、分页以及管理员置顶 / 隐藏 / 显示 / 删除等操作；同时订阅 `site_reactions` Realtime，实时刷新留言与评论的爱心计数；
- `src/components/discussion-comments.ts`：为主面板提供 discussion 条目与评论的共享状态和辅助逻辑；
- `src/app/api/feedback/route.ts`：真正的 mutation 边界，负责创建 discussion、创建回复、切换隐藏状态、切换置顶状态以及删除主条目或回复；
- `src/app/api/upload-image/route.ts`：把图片上传到公开的 `feedback-images` bucket；
- `src/app/api/reactions/route.ts`：记录点赞/取消点赞，写入 `user_id` 与 `actor_name`，并配合 `site_reactions` Realtime 返回最新计数。
- `src/components/user-profile-card.tsx`：头像悬浮简介卡片，实时显示在线状态，并支持关注/取消关注。
- `src/app/api/notifications/route.ts`：站内通知的读取、已读和 Realtime 订阅入口，覆盖回复、\@提及、点赞、关注与徽章解锁事件。

这里有一个很重要的维护经验：moderation 问题几乎不会永远只停留在一个文件里。只改 `site-feedback.tsx` 往往只是让按钮出现或消失；只改 `/api/feedback` 又可能让权限在接口层可用，但前端完全没有暴露入口。后续维护时应把这一组文件一起看作一条完整路径。

更稳妥的判断方式，是先分清当前修改到底属于“表现层”还是“权限层”。表现层问题通常落在组件文件，关注按钮何时显示、列表如何分区、预览如何渲染；权限层问题则应落在 `/api/feedback` 与管理员校验辅助函数，关注谁能执行 mutation、哪些字段允许变更。Discussion 功能后续最容易出现的回归，就是把这两个边界混在一起改，结果界面看似正确，但服务端仍然拒绝真正的管理员操作。

==== 10.4 Downloads 的目录级能力与单文件能力分工

现在的下载系统是有意拆成“目录级职责”和“单文件职责”的，这个分工后续最好继续保留。

- `src/components/download-catalog-panel.tsx`：负责面包屑导航、当前目录状态、目录内搜索、Grid / Table 视图切换、排序、目录级 CLI、manifest 导出、checksum 导出以及嵌套目录展示；同时读取 `sessionStorage.galibier_pending_downloads`，在 Records 跨页跳转后自动展开目标子目录、勾选文件、高亮并滚动到目标行；
- `src/components/download-actions.tsx`：负责单文件弹窗、单文件元数据补全、浏览器下载准备、CLI 命令展示、密码验证、管理员编辑、快速隐藏切换以及区域切换下的公共链接选择；
- `src/lib/download-info.ts`：根据元数据生成解析后的文件信息，以及浏览器 / CLI 下载命令；
- `src/lib/storage.ts`：判断某个 URL 是否真的是可下载的原始文件路径，而不是页面地址；
- `src/app/api/download-catalog/route.ts`：把配置中的 featured downloads 和数据库里的 sample-linked downloads 合并，再叠加管理员维护的隐藏状态、校验信息等；Records 样本文件会映射到 `Records/Variant_Calling_VCF` 与 `Records/ML_Ready_FASTA`，并过滤旧版 Records 根目录文件；
- `src/app/api/download-metadata/route.ts`：保存管理员编辑过的文件元数据；
- `src/app/api/download-metadata/resolve/route.ts`：把逻辑下载键解析成真正可下载的 URL；
- `src/app/api/download-metadata/verify/route.ts`：验证密码保护文件；
- `src/app/api/download-metadata/inc/route.ts`：记录下载事件。

实际维护时，先问清楚一个 bug 是“目录级浏览错误”还是“单文件交付错误”，通常就能立刻缩小到正确的文件簇。

还有一种常见情况其实属于“元数据级错误”。也就是目录结构、视图切换、弹窗外形都正常，但只有一批文件的大小、校验值、隐藏状态、私有存储路径或直链解析有问题。这类场景下，先看 `download_metadata` 与解析逻辑，往往比反复改 React 组件更有效。能先判断问题是目录级、单文件级还是元数据级，通常就能省掉大量无效改动。

==== 10.5 Records、详情浮层与 JBrowse 联动文件群

`Records` 流程也不是一个简单表格，而是一条多文件联动路径：

- `src/components/search-filters.tsx`：定义筛选输入面；
- `src/components/promoter-table.tsx`：负责排序、分页、行点击、批量选择，以及单行 `Download` 下拉（`Download Variant (VCF)` / `Download Sequence (FASTA)`）和选中行 `Send Selected to Downloads (VCF)` / `Send Selected to Downloads (FASTA)` 批量入口；
- `src/components/promoter-detail.tsx`：展示单条记录的详情浮层；
- `src/components/genome-browser.tsx` 与 `src/components/jbrowse-viewer.tsx`：把选中的 locus 真正交给浏览器运行时；
- `src/app/api/promoters/route.ts`：把筛选条件翻译成 Supabase 查询；
- `src/app/api/samples/[id]/route.ts` 与 `src/app/api/samples/batch/route.ts`：支撑样本级查询与批量导出流程；
- `src/app/api/variants/route.ts`：在更细粒度检查时提供变异查询面。
- `src/app/page.tsx`：通过 `handleRecordDownload(sampleId, kind)` 与 `handleSendSelectedToDownloads(kind, sampleIds)` 把待下载文件名写入 `sessionStorage.galibier_pending_downloads`，随后切换到 Downloads 标签页；

这组文件要连起来看，因为 Records 的价值从来不只是“显示一张表”，而是“让筛选结果、详情信息和浏览器坐标形成一条连续工作流”。

这也是为什么后续新增筛选字段时不能只改一个地方。只要 `search-filters.tsx` 多了一个条件，通常就意味着 route 解析、数据库字段、前端类型、详情浮层文案，甚至 JBrowse 跳转上下文都可能要一起调整。维护者如果把 Records 视为一个由筛选、结果、详情和浏览器共同组成的连续路径，很多“为什么界面能选但结果不对”一类的问题会更容易提前避免。

==== 10.6 Visitors 计数涉及的文件边界

页脚里的 Visitors 看起来只是一个小数字，但它其实跨越了前端持久化、API 逻辑和数据库策略三层：

- `src/components/site-uptime.tsx`：计算 uptime 文本，在 `localStorage` 中创建或复用浏览器访客 ID，构造浏览器指纹，并调用 `/api/visitors`；
- `src/app/api/visitors/route.ts`：对指纹做 hash，统计 `site_visitors` 总数，判断当前浏览器是否已存在，并根据 service-role 是否可用执行插入或更新时间；
- `schema.sql`：定义 `site_visitors` 表，以及让这个逻辑可运行的 read / insert / service-role update 策略。

这类功能最容易误导后续维护者，因为界面上只是一个很小的数字，但真正问题常常在浏览器持久化、RLS 策略或环境变量不一致上。

因此 Visitors 功能的验证最好至少使用两个彼此独立的浏览器身份，而不是只在同一个浏览器标签页里反复刷新。只有这样，维护者才能同时判断“新身份是否真的被插入”“已存在身份是否被正确去重”“页面显示的总数是否和数据库行为一致”。如果只在单浏览器环境里看一个数字，往往很难判断故障到底发生在插入、去重还是展示层。

==== 10.7 schema.sql 不是初始化脚本而是运行时行为骨架

`schema.sql` 不应该被当成一次性初始化脚本，而应被当成运行时行为的一部分。当前仓库里，它定义了多条真正影响站点行为的边界：

- `genome_samples`、`predicted_promoters`、`variant_index` 等核心数据表；
- `site_feedback`、`feedback_comments`、`site_reactions` 等 Discussion 相关表；
- `site_visitors` 访客统计表；
- `download_metadata` 与 `download_events` 这样的下载元数据和事件表；
- 把公开读、公开插入、service-role 更新 / 删除区分开的 RLS 策略。

因此只要线上数据库和这个文件脱节，界面仍可能正常渲染，但真正的写入、moderation、访客更新和下载解析会陆续失效。后续维护时不应把它视为样板 SQL，而要视为“应用行为的数据库表达”。

从维护角度看，每一次 schema 变更都应被当成一次产品行为变更。只要列名改了、默认值变了、RLS 收紧了，route handler、前端预期、运维说明乃至测试路径都可能需要一起跟进。如果数据库层先漂移，而上层文件仍按旧契约运行，GalibierHub 很容易出现“页面还能看、但真实操作陆续坏掉”的隐蔽退化。

==== 10.8 部署与平台适配文件

部署层同样有一组应被一起理解的文件：

- `next.config.ts` 与 `open-next.config.ts`：决定 Next.js 标准构建和 Cloudflare 适配行为；
- `wrangler.toml`：Cloudflare 运行时配置；
- `scripts/build-cloudflare.mjs`：Cloudflare 构建后处理脚本；
- `cloudflare-templates/hf-proxy/worker.js` 及其 `wrangler.toml`：可单独部署的 Hugging Face 代理 Worker 模板；
- `README.md` 与 `README.zh-CN.md`：维护者实际会遵循的部署说明入口。

因此当某个部署只在某个平台失败时，通常先看这组文件，而不是先改 UI 代码。

这组文件本质上也是项目记忆的一部分，记录了这个仓库究竟应该如何被构建、适配和上线。后续维护者不应把它们当成不可碰的脚手架附件，而应把它们看成部署契约本身。很多平台差异问题，与其在页面层反复猜测，不如先回到这些文件里确认这个 fork 当前究竟打算以什么方式被发布。



==== 10.9 悬浮翻转卡片（FlipCard）交互（Overview 页面）

`src/components/flip-card.tsx` 提供了一个可复用的 FlipCard 组件，基于 CSS 3D 变换（Tailwind 工具类）实现：

- 最外层容器设置 `[perspective:1000px]` 赋予深度感和 `group` 触发。
- 内层变换层使用 `[transform-style:preserve-3d]`，并通过 `group-hover:[transform:rotateY(180deg)]` 控制 180° Y 轴旋转。
- 正面（Front）添加 `[backface-visibility:hidden]`，渲染图标 + 标题 + 描述。
- 反面（Back）预翻转 `[transform:rotateY(180deg)]` 并添加 `[backface-visibility:hidden]`，内含功能特性列表和 CTA 按钮。
- 反面的按钮使用 `e.stopPropagation()`，点击不会触犯父级翻转。

`src/app/page.tsx` 在 Overview 标签页的 `StatsChart` 下方渲染四张 FlipCard（Overview 已精简为仅保留 StatsChart 仪表盘和 FlipCard 导航卡片，SearchFilters 和 PromoterTable 已移除）：

#tablem[
  | 卡片 | 图标主题 | 按钮行为 |
  | :--- | :--- | :--- |
  | Search & Discovery（检索发现） | 蓝色搜索图标 | "Explore Records" 跳转至 Records 标签页 |
  | Genome Browser（基因组浏览器） | 绿色图表图标 | "View Browser" 通过 `setActiveTab('genome-browser')` 跳转至独立的 Genome Browser 标签页 |
  | File Distribution（文件分发） | 紫色下载图标 | "Open Downloads" 跳转至 Downloads 标签页 |
  | Community & Moderation（社区讨论） | 琥珀色对话图标 | "Join Discussion" 跳转至 Discussion 标签页 |
]

*UX 原则*：仅首页概览的功能卡片使用翻转交互。高频操作界面（Records 数据表、下载按钮、搜索表单）保持静态，避免干扰快速工作流。


==== 10.10 基因组浏览器禅定模式（Zen Mode）

`src/components/genome-browser.tsx` 新增全屏禅定模式，支持无干扰的基因组浏览体验：

- *状态*：`const [zenMode, setZenMode] = useState(false)`，配合 `useCallback` 封装的切换函数。
- *触发*：JBrowse 查看器下方渲染"Fullscreen"按钮。
- *全屏覆盖层*：固定定位 `z-50` 全视口容器（`inset-0`），顶部标题栏显示"Genome Browser — Zen Mode"和"Exit (Esc)"按钮。
- *Esc 退出*：`keydown` 事件监听 Esc 键关闭禅定模式。
- *滚动锁定*：禅定模式激活时 `document.body.style.overflow = 'hidden'`，退出或组件卸载时恢复。
- *JBrowse 重新挂载*：`JBrowseViewer` 组件在覆盖层内以全视口尺寸重新渲染，轨道数据不丢失。


==== 10.11 色觉无障碍可视化调色板

`src/components/stats-chart.tsx`（Overview 页面 ECharts 饼图）将默认的 `viridis` 风格调色板替换为 *Okabe-Ito 色板*：

```
['#E69F00', '#56B4E9', '#009E73', '#F0E442', '#0072B2', '#D55E00', '#CC79A7', '#000000', '#999999', '#882255']
```

此色板专为红色盲（protanopia）、绿色盲（deuteranopia）和蓝色盲（tritanopia）三类色觉障碍设计，确保所有读者均能清晰区分物种分布饼图的各扇区。


==== 10.12 暗色模式移除与 Overview 页面精简

为进一步简化用户体验并减少维护负担，本次更新（2026-07-28）移除了暗色/浅色主题切换功能：

- 删除 src/components/theme-toggle.tsx（58 行）。
- 移除 src/app/layout.tsx 中的 ThemeScript 函数调用（13 行）。
- 移除 src/app/page.tsx 中的 ThemeToggle 引用。

同时 Overview 标签页内容进一步精简：仅保留 StatsChart 仪表盘和四张 FlipCard 导航卡片，SearchFilters 和 PromoterTable 移至 Records 标签页。


==== 10.13 独立的 Genome Browser 标签页

此前基因组浏览器仅嵌入在 Records 标签页底部。本次更新新增了独立的 Genome Browser 顶部导航标签页：

- activeTab 类型扩展为 overview | promoters | genome-browser | discussion | downloads。
- 顶部导航栏新增 Genome Browser 按钮。
- 独立的渲染分支：activeTab === genome-browser 包含全宽 JBrowse 线性基因组视图和 Zen Mode。
- FlipCard 和详情面板的 View Browser CTA 均更新为 setActiveTab(genome-browser)。




==== 10.14 Discussion 独立页面、站内通知与 Downloads 优化 (2026-07-29)

*Discussion 独立页面体系：* 每个讨论拥有独立 URL (/discussions/[id])，支持 SEO 索引和社交分享。详情页右侧悬浮时间轴显示阅读进度（如 2/5）、最早日期和最新活跃时间。回复之间插入时间间隔线（如 15 days later），每个内容块右下角提供数值点赞和分享链接按钮，红心图标已移除。底部展示浏览量、链接数和参与者头像集合（悬停弹出用户卡片）。未登录访客滚动到底部时显示注册引导模块。

*站内通知系统：* 顶部导航栏新增铃铛图标，小红点显示未读数量。基于 Supabase Realtime，GitHub 登录用户收到回复时实时推送。下拉面板展示通知列表（发起人、摘要、相对时间），支持一键全部已读。数据库新增 site\_notifications 表，API 路由 /api/notifications。

*Downloads 默认表格视图：* 文件浏览默认切换为表格视图，支持按文件名、大小、更新时间排序。网格视图通过右上角切换器保留。

*数据库变更：* site\_notifications 表含 RLS 策略。site\_feedback 新增可选 user\_id 列引用 auth.users(id)。


==== 10.15 徽章系统、macOS 设计语言与 Discussion 增强工具 (2026-07-29)

*徽章系统（游戏化激励）：* 16+ 种徽章类型，覆盖新手引导、社区活跃、极客技术、学术探讨和里程碑五大类别。徽章通过 API 触发器自动颁发（如首次发言自动获得 Ice Breaker，单条回复获 10 赞自动获得 Nice Reply）。徽章定义预置在 badge\_definitions 表中，用户已获得徽章存储在 user\_badges 表中。徽章以微型图标形式（青铜/白银/黄金/白金四级）紧贴用户名显示，在 Discussion 列表页和详情页均可见，通过 BadgeDisplay 组件统一渲染。

*macOS 设计语言全面升级：* 全局 CSS 采用苹果灰（\#F5F5F7）底色、毛玻璃导航栏（backdrop-blur-xl saturate-150）、自定义半透明滚动条、柔化焦点光晕、按钮微交互（inset\_0\_1px\_0 高光刻线 + active:scale-[0.98] 按压回弹反馈）。所有卡片统一使用
ounded-2xl 大圆角配合弥散阴影 shadow-[0\_8px\_30px\_rgb(0,0,0,0.04)]。全局启用抗锯齿 antialiased 和紧致字间距 	racking-tight。

*悬浮回复编辑器：* 将底部固定文本框升级为浮动的 FloatingReply 面板，配备完整 Markdown 工具栏（加粗、斜体、代码块、引用、链接、上传图片、无序列表）、Edit/Preview 切换、回复目标标记。图片通过 /api/upload-image 上传并内联渲染，点击可放大至全屏灯箱。

*Discussion 筛选与排序：* 列表页新增状态筛选（全部/进行中/已解决）和排序下拉（最新/最早/最多赞）。

*管理员操作：* 管理员可隐藏/删除帖子或单条回复、置顶讨论，并且管理员名称在讨论中统一显示为"GalibierHub Team"而非 GitHub 用户名。

*User Guide 侧边栏重构：* 全面视觉升级，采用苹果风格卡片分区布局、按模块着色 SVG 图标、kbd 风格 UI 关键词 Badge、改进的字号层级体系。



+ 优先修改 `src/site-config.ts`，不要把站点常量散落到多个组件里。
+ 保持管理员相关术语在界面文案和维护文档中一致。
+ 任何涉及管理员权限的改动，都要同时检查前端显示逻辑和后端身份校验。
+ 任何涉及下载行为的改动，都要区分公开文件与私有签名文件两条路径。
+ Hugging Face 文件应长期保存 `resolve/main` 直链，而不是 `blob/main` 页面地址。
+ 当 Vercel 构建通过而 Cloudflare 构建失败时，优先排查平台适配层，而不是直接回滚业务代码。
+ 当 README、部署文档和仓库代码发生偏移时，应优先修正文档，否则后续接手者会在错误入口上浪费很多时间。
+ 新增筛选条件前，先判断它属于哪一跳查询边界。
+ 表结构契约变化时，schema、route、UI 预期和文档应一起更新。
+ 一旦用户开始围绕原始存储路径写脚本，就要把这些路径当成公开 API 来维护。
+ 即便已经导入全量数据，也建议保留一小批已知正确的最小测试切片用于回归检查。
+ 凡是同时跨越 UI 状态和后端授权的功能，每次改动后都要双侧验证，不能只看一边通过。

这些建议并不复杂，但都来自同一个现实：GalibierHub 这种研究数据库模板的维护难点，往往不在算法本身，而在配置、边界和路径是否被持续保持清楚。能持续把边界写清楚，往往比多加几个功能更重要。

除了上面列出的 12 条具体建议外，还有几条更原则性的维护态度值得写下来。第一，每次改动后都要问自己一个问题：这个改动有没有让后续维护者的认知负担变得更轻？如果答案是否定的，那改动本身可能还需要再想一下。第二，尽量让每个边界都有唯一的责任归属。如果一个状态同时被两个文件管理，那么下次出现不一致时，维护者就需要在两个文件之间来回猜哪个才是真正的权威来源。第三，不要把测试只停留在"按钮能不能点"的层面。GalibierHub 的很多边界是跨层的——从浏览器到 API 到数据库到存储——如果只验证了最表面的一层，底层漂移就不会被发现。第四，文档维护本身就是工程的一部分。每当 README 和代码出现偏差时，优先修文档，而不是等后来者自己从代码里猜出正确的路径。

第五，当站点被 fork 到一个全新物种或领域时，最容易出问题的往往不是代码本身，而是那些看起来只是"示例数据"的部分。默认的物种名称、参考序列、默认 locus、精选下载卡片、样本排除规则，这些散落在配置和环境变量中的值才是真正需要第一时间对齐的。第六，对下载系统来说，每增加一种新的文件托管源或区域镜像，都应该同时更新 manifest 和 checksum 的导出逻辑，而不仅仅是让前端多一条直链。因为用户一旦开始依赖你的目录导出写脚本，他们就会把导出结果当成契约来用。

==== 10.16 Alpine Geek 色彩主题 (2026-07-30)

为进一步提升 GalibierHub 的品牌辨识度并降低科研工作者长时间盯屏的视觉疲劳，本次更新将全局 UI 从高饱和度 Bootstrap 默认蓝全面迁移至定制的"极客高山" (Alpine Geek) 配色体系：

*主色调：* 使用深石板蓝 (Slate \#0F172A / \#1E293B) 替代亮蓝色，应用于主要操作按钮（如 Apply filters、Copy Folder CLI、New Discussion），传递学术权威感和数据安全感。

*强调色：* 引入冰川青 (Glacier Teal \#0D9488) 作为导航高亮和交互反馈色，以及巅峰金 (Summit Gold \#EAB308) 用于核心 Download 按钮和徽章边框，形成品牌差异化。

*背景层：* 全局底色从纯白 \#FFFFFF 改为极浅冷灰 \#F5F5F7（苹果灰），内容卡片保留纯白并通过弥散阴影 (shadow-[0\_4px\_20px\_rgba(0,0,0,0.03)]) 浮起，创造"层叠雪峰"的空间层次感。

*语义色降饱和：* 所有成功（绿）、警告（黄）、错误（红）提示降低明度和饱和度，采用柔和粉彩底色搭配深色文字，管理员提示框使用极淡青灰底色配合深墨绿文字。

*按钮微交互：* 添加 inset\_0\_1px\_0 高光刻线、active:scale-[0.98] 按压回弹反馈、以及 hover:-translate-y-0.5 悬浮提升效果。

设计公式：深石板蓝主导（权威） + 大面积浅灰留白（呼吸感） + 克制的点缀色（引导）。

==== 10.17 邮箱密码登录与 AuthModal 统一认证 (2026-07-30)

为降低非 GitHub 用户（临床医生、公卫学者、湿实验研究员）的注册门槛，新增邮箱密码登录系统：

*AuthModal 组件 (src/components/auth-modal.tsx)：* 创建统一的登录模态框，顶部 Tab 切换 GitHub OAuth 和 Email 登录两种方式。

功能包含：
- GitHub 标签页：一键 GitHub OAuth 授权，错误友好提示（如 Provider 未启用时给出 Supabase 控制台操作指引）
- Email 登录标签页：邮箱 + 密码表单，调用 supabase.auth.signInWithPassword
- Email 注册标签页：邮箱 + 密码 + 确认密码，调用 supabase.auth.signUp，成功后显示"Check your email"确认提示
- 登录/注册模式切换：底部 "No account? Sign up" / "Already have an account? Sign in" 互转链接

*页面集成：*
- src/app/page.tsx：顶部"Sign in"按钮打开 AuthModal，登录后显示 UserMenuPanel
- src/app/discussions/[id]/page.tsx：同上集成；DiscussionFooter 中的 "Join the conversation" 注册引导模块的三个按钮 (Sign Up / Maybe later / no thanks) 已对接 AuthModal

*Supabase 后端配置要求：* Authentication -\> Providers -\> Email 需开启，生产环境前务必配置 SMTP（见 11.10）。

==== 10.18 Resend SMTP 邮件发送配置实战 (2026-07-30)

Supabase 自带的默认邮件服务器存在严格的速率限制（约 3 封/小时），无法满足生产环境需求。以下为绑定 Resend 专业邮件服务的完整流程：

*第一阶段：Resend 域名配置*
+ 注册 Resend (resend.com)，进入 Domains -\> Add Domain，填写 galibierhub.org
+ Resend 生成 DNS 记录（1 条 MX + 2-3 条 TXT）
+ 登录 Cloudflare 控制台，进入 galibierhub.org DNS -\> Records，逐一添加上述记录
+ 核心避坑：所有验证记录的代理状态必须为 DNS only（橙色小云关闭）
+ 回到 Resend 点击 Verify DNS records，验证通过后状态变绿
+ API Keys -\> Create API Key：Name 填 Supabase-SMTP，Permission 选 Sending access，Domain 选 galibierhub.org，生成后立即复制 re\_ 开头的密钥

*第二阶段：Supabase SMTP 填写*
+ Supabase 控制台 -\> Authentication -\> Emails -\> SMTP Settings
+ 开启 Enable Custom SMTP
+ 参数配置：
   - Host: smtp.resend.com
   - Port: 465
   - User: resend（固定值，非个人邮箱）
   - Password: 粘贴 re\_... 密钥
   - Sender Name: GalibierHub
   - Sender Email: noreply\@galibierhub.org

保存后，用户注册时将收到发件人为 GalibierHub \<noreply\@galibierhub.org\> 的验证邮件。


==== 10.19 全球时区辅助系统 (World Clock) (2026-07-30)

为降低跨国科研合作的沟通成本，新增全球时区命令面板与侧边栏小组件：

*命令面板 (Command Palette) 模式：*
- 入口：顶部导航栏地球图标按钮，附 Ctrl+K 快捷键提示
- 交互：点击后弹出居中极简模态框，顶部搜索框实时过滤城市/时区
- 默认展示：纽约、伦敦、北京、东京、苏黎世 5 个主要科研枢纽当前时间
- 搜索范围：覆盖 33+ 全球主要城市，支持按城市名、国家名、时区字符串检索
- 视觉设计：日间 显示 图标，夜间 显示月亮图标；底部状态栏显示本地参考时间
- 技术实现：纯浏览器原生 Intl.DateTimeFormat API + IANA 时区字符串，零第三方依赖

*侧边栏小组件模式：*
- 位置：Discussion 详情页导航栏右侧，与时间轴滑动条并列
- 样式：小巧的胶囊按钮，配合 Globe 图标显示，hover 时展示简短提示

*无感化时区处理：*
- 数据库统一存储 UTC 时间，前端根据浏览器时区自动本地化渲染
- 时间悬浮 Tooltip 显示绝对时间："Jul 30, 2026, 04:17 AM (Your Local Time)"
- 用户简介卡片可推算并显示对方当地时间与在线状态

文件实现：src/components/world-clock.tsx（独立组件，在 Discussions 列表页和详情页中复用）


==== 10.20 Downloads 模块学术级升级 (2026-07-30)

对标 Zenodo、Dryad、Hugging Face 等国际顶尖数据仓库，GalibierHub 的 Downloads 模块从学术引用体系、数据完整性校验、集群自动化脚本生成和社区联动四个维度进行了深度重构。

*学术引用体系：*
- 页面顶部 License 徽章旁新增 *Cite Dataset* 按钮，点击弹出 BibTeX、RIS、DataCite 及 Plain Text 四种引文格式。
- 侧边栏设立 Citation 模块，一键复制完整引用文本。
- 核心数据集建议分配 DOI 并展示在文件名旁的黑底白字 DOI 徽章中。

*数据版本控制与历史快照：*
- 侧边栏引入版本时间轴面板，列出特定日期的所有历史版本及对应 DOI。
- 旧版本页面顶部弹出显眼的版本更新提示条，防止使用过期数据进行分析。

*文件级完整性校验与预览：*
- 每个文件名称下方直接展示 md5 / SHA-256 校验字符串。
- 增加 `echo " checksum filename" | sha256sum -c` 终端校验命令。
- 对 CSV、TSV、R 脚本等文本文件提供 Preview（眼睛图标）按钮，利用 HTTP Range Requests 拉取文件头几 KB 数据并高亮渲染。

*面向 HPC 集群的高级批处理生成器：*
- 勾选多个文件后，Download Selected 按钮弹出选项弹出框，含三个选项：
  - Direct Browser Download（浏览器直接下载）
  - Copy Batch aria2c Script（aria2c 多线程加速批量脚本）
  - Export Selected Manifest CSV（导出选中清单 CSV）
- 支持生成 wget -i urls.txt 批量文本清单、Python requests / R download.file 自动化脚本片段。

*Discussions 生态联动：*
- 单文件下载弹窗引入选项卡结构（Tabs）：Download & CLI | File Preview | Checksum | Cite | Batch Script。
- 旧版 Linked Tutorials 标签页已移除；`Download & CLI Usage Guide` 现在位于独立 `/docs/download-cli` 页面。
- README 弹窗升级为完整 Markdown 渲染界面，支持语法高亮、表格渲染，底部放置 "Have questions? Ask in Discussions" 引导入口。

*主列表页 UI 改进：*
- CLI 按钮旁新增 Eye (Preview) 快捷预览图标。
- 管理员操作（Hide/Unhide）收纳进更多菜单（...），保持界面清爽。
- 表格视图默认按文件名、大小、更新时间可排序。

==== 10.21 社区、徽章、认证与 Downloads 更新 (2026-07-31)

本次更新完成了 GalibierHub 社区层的关键闭环：账户处理、Discussion 实时互动、用户资料、通知、徽章分析、管理员统计和下载完整性。

*认证与身份*
- 登录和创建账户的密码栏新增显示/隐藏切换按钮。
- 邮箱注册默认使用邮箱 `@` 前的文字作为用户名；登录时也会回填缺失的个人资料。
- 全站显示同一个已登录用户名，不再在非 Discussion 页面回退成 `Visitor`。
- Cloudflare Turnstile 覆盖登录、注册、忘记密码、OAuth、反馈、下载和图片上传流程，使用始终可见的 Managed 验证勾选框。

*Discussion 实时互动*
- 每条单独回复的点赞数值都能实时更新，红心图标已移除。
- ordered-list 工具栏按钮先插入 `1.`，随后依次插入 `2.`、`3.`。
- 浏览量不再显示占位 `-`，读取服务端真实浏览计数。
- 悬浮头像打开个人简介卡片，显示实时在线状态并支持关注/取消关注。
- 关注、取消关注、评论点赞、回复和 \@提及都会为目标用户写入站内通知。
- 时间线滑条可按住拖动移动整篇讨论，与浏览器滚动保持同步，并显示主帖和每条回复的发布日期。
- 分类筛选改为 `All Categories`、`Issue`、`Tutorials`，且只有管理员可新建 Tutorials；Downloads 下载指南位于 `/docs/download-cli`。

*Downloads*
- Export Manifest CSV 从下载元数据输出真实 SHA-256，不再导出 `NA`。
- CLI 与校验弹窗显示真实 SHA-256，不再显示 `N/A`。
- Downloads 统一提供 `Tutorials` 菜单，包含 `View all Tutorials` 和 `Download & CLI Usage Guide`；下载指南位于 `/docs/download-cli`。
- `Records` 是 Downloads 的第一个文件夹，集中展示 Records 界面的全部文件，并支持与其他文件夹完全一致的浏览、选择、导出、浏览器下载、CLI 和集群批量下载。
- Records 单行 `Download` 下拉与选中行批量操作会把对应 VCF / FASTA 写入 `sessionStorage`，在 Downloads 中自动展开目录、勾选、高亮并滚动到目标文件。

*个人资料、Settings 与通知*
- Settings 菜单保留 `Settings` 选项，并新增 `View saved profile` 按钮，用于查看当前用户保存后的完整个人资料；菜单中不再单独提供 `View Full Profile` 与 `Activity` 入口。
- Notifications、Replies、Likes、Following 四个下拉列表分别提供 `Mark all read` 一键已读按钮。
- 个人主页与动态页加载徽章、发帖/回复数、关注状态和动态流。
- Settings 保存后写入 Supabase，并同步显示到 Discussions、个人简介卡片和用户菜单；清空字段也会同步为空。
- 从 Settings 界面移除 Interface 功能。
- Realtime 通知订阅监听 `site_notifications` 并按 `recipient_id` 过滤，另加轮询兜底；通知标签可区分关注、取关、点赞、回复、\@提及和徽章解锁。

*徽章系统与徽章分析*
- 徽章定义和用户奖励分别存放在 `badge_definitions` 与 `user_badges`，颁发逻辑由数据库触发器完成，不依赖前端判断。
- 点赞类徽章同时覆盖 discussion 主帖与单条回复，通过 `entry_id` 和 `comment_id` 区分。
- `BadgeDisplay` 在用户名旁渲染已获得徽章；个人简介卡片、用户菜单和完整个人主页都会展示徽章详情。
- 管理员端 `Badges` 标签提供 KPI 卡片（累计颁发、活跃收集者、最容易解锁、最稀有成就）、稀有度分布、持有者矩阵、View Users 和手动授予 PI/Founder。
- 管理员徽章统计不再依赖 `admin_badge_stats` 视图，改为直接聚合 `badge_definitions` 与 `user_badges`；迁移中的视图可保留但不作为运行依赖。
- 手动授予徽章会同时写入 `site_notifications`，接收者立刻看到解锁通知。

*管理员用户统计*
- 新增管理员统计界面，显示总注册用户数、绿色 `+N this week` 趋势、GitHub 与邮箱注册占比迷你饼图，以及最近 5 位加入用户列表。
- 管理员界面同时汇总讨论、下载、访客和徽章活动。

*性能*
- 重型管理员面板和可选 UI 组件使用动态导入，降低首屏 JavaScript 和页面切换延迟。
- 保留原有缓存头与静态/动态路由边界，确保普通页面导航保持快速，同时不影响 Realtime 更新。


== IV. 运维、维护与故障排查


==== 11.1 不要把元数据和大文件塞进同一条路径

GalibierHub 当前最值得保留的工程习惯之一，就是始终把“可查询的结构化元数据”和“体积较大的二进制文件”分开处理。数据库擅长筛选、排序、计数、关联和状态管理，但并不适合直接承担大规模 FASTA、索引文件、注释文件或归档包的长期分发。

因此在当前架构里，更稳妥的做法一直是：

- 把记录、下载元数据、显示状态、权限标志和 moderation 状态放在 Supabase；
- 把参考序列、注释文件、发布压缩包和批量下载资源放在对象存储或公开文件托管；
- 通过 API 路由把两侧连接起来，而不是把两类数据强行压进一个系统里。

后续 fork 时，即便你换了物种、样本体系或数据来源，也建议继续保留这条边界。很多模板项目后面变难维护，并不是因为功能做多了，而是因为一开始把数据职责混在了一起，后面只能一边修一边重新拆分。


==== 11.2 Downloads 实际上有三条下载路径

当前 `Downloads` 页面的设计并不是只围绕一个下载按钮展开，而是刻意提供了三种不同的下载方式，因为真实用户的工作习惯并不相同。

第一条路径是浏览器直接下载，适合用户快速拿一个文件。第二条路径是单文件 CLI 弹窗，适合把 `wget` 或 `curl` 命令复制到远程服务器、Linux 终端或批处理脚本中。第三条路径是目录级工作流，也就是现在新增的面包屑导航、目录级 CLI、manifest 导出以及校验文件导出。

这三条路径不应该被视为“同一个按钮换了三种皮肤”，而应理解为三类不同的使用场景：

- 在网页里浏览和快速取回单个文件；
- 在命令行中做可复现的单文件拉取；
- 面向队列分析或批量任务做目录级下载与后续整理。

后续如果你继续扩展下载系统，首先应该问的不是“按钮怎么摆更好看”，而是“新需求主要服务的是哪一类下载习惯”，然后再检查另外两条路径是否仍然能正常退化运行。


==== 11.3 公开文件与受保护文件必须遵循不同契约

GalibierHub 的下载能力既要支持公开直链文件，也要预留给受保护资源或带验证条件的文件使用。这意味着下载行为并不只是前端视觉问题，它本质上还是一份访问契约。

对于公开文件，最理想的结果是给出一个稳定、可复用、可被浏览器和命令行直接消费的原始地址。对于受保护文件，目标则不同：前端可以正常展示目录结构、元数据和说明，但真正的文件地址应通过后端校验后再解析出来，而不是直接暴露在前端。

这里非常容易出现一种伪正常状态：维护者只拿公开测试文件验证，结果页面一切正常，但真实受控文件的校验接口、签名 URL 或过期逻辑其实已经失效。因此每次调整下载系统时，都应明确区分“公开下载路径”和“受控下载路径”是否分别被验证过。

如果未来 fork 版本引入 embargo 数据、受限临床文件或分阶段开放的资源，推荐做法是保持目录结构和可见元数据稳定，把真正的访问控制留在 `resolve` 或 `verify` 路由完成，而不是在前端把整条路径藏得不可读。


==== 11.4 Manifest 导出本身就是工作流接口的一部分

新增的 manifest 导出功能不只是一个顺手加上的按钮，它实际上承认了一个事实：很多用户不会停留在网页里，而是会把 GalibierHub 输出继续接到 QIIME 2、Snakemake、Nextflow、shell pipeline 或集群任务中。

因此 manifest 当前采用的是尽量平实、利于脚本读取的列设计。核心字段包括：

- `Directory_Path`
- `File_Name`
- `File_Type`
- `Size_Bytes`
- `Direct_URL`
- `SHA-256`

这些字段看起来并不花哨，但正因为它们语义稳定，才适合被 Excel、R、Python、shell 脚本和调度系统共同消费。后续如果你的 fork 版本需要加入样本配对关系、实验批次、测序方向或队列标签，也建议通过新增列来扩展，而不是改变现有字段的含义。

对维护者来说，manifest 最重要的不是“导出来好不好看”，而是“列名是否稳定、脚本是否能长期复用、用户是否能把它直接接进下游流程”。

2026-07-31 开始，manifest 与 CLI/checksum 使用目录元数据中的真实 SHA-256；没有校验值时导出空值而不是 `NA` / `N/A`，避免下游脚本把占位符当成真实校验值。


==== 11.5 校验文件不是装饰，而是科研下载闭环的一部分

科研下载最麻烦的一点在于，文件损坏常常不是显式报错，而是“文件下载完了，但后续软件读不动”。部分传输、断点异常、镜像节点中断或浏览器缓存错误，都可能让用户得到一个存在于磁盘上、却不可用的文件。

也正因为如此，Manifest CSV 导出中的 SHA-256 字段同样承担了校验角色。用户在批量下载结束后，可以通过 Manifest 中的 SHA-256 值进行文件级校验，而不是手工逐个核对文件是否完整。这一点对于真正的研究数据发布是交付闭环的一部分，而不是附属体验。

后续维护时至少要注意两件事：

- 如果文件托管源发生变化，要确认生成的校验值对应的是实际分发的文件内容，而不是中间跳转页面或 HTML 响应；
- 如果某个文件被原地替换，则校验文件和目录元数据应同时更新，否则页面显示的版本和用户验证到的版本会脱节。

一个声称可复现的数据站点，不应该在最终文件完整性这一步留下模糊空间。

CLI 与校验弹窗也使用同一真实值，不再显示 `N/A`。这样无论用户从 CSV manifest 还是从单文件 CLI 弹窗核对文件，得到的校验契约都保持一致。


==== 11.6 Discussion 已经是一条正式业务边界

当前 `Discussion` 页面已经不再是一个简单留言框，而更接近轻量级技术论坛。Markdown 编辑器、可视化工具栏、`Write` / `Preview`、置顶 discussion、隐藏状态、删除操作、回复 moderation 和管理员身份校验共同组成了一整套交互和权限模型。

2026-07-31 之后，它同时包含实时爱心反应、真实浏览量、头像卡片在线状态、关注/取消关注、通知事件和可拖动时间线。因此 Discussion 的验证不能只停留在“能不能发出去”，还要验证实时计数、通知写入、个人资料同步和时间线交互是否跨页面保持一致。

因此维护时真正要保护的，不只是某几个按钮是否存在，而是三层边界是否一直保持一致：

- 普通用户在前端能看到什么；
- 管理员在 GitHub 登录后前端会显示什么；
- 后端 `/api/feedback` 实际允许执行什么。

只要三层中有一层漂移，就会出现很难排查的异常，例如按钮显示了但权限不够、某个列表里可以置顶另一个列表里却失败、已隐藏的回复在错误查询里重新冒出来。也正因为如此，后续任何改动只要碰到 Discussion，都建议分别检查 `In Progress`、`Completed`、置顶、隐藏、删除、回复隐藏和回复删除这些状态，而不是只测试“能不能发帖”。


==== 11.7 Visitors 统计的是浏览器访客，不是刷新量

当前页脚里的 Visitors 计数设计目标是“累计浏览器访客数”，而不是简单的 page views。它依赖浏览器侧持久化访客标识来尽量避免同一浏览器反复刷新把数字迅速冲高。

换句话说，正常情况下，同一浏览器的持续刷新不应无限累加；但无痕模式、新浏览器、新设备或清空本地存储后重新访问，则可能被视为新的访客。这种取舍更接近轻量站点里常说的“近似唯一访客”，也比单纯刷新计数更有参考意义。

如果线上长期显示 `Visitors: 0`，那问题大概率不在样式，而在环境或数据库层面，例如：

- `schema.sql` 中的 `site_visitors` 表及其策略没有真正创建；
- 生产环境缺少预期的 Supabase 变量；
- service-role 路径不可用，而匿名回退又被策略阻断；
- 线上部署的代码并不是最新版本。

因此 Visitors 的排查顺序应从 schema、策略和环境变量开始，而不是先看前端渲染。


==== 11.8 fork 时优先改配置，而不是一上来重构结构

很多人拿到模板仓库后的第一反应是立刻改页面结构、拆组件甚至重写导航，但在 GalibierHub 里，这通常不是最高效的第一步。因为当前仓库已经把大量可见身份信息集中到了配置、文案和元数据层，你往往不需要先动结构就能完成第一轮定制。

更稳妥的 fork 顺序通常是：

+ 先改 `src/site-config.ts` 中的站点标题、描述、联系信息和默认展示内容；
+ 再替换环境变量和外部服务凭据；
+ 再导入或映射新的数据库内容；
+ 再替换参考文件和下载资源；
+ 最后才判断当前 UI 结构是否真的不够用。

这种顺序能避免一个常见问题：维护者一开始就重构结构，结果把运行时假设打散了，最后才发现原本大部分品牌替换和领域适配其实通过配置就能完成。


==== 11.9 回归检查最好按用户路径组织

GalibierHub 更适合按照“用户完整路径”而不是“源码目录”来做回归检查。也就是说，你应该能从头走通几条核心流程：

- 打开站点并确认 Overview 统计能返回；
- 搜索记录、打开一条结果、联动到 JBrowse；
- 进入 Discussion，测试发帖、格式预览和管理员 moderation；
- 进入 Downloads，测试面包屑、表格视图、manifest 导出和 CLI 复制。

这种验证方式之所以重要，是因为很多真实 bug 并不出在某一个文件里，而是出在“路由输出变了，但组件还按旧字段消费”这样的中间层断裂。只看源码目录很容易漏掉这类问题，按用户路径走一遍反而更容易发现实际故障点。


==== 11.10 后续维护最应该保住的不是某个视觉细节，而是边界清晰

GalibierHub 后续是否还能保持模板价值，并不取决于某一版按钮样式是否保留，而取决于这些基础边界是否还清楚：

- 是否还有一个明确的配置中心；
- 是否还清楚区分元数据与二进制文件；
- 是否还保留清楚的管理员身份模型；
- 是否还保留从浏览器点击到命令行批量拉取的完整下载链路；
- 是否还坚持按完整路径而不是零散组件做验证。

只要这些边界还在，GalibierHub 就仍然是一套可 fork、可复用、可长期接手的研究数据库模板；一旦这些边界被打散，它很快就会退化成只有原作者自己才知道怎么维护的一次性站点。


==== 11.11 技术栈的务实选择

Next.js + Supabase + Tailwind + Cloudflare 构成的栈适合读多写少、公开为主、偶有私有的资源数据库场景。关键决策在于：把大文件存储完全交给外部（Cloudflare R2/Hugging Face），不写入数据库。因此 fork 时优先调整配置和外部存储边界，不要一上来就重构技术选型。



==== 11.12 区域下载策略与公共路径

Hugging Face 官方端点在亚太地区可能不稳定。项目内置 hf-mirror.com 镜像切换，在 download-info.ts 中自动推导相应 CLI 命令。公共下载弹窗应展示最强的公共路径，确保默认下载行为适应面向国内科研用户的维护场景。



==== 11.13 官方回复必须持续绑定真实管理员身份

`Discussion` 区域的可信度，很大程度取决于谁有资格以管理员身份发言。GalibierHub 当前把这种权限绑定到 GitHub 登录身份和后端校验上，而不是只靠前端徽标或界面样式。

这条边界应该继续保持严格。后续维护时，可能会有人为了测试方便加入本地开关、纯前端角色切换或临时 impersonation 模式。在本地沙箱里这样做问题不大，但它不应渗透进生产逻辑。

实践上最简单的标准是：如果一个回复在界面上被呈现为“官方管理员回复”，那么后端必须能明确证明为什么这个身份是管理员。否则 Discussion 很快就会失去可信度。


==== 11.14 高密度工作台界面本身就是可维护性的一部分

GalibierHub 是研究工作台，不是营销首页。这一点会直接影响后续的维护判断。对于工作台界面来说，信息密度、对齐方式和稳定控件往往比装饰性新颖感更重要。

也正因为如此，前面的界面升级才会收紧 `Discussion` 的侧栏空间、把统计信息改成更紧凑的 badge 样式，并让 `Downloads` 更适合表格化浏览。这些变化不只是“更好看”，而是在为更长标题、更大队列、命令行工作流和重复高频使用做准备。

对未来 fork 而言，一个简单判断标准是：如果某个界面决策提升了扫描效率、比较效率和重复操作效率，它大概率是对的；如果它主要增加的是仪式感和装饰感，就应该谨慎。


==== 11.15 建议的接手第一周清单

对于准备真正把 GalibierHub 接过来并长期维护的人来说，第一周最应该做的通常不是立刻加功能，而是有控制地建立理解。

一个比较稳妥的接手顺序是：

+ 把 `README.md`、`README.zh-CN.md`、`.env.local.example` 和 `src/site-config.ts` 连起来读一遍；
+ 按 `schema.sql` 初始化 Supabase，并确认所有表、策略和 bucket 都真实存在；
+ 在本地运行站点，把各主要界面都走通一遍；
+ 替换站点身份、联系信息和对外说明；
+ 先导入一小批但足够真实的记录和下载数据，再考虑整批迁移；
+ 用真实 GitHub 登录链路验证一次管理员 moderation；
+ 验证 manifest 导出、checksum 导出以及至少一条 JBrowse 资源路径；
+ 最后再开始结构层面的定制。

这个顺序听上去保守，但它确实是保守的。对于研究数据库模板来说，保守的接手顺序通常比激进的早期重构更省时间，也更不容易把基础边界打散。

==== 10.22 加载反馈系统：GalibierLoader 爬坡动画与 nextjs-toploader (2026-08-06)

本次更新建立了按重量分级的加载反馈体系，彻底解决了骨架屏闪烁和动画滥用问题。

*设计原则*

- 重量级全屏沉浸式动画（Galibier 爬坡）仅用于三个核心场景，不打断用户心流。
- 轻量级页面跳转使用顶部极细进度条，消灭灰色骨架块。
- 防闪烁算法确保极速请求不显示动画，中等请求不闪烁。

*三个重量级场景*

 + *网站首次启动（Splash Screen）*：访客首次进入网站时，全屏显示 GalibierLoader 爬坡动画，包含完整的阿尔卑斯山场景（层叠雪峰、森林山脊、岩壁、带黄色虚线的山路），精细的骑行者 SVG（腿部、曲柄、车轮动画）沿山路爬升，实时海拔 HUD 从 0 攀升至 2,642m，中文标签遥测仪表盘显示"海拔高度"和"爬坡进度"，建立品牌第一印象。
+ *大队列特征过滤（Records）*：用户在 Records 页面设置复杂筛选条件并点击 Apply Filters 时，触发全屏爬坡动画。
+ *集群批量下载（Downloads）*：用户点击 Cluster Batch Download 按钮时，触发全屏爬坡动画。

*核心组件与文件*

 - src/components/GalibierLoader.tsx：爬坡动画组件，渲染完整的阿尔卑斯山场景（云层、雪峰、森林山脊、岩壁、带黄色虚线的山路），精细的骑行者 SVG（腿部、曲柄、车轮动画），实时海拔 HUD（0-2,642m，Col du Galibier 真实海拔），中文标签遥测仪表盘（"海拔高度"和"爬坡进度"），D 902 · COL DU GALIBIER 路线徽章。支持 progress prop 控制进度（传入数字为真实进度模式，不传为智能模拟模式）。
 - src/contexts/LoadingContext.tsx：全局加载状态管理，提供 showLoading(initialProgress?)、setLoadingProgress 和 hideLoading API。实现了 250ms 宽限期（操作在 250ms 内完成则不显示动画）和 2.0s 最短展示时间（一旦显示至少停留 2.0s 防止闪烁）。isLoading 状态初始为 true，使启动画面在服务器 HTML 中先于任何页面内容渲染，加载器 DOM 在 Provider 中置于 children 之前。
- src/app/layout.tsx：引入 \<NextTopLoader color="\#0D9488" height={2} showSpinner={false} /\>，为所有轻量级页面跳转提供 2px 青色顶部进度条。
 - src/app/loading.tsx：已删除。启动画面现在完全由 LoadingContext 管理，isLoading 默认为 true，不再依赖 Next.js 路由级别的 loading 文件。
 - src/app/page.tsx：Overview 页面不再在挂载时调用 showLoading(undefined)；启动画面已从上下文默认值中可见。页面获取 /api/stats 并在 2500ms 超时后调用 hideLoading()。Records 的 handleSearch 调用 showLoading(undefined) 触发检索动画。
- src/components/download-catalog-panel.tsx：Cluster Batch Download 按钮调用 showLoading(undefined) 触发下载动画。

*骨架屏移除*

skeleton-screen.tsx 组件已从所有页面导入中移除，骨架屏不再在应用程序的任何地方使用。所有页面跳转由 nextjs-toploader 接管，重型操作由 GalibierLoader 接管。

=== 12. 按真实故障场景组织的排错章节

==== 12.1 GitHub 登录后 Discussion 里始终看不到管理员操作按钮

这种故障的表面现象通常是：用户已经用 GitHub 登录，但看不到置顶、隐藏、显示、删除或管理员回复入口。

建议按这个顺序检查：

+ 确认 `src/app/page.tsx` 里浏览器侧会话确实拿到了 GitHub 登录名；
+ 确认 `src/lib/admin-login.ts` 解析出的管理员登录名与生产环境真实 GitHub 账号一致；
+ 确认 access token 已经传递给 `SiteFeedback` 与 `DownloadCatalogPanel`；
+ 确认 `/api/feedback` 中 `requireCreatorGithubAuth` 在服务端真正校验通过；
+ 确认生产环境 Supabase 的 GitHub OAuth 回调地址正确。

如果前端显示“已登录”，但后端并不承认同一个身份，那么页面其他部分都可能正常，只有管理员能力整块消失。

==== 12.2 置顶、隐藏或删除在一个 Discussion 列表里生效，在另一个列表里失效

这种问题通常出现在局部改造之后。比如 `In Progress` 可以置顶，但 `Completed` 不行；或者某条被隐藏后在一个列表消失了，却在另一个列表还会漏出来。

原因通常不是样式，而是列表分区和状态刷新逻辑。当前页面是先按 `creator_reply` 是否存在把条目分成两个列表，再叠加 pinned 排序、hidden 过滤和分页。所以正确排查顺序应是：

- 检查 `site-feedback.tsx` 中 `In Progress` 与 `Completed` 的筛选逻辑；
- 检查返回 payload 中该条目的 `creator_reply`、`hidden` 和 `pinned` 值；
- 检查 `/api/feedback` 是否真的更新了正确字段；
- 检查前端 mutation 成功后是否重新刷新条目列表。

这类问题本质上是状态分区或刷新问题，而不是单纯的视觉问题。

==== 12.3 Discussion 文本可以发出去，但图片上传失败

这是很常见的上线问题，因为文本提交和图片上传走的是两条不同后端路径。

如果文本正常而图片失败，应优先检查：

- Supabase Storage 中是否真的创建了 `feedback-images` bucket；
- `schema.sql` 里针对 `feedback-images` 的读取和插入策略是否真正执行过；
- `/api/upload-image` 是否已部署且可访问；
- 上传文件类型是否在前端允许列表里；
- 当前站点是否连接到了创建 bucket 的同一个 Supabase 项目。

也就是说，文本能发通常说明数据库表没问题；图片失败时，真正的问题更可能在 Storage 配置或上传路由。

==== 12.4 Downloads 页面能打开，但预期文件缺失

当下载目录缺文件时，不应先怪界面渲染。因为目录本身是由“配置中的 featured downloads”与“数据库里的 sample-linked downloads”合并出来的。

更稳妥的排查顺序是：

+ 先确认该文件本应来自 `SiteConfig.downloads.featured`，还是来自 `genome_samples` 中的 `vcf_download_url`、`fasta_download_url`、`gb_download_url`、`bed_download_url` 或 `gff3_download_url`；
+ 确认这个 sample 没有被 `isExcludedSampleId` 过滤掉；
+ 确认 URL 经过 `getDirectDownloadUrl` 和 `validateDirectFileUrl` 后仍然合法；
+ 确认 `download_metadata.hidden` 没把该文件对公开用户隐藏；
+ 如果文件只对管理员可见，确认请求里真的带了管理员 bearer token。

目录缺文件往往不是“没渲染出来”，而是“某个来源在归一化或可见性叠加阶段被筛掉了”。

==== 12.5 浏览器下载按钮报错，但 CLI 命令看起来仍然正常

这类故障通常说明：站点还能在逻辑层识别这个文件，但不能把它解析成真正适合浏览器下载的最终 URL。

应优先检查：

- 配置的是不是 `blob/main` 页面链接，而不是 `resolve/main` 原始文件链接；
- `validateDirectFileUrl` 是否把该 URL 判成了不可直接下载；
- 文件是否被标记为私有存储，但 `download_metadata` 中的 `storage_bucket` 或 `storage_path` 没填完整；
- 文件是否启用了密码保护，而验证过程其实失败了；
- 公共下载路径存在，但当前选中的区域镜像不可用。

这正是为什么当前单文件弹窗既有“逻辑元数据层”，又有“最终解析 URL 层”。文件可以在逻辑上存在，但在最后解析成浏览器下载地址时失败。

==== 12.6 Manifest 导出或 checksum 导出看起来不对

如果 manifest 行内容或 checksum 文件异常，首先应查路径推导逻辑，而不是先怀疑导出格式。

更具体地说，要检查：

- `deriveFolderPath` 和 `deriveFileName` 是否是在处理原始文件 URL，而不是页面 URL；
- 文件托管路径是否仍符合预期的 `/resolve/main/` 结构；
- checksum 是不是如预期来自 `download_metadata` 或远程元数据；
- 当前导出的目录范围是不是当前文件夹，而不是整棵树。

很多 manifest 异常其实是上游 URL 形态先变坏了，一旦路径解析含糊，后面所有导出都会跟着变脏。

如果这个 manifest 还要继续喂给下游流水线，就不要只盯着导出的表头是否齐全，而应抽查至少一行完整记录：确认目录路径是否真的可理解，文件名是否和实际对象一致，`Direct_URL` 是否能下载到预期文件，`SHA-256` 是否对应同一个对象。很多看似“格式没问题”的导出，真正出错的其实是内容契约已经不再可信。

==== 12.7 Visitors 长期显示 0 或始终不增长

这是真实部署里最常见的 Visitors 故障。

建议按这个顺序查：

+ 直接请求 `GET /api/visitors`，先看返回的错误信息是什么；
+ 确认生产 Supabase 项目里真实存在 `site_visitors` 表；
+ 确认生产环境使用的 `NEXT_PUBLIC_SUPABASE_URL` 确实对应已经执行过 `schema.sql` 的那个项目；
+ 如果希望 returning visitor 能更新时间，确认 `SUPABASE_SERVICE_ROLE_KEY` 已配置；
+ 确认浏览器能在 `localStorage` 中保存 `galibierhub-visitor-id`。

当前 Visitors 的设计目标不是“刷新一次就加一”，而是“新浏览器身份能否被成功插入并计入总数”。所以正确问题不是“刷新会不会增加”，而是“新的浏览器身份到底能不能被真正写入数据库”。

这也意味着无痕模式或隐私窗口在当前设计下通常会被视为新的浏览器身份，因为它们拥有隔离且可丢弃的本地存储。对维护者来说，这既是一个很实用的验证手段，也是一条必须写清楚的产品语义边界：这里统计的更接近“独立浏览器身份数”，而不是严格的人数。

==== 12.8 Vercel 能构建，Cloudflare 却失败

遇到这种情况，优先把它当成平台适配问题，而不是立刻怀疑业务功能代码。

应先检查：

- `open-next.config.ts`；
- `wrangler.toml`；
- `scripts/build-cloudflare.mjs`；
- Cloudflare 侧是否缺失必要环境变量或 Worker 相关设置。

然后再确认两个平台部署的是否是同一个 Git 提交。一个平台成功、一个平台失败时，问题往往在输出适配、运行时假设或环境不一致，而不是某个按钮或组件本身。

比较稳妥的排查顺序是：先确认提交是否一致，再确认环境变量是否一致，最后再确认运行时适配是否一致。这个顺序很重要，因为如果一开始就直接改应用代码，维护者很容易把一个纯部署差异问题误处理成业务层 bug，最终反而把两个平台的行为越改越分叉。

==== 12.9 Overview 正常，但 Records 为空或 stats 拉取失败

这通常意味着页面外壳没问题，但底层数据表为空、字段不匹配，或者查询权限不通。

建议检查：

- `genome_samples` 和 `predicted_promoters` 是否真的建表并导入了数据；
- 查询路由预期字段与当前表结构是否仍匹配；
- RLS 是否允许 `schema.sql` 中定义的匿名读取；
- `/api/stats` 或 `/api/promoters` 的响应里是否其实已经包含后端错误，只是页面仍能渲染外壳。

`src/app/page.tsx` 里已经对某些数据源错误给出了提示。后续维护者应该把这些提示理解为“数据边界的信号”，而不是普通的 UI 警告。

更高效的做法，是先从浏览器网络面板里抓一条真实的 `/api/stats` 或 `/api/promoters` 响应，再把它和当前 schema、环境变量矩阵对照。很多“Overview 正常但 Records 为空”的问题，其实几分钟内就能确认是表没导入、字段名不匹配或匿名读策略缺失，而不需要先动任何组件代码。

==== 12.10 JBrowse 能打开，但目标区间空白或非常慢

这类问题通常是存储行为或代理链路问题，而不只是浏览器组件本身的问题。

应检查：

- 引用的 FASTA、索引或注释文件是否能通过当前代理链路正确访问；
- 文件托管源是否支持所需的 Range 请求；
- 跨区域延迟或镜像不稳定是否让这条链路显著变慢；
- 被传入浏览器的 locus 是否真实存在于当前 assembly 中。

对 JBrowse 来说，“URL 在浏览器里能打开”远远不够。真正要测的是“浏览器能否 seek 到目标区间，并正常把该区间渲染出来”。

这类问题也提醒维护者：对象存储兼容性本身就是产品行为的一部分。一个源即使能把文件完整下载下来，也不代表它适合 JBrowse 这种需要频繁 range access 的运行时。如果宿主只满足“能拿到文件”，却不能稳定支持随机区间访问，那么对 GalibierHub 来说它仍然不是正确的部署介质。

==== 12.11 批量下载或 sample-level 文件与当前记录不匹配

当批量下载输出不完整或错配时，通常应先回到 sample 级元数据，而不是先怪批量 UI。

重点检查：

- 当前选中的记录是否带有预期 sample ID；
- 对应 `genome_samples` 行里是否真的填写了正确文件字段；
- excluded sample 规则是否意外过滤掉了本应保留的数据；
- `vcf_download_mode`、`fasta_download_mode` 等模式字段是否按预期设置。

因为批量行为本质上来自记录到样本的映射，一旦映射元数据本身不一致，批量输出就会先坏掉。

因此当 fork 版本继续扩展批量下载或样本级导出语义时，最好始终保留一个“已知正确”的参考样本作为固定校验夹具。只要这个样本的记录映射、文件链接和导出行为都稳定，后续维护者在排查回归时就能快速判断是映射层坏了、数据源坏了，还是新加的批量逻辑把原本正确的路径破坏了。

==== 12.12 给后续维护者的一套安全排错顺序

当问题边界不清楚时，后续维护者最应该避免的是随机改文件。更稳妥的顺序是：

+ 先确认到底是哪一个具体 UI 操作失败；
+ 再定位这个操作调用的是哪个 route handler；
+ 再确认这个 route 依赖的是哪张表、哪个 bucket、哪个配置或哪个权限边界；
+ 只有在依赖边界明确之后，再去查 RLS 策略和环境变量；
+ 每修一次，都重新走完整用户路径，而不是只盯着局部症状看。

这套顺序之所以重要，是因为 GalibierHub 很大程度上是一个“边界管理型项目”。随机改动很容易让表面症状挪位置，但真正断掉的契约根本没有被修好。

也正因为如此，文档质量对这个仓库不是附属品，而是维护效率的一部分。一个理解“界面动作 -\> route -\> 数据 / 存储 / 权限边界”顺序的维护者，通常能很快把故障压缩到正确文件簇；而只盯组件表面的维护者，则很容易在错误的层级上反复打补丁。



=== 13. 安全强化与反爬虫防御

GalibierHub 在 2026 年 7 月完成了一轮安全加固，针对科研公开数据库最常遭遇的两类威胁——恶意爬虫拖库和免费配额资源耗尽——实施了一套"边缘限流 + 显式 Managed 勾选验证 + 自托管 PoW + 代码级蜜罐"的分层防御体系。所有措施均在 Vercel + Cloudflare + Supabase + Hugging Face 免费档下运行，零额外平台费用。

==== 13.1 防御体系总览

GalibierHub 的安全架构遵循分层原则：外层由 Cloudflare 边缘处理 80% 的住宅代理池流量，中层由 Next.js 中间件做二次校验，内层由服务端 Route Handler 和 Supabase RLS 执行最终鉴权。

防御层次：

+ *Cloudflare 边缘层*：WAF + Rate Limiting Rules + Turnstile 显式 Managed 勾选验证
+ *Next.js 中间件*（`src/middleware.ts`）：CORS 校验、速率限制（fallback）、Turnstile token 校验、蜜罐/时间陷阱检测
+ *Route Handler 层*（`src/app/api/*/route.ts`）：Zod 输入校验、Supabase RLS 策略、cursor 分页硬限
+ *数据库层*（Supabase）：RLS 只读策略、服务角色密钥隔离、连接池（Supavisor 事务模式）
+ *基础设施层*：`security.txt`（RFC 9116）、`robots.txt`（AI 爬虫拦截）、Dependabot 自动依赖扫描

==== 13.2 新增反爬与安全文件

以下文件为本轮安全强化新增，每一个都对应一条具体的防御路径。

===== 13.2.1 `src/lib/anti-bot.ts` —— 安全工具库

中间件和 Route Handler 共用的安全模块，导出以下能力：

- *内存速率限制器*（`checkRateLimit`）：基于 key + 滑动窗口的轻量限流，作为 Cloudflare WAF 限流的 edge 端 fallback。对 `/api/promoters`、`/api/samples`、`/api/variants`、`/api/download-catalog`、`/api/reactions`、`/api/feedback` 等搜索/下载/交互路径生效。
- *客户端 IP 提取*（`clientIpKey`）：优先读取 Cloudflare 注入的 `cf-connecting-ip` 头，次选 `x-forwarded-for`，确保边缘限流的 key 准确。
- *Turnstile 服务端校验*（`verifyTurnstile`）：调用 Cloudflare siteverify 端点，带 5 秒超时和 AbortController，避免慢上游拖死中间件。开发环境下自动放行。
- *Turnstile Secret 读取*（`readTurnstileSecret`）：从 `TURNSTILE_SECRET` 环境变量读取，绝不暴露到前端。
- *API Key 哈希*（`hashApiKey`）：SHA-256 截取前 32 位十六进制，用于速率限流的 key 标识。
- *蜜罐检测*（`isHoneypotFilledJson`）：检查 JSON body 中的 `company` 字段（CSS `display:none` 隐藏），被填入即判为 bot。
- *时间陷阱校验*（`validateTimeTrap`）：要求表单提交距离页面渲染至少 2 秒，超过 2 小时则判过期。

中间件 `src/middleware.ts` 在各 `/api/*` 路径上统一调用这些函数，形成一条不可绕过的校验链。

===== 13.2.2 `src/components/turnstile-widget.tsx` —— 前端显式 Managed 验证组件

封装 Cloudflare Turnstile 的前端 widget，以 `render=explicit` 模式按需加载，避免页面初始渲染阻塞；生产环境通过 `appearance: 'always'` 渲染始终可见的 Managed 勾选框（“请验证您是真人”）。

特性：

- 仅在需要时才动态注入 `challenges.cloudflare.com/turnstile/v0/api.js` 脚本
- 本地开发环境无真实 site key 时自动使用 dev token，不影响调试
- 暴露 `onToken(token)` 回调和 `action` 属性，适配不同端点（feedback-submission、image-upload 等）
- 组件卸载时自动清理 widget 实例，防止内存泄漏

使用场景：

- `feedback-composer.tsx`：提交前调用 `turnstile.execute()`，token 随 POST 的 `x-turnstile-token` 头发送，中间件在 `/api/feedback` 校验
- 登录、注册、忘记密码、OAuth、下载触发和图片上传流程均已接入；`AuthModal` 在认证提交前要求用户完成显式勾选，token 随请求发送并在服务端校验

===== 13.2.3 `public/security.txt` —— 漏洞披露联系信息

符合 RFC 标准的 `security.txt` 文件，部署在 `/.well-known/security.txt` 路径，供安全研究者查找漏洞报告渠道。

===== 13.2.4 `public/robots.txt` —— 爬虫白名单与黑名单

分层规则：

- 默认：允许所有爬虫，禁止 `/api/` 路径（防止无意义的 API 爬取），全局 Crawl-delay 5 秒
- 拦截：GPTBot、anthropic-ai、CCBot、PerplexityBot 等 AI 训练爬虫；AhrefsBot、SemrushBot 等 SEO 商业爬虫
- 放行：Googlebot、Google-Scholar、SemanticScholarBot、Internet Archive 等学术索引爬虫，Crawl-delay 降至 1-2 秒
- 提供 Sitemap 指向

===== 13.2.5 `src/components/flip-card.tsx` —— 悬停翻转卡片组件

基于纯 CSS/Tailwind 3D transform 的可复用悬停翻转卡片组件：

- 使用 `[perspective:1000px]` 提供 3D 透视景深
- 使用 `[transform-style:preserve-3d]` 保持子元素的 3D 空间
- 使用 `[backface-visibility:hidden]` 隐藏翻转后的背面
- `group-hover:[transform:rotateY(180deg)]` 在鼠标悬停时沿 Y 轴旋转

*适用场景*：Overview 页面的特性介绍卡片、FAQ 问答模块、团队成员介绍。

*避免场景*：下载按钮、TanStack Table 数据行、任何高频操作控件。

==== 13.3 输入校验强化

`src/lib/validation.ts` 中已有的 Zod schema 覆盖了所有 `/api/*` 端点：

- `promotersQuerySchema`：所有查询参数（chrom、gene\_symbol、species、tissue、cohort、bmi\_class 等）均经 `z.string().max()` 和正则边界校验；`cursor` 字段限制最大 64 字符；`sort_by` 仅允许枚举值；`limit` 上限 1000；`offset` 硬上限 100000
- `feedbackPostSchema`：title 3-120 字符，message 3-2000 字符，rating 1-5 整数，category 和 visibility 枚举约束；`_rendered_at` 和 `company`（蜜罐）字段作为可选字段存在于 schema 中供中间件读取
- 所有下载相关 schema（`downloadMetadataPutSchema`、`downloadIncSchema`、`downloadVerifySchema`、`downloadResolveSchema`）：密码长度、签名 URL TTL、checksum 格式均有限制

每个 Route Handler 在执行数据库查询前调用 `parseAndValidate()`，格式不符的请求直接返回 400，绝不触及 Supabase。

==== 13.4 Cursor 分页防拖库

`src/app/api/promoters/route.ts` 实现了 cursor 分页（基于主键 UUID）替代传统 OFFSET 分页：

- 接受 `cursor` 参数（上页最后一条记录的 `id`）
- 构建查询：`if (cursor) query = query.gt('id', cursor)`
- 响应中返回 `nextCursor`（当前页最后一条记录的 `id`）
- 前端逐页推进，无法通过 `OFFSET 100000` 一次性跨越海量记录

这从根本上阻止了通过递增 offset 拖取全库数据的爬虫策略。

==== 13.5 安全 HTTP 头

`next.config.ts` 中配置的全局安全头，覆盖所有响应：

#tablem[
  | Header | Value | 防护目标 |
  | :--- | :--- | :--- |
  | Content-Security-Policy | default-src 'self'; script-src 限制域名; frame-ancestors 'none' | XSS 注入、恶意脚本加载 |
  | X-Frame-Options | DENY | 点击劫持（Clickjacking） |
  | Strict-Transport-Security | max-age=63072000; includeSubDomains; preload | 强制 HTTPS，防中间人 |
  | X-Content-Type-Options | nosniff | MIME 类型嗅探攻击 |
  | Cross-Origin-Opener-Policy | same-origin | 跨域窗口交互隔离 |
  | Cross-Origin-Resource-Policy | same-origin | 跨域资源访问限制 |
  | Permissions-Policy | camera=(), microphone=(), geolocation=() | 禁用非必要浏览器 API |
  | Referrer-Policy | strict-origin-when-cross-origin | 限制 Referer 泄露 |
]

CSP 的 `script-src` 仅允许 `'self'`、`'unsafe-inline'`（Next.js 必需）、Cloudflare Turnstile（`challenges.cloudflare.com`）和 CDN（`cdn.jsdelivr.net`）；`connect-src` 仅允许 Supabase、R2、Hugging Face 和 Turnstile 域名。

==== 13.6 CORS 跨域策略

`src/middleware.ts` 在处理所有 `/api/*` 请求时执行 CORS 校验：

- 仅允许 `NEXT_PUBLIC_SITE_URL`（生产域名）和 `localhost:3000/3001`（本地开发）作为 Origin
- 拒绝任何不在白名单中的跨域 API 调用，返回 403
- 允许的方法：GET、POST、PUT、PATCH、DELETE、OPTIONS
- 允许的自定义头：Authorization、X-API-Key、X-Turnstile-Token

==== 13.7 Supabase RLS 策略

`schema.sql` 中的所有表均已启用 RLS，关键策略包括：

- `genome_promoters`：匿名用户仅可 SELECT；authenticated 用户（管理员 GitHub OAuth 登录后）获得 INSERT/UPDATE/DELETE 权限
- `api_keys`：仅 `service_role` 可读写，绝不暴露给 anon key
- `feedback_entries` / `feedback_comments`：匿名用户可 INSERT（提交反馈），可 SELECT（查看公开反馈）；service\_role 可 UPDATE/DELETE（管理操作）
- `download_metadata`：匿名用户可 SELECT；service\_role 可 INSERT/UPDATE/DELETE
- `visitor_fingerprints`、`reactions`：匿名用户可 INSERT，service\_role 可全权限

这种策略确保了即使前端暴露的 `NEXT_PUBLIC_SUPABASE_ANON_KEY` 被黑客拿到，也无法直接通过 Supabase REST API 执行 DELETE、UPDATE 等破坏性操作。

==== 13.8 密钥隔离

- `NEXT_PUBLIC_SUPABASE_ANON_KEY`：前端可见，受 RLS 限制，仅可执行策略允许的操作
- `SUPABASE_SERVICE_ROLE_KEY`：仅在服务端 `src/utils/supabase.ts` 的 `getServiceSupabase()` 中使用，`NEXT_PUBLIC_` 前缀绝不出现
- `TURNSTILE_SECRET`：仅服务端 `anti-bot.ts` 读取，前端仅持有 `NEXT_PUBLIC_TURNSTILE_SITE_KEY`（公开的 site key）

==== 13.9 自动化依赖漏洞扫描

`.github/dependabot.yml` 启用了 npm 和 GitHub Actions 的自动依赖扫描：

- 频率：每周检查
- 自动提 PR 升级有已知漏洞的依赖
- 分组：生产依赖和开发依赖分组合并 PR，减少噪音

==== 13.10 防崩措施集成

本轮安全强化中，以下防崩措施与安全代码同时在以下文件中生效：

- *Supavisor 连接池*（`src/utils/supabase.ts`）：单例 Supabase 客户端，`persistSession: false`，避免 Vercel 函数每次冷启动新建连接
- *Cache-Control 头*（`src/app/api/promoters/route.ts`）：`public, s-maxage=300, stale-while-revalidate=600`，允许 Cloudflare CDN 缓存高频检索
- *R2 签名 URL*（下载流程）：大文件走 Cloudflare R2 预签名 URL，Vercel 不中转 1 字节
- *Supabase Keep-Alive*（`cloudflare-templates/supabase-keepalive/`）：独立 Cloudflare Worker 每 3 天查询一次 Supabase，防止 Free 7 天不活跃自动暂停；原有 Vercel `/api/cron/heartbeat` 路由可保留为备用方案
- *物化视图*（schema.sql）：重度聚合查询预计算，减轻 Nano 实例 CPU 压力

#line()



=== 14. 结论

GalibierHub 当前已经不是一个只演示静态界面的模板仓库，而是一套可以部署、扩展并长期维护的研究数据库工作台。对接手这个仓库的人来说，最重要的不是一开始就读完每个组件，而是先掌握四件事：配置入口、数据流向、文件边界和验证清单。


更具体地说，对每一位即将接手或正在维护 GalibierHub 的人，本文想要留下的核心信息其实只有三条。第一条是：配置、数据和权限的边界比任何单一组件的实现更重要。只要这些边界保持清晰，换物种、换数据源、换部署平台都只是配置层的工作；一旦边界被打散，再小的改动都可能引发跨层回归。第二条是：验证要按完整用户路径来跑，而不是按源文件来跑。只有从浏览器打开站点开始，一路走到 JBrowse 定位、Discussion 留言、下载文件或导出 manifest，才算是真正验证了一条路径。第三条是：文档就是工程的一部分。每当 README 与代码出现偏差时，优先修正文档；每当新增一个环境变量或修改一条 RLS 策略时，把变更写进维护说明。这样做不是因为文档本身有多高级，而是因为后来者最先看到的永远是文档，而不是代码。

最终，GalibierHub 的维护价值不体现在某一次完美部署上，而体现在下一次部署是否还能顺利完成、下一次改动是否还能安全收束上。本文试图保存的正是这种"可接手"的连续性。
只要这四件事抓住了，后续无论是替换物种、改造记录模型、扩展下载策略、调整管理员流程，还是把站点改造成其他研究资源门户，都会稳很多。也正因为如此，本文的目标不是把所有实现细节铺开到无法维护，而是保留真正能帮助下一位维护者快速接手的那部分结构化信息。


==== 2026-08-01 更新

- 登录窗移除 Google OAuth 选项，只保留 GitHub 与邮箱/密码认证；Cloudflare Turnstile 验证继续覆盖登录、反馈、下载与图片上传流程。
- Discussion 点赞改为纯数值展示，不再显示红色爱心；REPLIES 统计已移除，LIKES 与 VIEWS 保持同行。
- 管理员 Moderation Dashboard 已接入列表隐藏、删除、取消隐藏和顶部管理横幅。
- Downloads 的 `Download & CLI` 标签页保留直链、wget、curl 与 CLI 命令的点击展开复制；SHA-256 移入 `Checksum` 标签页展示。
- World Clock 弹窗遮罩加深为 `bg-black/70`，弹窗居中，点击遮罩任意区域关闭。
- 时间线滑条拖动会直接滚动整篇讨论，并继续与浏览器滚动同步；主帖与每条回复的日期均显示。
- Settings 保存后的资料变更会在个人简介卡片、用户菜单与讨论区同步，清空字段也能正确生效。
- `Downloads > Records` 成为 Downloads 的第一个文件夹，按 `Reference_Genomes`、`Variant_Calling_VCF`、`ML_Ready_FASTA` 三个子目录展示 1 个参考 FASTA、1 个 GFF3、12 个样本 VCF 和 12 个样本 FASTA；这些公开测试文件由 FANTOM5 人类原代细胞 CAGE 数据（hg19）转换而来，来源为 https://fantom.gsc.riken.jp/5/ 与 https://www.nature.com/articles/sdata2017112。
- Records 表格新增 `Download` 列，单行可选择 `Download Variant (VCF)` 或 `Download Sequence (FASTA)`；勾选多行后可执行 `Send Selected to Downloads (VCF)` / `Send Selected to Downloads (FASTA)`，目标文件通过 `sessionStorage` 在 Downloads 中自动勾选、高亮并滚动定位。
- Genome Browser 边框与 Records 控件改为网站统一的 slate 配色；User Guide 文案精简；用户菜单新增 Notifications、Replies、Likes、Following 的 `Mark all read` 与 Settings 中的 `View saved profile`；Site uptime 从 2026-08-01 开始计时。
- 徽章管理端修复 `admin_badge_stats` 相关报错，改为直查 `badge_definitions` 与 `user_badges` 聚合统计。

\<div style="text-align: center; margin: 2em 0;"\>
\<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 10" width="200" height="10"\>
\<rect x="0" y="0" width="200" height="10" rx="5" fill="currentColor" opacity="0.1"/\>
\</svg\>
\</div\>
