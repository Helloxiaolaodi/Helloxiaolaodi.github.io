#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "16S rRNA 扩增子分析全流程（QIIME 2 2024.2）",
  description: "面向硕士研究生的 16S 扩增子分析教程：从数据质控、DADA2 去噪、Greengenes2 closed-reference 建 OTU 表与物种注释，到 Alpha/Beta 多样性、系统进化树、PCoA/PCA/NMDS/UPGMA、差异丰度、RDA/CCA 与共发生网络，以 QIIME 2 2024.2 串起完整流程，并给出 R（vegan/SpiecEasi）端复现代码。",
  date: datetime(year: 2026, month: 11, day: 26),
  lang: "zh",
)

= 16S rRNA 扩增子分析全流程（QIIME 2 2024.2）

本教程以 *QIIME 2 2024.2* 为分析环境，采用 *DADA2 去噪*推断 #link(<t-asv>)[ASV]（扩增子序列变体）；在需要跨研究统一特征空间的主线中，进一步把 ASV 通过 *Greengenes2 backbone 做 99% closed-reference mapping*，得到参考库定义的 #link(<t-asv>)[OTU] 特征表。群落组成、#link(<t-alpha>)[Alpha/Beta 多样性]及基于分类单元的比较分析，以该 OTU 表为主要输入；ASV 表与未匹配序列则保留用于序列层面质控、参考库覆盖度评估和 PICRUSt2 等功能预测。

分工原则：*QIIME 2 负责上游——把原始 reads 变成干净的特征表、物种注释、进化树和核心多样性指标；PCA、NMDS、RDA/CCA、Rank-Abundance、UPGMA、LEfSe、网络分析等下游统计与可视化，交给 R 生态或独立工具*。每一步都会标注归属，避免在 QIIME 2 里找一个它本就不提供的命令。

#figure(
  image("imgs/00-pipeline-overview.png"),
  caption: [16S 扩增子整体分析流程总览],
)

#figure(
  image("imgs/amplicon-workflow-xiaoqizheng.png"),
  caption: [扩增子测序数据分析流程　#link("https://xiaoqizheng.github.io/biological_data_analysis/qiime2.html")[https://xiaoqizheng.github.io/biological_data_analysis/qiime2.html]],
)

#figure(
  image("imgs/qiime2-principle-fig1.png"),
  caption: [QIIME 2 架构与原理　#link("https://mp.weixin.qq.com/s/gz2G4RQ3IBF21AYrPRQdIA")[https://mp.weixin.qq.com/s/gz2G4RQ3IBF21AYrPRQdIA]],
)

#figure(
  image("imgs/qiime2-provenance-fig2.png"),
  caption: [迭代记录数据来源确保分析可重复　#link("https://mp.weixin.qq.com/s/gz2G4RQ3IBF21AYrPRQdIA")[https://mp.weixin.qq.com/s/gz2G4RQ3IBF21AYrPRQdIA]],
)

#line()

== 0. 准备工作与分析总览

=== 0.1 版本与环境

本文所有命令以 *QIIME 2 2024.2*（amplicon 发行版）为准。QIIME 2 不能直接在 Windows 上运行，需要在 Linux 服务器、Windows 的 WSL2（Ubuntu）或 macOS 上通过 Conda 安装（安装命令见附录 A）。各版本命令高度一致，个别插件参数会变，遇到报错先 `qiime <插件> <命令> --help` 查看当前版本的真实参数，比背参数更重要。

*适用范围*：Illumina PE 短读长的 #link(<t-16s>)[16S rRNA] 细菌 / 古菌扩增子（#link(<t-region>)[V3–V4 或 V4]）、双端或单端常规数据。*不覆盖*：真菌 ITS（换 UNITE 数据库与 ITSx 流程）、PacBio / ONT 三代全长 16S（无需拼接、建树与分类器策略不同）、shotgun 宏基因组（那是另一套分析框架）。另注意：2024.2 之后 QIIME 2 个别插件的参数有过变动（如 `--show-importable-*` 被移除、python 版本号变化），跑更新版本时以 `--help` 与 docs.qiime2.org/en/stable 为准。

QIIME 2 用两种文件承载数据，理解它们能省掉很多困惑：

#tablem[
  | 后缀 | 含义 | 典型用途 |
  | :--- | :--- | :--- |
  | `.qza` | QIIME 2 Artifact，带类型的「数据」压缩包 | 特征表、代表序列、进化树、分类注释、距离矩阵 |
  | `.qzv` | QIIME 2 Visualization，带类型的「可视化」压缩包 | 汇总表、质量图、柱状图、PCoA 交互图 |
]

`.qza` / `.qzv` 本质都是 zip 包，但*不要手动解压后改内容再塞回去*，否则会破坏校验。查看 `.qzv` 的标准姿势是把文件拖到 #link("https://view.qiime2.org")[view.qiime2.org]，在浏览器里交互式查看（国内镜像 view.qiime2.cn 曾出现 TLS 证书过期，浏览器可能告警，离线环境更稳的是本地部署 QIIME 2 View，见附录 D）；需要进入 R 分析时，再用 `qiime tools export` 导出为 BIOM / TSV / FASTA（见附录 C）。

=== 0.2 三个输入文件

正式跑流程前，手里需要三样东西：

- *原始测序数据*：Illumina 双端，每个样本一对 `*_1.fq.gz` / `*_2.fq.gz`。
- *样本元数据（metadata）*：一个 TSV，第一列是 `#SampleID`（要与数据里的样本名完全一致），其余列是分组、时间、临床变量等。QIIME 2 新版要求首列写成 `#SampleID` 或 `sample-id`。
- *清单文件（manifest）*：把样本名与双端文件路径对应起来，供导入使用。

```bash
# manifest.tsv 长这样（制表符分隔，路径写绝对路径最稳）
# sample-id	forward-absolute-filepath	reverse-absolute-filepath
# S1	/home/you/seq/S1_1.fq.gz	/home/you/seq/S1_2.fq.gz
# S2	/home/you/seq/S2_1.fq.gz	/home/you/seq/S2_2.fq.gz
```

导入为 QIIME 2 对象：

```bash
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path manifest.tsv \
  --output-path demux.qza \
  --input-format PairedEndFastqManifestPhred33V2
```

单端数据要注意：*`SingleEndFastqManifestPhred33V2` 只认两列*（`sample-id` + `absolute-filepath`），三列旧格式与 V2 导入格式不匹配：

```bash
# single-end manifest.tsv 只需两列
# sample-id	absolute-filepath
# S1	/home/you/seq/S1.fq.gz
# S2	/home/you/seq/S2.fq.gz

qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-path manifest.tsv \
  --output-path demux.qza \
  --input-format SingleEndFastqManifestPhred33V2
```

=== 0.3 术语与关键口径 <sec-keyterms>

后面反复出现的术语（16S rRNA 基因、测序深度、Q20/Q30、Good's 覆盖度、ASV/OTU、Bray–Curtis、UniFrac、Faith PD、Chao1、PERMANOVA、稀释曲线、NSTI、SparCC / SPIEC-EASI 等）已统一收录到文末的 #link(<glossary>)[附表：术语]，并在正文首次出现处加内链，点击即可跳转查阅。这里只保留两处最容易混淆、也最影响后续分析的「口径」：

*ASV 与 OTU 要分清四种口径，别混用*：

#tablem[
  | 术语 | 含义 | 主要用途 |
  | :--- | :--- | :--- |
  | ASV | DADA2 基于错误模型推断的精确序列变体 | 高分辨率序列信息；PICRUSt2、数据库覆盖度、未匹配序列分析 |
  | de novo OTU | 本研究数据内部按相似度聚类形成的 OTU | 传统 OTU 分析、不依赖固定参考库的场景 |
  | closed-reference OTU | ASV 按指定相似度映射到固定参考序列，同一参考序列的计数合并 | 跨研究统一特征空间（本教程主线） |
  | open-reference OTU | 先映射参考库，未匹配序列再 de novo 聚类 | 兼顾参考库与未覆盖序列的替代方案 |
]

*99% closed-reference OTU 不等于物种鉴定成功*：它只是把 ASV 归到参考库中最相近的参考序列，分辨率仍受扩增区与参考库覆盖限制。

另一个只差希腊字母、容易混掉的口径——α / β / γ 三个多样性层次（单样本内部 / 样本之间 / 区域整体，各对应哪些指标与章节），一并收在 #link(<t-alpha>)[附表：术语]。

一个常被忽略的量：*样本间测序深度不齐时，直接比较 α 多样性会被深度差异带偏*，所以 *QIIME 2 的常规 Alpha/Beta 流程*会先抽平（rarefy，即 `--p-sampling-depth`）到同一深度再比较。但抽平并非所有下游步骤的通用前提——*差异丰度分析通常使用未抽平的计数表*，由方法自身做归一化或偏差校正（见第 12 节）；`core-metrics-phylogenetic` 输出的抽平表也*不要*直接当作 ANCOM-BC / MaAsLin 的默认输入。

=== 0.4 分析总览与工具分工

#tablem[
  | 分析环节 | 主要工具 | 代表命令 / 函数 | 主要产物 |
  | :--- | :--- | :--- | :--- |
  | 质控与去噪 | QIIME 2（DADA2） | `demux summarize`、`dada2 denoise-paired` | 特征表、代表序列 |
  | 物种注释 | QIIME 2 | `classify-sklearn` | `taxonomy.qza` |
  | 进化树 | QIIME 2 | `align-to-tree-mafft-fasttree` | `rooted-tree.qza` |
  | Alpha 多样性 | QIIME 2 | `core-metrics-phylogenetic`、`alpha-rarefaction` | 多样性向量、稀释曲线 |
  | Beta 多样性 | QIIME 2 + R | `beta-group-significance`、vegan | 距离矩阵、PERMANOVA |
  | PCoA | QIIME 2 | `diversity pcoa` + `emperor plot` | 排序图 |
  | PCA / NMDS / UPGMA | R（vegan / base） | `prcomp` / `rda(~1)`、`metaMDS`、`hclust` | 排序图、聚类树 |
  | 组间差异 | QIIME 2 + R/LEfSe | `composition ancom`、LEfSe | 差异特征、标志物种 |
  | RDA / CCA / db-RDA | R（vegan） | `rda`、`cca`、`capscale`（DCA 选型诊断用 `decorana`，见第 13 节） | 约束排序图 |
  | Rank-Abundance | R | `ggplot2`、`radfit` | 等级丰度曲线 |
  | 网络分析 | R（SpiecEasi）/ Python | `spiec.easi`、`SparCC` | 共发生网络、关键物种 |
]

注意 `vegan::rda()` *无约束时做的就是 PCA*（对 Hellinger 后的矩阵），带约束公式时才是 RDA——二者共享底层算法，但统计含义不同，表里把 PCA 单独写成 `prcomp` 以免混淆。

这条教程的主线是：*导入 → Cutadapt 去引物（按需）→ DADA2 去噪（内置拼接与去嵌合体）→ ASV 特征表 → \[Greengenes2 99% closed-reference → OTU 表\] → 物种注释 → 进化树 → 多样性/排序 → 差异/关联*。方括号一段是本文的跨研究主线，下游以 OTU 表为主、ASV 表作为支线保留。关键文件名建议固定下来（全流程反复引用）：

#tablem[
  | 文件 | 含义 | 主要下游用途 |
  | :--- | :--- | :--- |
  | `table-asv.qza` | DADA2 原始 ASV 计数表 | ASV 支线、PICRUSt2、参考库覆盖度 |
  | `rep-seqs-asv.qza` | DADA2 ASV 代表序列 | closed-reference mapping、序列分析 |
  | `denoising-stats.qza` | DADA2 五阶段统计 | 质控与嵌合体比例评估 |
  | `table-gg2-cr99.qza` | Greengenes2 99% closed-reference OTU 表 | 群落组成、Alpha/Beta、多数 OTU 层面统计 |
  | `rep-seqs-gg2-cr99.qza` | 映射后特征的代表序列（= 命中的 Greengenes2 参考序列本身） | 与 OTU 特征 ID 对应的注释、序列核查 |
  | `unmatched-asvs-gg2.qza` | 未匹配 Greengenes2 的 ASV | 映射率评估、未覆盖序列分析 |
  | `taxonomy-gg2.qza` | 与 closed-reference 表特征 ID 对应的注释（= `2024.09.backbone.tax.qza` 按 ID 对应，在 4.5 直接复制生成） | `taxa collapse`、`taxa barplot` |
  | `tree-gg2.qza` | 与 closed-reference 特征 ID 匹配的树（de novo 生成，或直接用 GG2 参考树，见 6.0） | Faith PD、UniFrac |
]

=== 0.5 实验设计与 Metadata

主线能走多远，取决于 metadata 的设计质量——分组、协变量、配对 / 纵向结构直接决定第 7、12、14 节能建什么统计模型，所以它是*准备工作*的一部分，不是收尾杂项。合格 metadata 至少应含：sample-id（唯一、与特征表严格对应）、Group、Age、Sex、Batch、SubjectID、Time、采样部位、16S 可变区、测序平台。要点：

- 样本 ID 唯一且与特征表严格一致；分类变量*别用数字编码*（`1/2` 会被当连续变量）。
- 缺失值保留 `NA`，*不要主观补值*；原始论文 / SRA 无法确认的字段宁缺勿造。
- 同一受试者、同部位、同时间点的技术重复，是否合并 / 去重必须*预先定义*并记录。
- *Batch（测序批次）必须入表*——后面 PERMANOVA 的 `strata`、模型协变量、随机效应都靠它。
- 建议每个队列留存：原始 manifest、原始论文、整理后 metadata、整理脚本，以及 accession / 下载日期 / MD5 / 软件与数据库版本。

metadata 写好后先自检：用 `qiime metadata tabulate --m-input-file metadata.tsv --o-visualization metadata.qzv` 在 view 里过一眼，确认样本 ID 无重复、分组列无意外取值（`qiime metadata tabulate` 能直接暴露「列被当成数字」「多余空白」这类低级错误）。

=== 0.6 三类核心文件

真正在流程里流转的是三张表：*特征表*（谁在、各多少）、*元数据*（样本怎么分组）、*物种注释*（每个特征是谁）。它们格式与行列方向各不相同，弄反一次，后面所有命令和 R 代码都会*静默*算错。先一次看清「文件类型 / 行 = 什么 / 列 = 什么 / 值 = 什么」：

#tablem[
  | 文件 | 常见类型 | 行 | 列 | 单元格的值 | 用途 |
  | :--- | :--- | :--- | :--- | :--- | :--- |
  | 特征表 | `.qza`（`FeatureTable[Frequency]`）；导出 `.biom` / `.tsv` | feature（ASV 或 OTU 的 ID） | 样本 `sample-id` | 该特征在该样本的 reads *计数*（整数） | 组成、Alpha/Beta、差异丰度、网络的定量输入 |
  | 元数据 | 纯文本 `.tsv`（首列 `#SampleID` 或 `sample-id`） | 样本 | 变量（Group、Age、Batch…） | 该样本该变量的取值（分类或数值） | 分组比较、PERMANOVA/ANCOM 公式、排序着色 |
  | 物种注释 | `.qza`（`FeatureData[Taxonomy]`）；导出 `taxonomy.tsv` | feature | Feature ID / Taxon /（Confidence） | 该 feature 的分类谱系 `k__…;p__…;g__…` 与置信度 | `taxa collapse`、`taxa barplot` |
]

*三者必须共用同一套特征 ID 与同一套 sample-id*。closed-reference 之后，`table-gg2-cr99.qza` 的特征 ID 已变成 Greengenes2 参考序列 ID，只能用同 ID 空间的 `taxonomy-gg2.qza` 注释它，*不能*拿 ASV 的 taxonomy 去 collapse（见 4.5）。

*① 特征表（FeatureTable / BIOM）：一张「特征 × 样本」计数矩阵。* BIOM（Biological Observation Matrix）是存放这张矩阵的标准格式，QIIME 2 用 `.qza` 打包（内部即 BIOM）。导出成 TSV 后大致长这样。*注意首列的长相连两个阶段*——collapse 之前是真实的特征 ID（哈希 / 序列 ID），只有 `taxa collapse` 合并之后才会变成拼接的分类名：

```text
# 原始特征表（collapse 之前；#OTU ID 列是真实的 feature ID）
# Constructed from biom file
#OTU ID	S1	S2	S3
b5f0b7e7a37b6094…	120	0	45
4b0e4a3b01c1d2e3…	30	88	12
7a9c2d5f8e1b3a6c…	0	5	3
```

```text
# 属水平合并后的表（collapse --p-level 6 之后；首列变成拼接的分类名）
# Constructed from biom file
#OTU ID	S1	S2	S3
d__Bacteria;p__Firmicutes;c__Clostridia;…;g__Prevotella	120	3	45
d__Bacteria;p__Bacteroidetes;c__Bacteroidia;…;g__Bacteroides	30	88	12
d__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;…;g__Escherichia	0	5	3
```

- *行 = 特征*（首列是特征 ID），*列 = 样本*，值 = reads 计数。
- 方向陷阱：BIOM 导出的 TSV 是「行=特征、列=样本」，而 vegan 要「行=样本、列=特征」，进 R 前必须 `t()` 转置（附录 C 的 `read_biom_tsv()` 已处理）。
- 首行 `# Constructed from biom file` 是注释行，R 读取需 `skip = 1` 或 `comment.char = "#"`。
- 常用操作：

```bash
qiime feature-table summarize \
  --i-table table-clean.qza --o-visualization table-clean.qzv   # 每样本深度与特征数分布
qiime tools export --input-path table-clean.qza --output-path export/table   # → feature-table.biom
biom convert -i export/table/feature-table.biom -o export/table/feature-table.tsv --to-tsv
```

*② 元数据（Metadata / mapping）：样本的「注释表」。*

```text
#SampleID	Group	Age	Batch
S1	control	23	1
S2	disease	31	1
S3	control	27	2
```

- *行 = 样本*，*列 = 变量*；首列 `#SampleID`（或 `sample-id`）必须唯一、与特征表的列名严格一致。
- 分类变量*不要用数字编码*（`1/2` 会被当连续变量）；缺失值保留 `NA`，不要主观补值。
- 校验：`qiime metadata tabulate --m-input-file metadata.tsv --o-visualization metadata.qzv`，能在 view 里直接看出重复 ID、被误当数字的列、多余空白。
- 它是 PERMANOVA 的 `strata`、ANCOM 的公式、`beta-group-significance` 的 `--m-metadata-column`、R 里排序着色与 `adonis` 的分组来源（见 0.5）。

*③ 物种注释（Taxonomy）：feature → 分类谱系。*

```text
Feature ID	Taxon	Confidence
b5f0b7e7a37b6094…	d__Bacteria;p__Firmicutes;c__Clostridia;…;g__Prevotella	0.99
4b0e4a3b01c1d2e3…	d__Bacteria;p__Bacteroidetes;c__Bacteroidia;…;g__Bacteroides	0.98
```

- *行 = feature*，给出该 feature 的七级谱系 `d__/p__/c__/o__/f__/g__/s__`；`Confidence` 列的数值仅朴素贝叶斯 `classify-sklearn` 提供（其含义见 4.5），consensus 方法输出的是投票一致度（Consensus），含义不同，以导出文件为准。
- 谱系前缀的版本差异：Greengenes2 与 SILVA 138.1 的第一级是 `d__`（domain）；旧库（Greengenes 13_8、旧版 SILVA）则写成 `k__`（kingdom）——见到 `k__` 起头的谱系即可断定注释来自旧版本库。
- 用途：`qiime taxa collapse --p-level N` 把特征合并到门（2）/属（6）等层级；`qiime taxa barplot` 画堆叠柱状图（见第 5 节）。合并后特征 ID 变成拼接的分类名，别再当 ASV ID 用。

