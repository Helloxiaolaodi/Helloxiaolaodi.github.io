#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *
#import "@preview/theorion:0.6.0": quote-block

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "科研利器之生信工具的原理合集",
  description: "把 16S、宏基因组、MAG、功能注释、统计关联等常用生信工具放在同一张地图里，讲清原理与适用场景。",
  date: datetime(year: 2026, month: 7, day: 18),
  lang: "zh",
)

= 科研利器之生信工具的原理合集

这份笔记把微生物领域最常用、也相对新的生信分析工具放到同一张地图里，重点覆盖 16S 扩增子、shotgun 宏基因组、MAG 构建、功能注释、统计关联、来源追踪、长读长、病毒分析，以及化学信息学与关联数据库等任务。写法上保留 Markdown 标题、代码块、表格这类适合长期维护的排版，并把相近工具合并成模块，避免同类工具重复解释。

阅读方式是：先看每个模块的代表性工具，理解底层原理和适用场景；再看模块末尾的汇总表，快速建立"遇到什么问题该拿什么工具"的判断。文末还附了一个"Zhang et al. 2026 文献工具对照表"，把原始 `.txt` 内容并入同一份文档。

关于版本说明：文中出现的 MetaPhlAn3/4、HUMAnN3、CheckM2、SemiBin2、dbCAN3、geNomad、MaAsLin3 等均为当前社区主流版本，部分工具仍在迭代，使用前请到对应 GitHub 主页确认最新 release 与数据库版本。

#line()

== 一、数据获取、质控与宿主去除

这一层决定后面所有分析是否可靠。宏基因组数据如果在最开始没有把接头、低质量碱基、重复 reads 和宿主污染清干净，后面的物种分类、功能注释和组装都会被系统性放大偏差。这个模块里最常见的是下载工具、质控工具和宿主去除工具。

=== 1. SRA-Toolkit

- *为什么常用：* 公共数据库里的原始测序数据很多都在 NCBI SRA 中，做复现、重分析、方法比较时几乎绕不开它。
- *底层原理解读：* `SRA-Toolkit` 是 NCBI 官方提供的数据访问与格式转换工具集。它的核心不是"分析算法"，而是把 SRA 这个专用压缩容器格式稳定地还原为标准 FASTQ。`prefetch` 负责按 accession 拉取原始对象并支持断点续传，`fasterq-dump` 负责边读取边解包边重建读段和质量值，`sam-dump`/`vdb-dump` 则面向已比对或更底层的访问需求。它之所以比手工网页下载可靠，是因为工具内部知道 SRA 对象的元数据结构、双端配对关系和校验逻辑，因此更适合批量任务、断点续传和脚本化重现。在微生物组分析里，它的意义是把"公共数据可获取"这件事变成标准化步骤，从而支撑大队列复现、meta-analysis 和同一流程下的再处理。
- *简单流程图：*

```text
SRA accession -> prefetch 下载 .sra -> fasterq-dump 解包 -> FASTQ -> 进入质控流程
```

- *用途：* 批量下载公开测序数据，生成下游分析可直接使用的 FASTQ。
- *官方地址：* #link("https://github.com/ncbi/sra-tools")[GitHub] | #link("https://github.com/ncbi/sra-tools/wiki")[Wiki / 教程] | #link("https://www.ncbi.nlm.nih.gov/sra")[NCBI SRA]
- *Linux 常用命令：*

```bash
# 下载原始数据（支持断点续传，建议先 prefetch 再 fasterq-dump）
prefetch SRR12345678

# 转换为双端 FASTQ，-e 指定线程
fasterq-dump SRR12345678 --split-files -e 8 -O ./fastq

# 批量下载 accession 列表
prefetch --option-file srr_list.txt -O ./sra_cache

# 压缩输出节省空间
gzip ./fastq/SRR12345678_1.fastq ./fastq/SRR12345678_2.fastq
```

=== 2. fastp / FastQC / MultiQC

- *为什么常用：* 上手成本低、速度快、输出报告直观，单机处理常规微生物双端测序数据通常足够；FastQC 做单样本质量画像，MultiQC 汇总整批报告。
- *底层原理解读：* `fastp` 的核心思路是"单次扫描尽量完成最多清洗任务"。它用 C++ 实现了高性能的 per-read 处理流程，常见动作包括接头识别、滑窗质量剪切、N 碱基过滤、低复杂度过滤、UMI 处理和部分重复去除。它不是把 reads 先拆给多个工具再汇总，而是在读取每条序列时同步更新统计信息，因此 I/O 成本较低，适合大批量微生物样本。滑窗算法本质上是在 read 上移动一个窗口，检测局部平均质量是否跌破阈值，再决定从哪里截断；这样做比固定长度硬裁剪更稳，因为它能保留高质量尾部。`FastQC` 则逐样本统计 per-base quality、GC 含量、接头污染、重复水平等，给出 base-level 图表；`MultiQC` 不重算，而是把 fastp/FastQC/bowtie2 等几十种工具的日志聚合成一份跨样本报告。对微生物组数据来说，这一组工具的意义是先把明显脏数据挡在门外，减少假阳性 k-mer、错误拼接和错误物种命中。
- *简单流程图：*

```text
FASTQ -> fastp 接头识别/滑窗剪切/过滤 -> clean FASTQ + JSON/HTML 报告
原始/质控后 FASTQ -> FastQC 单样本画像 -> MultiQC 汇总全队列报告
```

- *用途：* 去接头、去低质量区域、过滤过短 reads，并输出质量报告；多工具日志汇总。
- *官方地址：* #link("https://github.com/OpenGene/fastp")[fastp] | #link("https://www.bioinformatics.babraham.ac.uk/projects/fastqc/")[FastQC] | #link("https://multiqc.info")[MultiQC]
- *Linux 常用命令：*

```bash
# fastp 一步质控
fastp \
  -i sample_R1.fastq.gz -I sample_R2.fastq.gz \
  -o clean_R1.fastq.gz -O clean_R2.fastq.gz \
  -q 20 -u 30 -n 5 -l 50 \
  --detect_adapter_for_pe --correction \
  -w 16 -h fastp.html -j fastp.json

# FastQC 单样本质量画像
fastqc -t 8 -o fastqc_out clean_R1.fastq.gz clean_R2.fastq.gz

# MultiQC 汇总整批报告
multiqc fastp_out fastqc_out -o multiqc_report --interactive
```

=== 3. Sunbeam

- *为什么常用：* Zhang et al. 2026 用 Sunbeam 处理了 3000 多个全球队列样本的质控，是宏基因组标准化的可复现流程之一。
- *底层原理解读：* `Sunbeam` 不是新算法，而是一套基于 Snakemake 的自动化管线。它的价值在于把"质控-去宿主-后续分析"接成一条可追溯工作流：内部整合 Trimmomatic（或 fastp）做接头和质量剪切，用 BWA 比对宿主参考基因组去除宿主污染，并通过 Snakemake 的 DAG 机制保证每一步只在输入变化时重算。对大队列项目来说，这种"流程即代码"的方式比手工脚本更稳，也更容易让多人协作和论文复现。
- *简单流程图：*

```text
FASTQ -> Snakemake DAG -> Trimmomatic 质控 -> BWA 去宿主 -> 输出 clean reads 供下游
```

- *用途：* 宏基因组大队列质控与去宿主的标准化流程。
- *官方地址：* #link("https://github.com/sunbeam-labs/sunbeam")[GitHub] | #link("https://sunbeam.readthedocs.io")[文档]
- *Linux 常用命令：*

```bash
# 安装并初始化配置
sunbeam init --project myproject

# 运行整个质控流程
sunbeam run --config myproject/config.yml all_qc
```

=== 4. KneadData / Bowtie2 / BWA

- *为什么常用：* 宏基因组样本里最常见的非目标污染就是宿主 DNA，尤其是粪便、口腔、皮肤、组织或宿主感染模型样本。
- *底层原理解读：* 这组工具通常要放在一起理解。`Bowtie2` 和 `BWA` 都是短序列比对器，本质都依赖压缩索引加快速种子匹配。`BWA-MEM` 采用 seed-and-extend 思路：先用 Burrows-Wheeler Transform 构建参考基因组的 FM-index，把 read 切成种子在 index 上快速定位，再做带间隙的局部延伸，适合 70bp 以上 reads 的大参考比对。`Bowtie2` 更偏通用短读长比对，擅长局部比对和带插入缺失的比对，对质量值利用更细。对宿主去除任务来说，核心不是把每条 read 完美比到人基因组，而是尽可能识别"明显属于宿主"的序列并剔除，以减少后续分类器把宿主片段错当成微生物信号。`KneadData` 则像一个流程编排器，把 Trimmomatic/fastp/Bowtie2 打包成"先清洗再去宿主"的一条线，适合批量样本和多人协作。
- *简单流程图：*

```text
clean FASTQ -> 建宿主索引 -> read 与 host genome 比对 -> 命中宿主的 reads 去除 -> 保留非宿主 reads
```

- *用途：* 宏基因组宿主污染去除，常见宿主包括人、小鼠、猪、植物等。
- *官方地址：* #link("https://github.com/biobakery/kneaddata")[KneadData] | #link("https://bowtie-bio.sourceforge.net/bowtie2/index.shtml")[Bowtie2] | #link("https://github.com/lh3/bwa")[BWA]
- *Linux 常用命令：*

```bash
# Bowtie2 建索引
bowtie2-build GRCh38.fa human_db

# KneadData 去宿主（可指定多个宿主库）
kneaddata \
  -i clean_R1.fastq.gz -i clean_R2.fastq.gz \
  -db /path/to/human_db --remove-intermediate \
  -o kneaddata_out --threads 16

# 直接用 BWA-MEM 去宿主，再用 samtools 过滤未比对
bwa index GRCh38.fa
bwa mem -t 16 GRCh38.fa clean_R1.fastq.gz clean_R2.fastq.gz | \
  samtools view -bS -f 12 -F 256 - > nonhost.bam
```

=== 5. 模块汇总表

#tablem[
  | 工具 | 典型任务 | 核心原理 | 什么时候优先用 |
  | :--- | :--- | :--- | :--- |
  | SRA-Toolkit | 公共数据下载 | 解析 SRA 容器并转 FASTQ | 复现公开研究、批量拉取 SRA 数据 |
  | fastp | 质控与剪切 | 单次扫描 + 滑窗质量控制 | 常规双端 reads 快速预处理 |
  | FastQC | 原始质量评估 | base-level 统计和图形化 | 先看数据长什么样 |
  | MultiQC | 报告汇总 | 汇聚多个样本日志 | 多样本项目质控汇总 |
  | Sunbeam | 标准化流程 | Snakemake DAG 整合质控去宿主 | 大队列、可复现流程 |
  | KneadData | 去宿主流程 | 封装 trimming + host removal | 想要标准化、批量化处理 |
  | Bowtie2 | 去宿主/比对 | FM-index + seed-and-extend | 通用、稳健的短读长比对 |
  | BWA-MEM | 去宿主/比对 | BWT/FM-index 局部延伸 | 常见参考基因组比对 |
]

#line()

== 二、16S 扩增子分析

16S 流程的核心不是"把所有 reads 拼回完整基因组"，而是用扩增子的差异来估计群落组成。这个任务里最关键的选择是：你是要做传统 OTU 聚类，还是更细的 ASV 去噪。近几年主流已经明显偏向 ASV。

=== 1. QIIME 2

- *为什么常用：* 它更像一个生态系统而不是单一算法，适合教学、规范化流程和插件式扩展。
- *底层原理解读：* `QIIME 2` 自己并不承担所有分析，而是通过 artifact 类型系统把数据、元数据、可追溯参数和插件计算绑定起来。它的真正价值在于"数据对象化"和"流程可追踪"。例如导入后的 `.qza` 既保存表格，也保存类型和来源，`.qzv` 则保存可视化结果和分析上下文。这样做的好处是减少文件格式乱飞、样本名错位和参数不可复现等问题。算法层面，QIIME 2 可以调用 DADA2、Deblur、VSEARCH、feature-classifier、diversity 等插件，因此适合从原始扩增子 reads 一路走到特征表、分类注释和 alpha/beta 多样性分析。物种注释通常用基于朴素贝叶斯的 `classify-sklearn`，配合 SILVA 或 GTDB 数据库。它在微生物组研究中的真正用途，是作为一个"把常见分析模块接成稳定可追溯工作流"的平台。
- *简单流程图：*

