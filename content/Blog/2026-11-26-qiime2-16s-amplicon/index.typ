#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "16S rRNA 扩增子生信分析全流程（QIIME 2 2024.2）",
  description: "面向硕士研究生的 16S 扩增子分析教程：从数据质控、DADA2 去噪、Greengenes2 closed-reference 建 OTU 表与物种注释，到 Alpha/Beta 多样性、系统进化树、PCoA/PCA/NMDS/UPGMA、差异丰度、RDA/CCA 与共发生网络，以 QIIME 2 2024.2 串起完整流程，并给出 R（vegan/SpiecEasi）端复现代码。",
  date: datetime(year: 2026, month: 11, day: 26),
  lang: "zh",
)

= 16S rRNA 扩增子生信分析全流程（QIIME 2 2024.2）

本教程以 *QIIME 2 2024.2* 为分析环境，采用 *DADA2 去噪*推断 ASV（扩增子序列变体）；在需要跨研究统一特征空间的主线中，进一步把 ASV 通过 *Greengenes2 backbone 做 99% closed-reference mapping*，得到参考库定义的 OTU 特征表。群落组成、Alpha/Beta 多样性及基于分类单元的比较分析，以该 OTU 表为主要输入；ASV 表与未匹配序列则保留用于序列层面质控、参考库覆盖度评估和 PICRUSt2 等功能预测。

要特别说明：*双端数据的 `dada2 denoise-paired` 内部已经完成质量过滤、去噪、拼接与去嵌合体*，不要把「拼接」「去嵌合体」再当成 DADA2 之后必须单独执行的主步骤；只有走 vsearch / Deblur 的 OTU 路线时，才需要显式拼接与去嵌合体。

分工原则：*QIIME 2 负责上游——把原始 reads 变成干净的特征表、物种注释、进化树和核心多样性指标；PCA、NMDS、RDA/CCA、Rank-Abundance、UPGMA、LEfSe、网络分析等下游统计与可视化，交给 R 生态或独立工具*。每一步都会标注归属，避免在 QIIME 2 里找一个它本就不提供的命令。

#figure(
  image("imgs/00-pipeline-overview.png"),
  caption: [16S 扩增子整体分析流程总览：从测序数据质控，到特征表生成与物种注释，再到多样性、排序、差异与环境因子关联分析（据参考资料与 BMKCloud 分析框架整理）],
)

#line()

== 0. 准备工作与分析总览

=== 0.1 版本、环境与基本概念

本文所有命令以 *QIIME 2 2024.2*（amplicon 发行版）为准。QIIME 2 不能直接在 Windows 上运行，需要在 Linux 服务器、Windows 的 WSL2（Ubuntu）或 macOS 上通过 Conda 安装（安装命令见附录 A）。各版本命令高度一致，个别插件参数会变，遇到报错先 `qiime <插件> <命令> --help` 查看当前版本的真实参数，比背参数更重要。

QIIME 2 用两种文件承载数据，理解它们能省掉很多困惑：

#tablem[
  | 后缀 | 含义 | 典型用途 |
  | :--- | :--- | :--- |
  | `.qza` | QIIME 2 Artifact，带类型的「数据」压缩包 | 特征表、代表序列、进化树、分类注释、距离矩阵 |
  | `.qzv` | QIIME 2 Visualization，带类型的「可视化」压缩包 | 汇总表、质量图、柱状图、PCoA 交互图 |
]

`.qza` / `.qzv` 本质都是 zip 包，但*不要手动解压后改内容再塞回去*，否则会破坏校验。查看 `.qzv` 的标准姿势是把文件拖到 #link("https://view.qiime2.org")[view.qiime2.org]（国内可用 #link("https://view.qiime2.cn")[view.qiime2.cn]），在浏览器里交互式查看；需要进入 R 分析时，再用 `qiime tools export` 导出为 BIOM / TSV / FASTA（见附录 C）。

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

=== 0.3 术语与基本量：先把话说清楚

后面反复出现的几个概念，先统一口径，免得边学边猜：

#tablem[
  | 术语 | 含义 | 为什么重要 |
  | :--- | :--- | :--- |
  | 16S rRNA 基因 | 细菌 / 古菌核糖体小亚基基因，全长约 1542 bp，含 V1–V9 约九个高变区与夹在中间的保守区 | 保守区用于设计「通用引物」，高变区用于区分物种 |
  | 扩增区（V3–V4 / V4） | 引物决定扩哪一段；V3–V4 约 460 bp、分辨力高；V4 约 250 bp、适合 2×250 | 扩增区必须与数据库、分类器一致 |
  | 测序深度 | 每个样本的 reads 条数 | 深度不足会漏掉稀有类群，且样本间不能直接比多样性 |
  | Q20 / Q30 | 碱基质量 ≥ 20 / ≥ 30 的碱基占比；Q20≈错误率 1%，Q30≈0.1% | Q20>90%、Q30>80% 通常算质量合格 |
  | Good's 覆盖度 | 样本覆盖度估计 C = 1 − F₁/N（F₁ = 只出现一次的特征数，N = 总计数）；不是「已发现种数 / 真实种数」 | 越接近 1，说明「测得越全」 |
  | ASV / OTU | 特征（feature）的两种单位 | 现代去噪用 ASV，经典聚类用 OTU（见第 4 节） |
]

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

多样性分三个层次，名字只差一个希腊字母，含义却完全不同：

#tablem[
  | 层次 | 回答的问题 | 典型指标 | 本文位置 |
  | :--- | :--- | :--- | :--- |
  | α（Alpha） | 单个样本内部有多少种、多均匀 | Shannon、Simpson、Chao1、Faith PD | 第 6 节 |
  | β（Beta） | 样本与样本之间差多少 | Bray–Curtis、Jaccard、UniFrac | 第 7 节 |
  | γ（Gamma） | 整个区域 / 所有样本合起来的总多样性 | 区域物种池丰富度 | 综合解读时提及 |
]

一个常被忽略的量：*样本间测序深度不齐时，直接比较 α 多样性会被深度差异带偏*，所以 *QIIME 2 的常规 Alpha/Beta 流程*会先抽平（rarefy，即 `--p-sampling-depth`）到同一深度再比较。但抽平并非所有下游步骤的通用前提——*差异丰度分析通常使用未抽平的计数表*，由方法自身做归一化或偏差校正（见第 12 节）；`core-metrics-phylogenetic` 输出的抽平表也*不要*直接当作 ANCOM-BC / MaAsLin 的默认输入。

=== 0.4 分析总览：哪一步归 QIIME 2，哪一步归 R

#tablem[
  | 分析环节 | 主要工具 | 代表命令 / 函数 | 主要产物 |
  | :--- | :--- | :--- | :--- |
  | 质控与去噪 | QIIME 2（DADA2） | `demux summarize`、`dada2 denoise-paired` | 特征表、代表序列 |
  | 物种注释 | QIIME 2 | `classify-sklearn` | `taxonomy.qza` |
  | 进化树 | QIIME 2 | `align-to-tree-mafft-fasttree` | `rooted-tree.qza` |
  | Alpha 多样性 | QIIME 2 | `core-metrics-phylogenetic`、`alpha-rarefaction` | 多样性向量、稀释曲线 |
  | Beta 多样性 | QIIME 2 + R | `beta-group-significance`、vegan | 距离矩阵、PERMANOVA |
  | PCoA | QIIME 2 | `diversity pcoa` + `emperor plot` | 排序图 |
  | PCA / NMDS / UPGMA | R（vegan） | `prcomp` / `rda(~1)`、`metaMDS`、`hclust` | 排序图、聚类树 |
  | 组间差异 | QIIME 2 + R/LEfSe | `composition ancom`、LEfSe | 差异特征、标志物种 |
  | RDA / CCA / db-RDA | R（vegan） | `rda`、`cca`、`capscale`、`decorana` | 约束排序图 |
  | Rank-Abundance | R | `ggplot2`、`radfit` | 等级丰度曲线 |
  | 网络分析 | R（SpiecEasi）/ Python | `spiec.easi`、`SparCC` | 共发生网络、关键物种 |
]

注意 `vegan::rda()` *无约束时做的就是 PCA*（对 Hellinger 后的矩阵），带约束公式时才是 RDA——二者共享底层算法，但统计含义不同，表里把 PCA 单独写成 `prcomp` 以免混淆。

