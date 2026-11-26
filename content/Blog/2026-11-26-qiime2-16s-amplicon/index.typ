#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "16S rRNA 扩增子生信分析全流程：以 QIIME 2 2024.2 为主线",
  description: "面向硕士研究生的 16S 扩增子分析教程：从数据质控、序列拼接、去除嵌合体、ASV/OTU 与物种注释，到 Alpha/Beta 多样性、系统进化树、PCoA/PCA/NMDS/UPGMA、组间差异与 RDA/CCA，以 QIIME 2 2024.2 串起完整流程，并给出 R（vegan）端复现代码。",
  date: datetime(year: 2026, month: 11, day: 26),
  lang: "zh",
)

= 16S rRNA 扩增子生信分析全流程（QIIME 2 2024.2）

本文写给刚进实验室、准备上手微生物组数据的硕士研究生。它把「拿到下机数据之后该做什么、每一步用什么命令、结果怎么读」按顺序讲清楚，用 *QIIME 2 2024.2* 作为主线，把数据质控、拼接、去嵌合体、ASV/OTU 构建、物种注释、Alpha/Beta 多样性、进化树、排序分析（PCoA/PCA/NMDS/UPGMA）、组间差异与 RDA/CCA 串成一条可复现的流水线。

需要先建立一个观念：*QIIME 2 负责上游「把原始 reads 变成干净的特征表、物种注释、进化树和核心多样性指标」，而下游一批统计与可视化（PCA、NMDS、RDA/CCA、Rank-Abundance、UPGMA、LEfSe 等）通常交给 R 生态（vegan、ggplot2、ggtree）或独立工具完成*。本文会明确标注每一步属于哪一侧，避免你在 QIIME 2 里苦苦寻找一个它本来就不提供的命令。

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

=== 0.3 术语与基本量：先把话说清楚

后面反复出现的几个概念，先统一口径，免得边学边猜：

#tablem[
  | 术语 | 含义 | 为什么重要 |
  | :--- | :--- | :--- |
  | 16S rRNA 基因 | 细菌 / 古菌核糖体小亚基基因，全长约 1542 bp，含 V1–V9 约九个高变区与夹在中间的保守区 | 保守区用于设计「通用引物」，高变区用于区分物种 |
  | 扩增区（V3–V4 / V4） | 引物决定扩哪一段；V3–V4 约 460 bp、分辨力高；V4 约 250 bp、适合 2×250 | 扩增区必须与数据库、分类器一致 |
  | 测序深度 | 每个样本的 reads 条数 | 深度不足会漏掉稀有类群，且样本间不能直接比多样性 |
  | Q20 / Q30 | 碱基质量 ≥ 20 / ≥ 30 的碱基占比；Q20≈错误率 1%，Q30≈0.1% | Q20>90%、Q30>80% 通常算质量合格 |
  | 覆盖度 Coverage | 测到的物种占真实物种的比例（Goods coverage 估计） | 越接近 1，说明「测得越全」 |
  | ASV / OTU | 特征（feature）的两种单位 | 现代去噪用 ASV，经典聚类用 OTU（见第 4 节） |
]

多样性分三个层次，名字只差一个希腊字母，含义却完全不同：

#tablem[
  | 层次 | 回答的问题 | 典型指标 | 本文位置 |
  | :--- | :--- | :--- | :--- |
  | α（Alpha） | 单个样本内部有多少种、多均匀 | Shannon、Simpson、Chao1、Faith PD | 第 6 节 |
  | β（Beta） | 样本与样本之间差多少 | Bray–Curtis、Jaccard、UniFrac | 第 7 节 |
  | γ（Gamma） | 整个区域 / 所有样本合起来的总多样性 | 区域物种池丰富度 | 综合解读时提及 |
]