```text
FASTQ -> 导入为 QIIME2 artifact -> 去噪/聚类 -> feature table -> 物种注释 -> 多样性/差异分析 -> 可视化
```

- *用途：* 16S/ITS 扩增子数据的标准化分析、可视化和结果追踪。
- *官方地址：* #link("https://qiime2.org")[官网] | #link("https://docs.qiime2.org")[文档] | #link("https://amplicon-docs.qiime2.org")[教程]
- *Linux 常用命令：*

```bash
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path manifest.csv \
  --output-path demux.qza \
  --input-format PairedEndFastqManifestPhred33V2

qiime demux summarize --i-data demux.qza --o-visualization demux.qzv

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux.qza \
  --p-trunc-len-f 240 --p-trunc-len-r 200 \
  --p-n-threads 16 \
  --o-table table.qza \
  --o-representative-sequences rep-seqs.qza \
  --o-denoising-stats stats.qza

qiime feature-classifier classify-sklearn \
  --i-classifier silva-138-ssu-nr99-classifier.qza \
  --i-reads rep-seqs.qza --o-classification taxonomy.qza
```

=== 2. DADA2

- *为什么常用：* 它把传统 OTU 聚类中"97% 相似度就算一个类群"的粗粒度方式，升级成了单碱基层面的 ASV 推断。
- *底层原理解读：* `DADA2` 的核心思想不是聚类，而是显式建模测序错误。它先从样本中学习平台特异的错误模型（通过自一致迭代估计错误率），再判断某个低频变体究竟是真实生物变异，还是高丰度序列产生的错误拷贝。这个过程包括质量过滤、去重、误差学习、去噪、双端合并和去嵌合体。算法上它利用概率模型估计"当前序列在给定错误率下由另一个真实序列生成的可能性"，从而把噪音压下去。与 OTU 相比，ASV 的好处是跨项目可比较、分辨率更高、也更适合下游生态统计。对于微生物群落研究，这意味着研究者能更稳定地追踪真实变异，而不是受到聚类阈值的人为影响。DADA2 对 Illumina 平台错误率建模尤其成熟，是当前 ASV 的事实标准之一。
- *简单流程图：*

```text
demux FASTQ -> 质量过滤 -> 学习错误模型 -> 去噪生成 ASV -> 合并双端 -> 去嵌合体 -> feature table
```

- *用途：* 高分辨率 ASV 推断，特别适合 16S/ITS 扩增子数据。
- *官方地址：* #link("https://benjjneb.github.io/dada2/")[官网教程] | #link("https://github.com/benjjneb/dada2")[GitHub]
- *Linux 常用命令：*

```r
library(dada2)
fnFs <- sort(list.files("fastq", pattern="_R1.fastq.gz", full.names=TRUE))
fnRs <- sort(list.files("fastq", pattern="_R2.fastq.gz", full.names=TRUE))
filtFs <- file.path("filtered", basename(fnFs))
filtRs <- file.path("filtered", basename(fnRs))
filterAndTrim(fnFs, filtFs, fnRs, filtRs, truncLen=c(240,200), maxN=0,
              maxEE=c(2,2), truncQ=2, rm.phix=TRUE, multithread=TRUE)
errF <- learnErrors(filtFs, multithread=TRUE)
errR <- learnErrors(filtRs, multithread=TRUE)
dadaFs <- dada(filtFs, err=errF, multithread=TRUE)
dadaRs <- dada(filtRs, err=errR, multithread=TRUE)
mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs)
seqtab <- makeSequenceTable(mergers)
seqtab.nochim <- removeBimeraDenovo(seqtab, method="consensus", multithread=TRUE)
```

=== 3. VSEARCH / mothur / Deblur

- *为什么常用：* 这类工具代表了 16S 分析里另外三条常见路线，分别对应开放源码的聚类搜索、教学友好的经典流程和更轻量的去噪方法。
- *底层原理解读：* `VSEARCH` 可以看作 USEARCH 的开源替代，核心能力是全局比对、去冗余、去嵌合体和 OTU 聚类，因此在需要与旧研究兼容时仍很重要。`mothur` 的价值在于完整的 SOP 和长期稳定的生态学分析流程，很多教学或传统实验室仍在使用。`Deblur` 的思路与 DADA2 不同，它不是从每个数据集重学错误模型，而是使用预先定义的错误剖面和固定长度裁剪来快速恢复真实序列，因此跨批次更统一、速度也快一些，但对数据裁剪和质量一致性要求更强。对用户来说，这组工具回答的是一个现实问题：如果项目强调与旧文献兼容、想做 OTU，选 VSEARCH/mothur；如果强调 ASV 且想用更轻量流程，可以考虑 Deblur。
- *简单流程图：*

```text
扩增子 FASTQ -> 去冗余/去噪 -> OTU 或 ASV -> 去嵌合体 -> 物种注释 -> 群落分析
```

- *用途：* OTU 聚类、去嵌合体、传统扩增子 SOP 或轻量去噪。
- *官方地址：* #link("https://github.com/torognes/vsearch")[VSEARCH] | #link("https://mothur.org")[mothur] | #link("https://github.com/biocore/deblur")[Deblur]
- *Linux 常用命令：*

```bash
# VSEARCH 去嵌合体
vsearch --uchime_denovo rep_seqs.fasta --nonchimeras rep_seqs.nochim.fasta

# VSEARCH OTU 聚类（97%）
vsearch --cluster_size rep_seqs.nochim.fasta --id 0.97 \
  --centroids otu97.fasta --uc otu97.uc --threads 16

# Deblur 去噪（需先解多重序列并按 trim 长度对齐）
deblur workflow --input seqs.fa --output deblur_out --min-reads 10 -t 150
```

=== 4. 模块汇总表

#tablem[
  | 工具 | 典型任务 | 核心原理 | 什么时候优先用 |
  | :--- | :--- | :--- | :--- |
  | QIIME 2 | 全流程平台 | artifact 类型系统 + 插件 | 想要规范化、可追踪 16S 流程 |
  | DADA2 | ASV 推断 | 显式错误模型 | 追求高分辨率、主流 ASV 方案 |
  | Deblur | 轻量去噪 | 固定误差轮廓 | 批量标准化、较快 |
  | VSEARCH | OTU/搜索 | 聚类 + 比对 + 去嵌合体 | 兼容旧式 OTU 研究 |
  | mothur | 传统 SOP | 完整经典流程 | 教学、旧项目延续 |
  | SILVA | 16S 参考库 | 分类学数据库 | 16S 分类注释常用库 |
  | GTDB | 新型分类框架 | 基因组系统发育 | 更贴近现代细菌古菌分类 |
  | Greengenes2 | 新版参考库 | 物理一致性 ASV 框架 | 与 GTDB 对齐的新参考库 |
]

#line()

== 三、shotgun 宏基因组的物种、菌株与功能画像

shotgun 与 16S 最大的区别，是它不只看一小段标记基因，而是直接采整段随机基因组片段。这会给你更细的物种分辨率、功能信息和组装潜力，但同时带来更高的数据库依赖和计算负担。

=== 1. Kraken2 + Bracken

- *为什么常用：* 这是现在最常见的一组"先快分，再校正丰度"的组合，在微生物组项目里出镜率非常高。
- *底层原理解读：* `Kraken2` 的核心是 k-mer 精确匹配。它把参考数据库里所有序列切成 k-mer，并给每个 k-mer 绑定它在分类树上能确定的最深分类单元——也就是最低公共祖先 LCA；当一条 read 进来时，工具检查其中大量 k-mer 分别支持哪些分类单元，再把这些证据在分类树上投票，最后选择覆盖 read 上最多 k-mer 的那个分类节点作为结果。这个方法非常快，因为它避开了全长比对，但缺点是 read-level 分类容易受数据库规模、共享 k-mer 和基因组长度影响，且对未知序列容易上推到更高层级。`Bracken` 的存在就是为了解决这个问题：它在 Kraken2 分类结果之上，根据不同物种的 read 长度分布和 k-mer 共享情况重新估计丰度，用贝叶斯重分配把"被上推到 genus 的 reads"尽量分回 species 层。对于复杂肠道或环境样本，这种组合通常能在速度和准确度之间取得很好的平衡。
- *简单流程图：*

```text
reads -> Kraken2 k-mer + LCA 投票 -> 各层级 read 计数 -> Bracken 贝叶斯重估 species/genus 丰度 -> 丰度表
```

- *用途：* 快速物种分类和物种丰度估计，适合大批量样本。
- *官方地址：* #link("https://github.com/DerrickWood/kraken2")[Kraken2] | #link("https://ccb.jhu.edu/software/bracken/")[Bracken] | #link("https://github.com/DerrickWood/kraken2/wiki/Manual")[Kraken2 数据库教程]
- *Linux 常用命令：*

```bash
kraken2 \
  --db /data/kraken2_db \
  --paired clean_R1.fastq.gz clean_R2.fastq.gz \
  --threads 24 \
  --report sample.kreport \
  --output sample.kraken \
  --confidence 0.1

bracken -d /data/kraken2_db -i sample.kreport -o sample.bracken -r 150 -l S

# 多样本合并为一张物种丰度表
combine_bracken_outputs.py -i *.bracken -o combined_bracken.tsv
```

=== 2. MetaPhlAn4 / StrainPhlAn / PanPhlAn / ChocoPhlAn

- *为什么常用：* 这套方法更偏"少而准"的标记基因路线，常用于肠道、口腔和皮肤等人体微生物组研究。
- *底层原理解读：* `MetaPhlAn` 不像 Kraken2 那样遍历所有 k-mer，也不试图利用所有 reads，而是只关注每个物种特异的 clade-specific marker genes，约占基因组的 4%。这样做的好处是宿主背景和保守区域干扰更小，物种丰度估计更稳，尤其适合人体共生微生物数据库较完整的场景；它先用 Bowtie2 把 reads 投到 marker 库，再统计各 marker 的覆盖情况估计相对丰度。`StrainPhlAn` 在此基础上进一步抽取样本中的 marker 序列变异位点，构建同一物种在不同样本间的系统发育树，用于菌株分辨；`PanPhlAn` 则把 reads 投到物种的泛基因组上，判断哪些基因簇存在或缺失，从而做基因内容层面的菌株比较。`ChocoPhlAn` 是 HUMAnN3 使用的参考泛基因组集合，可以理解成"每个物种的代表性泛基因组库"，HUMAnN3 用它来做分层数据库搜索的第一层。三者放一起看，分别回答了"是谁""是不是同一菌株""这个菌株带了哪些功能基因"三个层次的问题。
- *简单流程图：*

```text
reads -> marker gene 命中 -> 物种丰度 (MetaPhlAn)
reads -> marker 变异位点 -> 菌株树 (StrainPhlAn)
reads -> pangenome 基因簇存在/缺失 -> 菌株功能差异 (PanPhlAn)
ChocoPhlAn = HUMAnN3 第一层搜索用的泛基因组库
```

- *用途：* 物种 profiling、菌株分辨和泛基因组存在缺失分析；ChocoPhlAn 作为 HUMAnN3 的参考泛基因组。
- *官方地址：* #link("https://github.com/biobakery/MetaPhlAn")[MetaPhlAn] | #link("https://github.com/biobakery/MetaPhlAn/wiki/StrainPhlAn-4")[StrainPhlAn 文档] | #link("https://github.com/SegataLab/panphlan")[PanPhlAn] | #link("https://huttenhower.sph.harvard.edu/tools/")[bioBakery]
- *Linux 常用命令：*

```bash
metaphlan clean_R1.fastq.gz,clean_R2.fastq.gz \
  --input_type fastq \
  --bowtie2out sample.bowtie2.bz2 \
  -o sample_profile.txt \
  --nproc 24

# 菌株水平系统发育
strainphlan -s sample_profile.txt -o strainphlan_out
```