这条教程的主线是：*导入 → Cutadapt 去引物（按需）→ DADA2 去噪（内置拼接与去嵌合体）→ ASV 特征表 → [Greengenes2 99% closed-reference → OTU 表] → 物种注释 → 进化树 → 多样性/排序 → 差异/关联*。方括号一段是本文的跨研究主线，下游以 OTU 表为主、ASV 表作为支线保留。关键文件名建议固定下来（全流程反复引用）：

#tablem[
  | 文件 | 含义 | 主要下游用途 |
  | :--- | :--- | :--- |
  | `table-asv.qza` | DADA2 原始 ASV 计数表 | ASV 支线、PICRUSt2、参考库覆盖度 |
  | `rep-seqs-asv.qza` | DADA2 ASV 代表序列 | closed-reference mapping、序列分析 |
  | `denoising-stats.qza` | DADA2 五阶段统计 | 质控与嵌合体比例评估 |
  | `table-gg2-cr99.qza` | Greengenes2 99% closed-reference OTU 表 | 群落组成、Alpha/Beta、多数 OTU 层面统计 |
  | `rep-seqs-gg2-cr99.qza` | 映射后的代表参考序列 | 与 OTU 特征 ID 对应的注释、序列核查 |
  | `unmatched-asvs-gg2.qza` | 未匹配 Greengenes2 的 ASV | 映射率评估、未覆盖序列分析 |
  | `taxonomy-gg2.qza` | 与 closed-reference 表特征 ID 对应的注释 | `taxa collapse`、`taxa barplot` |
  | `tree-gg2.qza` | 与 closed-reference 特征 ID 匹配的树 | Faith PD、UniFrac |
]

下面逐节展开。

#line()

== 1. 数据质量评估及 QC

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

=== 1.2 用 Cutadapt 去引物（q2-cutadapt）

DADA2 不会自己「识别并切除」引物——它只是按 `--p-trim-left` 盲切固定长度。*若下机序列里引物还在，而你不知道引物有多长，最稳妥是用 Cutadapt 显式去引物*。常见扩增区的引物如下（写论文时也常需要提供）：

#tablem[
  | 扩增区 | 正向引物（5'→3'） | 反向引物（5'→3'） |
  | :--- | :--- | :--- |
  | V3–V4 | CCTACGGGNGGCWGCAG（341F） | GACTACHVGGGTATCTAATCC（805R） |
  | V4 | GTGYCAGCMGCCGCGGTAA（515F） | GGACTACNVGGGTWTCTAAT（806R） |
]

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

=== 1.3 QIIME 2 内建质控 vs 公司预处理流程

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

=== 1.5 读段级去宿主与替代质控（可选）

宿主相关样本（肠道、口腔、组织、根际）建议在去噪前先去掉「读段级宿主污染」：`taxa filter-table`（4.3 节）只能去掉已注释成线粒体 / 叶绿体的特征，而 KneadData / Bowtie2 / BWA 能在比对阶段直接剔除宿主 reads，更彻底。

```bash
# fastp 一步质控（去接头 + 滑窗质量剪切 + 过滤）
fastp -i R1.fq.gz -I R2.fq.gz -o clean_R1.fq.gz -O clean_R2.fq.gz \
  -q 20 -u 30 -n 5 -l 50 --detect_adapter_for_pe -w 16 -h fastp.html

# 建宿主索引后去宿主（以人 GRCh38 为例）
bowtie2-build GRCh38.fa human_db
kneaddata -i clean_R1.fq.gz -i clean_R2.fq.gz -db human_db \
  -o kneaddata_out --threads 16 --remove-intermediate

# 或直接用 BWA-MEM 去宿主，保留未比对 reads
bwa index GRCh38.fa
bwa mem -t 16 GRCh38.fa clean_R1.fq.gz clean_R2.fq.gz \
  | samtools view -bS -f 12 -F 256 - > nonhost.bam
```

FastQC 做单样本质量画像、MultiQC 汇总整批报告；它们与 `demux summarize` 的碱基质量图互补，多样本批次尤其值得先跑一遍 MultiQC 看整体质量是否一致。

#line()

== 2. DADA2 去噪与 ASV 构建（拼接内建）

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
- *`--p-trim-left` 用引物长度*。Illumina 下机序列 5' 端常残留引物，把正反向各切掉「引物长度」个碱基最稳（515F 约 17–19 bp，按你实际引物数）；若已用 Cutadapt 去过引物（第 1.2 节），这里设 0。
- *`--p-trunc-len` 要综合判断，不是只看 Q30*。截断位置应同时考虑：每个碱基位置的质量分布、期望错误数、截断后剩余长度、实际扩增子长度、去引物后正反向有效长度，以及双端拼接所需的最小重叠。*不要把某个固定值（如 250/230）当成通用标准*。
- *拼接的重叠长度要求*：截断后正反向 reads 的重叠要 ≥ `--p-min-overlap`（默认 12 nt）。可用 `L_overlap = L_F + L_R − L_amplicon` 估算重叠（`L_F`、`L_R` 为去引物并截断后的正反向有效长度，`L_amplicon` 为实际扩增片段长度），结果必须不小于所用最小重叠要求。

*两种入口二选一*：若第 1.2 节用 Cutadapt 去过引物，DADA2 输入 `demux-trimmed.qza` 且 `--p-trim-left` 设 0；若没跑 Cutadapt，输入 `demux.qza` 并按引物长度设 `--p-trim-left`。具体数值都必须依据你自己的 `demux.qzv` 质量图调整：

```bash
# 分支 A：已用 Cutadapt 去引物（输入 demux-trimmed.qza，左侧不再裁）
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux-trimmed.qza \
  --p-trim-left-f 0 --p-trim-left-r 0 \
  --p-trunc-len-f 250 --p-trunc-len-r 230 \
  --p-max-ee-f 2 --p-max-ee-r 2 --p-trunc-q 2 --p-n-threads 8 \
  --o-representative-sequences rep-seqs-asv.qza \
  --o-table table-asv.qza \
  --o-denoising-stats denoising-stats.qza

# 分支 B：未跑 Cutadapt（输入 demux.qza，按引物长度切左侧）
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux.qza \
  --p-trim-left-f 20 --p-trim-left-r 20 \
  --p-trunc-len-f 250 --p-trunc-len-r 230 \
  --p-max-ee-f 2 --p-max-ee-r 2 --p-trunc-q 2 --p-n-threads 8 \
  --o-representative-sequences rep-seqs-asv.qza \
  --o-table table-asv.qza \
  --o-denoising-stats denoising-stats.qza
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
# 1) 看质量：plotQualityProfile(fnFs[1:2])
# 2) 过滤截断：maxEE=2 比「平均质量」更能反映错误累积
out <- filterAndTrim(fnFs, filtFs, fnRs, filtRs,
                     truncLen = c(240, 160), maxN = 0,
                     maxEE = c(2, 2), truncQ = 2, rm.phix = TRUE,
                     multithread = TRUE)
# 3) 学错误模型 → 4) 去噪 → 5) 拼接
errF    <- learnErrors(filtFs, multithread = TRUE)
dadaFs  <- dada(filtFs, err = errF, multithread = TRUE)
mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, verbose = TRUE)
# 6) 去嵌合体（consensus 法）
seqtab.nochim <- removeBimeraDenovo(seqtab, method = "consensus", multithread = TRUE)
```

`truncLen=c(240,160)` 与 `--p-trunc-len-f/-r` 完全对应；`maxEE=2` 即 `--p-max-ee`；`removeBimeraDenovo(method="consensus")` 即 DADA2 默认的去嵌合体策略。两套写法二选一即可，结论应一致。

实际项目常把两者拼起来：先用 QIIME 2 导入并 `demux summarize` 定参数，再切到 R 的 DADA2 环境跑，产出 `ASVs_counts.tsv` 与 `ASVs.fa`（供第 4 节的注释与聚类复用）。一个可用的作业骨架：