一句话记：*特征表说「有多少」、元数据说「怎么分组」、物种注释说「是谁」*；三者 ID 对齐，流程才不出错。

下面逐节展开。

#line()

== 1. 数据质量评估（QC）

下机原始数据（raw reads）里混着低质量碱基、测序接头、残留引物和错误序列。*质控没做好，后面所有统计都是在噪声上做文章*。QC 要做两件事：一是看清数据到底长什么样，二是决定在哪里切、切多少。

=== 1.1 用 demux summarize 看质量

导入后先做一步总览，它会给出每个样本的 reads 数分布，以及按碱基位置绘制的质量分数热图：

```bash
qiime demux summarize \
  --i-data demux.qza \
  --o-visualization demux.qzv
```

在 view.qiime2.org 打开 `demux.qzv`，重点看三样：

- *每个样本的序列数*：样本之间测序量是否悬殊，有没有明显离群样本。
- *质量分数随位置的变化*：通常 3' 端质量会掉，据此决定反向 reads 的截断位置（对应第 2 节的 `--p-trunc-len-r`）。
- *碱基组成*：开头若引物未去干净、GC 异常富集，要警惕。

=== 1.2 去引物（Cutadapt）

DADA2 不会自己「识别并切除」引物——它只是按 `--p-trim-left` 盲切固定长度。*若下机序列里引物还在，而你不知道引物有多长，最稳妥是用 Cutadapt 显式去引物*。常见扩增区的引物如下（写论文时也常需要提供）：

#tablem[
  | 扩增区 | 正向引物（5'→3'） | 反向引物（5'→3'） |
  | :--- | :--- | :--- |
  | V3–V4 | CCTACGGGNGGCWGCAG（341F，17 bp） | GACTACHVGGGTATCTAATCC（805R，21 bp） |
  | V4 | GTGYCAGCMGCCGCGGTAA（515F，19 bp） | GGACTACNVGGGTWTCTAAT（806R，20 bp） |
]

*引物新旧版本要分清*：上表 V4 是较新的 515F-Y / 806R 简并版；文献与官方预训练分类器常用旧版 `GTGCCAGCMGCCGCGGTAA`（515F）/ `GGACTACHVGGGTWTCTAAT`（806R，附录 B 即此版本）。两套都是 19 bp / 20 bp，但结合位点略有差异。*去引物、训练分类器时，一律以你实验实际使用的引物为准*，别混用。

```bash
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences demux.qza \
  --p-front-f CCTACGGGNGGCWGCAG \
  --p-front-r GACTACHVGGGTATCTAATCC \
  --p-discard-untrimmed \
  --o-trimmed-sequences demux-trimmed.qza
```

`--p-discard-untrimmed` 表示「识别不到引物的 reads 直接丢弃」，能有效去掉接头污染和错配序列。去完引物后，用 `demux-trimmed.qza` 进入第 2 节，此时 `--p-trim-left` 可以设 0。

*关键衔接*：一旦跑了 Cutadapt，第 2 节 DADA2 的输入*必须是 `demux-trimmed.qza`*，不能再回到 `demux.qza`，否则去引物结果根本没进入去噪。两种去引物方式（Cutadapt 显式去 vs DADA2 用 `--p-trim-left` 按固定长度盲切）*二选一、不可重复*，否则会把引物区切两次。

=== 1.3 内建质控 vs 公司预处理

很多测序公司交付前已经做过一轮预处理，常见的是「Trimmomatic 去低质量 → Cutadapt 去引物 → USEARCH 拼接 → UCHIME 去嵌合体」这条老流水线。理解它的参数，有助于判断公司给你的「clean data」到底做了什么。以百迈客 v2.6 方法为例：

#tablem[
  | 步骤 | 软件 | 关键参数 | 作用 |
  | :--- | :--- | :--- | :--- |
  | 质量过滤 | Trimmomatic 0.33 | 50 bp 滑动窗口，窗口平均质量 < 20 则切掉窗口后碱基 | 去掉尾部低质量碱基 |
  | 去引物 | Cutadapt 1.9.1 | 最大错配 20%，最小覆盖 80% | 识别并切除两端引物 |
  | 双端拼接 | USEARCH 10 | 最小 overlap 10 bp、overlap 相似性 90%、最多 5 个错配 | 依据重叠区拼接成完整序列 |
  | 去嵌合体 | UCHIME 8.1 | 将 query 切块比对参考库，找两条最优 parents | 剔除 PCR 嵌合体 |
]

而在 *QIIME 2 里，这些步骤大多被 DADA2 一步内建完成*：DADA2 会依据质量参数自己完成质量过滤、拼接、去噪与去嵌合体，并直接给出 ASV（扩增子序列变体）。所以走 QIIME 2 主线时，你不必再单独跑 Trimmomatic/Cutadapt，只需要在第 2 节把 DADA2 的裁剪与截断参数设对即可。若公司已交付 clean data，也可以直接导入后进入去噪。

=== 1.4 质控的评估原则

质控没有统一的合格线。DADA2 去噪完成后，应结合各样本 input、filtered、denoised、merged、non-chimeric *各阶段的序列保留数量与比例*识别异常样本：若个别样本在过滤或拼接阶段明显异常损失，再回看原始质量分布、引物去除情况、目标扩增片段长度与双端重叠长度逐一排查。*不能仅凭整体保留率设一个统一阈值*（例如「低于 20% 就不可信」并不成立）——保留率低可能是参数设置问题，保留率高也不代表数据可靠。方法部分应如实报告各阶段保留情况，必要时画一张按样本的去噪保留率图。

=== 1.5 去宿主与替代质控（可选）

宿主相关样本（肠道、口腔、组织、根际）建议在去噪前先去掉「读段级宿主污染」：`taxa filter-table`（4.5 节）只能去掉已注释成线粒体 / 叶绿体的特征，而 KneadData / Bowtie2 / BWA 能在比对阶段直接剔除宿主 reads，更彻底。*执行顺序务必在导入 QIIME 2 之前*（fastp 质控 → 去宿主 → `qiime tools import`），因为导入后再删 reads 就要回到 manifest 重建了。

```bash
# fastp 一步质控（去接头 + 滑窗质量剪切 + 过滤）
# -q 20：碱基质量阈值；-u 30：一条 reads 中低于阈值的碱基比例上限（30%）
# -n 5：最多 N 碱基；-l 50：过滤后最短长度；--detect_adapter_for_pe：自动探测 PE 接头
fastp -i R1.fq.gz -I R2.fq.gz -o clean_R1.fq.gz -O clean_R2.fq.gz \
  -q 20 -u 30 -n 5 -l 50 --detect_adapter_for_pe -w 16 -h fastp.html

# 建宿主索引后去宿主（以人 GRCh38 为例）
bowtie2-build GRCh38.fa human_db
kneaddata -i clean_R1.fq.gz -i clean_R2.fq.gz -db human_db \
  -o kneaddata_out --threads 16 --remove-intermediate

# 或直接用 BWA-MEM 去宿主，保留未比对 reads
# 注：-f 12 只保留「双端都未比对上宿主」的 pair；若要连「仅一端比对上」pair 中
# 未比对上的那条也留下，改用 -f 4（两种口径都要在方法里写明）
bwa index GRCh38.fa
bwa mem -t 16 GRCh38.fa clean_R1.fq.gz clean_R2.fq.gz \
  | samtools view -bS -f 12 -F 256 - > nonhost.bam
```

FastQC 做单样本质量画像、MultiQC 汇总整批报告；它们与 `demux summarize` 的碱基质量图互补，多样本批次尤其值得先跑一遍 MultiQC 看整体质量是否一致。

#line()

== 2. DADA2 去噪与 ASV 构建

双端测序得到的是两条 reads：正向（R1）与反向（R2），来自同一扩增片段的两端。*拼接（merge）利用两条 reads 在中间的重叠区（overlap）把它们合成为一条完整序列*。在 QIIME 2 中，*拼接、去噪、去嵌合体都在 `dada2 denoise-paired` 一步内完成*——所以本节标题讲「去噪」，而不是把「拼接」当成一个独立主步骤。拼接质量取决于：重叠区够不够长、是否一致、两端质量好不好。

关键参数先讲清楚：

#tablem[
  | 参数 | 含义 | 怎么定 |
  | :--- | :--- | :--- |
  | `--p-trim-left-f` / `-r` | 正向 / 反向 reads 左侧裁掉多少 bp | 用引物长度，把残留引物切掉 |
  | `--p-trunc-len-f` / `-r` | 正向 / 反向 reads 在多少 bp 处截断 | 参考质量图：截在质量开始明显下降之前 |
  | `--p-max-ee-f` / `-r` | 允许的最大期望错误数（expected errors） | 常用 2；越大越宽松 |
  | `--p-trunc-q` | 质量低于该值的碱基视为截断点 | 常用 2（Phred 2） |
  | `--p-min-overlap` | 拼接所需最小 overlap 长度 | 默认 12，重叠短时适当调小 |
  | `--p-n-threads` | 线程数 | 设为可用核心数，0 表示用满 |
]

几个容易踩的点先说在前面：

- *DADA2 自己会拼接，不要再手动 join*。`denoise-paired` 内部完成「去除引物之后的拼接」，你无需、也不应该先跑 `join-pairs`；只有 Deblur / vsearch 路线才需要先 `qiime vsearch join-pairs` 再进各自流程。
- *`--p-trim-left` 用引物长度*。Illumina 下机序列 5' 端常残留引物，把正反向各切掉「引物长度」个碱基最稳（按 1.2 节表：341F/805R 为 17/21，515F/806R 为 19/20）；若已用 Cutadapt 去过引物（第 1.2 节），这里设 0。
- *`--p-trunc-len` 要综合判断，不是只看 #link(<t-q20>)[Q30]*。截断位置应同时考虑：每个碱基位置的质量分布、期望错误数、截断后剩余长度、实际扩增子长度、去引物后正反向有效长度，以及双端拼接所需的最小重叠。*不要把某个固定值（如 250/230）当成通用标准*。
- *拼接的重叠长度要求*：截断后正反向 reads 的重叠要 ≥ `--p-min-overlap`（默认 12 nt）。可用 `L_overlap = L_F + L_R − L_amplicon` 估算重叠（`L_F`、`L_R` 为去引物并截断后的正反向有效长度，`L_amplicon` 为实际扩增片段长度），结果必须不小于所用最小重叠要求。

*两种入口二选一*：若第 1.2 节用 Cutadapt 去过引物，DADA2 输入 `demux-trimmed.qza` 且 `--p-trim-left` 设 0；若没跑 Cutadapt，输入 `demux.qza` 并按引物长度设 `--p-trim-left`。具体数值都必须依据你自己的 `demux.qzv` 质量图调整：

```bash
# 分支 A：已用 Cutadapt 去引物（输入 demux-trimmed.qza，左侧不再裁）
# 示例参数按 V4 单区（扩增子 ≈250 bp）；V3–V4 数据不可照抄，见下方自检
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux-trimmed.qza \
  --p-trim-left-f 0 --p-trim-left-r 0 \
  --p-trunc-len-f 230 --p-trunc-len-r 200 \
  --p-max-ee-f 2 --p-max-ee-r 2 --p-trunc-q 2 --p-n-threads 8 \
  --o-representative-sequences rep-seqs-asv.qza \
  --o-table table-asv.qza \
  --o-denoising-stats denoising-stats.qza

# 分支 B：未跑 Cutadapt（输入 demux.qza，按引物长度切左侧）
# V4（515F/806R）：trim-left 19/20；V3–V4（341F/805R）：trim-left 17/21
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux.qza \
  --p-trim-left-f 19 --p-trim-left-r 20 \
  --p-trunc-len-f 230 --p-trunc-len-r 200 \
  --p-max-ee-f 2 --p-max-ee-r 2 --p-trunc-q 2 --p-n-threads 8 \
  --o-representative-sequences rep-seqs-asv.qza \
  --o-table table-asv.qza \
  --o-denoising-stats denoising-stats.qza
```

*示例数值只适用于 V4 单区，V3–V4 必须重算*：V3–V4 扩增子约 460 bp，若照抄 V4 风格的浅截断（如 230/200 截断再用 17/21 的 trim-left），有效长度只剩约 213+179 = 392 bp，重叠区 = −68 bp，`denoise-paired` 会大面积 merge 失败。V3–V4 需要更深的截断来保住重叠：2×300 数据的典型做法是正向截到 280 bp 左右、反向截到 250 bp 左右（trim-left 17/21，此时 L_F + L_R ≈ 492 bp > 460 bp，约剩 32 bp 重叠）；若 reads 只有 2×250，V3–V4 的拼接余量天然紧张——宁可在质量尚可处少截、用 `--p-max-ee` 收紧质量，也不要把重叠截没。但*不要背任何具体数值*，一律代入你的 `L_amplicon` 自检：

```text
L_F、L_R = min(trunc_len, read_len) − trim_left（去引物并截断后的有效长度）
L_overlap = L_F + L_R − L_amplicon ≥ --p-min-overlap（默认 12 nt），且留 20+ 余量更稳
```

单端数据用 `qiime dada2 denoise-single`（无 `--p-trunc-len-r`、无 `merged` 阶段），输入两列 manifest 导入的 `demux.qza`。

`--p-trunc-len-f/-r` 是最容易设错的地方。*截得太短会丢信息、太靠后又会把低质量碱基带进来*；经验做法是让正向、反向 reads 截断后仍能覆盖足够长的重叠区。跑完后看去噪统计，确认每个样本的「合并后保留比例」是否合理：

```bash
qiime metadata tabulate \
  --m-input-file denoising-stats.qza \
  --o-visualization denoising-stats.qzv
```

`denoising-stats.qzv` 里有 *input → filtered → denoised → merged → non-chimeric 五个阶段*的序列数：filtered 是质量过滤后，denoised 是错误模型校正后，merged 是双端成功拼接，non-chimeric 是去嵌合体后。若某样本从 filtered 到 merged 掉得特别多，通常是 overlap 太短或截断位置不当，需要回看 `demux.qzv` 重新调参。

=== 2.1 R 端等价流程（DADA2 包）

不想用 QIIME 2 时，DADA2 的 R 包是同一套算法。把它走一遍，有助于明白 `denoise-paired` 到底做了什么：

```r
library(dada2)
# fnFs / fnRs：正反向 FASTQ 路径向量；filtFs / filtRs：filterAndTrim 的输出（骨架代码，需先自行定义）
# 1) 看质量：plotQualityProfile(fnFs[1:2])
# 2) 过滤截断：maxEE=2 比「平均质量」更能反映错误累积
#    truncLen 顺序为 (正向, 反向)；数值按你的质量图与引物长度定，见第 2 节自检公式
out <- filterAndTrim(fnFs, filtFs, fnRs, filtRs,
                     truncLen = c(230, 200), maxN = 0,
                     maxEE = c(2, 2), truncQ = 2, rm.phix = TRUE,
                     multithread = TRUE)
# 3) 学错误模型 → 4) 去噪 → 5) 拼接
errF    <- learnErrors(filtFs, multithread = TRUE)
errR    <- learnErrors(filtRs, multithread = TRUE)   # 反向也要单独学一套错误模型
dadaFs  <- dada(filtFs, err = errF, multithread = TRUE)
dadaRs  <- dada(filtRs, err = errR, multithread = TRUE)
mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, verbose = TRUE)
# 6) 建序列表再去嵌合体（consensus 法）
seqtab        <- makeSequenceTable(mergers)
seqtab.nochim <- removeBimeraDenovo(seqtab, method = "consensus", multithread = TRUE)
```

`truncLen` 与 QIIME 2 的 `--p-trunc-len-f/-r` 参数格式对应（向量顺序 F, R，具体数值都按自己数据定）；`maxEE=2` 即 `--p-max-ee`；`removeBimeraDenovo(method="consensus")` 与 DADA2 默认去嵌合体策略一致。两套写法二选一即可，结论应一致。

实际项目常把两者拼起来：先用 QIIME 2 导入并 `demux summarize` 定参数，再切到 R 的 DADA2 环境跑，产出 `ASVs_counts.tsv` 与 `ASVs.fa`（供第 4 节的注释与聚类复用）。一个可用的作业骨架：

```bash
conda activate qiime2-2024.2
qiime tools import --type 'SampleData[SequencesWithQuality]' \
  --input-path manifest.tsv --output-path demux.qza \
  --input-format SingleEndFastqManifestPhred33V2
qiime demux summarize --i-data demux.qza --o-visualization demux.qzv
conda deactivate
module load R/4.1.3
source /path/to/miniconda3/etc/profile.d/conda.sh && conda activate micro
Rscript dada2_YL.r "${file_path}" trim
```

#line()

== 3. 去噪输出审核与特征整理

=== 3.1 嵌合体：已内建，勿重复筛

嵌合体（chimera）是 PCR 中的「拼接错误」：两条不同模板的片段在某处错误接在一起，形成自然界并不存在的「杂合序列」，若不剔除会虚增多样性。*DADA2 的 `denoise-paired` 默认就会去嵌合体*（`--p-chimera-method consensus`），结果反映在 denoising-stats 的 `non-chimeric` 数量上。走 DADA2 主线时，这一步*已经做过*，不必再手动跑一遍。

只有在走 *独立 OTU / vsearch 路线*（ASV 之外另做聚类）时，去嵌合体才需要显式执行：

```bash
qiime vsearch uchime-denovo \
  --i-table table-asv.qza \
  --i-sequences rep-seqs-asv.qza \
  --o-chimeras chimeras.qza \
  --o-nonchimeras nonchimeras.qza \
  --o-stats chimera-stats.qza
```

*不要在 DADA2 去噪之后重复跑 UCHIME*，除非有明确的额外质控目的，并在方法中写清为什么要重复筛查。

=== 3.2 低丰度特征过滤

注意：这一节过滤的是「罕见特征」，*不是按序列长度切短序列*——短序列由去噪阶段的 `--p-trunc-len` / `--p-min-overlap` 控制。下面按「总频数」和「出现样本数」筛特征：

```bash
# 只保留在 ≥2 个样本中出现、且总频数 ≥10 的特征
qiime feature-table filter-features \
  --i-table table-asv.qza \
  --p-min-frequency 10 \
  --p-min-samples 2 \
  --o-filtered-table table-filtered.qza
```

- `--p-min-frequency`：特征在所有样本中的*总丰度阈值*；
- `--p-min-samples`：特征至少出现在多少个样本中；
- 过滤过严会丢掉低丰度但真实存在的类群，过松则残留噪声。阈值需结合 #link(<t-depth>)[测序深度]、研究问题与污染控制结果确定，并*建议做阈值敏感性分析*；文中 `10 / 2` 只是示例，不是普适标准。

`table-filtered.qza` 的定位：它是 *ASV 支线*分析（序列层面 QC、参考库覆盖度评估等）的常规过滤表；主线 cr99 OTU 表在映射前也可先做同样的 `filter-features`（生成 `table-gg2-cr99` 时用过滤后的表作输入），并在结果中如实报告是否过滤、过滤掉多少特征。*下游一旦用上了过滤表，全流程请保持一致*，不要混用过滤前后的两张表。

=== 3.3 ASV 长度分布与非目标序列

- *长度检查*：`qiime feature-table tabulate-seqs` 可看每条 ASV 长度；明显短于预期扩增子（如截断后 ＜200 bp）的多来自接头自连或严重错切，应重点核查。
- *细胞器序列*：16S 通用引物会扩到宿主线粒体 / 叶绿体，需用 `taxa filter-table`（见 4.5）剔除。
- *低生物量样本的试剂污染*：皮肤、组织、低微生物量环境里，提取 / PCR 试剂本身带来的污染会扭曲 Alpha/Beta 多样性。这类「实验污染」与被扩增到的「生物学非目标（线粒体 / 叶绿体）」不同，应结合*阴性对照*用 `decontam` 识别，而不是简单把低丰度特征全当污染删掉。