=== 3. HUMAnN3

- *为什么常用：* 它是宏基因组功能分析里最成熟的标准工具之一，尤其适合把"功能丰度"和"来源物种"联系起来。
- *底层原理解读：* `HUMAnN3` 的核心是分层搜索。第一层，它优先把 reads 投到已知微生物的泛基因组数据库 `ChocoPhlAn`，因为如果样本里有比较熟悉的物种，这样做速度快、分辨率高。第二层，没命中的 reads 再去更大的蛋白数据库 `UniRef90` 做 translated search（用 DIAMOND 加速），以捕获未知或较远缘基因。最后它把基因家族、通路和酶学功能汇总成丰度表，并可输出 species-stratified 结果，也就是"某个功能主要由哪些物种贡献"。这点非常重要，因为很多微生物组问题不是简单地问某个 EC 或 pathway 高不高，而是问"它到底是谁在做"。HUMAnN 的真正价值就在这里：把功能信号从群落平均值推进到物种分层解释。它还会用 MinPath 等方法做通路重建，并用 CPM/TPM 归一化输出。
- *简单流程图：*

```text
reads -> MetaPhlAn 物种预估 -> 先搜 ChocoPhlAn 核酸层 -> 未命中再用 DIAMOND 搜 UniRef90 -> gene family -> pathway/EC -> species-stratified 功能表
```

- *用途：* 宏基因组和宏转录组功能注释、通路定量、EC 丰度分析。
- *官方地址：* #link("https://github.com/biobakery/humann")[GitHub] | #link("https://huttenhower.sph.harvard.edu/humann")[biobakery 文档]
- *Linux 常用命令：*

```bash
humann \
  --input clean_R1.fastq.gz \
  --output humann_out \
  --threads 24 \
  --metaphlan-options "--bowtie2db /data/mpa_db"

# 归一化为 CPM 并分层
humann_renorm_table --input humann_out/sample_genefamilies.tsv \
  --output sample_genefamilies_cpm.tsv --units cpm

# 按通路和 EC 重组
humann_regroup_table --input sample_genefamilies_cpm.tsv \
  --groups uniref90_ec --output sample_ec.tsv
```

=== 4. 模块汇总表

#tablem[
  | 工具 | 典型任务 | 核心原理 | 什么时候优先用 |
  | :--- | :--- | :--- | :--- |
  | Kraken2 | 物种分类 | k-mer + LCA 投票 | 大队列、速度优先 |
  | Bracken | 丰度重估 | 贝叶斯 read 重分配 | Kraken2 之后校正 species 丰度 |
  | MetaPhlAn4 | 物种 profiling | marker gene | 人体微生物组、稳健丰度 |
  | StrainPhlAn | 菌株追踪 | marker SNP 系统发育 | 看同一物种的菌株差异 |
  | PanPhlAn | 泛基因组分析 | 基因簇存在缺失 | 看菌株带了哪些基因 |
  | ChocoPhlAn | 参考泛基因组库 | 物种泛基因组集合 | HUMAnN3 第一层搜索底库 |
  | HUMAnN3 | 功能 profiling | 分层数据库搜索 | 关心 EC/pathway 和来源物种 |
  | Kaiju | 蛋白级分类 | translated search | 环境样本、远缘物种较多 |
  | mOTUs | marker 物种 profiling | 通用 marker genes | 对未培养类群较友好 |
  | DIAMOND | 蛋白比对加速 | 双索引种子延伸 | HUMAnN3/eggNOG 内部依赖 |
]

#line()

== 四、组装、分箱与 MAG 构建

如果你的目标不是只看"丰度表"，而是希望把未知微生物尽量还原成基因组草图，就要进入 MAG 路线。这个模块的技术重点，是把碎 read 先拼成长 contig，再把属于同一基因组的 contig 尽量装进同一个 bin 里。

=== 1. MEGAHIT / metaSPAdes

- *为什么常用：* 二者都是宏基因组组装中的主力，前者强调速度和内存效率，后者通常在复杂样本中组装质量更细致。
- *底层原理解读：* 宏基因组组装本质上是在混合样本中重建多条未知基因组。`MEGAHIT` 和 `metaSPAdes` 都以 de Bruijn graph 为核心：把 reads 切成 k-mer，k-mer 之间按前后缀关系连边，再在图中寻找可以重建的路径。难点在于不同物种共享片段、重复序列、丰度差异巨大和测序错误都会把图弄得很复杂。MEGAHIT 通过 succinct de Bruijn graph 这类压缩数据结构（基于 SDSL）提升大数据集效率，并采用多 k-mer 从小到大迭代组装策略；metaSPAdes 则在多 k-mer 策略、图清理、基于覆盖度的 Bulge/Tip 处理和局部重建方面做得更充分，并通过 exSPAnder 处理重复与变异，因此在高复杂环境样本中常能得到更好的 contig 连续性。对微生物研究者来说，组装器的选择直接影响后续 binning、基因预测和新物种发现。
- *简单流程图：*

```text
clean reads -> 切成 k-mer -> 构建 de Bruijn graph -> 多 k-mer 迭代/图清理 -> 输出 contigs
```

- *用途：* 宏基因组 reads 组装成 contig，作为后续分箱和注释输入。
- *官方地址：* #link("https://github.com/voutcn/megahit")[MEGAHIT] | #link("https://github.com/ablab/spades")[SPAdes/metaSPAdes]
- *Linux 常用命令：*

```bash
# MEGAHIT：快、省内存，大队列首选
megahit -1 clean_R1.fastq.gz -2 clean_R2.fastq.gz -o megahit_out -t 32

# metaSPAdes：质量更细，但更吃内存
metaspades.py -1 clean_R1.fastq.gz -2 clean_R2.fastq.gz -o metaspades_out -t 32 -m 250

# 评估组装质量
quast.py megahit_out/final.contigs.fa -o quast_out
```

=== 2. metaWRAP / MetaBAT2 / MaxBin2 / CONCOCT / SemiBin2

- *为什么常用：* 这是 MAG 构建中最常见的组合拳。一个工具很难在所有样本里都分得最好，所以实践里通常是多分箱器并用，再做提纯整合。
- *底层原理解读：* `MetaBAT2` 主要依据 tetranucleotide frequency 和 contig abundance 协方差，把序列成分相似、跨样本丰度变化一致的 contig 放在一起；`MaxBin2` 更依赖单拷贝标记基因和覆盖度；`CONCOCT` 利用 k-mer 频率与丰度做高斯混合聚类；`SemiBin2` 则是近几年很值得关注的新工具，它用半监督/自监督学习把 contig 表示成更适合聚类的向量，并可以利用 provided labels 或环境特异先验提升精度，因此在复杂环境和低丰度基因组上常优于传统方法。`metaWRAP` 的价值不在于发明新算法，而在于把这些组装、分箱、精炼步骤接成一条成熟流程，并通过 `bin_refinement` 取多个分箱器的交集做提纯。研究者真正需要的是高质量 MAG，而不是单个分箱器的理论优雅，所以 workflow 工具在生产环境里非常重要。
- *简单流程图：*

```text
contigs + abundance 信息 -> 多种分箱器独立分箱 -> bin refinement/融合 -> 高质量 MAG
```

- *用途：* contig 分箱、MAG 提纯、复杂样本中的未培养微生物重建。
- *官方地址：* #link("https://github.com/bxlab/metaWRAP")[metaWRAP] | #link("https://bitbucket.org/berkeleylab/metabat/src/master/")[MetaBAT2] | #link("https://sourceforge.net/projects/maxbin2/")[MaxBin2] | #link("https://github.com/BinPro/CONCOCT")[CONCOCT] | #link("https://github.com/BigDataBiology/SemiBin")[SemiBin]
- *Linux 常用命令：*

```bash
# metaWRAP 组装
metawrap assembly -1 clean_R1.fastq.gz -2 clean_R2.fastq.gz -o assembly_out -t 32 -m 250

# metaWRAP 多分箱器并行
metawrap binning -o binning_out -t 32 -a assembly_out/final_assembly.fasta \
  --metabat2 --maxbin2 --concoct clean_R1.fastq.gz clean_R2.fastq.gz

# metaWRAP 提纯
metawrap bin_refinement -o refined_bins -t 32 \
  -A binning_out/metabat2_bins \
  -B binning_out/maxbin2_bins \
  -C binning_out/concoct_bins -c 50 -x 10

# SemiBin2 单样本分箱
SemiBin2 single_easy_bin -i assembly_out/final_assembly.fasta -o semibin_out \
  -1 clean_R1.fastq.gz -2 clean_R2.fastq.gz -t 32
```

=== 3. CheckM2 / dRep / GTDB-Tk

- *为什么常用：* 分箱不是终点，后面还要回答三个问题：bin 质量怎么样、有没有冗余、它到底是什么类群。
- *底层原理解读：* `CheckM2` 是近几年比传统 CheckM 更受关注的新版本，它不再只依赖固定单拷贝 marker 集，而是利用机器学习（梯度提升树）综合多类基因组特征来预测完整度和污染度，因此对新类群和碎片化基因组更稳一些，且不依赖参考基因集。`dRep` 的核心是"先粗后细"的去冗余：先用 MASH 这类 sketch 方法做粗聚类，再用 ANI 做精细两两比较，最后从每个簇中选出质量最好的代表基因组。`GTDB-Tk` 则把 MAG 放到 GTDB 参考系统发育框架中，通过约 120 个单拷贝 marker 构建系统发育树，基于拓扑结构和相对进化发散度（RED）给出分类学标签，是目前宏基因组最权威的命名系统之一。三者串起来就是 MAG 质控链条：先评估质量，再去重，最后注释身份，这也是论文级 MAG 分析的基本动作。
- *简单流程图：*

```text
MAG bins -> CheckM2 评估完整度/污染 -> dRep 去冗余 -> GTDB-Tk 分类注释 -> 最终 MAG 集合
```

- *用途：* MAG 质量评估、菌株级去冗余、现代分类学注释。
- *官方地址：* #link("https://github.com/chklovski/CheckM2")[CheckM2] | #link("https://github.com/MrOlm/drep")[dRep] | #link("https://github.com/Ecogenomics/GTDBTk")[GTDB-Tk] | #link("https://gtdb.ecogenomic.org")[GTDB]
- *Linux 常用命令：*

```bash
checkm2 predict --input refined_bins --output-directory checkm2_out --threads 24

dRep dereplicate derep_out -g refined_bins/*.fa -p 24 -comp 50 -con 10 -sa 0.99 -nc 0.3

gtdbtk classify_wf --genome_dir derep_out/dereplicated_genomes --out_dir gtdbtk_out --cpus 24
```

=== 4. 模块汇总表

#tablem[
  | 工具 | 典型任务 | 核心原理 | 什么时候优先用 |
  | :--- | :--- | :--- | :--- |
  | MEGAHIT | 宏基因组组装 | succinct de Bruijn graph | 大项目、速度和内存优先 |
  | metaSPAdes | 宏基因组组装 | 多 k-mer 图组装 | 追求更细的 contig 质量 |
  | metaWRAP | 工作流整合 | 封装组装与分箱 | 想用成熟流程减少手工拼装 |
  | MetaBAT2 | 分箱 | tetranucleotide + abundance | 常见基线分箱器 |
  | MaxBin2 | 分箱 | marker gene + coverage | 常与其他分箱器联合 |
  | CONCOCT | 分箱 | k-mer + coverage 聚类 | 多样本联合分箱 |
  | SemiBin2 | 分箱 | 半监督表示学习 | 近年较新的高性能方案 |
  | CheckM2 | MAG 质控 | 机器学习预测质量 | 新类群或碎片 MAG |
  | dRep | 去冗余 | sketch + ANI | 菌株级代表基因组筛选 |
  | GTDB-Tk | 分类 | GTDB marker phylogeny + RED | MAG 最终分类标注 |
  | QUAST/metaQUAST | 组装评估 | 比对与连续性统计 | 组装质量快速体检 |
]