```bash
conda activate qiime2-2024.2
qiime tools import --type 'SampleData[SequencesWithQuality]' \
  --input-path manifest.csv --output-path demux.qza \
  --input-format SingleEndFastqManifestPhred33V2
qiime demux summarize --i-data demux.qza --o-visualization demux.qzv
conda deactivate
module load R/4.1.3
source /path/to/miniconda3/etc/profile.d/conda.sh && conda activate micro
Rscript dada2_YL.r "${file_path}" trim
```

#line()

== 3. DADA2 输出质量审核与 ASV 特征整理

=== 3.1 嵌合体：DADA2 已内建，勿重复筛

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

=== 3.2 低丰度及低出现率特征过滤

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
- 过滤过严会丢掉低丰度但真实存在的类群，过松则残留噪声。阈值需结合测序深度、研究问题与污染控制结果确定，并*建议做阈值敏感性分析*；文中 `10 / 2` 只是示例，不是普适标准。

=== 3.3 ASV 长度分布与非目标序列

- *长度检查*：`qiime feature-table tabulate-seqs` 可看每条 ASV 长度；明显短于预期扩增子（如截断后 ＜200 bp）的多来自接头自连或严重错切，应重点核查。
- *细胞器序列*：16S 通用引物会扩到宿主线粒体 / 叶绿体，需用 `taxa filter-table`（见 4.5）剔除。
- *低生物量样本的试剂污染*：皮肤、组织、低微生物量环境里，提取 / PCR 试剂本身带来的污染会扭曲 Alpha/Beta 多样性。这类「实验污染」与被扩增到的「生物学非目标（线粒体 / 叶绿体）」不同，应结合*阴性对照*用 `decontam` 识别，而不是简单把低丰度特征全当污染删掉。

=== 3.4 阴性对照、阳性对照与污染识别（decontam）

- *阴性对照*：DNA 提取空白（extraction blank）与 PCR 空白（PCR negative control），用于识别试剂、耗材与环境带来的污染序列。
- *阳性对照 / Mock Community*：已知组成的菌群混合物，用来验证流程能否正确检出、扩增偏好与去噪是否异常。
- *污染识别*：`decontam`（R 包）用 prevalence（是否在阴性对照中出现）或 frequency（DNA 浓度—丰度关系）建模判定污染特征。示意：`isContaminant(seqtab, method = "prevalence", neg = neg_samples)`。*不能仅凭「低丰度」就认定污染*，也不能不看阴性对照就直接过滤；污染过滤前后应核对样品测序量、特征数与主要结论是否稳定。

#line()

== 4. OTU 统计分析及注释

=== 4.1 ASV 与 OTU：先分清再动手

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
  --i-table table.qza \
  --i-sequences rep-seqs.qza \
  --p-perc-identity 0.97 \
  --o-clustered-table table-dn-97.qza \
  --o-clustered-sequences rep-seqs-dn-97.qza
```

- *de novo*：不依赖参考库，按数据自身相似度聚类（上面的 97% / 99%），用于传统 OTU 分析。
- *open-reference*：先闭合参考、再对剩下的 de novo，兼顾两者，但耗时。
- *closed-reference*：只保留能比对到参考库的序列，把 ASV 归并到参考特征，*实现跨研究统一特征空间*——这正是本文主线要做的（见 4.2）。

去冗余（`dereplicate-sequences`）是 de novo 聚类的常见前置步骤，可先合并重复序列再加速；所有 vsearch 聚类都应在去嵌合体之后做。

=== 4.2 Greengenes2 99% closed-reference mapping（主线）

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

=== 4.3 映射率（mapping rate）与未匹配 ASV 质控

映射率衡量有多少 ASV reads 落到了参考库，是跨队列整合的关键质控。*样本级*定义：

```text
Mapping rate_i = 样本 i 映射成功的 reads / 样本 i 输入 closed-reference 的 ASV reads × 100%
```

把原始 ASV 表与 closed-reference 表都导出为 BIOM/TSV，在 R 中计算（导出的 BIOM TSV 是*行=特征、列=样本*）：

```r
read_biom_tsv <- function(f) {
  as.matrix(read.delim(f, row.names = 1, skip = 1,
                       check.names = FALSE, comment.char = ""))
}
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

*队列级 QC 是研究特定规则，不是行业标准*：例如某大型跨队列研究设定了「超过 30% 样本嵌合体比例 >25% 则排除该队列」「排除 mapping rate 为 0 的样本」「队列整体 mapping rate ＜70% 排除该队列」。这些可作为多队列整合的示范，但单队列项目不应照搬。建议做一张 QC 汇总表，逐队列记录样本数、去噪成功率、嵌合体比例、mapping rate 分布与最终保留数。

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

*主线（OTU 表）的注释用 Greengenes2 backbone taxonomy*，而不是 SILVA 分类器——`table-gg2-cr99.qza` 的 feature ID 是 Greengenes2 参考序列 ID，直接用同版本 `2024.09.backbone.tax.qza` 按 ID 对应：

```bash
qiime taxa collapse \
  --i-table table-gg2-cr99.qza \
  --i-taxonomy 2024.09.backbone.tax.qza \
  --p-level 6 \
  --o-collapsed-table table-gg2-l6.qza
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

官方预训练分类器（按扩增区选，下载即用，见附录 B）：`silva-138-99-515-806-nb-classifier.qza`（V4）、`gg-13-8-99-515-806-nb-classifier.qza`（Greengenes V4）等。

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
  --i-taxonomy 2024.09.backbone.tax.qza \
  --p-exclude mitochondria,chloroplast \
  --p-mode contains \
  --o-filtered-table table-clean.qza
```

此后群落组成（第 5 节）、Alpha/Beta（第 6/7 节）统一使用经过过滤的 `table-clean.qza`（及同 ID 的 `tree-gg2.qza`），*不要一会儿用 ASV 表、一会儿用 OTU 表*。

若引物只扩增某个高变区（如 V3–V4、V4），最稳是用*相同引物* `extract-reads` 截取参考区段后再训练（见附录 B）；附录 B 的 V4 `extract-reads` 示例*不适用于 V3–V4 数据*，需换成 V3–V4 引物重新截取。

#line()

== 5. 物种丰度统计及群落组成分析

有了特征表和分类注释，就可以回答第一个生态学问题：「这群落里都有谁、各占多少」。核心是*把特征表按分类水平合并，再计算相对丰度并可视化*。

=== 5.1 按分类水平合并与相对丰度

```bash
# 合并到门（level 2）与属（level 6），注释用与 OTU 表同 ID 的 Greengenes2 taxonomy
qiime taxa collapse \
  --i-table table-clean.qza \
  --i-taxonomy 2024.09.backbone.tax.qza \
  --p-level 2 \
  --o-collapsed-table table-gg2-l2.qza

qiime taxa collapse \
  --i-table table-clean.qza \
  --i-taxonomy 2024.09.backbone.tax.qza \
  --p-level 6 \
  --o-collapsed-table table-gg2-l6.qza

# 转成相对丰度（每样本各特征占比之和为 1）
qiime feature-table relative-frequency \
  --i-table table-gg2-l6.qza \
  --o-relative-frequency-table rel-l6.qza
```

分类水平编号：1 界、2 门、3 纲、4 目、5 科、6 属、7 种。

注意 `relative-frequency` 是「逐样本」归一（每个样本各特征占比之和为 1），便于跨样本比较组成，但它*不是*抽平，不改变样本之间的深度差异。*差异丰度分析在第 12 节用未抽平的计数表*；Alpha/Beta 的深度处理按具体指标与方法决定（见第 6/7 节），不要把 `core-metrics` 的抽平表直接拿去做差异分析。

=== 5.2 堆叠柱状图与热图

堆叠柱状图是论文里最常见的「群落组成」图，一眼看出优势类群及其在组间的变化：

```bash
qiime taxa barplot \
  --i-table table-clean.qza \
  --i-taxonomy 2024.09.backbone.tax.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization taxa-bar-plots.qzv
```

在 view.qiime2.org 打开 `taxa-bar-plots.qzv`，可切换分类水平、按分组排序、按某个门降序排列，并导出 SVG 矢量图与 CSV 数据。*正式出图建议导出 CSV 后用 R/ggplot2 重绘*，配色、图例、排序更可控（见第 16 节的设计说明）。