一个常被忽略的量：*样本间测序深度不齐时，直接比较 α 多样性会被深度差异带偏*，所以要先「抽平（rarefy）」到同一深度再比较——这就是第 6 节 `--p-sampling-depth` 的由来。

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
  | PCA / NMDS / UPGMA | R（vegan） | `rda`、`metaMDS`、`hclust` | 排序图、聚类树 |
  | 组间差异 | QIIME 2 + R/LEfSe | `composition ancom`、LEfSe | 差异特征、标志物种 |
  | RDA / CCA | R（vegan） | `rda`、`cca`、`decorana` | 约束排序图 |
  | Rank-Abundance | R | `ggplot2`、`radfit` | 等级丰度曲线 |
]

记住这条主线：*导入 → 质控去噪（拼接 + 去嵌合体）→ 特征表 → 物种注释 → 进化树 → 多样性/排序 → 差异/关联*。下面逐节展开。

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

=== 1.4 质控的「停止规则」

质控没有绝对的合格线，但有一个实用的*停止规则*：跑完去噪后看 denoising-stats 里各样本的逐级保留比例。若多数样本从 input 到 non-chimeric 的*保留率低于约 20%*，通常意味着截断 / 去引物参数设错了（截到质量陡降点之后，或引物没去干净），应回到 `demux.qzv` 重新设 `--p-trunc-len`，而不是硬着头皮往下做。数据质量差到这个程度时，下游所有多样性结论都不可信。

#line()

== 2. 序列拼接

双端测序得到的是两条 reads：正向（R1）与反向（R2），它们来自同一扩增片段的两端。*拼接（merge）就是利用两条 reads 在中间的重叠区（overlap）把它们合成为一条完整序列*。拼接质量取决于：重叠区够不够长、重叠区是否一致、以及两端质量好不好。

在 QIIME 2 中，拼接与去噪是同一命令 `dada2 denoise-paired` 完成的。关键参数先讲清楚：

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
- *`--p-trunc-len` 可以设 0 = 不截断*，但仅在两端质量都很高时才安全；绝大多数数据应截在质量开始下滑之前——判据是质量图里*中位质量降到 Q30 以下的位置*再往前留一点。
- *拼接成功的硬条件*：两条 reads 截断后仍要有足够重叠。DADA2 官方建议至少保留 `20 + 生物学长度变异` 个碱基的重叠（例如 V4 用 2×250、各截到约 220–230 通常足够）。

一条可用的双端去噪命令（具体数值必须依据你自己的 `demux.qzv` 质量图调整）：

```bash
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux.qza \
  --p-trim-left-f 20 \
  --p-trim-left-r 20 \
  --p-trunc-len-f 250 \
  --p-trunc-len-r 230 \
  --p-max-ee-f 2 \
  --p-max-ee-r 2 \
  --p-trunc-q 2 \
  --p-n-threads 8 \
  --o-representative-sequences rep-seqs.qza \
  --o-table table.qza \
  --o-denoising-stats denoising-stats.qza
```

`--p-trunc-len-f/-r` 是最容易设错的地方。*截得太短会丢信息、太靠后又会把低质量碱基带进来*；经验做法是让正向、反向 reads 截断后仍能覆盖足够长的重叠区。跑完后看去噪统计，确认每个样本的「合并后保留比例」是否合理：

```bash
qiime metadata tabulate \
  --m-input-file denoising-stats.qza \
  --o-visualization denoising-stats.qzv
```

`denoising-stats.qzv` 里有 input、filtered、merged、non-chimeric 四个逐级保留的序列数。若某样本从 filtered 到 merged 掉得特别多，通常是 overlap 太短或截断位置不当，需要回看 `demux.qzv` 重新调参。

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

#line()

== 3. 去除嵌合体及短序列分析

=== 3.1 什么是嵌合体

嵌合体（chimera）是 PCR 过程中的「拼接错误」：两条不同模板的片段在某处错误接在一起，形成自然界并不存在的「杂合序列」。若不清除，它会被当成一个新物种，虚增多样性。*DADA2 的 `denoise-paired` 默认就会去嵌合体*（`--p-chimera-method consensus`）。所以走 DADA2 主线时，这一步通常不用你额外操作，但你必须知道它已经做了，并会去检查去噪统计里的 non-chimeric 数量。