#line()

== 五、基因组功能注释与特化功能挖掘

到这一步，问题从"这个 bin/物种是谁"变成"它能做什么"。不同工具在注释粒度上差别很大，有的偏基础基因预测，有的偏代谢网络，有的专抓糖活性酶、耐药基因或次级代谢产物。

=== 1. Prokka / Bakta

- *为什么常用：* 这是原核基因组快速注释里最典型的一对组合。Prokka 经典、轻量，Bakta 较新、标准化程度更高。
- *底层原理解读：* `Prokka` 的工作核心是"先找基因，再给名字"。它调用 `Prodigal` 预测 CDS，再用 `Aragorn`/`Barrnap`/`RNAmmer` 找 tRNA/rRNA，最后把预测得到的蛋白序列与一组精简但实用的注释库比对，输出 `.gff`、`.gbk`、`.faa`、`.ffn` 等标准结果。`Bakta` 可以看作新一代自动注释器，强调数据库标准化、可重复性和对基因组元素（CDS、sRNA、CRISPR、pseudo gene 等）的细分标注，并内置了 AMR、IPS、COG 等注释。两者都不等于深度功能解析，但它们是后续 eggNOG、DRAM、antiSMASH、耐药和毒力分析的地基。对于微生物研究者来说，先把一个 MAG 或分离株整理成结构清楚、坐标准确的基因组注释文件，是一切比较基因组和代谢分析的起点。
- *简单流程图：*

```text
genome/MAG -> Prodigal 预测 CDS -> rRNA/tRNA 检测 -> 蛋白功能比对 -> GFF/FAA/GBK 注释文件
```

- *用途：* 原核基因组快速结构注释和基础功能命名。
- *官方地址：* #link("https://github.com/tseemann/prokka")[Prokka] | #link("https://github.com/oschwengers/bakta")[Bakta] | #link("https://github.com/hyattpd/prodigal")[Prodigal]
- *Linux 常用命令：*

```bash
prokka --outdir prokka_out --prefix sample --cpus 16 --kingdom Bacteria genome.fa

bakta --db /data/bakta_db --output bakta_out --prefix sample --threads 16 genome.fa
```

=== 2. eggNOG-mapper / DRAM

- *为什么常用：* 当你不满足于"这个基因可能是什么蛋白"，而是想系统整理代谢潜力、功能类别和通路时，这类工具比 Prokka 更合适。
- *底层原理解读：* `eggNOG-mapper` 依赖 eggNOG 的同源群和功能注释体系，本质上是"把你的蛋白放到一个已知正交群里，再继承该群已有的 COG、GO、KEGG、EC、CAZy 等注释"。这种正交群方式比简单 BLAST 命中更有结构性，适合批量功能摘要；底层用 DIAMOND 或 HMMER 加速。`DRAM` 则更偏向代谢解读，它会把基因组或 MAG 的注释结果重组成代谢层面的摘要，尤其适合查看碳、氮、硫代谢、发酵、能量获取和生态位相关模块，并输出 distill 摘要表。很多环境微生物或肠道微生物研究最终都要回答"谁在做什么代谢"，这正是 DRAM 擅长的地方。
- *简单流程图：*

```text
蛋白序列/基因组 -> 同源群匹配或代谢词典映射 -> EC/KO/COG/GO -> 代谢模块摘要
```

- *用途：* 大规模功能注释、代谢潜力整理、EC/KO/GO/COG 分析。
- *官方地址：* #link("https://github.com/eggnogdb/eggnog-mapper")[eggNOG-mapper] | #link("https://github.com/WrightonLabCSU/DRAM")[DRAM] | #link("http://eggnog5.embl.de")[eggNOG 数据库]
- *Linux 常用命令：*

```bash
emapper.py -i prokka_out/sample.faa --output sample_eggnog --cpu 24 -m diamond

DRAM.py annotate -i genome.fa -o dram_annotate --threads 24
DRAM.py distill -i dram_annotate/annotations.tsv -o dram_distill
```

=== 3. dbCAN3 / antiSMASH / RGI / AMRFinderPlus

- *为什么常用：* 这是"专题功能挖掘"工具组，分别对应碳水化合物代谢、次级代谢产物、生物合成和耐药性。
- *底层原理解读：* `dbCAN3` 聚焦 CAZyme，也就是糖苷水解酶、糖基转移酶等碳水化合物活性酶，通常结合 HMM（基于 dbCAN HMM 库）、DIAMOND（CAZy 库）和 Hotpep 三种证据投票，提高糖代谢相关注释的可靠性。`antiSMASH` 则专门寻找次级代谢基因簇，例如 NRPS、PKS、bacteriocin 等，它本质上是在基因组上寻找具有特定组织结构和保守域组合的 biosynthetic gene cluster，并配合规则库和 HMM 识别。`RGI` 和 `AMRFinderPlus` 面向耐药基因识别，前者依托 CARD，用严格/宽松两种模式结合蛋白家族规则；后者依托 NCBI AMR 体系，除了精确序列匹配，也会考虑蛋白家族规则和功能域，覆盖 AMR、stress、biocide 和部分毒力。微生物研究中，这类专题工具非常关键，因为很多生物学问题不是"这个菌总体代谢如何"，而是"它能不能降解多糖、产天然产物、携带耐药性"。
- *简单流程图：*

```text
基因组/蛋白 -> 专题数据库搜索 -> 专题规则过滤 -> CAZy/BGC/AMR 结果表 -> 机制解释
```

- *用途：* 糖活性酶、次级代谢基因簇、耐药基因等特定功能挖掘。
- *官方地址：* #link("https://github.com/linnabrown/run_dbcan")[dbCAN] | #link("https://antismash.secondarymetabolites.org")[antiSMASH] | #link("https://github.com/arpcard/rgi")[CARD-RGI] | #link("https://github.com/ncbi/amr")[AMRFinderPlus] | #link("https://github.com/tseemann/abricate")[abricate]
- *Linux 常用命令：*

```bash
run_dbcan genome.fa prok --out_dir dbcan_out --db_dir /data/dbcan --dia_cpu 24 --hmm_cpu 24

antismash --genefinding-tool prodigal --output-dir antismash_out genome.fa

rgi main --input_sequence prokka_out/sample.faa --output_file sample_rgi --input_type protein --num_threads 24

amrfinder -n genome.fa -o amrfinder.tsv --threads 24

# abricate 一次性扫多个数据库（CARD/NCBI/VFDB）
abricate --db vfdb genome.fa > vfdb_hits.tsv
```

=== 4. 模块汇总表

#tablem[
  | 工具 | 典型任务 | 核心原理 | 什么时候优先用 |
  | :--- | :--- | :--- | :--- |
  | Prokka | 快速注释 | Prodigal 基因预测 + 轻量库比对 | 初步整理分离株和 MAG |
  | Bakta | 标准化注释 | 统一数据库 + 规则注释 | 想要更现代、规范的结果 |
  | eggNOG-mapper | 批量功能注释 | 正交群映射 | 需要 KO/EC/GO/COG |
  | DRAM | 代谢潜力摘要 | 代谢模块重构 | 环境/肠道代谢解读 |
  | dbCAN3 | CAZyme | HMM + DIAMOND + Hotpep 投票 | 多糖降解、碳源利用 |
  | antiSMASH | 次级代谢产物 | BGC 识别规则 | 天然产物和菌群竞争机制 |
  | RGI | 耐药基因 | CARD 规则匹配 | AMR 机制挖掘 |
  | AMRFinderPlus | 耐药/抗性 | NCBI AMR 框架 | 临床和病原微生物项目 |
  | abricate | 毒力/耐药扫描 | 多专题数据库一次性比对 | 病原菌快速筛查 |
  | VFDB | 毒力因子 | 毒力数据库 | 病原菌分析补充 |
]

#line()

== 六、微生物生态性状与生活史特征分析

前几章解决了"谁在那里"和"能做什么代谢"，但没有回答"它们以什么生态策略占位"。生态性状（trait）分析这一层，就是把基因组或群落组成翻译成一组可量化的生活史/生态策略指标，例如 copiotroph 与 oligotroph 倾向、rRNA 操纵子拷贝数、胁迫响应能力、碳氮硫代谢潜力等。这一层在环境微生物组、肠道-环境比较、菌株生态位分化等研究中越来越重要，因为它把"物种名"或"基因清单"推进到"功能策略"，更容易和生态学假设对接。这一章把从基因组层（microtrait）到 16S 层（FAPROTAX、Tax4Fun2、PICRUSt2、BugBase、METAGENassist）的性状预测工具集中起来对比，因为它们输入不同、假设不同，但目标都是同一个：给群落一个可比较的生态/功能画像。

=== 1. microtrait

- *为什么常用：* 当你手上已经是分离株基因组或高质量 MAG，想直接从基因组特征推断"它以什么策略生存"时，microtrait 是目前少数能输出系统化生活史特征矩阵的工具。
- *底层原理解读：* `microtrait` 不做基因命名，而是把基因组特征聚合成可计算的"微生物生活史特征（traits）"。它从基因组里抽取一系列与生态策略相关的可量化指标：基因组大小、GC 含量、16S 拷贝数、rRNA 操纵子数、碳源利用相关基因、抗生素抗性基因、胁迫响应基因、运动性基因等，再用规则或模型聚合成 trait 矩阵。这样做的价值是把"一个基因组"翻译成"一组生态位和生活史策略的数值描述"，方便跨样本、跨类群比较。例如 rRNA 操纵子数常被用作"响应型 copiotroph vs 贫营养型 oligotroph"的代理指标：拷贝多通常对应高资源响应、快速生长，拷贝少对应贫营养稳定环境。对环境和肠道微生物组研究来说，microtrait 把"谁在那里"推进到"它们以什么策略占位"，是从基因清单走向生态学假设的关键一步。
- *简单流程图：*

```text
基因组 FASTA -> 基因预测 + 特征抽取（大小/GC/16S 拷贝/功能基因）-> 规则聚合为 trait 矩阵 -> 跨基因组生活史/生态策略比较
```

- *用途：* 从分离株/MAG 基因组推断生活史特征（生长策略、资源响应、胁迫适应），支撑生态策略与生活史比较。
- *官方地址：* #link("https://github.com/ukaraoz/microtrait")[microtrait GitHub] | #link("https://ukaraoz.github.io/microtrait/")[microtrait 文档]
- *Linux 常用命令：*

```bash
# 构建特征矩阵（需先准备基因组目录）
microtrait build-trait-matrix -i genomes_dir -o microtrait_out

# 对单个基因组提取 trait
microtrait extract-trait -i genome.fa -o genome_traits.tsv
```

=== 2. FAPROTAX

- *为什么常用：* 只拿到 16S 物种表、没有 shotgun 数据时，FAPROTAX 是把 OTU/ASV 丰度表"翻译"成生态功能（尤其是碳氮硫循环、发酵、共生等）最常用的经验注释工具。
- *底层原理解读：* `FAPROTAX`（Functional Annotation of Prokaryotic Taxa）的核心是一个手工整理的"分类单元-功能"映射表，目前收录约 7600 多个原核分类单元到 90 余个功能（如好氧化合、硝化、反硝化、发酵、光养、芳香化合物降解等）的关联。它的工作流是：以 16S 得到的物种/属级注释为输入，按映射表把每个分类单元对应的功能累加到样本层面，输出样本-功能矩阵。本质上这是一种基于专家文献经验的"分类学推断功能"，而不是真正的基因预测，因此适合做宏观生态功能比较、生态系统过程假设，但对菌株级功能差异不可靠，且依赖参考库覆盖度。
- *简单流程图：*

```text
16S OTU/ASV 丰度表 + 物种注释 -> 查 FAPROTAX 映射表（taxa->function）-> 按丰度累加 -> 样本-功能矩阵（碳氮硫循环/发酵等）
```

- *用途：* 从 16S 数据推断群落生态功能，特别是元素循环（C/N/S/Fe）、发酵和共生关系，适合环境样本。
- *官方地址：* #link("http://www.loucalab.com/archive/FAPROTAX")[FAPROTAX] | #link("https://pages.uoregon.edu/slouc/FAPROTAX/")[FAPROTAX 文档与下载]
- *Linux 常用命令：*