热图适合展示「高丰度类群 × 样本」的分布格局，Krona 圈图则适合交互式、多层级的整体浏览。这两者通常不在 QIIME 2 内一次成图，用导出的相对丰度表在 R 中绘制（`pheatmap` / `ComplexHeatmap`），或使用公司云平台相应模块。

#line()

== 6. Alpha 多样性分析

Alpha 多样性描述*单个样本内部*的物种丰富度与均匀度。它回答「这个样本里有多少种、分布是否均衡」，不回答「两个样本像不像」——后者是第 7 节的 Beta 多样性。

=== 6.1 Alpha 多样性指数分析

先认识常用指数，避免「只看一个数就下结论」：

#tablem[
  | 指数 | QIIME 2 名称 | 表征 | 怎么读 |
  | :--- | :--- | :--- | :--- |
  | 观测特征数 | `observed_features` | 丰富度（实际看到的物种数） | 越大种类越多 |
  | Shannon | `shannon` | 丰富度 + 均匀度 | 越大多样性越高 |
  | Simpson | `simpson` | 偏向优势类群的多样性 | 需确认软件定义方向 |
  | Chao1 | `chao1` | 估计的真实丰富度（含未测到的） | 越大潜在种类越多 |
  | Faith PD | `faith_pd` | 基于进化树的多样性 | 越大进化多样性越高 |
  | Pielou 均匀度 | `evenness` | 均匀度 | 越接近 1 越均匀 |
  | Goods 覆盖度 | `goods_coverage` | 测序覆盖度 | 越接近 1 覆盖越全 |
]

几个指数的定义式（便于理解方向与量纲；`Pi` 为第 i 个类群的相对丰度，`S` 为观测到的类群数，`N` 为总个体数）：

```text
Shannon    H' = -Σ Pi·ln(Pi)
Simpson    D  = 1 - Σ Pi²          # QIIME 2 的 simpson 即此「多样性」方向，越大越多样
Pielou 均匀度 E  = H' / ln(S)
Margalef   R  = (S - 1) / ln(N)
Gleason    R  = S / ln(A)          # A 为个体数或样本数
Alatalo    Ea = [1/ΣPi² - 1] / [exp(H') - 1]
```

`core-metrics-phylogenetic` 只算一部分指标（shannon、observed_features、faith_pd、evenness 等）；Chao1、Simpson 等要单独算（不同版本可用指标略有差异，以 `qiime diversity alpha --help` 为准）：

```bash
qiime diversity alpha \
  --i-table table-clean.qza \
  --p-metric chao1 \
  --o-alpha-diversity chao1.qza
```

*Faith PD（系统发育多样性）* 不是数物种，而是把「该样本所含类群在进化树上连通的枝长」加起来：`PD = Σ 分支长度`。它需要第 8 节的定根树，在 R 里用 `picante::pd(comm, phy, include.root = TRUE)` 也可复算。所以 Faith PD 比「观测物种数」多了一层进化距离信息。

一次性算齐核心 Alpha/Beta 指标的最省事办法是 `core-metrics-phylogenetic`（它需要进化树，见第 8 节；*实际流程中先建树、再跑这一步*）：

```bash
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny tree-gg2.qza \
  --i-table table-clean.qza \
  --p-sampling-depth 10000 \
  --m-metadata-file metadata.tsv \
  --output-dir core-metrics-results
```

*`--p-sampling-depth` 会静默删除所有深度低于该值的样本*——它常被当成「穿着归一化外衣的删样本旋钮」。运行前务必在 `table.qzv` 的 Interactive Sample Detail 里确认哪些样本会被丢弃，并在方法部分报告丢弃的样本数与原因。深度选择*没有普适阈值*（不应硬套 90% / 5000 / 10000）：应绘制样本深度分布、计算不同深度下的样本保留数、对比不同深度下 Alpha/Beta 的结果，再定值；并对关键结论做不同深度的敏感性分析。历史经验值（如 1000）来自 454 时代，不可照搬。

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

=== 6.2 物种多样性稀释曲线

稀释曲线（rarefaction curve）回答一个前置问题：*测序深度够不够*。它按不同抽样深度重算多样性，曲线趋于平台说明「再多测也发现不了多少新物种」，此时比较 Alpha 多样性才可靠。

```bash
qiime diversity alpha-rarefaction \
  --i-table table-clean.qza \
  --i-phylogeny tree-gg2.qza \
  --p-max-depth 20000 \
  --p-metrics shannon observed_features faith_pd \
  --m-metadata-file metadata.tsv \
  --o-visualization alpha-rarefaction.qzv
```

默认在每个深度重复抽样若干次（`--p-iterations`，默认约 10 次）来画误差条，深度点越多曲线越平滑。*别和「物种累积曲线」混淆*：这里的稀释曲线是*固定样本、改抽 reads 深度*，回答「单样本还要测多深」；而物种累积曲线是*改样本数量*，回答「还要采多少样本能发现多少 taxa」，在 R 里用 `vegan::specaccum`。进阶做法（CHM 稿件）是对 1 到 N 个样本的每个规模随机抽样多次（如 150 次），统计独特 taxa 数、取均值，再用 `mgcv` 的 GAM（`y ~ s(x, bs = "cs")`）平滑——这是样本累积曲线，与 `alpha-rarefaction` 不是一回事。

`--p-max-depth` 一般取样本测序量最大值（若最大值是离群值，取第三四分位数到最大值之间的合理值）。在 `alpha-rarefaction.qzv` 里切换指数即可看到各分组随深度变化的曲线。*曲线未达平台时，不要急着解读组间 Alpha 差异*，因为差异可能只是测序量不同造成的。

#line()

== 7. Beta 多样性分析

Beta 多样性描述*样本之间*的群落差异，是「分组有没有意义」的核心证据。它先算样本两两之间的距离矩阵，再做排序（第 10、14 节）与统计检验（本节）。

=== 7.1 距离指标怎么选

#tablem[
  | 距离 | QIIME 2 名称 | 是否用进化树 | 是否加权丰度 | 特点 |
  | :--- | :--- | :--- | :--- | :--- |
  | Bray–Curtis | `bray_curtis` | 否 | 是 | 生态学最常用，敏感于丰度 |
  | Jaccard | `jaccard` | 否 | 否 | 只看有无，不看多少 |
  | 加权 UniFrac | `weighted_unifrac` | 是 | 是 | 结合进化关系与丰度 |
  | 非加权 UniFrac | `unweighted_unifrac` | 是 | 否 | 结合进化关系、只看有无 |
]

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

经验：*一般同时报告 Bray–Curtis 与 unweighted UniFrac*，前者看丰度格局，后者看进化层面的「有无」。UniFrac 需要第 8 节的进化树，因此 `core-metrics-phylogenetic` 会把四种距离矩阵一次性算好，输出在 `core-metrics-results/` 下。

=== 7.2 组间差异检验（PERMANOVA / ANOSIM / PERMDISP）

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

`--p-method` 可选 `permanova`（默认，常用）、`anosim`、`permdisp`。*PERMDISP 不是可选项，而是 PERMANOVA 的标准配套检查*：先看 PERMDISP，若显著（组内离散度不一致），PERMANOVA 的组间差异就可能只是「组内离散度不同」造成的，不能直接归因于群落组成变化。结果含组间距离分布箱线图与两两比较的 P 值 / Q 值。*报告时同时给出 R²（解释度）与 P 值*，R² 大说明分组对差异的解释力强。

三种检验的分工与统计量：

#tablem[
  | 方法 | 统计量 | 取值范围 | 含义 |
  | :--- | :--- | :--- | :--- |
  | PERMANOVA / Adonis | R² | 0 – 1 | 分组因素解释的方差比例，越大越强 |
  | ANOSIM | R | -1 – 1 | 组间 / 组内差异的相对大小，越近 1 越强 |
  | PERMDISP | F / P | — | 组内离散度是否一致（方差齐性检查） |
]

这些在 R 里用 `vegan` 也能方便地交叉验证：

```r
library(vegan)
meta <- read.delim("metadata.tsv", row.names = 1, comment.char = "")
meta <- meta[rownames(comm), , drop = FALSE]              # 与 comm 样本顺序对齐
adonis2(d_bc ~ Group, data = meta, permutations = 999)    # 报 R² 与 P
anosim(d_bc, grouping = meta$Group, permutations = 999)   # 报 R 与 P

# PERMDISP：组内离散度（PERMANOVA 的前置检查）
bd <- betadisper(d_bc, meta$Group)
permutest(bd, permutations = 999)                         # 显著 → 组内离散度不一致
plot(bd)
```