若你走的是 *OTU / vsearch 路线*（第 4 节），去嵌合体要显式执行：

```bash
qiime vsearch uchime-denovo \
  --i-table table.qza \
  --i-sequences rep-seqs.qza \
  --o-chimeras chimeras.qza \
  --o-nonchimeras nonchimeras.qza \
  --o-stats chimera-stats.qza

# 依据嵌合体列表剔除对应特征与序列
qiime feature-table filter-features \
  --i-table table.qza \
  --m-metadata-file chimeras.qza \
  --p-exclude-ids \
  --o-filtered-table table-nochim.qza
```

=== 3.2 短序列与低丰度过滤

「短序列」有两层含义：一是拼接后过短、可信度低的序列，二是在所有样本里都罕见、更可能是错误的序列。前者主要靠 DADA2 的 `--p-trunc-len` / `--p-min-overlap` 在去噪阶段控制；后者用频率与样本数阈值过滤：

```bash
# 只保留在 ≥2 个样本中出现、且总频数 ≥10 的特征
qiime feature-table filter-features \
  --i-table table.qza \
  --p-min-frequency 10 \
  --p-min-samples 2 \
  --o-filtered-table table-filtered.qza
```

过滤阈值没有金标准，*取决于测序深度与研究目的*：阈值太高会误删真实的稀有类群，太低则残留噪声。常见做法是先查看 `table.qzv` 的特征数分布，再设一个温和的阈值，并在方法部分如实报告。经验参考：小规模数据（如 ＜100 样本）常用 `--p-min-frequency 5 --p-min-samples 1`，较大规模数据用 `50 / 5` 更常见，本文示例的 `10 / 2` 是折中。

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

此外还有去冗余与闭合参考聚类，用于把序列对齐到已知参考库：

```bash
# 先做序列去冗余（dereplicate），得到唯一的代表序列
qiime vsearch dereplicate-sequences \
  --i-sequences rep-seqs.qza \
  --o-dereplicated-table table-derep.qza \
  --o-dereplicated-sequences seqs-derep.qza

# 闭合参考（closed-reference）：只保留能比对到参考库的序列
qiime vsearch cluster-features-closed-reference \
  --i-table table-derep.qza \
  --i-sequences seqs-derep.qza \
  --i-reference-sequences silva-138-99-seqs.qza \
  --p-perc-identity 0.85 \
  --o-clustered-table table-cr.qza \
  --o-clustered-sequences seqs-cr.qza \
  --o-unmatched-sequences unmatched.qza
```

- *de novo*：不依赖参考库，按数据自身相似度聚类（上面的 97% / 99%）。
- *closed-reference*：只保留能比对到参考库的序列，跨研究可比较，但会丢掉参考库没有的类群（`--p-perc-identity` 常用 0.85–0.97）。
- *open-reference*：先闭合参考、再对剩下的 de novo，兼顾两者，但耗时。

注意：这些 vsearch 聚类命令要求 ASV 序列已去冗余、且已去嵌合体，否则会把错误序列也聚进去。

=== 4.2 特征表统计

无论 ASV 还是 OTU，下一步都是看这张「样本 × 特征」的丰度表长什么样：

```bash
qiime feature-table summarize \
  --i-table table-filtered.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file metadata.tsv

qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv
```

`table.qzv` 里最有用的是 *Frequency per sample*：记下样本测序量的最小值，它就是后面多样性分析的抽平深度（`--p-sampling-depth`）的候选值。`rep-seqs.qzv` 则展示每条代表序列的长度、ID，序列可一键跳转 NCBI BLAST 比对。

=== 4.3 物种注释与数据库

物种注释是把每条特征序列比对到参考数据库，得到「界门纲目科属种」的分类。*数据库选错，注释准确率会明显下降*：

#tablem[
  | 数据库 | 适用 | 说明 |
  | :--- | :--- | :--- |
  | SILVA 138 | 细菌 / 古菌 16S 首选 | 覆盖广、更新及时，2024.2 官方提供配套序列与分类 |
  | Greengenes | 细菌 / 古菌（经典） | 老牌、肠道研究常用；新版为 Greengenes2 |
  | UNITE | 真菌 ITS | 真菌鉴定标准库 |
  | NCBI / RDP | 补充 | 按需使用 |
]