=== 3.4 对照设置与污染识别（decontam）

- *阴性对照*：DNA 提取空白（extraction blank）与 PCR 空白（PCR negative control），用于识别试剂、耗材与环境带来的污染序列。
- *阳性对照 / Mock Community*：已知组成的菌群混合物，用来验证流程能否正确检出、扩增偏好与去噪是否异常。
- *污染识别*：`decontam`（R 包）用 prevalence（是否在阴性对照中出现）或 frequency（DNA 浓度—丰度关系）建模判定污染特征。示意：`isContaminant(seqtab, method = "prevalence", neg = neg_samples)`。*不能仅凭「低丰度」就认定污染*，也不能不看阴性对照就直接过滤；污染过滤前后应核对样品测序量、特征数与主要结论是否稳定。

#line()

== 4. OTU 与物种注释

=== 4.1 ASV 与 OTU

这是 16S 分析绕不开的概念分歧，也是审稿人会追问的点：

#tablem[
  | 维度 | ASV（扩增子序列变体） | OTU（操作分类单元） |
  | :--- | :--- | :--- |
  | 定义 | 以「精确序列」为单位，逐碱基去噪得到 | 以 97% 相似度聚类，一个 OTU 代表一簇序列 |
  | 产生方式 | DADA2 去噪（本文主线） | vsearch 按相似度聚类 |
  | 优点 | 分辨率高、可跨研究复现、结果可比较 | 概念经典、对测序错误不敏感 |
  | 缺点 | 对测序质量与去噪参数敏感 | 97% 阈值会合并不同物种、结果难跨研究对齐 |
]

*97% 这个阈值的来历*：它来自 DNA–DNA 杂交 reassociation 实验的近似（Stackebrandt & Goebel 1994）——相似度 97% 大致对应 70% 全基因组杂交，传统上视为「同种」。但这个「种」的阈值随扩增区而变：全长 16S 上「种」更接近 99%，而只用 V4 高变区时，甚至一个碱基差异就可能对应不同种（Edgar 2018）；属水平常用 95%，Yarza 2014 又给出 98.5% 作为常见物种界值。所以：

- *ASV（DADA2 / UNOISE）* 不设阈值，直接以真实序列为单位，跨研究可复现，现代首选。
- *OTU 97%* 是历史惯例，便于和旧文献对齐，但会合并近缘种。
- *OTU 99%* 更接近「种」，仍有聚类误差；*ZOTU（UNOISE3）* 是去噪版 OTU，效果接近 ASV。

写论文时，把「用 ASV 还是 97% OTU、为什么」讲清楚，本身就体现方法学素养。

现代推荐用 ASV（DADA2/UNOISE 去噪）。但很多课题、导师和旧流程仍以 OTU 表达，所以两条路都要会。QIIME 2 里从 ASV 转 OTU 只需一步聚类：

```bash
# 在 97% 相似度上对 ASV 序列聚类为 OTU（de novo）
qiime vsearch cluster-features-de-novo \
  --i-table table-asv.qza \
  --i-sequences rep-seqs-asv.qza \
  --p-perc-identity 0.97 \
  --o-clustered-table table-dn-97.qza \
  --o-clustered-sequences rep-seqs-dn-97.qza
```

- *de novo*：不依赖参考库，按数据自身相似度聚类（上面的 97% / 99%），用于传统 OTU 分析。
- *open-reference*：先闭合参考、再对剩下的 de novo，兼顾两者，但耗时。
- *closed-reference*：只保留能比对到参考库的序列，把 ASV 归并到参考特征，*实现跨研究统一特征空间*——这正是本文主线要做的（见 4.2）。

去冗余（`dereplicate-sequences`）是 de novo 聚类的常见前置步骤，可先合并重复序列再加速；所有 vsearch 聚类都应在去嵌合体之后做。

=== 4.2 Greengenes2 99% closed-reference（主线）

为什么 DADA2 之后还要做 closed-reference？因为*不同研究、不同扩增区的 DADA2 ASV 不是同一个特征空间*，无法直接合并比较；把 ASV 映射到固定版本的 Greengenes2 backbone，才能让多个队列落到同一套参考特征上。*注意这是本文跨队列整合的设定，不是所有 16S 项目的强制步骤*——单队列高分辨率分析可以直接用 ASV。

先固定 Greengenes2 2024.09 版本并下载（不要用会随时间变化的 `current` 路径）：

```bash
mkdir -p reference/gg2_2024.09 && cd reference/gg2_2024.09
wget -c https://ftp.microbio.me/greengenes_release/2024.09/2024.09.backbone.full-length.fna.qza
wget -c https://ftp.microbio.me/greengenes_release/2024.09/2024.09.backbone.tax.qza
qiime tools peek 2024.09.backbone.full-length.fna.qza   # 核对类型 / 版本
```

执行 99% 映射（ASV 表 + 代表序列*两个输入都必须给*）：

```bash
qiime vsearch cluster-features-closed-reference \
  --i-table table-asv.qza \
  --i-sequences rep-seqs-asv.qza \
  --i-reference-sequences reference/gg2_2024.09/2024.09.backbone.full-length.fna.qza \
  --p-perc-identity 0.99 --p-threads 8 --p-strand both \
  --o-clustered-table table-gg2-cr99.qza \
  --o-clustered-sequences rep-seqs-gg2-cr99.qza \
  --o-unmatched-sequences unmatched-asvs-gg2.qza
```

要点：
1. *输入必须是一对对应的 DADA2 输出*（`FeatureTable[Frequency]` + `FeatureData[Sequence]`），不能只给序列不给计数表。
2. `--p-perc-identity 0.99` 是与本研究的 Greengenes2 backbone 对齐的设定，*不是所有扩增区通用的阈值*。
3. 映射到同一参考序列的多个 ASV，其样本内 counts 会合并到对应参考特征；未达阈值的 ASV 不进 clustered table，而由 `unmatched-asvs-gg2.qza` 保留。
4. *输出 feature ID 继承参考序列 / 聚类中心 ID，不再是原始 ASV ID*，所以下游 taxonomy、tree 必须换成与新表 ID 对应的版本（见 4.5）。
5. 若上游是 R 版 DADA2 产出的 `ASVs_counts.tsv` / `ASVs.fa`，先用 `biom convert ... --to-hdf5` 转 BIOM、再 `qiime tools import` 成 `table-asv.qza` / `rep-seqs-asv.qza`，再接上面的映射命令。

=== 4.3 映射率与未匹配 ASV

映射率衡量有多少 ASV reads 落到了参考库，是跨队列整合的关键质控。*样本级*定义：

```text
Mapping rate_i = 样本 i 映射成功的 reads / 样本 i 输入 closed-reference 的 ASV reads × 100%
```

把原始 ASV 表与 closed-reference 表都导出为 BIOM/TSV，在 R 中计算（导出的 BIOM TSV 是*行=特征、列=样本*）：

```r
# read_biom_tsv 的定义见附录 C（全流程唯一的公共导入函数，避免两处各写一份将来不同步）
asv <- read_biom_tsv("export/asv/feature-table.tsv")
cr  <- read_biom_tsv("export/cr99/feature-table.tsv")
smp <- intersect(colnames(asv), colnames(cr))
asv <- asv[, smp, drop = FALSE]; cr <- cr[, smp, drop = FALSE]
mapping_qc <- data.frame(
  sample_id = smp,
  input_reads = colSums(asv),
  mapped_reads = colSums(cr),
  mapping_rate = colSums(cr) / colSums(asv)
)
write.table(mapping_qc, "sample_mapping_rate.tsv",
            sep = "\t", quote = FALSE, row.names = FALSE)
```

*未匹配 ASV 不要直接丢*：对 OTU 主线它们不进表，但对「数据库覆盖度 / 新颖类群」分析是宝贵输入（可再用 eHOMD、SILVA、BLAST/VSEARCH 或系统发育放置继续鉴定）。*未匹配 ≠ 新物种*，也可能来自扩增区差异、质量、污染、嵌合体或参考库缺口。

*映射率过低怎么办*：先分原因，再决定补做还是放弃——引物区分与 backbone 不匹配（未匹配大量集中于 V 区两端，回查引物与 backbone 覆盖）；扩增区太偏（换 `2024.09.phylogeny.id.nwk` 对应的 ID 口径或评估 V4 截短序列库）；perc-identity 过严（0.99 是与 backbone 对齐的设定，可在 0.98–0.99 区间做敏感性对比）；数据本身质量差（回看去噪保留率）。*阈值没有行业标准*：单队列项目 mapping rate 低至 30–50% 仍可继续分析 unmatched 部分，但跨队列整合时应把各队列 mapping rate 分布写进结果，并统一阈值设定。

*队列级 QC 是研究特定规则，不是行业标准*：例如整理自某跨队列整合研究的做法——「超过 30% 样本嵌合体比例 >25% 则排除该队列」「排除 mapping rate 为 0 的样本」「队列整体 mapping rate ＜70% 排除该队列」（*该阈值取自作者参与的多队列项目内部约定，未经正式发表，仅作示例，请勿直接引用为文献依据*）。这些可作为多队列整合的示范，但单队列项目不应照搬。建议做一张 QC 汇总表，逐队列记录样本数、去噪成功率、嵌合体比例、mapping rate 分布与最终保留数。

=== 4.4 特征表统计

无论 ASV 还是 OTU，下一步都是看这张「样本 × 特征」的丰度表长什么样：

```bash
qiime feature-table summarize \
  --i-table table-gg2-cr99.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file metadata.tsv

qiime feature-table tabulate-seqs \
  --i-data rep-seqs-gg2-cr99.qza \
  --o-visualization rep-seqs.qzv
```

`table.qzv` 里最有用的是 *Frequency per sample*：记下样本测序量的最小值，它就是后面多样性分析的抽平深度（`--p-sampling-depth`）的候选值。`rep-seqs.qzv` 则展示每条代表序列的长度、ID，序列可一键跳转 NCBI BLAST 比对。

=== 4.5 物种注释与数据库

物种注释是把每条特征序列比对 / 匹配到参考数据库，得到不同分类层级的*预测*。*可靠的分类深度取决于扩增区、参考库覆盖与分类器置信度*：无法可靠区分的近缘物种，应保留在属或更高层级，不要强行解释到种。*数据库选错，注释准确率会明显下降*：

#tablem[
  | 数据库 | 适用 | 说明 |
  | :--- | :--- | :--- |
  | SILVA 138 | 细菌 / 古菌 16S 首选 | 覆盖广、更新及时，2024.2 官方提供配套序列与分类 |
  | Greengenes2 | 细菌 / 古菌（现代） | 与 GTDB 对齐的物理一致框架；本文 closed-reference 主线用它 |
  | GTDB | 细菌 / 古菌（现代分类） | 基于基因组系统发育的新框架，分类更贴近现代标准 |
  | UNITE | 真菌 ITS | 真菌鉴定标准库 |
  | NCBI / RDP | 补充 | 按需使用 |
]

*两个版本陷阱*：① 数据库 / 预训练分类器版本必须与 QIIME 2 版本匹配（对 scikit-learn 版本敏感）；② SILVA 的种水平在短扩增区上常常不可靠，别把 `species` 当成确定鉴定。

*主线（OTU 表）的注释用 Greengenes2 backbone taxonomy*，而不是 SILVA 分类器——`table-gg2-cr99.qza` 的 feature ID 是 Greengenes2 参考序列 ID，直接用同版本 `2024.09.backbone.tax.qza` 按 ID 对应（0.4 关键文件表中的 `taxonomy-gg2.qza` 即是它——直接复制一份或重命名即可，0.4 表与附录 C 都按这个名字引用）：

```bash
cp 2024.09.backbone.tax.qza taxonomy-gg2.qza

# 下方仅演示 collapse 用法（临时名 cr99-l6-demo.qza；正式的 table-gg2-l6.qza 在 5.1
# 从去线粒体/叶绿体后的 table-clean.qza 生成，别在这里重名生成两份）
qiime taxa collapse \
  --i-table table-gg2-cr99.qza \
  --i-taxonomy taxonomy-gg2.qza \
  --p-level 6 \
  --o-collapsed-table cr99-l6-demo.qza
```

*ASV 支线的注释*才用下面的 SILVA 分类器（对 `rep-seqs-asv.qza` 注释，供未匹配序列探索与 PICRUSt2 参考）。QIIME 2 常用两类方法：*朴素贝叶斯 `classify-sklearn`* 快、最常用；*比对一致性 `classify-consensus-blast/vsearch`* 透明可控。差别：

#tablem[
  | 方法 | 命令 | 关键参数 | 特点 |
  | :--- | :--- | :--- | :--- |
  | 朴素贝叶斯 | `classify-sklearn` | `--p-confidence 0.7` | 快、最常用；confidence 越高越保守 |
  | 比对一致性（BLAST） | `classify-consensus-blast` | `--p-maxaccepts 3 --p-perc-identity 0.9 --p-query-cov 0.9 --p-min-consensus 0.51` | 透明可控；取「满足阈值中*最先接受*的 N 条」投票，非全库最相似 N 条 |
  | 比对一致性（vsearch） | `classify-consensus-vsearch` | 同上 | 更快，适合大数据 |
]

先获取 SILVA 参考并训练（或用官方预训练分类器，见附录 B）：

```bash
wget https://data.qiime2.org/2024.2/common/silva-138-99-seqs.qza
wget https://data.qiime2.org/2024.2/common/silva-138-99-tax.qza

qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads silva-138-99-seqs.qza \
  --i-reference-taxonomy silva-138-99-tax.qza \
  --o-classifier silva-138-99-nb-classifier.qza

qiime feature-classifier classify-sklearn \
  --i-classifier silva-138-99-nb-classifier.qza \
  --i-reads rep-seqs-asv.qza \
  --p-confidence 0.7 \
  --o-classification taxonomy-asv.qza
```

*`confidence` 的准确含义*：它表示「*在参考库确实包含该物种的前提下*，模型对该分类的把握」，并不等于「这条序列一定属于这个分类单元」。若真实物种不在参考库里，分类器仍会自信地给出一个最近缘的*错误*分类——所以高 confidence 不是「注释正确」的保证。

官方预训练分类器（按扩增区选，下载即用，见附录 B）：`silva-138-99-515-806-nb-classifier.qza`（SILVA，V4，最常用）、`gg_2022_10_backbone.v4.nb.qza`（Greengenes2 V4，与本文 backbone 主线口径一致）等。注意 *2024.2 官方 data-resources 已宣布 Greengenes2 取代 Greengenes 13_8*，老文件 `gg-13-8-99-515-806-nb-classifier.qza` 仍可下载但属遗留资源，仅在需要兼容旧文献 / 旧 PICRUSt 流程时使用。

`classify-consensus-blast` 的等价命令（更透明，可追溯每条序列投给了哪些参考）：

```bash
qiime feature-classifier classify-consensus-blast \
  --i-query rep-seqs-asv.qza \
  --i-reference-reads silva-138-99-seqs.qza \
  --i-reference-taxonomy silva-138-99-tax.qza \
  --p-maxaccepts 3 --p-perc-identity 0.9 --p-query-cov 0.9 --p-min-consensus 0.51 \
  --o-classification taxonomy-asv-blast.qza
```

如果是宿主相关样本，务必*剔除宿主细胞器序列*——16S 通用引物会扩到宿主线粒体 / 叶绿体（注意这是「生物学非目标」，与 3.4 的试剂污染不同）：

```bash
qiime taxa filter-table \
  --i-table table-gg2-cr99.qza \
  --i-taxonomy taxonomy-gg2.qza \
  --p-exclude mitochondria,chloroplast \
  --p-mode contains \
  --o-filtered-table table-clean.qza
```

此后群落组成（第 5 节）、Alpha/Beta（第 6/7 节）统一使用经过过滤的 `table-clean.qza`（及同 ID 的 `tree-gg2.qza`），*不要一会儿用 ASV 表、一会儿用 OTU 表*。

若需要按样本级条件过滤（分组子集、深度下限等），用 `feature-table filter-samples`：

```bash
# 示例：只保留 control 组样本（--p-where 用 SQLite 语法，字符串要带单引号）
qiime feature-table filter-samples \
  --i-table table-clean.qza \
  --m-metadata-file metadata.tsv \
  --p-where "Group='control'" \
  --o-filtered-table table-control.qza

# 按测序深度过滤（比如剔除 reads < 5000 的样本）
qiime feature-table filter-samples \
  --i-table table-clean.qza \
  --p-min-frequency 5000 \
  --o-filtered-table table-deep.qza
```

*属水平注释的 confidence 阈值建议做敏感性检查*：0.5 / 0.7 / 0.9 各跑一次 `classify-sklearn`，对比属级分类的一致性（阈值越高越保守、Unassigned 越多）；报告时写明所用阈值。

若引物只扩增某个高变区（如 V3–V4、V4），最稳是用*相同引物* `extract-reads` 截取参考区段后再训练（见附录 B）；附录 B 的 V4 `extract-reads` 示例*不适用于 V3–V4 数据*，需换成 V3–V4 引物重新截取。

#line()

== 5. 群落组成分析

有了特征表和分类注释，就可以回答第一个生态学问题：「这群落里都有谁、各占多少」。核心是*把特征表按分类水平合并，再计算相对丰度并可视化*。

=== 5.1 按分类水平合并与相对丰度

```bash
# 合并到门（level 2）与属（level 6）
# 输入用去线粒体/叶绿体后的 table-clean.qza；注释 taxonomy-gg2.qza 见 4.5
# 注意：collapse 后的特征 ID 已是拼接的属名字符串（如 "d__Bacteria;p__..."），
# 后续属水平差异分析请按该形式解读，别再当 ASV ID 用
qiime taxa collapse \
  --i-table table-clean.qza \
  --i-taxonomy taxonomy-gg2.qza \
  --p-level 2 \
  --o-collapsed-table table-gg2-l2.qza

qiime taxa collapse \
  --i-table table-clean.qza \
  --i-taxonomy taxonomy-gg2.qza \
  --p-level 6 \
  --o-collapsed-table table-gg2-l6.qza

# 转成相对丰度（每样本各特征占比之和为 1）
qiime feature-table relative-frequency \
  --i-table table-gg2-l6.qza \
  --o-relative-frequency-table rel-l6.qza
```

分类水平编号：1 域（界）、2 门、3 纲、4 目、5 科、6 属、7 种。

注意 `relative-frequency` 是「逐样本」归一（每个样本各特征占比之和为 1），便于跨样本比较组成，但它*不是*抽平，不改变样本之间的深度差异。*差异丰度分析在第 12 节用未抽平的计数表*；另记住相对丰度只反映组成占比——16S 无法测绝对载量，组间占比变化不能直接解读为绝对丰度变化（见 12.3）；Alpha/Beta 的深度处理按具体指标与方法决定（见第 6/7 节），不要把 `core-metrics` 的抽平表直接拿去做差异分析。

=== 5.2 堆叠柱状图与热图

堆叠柱状图是论文里最常见的「群落组成」图，一眼看出优势类群及其在组间的变化：

```bash
qiime taxa barplot \
  --i-table table-clean.qza \
  --i-taxonomy taxonomy-gg2.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization taxa-bar-plots.qzv
```

在 view.qiime2.org 打开 `taxa-bar-plots.qzv`，可切换分类水平、按分组排序、按某个门降序排列，并导出 SVG 矢量图与 CSV 数据。*正式出图建议导出 CSV 后用 R/ggplot2 重绘*，配色、图例、排序更可控（见第 16 节的设计说明）。

热图适合展示「高丰度类群 × 样本」的分布格局，Krona 圈图则适合交互式、多层级的整体浏览。这两者通常不在 QIIME 2 内一次成图，用导出的相对丰度表在 R 中绘制（`pheatmap` / `ComplexHeatmap`），或使用公司云平台相应模块。