#line()

== 8. 系统进化树分析

进化树在 16S 分析里不是「配角」：*Faith PD、UniFrac 都依赖它，所以它必须在做多样性之前建好*。目录里它排在第 8 节，但请把它的命令提前到第 6、7 节之前执行。

=== 8.1 建树流程

标准做法是 MAFFT 多序列比对 → 去高变/低信息区（masking）→ FastTree 建树 → 定根：

```bash
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs-gg2-cr99.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree tree-gg2.qza
```

- *aligned*：多序列比对结果。
- *masked-aligned*：屏蔽掉比对中信息量低的高变区，避免错误分支。
- *unrooted-tree*：未定根的树。
- *rooted-tree*：定根后的树，*多样性分析用它*。

*建树前先确认特征 ID 对齐*：树的 tip 必须覆盖特征表 `table-gg2-cr99.qza` 的*每一个* feature ID（树可多 tip，但不能少）；若做过过滤（如 3.2），要用过滤后的表重建或核对，否则 `core-metrics-phylogenetic` 会报错。也可直接使用与 closed-reference 表同 ID 的 Greengenes2 参考树 `tree-gg2.qza`（CHM 稿件即如此），但必须确保 *taxonomy、tree、table 三者来自同一 release / ID 命名空间*。

若追求更高建树精度，可在比对基础上用 IQ-TREE 建树（输入对齐后的序列），代价是耗时更长；它属进阶方法，不必每个数据集都做：

```bash
qiime phylogeny iqtree \
  --i-alignment aligned-rep-seqs.qza \
  --p-n-cores 8 \
  --o-tree iqtree-tree.qza
```

*短读长 de novo 建树的局限*：从 250–460 bp 的 ASV de novo 建树，深层分支不可靠，会传导到 Faith PD 与 UniFrac。更稳的现代替代是 *SEPP 片段插入到参考树*（如 Greengenes2 参考树）或直接用 Greengenes2 放置——本文 closed-reference 主线本就用参考树，正是为此。

=== 8.2 树的查看与美化

`rooted-tree.qza` 可直接用于 UniFrac/Faith PD；若要在论文中展示，把它导出为 Newick，再在 #link("https://itol.embl.de")[iTOL] 网页端或 R 的 `ggtree` 中加注释、着色、加图例：

```bash
qiime tools export \
  --input-path rooted-tree.qza \
  --output-path export/tree
# 导出后得到 export/tree/tree.nwk，可直接上传 iTOL 或用 ggtree 读取
```

#line()

== 9. Rank-Abundance 分析

等级丰度曲线（Rank-Abundance Curve）用一张图同时讲两件事：*横轴的长度=丰富度，曲线的陡缓=均匀度*。物种多则曲线向右延伸得长；分布均匀则曲线平缓；少数类群独大则曲线陡降。

QIIME 2 不直接出这张图，标准做法是在 R 里用相对丰度表绘制：

```r
library(ggplot2)

# BIOM 导出的 TSV 是「行=特征，列=样本」→ 先转置成 样本×特征
dat  <- read.delim("feature-table.tsv", row.names = 1, skip = 1, check.names = FALSE)
comm <- t(dat)                                 # 行=样本，列=特征

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

== 10. 样品间主坐标分析（PCoA）与主成分分析（PCA）

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

dat  <- read.delim("feature-table.tsv", row.names = 1, skip = 1, check.names = FALSE)
comm <- t(dat)                                  # 样本×特征
comm <- comm[, colSums(comm) > 0, drop = FALSE] # 去掉全零特征（这里是「列」，不是行）

# Hellinger 变换后做 PCA；vegan::rda() 无约束公式时即为 PCA
pca <- rda(decostand(comm, method = "hellinger"))
# 等价写法：prcomp(decostand(comm, "hellinger"), scale. = TRUE)

sc <- scores(pca, display = "sites", choices = 1:2)
plot(pca, type = "n")
points(sc, pch = 21, bg = "steelblue")
```

出图时同样要在坐标轴标注解释率，并用颜色区分分组。*概念提醒*：`rda()` 无约束（不带 `~ 因子`）时做的是 PCA，带约束公式时才是 RDA——二者共享同一底层算法，但统计含义不同。另外，PCA 与 PCoA *不要求结论一致*：它们输入不同（丰度矩阵 vs 距离矩阵）、假设不同，结果差异本身需要解释，而不是强行对齐。

#line()

== 11. 样品非加权配对平均法聚类分析（UPGMA）

UPGMA（非加权配对平均法）是一种层次聚类：*每次把距离最近的两个对象并成一簇，用组间平均距离继续合并*，最终形成一棵样本聚类树。它和 PCoA 是「一体两面」——都基于距离矩阵，一个用坐标展示，一个用树形展示。QIIME 2 不直接提供样本 UPGMA，用 R 实现：

```r
library(vegan)
library(ape)

dat  <- read.delim("feature-table.tsv", row.names = 1, skip = 1, check.names = FALSE)
comm <- t(dat)                                  # 样本×特征
comm <- decostand(comm, method = "total")       # 可选：先转相对丰度
d    <- vegdist(comm, method = "bray")          # 样本间 Bray-Curtis 距离

hc <- hclust(d, method = "average")             # average linkage = UPGMA
plot(as.dendrogram(hc), horiz = TRUE, hang = -1)
```

`method = "average"` 就是 UPGMA；换成 `"ward.D2"`、`"complete"` 则是其他聚类策略。若想评估分枝的可靠性，可加 `pvclust` 做 bootstrap 支持率；出图用 `ggtree` 或 `dendextend` 比基础绘图更方便与堆叠柱状图拼合。发表时常用「左侧聚类树 + 右侧物种堆叠柱状图」的组合图（R 里 `aplot` / `patchwork` 可拼），一眼看出聚类分枝与群落组成是否对应。

#line()

== 12. 组间显著性差异分析

前面几节回答「整体结构是否不同」，本节回答「*到底哪些物种/特征在组间显著不同*」。这是论文创新点的富矿，也是统计最容易出问题的地方——*只报 P 值不校正多重比较，结论不可靠*。

=== 12.1 ANCOM / ANCOM-BC（QIIME 2 原生）

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
# 注意：2024.2 的 ancombc 输出的是差异丰度 Artifact，不是 qzv
qiime composition ancombc \
  --i-table table-gg2-l6.qza \
  --m-metadata-file metadata.tsv \
  --p-formula "Group" \
  --o-differentials ancombc-l6.qza

# 单独把差异丰度 Artifact 转成可读/可视化表（参数名以本机 --help 为准）
qiime composition tabulate \
  --i-data ancombc-l6.qza \
  --o-visualization ancombc-l6.qzv