QIIME 2 常用两类注释方法：*朴素贝叶斯分类器（classify-sklearn）* 速度快、最常用；*比对一致性法（classify-consensus-blast/vsearch）* 直接比对、透明可控。两者差别：

#tablem[
  | 方法 | 命令 | 关键参数 | 特点 |
  | :--- | :--- | :--- | :--- |
  | 朴素贝叶斯 | `classify-sklearn` | `--p-confidence 0.7` | 快、最常用；confidence 越高越保守 |
  | 比对一致性（BLAST） | `classify-consensus-blast` | `--p-maxaccepts 3 --p-perc-identity 0.9 --p-query-cov 0.9 --p-min-consensus 0.51` | 透明可控；取前 N 条比对的一致性投票 |
  | 比对一致性（vsearch） | `classify-consensus-vsearch` | 同上 | 更快，适合大数据 |
]

下面用分类器法，先获取 SILVA 参考并训练（或用官方预训练分类器，见附录 B）：

```bash
wget https://data.qiime2.org/2024.2/common/silva-138-99-seqs.qza
wget https://data.qiime2.org/2024.2/common/silva-138-99-tax.qza

qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads silva-138-99-seqs.qza \
  --i-reference-taxonomy silva-138-99-tax.qza \
  --o-classifier silva-138-99-nb-classifier.qza

qiime feature-classifier classify-sklearn \
  --i-classifier silva-138-99-nb-classifier.qza \
  --i-reads rep-seqs.qza \
  --p-confidence 0.7 \
  --o-classification taxonomy.qza

qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv
```

官方预训练分类器（按扩增区选，下载即用，见附录 B）：`silva-138-99-515-806-nb-classifier.qza`（V4）、`gg-13-8-99-515-806-nb-classifier.qza`（Greengenes V4）等；用 Greengenes 主要为了后续 PICRUSt 功能预测方便。

`classify-consensus-blast` 的等价命令（更透明，可追溯每条序列投给了哪些参考）：

```bash
qiime feature-classifier classify-consensus-blast \
  --i-query rep-seqs.qza \
  --i-reference-reads silva-138-99-seqs.qza \
  --i-reference-taxonomy silva-138-99-tax.qza \
  --p-maxaccepts 3 --p-perc-identity 0.9 --p-query-cov 0.9 --p-min-consensus 0.51 \
  --o-classification taxonomy-blast.qza
```

如果是宿主相关样本（肠道、组织、根际），务必*剔除宿主污染*——16S 通用引物会扩到宿主线粒体 / 叶绿体：

```bash
qiime taxa filter-table \
  --i-table table-filtered.qza \
  --i-taxonomy taxonomy.qza \
  --p-exclude mitochondria,chloroplast \
  --p-mode contains \
  --o-filtered-table table-no-host.qza
```

`confidence` 越高越保守（更多序列会被标为 `Unassigned`）。若你的引物只扩增某个高变区（如 V3–V4、V4），最稳是用相同引物 `extract-reads` 截取参考区段后再训练，可显著提升注释精度（见附录 B）。

#line()

== 5. 物种丰度统计及群落组成分析

有了特征表和分类注释，就可以回答第一个生态学问题：「这群落里都有谁、各占多少」。核心是*把特征表按分类水平合并，再计算相对丰度并可视化*。

=== 5.1 按分类水平合并与相对丰度

```bash
# 合并到门（level 2）与属（level 6）
qiime taxa collapse \
  --i-table table-filtered.qza \
  --i-taxonomy taxonomy.qza \
  --p-level 2 \
  --o-collapsed-table table-l2.qza

qiime taxa collapse \
  --i-table table-filtered.qza \
  --i-taxonomy taxonomy.qza \
  --p-level 6 \
  --o-collapsed-table table-l6.qza

# 转成相对丰度（每样本各特征占比之和为 1）
qiime feature-table relative-frequency \
  --i-table table-l6.qza \
  --o-relative-frequency-table rel-l6.qza
```