#line()

== 6. Alpha 多样性分析

Alpha 多样性描述*单个样本内部*的物种丰富度与均匀度。它回答「这个样本里有多少种、分布是否均衡」，不回答「两个样本像不像」——后者是第 7 节的 Beta 多样性。

先把 `q2-diversity` 的动作对号入座（下列动作名与指标名均可在本机 `qiime diversity <动作> --help` 核对）：

#tablem[
  | 动作 | 作用 | 典型输入 → 输出 |
  | :--- | :--- | :--- |
  | `core-metrics-phylogenetic` | 一次算 Faith PD / observed_features / Shannon / evenness + 四种 β 距离 + 对应 PCoA | 表 + 有根树 + 抽平深度 + metadata |
  | `core-metrics` | 同上，但不含系统发育指标（无 Faith PD / UniFrac） | 表 + 抽平深度 + metadata |
  | `alpha` / `alpha-phylogenetic` | 计算单个 α 指标（`--p-metric`） | 表（+ 树）→ 向量 |
  | `beta` / `beta-phylogenetic` | 两两样本 β 距离（指定 metric） | 表（+ 树）→ 距离矩阵 |
  | `alpha-group-significance` | 按分组比较 α（Kruskal–Wallis，可两两） | α 向量 + 分类变量 |
  | `beta-group-significance` | 置换检验 β 组间差异（`--p-method permanova/anosim/permdisp`） | 距离矩阵 + 分类变量 |
  | `alpha-rarefaction` | 稀释曲线（多深度 α 曲线） | 表 + 最大深度 + metadata |
  | `pcoa` / `pcoa-biplot` | 主坐标分析（含特征双序图） | 距离矩阵 → PCoA 结果 |
  | `mantel` / `procrustes-analysis` | 两距离矩阵 / 两排序的一致性检验 | 距离矩阵(×2) / PCoA(×2) |
]

常用指标名（`--p-metric`）：α = `shannon`、`simpson`、`chao1`、`observed_features`、`faith_pd`、`pielou_e`、`goods_coverage`；β = `braycurtis`、`jaccard`、`unweighted_unifrac`、`weighted_unifrac`（`beta` 还支持 `aitchison`、`jensenshannon`、`euclidean` 等）。`core-metrics-phylogenetic` 的必填输入是 `--i-table`（`FeatureTable[Frequency]`）、`--i-phylogeny`（`Phylogeny[Rooted]`）、`--p-sampling-depth`、`--m-metadata-file`。

=== 6.0 建树

*#link(<t-faith>)[Faith PD]、#link(<t-unifrac>)[UniFrac] 都依赖进化树，所以它必须在跑 6.1 与第 7 节之前建好*。把建树放在本节开头，目录顺序与实际执行顺序就一致了，不用再「跳到第 8 节建完树再回来」。

标准做法：MAFFT 多序列比对 → 屏蔽高变/低信息区（masking）→ FastTree 建树 → 定根：

```bash
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs-gg2-cr99.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree tree-gg2.qza
```

- *aligned*：多序列比对结果。
- *masked-aligned*：屏蔽比对中信息量低的高变区，避免错误分支。
- *unrooted-tree*：未定根的树。
- *rooted-tree*：定根后的树，*多样性分析用它*。

*closed-reference 主线更推荐直接用 GG2 参考树*：本文 `table-gg2-cr99.qza` 的 feature ID 已是 Greengenes2 backbone ID，直接下载同版本参考树即可（*注意 2024.09 release 里没有 `backbone.nwk` 之类的树文件*，可直接当 `--i-phylogeny` 用的是 phylogeny 系列）：

```bash
wget https://ftp.microbio.me/greengenes_release/2024.09/2024.09.phylogeny.md5.nwk.qza
# 该 .nwk.qza 已是 QIIME 2 artifact（*Phylogeny[Rooted]*，q2-greengenes2 按有根树注册），
# 无需再 import，可直接作 core-metrics-phylogenetic / faith_pd / unifrac 的 --i-phylogeny：
cp 2024.09.phylogeny.md5.nwk.qza tree-gg2.qza
# md5 版面向去冗余 16S 表（cr99 主线）；asv / id 版面向 ASV 表与 backbone ID 表，按需选——
# 别只凭文件名判断版本归属，跑前抽样核对树 tip 与特征表 feature ID 是否同一命名空间
```

用参考树保证 tip 与特征 ID 一一对应、省去建树耗时，且与 backbone 严格一致；de novo FastTree 只作 ASV 支线的备选。另外两点说明：① *「短读长建树深层分支不可靠」只针对 ASV 支线*——cr99 主线的 `rep-seqs-gg2-cr99.qza` 中是命中的 Greengenes2 *全长参考序列*，用它 de novo 建树不踩这个坑；② 若走 de novo 路线且表做过过滤，树的 tip 仍须覆盖过滤后表的每个 feature ID（见下一段），否则会报「feature IDs missing from tree」。

*建树前先确认特征 ID 对齐*：树的 tip 必须覆盖特征表 `table-gg2-cr99.qza` 的*每一个* feature ID（树可多 tip，但不能少）；若做过过滤（如 3.2），要用过滤后的表重建或核对，否则 `core-metrics-phylogenetic` 会报错。*taxonomy、tree、table 三者必须来自同一 release / ID 命名空间*。

建树策略的进一步取舍、IQ-TREE 进阶与 SEPP 片段放置，见第 8 节。

=== 6.1 Alpha 多样性指数

先认识常用指数，避免「只看一个数就下结论」：

#tablem[
  | 指数 | QIIME 2 名称 | 表征 | 怎么读 |
  | :--- | :--- | :--- | :--- |
  | 观测特征数 | `observed_features` | 丰富度（实际看到的物种数） | 越大种类越多 |
  | Shannon | `shannon` | 丰富度 + 均匀度 | 越大多样性越高 |
  | Simpson | `simpson` | 偏向优势类群的多样性 | 需确认软件定义方向 |
  | Chao1 | `chao1` | 估计的真实丰富度（含未测到的） | 越大潜在种类越多 |
  | Faith PD | `faith_pd` | 基于进化树的多样性 | 越大进化多样性越高 |
  | Pielou 均匀度 | `pielou_e`（命令用名；core-metrics 输出列名为 `evenness`） | 均匀度 | 越接近 1 越均匀 |
  | Goods 覆盖度 | `goods_coverage` | 测序覆盖度 | 越接近 1 覆盖越全 |
]

几个指数的定义式（便于理解方向与量纲；`Pi` 为第 i 个类群的相对丰度，`S` 为观测到的类群数，`N` 为总个体数）：

```text
Shannon    H' = -Σ Pi·ln(Pi)
Simpson    D  = 1 - Σ Pi²          # QIIME 2 的 simpson 即此「多样性」方向，越大越多样
Pielou 均匀度 E  = H' / ln(S)
Margalef   R  = (S - 1) / ln(N)
Gleason    R  = (S - 1) / log2(N)  # 离散变体，与 Margalef 只差对数底
Alatalo    Ea = [1/ΣPi² - 1] / [exp(H') - 1]
```

*Gleason 的两种写法不可混用*：上表取的是计数数据常用的离散变体 `(S − 1)/log₂(N)`。Gleason (1922) 的种—面积关系原始形式是 `S/ln(A)`（A 为抽样*面积*），只适用于面积样本；有的手册把 Gleason 直接写成 Margalef 换底（`(S−1)/ln N`）。写方法时注明你用的是哪一种即可，别三式互串。

`core-metrics-phylogenetic` 只算一部分指标（shannon、observed_features、faith_pd、evenness 等）；#link(<t-chao1>)[Chao1]、#link(<t-simpson>)[Simpson] 等要单独算（不同版本可用指标略有差异，以 `qiime diversity alpha --help` 为准）：

```bash
qiime diversity alpha \
  --i-table table-clean.qza \
  --p-metric chao1 \
  --o-alpha-diversity chao1.qza
```

*Faith PD（系统发育多样性）* 不是数物种，而是把「该样本所含类群在进化树上连通的枝长」加起来：`PD = Σ 分支长度`。它需要 6.0 建好的定根树，在 R 里用 `picante::pd(comm, phy, include.root = TRUE)` 也可复算。所以 Faith PD 比「观测物种数」多了一层进化距离信息。

一次性算齐核心 Alpha/Beta 指标的最省事办法是 `core-metrics-phylogenetic`（它需要进化树，见 6.0）：

```bash
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny tree-gg2.qza \
  --i-table table-clean.qza \
  --p-sampling-depth 10000 \
  --m-metadata-file metadata.tsv \
  --output-dir core-metrics-results
```

*`--p-sampling-depth` 会把所有深度低于该值的样本直接剔除*（运行日志有提示，但 qzv 视图里不直观，容易漏看）——它常被当成「穿着归一化外衣的删样本旋钮」。运行前务必在 `table.qzv` 的 Interactive Sample Detail 里确认哪些样本会被丢弃，并在方法部分报告丢弃的样本数与原因。深度选择*没有普适阈值*（不应硬套 90% / 5000 / 10000）：应绘制样本深度分布、计算不同深度下的样本保留数、对比不同深度下 Alpha/Beta 的结果，再定值；并对关键结论做不同深度的敏感性分析。历史经验值（如 1000）来自 454 时代，不可照搬。

*敏感性检查的最小做法*：选 2–3 个候选深度（例如能保留 100% 样本的最大深度、保留 ≥95% 样本的深度、保留 ≥90% 样本的深度），分别跑 Alpha 的 Kruskal–Wallis 与 Beta 的 PERMANOVA，看显著性和效应量*方向*是否稳定。若换深度后结论翻转，就在方法里如实写「结论对抽平深度敏感」，而不是只报某一个深度下漂亮的 P 值。

单看指数意义有限，*组间比较才是重点*。用 `alpha-group-significance` 得到箱线图与 Kruskal–Wallis 两两检验：

```bash
for idx in shannon observed_features faith_pd evenness; do
  qiime diversity alpha-group-significance \
    --i-alpha-diversity core-metrics-results/${idx}_vector.qza \
    --m-metadata-file metadata.tsv \
    --o-visualization core-metrics-results/${idx}-group-significance.qzv
done
```

结果解读要克制：*统计学显著不等于生物学意义大*。同时看箱线图的分布、P 值与效应量，并至少联合观察丰富度与均匀度两类指标。常见论文写法是「与对照组相比，病例组 Shannon 下降，提示均匀度降低；Observed features 无显著差异，提示丰富度变化有限」。

=== 6.2 稀释曲线

#link(<t-rare>)[稀释曲线]（rarefaction curve）回答一个前置问题：*测序深度够不够*。它按不同抽样深度重算多样性，曲线趋于平台说明「再多测也发现不了多少新物种」，此时比较 Alpha 多样性才可靠。

```bash
qiime diversity alpha-rarefaction \
  --i-table table-clean.qza \
  --i-phylogeny tree-gg2.qza \
  --p-max-depth 20000 \
  --p-metrics shannon observed_features faith_pd \
  --m-metadata-file metadata.tsv \
  --o-visualization alpha-rarefaction.qzv
```

默认在每个深度重复抽样若干次（`--p-iterations`，默认约 10 次）来画误差条，深度点越多曲线越平滑。*别和「物种累积曲线」混淆*：这里的稀释曲线是*固定样本、改抽 reads 深度*，回答「单样本还要测多深」；而物种累积曲线是*改样本数量*，回答「还要采多少样本能发现多少 taxa」，在 R 里用 `vegan::specaccum`。进阶做法（参见某些样本累积分析手稿）是对 1 到 N 个样本的每个规模随机抽样多次（如 150 次），统计独特 taxa 数、取均值，再用 `mgcv` 的 GAM（`y ~ s(x, bs = "cs")`）平滑——这是样本累积曲线，与 `alpha-rarefaction` 不是一回事。

`--p-max-depth` 一般取样本测序量最大值（若最大值是离群值，取第三四分位数到最大值之间的合理值）。在 `alpha-rarefaction.qzv` 里切换指数即可看到各分组随深度变化的曲线。*曲线未达平台时，不要急着解读组间 Alpha 差异*，因为差异可能只是测序量不同造成的。

#line()

== 7. Beta 多样性分析

Beta 多样性描述*样本之间*的群落差异，是「分组有没有意义」的核心证据。它先算样本两两之间的距离矩阵，再做排序（第 10、14 节）与统计检验（本节）。

=== 7.1 距离指标选择

#tablem[
  | 距离 | QIIME 2 名称 | 是否用进化树 | 是否加权丰度 | 特点 |
  | :--- | :--- | :--- | :--- | :--- |
  | Bray–Curtis | `braycurtis` | 否 | 是 | 生态学最常用，敏感于丰度 |
  | Jaccard | `jaccard` | 否 | 否 | 只看有无，不看多少 |
  | 加权 UniFrac | `weighted_unifrac` | 是 | 是 | 结合进化关系与丰度 |
  | 非加权 UniFrac | `unweighted_unifrac` | 是 | 否 | 结合进化关系、只看有无 |
]

注意 `--p-metric` 传的是 *`braycurtis`（无下划线）*；`bray_curtis_…` 只是 `core-metrics-phylogenetic` 输出*文件名*的前缀，别当成指标名（下文命令引用的是文件名，与此表不矛盾）。

*β 距离指数也有解析式*（`a` 为两样本共有类群，`b`/`c` 为各自独有；`S` 为总类群数；`α_mean` 为平均样本内多样性）：

```text
Bray–Curtis     BC_ij = Σ_k |x_ik − x_jk| / Σ_k (x_ik + x_jk)   # 定量丰度形式
Jaccard         J  = (b + c) / (a + b + c)                       # 定性，只看有无
Whittaker βw    βw = S / α_mean - 1
Cody βc         βc = [g(H) + l(H)] / 2                          # g=增益物种，l=丢失物种
Wilson–Shmida   βT  = [g(H) + l(H)] / (2·α_mean)
```

注意上式的 Bray–Curtis 是*定量形式*（对丰度求和），`(b+c)/(2a+b+c)` 只是它在「只看有无」时的二元特例，不能直接当通用公式。

R 里用 `vegan::vegdist` 一次性算好距离矩阵。记住 *BIOM 导出的是「行=特征、列=样本」*，要先转成 `comm`（行=样本、列=特征，见附录 C），且 Jaccard 若要纯 presence/absence 必须显式 `binary = TRUE`：

```r
library(vegan)
# comm：行=样本、列=特征（见附录 C）
comm_rel <- decostand(comm, method = "total")
d_bc <- vegdist(comm_rel, method = "bray")                 # 定量 Bray–Curtis
d_jd <- vegdist(comm, method = "jaccard", binary = TRUE)   # 只看有无
d_bc                                                        # 下三角距离矩阵
```

经验：*一般同时报告 #link(<t-bc>)[Bray–Curtis] 与 unweighted UniFrac*，前者看丰度格局，后者看进化层面的「有无」。UniFrac 需要 6.0 建好的进化树，因此 `core-metrics-phylogenetic` 会把四种距离矩阵一次性算好，输出在 `core-metrics-results/` 下。

=== 7.2 组间差异检验（PERMANOVA 等）

有了距离矩阵，用 `beta-group-significance` 检验分组对群落结构的解释力：

```bash
qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/bray_curtis_distance_matrix.qza \
  --m-metadata-file metadata.tsv \
  --m-metadata-column Group \
  --p-method permanova \
  --p-pairwise \
  --o-visualization core-metrics-results/bray-curtis-Group-permanova.qzv
```

`--p-method` 可选 `permanova`（默认，常用）、`anosim`、`permdisp`。*PERMDISP 不是可选项，而是 PERMANOVA 的标准配套检查*：先看 PERMDISP，若显著（组内离散度不一致），PERMANOVA 的组间差异就可能只是「组内离散度不同」造成的，不能直接归因于群落组成变化。结果含组间距离分布箱线图与两两比较的 P 值 / Q 值。*QIIME 2 的 PERMANOVA 输出不含 R²*——`beta-group-significance --p-method permanova` 报告的是*伪 F 统计量*、样本数、组数、P 值与置换次数；R²（分组解释的方差比例）要用 `qiime diversity adonis`（R 端 vegan::adonis 的封装）或 R 端 `adonis2` 补算：

```bash
# R² 用 adonis 拿（多协变量 / 顺序检验也走它；结果含 R² 与 P）
qiime diversity adonis \
  --i-distance-matrix core-metrics-results/bray_curtis_distance_matrix.qza \
  --m-metadata-file metadata.tsv \
  --p-formula "Group" \
  --o-visualization core-metrics-results/bray-curtis-adonis.qzv
```

三种检验的分工与统计量：

#tablem[
  | 方法 | 统计量 | 取值范围 | 含义 |
  | :--- | :--- | :--- | :--- |
  | PERMANOVA | 伪 F | ≥ 0 | 组间 / 组内离差比，越大组间差异越强（QIIME 2 报这个；R² 用 adonis 补） |
  | Adonis / adonis2 | R² | 0 – 1 | 分组因素解释的方差比例，越大越强 |
  | ANOSIM | R | -1 – 1 | 组间 / 组内差异的相对大小，越近 1 越强 |
  | PERMDISP | F / P | — | 组内离散度是否一致（方差齐性检查） |
]

这些在 R 里用 `vegan` 也能方便地交叉验证：

```r
library(vegan)
# meta：已按附录 C 的统一导入模块就绪，与 comm 样本顺序对齐
adonis2(d_bc ~ Group, data = meta, permutations = 999)    # 报 R² 与 P（PERMANOVA 的 R² 从这里拿）

# 有测序批次时：把 Batch 显式放进模型（或限定置换都在批次内进行）
adonis2(d_bc ~ Group + Batch, data = meta, permutations = 999)
adonis2(d_bc ~ Group, data = meta,
        permutations = how(nperm = 999, blocks = meta$Batch))  # 批次内置换
anosim(d_bc, grouping = meta$Group, permutations = 999)   # 报 R 与 P

# Mantel 检验：群落距离与环境因子距离是否共变（见第 13 节时常用）
# mantel(d_bc, dist(env), permutations = 999)

# PERMDISP：组内离散度（PERMANOVA 的前置检查）
bd <- betadisper(d_bc, meta$Group)
permutest(bd, permutations = 999)                         # 显著 → 组内离散度不一致
plot(bd)
```

*报告规范（先看 PERMDISP）*：解读时先看 PERMDISP 的 P 值。若 PERMDISP 不显著，才能把 #link(<t-permanova>)[PERMANOVA] 的伪 F（或 adonis 的 R²）解释为「组间群落组成差异」；若 PERMDISP 显著，则必须说明「组间离散度也不一致」，PERMANOVA 的显著不能单纯归因于组成变化。一个可直接套用的写法：「PERMANOVA 显示 Group 显著（伪 F=…，P=…，`qiime diversity adonis` R²=…）；PERMDISP 亦显著（P=…），提示组间组内离散度不一致，组间差异需结合离散度差异一并解读。」

#line()

== 8. 系统进化树分析

进化树在 16S 分析里不是「配角」：*Faith PD、UniFrac 都依赖它*。建树命令已在 *6.0* 给出（放在 Alpha/Beta 之前，目录顺序与执行顺序一致）；本节讨论*建树策略怎么选*，以及树的查看与美化。

=== 8.1 建树策略：de novo vs 参考树 vs SEPP

主线用 6.0 的 FastTree（或 GG2 同版本参考树）即可，绝大多数分析够用。要不要升级：

- *IQ-TREE 进阶*：在比对基础上用 IQ-TREE 建树，精度更高但更慢，非每个数据集必做：