```

*一个真实结果长什么样*：以刘永鑫教程的测试数据为例，ANCOM 在属水平只检出 *1 个*差异显著类群（*Pleomorphomonas* 属的一个 ASV）。属水平差异类群少是常见现象，但要先确认*样本量与检验力是否足够*——若样本量小、测序深度低，「只检出 1 个」可能只是检验力不足，而不是真的没有差异；怀疑时用 ANCOM-BC2 / LinDA 做敏感性分析，而不是直接接受「差异少」的结论。

ANCOM 的原理建立在「类群之间两两 log 比值」的 Aitchison 思想上：它不假设绝对丰度，只看类群之间的相对关系，所以特别适合 16S 这种组成型数据；`add-pseudocount` 是给零值加一个极小伪计数，避免 `log(0)`。

结果以火山图 / 条形图展示显著差异的分类单元，需结合 `taxonomy.qzv` 把特征 ID 翻译成物种名。*建议在属水平做差异分析*，结果更容易做生物学解释。

=== 12.2 LEfSe 与 Metastats

- *LEfSe*：线性判别分析 + 效应量，专门找「标志物种（biomarker）」。它不在 QIIME 2 内，用独立命令行或 Galaxy/Huttenhower 网页版。核心参数：logarithmic LDA score 阈值 4.0；分组数 ≥2 且每组样本 ≥2。
- *Metastats*：逐特征做组间检验（t 检验/Wilcoxon），P 值校正得 Q 值。可在 R 中自行实现，或用公司流程。

```bash
# LEfSe 输入不是 QIIME 的 BIOM 表，必须转成 LEfSe 格式（行为特征、列为样本，含分组行）
# -c 是「类别变量所在的列编号」（整数，从 1 开始），不是列名字符串；-f r 表示输入为相对丰度
lefse_format_input.py otu_table.txt otu.in -c 1 -f r
run_lefse.py otu.in otu.res -l 4.0
plot_res.py otu.res lefse.png
```

要点：`-c` 给的是*列号*而非 `Group` 这样的列名；若数据含 subclass / subject 信息，再加 `-s` / `-u` 指定其列号（没有就别加，否则报错）。跑之前先用 QIIME 把特征表/注释导出成 LEfSe 可读的纯文本表，并确认分组列的位置。

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

=== 12.3 其他差异丰度方法（MaAsLin3 / LinDA / metagenomeSeq）

ANCOM-BC 之外，主流还有几种，假设不同、可互为校验：

#tablem[
  | 方法 | 原理 | 适用 |
  | :--- | :--- | :--- |
  | ANCOM-BC2 | 偏差校正，直接估计绝对丰度级倍数变化 | 组成型、控制假阳性 |
  | MaAsLin3 | GLM + 固定 / 随机效应 | 多协变量、纵向 / 多中心 |
  | LinDA | log-ratio 线性模型 | 速度快、FDR 控制好 |
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

*多方法共识（强烈建议）*：同一张特征表用 ANCOM-BC2 / LinDA / MaAsLin2（或 ALDEx2）各跑一遍，结果往往*显著类群重叠但并非一致*。可靠做法是取*至少两个组成型方法方向一致、且各自 BH 校正后仍显著（p ≤ 0.05）*的类群作为「共识差异特征」，而不是只跑一个工具就下结论。同时务必区分*相对丰度变化≠绝对丰度变化*——16S 无法推断绝对载量，除非有 qPCR 或 spike-in 锚定。文中 12.1 用 QIIME 2 命令入门，复杂设计（协变量、纵向、随机效应）请切到 R 的 `ANCOMBC::ancombc2()`。

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

dat  <- read.delim("feature-table.tsv", row.names = 1, skip = 1, check.names = FALSE)
comm <- t(dat)                                   # 样本×特征（vegan 群落矩阵约定）
comm <- comm[, colSums(comm) > 0, drop = FALSE]
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
```

#line()

== 14. 非度量多维尺度分析（NMDS）

NMDS（非度量多维尺度分析）与 PCoA 都是排序，但思路不同：*PCoA 尽量保持真实距离，NMDS 只保持样本间距离的「排序（次序）」*。因此 NMDS 对距离的绝对数值不敏感，特别适合「只能得到样本间等级关系」的情形，也更扛得住非线性。

关键指标是 *Stress*：衡量「降维后的距离」与「原始距离排序」的吻合程度。*一般 Stress < 0.2 可接受，< 0.1 较好*；Stress 太高说明二维平面装不下真实结构，需要换维数或换距离。R 实现：

```r
library(vegan)

dat  <- read.delim("feature-table.tsv", row.names = 1, skip = 1, check.names = FALSE)
comm <- t(dat)                                  # 样本×特征

# ASV/OTU 丰度高度偏态：先 Wisconsin 双标准化或 sqrt 变换，
# 避免少数高丰度特征主导距离排序
comm_w <- wisconsin(sqrt(comm))
d <- vegdist(comm_w, method = "bray")

meta <- read.delim("metadata.tsv", row.names = 1, comment.char = "")
meta <- meta[rownames(comm), , drop = FALSE]    # 按样本顺序对齐

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

== 15. 微生物共发生网络分析（SPCC / SparCC / SPIEC-EASI）

共发生网络（co-occurrence network）把每个类群（属 / OTU / ASV）当成节点，把「两个类群在不同样本中丰度是否协同变化」当成边。正相关 = 共发生（可能互利或同生态位），负相关 = 互斥（竞争 / 拮抗）。它把分析从「谁在」推进到「谁和谁相关」。

=== 15.1 为什么不能用 Pearson：组成型数据

16S 丰度是组成型（compositional）数据：各特征相对丰度之和恒为 1，一个类群升高会「挤压」其他类群的相对值，直接算 Pearson 相关会得到大量假相关。因此要用专门处理组成型数据的稀疏相关 / 偏相关方法：

#tablem[
  | 方法 | 原理 | 实现 | 备注 |
  | :--- | :--- | :--- | :--- |
  | SparCC | 组成型「稀疏相关」：假设多数类群无关联，迭代估计基础相关 | Python `SparCC.py` | 经典、直观 |
  | SPIEC-EASI（MB） | 稀疏*偏相关*：邻域选择 + 稳定性选择 | R `SpiecEasi::spiec.easi(method="mb")` | 推荐、稳健 |
  | SPIEC-EASI（glasso） | 图 lasso 稀疏逆协方差（偏相关） | 同上 `method="glasso"` | 备选 |
  | CCLasso / CoNet | 组成型相关 / 集成多指标 | R / Cytoscape 插件 | 补充 |
]

*别把 SparCC 与 SPIEC-EASI 混为一谈*：SparCC 估计的是「组成型稀疏*相关*」（correlation）；SPIEC-EASI 估计的是「稀疏*偏相关* / 逆协方差」（conditional dependence——边表示*控制其他节点之后*仍存在的关联），二者对同一条边的生态含义不同。另外，「SPCC」并不是 SparCC 的别名，写方法时直接写 SparCC 或 SPIEC-EASI，别用含糊缩写。选一个主流方法即可，不必全做。

=== 15.2 标准流程

1. *选层级*：用属水平相对丰度表（`taxa collapse --p-level 6` + `relative-frequency`）；节点过多时先按丰度 / 出现率过滤。
2. *过滤*：去掉出现率过低、或平均相对丰度极低的类群，减少噪声边。*出现率阈值不是固定规则*（20%、30% 只是常见示例），要结合样本量、特征数、稀疏程度和研究问题设定，并对不同阈值做敏感性分析。
3. *变换与相关*：CLR 变换后估计稀疏相关 / 偏相关（SparCC 或 SPIEC-EASI）。
4. *阈值*：保留 |r| ≥ 0.6（或 0.7）且 FDR 校正后 P ＜ 0.05 的边。
5. *建网与出图*：转成图对象，用 Gephi / Cytoscape 布局、着色、导出。
6. *拓扑与关键物种*：计算度、模块度等，找 Hub 与模块连接者。

样本量决定稳健性：*一般建议 ≥ 20–30 个样本*，越多越可靠；样本太少时大量边只是噪声。

=== 15.3 R 实现（SpiecEasi + igraph）

```r
library(SpiecEasi); library(igraph); library(Matrix)
# dat：行=样本，列=属；先做出现率过滤
X  <- as.matrix(dat[, colMeans(dat > 0) > 0.2])      # 出现率 > 20%
se <- spiec.easi(X, method = "mb", lambda.min.ratio = 1e-2,
                 nlambda = 20, sel.criterion = "stars",
                 pulsar.params = list(rep.num = 50, ncores = 4))