分类水平编号：1 界、2 门、3 纲、4 目、5 科、6 属、7 种。

注意 `relative-frequency` 是「逐样本」归一（每个样本各特征占比之和为 1），便于跨样本比较组成，但它*不是*抽平，不改变样本之间的深度差异；做统计检验前仍要抽平。

=== 5.2 堆叠柱状图与热图

堆叠柱状图是论文里最常见的「群落组成」图，一眼看出优势类群及其在组间的变化：

```bash
qiime taxa barplot \
  --i-table table-filtered.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization taxa-bar-plots.qzv
```

在 view.qiime2.org 打开 `taxa-bar-plots.qzv`，可切换分类水平、按分组排序、按某个门降序排列，并导出 SVG 矢量图与 CSV 数据。*正式出图建议导出 CSV 后用 R/ggplot2 重绘*，配色、图例、排序更可控（见第 15 节的设计说明）。

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

*Faith PD（系统发育多样性）* 不是数物种，而是把「该样本所含类群在进化树上连通的枝长」加起来：`PD = Σ 分支长度`。它需要第 8 节的定根树，在 R 里用 `picante::pd(comm, phy, include.root = TRUE)` 也可复算。所以 Faith PD 比「观测物种数」多了一层进化距离信息。

一次性算齐核心 Alpha/Beta 指标的最省事办法是 `core-metrics-phylogenetic`（它需要进化树，见第 8 节；*实际流程中先建树、再跑这一步*）：

```bash
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table table-filtered.qza \
  --p-sampling-depth 10000 \
  --m-metadata-file metadata.tsv \
  --output-dir core-metrics-results
```

`--p-sampling-depth` 是抽平深度，*要选一个既能保留尽量多测序量、又只丢弃尽量少样本的值*。更具体的规则：*选一个能保留 ≥90% 样本的最大深度*。看 `table.qzv` 的 Frequency per sample：若样本测序量分布均匀，取最小值即可；若最小值会让样本骤减（与第一四分位数差距很大），就上移到某个保留绝大多数样本的深度，并在方法中写明丢弃了哪些样本。历史经验值（如 1000）来自 454 时代，如今建议 ≥5000，能做到 10000 以上更稳。

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
  --i-table table-filtered.qza \
  --i-phylogeny rooted-tree.qza \
  --p-max-depth 20000 \
  --p-metrics shannon observed_features faith_pd \
  --m-metadata-file metadata.tsv \
  --o-visualization alpha-rarefaction.qzv
```

默认在每个深度重复抽样若干次（`--p-iterations`，默认约 10 次）来画误差条，深度点越多曲线越平滑。若想看「样本数增加时物种数如何累积」，那是对应的*物种累积曲线（species accumulation curve）*，在 R 里用 `vegan::specaccum`——它回答「还要采多少样本」，与稀释曲线（「还要测多深」）互补。

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
Bray–Curtis     BC = (b + c) / (2a + b + c)         # 定量，常用
Jaccard         J  = (b + c) / (a + b + c)          # 定性，只看有无
Whittaker βw    βw = S / α_mean - 1
Cody βc         βc = [g(H) + l(H)] / 2              # g=增益物种，l=丢失物种
Wilson–Shmida   βT  = [g(H) + l(H)] / (2·α_mean)
```

R 里用 `vegan::vegdist` 一次性算好距离矩阵，便于下游聚类与排序：

```r
library(vegan)
d_bc <- vegdist(dat, method = "bray")     # Bray–Curtis
d_jd <- vegdist(dat, method = "jaccard")  # Jaccard
d_bc                                       # 下三角距离矩阵
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

`--p-method` 可选 `permanova`（默认，常用）、`anosim`、`permdisp`（检验组内离散度是否一致，常与 PERMANOVA 配合做假设检查）。结果里包含组间距离分布箱线图与两两比较的 P 值 / Q 值。*报告时同时给出 R²（解释度）与 P 值*，R² 大说明分组对差异的解释力强。

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
meta <- read.delim("metadata.tsv", row.names = 1, comment.char = "#")
adonis2(d_bc ~ Group, data = meta, permutations = 999)   # 报 R² 与 P
anosim(d_bc, grouping = meta$Group, permutations = 999)  # 报 R 与 P
```