```bash
# 典型用法：以 OTU 表（含 taxonomy 列）为输入，输出功能表
python collapse_table.py -i otu_table.txt -o FAPROTAX_reported_func.tsv \
  -g FAPROTAX.txt -c "#" -d ";" -v

# 默认 strict 模式只注释到属以上明确注释的类群；
# 加 --include_subclades 可向下推到种，但需谨慎
```

=== 3. Tax4Fun2 / PICRUSt2

- *为什么常用：* 只有 16S 数据但想要 KEGG 通路/EC 层面的功能丰度估计时，这两个工具是主力：PICRUSt2 基于系统发育祖先状态推断，Tax4Fun2 基于参考基因组相似度直接映射，思路不同可互为校验。
- *底层原理解读：* `PICRUSt2` 的核心是"用系统发育关系预测未培养类群的基因内容"。它先对 16S 序列放置到参考树（通过 EPA-ng/SEPP），再用祖先状态重建（castor）推断每个 ASV 对应的基因家族拷贝数，结合 NSTI（Nearest Sequenced Taxon Index）给出预测可靠性，最后映射到 KEGG 通路/EC/MetaCyc，输出样本-功能丰度表。NSTI 越大代表最近参考基因组越远、预测越不可靠，这是 PICRUSt2 最重要的可信度指标。`Tax4Fun2` 走的是另一条路：它把 16S 序列直接与参考基因组 16S 比对（默认用 usearch），按相似度阈值（如 97%）选出参考基因组，再把这些参考基因组的 KEGG 功能谱按丰度加权聚合到样本。两者都依赖参考库覆盖度，Tax4Fun2 允许自建参考集，更适合环境或非肠道样本；PICRUSt2 对肠道等覆盖好的样本更成熟，且输出粒度更细。
- *简单流程图：*

```text
PICRUSt2: ASV -> 放到参考树 -> 祖先状态重建预测基因拷贝 -> NSTI 评估 -> KEGG 通路/EC 丰度表
Tax4Fun2: ASV -> 与参考 16S 比对选参考基因组 -> 参考功能谱加权聚合 -> KEGG 功能丰度表
```

- *用途：* 从 16S 推断 KEGG 通路、EC、MetaCyc 功能丰度，做"无 shotgun 数据"的功能假设和筛选。
- *官方地址：* #link("https://github.com/picrust/picrust2")[PICRUSt2] | #link("https://picrust.github.io/picrust/")[PICRUSt2 文档] | #link("https://github.com/bwemheu/Tax4Fun2")[Tax4Fun2]
- *Linux 常用命令：*

```bash
# PICRUSt2：输入为 QIIME2 序列和特征表
picrust2_pipeline.py -s seqs.qza -i table.qza -o picrust2_out \
  -p 24 --stratified --per_sequence_contrib

# Tax4Fun2：先建参考集（一次性），再预测
runTax4Fun2.R -ref_folder ref_db -threads 24
predictFunctionalProfiles.R -fwd R1.fastq -rev R2.fastq \
  -folder seqs -ref ref_db -out tax4fun2_out
```

=== 4. BugBase

- *为什么常用：* 想快速得到群落在"表型"层面的占比（革兰氏阳性/阴性、好氧/厌氧、耐受性、生物膜形成等）时，BugBase 提供一个现成的表型注释入口，适合做表型驱动的样本比较。
- *底层原理解读：* `BugBase` 的逻辑与 FAPROTAX 类似，都是"分类单元-\>表型"的经验映射，但它聚焦的是微生物表型而非生态功能：革兰氏染色、好氧/厌氧/兼性、致病性、移动性、氧化胁迫耐受、生物膜形成等。输入 16S OTU 表后，它按映射表把分类单元对应表型，再以丰度加权得到每个样本各表型的相对占比，并支持按分组比较表型差异、输出可视化。它的局限是依赖映射表的覆盖度和准确度，且多基于属级注释，菌株差异不可分辨；但对教学、快速探索和临床样本表型画像仍然实用。
- *简单流程图：*

```text
16S OTU 表 + 物种注释 -> 查 BugBase 表型映射表 -> 丰度加权 -> 样本-表型占比（革兰/氧需求/致病性等）
```

- *用途：* 从 16S 推断群落表型构成（革兰染色、氧需求、致病性、生物膜等），适合表型驱动比较。
- *官方地址：* #link("http://bugbase.cs.brown.edu/")[BugBase] | #link("https://github.com/knights-lab/BugBase")[BugBase GitHub]
- *Linux 常用命令：*

```bash
# BugBase 主要为 Web/R 流程，命令行示例（需先准备 OTU 表与元数据）
run.bugbase.r -i otu_table.biom -m metadata.txt -c treatment -o bugbase_out

# Web 版：访问 bugbase.cs.brown.edu 上传 biom 文件即可
```

=== 5. METAGENassist

- *为什么常用：* 想把微生物组丰度与表型/环境元数据在一个交互式平台里做统计和可视化比较时，METAGENassist 把数据清洗、统计和化学/环境表型分析打包在一起，适合不写代码的分析者。
- *底层原理解读：* `METAGENassist` 是一个基于 Web 的宏基因组分析平台，核心是把"物种丰度表"与"微生物表型/环境属性"（如氧需求、代谢类型、栖息地、温度范围等）和样本元数据耦合，提供从数据过滤、归一化、单/多变量统计到可视化的完整流程。它的表型库覆盖代谢类型、电子受体、氧需求、温度、盐度等，能直接把群落组成与生态/环境属性关联，而不只是输出物种差异。底层统计封装了 PCA、PLS-DA、随机森林、热图、火山图等常见方法。它的价值在于"表型-环境-丰度"三者的联动分析，对环境微生物组尤其是污染、发酵、极端环境等方向很合用；缺点是依赖在线平台和内置表型库的覆盖度。
- *简单流程图：*

```text
物种丰度表 + 样本元数据 + 微生物表型库 -> 归一化/过滤 -> 统计建模（PCA/PLS-DA/RF）-> 表型-环境-丰度关联可视化
```

- *用途：* 把微生物组丰度与表型/环境元数据联动分析，做统计建模与可视化比较。
- *官方地址：* #link("https://metagenassist.ca")[METAGENassist]
- *Linux 常用命令：*

```bash
# METAGENassist 主要为 Web 平台，无标准命令行入口
# 典型流程：访问 https://metagenassist.ca -> 上传物种丰度表 + 元数据 -> 选表型属性 -> 在线统计与可视化 -> 导出结果
# 若需脚本化，可先用本地工具（如 vegan、randomForest）复现其分析，再对比
```

=== 6. 模块汇总表

#tablem[
  | 工具 | 输入 | 核心原理 | 主要产出 | 什么时候优先用 |
  | :--- | :--- | :--- | :--- | :--- |
  | microtrait | 分离株/MAG 基因组 | 基因组特征抽取聚合成 trait 矩阵 | 生活史/生态策略特征 | 已有高质量基因组，做策略级比较 |
  | FAPROTAX | 16S 物种表 | taxa-\>function 经验映射 | 碳氮硫循环/发酵等功能矩阵 | 只有 16S，关心元素循环 |
  | Tax4Fun2 | 16S 序列 | 参考基因组相似度映射 | KEGG 功能丰度 | 只有 16S，可自建参考集、环境样本 |
  | PICRUSt2 | 16S ASV + 树 | 系统发育祖先状态重建 | KEGG 通路/EC/MetaCyc + NSTI | 肠道等覆盖好的样本，要细粒度 |
  | BugBase | 16S OTU 表 | taxa-\>表型映射 | 革兰/氧需求/致病性等表型占比 | 快速表型画像、教学探索 |
  | METAGENassist | 丰度表 + 元数据 | 表型-环境-丰度耦合统计 | 关联分析与可视化 | 表型/环境驱动比较，少代码分析 |
]

#line()
== 七、统计分析、差异丰度、来源追踪与机器学习

微生物组分析最容易出偏差的不是"没有工具"，而是没有理解组成型数据、零膨胀和批次效应。这个模块里的工具看起来不像组装器那么"硬核"，但决定了结论能不能站得住。

=== 1. vegan

- *为什么常用：* 只要做 alpha/beta 多样性、排序、PERMANOVA、envfit，几乎都会碰到它。
- *底层原理解读：* `vegan` 不是某一个单独算法，而是一套生态统计工具箱。它之所以在微生物组里重要，是因为群落数据天然是高维、稀疏且非正态的，很多传统线性统计并不适合。vegan 提供的 Shannon、Simpson、Bray-Curtis、Jaccard、Aitchison、NMDS、PCoA、PERMANOVA、envfit、dbRDA 等方法，本质上是在不同距离定义下描述样本间"群落结构是否更相似"以及"哪些环境因子在解释这种差异"。例如 PERMANOVA（adonis2）是基于距离矩阵的置换检验，适合不满足正态分布前提的生态数据；envfit 把环境因子拟合到排序空间，看哪些变量与群落梯度显著相关。它不能替代差异丰度模型，但非常适合作为群落层面的第一张全景图。
- *简单流程图：*

```text
feature table -> 距离矩阵 -> 排序/聚类 -> PERMANOVA/envfit/dbRDA -> 群落层面解释
```

- *用途：* alpha/beta 多样性、排序分析、PERMANOVA、生态统计。
- *官方地址：* #link("https://cran.r-project.org/package=vegan")[CRAN] | #link("https://vegandevs.github.io/vegan/")[文档]
- *Linux 常用命令：*

```r
library(vegan)
shannon <- diversity(otu_table, index = "shannon")
bc <- vegdist(otu_table, method = "bray")
adonis2(bc ~ Group + BMI + Batch, data = meta, permutations = 999)
ord <- capscale(bc ~ Group + Condition(Batch), data = meta)
envfit(ord, meta[, c("BMI","Age","pH")])
```

=== 2. ANCOM-BC2 / MaAsLin3 / LinDA / metagenomeSeq

- *为什么常用：* 这组工具都是为"差异丰度分析"服务，但假设不同，所以没有一把万能锤子。
- *底层原理解读：* 微生物丰度表不是普通计数矩阵，它既有组成型约束，也有大量零值。`ANCOM-BC2` 试图通过 bias correction 估计不同组间真实丰度变化，从数学上处理"一个菌升必然导致其他菌相对降"的组成型偏差，直接估计绝对丰度级别的倍数变化，适合控制假阳性并支持较复杂协变量。`MaAsLin3` 更强调多变量关联建模，用广义线性模型同时纳入固定效应（疾病状态、饮食）和随机效应（临床中心、受试者），适合"菌和临床变量/饮食/环境因素的关系"这类问题。`LinDA` 采用 log-ratio 思路，是目前速度和假阳性控制（FDR）综合表现顶尖的算法之一。`metagenomeSeq` 的 ZIG（零膨胀高斯）模型是较早处理零膨胀的经典工具，会把"真生物学缺失"与"测序深度不足造成的缺失"分开建模。它们的共同点是：都在努力解决"总和约束"和"零太多"这两个微生物组统计核心难题。选择时通常要看研究设计、协变量复杂度和审稿领域偏好。
- *简单流程图：*

```text
feature table + metadata -> 归一化/偏差校正 -> 回归或差异模型 -> 多重校正 -> 显著菌/功能列表
```

- *用途：* 差异丰度、微生物-表型关联、多变量校正。
- *官方地址：* #link("https://github.com/FrederickHuangLin/ANCOMBC")[ANCOMBC] | #link("https://github.com/biobakery/maaslin3")[MaAsLin3] | #link("https://github.com/zhouhj1994/LinDA")[LinDA] | #link("https://github.com/HCBravoLab/metagenomeSeq")[metagenomeSeq]
- *Linux 常用命令：*