getStability(se)                 # 稳定性选择越接近阈值 0.05 越好
adj <- getRefit(se)              # 稀疏邻接矩阵
ig  <- adj2igraph(adj)           # 转 igraph，正 / 负边可按符号着色
plot(ig, vertex.size = 3, vertex.label = NA, layout = layout_with_fr)
```

SparCC 的 Python 路线（脚本参数以官方为准）：

```bash
# otu_table：行=类群，列=样本
python SparCC.py otu_table.txt -i 10 -c sparcc_corr.txt -a sparcc_pvals.txt -x 100
```

再用相关与 P 值阈值筛边，导入 igraph / Gephi。

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

=== 15.6 解读底线

- *相关 ≠ 因果*：网络边只是统计关联，Hub 只是假设，需培养 / 实验验证。
- 组成型、阈值、样本量都会改变网络结构；方法部分要写清「层级、过滤、方法、阈值、FDR」。
- 正负边分开解读：负边可能是竞争，也可能是组成效应造成的假象。

#line()

== 16. 从结果到论文：出图、统计与常见坑

做到这里，你已经有了一套可复现的结果。要让它们变成「能发表的图」，还要过几道关。

=== 16.1 出图与配色

- *矢量优先*：论文图用 SVG/PDF，别用截图；QIIME 2 的 qzv 可导出 SVG，R 用 `ggsave(..., device = "svg")`。
- *克制配色*：分组颜色选一套对色盲友好、区分度高的调色板；避免彩虹色堆叠柱状图。
- *对齐与信息密度*：坐标轴统一字体字号，图例、标签对齐；一张图只讲一件事，把 P 值、R²、Stress 等关键统计量直接标在图上或图注里。
- *R 端重绘*：堆叠柱状图、PCoA、Alpha 箱线图，导出 CSV 后用 ggplot2 重绘，能完全掌控样式。

=== 16.2 统计报告的底线

- 组间差异*必须做多重检验校正*，报告 P 值、Q 值、效应量。
- Alpha 用 Kruskal–Wallis（多组）或 Wilcoxon（两组）；Beta 用 PERMANOVA（报 R²、P），并用 PERMDISP 检查离散度。
- 小样本研究的结论要克制，写成「提示……，仍需进一步验证」，不要绝对化。

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

- *PICRUSt2 功能预测（走 ASV 支线）*：以*质控后的 ASV 表 `table-asv.qza` + ASV 代表序列 `rep-seqs-asv.qza`* 为输入（*不要*换成 closed-reference OTU 表——PICRUSt2 要把序列放置到参考系统发育树上，OTU 的参考编号会破坏这一步）。QIIME 2 里用 `q2-picrust2`，关键参数 `--p-max-nsti 2`（weighted NSTI > 2 表示该序列偏离参考树较远、预测不可靠，会被剔除或标记）；输出 EC（酶）、KO（KEGG 同源）、MetaCyc pathway 三类预测。
- *Tax4Fun2*：按 16S 与参考基因组的相似度直接映射 KEGG 功能，适合环境样本、可自建参考集，可与 PICRUSt2 互为校验。
- *FAPROTAX 生态功能*：用「分类单元→功能」经验映射表，把 16S 物种表翻译成碳 / 氮 / 硫循环、发酵、光养等功能；只有 16S 又关心元素循环时最常用（`collapse_table.py`）。
- *BugBase 表型预测*：输出革兰氏阴阳性、好氧 / 厌氧、生物膜形成、致病性等表型比例。
- *FUNGuild 真菌功能*：把 ITS 物种映射到 *病理营养型（pathotroph）、共生营养型（symbiotroph）、腐生营养型（saprotroph）* 三大营养型及其细分 guild。

这些是从「物种描述」走向「功能推断」的加分项，但预测结果仍需实验验证；网络分析见第 15 节。若问题变成「群落像谁、来自谁」，用来源追踪：`SourceTracker2`（贝叶斯混合 + Gibbs）或 `FEAST`（EM 混合模型）估计 source→sink 的贡献比例。*前提*：必须先有明确的 source / sink 采样设计（例如同个体的口腔→肠道配对），否则来源追踪无法解释；预测出的来源比例是*模型估计*，不是直接观测到的微生物转移事件，Unknown 比例也不可当作可忽略的噪声。

#line()

== 17. 进阶与跨研究模块（选读）

本节不属前面 14 个必学主题，而是跨研究整合常用、单队列项目也可借鉴的进阶做法。读不读不影响跑通主线。

=== 17.1 实验设计与 Metadata 质量控制

主线能走多远，取决于 metadata 的设计质量。合格 metadata 至少应含：sample-id（唯一、与特征表严格对应）、Group、Age、Sex、Batch、SubjectID、Time、采样部位、16S 可变区、测序平台。要点：

- 样本 ID 唯一且与特征表严格一致；分类变量*别用数字编码*（`1/2` 会被当连续变量）。
- 缺失值保留 `NA`，*不要主观补值*；原始论文 / SRA 无法确认的字段宁缺勿造。
- 同一受试者、同部位、同时间点的技术重复，是否合并 / 去重必须*预先定义*并记录。
- *Batch（测序批次）必须入表*——后面 PERMANOVA 的 `strata`、模型协变量、随机效应都靠它。
- 建议每个队列留存：原始 manifest、原始论文、整理后 metadata、整理脚本，以及 accession / 下载日期 / MD5 / 软件与数据库版本。

=== 17.2 核心微生物组（core microbiome）

16S 不只要回答「谁最多」，还要回答「谁在不同样本 / 组里*稳定出现*」。核心菌群用*出现率（prevalence）*而非丰度定义：在多大比例的样本里检出（阈值 50% / 70% / 90% 代表不同严格程度，*必须预先定义并报告*）。可视化用 UpSet 图（多组交集，`UpSetR` / `ComplexUpset`）或 Venn 图（组数少时）；同时报核心菌群的相对丰度与出现率。注意：出现率高只说明「稳定」，并不等于功能重要。

=== 17.3 配对 / 纵向与重复测量

同一受试者干预前后、多时间点、多部位、配对病例-对照的数据，*不能当独立样本做普通检验*。处理方式：

- 配对两组：配对 Wilcoxon（`wilcox.test(x, y, paired = TRUE)`）或配对距离比较。
- 重复测量 / 多协变量：线性混合效应模型，个体作随机截距：
  ```r
  library(lme4); library(lmerTest)
  lmer(Shannon ~ Group + Age + Sex + (1 | SubjectID), data = meta)
  ```
  报告边际 R² 与条件 R²（`MuMIn::r2()`），写清 complete-case 样本量与队列 / 个体数。
- Beta 端：QIIME 2 `q2-longitudinal`（如 `pairwise-differences`、`linear-mixed-effects`），或把个体作为 `strata` 的重复测量 PERMANOVA。

=== 17.4 机器学习与跨研究验证（LOSO）

用微生物组做年龄 / 疾病预测时，*验证设计比算法更重要*：

- 训练 / 验证 / 测试要分开；特征筛选与预处理必须*在训练折内部*完成，防止数据泄漏。
- 跨队列泛化用 *Leave-One-Study-Out（LOSO）* 交叉验证——每次留出一个 BioProject 整合作独立测试集；别把同一队列样本同时塞进训练和测试后还宣称「跨队列泛化」。
- 指标按任务报：分类用 AUC、敏感度 / 特异度；回归（如年龄）用 MAE、R²、Spearman ρ，并给置信区间与外部验证。

=== 17.5 跨队列网络共识

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
wget https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.2-py39-linux-conda.yml
conda env create -n qiime2-2024.2 --file qiime2-amplicon-2024.2-py39-linux-conda.yml

# 3) 激活
conda activate qiime2-2024.2
qiime --help
```

国内下载 conda 清单或数据库缓慢时，可改用国内镜像或维护者备份站点；QIIME 2 中文手册（Yongxin Liu 维护）也提供备份链接。

=== 附录 B. 分类器与数据库

官方为常见引物区提供了预训练分类器，可直接下载使用；也可按第 4.3 节自行训练。若扩增的是特定高变区（如 V3–V4、V4），用对应引物 `extract-reads` 截取参考后再训练，精度更高：

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

*注意区段必须与数据一致*：上面示例用的是 *V4* 引物（515F/806R）。若你的数据是 *V3–V4*（正文 1.2 的 `CCTACGGGNGGCWGCAG` / `GACTACHVGGGTATCTAATCC`），这套 V4 `extract-reads` 与 V4 预训练分类器*都不适用*，必须换成 V3–V4 引物重新截取参考后再训练，或直接用官方 V3–V4 预训练分类器。拿错区段的分类器去注释，会得到大量 Unassigned 或系统性误注释。

常用官方预训练分类器（下载即用，免训练）：

- `silva-138-99-515-806-nb-classifier.qza`：SILVA，V4（515F/806R），最通用。
- `gg-13-8-99-515-806-nb-classifier.qza`：Greengenes 13_8，V4，兼容 PICRUSt。
- 真菌 ITS：用 UNITE 训练的分类器。

R 端 DADA2 等价注释，`minBoot` 是 bootstrap 置信阈值（默认 50）：