#line()

== 8. 系统进化树分析

进化树在 16S 分析里不是「配角」：*Faith PD、UniFrac 都依赖它，所以它必须在做多样性之前建好*。目录里它排在第 8 节，但请把它的命令提前到第 6、7 节之前执行。

=== 8.1 建树流程

标准做法是 MAFFT 多序列比对 → 去高变/低信息区（masking）→ FastTree 建树 → 定根：

```bash
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza
```

- *aligned*：多序列比对结果。
- *masked-aligned*：屏蔽掉比对中信息量低的高变区，避免错误分支。
- *unrooted-tree*：未定根的树。
- *rooted-tree*：定根后的树，*多样性分析用它*。

若追求更高建树精度，可在比对基础上用 IQ-TREE 建树（输入用对齐后的序列），代价是耗时更长：

```bash
qiime phylogeny iqtree \
  --i-alignment aligned-rep-seqs.qza \
  --p-threads 8 \
  --o-tree iqtree-tree.qza
```

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

# 由 QIIME2 导出的特征表（行=样本，列=特征）
dat <- read.delim("feature-table.tsv", row.names = 1, skip = 1, check.names = FALSE)

# 取一个样本，按相对丰度降序排列后编号
x <- sort(as.numeric(dat["S1", ]) / sum(dat["S1", ]), decreasing = TRUE)
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

dat <- read.delim("feature-table.tsv", row.names = 1, skip = 1, check.names = FALSE)
mat <- t(dat)                                  # 特征 × 样本
mat <- mat[colSums(mat) > 0, , drop = FALSE]   # 去掉全零特征

pca <- rda(decostand(t(mat), method = "hellinger"))
# 或用 prcomp(decostand(t(mat), "hellinger"), scale. = TRUE)

sc <- scores(pca, display = "sites", choices = 1:2)
plot(pca, type = "n")
points(sc, pch = 21, bg = "steelblue")
```

出图时同样要在坐标轴标注解释率，并用颜色区分分组。*PCA 与 PCoA 结论一致时更有说服力；不一致时，通常是距离选择或变换方式造成的差异，需要在方法中说明*。

#line()

== 11. 样品非加权配对平均法聚类分析（UPGMA）

UPGMA（非加权配对平均法）是一种层次聚类：*每次把距离最近的两个对象并成一簇，用组间平均距离继续合并*，最终形成一棵样本聚类树。它和 PCoA 是「一体两面」——都基于距离矩阵，一个用坐标展示，一个用树形展示。QIIME 2 不直接提供样本 UPGMA，用 R 实现：

```r
library(vegan)
library(ape)

dat <- read.delim("feature-table.tsv", row.names = 1, skip = 1, check.names = FALSE)
d <- vegdist(dat, method = "bray")            # 样本间 Bray-Curtis 距离

hc <- hclust(d, method = "average")           # average linkage = UPGMA
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
  --i-table table-l6.qza \
  --o-composition-table comp-l6.qza

qiime composition ancom \
  --i-table comp-l6.qza \
  --m-metadata-file metadata.tsv \
  --m-metadata-column Group \
  --o-visualization ancom-l6.qzv

# ANCOM-BC：直接建模，给出 log fold change 与校正后 P 值
qiime composition ancombc \
  --i-table table-l6.qza \
  --m-metadata-file metadata.tsv \
  --p-formula "Group" \
  --o-visualization ancombc-l6.qzv