```r
library(ANCOMBC)
res <- ancombc2(data = physeq, fix_formula = "Group + BMI + Age",
               p_adj_method = "BH", group = "Group")

library(maaslin3)
fit_data <- maaslin3(input_data = feat, input_metadata = meta,
                     output = "maaslin3_out",
                     formula = "~ disease_status + age + BMI")

library(metagenomeSeq)
obj <- newMRexperiment(counts)
obj <- cumNorm(obj)
fit <- fitZIG(obj, mod = model.matrix(~ Group + BMI, data = meta))
```

=== 3. FEAST / SourceTracker2

- *为什么常用：* 当问题变成"这个群落像谁、来自谁、迁移了多少"时，普通差异分析不够用了。
- *底层原理解读：* `SourceTracker2` 基于贝叶斯混合模型，用 Gibbs 抽样把目标样本视为多个已知来源环境的混合结果，估计每个来源的贡献比例，并带有一个"未知来源"的类别吸收无法解释的部分。`FEAST` 也是来源追踪工具，但它用更高效的期望最大化（EM）框架做混合权重估计，在大样本情况下通常更快。两者的关键假设都是：目标样本的微生物组成可以由若干 source community 线性组合近似。Zhang et al. 2026 正是用这类方法分析泰国移民肠道内酶谱的演替来源，比较美国出生者、泰国居住者、新移民、长期居住者的群落相似性。对微生物生态、移民队列、环境暴露和污染追踪研究来说，这非常有用，因为问题不再是某个菌多不多，而是"群落整体更像哪个来源"。
- *简单流程图：*

```text
source communities + sink samples -> 混合模型拟合 -> 估计来源权重 -> 来源贡献比例图
```

- *用途：* 来源追踪、迁移分析、环境暴露与微生物转移研究。
- *官方地址：* #link("https://github.com/caporaso-lab/sourcetracker2")[SourceTracker2] | #link("https://github.com/cozygene/FEAST")[FEAST]
- *Linux 常用命令：*

```bash
sourcetracker2 gibbs -i otu_table.biom -m sample_metadata.tsv -o st2_out --jobs 4
```

```r
library(FEAST)
# FEAST 通常在 R 中准备 source/sink 计数矩阵后调用
# source_counts: 行为 source 样本，列为 ASV
# sink_counts: 行为 sink 栓本，列为 ASV
est <- FEAST(source = source_counts, sinks = sink_counts, em_itr = 1000)
```

=== 4. caret / Boruta / pROC / fastshap / robCompositions / compositions / labdsv / lmerTest

- *为什么常用：* 当目标是做诊断模型、筛关键菌或解释模型时，这类工具能把统计结果进一步转成预测框架；同时组成型预处理和重复测量统计也常被一起使用。
- *底层原理解读：* `caret` 更像机器学习调度层，它统一封装了交叉验证、预处理和模型训练接口；`Boruta` 基于随机森林和 shadow features 做特征选择，判断某个菌或功能是否真的比随机噪声更重要；`pROC` 专注 ROC/AUC 评估；`fastshap` 则把模型输出拆成特征贡献，近似计算每个变量的 Shapley value。`robCompositions` 和 `compositions` 都处理组成型数据，前者计算稳健 Aitchison 距离，后者提供 CLR 变换；`labdsv` 用 Dufrêne-Legendre indval 找特征种；`lmerTest` 用线性混合模型处理重复测量和小动物模型。对于微生物组项目，这类方法最容易被滥用，因为样本量往往不大、特征却很多，所以一定要配合分层交叉验证、外部验证和批次控制使用。工具本身并不保证可靠结论，但它们能把"差异列表"升级为"可解释预测模型"和"稳健生态统计"。
- *简单流程图：*

```text
特征表 -> CLR/组成型预处理 -> 训练/验证划分 -> 特征筛选 -> 建模 -> ROC/AUC -> SHAP 解释特征贡献
```

- *用途：* 微生物标志物筛选、分类模型、可解释机器学习、组成型统计与重复测量。
- *官方地址：* #link("https://cran.r-project.org/package=caret")[caret] | #link("https://cran.r-project.org/package=Boruta")[Boruta] | #link("https://cran.r-project.org/package=pROC")[pROC] | #link("https://cran.r-project.org/package=fastshap")[fastshap] | #link("https://cran.r-project.org/package=compositions")[compositions] | #link("https://cran.r-project.org/package=labdsv")[labdsv] | #link("https://cran.r-project.org/package=lmerTest")[lmerTest]
- *Linux 常用命令：*

```r
library(caret)
ctrl <- trainControl(method = "repeatedcv", number = 5, repeats = 3,
                     classProbs = TRUE, summaryFunction = twoClassSummary)
rf_fit <- train(Group ~ ., data = train_df, method = "rf",
                trControl = ctrl, metric = "ROC")

library(Boruta)
bor <- Boruta(Group ~ ., data = train_df, doTrace = 0)
bor_imp <- TentativeRoughFix(bor)

library(pROC)
roc_obj <- roc(test_df$Group, predict(rf_fit, test_df, type = "prob")[,2])
auc(roc_obj)

library(compositions)
clr_mat <- clr(otu_table + 0.5)
```

=== 5. 模块汇总表

#tablem[
  | 工具 | 典型任务 | 核心原理 | 什么时候优先用 |
  | :--- | :--- | :--- | :--- |
  | vegan | 群落统计 | 距离矩阵与置换检验 | alpha/beta 多样性、排序 |
  | robCompositions | 稳健 Aitchison | 稳健组成型距离 | β 多样性组成型数据 |
  | compositions | CLR 变换 | 组成型数据预处理 | 相关分析前归一化 |
  | labdsv | 指标种 | Dufrêne-Legendre indval | 找各区域特征种 |
  | ANCOM-BC2 | 差异丰度 | 偏差校正 | 组成型数据、控制假阳性 |
  | MaAsLin3 | 关联建模 | GLM + 随机效应 | 多协变量微生物-表型关系 |
  | LinDA | 差异丰度 | log-ratio 模型 | 组成型数据分析 |
  | metagenomeSeq | 差异丰度 | 零膨胀高斯模型 | 稀疏度高的早期经典方案 |
  | FEAST | 来源追踪 | EM 混合模型 | 迁移/暴露/来源比例 |
  | SourceTracker2 | 来源追踪 | 贝叶斯混合 + Gibbs | source-sink 问题 |
  | lmerTest | 重复测量 | 线性混合模型 | 小鼠时间序列、纵向数据 |
  | caret | 建模 | 统一训练接口 | 快速建立分类模型 |
  | Boruta | 特征选择 | shadow features | 挑稳定标志物 |
  | pROC | 评估 | ROC/AUC | 模型性能评估 |
  | fastshap | 解释 | SHAP 近似 | 解释模型特征贡献 |
  | Benjamini-Hochberg | 多重校正 | FDR 控制 | 多重比较后控假阳性 |
]

#line()

== 八、近年值得补充的长读长、病毒与移动元件工具

如果项目开始涉及 Nanopore/PacBio、噬菌体、质粒或移动遗传元件，传统短读长细菌工具就不够了。这个模块是近几年微生物分析里增长很快的方向。

=== 1. metaFlye / Unicycler / OPERA-MS

- *为什么常用：* 长读长让重复区域和结构变异更容易被跨越，对闭环基因组、质粒和复杂基因簇尤其有帮助。
- *底层原理解读：* `metaFlye` 面向长读长宏基因组组装，核心是利用长 read 覆盖重复区域的能力，在重叠图或 string graph 框架下恢复更长 contig，并用纠错与重复解析提升连续性。与短读长 de Bruijn graph 不同，长读长组装更多依赖 read-read overlap，因此对错误率和覆盖要求更敏感，但在结构连续性上优势明显。`Unicycler` 则擅长细菌分离株的混合组装，常用短读长校错、长读长架桥，把染色体和质粒尽量闭环，输出桥接图。`OPERA-MS` 属于宏基因组混合组装路线，试图利用短读长的准确度和长读长的跨重复能力共同改进 assembly，并支持菌株级分辨。对微生物研究来说，这类工具特别适合做高质量参考基因组、质粒传播和耐药岛分析。
- *简单流程图：*

```text
Nanopore/PacBio reads +/- Illumina reads -> overlap/混合组装 -> scaffold/闭环 -> 高连续基因组
```

- *用途：* 长读长或混合组装，闭环基因组、质粒和复杂重复区重建。
- *官方地址：* #link("https://github.com/fenderglass/Flye")[Flye/metaFlye] | #link("https://github.com/rrwick/Unicycler")[Unicycler] | #link("https://github.com/CSB5/OPERA-MS")[OPERA-MS]
- *Linux 常用命令：*

```bash
flye --meta --nano-raw nanopore.fastq.gz --out-dir metaflye_out --threads 32

unicycler -1 clean_R1.fastq.gz -2 clean_R2.fastq.gz -l nanopore.fastq.gz -o unicycler_out -t 32

# 长读长 polishing
racon -t 16 reads.fastq metaflye_out/assembly.fasta metaflye_out/racon_out.fasta
```

=== 2. VirSorter2 / geNomad / CheckV

- *为什么常用：* 宏基因组里病毒和质粒往往最难找，因为它们没有稳定的通用 marker，也常常高度新颖。
- *底层原理解读：* `VirSorter2` 利用多种特征识别病毒序列，包括病毒 hallmark genes、基因密度、基因方向、序列组成等，并结合分类器把 contig 评为更可能是病毒还是细胞型序列，再按 dsDNAphage、ssDNA、RNA 等类别细分。`geNomad` 是近几年非常值得关注的工具，它把病毒、质粒和染色体序列放在统一框架里做鉴别，借助神经网络和标记基因证据，对移动元件识别尤其方便，并自带注释。`CheckV` 不负责"发现病毒"，而是负责评估病毒序列完整度、宿主污染和边界，帮助你判断一个病毒 contig 是完整、近完整还是碎片，并修复边界。三者合起来，可以从环境和肠道宏基因组中系统挖掘 vMAG、噬菌体和质粒。
- *简单流程图：*

```text
contigs -> 病毒/质粒识别 -> 完整度评估 -> 去污染与分级 -> 病毒基因组集合
```

- *用途：* 病毒、质粒和移动元件识别与质量评估。
- *官方地址：* #link("https://github.com/jiarong/VirSorter2")[VirSorter2] | #link("https://github.com/apcamargo/genomad")[geNomad] | #link("https://bitbucket.org/berkeleylab/checkv/src/master/")[CheckV]
- *Linux 常用命令：*

```bash
virsorter run -w virsorter2_out -i contigs.fa --include-groups dsDNAphage,ssDNA -j 24 all

genomad end-to-end contigs.fa genomad_out /data/genomad_db --threads 24

checkv end_to_end contigs.fa checkv_out /data/checkv_db -t 24
```

=== 3. CoverM / Salmon / featureCounts

- *为什么常用：* 当你已经有 MAG、基因或 contig 集合后，还需要一个稳健的方法把样本 reads 回贴回去，计算覆盖度或表达量。
- *底层原理解读：* `CoverM` 是近年在 MAG 和 contig 丰度估计里非常实用的工具，本质上是围绕 read mapping 后的覆盖统计做了高效封装，尤其适合计算 genome coverage、contig abundance 和相对丰度，支持 mean、relative\_abundance、covered\_fraction 等多种度量。`Salmon` 虽然最初为转录组设计，但在基因家族或转录本定量上仍常被借用，其核心是轻量级 quasi-mapping 和概率分配，并支持偏差校正。`featureCounts` 则在有明确坐标注释时快速汇总 reads 到基因级别。对微生物组研究者而言，这一步常常把"静态基因组集合"转成"样本中的实际丰度或表达"，是比较组学和时间序列分析的重要中间层。
- *简单流程图：*

```text
reads + reference(MAG/gene set) -> mapping/quasi-mapping -> 覆盖度或计数 -> 丰度矩阵
```

- *用途：* MAG 覆盖度估计、基因计数、宏转录组表达量估计。
- *官方地址：* #link("https://github.com/wwood/CoverM")[CoverM] | #link("https://github.com/COMBINE-lab/salmon")[Salmon] | #link("https://subread.sourceforge.net")[featureCounts/Subread]
- *Linux 常用命令：*