```bash
qiime phylogeny iqtree \
  --i-alignment aligned-rep-seqs.qza \
  --p-n-cores 8 \
  --o-tree iqtree-unrooted.qza
# 注意：iqtree 只输出未定根树；用于 core-metrics-phylogenetic（UniFrac/Faith PD）前必须定根：
qiime phylogeny midpoint-root \
  --i-tree iqtree-unrooted.qza \
  --o-rooted-tree iqtree-tree.qza
# 更省事：直接用同输出的 pipeline `align-to-tree-mafft-iqtree`（一并给出 rooted tree）
```

- *短读长 de novo 建树的局限*：从 250–460 bp 的 ASV de novo 建树，深层分支不可靠，会传导到 Faith PD 与 UniFrac。
- *更稳的现代替代*：*SEPP 片段插入到参考树*（如 Greengenes2 参考树）或直接用 Greengenes2 放置。本文 closed-reference 主线本就推荐用 GG2 同版本参考树（见 6.0），正是为此；de novo FastTree 只作 ASV 支线备选。

=== 8.2 树的查看与美化

`tree-gg2.qza` 可直接用于 UniFrac/Faith PD；若要在论文中展示，把它导出为 Newick，再在 #link("https://itol.embl.de")[iTOL] 网页端或 R 的 `ggtree` 中加注释、着色、加图例：

```bash
qiime tools export \
  --input-path tree-gg2.qza \
  --output-path export/tree
# 导出后得到 export/tree/tree.nwk，可直接上传 iTOL 或用 ggtree 读取
```

#line()

== 9. Rank-Abundance 分析

等级丰度曲线（Rank-Abundance Curve）用一张图同时讲两件事：*横轴的长度=丰富度，曲线的陡缓=均匀度*。物种多则曲线向右延伸得长；分布均匀则曲线平缓；少数类群独大则曲线陡降。

QIIME 2 不直接出这张图，标准做法是在 R 里用相对丰度表绘制：

```r
library(ggplot2)

# comm：行=样本、列=特征，已按附录 C 的统一导入模块就绪

# 取一个样本，按相对丰度降序排列后编号
x <- sort(as.numeric(comm["S1", ]) / sum(comm["S1", ]), decreasing = TRUE)
df <- data.frame(rank = seq_along(x), abundance = x)

ggplot(df, aes(rank, abundance)) +
  geom_point(size = 1.5) +
  scale_y_log10() +
  labs(x = "物种等级 (rank)", y = "相对丰度 (log10)") +
  theme_bw()
```

若要做模型拟合（比较对数正态、几何级数、断棍等分布），`vegan::radfit()` 可对每个样本拟合 rank-abundance 模型，用 AIC 选最优。

多组比较时，把每个样本各画一条曲线，用颜色区组，即可直观看出哪一组更丰富、哪一组更均匀。

#line()

== 10. PCoA 与 PCA

PCoA 和 PCA 都是「降维排序」：把高维的样本关系压到二维平面，让*图上点与点的远近尽量反映样本的真实差异*。两者常被混用，区别必须讲清：

#tablem[
  | 维度 | PCoA（主坐标分析） | PCA（主成分分析） |
  | :--- | :--- | :--- |
  | 输入 | 距离矩阵（任意距离：Bray、UniFrac…） | 原始丰度矩阵（经标准化/变换） |
  | 是否用进化信息 | 取决于距离（UniFrac 用） | 不用 |
  | 坐标轴括号百分比 | 该轴解释的样本差异比例 | 该主成分解释的方差比例 |
  | QIIME 2 是否直接支持 | 是（emperor） | 非内建，通常用 R |
]

=== 10.1 PCoA：QIIME 2 原生

`core-metrics-phylogenetic` 已经为每种距离生成了 PCoA 结果与交互式 emperor 图，例如 `bray_curtis_emperor.qzv`、`unweighted_unifrac_emperor.qzv`。若要单独重算：

```bash
qiime diversity pcoa \
  --i-distance-matrix core-metrics-results/bray_curtis_distance_matrix.qza \
  --o-pcoa core-metrics-results/bray_curtis_pcoa_results.qza

qiime emperor plot \
  --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization core-metrics-results/bray_curtis_emperor.qzv
```

在 emperor 的 3D 交互图里，按分组着色、设置点大小透明度，再导出 SVG+图例。*坐标轴括号里的百分比就是解释率*，它告诉你这一轴能代表多少真实差异。

=== 10.2 PCA：R 端复现

PCA 直接在丰度矩阵上做，常用 Hellinger 变换降低「大量零值」的影响，再求主成分：

```r
library(vegan)

# comm：行=样本、列=特征，已按附录 C 的统一导入模块就绪（全零特征已去掉）

# Hellinger 变换后做 PCA；rda() 不带公式（或显式 ~ 1）即为 PCA
pca <- rda(decostand(comm, method = "hellinger") ~ 1)
# 等价写法：prcomp(decostand(comm, "hellinger"))，即 scale. = FALSE（rda 默认只中心化）
# 千万别写成 scale. = TRUE：那是「相关型 PCA」，等价于 rda(..., scale = TRUE)，
# 与 rda 默认的「协方差型 PCA」结果不同
# 切记：不带公式 / ~ 1 才是 PCA；写成 ~ 环境因子 就变成 RDA 了

sc <- scores(pca, display = "sites", choices = 1:2)
plot(pca, type = "n")
points(sc, pch = 21, bg = "steelblue")
```

出图时同样要在坐标轴标注解释率，并用颜色区分分组。*概念提醒*：`rda()` 无约束（不带 `~ 因子`）时做的是 PCA，带约束公式时才是 RDA——二者共享同一底层算法，但统计含义不同。另外，PCA 与 PCoA *不要求结论一致*：它们输入不同（丰度矩阵 vs 距离矩阵）、假设不同，结果差异本身需要解释，而不是强行对齐。

#line()

== 11. UPGMA 聚类分析

UPGMA（非加权配对平均法）是一种层次聚类：*每次把距离最近的两个对象并成一簇，用组间平均距离继续合并*，最终形成一棵样本聚类树。它和 PCoA 是「一体两面」——都基于距离矩阵，一个用坐标展示，一个用树形展示。QIIME 2 不直接提供样本 UPGMA，用 R 实现：

```r
library(vegan)
library(ape)

# comm：行=样本、列=特征，已按附录 C 的统一导入模块就绪
comm <- decostand(comm, method = "total")       # 可选：先转相对丰度
d    <- vegdist(comm, method = "bray")          # 样本间 Bray-Curtis 距离

hc <- hclust(d, method = "average")             # average linkage = UPGMA
plot(as.dendrogram(hc), horiz = TRUE, hang = -1)
```

`method = "average"` 就是 UPGMA；换成 `"ward.D2"`、`"complete"` 则是其他聚类策略。若想评估分枝的可靠性，可加 `pvclust` 做 bootstrap 支持率；出图用 `ggtree` 或 `dendextend` 比基础绘图更方便与堆叠柱状图拼合。发表时常用「左侧聚类树 + 右侧物种堆叠柱状图」的组合图（R 里 `aplot` / `patchwork` 可拼），一眼看出聚类分枝与群落组成是否对应。

#line()

== 12. 差异丰度分析

前面几节回答「整体结构是否不同」，本节回答「*到底哪些物种/特征在组间显著不同*」。这是论文创新点的富矿，也是统计最容易出问题的地方——*只报 P 值不校正多重比较，结论不可靠*。

=== 12.1 ANCOM / ANCOM-BC

16S 数据是组成型（compositional）数据，各组丰度之和固定，普通 t 检验会失真。ANCOM 与 ANCOM-BC 专为此设计。先按属水平合并，再检验：

```bash
# ANCOM：先加伪计数，避免 log(0)
qiime composition add-pseudocount \
  --i-table table-gg2-l6.qza \
  --o-composition-table comp-l6.qza

qiime composition ancom \
  --i-table comp-l6.qza \
  --m-metadata-file metadata.tsv \
  --m-metadata-column Group \
  --o-visualization ancom-l6.qzv

# ANCOM-BC：直接建模，给出 log fold change 与校正后 P 值
# ancombc 输出 FeatureData[DifferentialAbundance] Artifact；QIIME 2 不提供该 Artifact
# 的内置 qzv 可视化：用 composition tabulate 转成含 lfc/p/q 的表，或 da-barplot 出图，
# 再导出 TSV 进 R。注意 q2 把 R 侧 p_adj_method 暴露为 --p-p-adj-method（默认 holm），
# 要与全文 BH 统一需显式传参；确切拼写以 qiime composition ancombc --help 为准
qiime composition ancombc \
  --i-table table-gg2-l6.qza \
  --m-metadata-file metadata.tsv \
  --p-formula "Group" \
  --p-p-adj-method BH \
  --o-differentials ancombc-l6.qza

# 把差异丰度 Artifact 转成含 lfc/p/q 的表 qzv（参数名以本机 --help 为准）
qiime composition tabulate \
  --i-data ancombc-l6.qza \
  --o-visualization ancombc-l6.qzv

# 需要控制协变量（如 BMI、Age、Batch）时：QIIME 2 的 ancom 不支持协变量，
# 把协变量写进 ancombc 的 --p-formula（如 --p-formula "Group + BMI + Age"），
# 或直接切到 12.3 的 R 端 ancombc2（支持固定 + 随机效应与 structural zeros 检测）
```

*一个真实结果长什么样*：以刘永鑫教程的测试数据为例，ANCOM 在属水平表中只检出 *1 个*显著差异属（*Pleomorphomonas*）。属水平差异类群少是常见现象，但要先确认*样本量与检验力是否足够*——若样本量小、测序深度低，「只检出 1 个」可能只是检验力不足，而不是真的没有差异；怀疑时用 ANCOM-BC2 / LinDA 做敏感性分析，而不是直接接受「差异少」的结论。

ANCOM 的原理建立在「类群之间两两 log 比值」的 Aitchison 思想上：它不假设绝对丰度，只看类群之间的相对关系，所以特别适合 16S 这种组成型数据；`add-pseudocount` 是给零值加一个极小伪计数，避免 `log(0)`。

结果以差异条形图（显著类群按 W 值排序展示）呈现，ANCOM 不输出火山图，别按火山图找结果；需结合 `taxonomy.qzv` 把特征 ID 翻译成物种名。*建议在属水平做差异分析*，结果更容易做生物学解释。

=== 12.2 LEfSe 与 Metastats

- *LEfSe*：线性判别分析 + 效应量，专门找「标志物种（biomarker）」。它不在 QIIME 2 内，用独立命令行或 Galaxy/Huttenhower 网页版。核心参数：logarithmic LDA score 阈值 4.0；分组数 ≥2 且每组样本 ≥2。
- *Metastats*：逐特征做组间检验（t 检验/Wilcoxon），P 值校正得 Q 值。可在 R 中自行实现，或用公司流程。

```bash
# LEfSe 输入不是 QIIME 的 BIOM 表，必须转成 LEfSe 格式（行为特征、列为样本，class 列放第一列）
# 当前版本（SegataLab/lefse）的命令都带 lefse_ 前缀：
lefse_format_input.py otu_table.txt otu.in -c 1 -o 1000000
lefse_run.py otu.in otu.res -l 4.0
lefse_plot_cladogram.py otu.res lefse.cladogram.pdf          # 可选：圈图
lefse_plot_res.py otu.res lefse.png                          # 结果条形图
```

参数归属（从 SegataLab/lefse 源码核对，*容易装成旧版时混淆*）：

- `-c`（class 列号，整数从 1 起）、`-s`（subclass）、`-u`（subject）、`-f c|r`（features 按行 r / 按列 c 布局，*默认 r*）、`-o`（归一化数值，默认 1e6）——这些*全属于 `lefse_format_input.py`*。
- `lefse_run.py` 的 `-l`（LDA 阈值）*默认 2.0*，`-l 4.0` 是惯例的显式收紧；它自己的 `-f` 是 bootstrap 子采样比例（默认 0.67），*别*把格式化那步的 `-f r` 放到 run 步——传进去会被静默当成 0.67 而不报错。
- 旧版教程里的 `run_lefse.py` / `plot_res.py`（无前缀命令名）与新版并不通用，import 报 `command not found` 时先看装的是哪个版本。

跑之前先用 QIIME 把特征表/注释导出成 LEfSe 可读的纯文本表，并确认分组列的位置。

方法对比与选用建议：

#tablem[
  | 方法 | 优点 | 适用 | 归属 |
  | :--- | :--- | :--- | :--- |
  | ANCOM-BC | 组成型数据、可解释 | 多组、丰度差异 | QIIME 2 |
  | LEfSe | 找标志物种、效应量排序 | 组间 biomarker | 独立工具 |
  | Metastats | 简单直观 | 两组丰度比较 | 独立 / R |
  | Wilcoxon / Kruskal | 非参数、稳健 | 两组 / 多组 | R |
]

*务必做多重检验校正（FDR/BH），并如实报告 P 值、Q 值与效应量*；没有统计学意义的结果，不要包装成结论。

=== 12.3 其他差异丰度方法

ANCOM-BC 之外，主流还有几种，假设不同、可互为校验：

#tablem[
  | 方法 | 原理 | 适用 |
  | :--- | :--- | :--- |
  | ANCOM-BC2 | 偏差校正，直接估计绝对丰度级倍数变化 | 组成型、控制假阳性 |
  | MaAsLin3 | GLM + 固定 / 随机效应 | 多协变量、纵向 / 多中心 |
  | LinDA | 对 CLR 变换后的数据拟合线性模型 + 组成效应偏差校正，渐近 FDR 控制 | 速度快、FDR 控制好 |
  | metagenomeSeq | 零膨胀高斯（ZIG） | 零值多的稀疏数据 |
]

```r
library(ANCOMBC)
# 注意：ANCOMBC::ancombc2() 是 R 包里的 ANCOM-BC2，与 12.1 的 QIIME2 `composition ancombc`
# 不是同一个函数；ANCOM-BC2 默认校正方法是 holm，这里显式改成 BH 以便与全文统一
ancombc2(data = physeq, fix_formula = "Group + BMI + Age",
         p_adj_method = "BH", group = "Group")
library(maaslin3)
maaslin3(input_data = feat, input_metadata = meta,
         output = "maaslin3_out", formula = "~ Group + age + BMI")
```

*多方法共识（强烈建议）*：同一张特征表用 ANCOM-BC2 / LinDA / MaAsLin3（MaAsLin2 为稳定旧版；或 ALDEx2）各跑一遍，结果往往*显著类群重叠但并非一致*。可靠做法是取*至少两个组成型方法方向一致、且各自 BH 校正后仍显著（q ≤ 0.05）*的类群作为「共识差异特征」，而不是只跑一个工具就下结论。

安装方式提醒：ANCOMBC 与 maaslin3 *都不在 CRAN*，均走 Bioconductor（`BiocManager::install(c("ANCOMBC", "maaslin3"))`）；别用 `install.packages()` 硬装。

*可操作的最小共识模板*：对每个特征，若*至少两个方法*在 BH 校正后均显著（q ≤ 0.05），且 log fold change 的*方向一致*，才列入「共识差异特征」；只在一个方法中显著的，作为「方法特异性候选」单独报告。这样比取三方法严格交集更稳健——三者都显著的交集往往过小，「两方法方向一致」在敏感性与可重复性之间更平衡。同时务必区分*相对丰度变化≠绝对丰度变化*——16S 无法推断绝对载量，除非有 qPCR 或 spike-in 锚定。文中 12.1 用 QIIME 2 命令入门，复杂设计（协变量、纵向、随机效应）请切到 R 的 `ANCOMBC::ancombc2()`。

若要做「标志物 + 诊断模型」，可接 `caret`（交叉验证训练）、`Boruta`（随机森林 shadow features 选特征）、`pROC`（ROC / AUC）；样本量小时务必用分层交叉验证并做外部验证，避免过拟合。

#line()

== 13. RDA / CCA 分析

当你有*环境因子*（pH、有机质、温度、临床指标等）时，就需要回答「哪些因子驱动了群落结构变化」。RDA（冗余分析，基于线性模型）与 CCA（典范对应分析，基于单峰模型）是两类约束排序，把「物种组成」回归到「环境因子」上。QIIME 2 不做这一步，用 R 的 `vegan`：

=== 13.1 先做 DCA，再选 RDA 还是 CCA

选错模型会误导结论。先做去趋势对应分析（DCA），看第一轴的梯度长度（Lengths of gradient）：

#tablem[
  | 第一轴梯度长度 | 选用模型 |
  | :--- | :--- |
  | > 4.0 | CCA |
  | 3.0 – 4.0 | RDA 或 CCA 均可 |
  | < 3.0 | RDA 更好 |
]

*限定条件*：这套梯度长度阈值是*在原始物种多度数据上*的经验规则；对 Hellinger 变换后的矩阵或 ASV 表，轴长的「长度」含义会变，别把阈值当硬判据，仅作参考。环境因子多于 5–6 个时，*不要直接 `~ .`*，先用 `ordistep` / `ordiR2step` 做前向选择，再用 `vif.cca` 查共线。

```r
library(vegan)

# comm：行=样本、列=特征，已按附录 C 的统一导入模块就绪（全零特征已去掉）
env  <- read.delim("env.tsv", row.names = 1, comment.char = "")
env  <- env[rownames(comm), , drop = FALSE]      # 环境表按同样本顺序对齐

dca <- decorana(comm)
dca                                              # 看 DCA1 的 Axis lengths

# 线性模型选 RDA：先 Hellinger 变换
rda_mod <- rda(decostand(comm, "hellinger") ~ ., data = env)
anova(rda_mod, permutations = 999)               # 整体显著性
anova(rda_mod, by = "term", permutations = 999)  # 逐项：顺序检验，受变量进入顺序影响
anova(rda_mod, by = "margin", permutations = 999) # 边际检验：考虑其他项之后的独立贡献

# 环境因子多时先做前向选择，再查共线
rda_sel <- ordiR2step(rda(decostand(comm, "hellinger") ~ 1, data = env),
                      scope = formula(rda_mod), permutations = 999)
vif.cca(rda_sel)

# 单峰模型选 CCA
cca_mod <- cca(comm ~ ., data = env)
anova(cca_mod, permutations = 999)
```

若距离非欧氏（如想用 Bray-Curtis），用 `capscale()` 做 *db-RDA（基于距离的冗余分析）*——它是 RDA 在任意距离上的推广，写法与 `rda()` 一致但接受 `dist`：
```r
db_rda <- capscale(vegan::vegdist(comm, "bray") ~ ., data = env)
anova(db_rda, permutations = 999)
```

=== 13.2 解读与出图

- *解释率*：约束轴括号里的百分比，表示该轴在「被环境因子解释的那部分」差异中的占比；整体 `R²`（`RsquareAdj`）才是环境因子对总差异的解释度，别混淆。
- *因子箭头*：箭头方向表示变化趋势，长度表示影响强度；`envfit` 可把环境因子叠加到 PCoA/NMDS 图上做直观关联。
- *共线性*：先用 `vif.cca` 检查方差膨胀因子，剔除共线因子（VIF 过大），否则模型不稳。

```r
RsquareAdj(rda_mod)
vif.cca(rda_mod)                                 # 检查共线性

# envfit：把环境因子叠加到排序图（PCoA/NMDS/RDA 均可）
fit <- envfit(rda_mod, env, permutations = 999)       # 公式接口 envfit(ord ~ ., env) 亦可
plot(rda_mod)
plot(fit, p.max = 0.05)                          # 只画显著因子箭头
```

#line()

== 14. NMDS 分析

NMDS（非度量多维尺度分析）与 PCoA 都是排序，但思路不同：*PCoA 尽量保持真实距离，NMDS 只保持样本间距离的「排序（次序）」*。因此 NMDS 对距离的绝对数值不敏感，特别适合「只能得到样本间等级关系」的情形，也更扛得住非线性。