```

*一个真实结果长什么样*：以刘永鑫教程的测试数据为例，ANCOM 在属水平只检出 *1 个*差异显著类群（*Pleomorphomonas* 属的一个 ASV）——说明「差异类群往往很少，别期待一张满屏红点」，这本身就是正常且可发表的结论。

ANCOM 的原理建立在「类群之间两两 log 比值」的 Aitchison 思想上：它不假设绝对丰度，只看类群之间的相对关系，所以特别适合 16S 这种组成型数据；`add-pseudocount` 是给零值加一个极小伪计数，避免 `log(0)`。

结果以火山图 / 条形图展示显著差异的分类单元，需结合 `taxonomy.qzv` 把特征 ID 翻译成物种名。*建议在属水平做差异分析*，结果更容易做生物学解释。

=== 12.2 LEfSe 与 Metastats

- *LEfSe*：线性判别分析 + 效应量，专门找「标志物种（biomarker）」。它不在 QIIME 2 内，用独立命令行或 Galaxy/Huttenhower 网页版。核心参数：logarithmic LDA score 阈值 4.0；分组数 ≥2 且每组样本 ≥2。
- *Metastats*：逐特征做组间检验（t 检验/Wilcoxon），P 值校正得 Q 值。可在 R 中自行实现，或用公司流程。

```bash
# LEfSe 命令行（需先安装 lefse 环境）
lefse_format_input.py otu_table.txt otu.in -c Group
run_lefse.py otu.in otu.res -l 4.0
plot_res.py otu.res lefse.png
```

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

```r
library(vegan)

dat <- read.delim("feature-table.tsv", row.names = 1, skip = 1, check.names = FALSE)
mat <- t(dat)
env <- read.delim("env.tsv", row.names = 1)     # 行=样本，列=环境因子

dca <- decorana(mat)
dca                                              # 看 DCA1 的 Axis lengths

# 线性模型选 RDA（可先对丰度做 Hellinger 变换）
rda_mod <- rda(decostand(t(mat), "hellinger") ~ ., data = env)
anova(rda_mod, permutations = 999)               # 整体显著性
anova(rda_mod, by = "term", permutations = 999)  # 各因子显著性

# 单峰模型选 CCA
cca_mod <- cca(mat ~ ., data = env)
anova(cca_mod, permutations = 999)
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

dat <- read.delim("feature-table.tsv", row.names = 1, skip = 1, check.names = FALSE)
d <- vegdist(dat, method = "bray")

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

== 15. 从结果到论文：出图、统计与常见坑

做到这里，你已经有了一套可复现的结果。要让它们变成「能发表的图」，还要过几道关。

=== 15.1 出图与配色

- *矢量优先*：论文图用 SVG/PDF，别用截图；QIIME 2 的 qzv 可导出 SVG，R 用 `ggsave(..., device = "svg")`。
- *克制配色*：分组颜色选一套对色盲友好、区分度高的调色板；避免彩虹色堆叠柱状图。
- *对齐与信息密度*：坐标轴统一字体字号，图例、标签对齐；一张图只讲一件事，把 P 值、R²、Stress 等关键统计量直接标在图上或图注里。
- *R 端重绘*：堆叠柱状图、PCoA、Alpha 箱线图，导出 CSV 后用 ggplot2 重绘，能完全掌控样式。

=== 15.2 统计报告的底线

- 组间差异*必须做多重检验校正*，报告 P 值、Q 值、效应量。
- Alpha 用 Kruskal–Wallis（多组）或 Wilcoxon（两组）；Beta 用 PERMANOVA（报 R²、P），并用 PERMDISP 检查离散度。
- 小样本研究的结论要克制，写成「提示……，仍需进一步验证」，不要绝对化。

=== 15.3 常见坑清单