```bash
coverm genome -1 clean_R1.fastq.gz -2 clean_R2.fastq.gz -r mags/*.fa \
  --threads 24 --methods relative_abundance covered_fraction mean -o coverm.tsv

salmon index -t gene_catalog.fa -i salmon_idx
salmon quant -i salmon_idx -l A -1 clean_R1.fastq.gz -2 clean_R2.fastq.gz -p 24 -o salmon_quant

featureCounts -a sample.gff -o counts.txt mapped.bam -T 24 -p
```

=== 4. 模块汇总表

#tablem[
  | 工具 | 典型任务 | 核心原理 | 什么时候优先用 |
  | :--- | :--- | :--- | :--- |
  | metaFlye | 长读长宏基因组组装 | overlap graph | Nanopore/PacBio 宏基因组 |
  | Unicycler | 混合组装 | 短读长校错 + 长读长架桥 | 分离株闭环、质粒分析 |
  | OPERA-MS | 混合宏基因组组装 | short+long hybrid | 想改进复杂样本连续性 |
  | Racon/Medaka | 长读长抛光 | 共识纠错 | Nanopore 组装后纠错 |
  | VirSorter2 | 病毒识别 | hallmark genes + 分类器 | 噬菌体挖掘 |
  | geNomad | 病毒/质粒识别 | 深度学习 + 标记基因 | 新一代移动元件分析 |
  | CheckV | 病毒质控 | 完整度与污染评估 | vMAG/vContig 质量控制 |
  | CoverM | 覆盖度估计 | mapping coverage | MAG 丰度回贴 |
  | Salmon | 表达定量 | quasi-mapping | 宏转录组/基因级表达 |
  | featureCounts | 基因计数 | 注释坐标汇总 | 已有 GFF/GTF 的计数任务 |
]

#line()

== 九、化学信息学与关联数据库

这一模块对应 Zhang et al. 2026 把肠道微生物与植物化学成分直接绑定的工作。这类研究要把"食物-化合物-酶-微生物"串成一条链，依赖大量数据库查询和化学信息学计算，是微生物组向食物-代谢-健康方向延伸时绕不开的一层。

=== 1. 天然产物与化学库：NutriChem 2.0 / LOTUS / NPASS / PubChem / KNApSAcK / SuperNatural / InflamNat

- *为什么常用：* 微生物代谢研究经常要先回答"这种化合物来自哪些食物、是不是植物来源"。
- *底层原理解读：* 这组数据库的核心都是建立"化合物-天然来源"的映射。`NutriChem 2.0` 提供食物-植物营养素关联，是构建"健康食品-植物营养素"矩阵的关键来源。`LOTUS`、`NPASS`、`KNApSAcK` 是天然产物库，通常用化合物 ID（如 CID）查询并验证化合物是否来自 Viridiplantae，可作为第一级筛选。`SuperNatural 3.0` 用 InChI/SMILES 查询第一级未匹配的化合物，做第二级筛选。`PubChem` 是通用化合物库，用 CID 关联植物营养素与酶反应，并用 Taxonomy 信息验证化合物来源。`InflamNat` 专门收录天然产物的抗炎活性，可按 IC50 阈值筛抗炎化合物。它们的共同逻辑是：先用结构标识符（SMILES/InChI/CID）定位化合物，再用 taxonomy 或来源表确认植物属性，最后与酶反应数据库对接。
- *简单流程图：*

```text
化合物 ID(SMILES/InChI/CID) -> 天然产物库匹配 -> taxonomy 校验 Viridiplantae -> 食物/来源矩阵
```

- *用途：* 化合物来源确认、食物-化合物矩阵、天然产物抗炎筛选。
- *官方地址：* #link("http://datam.iis.sinica.edu.tw/nutrichem2/")[NutriChem 2.0] | #link("https://lotus.naturalproducts.net")[LOTUS] | #link("https://bidd.group/NPASS/")[NPASS] | #link("https://pubchem.ncbi.nlm.nih.gov")[PubChem] | #link("http://www.knapsackfamily.com/knapsack_jsp/top.html")[KNApSAcK] | #link("http://bioinf.appliedinformatics.in/supernatural3/")[SuperNatural 3.0] | #link("http://www.inflamnat.org/")[InflamNat]
- *Linux 常用命令（多为数据库/API）：*

```bash
# 通过 PubChem REST API 按 CID 查询
curl -s "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/5280343/property/CanonicalSMILES,InChIKey,MolecularFormula/JSON"

# NPASS 提供离线下载的天然产物-来源表
wget https://bidd.group/NPASS/download/NPASSv1.01_NP_Pathway.txt
```

=== 2. 酶与反应数据库：KEGG / BKMS-react / IntEnz / EzCatDB / M-CSA / SFLD / EAWAG / Transformer / HMDB

- *为什么常用：* 把化合物绑到酶促反应，才能进一步连到微生物功能。
- *底层原理解读：* 这组数据库大多以 EC 编号（Enzyme Commission number）为核心标识，再用 CID、CHEBI、InChI 等结构标识符关联反应物。`KEGG` 是最常用的生化反应与通路库，通过 API 提供 EC-反应关联和次级/初级代谢分类。`BKMS-react` 整合了 BRENDA、KEGG、MetaCyc、SABIO-RK，用 InChI 关联。`IntEnz` 是酶命名库，用 CHEBI 标识符关联。`EzCatDB`、`M-CSA`、`SFLD`、`EAWAG`、`Transformer` 分别聚焦酶催化机制、催化位点、结构-功能、生物转化等不同侧面。`HMDB` 是人类代谢组库，用 CID 关联。它们的共同逻辑是：用 EC 把"酶"标准化，再用结构标识符把"化合物"绑到"反应"上，从而构建化合物-酶网络。
- *简单流程图：*

```text
化合物结构标识符 -> 匹配 EC/CID/CHEBI/InChI -> 酶反应数据库 -> 化合物-酶-反应网络
```

- *用途：* 化合物-酶关联、反应网络构建、次级/初级代谢分类。
- *官方地址：* #link("https://www.kegg.jp")[KEGG] | #link("https://bkms-react.brenda-enzymes.org")[BKMS-react] | #link("https://www.ebi.ac.uk/intenz/")[IntEnz] | #link("https://ezcatdb.cbrc.pj.aist.go.jp/OZCAT/")[EzCatDB] | #link("https://www.ebi.ac.uk/thornton-srv/m-csa/")[M-CSA] | #link("https://hmdb.ca")[HMDB] | #link("https://www.brenda-enzymes.org")[BRENDA]
- *Linux 常用命令：*

```bash
# KEGG REST API 查询某 EC 的反应
curl -s "https://rest.kegg.jp/get/ec:5.5.1.6"
```

```r
library(KEGGREST)
res <- keggGet("ec:5.5.1.6")
```

=== 3. 结构计算工具：RDKit / R 包（KEGGREST / XML / rvest）

- *为什么常用：* 数据库给的是标识符，但跨库对接和结构特征分析需要真正的化学信息学计算。
- *底层原理解读：* `RDKit` 是开源化学信息学 Python 库，核心能力包括 SMILES/InChI 互转、子结构匹配、功能基团识别、分子描述符计算。在 Zhang et al. 2026 中，它被用来把 SMILES 转 InChI 以对接 BKMS-react，并用 `rdkit.Chem.Fragments` 识别每个植物营养素的功能基团，用于"共享型 vs 肠道限制型"底物的结构特征分析。R 端则常用 `KEGGREST` 调 KEGG API、`XML` 解析返回、`rvest` 抓取 EAWAG/SFLD/Transformer 这类无标准 API 的数据库页面。这一层把"标识符列表"升级为"可计算分子结构"。
- *简单流程图：*

```text
SMILES -> RDKit -> InChI/功能基团/描述符 -> 对接酶反应库 -> 结构-活性分析
```

- *用途：* 分子结构转换、功能基团识别、跨库标识符对接、网页抓取。
- *官方地址：* #link("https://www.rdkit.org")[RDKit] | #link("https://www.rdkit.org/docs/")[RDKit 文档] | #link("https://bioconductor.org/packages/KEGGREST/")[KEGGREST] | #link("https://rvest.tidyverse.org")[rvest]
- *Linux 常用命令：*

```python
from rdkit import Chem
from rdkit.Chem import Descriptors, Fragments
mol = Chem.MolFromSmiles("C1=CC=C(C=C1)O")  # phenol
inchi = Chem.MolToInchi(mol)
print(inchi)
print(Fragments.fr_phenols(mol))  # 功能基团计数
```

=== 4. 化合物 ID 一致性处理实操

- *为什么常用：* 跨库对接（PubChem↔KEGG↔BKMS-react↔LOTUS↔HMDB）时，同一个化合物在不同库里用不同标识符（CID、InChI、InChIKey、SMILES、CAS、CHEBI、KEGG C number），而且立体化学、互变异构、盐形式的差异会让"同一个分子匹配不上"。这是化学信息学流程里最高频的隐性错误来源，处理不好会让"化合物-酶-微生物"关联直接漏掉一大块。
- *底层原理解读：* 标识符一致性处理的核心是"把任意输入统一到一套规范的、可比较的标识符上"。最稳的做法是用 InChIKey 的连接层（前 14 位）做跨库主键：InChIKey 第一层编码分子骨架连接性、忽略立体和同位素，因此同骨架不同立体异构体仍能聚到一起；需要立体精确匹配时再用完整 InChIKey。典型流程是：(1) 用 RDKit 把任意 SMILES/InChI 规范化为 canonical SMILES 和 InChI/InChIKey，并做去盐和 Sanitize；(2) 用 PubChem REST PUG 把 InChIKey/SMILES 反查 CID；(3) 用 CID 或 InChIKey 到 KEGG/CHEBI/BKMS-react 做交叉匹配；(4) 对仍命中不上的，做互变异构/盐形式归一化后重试。关键风险点有四类：盐形式（游离酸 vs 钠盐被当不同化合物）、立体缺失（库 A 给了立体而库 B 没给）、互变异构（酮-烯醇、内酰胺-内酰亚胺）、命名歧义。InChIKey 连接层匹配能解决大部分"同物异名"，但要警惕"异物同名"和立体敏感的活性差异，所以最终用途对立体敏感时一定要回到完整 InChI 或 canonical SMILES 二次校验。
- *简单流程图：*

```text
任意标识符(SMILES/InChI/CID/名称) -> RDKit 规范化(canonical SMILES + InChIKey) -> InChIKey 连接层做跨库主键 -> PubChem 反查 CID -> KEGG/CHEBI/BKMS-react 交叉匹配 -> 未命中则去盐/互变异构归一化重试 -> 一致性化合物表
```

- *用途：* 跨库化合物匹配、去重、盐/立体/互变异构归一化，是化合物-酶-微生物关联分析的前置数据清洗。
- *官方地址：* #link("https://www.rdkit.org")[RDKit] | #link("https://pubchemdocs.ncbi.nlm.nih.gov/pug-rest")[PubChem PUG-REST] | #link("https://bioconductor.org/packages/KEGGREST/")[KEGGREST] | #link("https://www.inchi-trust.org")[InChI 标准]
- *Linux 常用命令：*

```python
from rdkit import Chem
from rdkit.Chem import SaltRemover
import requests

# 1) 任意输入规范化为 canonical SMILES + InChIKey（连接层用于跨库匹配）
def standardize(smi):
    mol = Chem.MolFromSmiles(smi)
    if mol is None:
        return None
    mol = SaltRemover.SaltRemover().StripMol(mol)   # 去盐，避免游离酸 vs 钠盐误判
    Chem.SanitizeMol(mol)
    return Chem.MolToSmiles(mol), Chem.MolToInchiKey(mol)

can, ikey = standardize("CC(=O)Oc1ccccc1C(=O)O")    # 阿司匹林
print("canonical SMILES:", can)
print("InChIKey:", ikey, "| 连接层:", ikey[:14])

# 2) 用 InChIKey 反查 PubChem CID
cid = requests.get(
    f"https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/inchikey/{ikey}/cids/TXT",
    timeout=30).text.strip()
print("PubChem CID:", cid)

# 3) 用 KEGG C number <-> PubChem CID 双向校验
import urllib.request
print(urllib.request.urlopen("https://rest.kegg.jp/conv/cid/c:C00022").read().decode())
```