关键指标是 *Stress*：衡量「降维后的距离」与「原始距离排序」的吻合程度。*一般 Stress < 0.2 可接受，< 0.1 较好*（经验阈值体系出自 Clarke 1993 与 Kruskal 的经典建议）；Stress 太高说明二维平面装不下真实结构，需要换维数或换距离。注意 metaMDS 受随机起点影响，*跑前固定 `set.seed()`*，并多试几个起点（trymax）确认解稳定。R 实现：

```r
library(vegan)

# comm、meta：已按附录 C 的统一导入模块就绪

# ASV/OTU 丰度高度偏态：先 Wisconsin 双标准化或 sqrt 变换，
# 避免少数高丰度特征主导距离排序
comm_w <- wisconsin(sqrt(comm))
d <- vegdist(comm_w, method = "bray")

nmds <- metaMDS(d, k = 2, trymax = 100)
nmds$stress                                     # 报告应力值
stressplot(nmds)                                # 拟合优度图

plot(nmds, type = "n")
points(nmds, display = "sites", pch = 21,
       bg = as.integer(factor(meta$Group)))
ordiellipse(nmds, groups = meta$Group, kind = "se", conf = 0.95)
```

与 PCoA 的关系：两者常一起报，*结论一致时最稳*。PCoA 的轴有解释率、NMDS 的图有 Stress，各自报告对应指标即可，不要拿 PCoA 的百分比去标注 NMDS 图。

#line()

== 15. 共发生网络分析（SparCC / SPIEC-EASI）

共发生网络（co-occurrence network）把每个类群（属 / OTU / ASV）当成节点，把「两个类群在不同样本中丰度是否协同变化」当成边。正相关 = 共发生（可能互利或同生态位），负相关 = 互斥（竞争 / 拮抗）。它把分析从「谁在」推进到「谁和谁相关」。

=== 15.1 为什么不能用 Pearson

16S 丰度是组成型（compositional）数据：各特征相对丰度之和恒为 1，一个类群升高会「挤压」其他类群的相对值，直接算 Pearson 相关会得到大量假相关。因此要用专门处理组成型数据的稀疏相关 / 偏相关方法：

#tablem[
  | 方法 | 原理 | 实现 | 备注 |
  | :--- | :--- | :--- | :--- |
  | SparCC | 组成型「稀疏相关」：假设多数类群无关联，迭代估计基础相关 | Python `SparCC.py` | 经典、直观 |
  | SPIEC-EASI（MB） | 稀疏*偏相关*：邻域选择 + 稳定性选择 | R `SpiecEasi::spiec.easi(method="mb")` | 推荐、稳健 |
  | SPIEC-EASI（glasso） | 图 lasso 稀疏逆协方差（偏相关） | 同上 `method="glasso"` | 备选 |
  | CCLasso / CoNet | 组成型相关 / 集成多指标 | R / Cytoscape 插件 | 补充 |
  | 普通 Pearson / Spearman | 直接算相关，*不校正组成性* | 任意 | 仅作快速探索，正式分析别用 |
  | WGCNA（加权相关网络） | 加权相关 + 软阈值，善于划分模块 | R `WGCNA` / `microeco` | 侧重模块，不强调稀疏性 |
]

*别把 SparCC 与 SPIEC-EASI 混为一谈*：SparCC 估计的是「组成型稀疏*相关*」（correlation）；SPIEC-EASI 估计的是「稀疏*偏相关* / 逆协方差」（conditional dependence——边表示*控制其他节点之后*仍存在的关联），二者对同一条边的生态含义不同。另外，「SPCC」并不是 SparCC 的别名，写方法时直接写 SparCC 或 SPIEC-EASI，别用含糊缩写。选一个主流方法即可，不必全做。

=== 15.2 标准流程

1. *选层级*：用属水平*计数表*（`taxa collapse --p-level 6`，*不要预先 `relative-frequency` 转相对丰度*——#link(<t-sparcc>)[SparCC 与 SPIEC-EASI] 都在计数 / CLR 空间建模，`spiec.easi` 内部会自行按比例归一化，预先转相对丰度反而丢信息）；节点过多时先按丰度 / 出现率过滤。
2. *过滤*：去掉出现率过低、或平均相对丰度极低的类群，减少噪声边。*出现率阈值不是固定规则*（20%、30% 只是常见示例），要结合样本量、特征数、稀疏程度和研究问题设定，并对不同阈值做敏感性分析。
3. *变换与相关*：CLR 变换后估计稀疏相关 / 偏相关（SparCC 或 SPIEC-EASI）。
4. *阈值*：保留 |r| ≥ 0.6（或 0.7）且 FDR 校正后 P ＜ 0.05 的边。
5. *建网与出图*：转成图对象，用 Gephi / Cytoscape 布局、着色、导出。
6. *拓扑与关键物种*：计算度、模块度等，找 Hub 与模块连接者。

样本量决定稳健性：*一般建议 ≥ 20–30 个样本*，越多越可靠；样本太少时大量边只是噪声。

=== 15.3 R 实现（SpiecEasi + igraph）

```r
# SpiecEasi 不在 CRAN，只能从 GitHub 装：remotes::install_github("zdk123/SpiecEasi")
library(SpiecEasi); library(igraph); library(Matrix)
# dat：行=样本，列=属；先做出现率过滤
X  <- as.matrix(dat[, colMeans(dat > 0) > 0.2])      # 出现率 > 20%
se <- spiec.easi(X, method = "mb", lambda.min.ratio = 1e-2,
                 nlambda = 20, sel.criterion = "stars",
                 pulsar.params = list(rep.num = 50, ncores = 4))
getStability(se)                 # λ 路径上网络的稳定性摘要；spiec.easi 内部按 stars 阈值（默认 0.05）自动选 λ，解读见 ?getStability
adj <- getRefit(se)              # 稀疏邻接矩阵
ig  <- adj2igraph(adj)           # 转 igraph，正 / 负边可按符号着色
plot(ig, vertex.size = 3, vertex.label = NA, layout = layout_with_fr)
```

SparCC 的 Python 路线（*注意参数语义与常见误写*）：`SparCC.py` 的 `-i/--iterations` 是剔除高相关对的迭代次数（默认 10）、`-x/--xiter` 同为迭代数——*它们都与 P 值无关*；`-a/--algo` 是选关联算法（SparCC / pearson / spearman / kendall），别把输出文件名传给它。P 值必须独立走 bootstrap 两步：

```bash
# otu_table：行=类群（特征），列=样本；输入计数表，SparCC 内部做 CLR
# 原版仓库（bitbucket.org/yonatanf/sparcc）已被 Bitbucket 停用，镜像：
#   github.com/TankMermaid/sparcc
python SparCC.py otu_table.txt -i 10 -c sparcc_corr.txt          # ① 相关
python MakeBootstraps.py otu_table.txt -n 100 -t permutation_#.csv -p ./   # ② 置换表
# ③ 对每张置换表各跑一次 SparCC.py 得到置换相关（如 perm_cor_#.txt），
#    再把置换相关（不是置换表本身）喂给 PseudoPvals 合成 P 值：
python PseudoPvals.py sparcc_corr.txt perm_cor_#.txt 100 -o sparcc_pvals.txt -t two_sided
```

更省事的是 C++ 重写版 *FastSpar*（速度远快于原版，bioconda 可直接装，参数接口对齐 SparCC）：

```bash
fastspar -c otu_table_counts.tsv -o fastspar_out -i 30   # 配合 fastspar_bootstrap 与 fastspar_pvals 出 P 值
```

再用相关与 P 值阈值筛边，导入 igraph / Gephi。

*更省事的封装：R 包 `microeco`。* 若不想自己拼 SpiecEasi + igraph，可用 `microeco::trans_network` 一条链完成建网、模块、拓扑与导出：`cor_method` 可选 `spearman` / `pearson` / `sparcc` / `bray`，或 `use_WGCNA_pearson_spearman = TRUE` 走 WGCNA 加权网络（善分模块）；先用 `filter_thres` 去掉低丰度（如 0.001），`COR_cut` 设相关系数阈值（如 0.6）、`COR_p_thres` 设 P / FDR（如 0.01），`COR_optimization = TRUE` 可据随机矩阵理论自动定阈值。建网后 `$cal_module(method = "cluster_fast_greedy")` 分模块、`$cal_network_attr()` 出拓扑（模块度 Modularity＞0.4 通常认为模块结构显著）、`$get_node_table(node_roles = TRUE)` 出 Zi–Pi 角色、`$save_network("network.gexf")` 导 Gephi。方法与 15.2 一致，只是把繁琐步骤封装了——*相关 ≠ 因果*这条底线不变。

=== 15.4 拓扑指标与关键物种（Zi–Pi）

常用拓扑指标（Gephi / igraph / Cytoscape 均可计算）：

#tablem[
  | 指标 | 含义 |
  | :--- | :--- |
  | 度 degree | 节点连边数，越高越中心 |
  | 聚类系数 clustering coefficient | 邻居之间也相连的程度 |
  | 接近中心性 closeness | 到其他节点的平均距离，越小越中心 |
  | 介数中心性 betweenness | 位于多少最短路径上，越高越关键 |
  | 模块度 modularity | 网络分模块的清晰程度 |
  | 直径 / 平均路径长度 | 网络大小与紧密程度 |
  | 密度 density | 实际边数 / 可能边数 |
]

*关键物种用 Zi–Pi 图判定*。划分模块后，对每个节点计算模块内连接度 Zi 与模块间连接度 Pi：

```text
Zi = (Ki - mean(K)) / sd(K)
Pi = 1 - Σ (Kis / Ki)²
```

- *模块枢纽 module hubs*：Zi＞2.5、Pi＜0.62
- *连接者 connectors*：Zi＜2.5、Pi＞0.62
- *网络枢纽 network hubs*：Zi＞2.5、Pi＞0.62
- *边缘节点 peripherals*：Zi＜2.5、Pi＜0.62

高 Zi / Pi 只说明该节点在*网络结构*上处于枢纽 / 连接者位置，*不等于已证实的生态 keystone taxon*——真正的 keystone 需要去除实验（如培养敲除后观察群落是否剧变）来验证。因此把 Zi–Pi 结果表述为「网络枢纽候选」更稳妥，不要让读者把它当成 keystone 的定论。

=== 15.5 与随机网络比较

把实测网络的*平均聚类系数、平均路径长度、模块度*与同规模 Erdős–Rényi 随机网络比较：

- 小世界性：聚类系数显著高于随机、路径长度相近，说明网络具小世界结构；
- 模块度显著高于随机，说明群落有清晰模块划分。

可用 MENA（http://ieg4.rccc.ou.edu/mena/）、`igraph` 或置换检验完成。*换不同阈值 / 相关方法重跑，结论稳定才可信*。

*阈值敏感性的最小流程*：至少在相关系数绝对值 ≥ 0.5 / 0.6 / 0.7 三档阈值下各建一次网络，记录每档的节点数、边数、模块度，以及 *Hub 列表的重叠比例*。若 Hub 集合在三档之间高度不稳定（重叠很低），说明网络结论对阈值太敏感，不应把它当作主要发现；只有在合理阈值范围内都稳定出现的 Hub，才值得写进结论。

=== 15.6 解读底线

- *相关 ≠ 因果*：网络边只是统计关联，Hub 只是假设，需培养 / 实验验证。
- 组成型、阈值、样本量都会改变网络结构；方法部分要写清「层级、过滤、方法、阈值、FDR」。
- 正负边分开解读：负边可能是竞争，也可能是组成效应造成的假象。

#line()

== 16. 出图、报告与常见坑

做到这里，你已经有了一套可复现的结果。要让它们变成「能发表的图」，还要过几道关。

=== 16.1 出图与配色

- *矢量优先*：论文图用 SVG/PDF，别用截图；QIIME 2 的 qzv 可导出 SVG，R 用 `ggsave(..., device = "svg")`。
- *克制配色*：分组颜色选一套对色盲友好、区分度高的调色板；避免彩虹色堆叠柱状图。
- *对齐与信息密度*：坐标轴统一字体字号，图例、标签对齐；一张图只讲一件事，把 P 值、R²、Stress 等关键统计量直接标在图上或图注里。
- *R 端重绘*：堆叠柱状图、PCoA、Alpha 箱线图，导出 CSV 后用 ggplot2 重绘，能完全掌控样式。属水平堆叠柱状图的重绘骨架：

```r
library(ggplot2)
# dat：行=样本，列=属（相对丰度，由 barplot 导出的 CSV 经 `qiime tools export` 整理）
plot_df <- as.data.frame(dat)
plot_df$SampleID <- rownames(dat)
long <- reshape(plot_df, direction = "long", varying = setdiff(names(plot_df), "SampleID"),
                v.names = "Abundance", timevar = "Genus", idvar = "SampleID",
                times = setdiff(names(plot_df), "SampleID"), new.row.names = 1:1e6)
# 只画 top N 属，其余并入 "Other"，避免彩虹色
top <- names(sort(colMeans(dat), decreasing = TRUE))[1:12]
long$Genus <- ifelse(long$Genus %in% top, long$Genus, "Other")

ggplot(long, aes(SampleID, Abundance, fill = Genus)) +
  geom_col(width = 0.9) +
  facet_grid(~ Group, scales = "free_x", space = "free_x") +
  scale_y_continuous(expand = c(0, 0)) +
  theme_bw(12) + theme(axis.text.x = element_text(angle = 45, hjust = 1))
```

=== 16.2 统计报告的底线

- 组间差异*必须做多重检验校正*，报告 P 值、Q 值、效应量。
- Alpha 用 Kruskal–Wallis（多组）或 Wilcoxon（两组）；Beta 用 PERMANOVA（QIIME 2 报伪 F 与 P，R² 用 `qiime diversity adonis` 或 R 端 `adonis2` 补），并用 PERMDISP 检查离散度。
- 全流程固定收集版本信息：QIIME 2 跑 `qiime info` 存档，R 里 `sessionInfo()` 存档，数据库 / 预训练分类器记录下载日期与 MD5。
- 小样本研究的结论要克制，写成「提示……，仍需进一步验证」，不要绝对化。

逐项留档的*最小报告清单*（别全凭记忆回写方法部分）：

#tablem[
  | 阶段 | 必报内容 |
  | :--- | :--- |
  | 导入与 QC | 样本数、去噪各阶段保留率、嵌合体比例、宿主 / 细胞器与污染去除量 |
  | 特征表 | 过滤阈值与过滤前后特征数、抽平深度、因深度不足被丢弃的样本数 |
  | 注释与映射 | 数据库 / 预训练分类器版本、confidence 阈值、mapping rate 分布（cr99 主线） |
  | 多样性 | 距离指标及选择理由、PERMANOVA 伪 F / R² / P、PERMDISP P、置换次数 |
  | 差异丰度 | 方法（含多方法共识策略）、多重校正方法与 Q 值阈值、log fold change、效应量 |
  | 环境 | `qiime info`、R `sessionInfo()`、脚本与参数版本、数据库 MD5 |
]

=== 16.3 常见坑清单

#tablem[
  | 坑 | 后果 | 对策 |
  | :--- | :--- | :--- |
  | 抽平深度设太低或样本删太多 | 多样性失真、样本损失 | 看 `table.qzv`，兼顾深度与样本数 |
  | 稀释曲线未达平台就比较 Alpha | 差异可能只是测序量差异 | 先看 `alpha-rarefaction.qzv` |
  | 数据库与扩增区不匹配 | 注释准确率低 | 用相同引物训练特异分类器 |
  | 未做多重检验校正 | 假阳性结论 | FDR/BH 校正，报告 Q 值 |
  | PCA 与 PCoA 混为一谈 | 方法学被审稿人质疑 | 记牢：PCA 用丰度矩阵，PCoA 用距离矩阵 |
  | 去噪保留率异常偏低（无固定阈值，需结合质量图与分阶段损失判断） | 参数可能设错、结论不可信 | 回 `demux.qzv` 看各阶段损失，重设截断 / 去引物 |
  | 宿主线粒体 / 叶绿体污染 | 假多样性、属名异常 | `taxa filter-table` 去 mitochondria/chloroplast |
  | 分类器扩增区不匹配 | 大量 Unassigned / 误注释 | 用相同引物 `extract-reads` 训练特异分类器 |
  | 中文 / 空格路径 | 部分工具报错 | 全程用英文无空格路径 |
]

=== 16.4 延伸：功能预测

拿到物种组成后，常被追问「这些菌在干什么」。先说底线：*下面这些方法都是「预测」，不是「测量」*——它们基于 16S 序列与参考基因组的相似性推断功能，不能替代 shotgun 宏基因组的功能实测；结论用于*生成假设*，不用于下功能定论。常见几类：

- *PICRUSt2 功能预测（走 ASV 支线）*：以*质控后的 ASV 表 `table-asv.qza` + ASV 代表序列 `rep-seqs-asv.qza`* 为输入（*不要*换成 closed-reference OTU 表——PICRUSt2 要把序列放置到参考系统发育树上，OTU 的参考编号会破坏这一步）。QIIME 2 里用 `q2-picrust2` 插件，命令是 `qiime picrust2 full-pipeline`（输入 `--i-table` 与 `--i-seq`，常用 `--p-placement-tool sepp --p-hsp-method pic --p-max-nsti 2`；`--p-max-nsti 2` 默认即 2，weighted #link(<t-nsti>)[NSTI] > 2 表示该序列偏离参考树较远、预测不可靠，会被剔除或标记）；输出 EC（酶）、KO（KEGG 同源）、MetaCyc pathway 三类预测。
- *Tax4Fun2*：按 16S 与参考基因组的相似度直接映射 KEGG 功能，适合环境样本、可自建参考集，可与 PICRUSt2 互为校验。
- *FAPROTAX 生态功能*：用「分类单元→功能」经验映射表，把 16S 物种表翻译成碳 / 氮 / 硫循环、发酵、光养等功能；只有 16S 又关心元素循环时最常用（`collapse_table.py`）。
- *BugBase 表型预测*：输出革兰氏阴阳性、好氧 / 厌氧、生物膜形成、致病性等表型比例。
- *FUNGuild 真菌功能*：把 ITS 物种映射到 *病理营养型（pathotroph）、共生营养型（symbiotroph）、腐生营养型（saprotroph）* 三大营养型及其细分 guild。

PICRUSt2 在 QIIME 2 里的一条龙命令（先装插件 `conda install q2-picrust2 -c conda-forge -c bioconda -c picrust`）：

```bash
qiime picrust2 full-pipeline \
  --i-table table-asv.qza \
  --i-seq rep-seqs-asv.qza \
  --output-dir q2-picrust2_output \
  --p-placement-tool sepp \
  --p-threads 8 \
  --p-hsp-method pic \
  --p-max-nsti 2 \
  --verbose
```

输出三类预测（`.qza`，行 = 功能、列 = 样本）：`ec_metagenome.qza`（EC 酶）、`ko_metagenome.qza`（KEGG KO）、`pathway_abundance.qza`（MetaCyc 通路）；`qiime tools export --input-path q2-picrust2_output/pathway_abundance.qza --output-path export/pathway` 后可进 R 做差异 / 排序。`--p-max-nsti` 默认即 2：weighted NSTI 大于 2 表示该序列放置到参考树太远、预测不可靠，应剔除或标注。

*shotgun 宏基因组是「测量」而非「预测」*：真要回答功能问题，别用 16S 猜——直接做 shotgun 测序，用 *MetaPhlAn4*（clade-specific 标记基因做物种 / 菌株定量，每样本输出 `_profile.txt`，`merge_metaphlan_tables.py` 合并成丰度表）与 *HUMAnN*（通路 / 基因家族功能定量）。它们输入 trimmed fastq、直接测得而非推断，代价是成本与数据量远高于 16S——这正是「预测 vs 测量」的分水岭。