#tablem[
  | 坑 | 后果 | 对策 |
  | :--- | :--- | :--- |
  | 抽平深度设太低或样本删太多 | 多样性失真、样本损失 | 看 `table.qzv`，兼顾深度与样本数 |
  | 稀释曲线未达平台就比较 Alpha | 差异可能只是测序量差异 | 先看 `alpha-rarefaction.qzv` |
  | 数据库与扩增区不匹配 | 注释准确率低 | 用相同引物训练特异分类器 |
  | 未做多重检验校正 | 假阳性结论 | FDR/BH 校正，报告 Q 值 |
  | PCA 与 PCoA 混为一谈 | 方法学被审稿人质疑 | 记牢：PCA 用丰度矩阵，PCoA 用距离矩阵 |
  | 去噪后保留率 < 20% | 参数设错、结论不可信 | 回 `demux.qzv` 重设截断 / 去引物 |
  | 宿主线粒体 / 叶绿体污染 | 假多样性、属名异常 | `taxa filter-table` 去 mitochondria/chloroplast |
  | 分类器扩增区不匹配 | 大量 Unassigned / 误注释 | 用相同引物 `extract-reads` 训练特异分类器 |
  | 中文 / 空格路径 | 部分工具报错 | 全程用英文无空格路径 |
]

=== 15.4 延伸：功能预测与网络分析

拿到物种组成后，常被追问「这些菌在干什么」。三类延伸：

- *PICRUSt2 功能预测*：基于 16S 的进化关系把 ASV 映射到 KEGG 通路。QIIME 2 里用 `q2-picrust2`，关键参数 `--p-max-nsti 2`（NSTI > 2 的 ASV 预测不可靠，会被剔除）；建议用 Greengenes 注释，便于与 PICRUSt 参考树对齐。
- *BugBase 表型预测*：输出革兰氏阴阳性、好氧 / 厌氧、生物膜形成、致病性等表型比例。
- *FUNGuild 真菌功能*：把 ITS 物种映射到 *病理营养型（pathotroph）、共生营养型（symbiotroph）、腐生营养型（saprotroph）* 三大营养型及其细分 guild。

*共发生网络分析*：用 Spearman 相关（常见阈值 |r|＞0.6、P＜0.05）构建「菌–菌」关联网络，再用 Gephi / Cytoscape 计算拓扑指标找核心 Hub 菌群：

#tablem[
  | 指标 | 含义 |
  | :--- | :--- |
  | 度 degree | 一个节点连了多少条边，越高越中心 |
  | 聚类系数 clustering coefficient | 邻居之间也相连的程度 |
  | 接近中心性 closeness | 到其他节点的平均距离，越小越中心 |
  | 介数中心性 betweenness | 位于多少条最短路径上，越高越关键 |
  | 模块度 modularity | 网络分模块的清晰程度 |
  | 直径 diameter / 平均路径长度 | 网络大小与紧密程度 |
  | 密度 density | 实际边数 / 可能边数 |
]

这些属于「从物种描述走向机制解释」的加分项，但要牢记*相关性 ≠ 因果*：网络 Hub 只是假设，仍需实验验证。

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
# 导出特征表为 BIOM，并转 TSV
qiime tools export --input-path table-filtered.qza --output-path export/table
biom convert -i export/table/feature-table.biom \
  -o export/table/feature-table.tsv --to-tsv

# 导出代表序列与物种注释
qiime tools export --input-path rep-seqs.qza --output-path export/rep-seqs
qiime tools export --input-path taxonomy.qza --output-path export/taxonomy

# 导出距离矩阵（供 R 做 PERMANOVA / 聚类）
qiime tools export \
  --input-path core-metrics-results/bray_curtis_distance_matrix.qza \
  --output-path export/dist
```

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
- QIIME 2 中文手册（Yongxin Liu）：#link("https://github.com/YongxinLiu/QIIME2ChineseManual")[github.com/YongxinLiu/QIIME2ChineseManual]
- 讲义 `diversity_analysis.md`（QIIME 2 概览与 2020.11 / 2021.2 完整流程命令）。

=== 一点说明

上述链接中，部分站点为镜像、需登录或已迁移，个别页面在抓取时返回的是与标题不符的内容或纯前端渲染的空白。本文只采纳其中*可复现、与 QIIME 2 官方行为一致*的命令与数值；凡涉及具体参数处，均以「示例、需按自己数据调整」提示为准。真正跑流程时，请以 `qiime <插件> <命令> --help` 与官方 2024.2 文档为最终依据。