```bash
# 命令行：InChIKey -> CID 反查（批量匹配的核心动作）
curl -s "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/inchikey/RYXOBKVOIHTHPG-UHFFFAOYSA-N/cids/TXT"

# KEGG REST：PubChem CID <-> KEGG C number 双向映射
curl -s "https://rest.kegg.jp/conv/cid/c:C00022"
curl -s "https://rest.kegg.jp/conv/cid/pubchem:5793"
```

```r
# R 端：KEGGREST 取 KEGG compound 的 PubChem/CHEBI 交叉 ID
library(KEGGREST)
ent <- keggGet("cpd:C00022")[[1]]
ent$DBLINKS          # 含 PubChem CID、CHEBI 等交叉 ID
```
=== 5. 队列元数据与益生菌数据库：curatedMetagenomicData / Probio / BacDive / ncib-genome-download

- *为什么常用：* 大队列分析需要标准化元数据，益生菌研究需要菌株清单和基因组获取工具。
- *底层原理解读：* `curatedMetagenomicData` 是一个 R 包，直接提供全球各地数万例标准化的、带完整临床元信息的宏基因组相对丰度表，省去了上游巨量的算力消耗，非常适合 meta-analysis。`Probio`、`Integrated Probiotic DataBase`、`AEProbio`、`Chr. Hansen`、`Optibac` 提供市售益生菌菌株清单。`DSMZ BacDive` 是细菌多样性数据库，可获取菌株基础信息和序列来源。`ncbi-genome-download` 则是批量从 NCBI 拉取基因组的命令行工具，常用于构建益生菌参考集。
- *简单流程图：*

```text
curatedMetagenomicData -> 标准化丰度表 + 临床元数据 -> meta-analysis
益生菌数据库 -> 菌株清单 -> ncbi-genome-download -> 益生菌参考基因组集
```

- *用途：* 大队列元数据获取、meta-analysis、益生菌菌株清单与参考基因组收集。
- *官方地址：* #link("https://github.com/waldronlab/curatedMetagenomicData")[curatedMetagenomicData] | #link("https://bacdive.dsmz.de")[BacDive] | #link("https://github.com/kblin/ncbi-genome-download")[ncbi-genome-download]
- *Linux 常用命令：*

```bash
# 批量下载益生菌基因组
ncbi-genome-download bacteria --section refseq \
  --genera "Lactobacillus Bifidobacterium" \
  --formats fasta,gff -o probio_genomes -p 8
```

```r
library(curatedMetagenomicData)
combined <- curatedMetagenomicData("*", dryrun = FALSE, counts = TRUE)
```

=== 6. 模块汇总表

#tablem[
  | 工具或数据库 | 分类 | 主要用途 |
  | :--- | :--- | :--- |
  | NutriChem 2.0 | 天然产物/食物 | 食物-植物营养素关联矩阵 |
  | LOTUS / NPASS / KNApSAcK | 天然产物库 | 植物来源化合物筛选 |
  | SuperNatural 3.0 | 天然产物库 | 二级 InChI/SMILES 查询 |
  | InflamNat | 天然产物活性 | 抗炎化合物筛选 |
  | PubChem | 通用化合物库 | CID 关联与 taxonomy 校验 |
  | KEGG | 酶/反应/通路 | EC-反应关联与代谢分类 |
  | BKMS-react | 整合反应库 | 多库 InChI 关联 |
  | IntEnz / EzCatDB / M-CSA / SFLD / EAWAG / Transformer | 酶反应/催化 | 化合物-酶-催化机制 |
  | HMDB | 人类代谢组 | 代谢物与酶关联 |
  | BRENDA | 酶学数据库 | 酶功能与动力学 |
  | RDKit | 化学信息学 | 结构转换、功能基团、描述符 |
  | KEGGREST / XML / rvest | R 数据获取 | API 查询与网页抓取 |
  | 化合物 ID 一致性处理 | 标识符标准化 | InChIKey 连接层 + PubChem/KEGG 交叉匹配 |
  | curatedMetagenomicData | 队列元数据 | 标准化大队列丰度+临床信息 |
  | BacDive | 细菌数据库 | 菌株基础信息 |
  | ncbi-genome-download | 基因组下载 | 批量获取参考基因组 |
  | Probio / AEProbio / Chr. Hansen / Optibac | 益生菌清单 | 市售益生菌菌株汇总 |
]

#line()

== 十、工具选择建议

如果只想先搭一个稳妥的微生物组分析底盘，可以按下面这个顺序搭配：

+ *16S 项目：* `QIIME 2 + DADA2 + SILVA/GTDB + vegan + ANCOM-BC2`
+ *shotgun 物种和功能：* `fastp + KneadData + Kraken2/Bracken 或 MetaPhlAn4 + HUMAnN3`
+ *MAG 项目：* `fastp + MEGAHIT/metaSPAdes + SemiBin2/metaWRAP + CheckM2 + dRep + GTDB-Tk + Bakta/eggNOG-mapper`
+ *专题功能：* 在通用注释后追加 `dbCAN3`、`antiSMASH`、`RGI`、`AMRFinderPlus`；生态性状与生活史特征见第六章（microtrait / FAPROTAX / Tax4Fun2 / PICRUSt2 等）
+ *高级方向：* 长读长上 `metaFlye/Unicycler`，病毒上 `VirSorter2 + geNomad + CheckV`
+ *食物-代谢-健康延伸：* `NutriChem/LOTUS + KEGG + RDKit + curatedMetagenomicData`

这套组合的逻辑是：先解决数据质量，再解决"是谁"，再解决"能做什么"，最后处理统计、建模、专题功能和跨组学关联。不要一开始就堆过多冷门工具，否则流程复杂度会远大于收益。

#line()

== 十一、Zhang et al. 2026 文献工具与数据库对照表

下面这部分把原始 `.txt` 的文献表格压缩整理成可检索的表格，便于把具体文献和上面的通用工具模块连起来看。

=== 1. 宏基因组分析流程

#tablem[
  | 工具 | 版本 | 方法部分出现位置 | 结果部分出现位置 | 功能用途 | 在文献中的作用 |
  | :--- | :--- | :--- | :--- | :--- | :--- |
  | Sunbeam | v2.1 | Shotgun metagenomics data processing | - | 宏基因组原始数据质控流程 | 去接头、去低质量区域、去人源 DNA 污染 |
  | BWA | - | Shotgun metagenomics data processing | - | 短序列比对工具 | 将 reads 比对到 GRCh38 去除宿主污染 |
  | MetaPhlAn3 | - | Shotgun metagenomics data processing | Fig. 1a; Extended Data Fig. 1a | 标记基因物种注释 | 生成物种相对丰度表 |
  | HUMAnN3 | - | Shotgun metagenomics data processing; Functional profiling | Fig. 1a; Fig. 3; Fig. 5f,g | 功能注释流程 | 生成 EC/通路丰度并支持 species-stratified 结果 |
  | ChocoPhlAn3 | - | Comparison between genomic-based vs HUMAnN3-based results | Extended Data Fig. 1b | HUMAnN3 参考泛基因组库 | 用于评估功能注释覆盖度 |
]

=== 2. MAG 构建与注释

#tablem[
  | 工具 | 方法部分出现位置 | 功能用途 | 在文献中的作用 |
  | :--- | :--- | :--- | :--- |
  | metaWRAP | MAG construction and annotation | 组装与分箱整合流程 | 调用 metaSPAdes、MetaBAT2、MaxBin2、CONCOCT 并做提纯 |
  | metaSPAdes | MAG construction and annotation | 宏基因组组装 | 从质控 reads 构建 contigs |
  | MetaBAT2 | MAG construction and annotation | 基于序列组成和丰度分箱 | 三种分箱器之一 |
  | MaxBin2 | MAG construction and annotation | 基于 marker 和覆盖度分箱 | 三种分箱器之一 |
  | CONCOCT | MAG construction and annotation | k-mer + 覆盖度聚类分箱 | 三种分箱器之一 |
  | dRep | MAG construction and annotation | 去冗余 | 99% ANI 聚成菌株级非冗余 MAG |
  | GTDB-Tk | MAG construction and annotation | 分类注释 | 对去冗余 MAG 做现代分类学标注 |
  | Prokka | MAG construction and annotation | 快速注释 | 生成 GFF/TSV 并支持后续功能分析 |
  | eggNOG-mapper | MAG construction and annotation | 功能注释 | 生成 MAG 的 EC profile |
]

=== 3. 益生菌、数据库与化学信息学

#tablem[
  | 工具或数据库 | 类型 | 主要用途 |
  | :--- | :--- | :--- |
  | ncbi-genome-download | 下载工具 | 批量获取益生菌基因组 |
  | Probio / Integrated Probiotic DataBase / AEProbio | 益生菌数据库 | 汇总市售益生菌菌株信息 |
  | Chr. Hansen / Optibac Probiotics | 商业来源 | 补充菌株和产品信息 |
  | PanPhlAn | 泛基因组工具 | 体外实验菌株的基因存在缺失判断 |
  | BLAST | 比对工具 | 验证特定酶或基因存在与否 |
  | DSMZ BacDive | 细菌数据库 | 获取菌株基础信息和序列来源 |
  | NutriChem 2.0 | 食物-化合物库 | 连接植物营养素与食物来源 |
  | KEGG / PubChem / HMDB / BKMS-react / IntEnz / EAWAG / EzCatDB / M-CSA / SFLD / Transformer | 反应与代谢数据库 | 构建植物营养素-酶关系 |
  | LOTUS / NPASS / KNApSAcK / SuperNatural 3.0 / InflamNat | 天然产物库 | 化合物来源、天然产物和抗炎活性筛选 |
  | curatedMetagenomicData | R 数据资源 | 获取大队列样本元数据 |
  | RDKit | 化学信息学工具 | SMILES/InChI 转换和功能基团识别 |
  | KEGGREST / XML / rvest | R 包 | API 查询、XML 解析和网页抓取 |
]

=== 4. 统计与机器学习

#tablem[
  | 工具 | 主要用途 | 在文献中的典型角色 |
  | :--- | :--- | :--- |
  | vegan | 多样性和群落结构统计 | Shannon、Bray-Curtis、PERMANOVA、Procrustes、dbRDA |
  | robCompositions / compositions | 组合数据分析 | Aitchison/CLR 相关分析 |
  | labdsv | 指标种分析 | signature species |
  | rstatix / ppcor | 相关和偏相关 | 微生物与 BMI、酶比例等关系 |
  | metagenomeSeq | 差异丰度 | 检测健康与疾病间显著差异 |
  | FEAST | 来源追踪 | 分析移民或暴露后的微生物来源 |
  | lmerTest | 线性混合模型 | 小鼠时间序列和重复测量 |
  | Benjamini-Hochberg | 多重校正 | 控制 FDR |
  | caret / Boruta / pROC / fastshap | 机器学习 | 随机森林、特征选择、AUC、SHAP 解释 |
]

#line()

== 十二、最后的使用建议

真正做项目时，不要把"知道很多工具名字"误当成"流程已经合理"。更实用的原则是：

- 先确认研究问题，再选工具，不要反过来。
- 同一层任务最多保留一到两条主流程，避免结果互相打架。
- 常规项目优先成熟工具；新工具用于补短板，不要整条流程都压在最新软件上。
- 微生物组统计一定要考虑组成型、零膨胀、批次和协变量。
- MAG、病毒和机器学习分析都很容易"看起来很高级"，但最怕前处理和验证不扎实。
- 化学信息学和关联数据库越来越多出现在微生物-食物-健康研究里，但它们对化合物标识符一致性要求很高，先用 RDKit/InChI 把标识符统一是关键。

如果只保留一句总原则，那就是：*先把数据质量和流程可复现性打牢，再去追求更细的分类、更全的功能和更复杂的模型。*