```r
taxa <- assignTaxonomy(seqtab.nochim, "silva_nr99_v138.1_train_set.fa.gz", multithread = TRUE)
taxa <- addSpecies(taxa, "silva_v138.1_assignSpecies.fa.gz")   # 种水平精确匹配
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
# BIOM 导出的 TSV：行=特征，列=样本，首行是注释行，故 skip = 1
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
# 看当前版本支持哪些导入格式 / 类型（比背格式名靠谱）
qiime tools import --show-importable-formats
qiime tools import --show-importable-types

# 若数据是 EMP 三文件（forward/reverse/barcodes），用 EMPPairedEndSequences 导入
qiime tools import \
  --type EMPPairedEndSequences \
  --input-path emp-paired-end-sequences \
  --output-path demux.qza

# BIOM 转 TSV 时把物种注释一并带出
biom convert -i feature-table.biom -o table-with-taxonomy.tsv \
  --to-tsv -b --header-key taxonomy
```

*deblur / vsearch 路线需要先拼接*：`qiime vsearch join-pairs --i-demultiplexed-seqs demux.qza --o-joined-sequences demux-joined.qza`，再进 `qiime deblur denoise-16S`（Deblur 会丢弃与 85% Greengenes 相似度过低的序列，速度通常快于 DADA2）。

导出的 TSV 首行常有 `# Constructed from biom file` 注释行，R 里用 `read.delim(..., skip = 1)` 跳过即可（本文各 R 代码已按此写法）。

=== 附录 D. 常见问题

- *分类器版本不兼容（scikit-learn）*：报错提示版本不匹配时，用当前环境重新训练分类器即可（附录 B）。
- *conda 清单下载失败*：改用国内镜像或中文手册的备份链接，或换用 `conda-pack` 打包好的环境。
- *内存不足（OOM）*：DADA2 与建树较吃内存，减小 `--p-n-threads`、分批处理或上服务器运行。
- *中文 / 空格路径报错*：全程使用英文、无空格的绝对路径。
- *BIOM 版本不兼容（biom 2.1.7 报错）*：新版 biom 偶有格式兼容问题，可改用 `qiime tools export` 后直接用 R 的 `read.delim`，或安装匹配版本的 biom。
- *DADA2 线程与耗时*：以 18 样本、每样本约 5 万对 reads 为例，`--p-n-threads` 取 96 / 24 / 8 / 1 时耗时约 34 / 44 / 77 / 462 分钟——线程不是越多越线性加速，找到机器的甜点即可。
- *下载慢或断*：国内可换镜像，或从维护者备份站（如 nmdc.cn、Yongxin Liu 的 GitHub 备份清单）取数据库与分类器。
- *qzv 打不开*：确认是拖到 view.qiime2.org 查看，而不是双击；离线环境用 view.qiime2.cn 或本地部署。

=== 附录 E. 从 SRA 批量下载数据（Slurm 并行）

公共数据常需按研究号批量下载 SRA。下面是一个 Slurm 数组作业的思路，与前面的 DADA2 分析脚本衔接：

```bash
# 1) 由研究号取全部 run（S、D、E 开头的 SRR/DRR/ERR）
curl -s "https://trace.ncbi.nlm.nih.gov/Traces/sra-db-be/runinfo?acc=${study_id}" \
  | awk -F ',' 'NR>1 {print $1}' | grep -E '^[SDE]RR' | tr -d '\r' > sample.txt

# 2) 下载并拆分为 FASTQ
prefetch --option-file sample.txt --output-directory sra
fastq-dump --split-3 --threads 4 sra/${run_id}/${run_id}.sra --outdir rawdata

# 3) 生成 manifest（2024.2 双端 V2 格式：列名与列数固定，不能省）
printf 'sample-id,forward-absolute-filepath,reverse-absolute-filepath\n' > manifest.csv
for fq in rawdata/*_1.fastq; do
  sid=$(basename "$fq" _1.fastq)
  r1=$(realpath "$fq"); r2=$(realpath "rawdata/${sid}_2.fastq")
  printf '%s,%s,%s\n' "$sid" "$r1" "$r2" >> manifest.csv
done
```

- manifest 必须与 `qiime tools import --type` 对应：*双端*用 `PairedEndFastqManifestPhred33V2`（三列：`sample-id`、`forward-absolute-filepath`、`reverse-absolute-filepath`）；*单端*用 `SingleEndFastqManifestPhred33V2`（*只有两列*：`sample-id`、`absolute-filepath`，见 0.2）。列名或列数写错是最常见的导入报错来源。

- 用 `#SBATCH -a 1-N` 数组作业，一个任务处理一个研究号：`sed -n "${SLURM_ARRAY_TASK_ID}p" study_list.txt` 取当前号。
- `prefetch` 失败可重试；`fastq-dump --split-3` 把双端拆成 `_1` / `_2`，单端只有一个文件。
- 生成 manifest 后用 `comm` 比对「应有」与「已下」列表，统计缺失样本。
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

# FAPROTAX（OTU 表含 taxonomy 列）
python collapse_table.py -i otu_table.txt -o func.tsv -g FAPROTAX.txt -c "#" -d ";" -v
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

== 参考与延伸阅读

本文的流程、参数与判断规则，来自下列公开资料与两份作者教程。按用途分组，方便按需回查。

=== QIIME 2 官方与规范文档

- QIIME 2 2024.2 文档：#link("https://docs.qiime2.org/2024.2/")[docs.qiime2.org/2024.2]
- 多样性插件命令参考：#link("https://docs.qiime2.org/en/latest/references/plugins/diversity/")[docs.qiime2.org/…/plugins/diversity]
- 「Moving Pictures」教程（2‑4 与 2‑3 两版）：#link("https://forum.qiime2.org/t/qiime-2-4-moving-pictures-2018-11/7598")[forum/7598]、#link("https://forum.qiime2.org/t/qiime-2-3-2018-11/7599")[forum/7599]
- 经验驱动指南（中文镜像）：#link("https://geekdaxue.co/read/QIIME2-doc-zh/2-Tutorial-03-Experienced-Driver-Guide-Experience.md")[geekdaxue QIIME2-doc-zh]
- 宿主微生物组 QIIME 2 实验流程：#link("https://protocols.hostmicrobe.org/microbio/qiime2")[protocols.hostmicrobe.org]
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

- SpiecEasi（SPIEC-EASI / SPCC 的 R 实现）：#link("https://github.com/zdk123/SpiecEasi")[github.com/zdk123/SpiecEasi]
- SparCC（基于 Aitchison 的组成型相关）：#link("https://bitbucket.org/yonatanf/sparcc")[bitbucket.org/yonatanf/sparcc]
- MENA（分子生态网络分析平台）：#link("http://ieg4.rccc.ou.edu/mena/")[ieg4.rccc.ou.edu/mena]
- QIIME 2 中文手册（Yongxin Liu）：#link("https://github.com/YongxinLiu/QIIME2ChineseManual")[github.com/YongxinLiu/QIIME2ChineseManual]
- 讲义 `diversity_analysis.md`（QIIME 2 概览与 2020.11 / 2021.2 完整流程命令）。

=== 参考库与 closed-reference 主线

- Greengenes2 2024.09 文件索引（backbone 序列与 taxonomy）：#link("https://ftp.microbio.me/greengenes_release/2024.09/")[ftp.microbio.me/greengenes_release/2024.09]
- q2-greengenes2 插件说明：#link("https://github.com/biocore/q2-greengenes2/")[github.com/biocore/q2-greengenes2]
- QIIME 2 OTU clustering 教程（closed-reference / open-reference，确认 DADA2 输出可作输入；命令参数以本机 2024.2 `--help` 为准）：#link("https://docs.qiime2.org/2024.10/tutorials/otu-clustering/")[docs.qiime2.org/2024.10/tutorials/otu-clustering]

=== 一点说明

上述链接中，部分站点为镜像、需登录或已迁移，个别页面在抓取时返回的是与标题不符的内容或纯前端渲染的空白。本文只采纳其中*可复现、与 QIIME 2 官方行为一致*的命令与数值；凡涉及具体参数处，均以「示例、需按自己数据调整」提示为准。真正跑流程时，请以 `qiime <插件> <命令> --help` 与官方 2024.2 文档为最终依据。