这些是从「物种描述」走向「功能推断」的加分项，但预测结果仍需实验验证；网络分析见第 15 节。若问题变成「群落像谁、来自谁」，用来源追踪：`SourceTracker2`（贝叶斯混合 + Gibbs）或 `FEAST`（EM 混合模型）估计 source→sink 的贡献比例。*前提*：必须先有明确的 source / sink 采样设计（例如同个体的口腔→肠道配对），否则来源追踪无法解释；预测出的来源比例是*模型估计*，不是直接观测到的微生物转移事件，Unknown 比例也不可当作可忽略的噪声。

#line()

== 17. 进阶与跨研究模块（选读）

本节不属前面 14 个必学主题，而是跨研究整合常用、单队列项目也可借鉴的进阶做法。读不读不影响跑通主线。（*实验设计与 Metadata 质量控制是后续统计的前置条件，已前移到 0.5 节*，不放在这里。）

=== 17.1 核心微生物组（core microbiome）

16S 不只要回答「谁最多」，还要回答「谁在不同样本 / 组里*稳定出现*」。核心菌群用*出现率（prevalence）*而非丰度定义：在多大比例的样本里检出（阈值 50% / 70% / 90% 代表不同严格程度，*必须预先定义并报告*）。可视化用 UpSet 图（多组交集，`UpSetR` / `ComplexUpset`）或 Venn 图（组数少时）；同时报核心菌群的相对丰度与出现率。注意：出现率高只说明「稳定」，并不等于功能重要。

=== 17.2 配对 / 纵向与重复测量

同一受试者干预前后、多时间点、多部位、配对病例-对照的数据，*不能当独立样本做普通检验*。处理方式：

- 配对两组：配对 Wilcoxon（`wilcox.test(x, y, paired = TRUE)`）或配对距离比较。
- 重复测量 / 多协变量：线性混合效应模型，个体作随机截距：
  ```r
  library(lme4); library(lmerTest)
  lmer(Shannon ~ Group + Age + Sex + (1 | SubjectID), data = meta)
  ```
  报告边际 R² 与条件 R²（`MuMIn::r.squaredGLMM(mod)`，读 `R2m` / `R2c` 两列；也可用 `performance::r2(mod)`），写清 complete-case 样本量与队列 / 个体数。
- Beta 端：QIIME 2 `q2-longitudinal`（如 `pairwise-differences`、`pairwise-distances`、`linear-mixed-effects`）或把个体作为 `strata` 的重复测量 PERMANOVA；纵向特征级差异切到 R 端 `ancombc2` / `maaslin3`（见 12.3），支持固定 + 随机效应。

=== 17.3 机器学习与跨研究验证（LOSO）

用微生物组做年龄 / 疾病预测时，*验证设计比算法更重要*：

- 训练 / 验证 / 测试要分开；特征筛选与预处理必须*在训练折内部*完成，防止数据泄漏。
- 跨队列泛化用 *Leave-One-Study-Out（LOSO）* 交叉验证——每次留出一个 BioProject 整合作独立测试集；别把同一队列样本同时塞进训练和测试后还宣称「跨队列泛化」。
- 指标按任务报：分类用 AUC、敏感度 / 特异度；回归（如年龄）用 MAE、R²、Spearman ρ，并给置信区间与外部验证。

=== 17.4 跨队列网络共识

把多个研究简单合并算一次相关，会把批次差异当成生物关联。更稳的做法：*在各自 BioProject 内、按健康 / 疾病分层分别建网*（如 SparCC / SPIEC-EASI）→ 用 NetMoss 之类工具整合 → *只保留在足够比例队列中方向一致、且 pooled 关联达阈值的边* → Louvain 识别模块 → Zi–Pi / within-module degree 描述节点角色。阈值（如相关系数绝对值 ≥ 0.2、60% 队列一致）是*研究特定*设定，作案例而非默认标准；边仍是统计关联，不证明互作或因果。

#line()

== 附录

=== 附录 A. 安装 QIIME 2 2024.2

```bash
# 1) 安装 Miniconda（已安装可跳过）
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
~/miniconda3/bin/conda init

# 2) 下载 2024.2 amplicon 发行版清单并建环境
# 注意文件名里的 python 版本随发行版变（2024.2 是 py38，2024.10 已是 py310），
# 以 https://data.qiime2.org/distros/ 的当前页面为准，别照抄别处的 URL
wget https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.2-py38-linux-conda.yml
conda env create -n qiime2-2024.2 --file qiime2-amplicon-2024.2-py38-linux-conda.yml

# 3) 激活
conda activate qiime2-2024.2
qiime --help
```

国内下载 conda 清单或数据库缓慢时，可改用国内镜像或维护者备份站点；QIIME 2 中文手册（Yongxin Liu 维护）也提供备份链接。

=== 附录 B. 分类器与数据库

官方为常见引物区提供了预训练分类器，可直接下载使用；也可按第 4.5 节自行训练。若扩增的是特定高变区（如 V3–V4、V4），用对应引物 `extract-reads` 截取参考后再训练，精度更高：

```bash
# 以 V4 (515F/806R) 为例，截取参考区段后训练
qiime feature-classifier extract-reads \
  --i-sequences silva-138-99-seqs.qza \
  --p-f-primer GTGCCAGCMGCCGCGGTAA \
  --p-r-primer GGACTACHVGGGTWTCTAAT \
  --p-min-length 100 --p-max-length 400 \
  --o-reads ref-seqs-v4.qza

qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads ref-seqs-v4.qza \
  --i-reference-taxonomy silva-138-99-tax.qza \
  --o-classifier silva-138-99-v4-classifier.qza
```

*注意区段必须与数据一致*：上面示例用的是 *V4* 引物（515F/806R 旧版）。若你的数据是 *V3–V4*（正文 1.2 的 `CCTACGGGNGGCWGCAG` / `GACTACHVGGGTATCTAATCC`），这套 V4 `extract-reads` 与 515–806 预训练分类器*都不适用*，必须换成 V3–V4 引物重新截取参考后再训练——*官方没有提供现成的 341F/806R 预训练分类器*，任何「官方 V3–V4 分类器」的说法都是误传（QIIME 2 论坛的官方建议正是自行 `extract-reads` 训练）。另外，官方预训练分类器对 scikit-learn 版本敏感，下载 URL 要带当前 QIIME 2 环境的 sklearn 版本号（形如 `https://data.qiime2.org/classifiers/sklearn-1.4.2/...`），旧版分类器与新环境混用会报版本不匹配。拿错区段的分类器去注释，会得到大量 Unassigned 或系统性误注释。

常用官方预训练分类器（下载即用，免训练，均截自 515F/806R 扩增区）：

- `silva-138-99-515-806-nb-classifier.qza`：SILVA，V4，最通用。
- `gg_2022_10_backbone.v4.nb.qza`：Greengenes2 V4，与本文 backbone 主线口径一致。
- `gg-13-8-99-515-806-nb-classifier.qza`（遗留）：Greengenes 13_8 仅在兼容旧文献 / 旧 PICRUSt 流程时用，2024.2 data-resources 已由 Greengenes2 取代。
- 真菌 ITS：用 UNITE 训练的分类器。
- V3–V4 数据：没有对应预训练包，按上文自行训练。

再补一个小坑：训练用参考序列默认按正向书写，若你的代表序列方向不定（拼接后可能与参考反向互补），`classify-sklearn` 对反向序列的命中率会明显下降——自行训练时用与数据同向的 `extract-reads` 截段，或改用 `classify-consensus-vsearch` / `-blast`（支持 `--p-strand both`，对方向不敏感）。

R 端 DADA2 等价注释，`minBoot` 是 bootstrap 置信阈值（默认 50）：

```r
taxa <- assignTaxonomy(seqtab.nochim, "silva_nr99_v138.1_train_set.fa.gz", multithread = TRUE)
taxa <- addSpecies(taxa, "silva_species_assignment_v138.1.fa.gz")   # 种水平精确匹配（文件名勿写错）
```

=== 附录 C. 导入 / 导出：进入 R 分析

```bash
# 导出特征表为 BIOM，并转 TSV（用最终分析表，主流程即 closed-reference OTU 表）
qiime tools export --input-path table-clean.qza --output-path export/table
biom convert -i export/table/feature-table.biom \
  -o export/table/feature-table.tsv --to-tsv

# 导出代表序列与物种注释（与上面特征表同一命名空间）
qiime tools export --input-path rep-seqs-gg2-cr99.qza --output-path export/rep-seqs
qiime tools export --input-path taxonomy-gg2.qza --output-path export/taxonomy

# 导出距离矩阵（供 R 做 PERMANOVA / 聚类）
qiime tools export \
  --input-path core-metrics-results/bray_curtis_distance_matrix.qza \
  --output-path export/dist
```

*统一 R 导入模块（建议固化下来，后面所有 R 章节都复用 `comm` / `meta`）*：

```r
# BIOM 导出的 TSV：行=特征，列=样本，首行是注释行（"# Constructed from biom file"）
# 用 skip = 1 跳过它；若你的文件首行不是这行注释（个别 BIOM 版本或已手工处理过），
# 需按实际调整 skip；更稳妥也可用 comment.char = "#" 让 R 跳过所有以 # 开头的行
read_biom_tsv <- function(file) {
  x <- read.delim(file, row.names = 1, skip = 1,
                  check.names = FALSE, comment.char = "")
  as.matrix(x)
}

asv  <- read_biom_tsv("export/table/feature-table.tsv")  # 行=特征，列=样本
comm <- t(asv)                                           # 转成 样本×特征（vegan 约定）
comm <- comm[, colSums(comm) > 0, drop = FALSE]          # 去掉全零特征

meta <- read.delim("metadata.tsv", row.names = 1, comment.char = "")
meta <- meta[rownames(comm), , drop = FALSE]             # 与 comm 同样本顺序对齐

stopifnot(identical(rownames(comm), rownames(meta)))    # 顺序自检，报错就回头查 ID
```

后文各 R 章节都默认 `comm`（样本×特征）与 `meta`（已对齐）已经就绪；不要再各自 `t(dat)`、重复转置——*行=样本、列=特征* 是 vegan 的约定，弄反了所有距离、排序、聚类都会静默出错。

进阶与排错：

```bash
# 看当前版本支持哪些导入类型 / 格式（比背格式名靠谱）
# 注意：2024.2 已移除旧的 `--show-importable-formats/types` 旗标，现在的写法是：
qiime tools list-types
qiime tools list-formats --importable

# 若数据是 EMP 三文件（forward/reverse/barcodes），用 EMPPairedEndSequences 导入
# 目录形式可省 --input-format；若给单个 zip 压缩包则需 --input-format EMPEmbeddedSequences
qiime tools import \
  --type EMPPairedEndSequences \
  --input-path emp-paired-end-sequences \
  --output-path demux.qza

# BIOM 转 TSV 时把物种注释一并带出（前提：该 BIOM 已含 taxonomy 观察元数据——
# 从纯 FeatureTable 表导出的 biom 没有注释，此时必须先 collapse 后再导出，否则报错）
biom convert -i feature-table.biom -o table-with-taxonomy.tsv \
  --to-tsv -b --header-key taxonomy
```

*deblur / vsearch 路线需要先拼接*：`qiime vsearch join-pairs --i-demultiplexed-seqs demux.qza --o-joined-sequences demux-joined.qza`，再进 `qiime deblur denoise-16S`（Deblur 用 Greengenes 13_8 *88%* OTU 集做 16S *正向过滤*——经 SortMeRNA 比对后只保留「疑似 16S」的序列；`--p-trim-length` 必填，还有 `--p-min-reads` 默认 10、`--p-min-size` 默认 2，只处理正向 reads；速度通常快于 DADA2）。

导出的 TSV 首行常有 `# Constructed from biom file` 注释行，R 里用 `read.delim(..., skip = 1)` 跳过即可（本文各 R 代码已按此写法）。

=== 附录 D. 常见问题

高频报错速查（报错原文 → 原因 → 解法）：

- *`Feature IDs found in the table are missing from the tree`*：过滤顺序导致树 tip 与特征表不齐 → 用过滤后的表核对 / 重建树，或改用与表同 ID 命名空间的参考树（见 6.0）。
- *sklearn 版本不匹配（预训练分类器）*：分类器训练环境与当前环境不一致 → 按当前 sklearn 版本下载对应分类器，或自行重新训练（附录 B）。
- *DADA2 大量 `merged=0`*：重叠区不足 → 按 2 节的 `L_overlap` 公式重算 trim/trunc 参数。
- *大量 Unassigned*：引物区残留或引物区分与分类器不匹配 → 检查 `--p-trim-left` / Cutadapt，或按数据引物重训分类器。
- *closed-reference 后 unmatched 异常多*：perc-identity 过严或扩增区与 backbone 不匹配 → 见 4.3 的排查顺序。

常规问题：

- *分类器版本不兼容（scikit-learn）*：报错提示版本不匹配时，用当前环境重新训练分类器即可（附录 B）。
- *conda 清单下载失败*：改用国内镜像或中文手册的备份链接，或换用 `conda-pack` 打包好的环境。
- *内存不足（OOM）*：DADA2 与建树较吃内存，减小 `--p-n-threads`、分批处理或上服务器运行。
- *中文 / 空格路径报错*：全程使用英文、无空格的绝对路径。
- *BIOM 版本不兼容（biom 2.1.7 报错）*：新版 biom 偶有格式兼容问题，可改用 `qiime tools export` 后直接用 R 的 `read.delim`，或安装匹配版本的 biom。
- *DADA2 线程与耗时*：以 18 样本、每样本约 5 万对 reads 为例，`--p-n-threads` 取 96 / 24 / 8 / 1 时耗时约 34 / 44 / 77 / 462 分钟——线程不是越多越线性加速，找到机器的甜点即可。
- *下载慢或断*：国内可换镜像，或从维护者备份站（如 nmdc.cn、Yongxin Liu 的 GitHub 备份清单）取数据库与分类器。
- *qzv 打不开*：确认是拖到 view.qiime2.org 查看，而不是双击；国内镜像 view.qiime2.cn 曾出现 TLS 证书过期（浏览器可能告警），离线环境优先本地部署 QIIME 2 View。

=== 附录 E. 从 SRA 批量下载数据（Slurm 并行）

公共数据常需按研究号批量下载 SRA。下面是一个 Slurm 数组作业的思路，与前面的 DADA2 分析脚本衔接：

```bash
# 1) 由研究号取全部 run（S、D、E 开头的 SRR/DRR/ERR）
curl -s "https://trace.ncbi.nlm.nih.gov/Traces/sra-db-be/runinfo?acc=${study_id}" \
  | awk -F ',' 'NR>1 {print $1}' | grep -E '^[SDE]RR' | tr -d '\r' > sample.txt

# 2) 下载并拆分为 FASTQ
# 注意：--threads 是 fasterq-dump 的选项（fastq-dump 单线程设计、没有该选项）
prefetch --option-file sample.txt --output-directory sra
# 先确认实际落盘路径：prefetch 多数版本产出扁平的 sra/<acc>.sra，个别版本是 sra/<acc>/<acc>.sra
ls sra/
fasterq-dump --split-3 --threads 4 "sra/${run_id}.sra" --outdir rawdata

# 3) 生成 manifest（2024.2 双端 V2 格式：TSV（制表符分隔），列名与列数固定，不能省）
printf 'sample-id\tforward-absolute-filepath\treverse-absolute-filepath\n' > manifest.tsv
for fq in rawdata/*_1.fastq; do
  sid=$(basename "$fq" _1.fastq)
  r1=$(realpath "$fq"); r2=$(realpath "rawdata/${sid}_2.fastq")
  printf '%s\t%s\t%s\n' "$sid" "$r1" "$r2" >> manifest.tsv
done
```

- manifest 必须与 `qiime tools import --type` 对应：*双端*用 `PairedEndFastqManifestPhred33V2`（*TSV 制表符分隔*，三列：`sample-id`、`forward-absolute-filepath`、`reverse-absolute-filepath`，列名与列数都不能改）；*单端*用 `SingleEndFastqManifestPhred33V2`（*只有两列*：`sample-id`、`absolute-filepath`，见 0.2）。*V2 格式只解析制表符分隔文件，逗号分隔的 CSV 会导入失败*；列名或列数写错是最常见的导入报错来源。

- 用 `#SBATCH -a 1-N` 数组作业，一个任务处理一个研究号：`sed -n "${SLURM_ARRAY_TASK_ID}p" study_list.txt` 取当前号。
- `prefetch` 失败可重试；`fasterq-dump --split-3` 把双端拆成 `_1` / `_2`，单端只有一个文件（旧的 `fastq-dump --split-3` 仍可用作备选，速度较慢且无 `--threads`）。
- 生成 manifest 后用 `comm -23 <(sort sample.txt) <(ls rawdata | sed 's/_[12]\.fastq//' | sort -u)` 比对「应有」与「已下」列表，统计缺失样本（也可补装 Entrez Direct 的 `esearch`/`efetch` 作为 runinfo 接口的备选）。
- 之后进入第 2 节导入与去噪；大批量运行时让 `--p-n-threads` 与 Slurm 的 `-c` 对齐。

#line()

=== 附录 F. 16S 相关生信工具原理速查

从「数据获取」到「差异 / 来源追踪」，16S 流程会碰到的工具及选型如下（原理要点整理自作者《科研利器之生信工具的原理合集》）：

#tablem[
  | 工具 | 任务 | 核心原理 | 何时优先用 |
  | :--- | :--- | :--- | :--- |
  | SRA-Toolkit | 公共数据下载 | 解析 SRA 容器转 FASTQ | 复现公开研究 |
  | fastp / FastQC / MultiQC | 质控 / 画像 / 汇总 | 滑窗剪切 + base 级统计 | 常规预处理、批量报告 |
  | KneadData / Bowtie2 / BWA | 读段级去宿主 | FM-index 比对剔除宿主 reads | 宿主相关样本 |
  | QIIME 2 | 全流程平台 | artifact 类型系统 + 插件 | 规范化、可追踪流程 |
  | DADA2 | ASV 推断 | 显式错误模型 | 高分辨率 ASV |
  | Deblur | 轻量去噪 | 固定误差剖面 | 批量标准化 |
  | VSEARCH / mothur | OTU / 传统 SOP | 聚类 + 比对 | 兼容旧式 OTU |
  | SILVA / GTDB / Greengenes2 | 参考库 | 分类 / 系统发育框架 | 物种注释 |
  | FAPROTAX | 生态功能 | taxa→function 映射 | 元素循环推断 |
  | PICRUSt2 / Tax4Fun2 | KEGG 功能 | 祖先状态重建 / 参考基因组映射 | 无 shotgun 的功能假设 |
  | BugBase / METAGENassist | 表型 | taxa→表型映射、表型-环境耦合 | 表型画像 |
  | vegan | 群落统计 | 距离矩阵与置换检验 | alpha / beta、排序 |
  | ANCOM-BC2 / MaAsLin3 / LinDA / metagenomeSeq | 差异丰度 | 偏差校正 / GLM / log-ratio / ZIG | 组成型差异分析 |
  | SourceTracker2 / FEAST | 来源追踪 | 贝叶斯混合 / EM | source→sink 贡献 |
  | caret / Boruta / pROC | 机器学习 | 交叉验证 / shadow features / ROC | 标志物 + 诊断模型 |
]

几个最常用的底层命令（与正文命令互补）：

```bash
# 读段级去宿主（KneadData 封装 trimming + host removal）
kneaddata -i R1.fq.gz -i R2.fq.gz -db host_db -o kneaddata_out --threads 16

# VSEARCH 独立去嵌合体 / 97% OTU 聚类
vsearch --uchime_denovo rep_seqs.fasta --nonchimeras rep_seqs.nochim.fasta
vsearch --cluster_size rep_seqs.nochim.fasta --id 0.97 \
  --centroids otu97.fasta --uc otu97.uc --threads 16

# FAPROTAX（OTU 表含 taxonomy 注释）
# 注意：当前版 collapse_table.py（v1.3.7）里 -c 是「注释前缀」（默认就是 '#'，
# 旧版的 -d 分隔符改为 --row_names_are_in_column 指定行名/注释列，按列名或 0 起始索引）
python collapse_table.py -i otu_table.txt -g groups.txt -o func.tsv \
  -c '#' --row_names_are_in_column taxonomy -v
# 该命令对脚本版本敏感（v1.2.x 与 v1.3.7 参数含义不同），跑前先 -h 看本机版本
```

```r
# 差异丰度与来源追踪（R 端示意）
library(ANCOMBC);  ancombc2(data = physeq, fix_formula = "Group", p_adj_method = "BH")
library(maaslin3); maaslin3(input_data = feat, input_metadata = meta,
                            output = "maaslin3_out", formula = "~ Group + age")
# SourceTracker2 命令行：sourcetracker2 gibbs -i otu.biom -m meta.tsv -o st2_out
```

选型原则：*先用 QIIME 2 把上游标准化，再用 DADA2（ASV）或 VSEARCH（OTU）二选一；功能预测用 PICRUSt2（肠道）或 FAPROTAX / Tax4Fun2（环境）；差异分析优先组成型方法（ANCOM-BC2 / LinDA），模型类结论务必交叉验证*。

#line()

== 附表：术语 <glossary>

正文反复出现的术语按主题收录于此，供集中查阅；正文首次出现处已加内链，点击即跳转本表对应条目。概念辨析的展开（ASV/OTU 的四种口径、抽平不是通用前提）见 #link(<sec-keyterms>)[0.3 节] 与第 4 节。

#tablem[
  | 术语 | 说明 |
  | :--- | :--- |
  | *16S rRNA 基因* <t-16s> | 细菌 / 古菌核糖体小亚基基因，全长约 1542 bp，含 V1–V9 约九个高变区与夹在中间的保守区；保守区用于设计「通用引物」，高变区用于区分物种。 |
  | *扩增区（V3–V4 / V4）* <t-region> | 引物决定扩哪一段；V3–V4 约 460 bp、分辨力高；V4 约 250 bp、适合 2×250。扩增区必须与数据库、分类器一致（第 1、4 节）。 |
  | *测序深度* <t-depth> | 每个样本的 reads 条数。深度不足会漏掉稀有类群，且样本间不能直接比多样性（第 4、6 节）。 |
  | *Q20 / Q30* <t-q20> | 碱基质量 ≥ 20 / ≥ 30 的碱基占比；Q20≈错误率 1%，Q30≈0.1%。Q20>90%、Q30>80% 通常算质量合格（第 1 节）。 |
  | *Good's 覆盖度* <t-goods> | 样本覆盖度估计 C = 1 − F₁/N（F₁ = 只出现一次的特征数，N = 总计数）；不是「已发现种数 / 真实种数」。越接近 1，说明「测得越全」（`goods_coverage`，见 6.1）。 |
  | *ASV / OTU* <t-asv> | 特征（feature）的两种单位：ASV 由 DADA2 等方法基于错误模型去噪得到，OTU 按相似度聚类形成；四种聚类口径的对比见 #link(<sec-keyterms>)[0.3 节] 与 4.1。 |
  | *Shannon* <t-shannon> | 兼顾丰富度与均匀度的多样性指数 H' = −Σ Pi·ln(Pi)，越大多样性越高（定义式见 6.1）。 |
  | *Simpson* <t-simpson> | D = 1 − Σ Pi²，偏向优势类群的多样性；QIIME 2 的 `simpson` 取「越大越多样」方向（见 6.1）。 |
  | *α / β / γ 多样性* <t-alpha> | 三个只差希腊字母的层次：α（Alpha）= 单个样本内部有多少种、多均匀，典型指标 Shannon、Simpson、Chao1、Faith PD（第 6 节）；β（Beta）= 样本与样本之间差多少，典型指标 Bray–Curtis、Jaccard、UniFrac（第 7 节）；γ（Gamma）= 整个区域 / 所有样本合起来的总多样性（区域物种池丰富度），综合解读时提及。 |
  | *Bray–Curtis* <t-bc> | 定量 β 距离：对丰度求差再归一，0 = 完全相同、1 = 完全不重叠；生态学最常用的群落相异度，对丰度敏感（公式见 7.1）。 |
  | *UniFrac（加权 / 非加权）* <t-unifrac> | 结合进化树的 β 距离；加权计入丰度、非加权只看有无。需先建树（见 6.0、7.1）。 |
  | *Faith PD* <t-faith> | Faith 系统发育多样性：样本内类群在有根进化树上覆盖的分支长度之和；强调「遗传多样性」而非仅物种数（见 6.0、6.1）。 |
  | *Chao1* <t-chao1> | 依低丰度（singleton / doubleton）估计的物种丰富度；校正「测少了」的丰富度估计，深度低时更重要（见 6.1）。 |
  | *PERMANOVA（伪 F / R²）* <t-permanova> | 基于距离矩阵的多元方差分析；伪 F 为组间 / 组内离差比，QIIME 2 报伪 F 与置换 P 值，R²（因子解释的方差比例）用 `qiime diversity adonis` 或 R 端 `adonis2` 补算（见 7.2）。 |
  | *稀释曲线（rarefaction）* <t-rare> | 固定样本、抽取不同测序深度时重算多样性得到的曲线；走平说明深度足够、可据此选抽平深度（见 6.2）。注意与「改变样本数」的物种累积曲线（`specaccum`）区分。 |
  | *NSTI* <t-nsti> | PICRUSt2 中序列放置到参考树的偏离指数，越大越不可靠（默认阈值 2；见 16.4）。 |
  | *SparCC / SPIEC-EASI* <t-sparcc> | 组成型网络方法：SparCC 估计稀疏*相关*，SPIEC-EASI 估计稀疏*偏相关*；共发生网络不能用普通 Pearson（见第 15 节）。 |
]

#line()

== 参考与延伸阅读

本文的流程、参数与判断规则，来自下列公开资料与两份作者教程。按用途分组，方便按需回查。

=== 主要方法文献（建议正文引用处补全）

- QIIME 2：Bolyen et al. 2019, *Nature Biotechnology* 37:852–857（doi:10.1038/s41587-019-0209-9）
- DADA2：Callahan et al. 2016, *Nature Methods* 13:581–583
- Greengenes2：McDonald et al., *PLoS Computational Biology*（greengenes2，与 GTDB 物理一致）
- SILVA：Quast et al. 2013, *NAR* 41:D590–D596；GTDB：Parks et al. 2022 / Reeves et al. 2021
- UniFrac：Lozupone & Knight 2005, *Appl Environ Microbiol*；Faith PD：Faith 1992, *Biol Conserv*
- ANCOM：Mandal et al. 2015, *Microbiome* 3:16；ANCOM-BC：Lin & Peddada 2020, *Microbiome* 8:70
- LinDA：Zhou, He, Chen & Zhang 2022, *Genome Biology* 23:95（doi:10.1186/s13059-022-02655-5，注意刊名是 Genome Biology，不是 Microbiome）；MaAsLin2/3：Huttenhower 组（MaAsLin3 见 Nickols et al., *Nat Methods* 2026）
- LEfSe：Segata et al. 2011, *Genome Biology* 12:R60；Metastats：White et al. 2009
- PICRUSt2：Douglas et al. 2020, *Nat Biotechnol*；Tax4Fun2：Wemheuer et al. 2020；FAPROTAX：Louca et al. 2016, *Glob Ecol Biogeogr*
- MetaPhlAn4：Blanco-Míguez et al. 2023, *Nat Biotechnol*；HUMAnN：Beghini et al. 2021, *Nat Methods*（shotgun 宏基因组的物种 / 功能「测量」，非 16S 预测）
- SparCC：Friedman & Alm 2012, *PLoS Comput Biol*；SPIEC-EASI：Kurtz et al. 2015, *PLoS Comput Biol*
- Zi–Pi 节点角色：Guimerà & Amaral 2005, *Nature* / Olesen et al. 2007, *PNAS*
- 排序选型（DCA/RDA/CCA）：Lepš & Šmilauer《Multivariate Analysis of Ecological Data》；vegan：Oksanen et al.（CRAN vegan 文档）
- 97% 阈值谱系：Stackebrandt & Goebel 1994（正文 4.1 已点名的三篇补全：Edgar 2018, *PeerJ* 6:e5453；Yarza et al. 2014, *Nat Rev Microbiol* 12:635–645）

=== QIIME 2 官方与规范文档

- QIIME 2 当前文档站（*旧版 per-release 路径如 docs.qiime2.org/2024.2 已整体下线 404*，旧版本文档存档在 Zenodo：doi:10.5281/zenodo.24082639）：#link("https://docs.qiime2.org/en/stable/")[docs.qiime2.org/en/stable]
- 多样性插件命令参考：#link("https://docs.qiime2.org/en/latest/references/plugins/diversity/")[docs.qiime2.org/…/plugins/diversity]
- 「Moving Pictures」教程（2‑4 与 2‑3 两版）：#link("https://forum.qiime2.org/t/qiime-2-4-moving-pictures-2018-11/7598")[forum/7598]、#link("https://forum.qiime2.org/t/qiime-2-3-2018-11/7599")[forum/7599]
- 经验驱动指南（中文镜像）：#link("https://geekdaxue.co/read/QIIME2-doc-zh/2-Tutorial-03-Experienced-Driver-Guide-Experience.md")[geekdaxue QIIME2-doc-zh]
- 宿主微生物组 QIIME 2 实验流程：#link("https://protocols.hostmicrobe.org/microbio/qiime2")[protocols.hostmicrobe.org]
- 宿主微生物组宏基因组流程（MetaPhlAn4 / HUMAnN / Sunbeam / Sourmash 等）：#link("https://protocols.hostmicrobe.org/microbio")[protocols.hostmicrobe.org/microbio]
- QIIME 2 原理与可追溯性（本文配图「附图1 原理图」与「图2 provenance」出处）：#link("https://mp.weixin.qq.com/s/gz2G4RQ3IBF21AYrPRQdIA")[微信 · QIIME 2 中文导读]
- DADA2 官方教程（R 端参数来源）：#link("https://benjjneb.github.io/dada2/tutorial.html")[benjjneb.github.io/dada2]

=== 勤勤山 16S 系列（逐篇对应本文各节）

- 系列总目录：#link("https://qinqianshan.com/bioinformatics/16s/")[16s 索引]
- 入门 / 安装 / 载入：#link("https://qinqianshan.com/bioinformatics/16s/qiime2-introduction/")[入门]、#link("https://qinqianshan.com/bioinformatics/16s/install-qiime2/")[安装]、#link("https://qinqianshan.com/bioinformatics/16s/qiime2-load/")[载入]
- 拆样与去噪：#link("https://qinqianshan.com/bioinformatics/16s/qiime2-demux/")[demux]、#link("https://qinqianshan.com/bioinformatics/16s/qiime2-feture/")[特征表]
- OTU 定义与去嵌合体：#link("https://qinqianshan.com/bioinformatics/16s/defining-and-interpreting-otus/")[OTU]、#link("https://qinqianshan.com/bioinformatics/16s/uchime-chimera/")[UCHIME]
- 数据库与 mapping / BIOM：#link("https://qinqianshan.com/bioinformatics/16s/taxonomy-db/")[数据库]、#link("https://qinqianshan.com/bioinformatics/16s/qiime-mapping/")[mapping]、#link("https://qinqianshan.com/bioinformatics/16s/qiime-biom/")[BIOM]
- 建树 / UniFrac / Faith PD：#link("https://qinqianshan.com/bioinformatics/16s/qiime2-phylo-tree/")[建树]、#link("https://qinqianshan.com/bioinformatics/16s/unifrac/")[UniFrac]、#link("https://qinqianshan.com/bioinformatics/16s/faith-phylogenetic/")[Faith PD]
- Alpha / Beta / Gamma：#link("https://qinqianshan.com/bioinformatics/16s/qiime2-alpha-beta/")[α/β 流程]、#link("https://qinqianshan.com/bioinformatics/16s/%CE%B1-diversity/")[α]、#link("https://qinqianshan.com/bioinformatics/16s/%CE%B2-diversity/")[β]、#link("https://qinqianshan.com/bioinformatics/16s/%CE%B3-diversity/")[γ]
- 指数与稀释曲线：#link("https://qinqianshan.com/bioinformatics/16s/diversity-index-and-richness-index/")[多样性 / 丰富度指数]、#link("https://qinqianshan.com/bioinformatics/16s/rarefaction-curve/")[稀释曲线]
- 距离与检验：#link("https://qinqianshan.com/bioinformatics/16s/r-vegdist/")[vegdist]、#link("https://qinqianshan.com/bioinformatics/16s/permanova/")[PERMANOVA]
- 批量下载 NCBI 数据：#link("https://qinqianshan.com/bioinformatics/16s/batch-download-micro/")[批量下载]

=== 中文实战博客与教程

- R 微生物组分析课程（d2rs）：#link("https://d2rs-2026spring.github.io/lecture6-r-microbiome-analysis/")[d2rs lecture6]
- yjpweb 16S / QIIME 2 教程（引物、截断、抽平细节）：#link("https://yjpweb.cn/tutorials/16s-qiime2.html")[yjpweb.cn]
- xizhihui 扩增子 QIIME2 示例：#link("https://xizhihui.github.io/2018/10/15/%E6%89%A9%E5%A2%9E%E5%AD%90%E6%B5%8B%E5%BA%8F-QIIME2%E4%BD%BF%E7%94%A8%E7%A4%BA%E4%BE%8B/")[xizhihui]
- Asa 的扩增子分析流程（ASV / OTU、Deblur、Kraken）：#link("https://asa-blog.netlify.app/p/amplicon-workflow/")[asa-blog]
- 小祁正 QIIME2 笔记（denoise / core-metrics / ANCOM）：#link("https://xiaoqizheng.github.io/biological_data_analysis/qiime2.html")[xiaoqizheng]
- leezx 博客（微生物多样性）：#link("https://www.cnblogs.com/leezx/p/7053199.html")[cnblogs/leezx]
- 萌檬控教程：#link("https://www.maimengkong.com/?post=1575")[maimengkong]
- Fanshouji 微生物组实战（测试数据与耗时）：#link("https://www.fanshouji.com/mpb-shen-zhen-ji-yin-zu-suo-liu-yong-xin-zu-shi-yong/")[fanshouji]
- modb.pro 数据库社区笔记：#link("https://www.modb.pro/db/564077")[modb.pro/564077]
- 腾讯云开发者社区文章：#link("https://cloud.tencent.com/developer/article/2708345")[cloud.tencent/2708345]
- 微信热点整理：#link("https://wxredian.com/art?id=7f12749202f1bc1e8a400468f26f6f8b")[wxredian]

=== 微信公众号系列（9 篇）

- #link("https://mp.weixin.qq.com/s/kAw1y_MXEhFAXzK5ZpZFWA")[QIIME 2 基础流程]
- #link("https://mp.weixin.qq.com/s/JZysXeveO-_dkuDQVJrptg")[扩增子分析（一）]
- #link("https://mp.weixin.qq.com/s/oJSJT1CP260g6Rorkzxyng")[扩增子分析（二）]
- #link("https://mp.weixin.qq.com/s/s8kb8HJImEE-RG9S9YQqMw")[扩增子分析（三）]
- #link("https://mp.weixin.qq.com/s/O36ansiLRB--nXQK7ivWKw")[多样性分析]
- #link("https://mp.weixin.qq.com/s/_vU_PkDTTun9scZxA6wp5Q")[排序分析]
- #link("https://mp.weixin.qq.com/s/qqKerJTyI8Lz9NQL68hgzA")[差异分析]
- #link("https://mp.weixin.qq.com/s/1YOctkvcii0hIYbLy3DnFg")[可视化]
- #link("https://mp.weixin.qq.com/s/KgNzy_TWcQjO4firXeadZQ")[综合案例]

=== CSDN 专栏

- QIIME 2 扩增子专栏：#link("https://wenku.csdn.net/column/4ydpke7d59")[csdn 4ydpke7d59]
- 扩增子分析专栏：#link("https://wenku.csdn.net/column/3v5qomi7ft")[csdn 3v5qomi7ft]

=== 本文直接依据的教程与讲义

- 刘永鑫等《使用 QIIME 2 分析微生物组 16S rRNA 基因扩增子测序数据》（Bio-protocol；本地 DOCX）——测试数据（Huang et al. 2019 拟南芥根际，GSA CRA002352，3 组 × 6 = 18 样本）、去噪耗时、ANCOM 示例出自此。
- 北京百迈客《微生物多样性分析方法 v2.6》（本地 PDF）——公司预处理参数、分类器阈值、LEfSe / Metastats、RDA / CCA 选型、网络指标、PICRUSt2 / BugBase / FUNGuild、三代测序 CCS / lima 参数出自此。
- 作者《科研利器之生信工具的原理合集》（本地 Markdown）——附录 F 的工具原理、命令与选型整理自此。
- 作者 DADA2 / closed-reference Slurm 脚本（dada2_download_YL.sh、dada2_analysis_YL.sh、closed_reference_YL.sh）——附录 E 与 4.1 节的真实并行链路、去噪 / 闭合参考参数来源。

=== 网络分析与进阶方法

- SpiecEasi（SPIEC-EASI 的 R 实现）：#link("https://github.com/zdk123/SpiecEasi")[github.com/zdk123/SpiecEasi]
- SparCC：原版仓库 #link("https://bitbucket.org/yonatanf/sparcc")[bitbucket.org/yonatanf/sparcc] 已被 Bitbucket 停用（404），代码镜象见 #link("https://github.com/TankMermaid/sparcc")[github.com/TankMermaid/sparcc]；更常用的 C++ 重写版 FastSpar：#link("https://github.com/scwatts/fastspar")[github.com/scwatts/fastspar]（bioconda 可装）
- MENA（分子生态网络分析平台，需免费注册登录）：#link("http://ieg4.rccc.ou.edu/mena/")[ieg4.rccc.ou.edu/mena]
- QIIME 2 中文手册（Yongxin Liu）：#link("https://github.com/YongxinLiu/QIIME2ChineseManual")[github.com/YongxinLiu/QIIME2ChineseManual]
- 讲义 `diversity_analysis.md`（QIIME 2 概览与 2020.11 / 2021.2 完整流程命令）。

=== 参考库与 closed-reference 主线

- Greengenes2 2024.09 文件索引（backbone 序列 / taxonomy 与 phylogeny 系列参考树）：#link("https://ftp.microbio.me/greengenes_release/2024.09/")[ftp.microbio.me/greengenes_release/2024.09]
- q2-greengenes2 插件说明：#link("https://github.com/biocore/q2-greengenes2/")[github.com/biocore/q2-greengenes2]
- QIIME 2 OTU clustering 教程（closed-reference / open-reference，确认 DADA2 输出可作输入；旧版 per-release 路径已 404，改用当前文档站的 how-to-guides；命令参数以本机 `--help` 为准）：#link("https://docs.qiime2.org/en/stable/how-to-guides/cluster-reads-into-otus/")[docs.qiime2.org/en/stable/how-to-guides/cluster-reads-into-otus]

=== 一点说明

上述链接中，部分站点为镜像、需登录或已迁移，个别页面在抓取时返回的是与标题不符的内容或纯前端渲染的空白。本文只采纳其中*可复现、与 QIIME 2 官方行为一致*的命令与数值；凡涉及具体参数处，均以「示例、需按自己数据调整」提示为准。真正跑流程时，请以 `qiime <插件> <命令> --help` 与 QIIME 2 当前版本文档（docs.qiime2.org/en/stable；旧版本文档已存档于 Zenodo，doi:10.5281/zenodo.24082639）为最终依据。
