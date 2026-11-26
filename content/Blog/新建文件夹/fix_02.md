# **一、总体评价：教程内容丰富，但目前还不能作为一份可直接照着执行的标准流程**

我完整检查了 `index.typ` 的 1,406 行内容。先说结论：**这份教程的优点是覆盖面广，已经涉及从原始数据处理到群落生态分析的许多常用方法；但目前存在“主流程、可选分支和拓展分析混排”的问题，而且有若干命令、参数解释和统计学概念需要修正。**

最需要优先处理的不是增加更多分析方法，而是先把教程拆成三个层次：

1. **标准分析主线**：原始数据准备 → 导入与质量评估 → 去引物和质量过滤 → ASV 推断 → 特征表与分类注释 → 多样性分析 → 差异分析。

2. **可选分析分支**：OTU 聚类、替代去噪算法、功能预测、来源追踪等。

3. **进阶生态分析**：RDA/CCA、NMDS、网络分析、机器学习等。

目前的章节顺序会让初学者误以为序列拼接、嵌合体去除、短序列过滤、OTU 统计是所有 16S 数据都必须独立执行的步骤。实际上，DADA2 主线中，质量过滤、去噪、双端拼接和嵌合体去除已经整合在 `dada2 denoise-paired` 中；OTU 聚类则是另一种可选分析策略，不应该和 ASV 主流程混成一条连续操作链。

另一个影响较大的问题是：**有些章节给出的命令本身可能可以运行，但其输入文件、前文步骤或统计解释并不匹配。** 这类问题比单纯的文字错误更值得优先修正。

我重新逐段核对了原文件中的命令和代码。下面继续给出具体审查意见，重点放在**会导致命令报错、分析对象错误、统计结论不可靠，以及目录结构需要调整**的地方。

先更正我前面的一处判断：我之前说 VSEARCH 的 `uchime-denovo` 命令缺少 `--i-sequences`，重新核对原文件后发现，这个判断不正确。你的第 3.1 节已经写了 `--i-sequences rep-seqs.qza`，输入参数是完整的。另外，使用 `chimeras.qza` 作为 `--m-metadata-file`，配合 `--p-exclude-ids` 排除嵌合体特征的思路也是成立的。QIIME 2 官方文档明确支持将序列 Artifact 作为 Metadata，用于筛除嵌合体序列。

docs.qiime2.org

# **二、原教程中需要修改的具体问题**

我把问题分成三个等级：

* **P0：必须修改**——命令错误、数据方向错误、方法概念错误，可能直接导致分析失败或结果错误。

* **P1：重要修改**——流程逻辑不严谨、方法学描述不准确，容易让读者误用。

* **P2：建议完善**——内容本身不一定错误，但不够系统，作为教程还缺少必要信息。

## **2.1 P0：必须修改的问题**

### **问题1：Cutadapt 的输出没有接入 DADA2，属于上下游文件不一致**

P0 必须修改

你在第 1.2 节执行：

```
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences demux.qza \
  --p-front-f CCTACGGGNGGCWGCAG \
  --p-front-r GACTACHVGGGTATCTAATCC \
  --p-discard-untrimmed \
  --o-trimmed-sequences demux-trimmed.qza
```

这一节明确写明去引物后，使用 `demux-trimmed.qza` 进入下一节。

但是第 2 节的 DADA2 命令仍然使用：

```
--i-demultiplexed-seqs demux.qza
```

这样 Cutadapt 的结果实际上没有进入 DADA2。

**修改方法：**

如果选择 Cutadapt 去引物，就应该改为：

```
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux-trimmed.qza \
  --p-trim-left-f 0 \
  --p-trim-left-r 0 \
  --p-trunc-len-f 250 \
  --p-trunc-len-r 230 \
  --p-max-ee-f 2 \
  --p-max-ee-r 2 \
  --p-trunc-q 2 \
  --p-n-threads 8 \
  --o-representative-sequences rep-seqs.qza \
  --o-table table-asv.qza \
  --o-denoising-stats denoising-stats.qza
```

这里的截断长度只是演示，不能直接作为所有数据的推荐值。

如果不使用 Cutadapt，而是直接使用 DADA2，则应该根据实际引物长度设置 `--p-trim-left-f/r`。

这两种操作不能重复执行，否则可能把引物区域重复切除。

### **问题2：单端数据的 Manifest 格式写错**

P0 必须修改

第 0.2 节中写道：

> 单端数据则用三列 manifest（SampleID, absolute-filepath, direction）。

但后面的导入命令使用：

```
--input-format SingleEndFastqManifestPhred33V2
```

这两者不匹配。

QIIME 2 的 V2 单端 Manifest 只需要两列：

```
sample-id    absolute-filepath
S1           /data/S1.fastq.gz
S2           /data/S2.fastq.gz
```

而你写的三列形式对应的是旧版 Manifest 格式，需要使用非 V2 的导入格式。QIIME 2 官方导入文档对单端和双端 V2 Manifest 的列结构有明确说明。

QIIME 2 2024.10.1 documentation

建议直接把教程统一为 V2 格式：

**双端数据：**

```
sample-id    forward-absolute-filepath    reverse-absolute-filepath
S1           /data/S1_R1.fastq.gz          /data/S1_R2.fastq.gz
S2           /data/S2_R1.fastq.gz          /data/S2_R2.fastq.gz
```

**单端数据：**

```
sample-id    absolute-filepath
S1           /data/S1.fastq.gz
S2           /data/S2.fastq.gz
```

此外，建议在第 0.2 节增加单端和双端分别对应的 DADA2 分析流程，因为你的教程目前主要只有双端数据的 `denoise-paired`，缺少完整的单端分析主线。

### **问题3：ANCOM-BC 命令的输出类型错误**

P0 必须修改

第 12.1 节的命令：

```
qiime composition ancombc \
  --i-table table-l6.qza \
  --m-metadata-file metadata.tsv \
  --p-formula "Group" \
  --o-visualization ancombc-l6.qzv
```

这里的 `--o-visualization` 不正确。

`qiime composition ancombc` 输出的是差异丰度结果 Artifact，而不是直接输出 Visualization。其输出类型为 `FeatureData[DifferentialAbundance]`，应使用 `--o-differentials`。

docs.qiime2.org+1

建议修改为：

```
qiime composition ancombc \
  --i-table table-l6.qza \
  --m-metadata-file metadata.tsv \
  --p-formula 'Group' \
  --o-differentials ancombc-l6.qza
```

随后再对结果进行可视化或表格汇总：

```
qiime composition tabulate \
  --i-data ancombc-l6.qza \
  --o-visualization ancombc-l6.qzv
```

如果当前安装的 QIIME 2 2024.2 插件提供 `da-barplot`，也可以进一步绘制差异结果图。具体以该环境下的：

```
qiime composition --help
qiime composition ancombc --help
```

为准。

同时，你需要把 ANCOM 和 ANCOM-BC 的原理分开介绍：

* **ANCOM**：以特征间的两两对数比值为基础，识别差异类群。

* **ANCOM-BC**：通过偏差校正模型估计差异丰度，并提供效应量等结果。

不能把两种方法统称为同一个分析过程。

### **问题4：IQ-TREE 建树命令的线程参数不匹配**

P0 必须修改

你原文：

```
qiime phylogeny iqtree \
  --i-alignment aligned-rep-seqs.qza \
  --p-threads 8 \
  --o-tree iqtree-tree.qza
```

这里的 `--p-threads` 存在参数名称问题。

QIIME 2 的 IQ-TREE 接口参数是 `n_cores`，对应 CLI 参数应使用 `--p-n-cores`。当前官方插件文档中也将其定义为用于并行计算的核心数。

docs.qiime2.org

建议按以下形式修改，并在 QIIME 2 2024.2 环境中用 `--help` 再确认：

```
qiime phylogeny iqtree \
  --i-alignment aligned-rep-seqs.qza \
  --p-n-cores 8 \
  --o-tree iqtree-tree.qza
```

另外，IQ-TREE 建树并不是所有 16S 分析的必要步骤。你已经有 `align-to-tree-mafft-fasttree`，建议把 FastTree 作为常规主线，把 IQ-TREE 放到进阶建树分支。

### **问题5：LEfSe 的&#x20;**`-c Group`**&#x20;参数使用错误**

P0 必须修改

你原文：

```
lefse_format_input.py otu_table.txt otu.in -c Group
```

LEfSe 的 `-c` 参数用于指定分类变量所在的**列编号**，不是变量名称。官方脚本中该参数的数据类型是整数。

GitHub

因此，不能简单地把 `Group` 作为参数传入。

如果输入文件已经按照 LEfSe 所要求的格式整理，并且分类变量是其规定的第 1 个元数据字段，才可以类似这样写：

```
lefse_format_input.py otu_table.txt otu.in -c 1 -f r
run_lefse.py otu.in otu.res -l 4.0
plot_res.py otu.res lefse.png
```

但这不是说把 QIIME 2 导出的普通特征表直接输入就一定可以。LEfSe 输入数据需要按照其格式组织样本分组信息、特征丰度和可选的 subclass、subject 等信息。

建议单独增加一节：

**LEfSe 输入数据格式整理与运行前检查**

### **问题6：BIOM 导出的矩阵方向与 R 分析代码不一致**

P0 必须修改

这是你整份教程中非常重要的一类错误。

你在附录 C 使用：

```
qiime tools export \
  --input-path table-filtered.qza \
  --output-path export/table

biom convert \
  -i export/table/feature-table.biom \
  -o export/table/feature-table.tsv \
  --to-tsv
```

BIOM 转出的 TSV 默认是：

* 行：Feature / ASV / OTU

* 列：Sample

* 第一列：`#OTU ID`

这与 BIOM 官方提供的 TSV 示例一致。

biom-format.org

但是你后面好几个 R 代码块，都按照“行是样本、列是特征”来操作，导致计算对象错误。

具体问题如下：

| 原文位置             | 当前代码问题                                  | 修改方向                       |
| ---------------- | --------------------------------------- | -------------------------- |
| 7.1 Beta 多样性     | `vegdist(dat)` 计算的是特征之间的距离              | 先转置，计算样本间距离                |
| 9 Rank-Abundance | `dat["S1", ]` 把样本名当作特征行名                | 先转置再提取样本                   |
| 10.2 PCA         | `mat <- mat[colSums(mat)>0,]` 删除零值时方向错误 | 应按特征列过滤                    |
| 10.2 PCA         | `rda(decostand(t(mat), ...))` 再次把矩阵转置错了 | 直接对样本 × 特征矩阵做 Hellinger 变换 |
| 11 UPGMA         | `vegdist(dat)` 计算的是特征间距离                | 使用样本 × 特征矩阵                |
| 13 RDA           | `decostand(t(mat), ...)` 转置方向错误         | 使用样本 × 特征矩阵                |
| 14 NMDS          | `vegdist(dat)` 方向错误                     | 使用样本 × 特征矩阵                |

我建议你不要只修改这几行，而是在附录 C 里建立一个**统一的 R 数据导入与矩阵整理模块**，后面所有 R 章节都调用同一个对象。

建议直接增加以下代码：

```
library(vegan)

# 读取 QIIME 2 导出的 BIOM TSV
# 第一行是 BIOM 注释行，因此 skip = 1
otu <- read.delim(
  "feature-table.tsv",
  row.names = 1,
  skip = 1,
  check.names = FALSE
)

# 原始 BIOM 导出矩阵：行 = 特征，列 = 样本
# 转换为 vegan 常用格式：行 = 样本，列 = 特征
comm <- t(as.matrix(otu))

# 确保为数值矩阵
storage.mode(comm) <- "numeric"

# 去掉全零样本和全零特征
comm <- comm[
  rowSums(comm) > 0,
  colSums(comm) > 0,
  drop = FALSE
]

# 读取样本元数据
meta <- read.delim(
  "metadata.tsv",
  row.names = 1,
  check.names = FALSE,
  comment.char = ""
)

# 严格按照样本矩阵的顺序排列 metadata
meta <- meta[rownames(comm), , drop = FALSE]

# 检查样本顺序是否一致
stopifnot(identical(rownames(comm), rownames(meta)))
```

这里还需要特别提醒：你原来部分代码读取 metadata 时使用了：

```
comment.char = "#"
```

如果 Metadata 的首列标题是 `#SampleID`，这可能导致标题行被作为注释跳过。建议统一使用 `sample-id` 作为首列，R 端读取时使用 `comment.char = ""`。

**以后所有基于 vegan 的分析，都建议使用&#x20;**`comm`**&#x20;这个统一对象，不要反复重新读取并转置特征表。**

### **问题7：Beta 多样性中的 Bray-Curtis 和 Jaccard 代码需要修改**

P0 必须修改

你原文：

```
d_bc <- vegdist(dat, method = "bray")
d_jd <- vegdist(dat, method = "jaccard")
```

除了矩阵方向错误外，第二行还有一个统计学解释问题。

`vegan::vegdist()` 的 Jaccard 默认并不等于纯粹的 presence/absence Jaccard。若需要只根据类群是否存在来计算距离，应明确使用 `binary = TRUE`。vegan 的官方文档对此有明确说明。

GitHub

建议改为：

```
# 相对丰度矩阵：每个样本总和为 1
comm_rel <- decostand(comm, method = "total")

# 基于丰度差异的 Bray-Curtis
d_bc <- vegdist(comm_rel, method = "bray")

# 基于有无关系的 Jaccard
d_jaccard <- vegdist(comm, method = "jaccard", binary = TRUE)
```

另外，你的 Bray-Curtis 公式：

\\\[ BC=\frac{b+c}{2a+b+c} \\]

是基于共有与独有类群数量的二元形式，不应直接作为一般定量丰度版本的公式。

建议教程中使用标准表达式：

\\\[ BC\_{ij}= \frac{\sum\_k |x\_{ik}-x\_{jk}|} {\sum\_k (x\_{ik}+x\_{jk})} \\]

这样才与实际丰度矩阵的计算形式一致。

## **2.2 P1：重要的方法学与逻辑问题**

### **问题8：DADA2 的去噪统计说明少了一列**

你原文写道：

> denoising-stats.qzv 里有 input、filtered、merged、non-chimeric 四个逐级保留的序列数。

建议修改。

DADA2 的统计信息还包括 `denoised` 阶段。建议将其解释为：

| 阶段           | 含义               |
| ------------ | ---------------- |
| input        | 输入的原始序列数         |
| filtered     | 经过质量过滤后保留的序列数    |
| denoised     | 错误模型校正、去噪后保留的序列数 |
| merged       | 双端成功拼接的序列数       |
| non-chimeric | 去除嵌合体后保留的序列数     |

DADA2 的 `denoise-paired` 本身就包含去噪、去冗余、双端拼接和嵌合体过滤，并提供各阶段的序列保留统计。

docs.qiime2.org+1

这也说明你的章节结构应该改变：不要把 DADA2 的拼接和去嵌合体当成必须独立执行的两个主流程步骤。

### **问题9：20% 序列保留率不应该作为统一的停止标准**

你原文第 1.4 节：

> 若多数样本从 input 到 non-chimeric 的保留率低于约 20%，下游所有多样性结论都不可信。

这段建议大幅修改。

问题在于：20% 是你人为设定的经验阈值，并不是 DADA2 或 QIIME 2 通用的质量判定界限。

即使一个样本保留率低于 20%，也不能仅凭这个比例判断结果不可信；反过来，保留率很高，也不能证明数据质量可靠。

建议改为：

> DADA2 去噪完成后，应结合各样本 input、filtered、denoised、merged 和 non-chimeric 阶段的序列保留数量与比例，识别异常样本。若个别样本在过滤或拼接阶段出现明显异常损失，应结合原始质量分布、引物去除情况、目标扩增片段长度以及双端重叠长度进行排查。不能仅依据整体序列保留率设置统一的合格标准。

你还应该增加**按样本展示 DADA2 序列保留率的统计图**，而不只是展示一张总表。

### **问题10：DADA2 的截断参数介绍过于经验化**

你现在写：

> 截在质量开始下滑之前，判据是质量图里中位质量降到 Q30 以下的位置再往前留一点。

这个描述过于绝对。

DADA2 的截断位置并不是必须按照 Q30 硬性确定。应该综合考虑：

* 每个碱基位置的质量分布；

* 预期错误数；

* 截断后剩余序列长度；

* 扩增子插入片段长度；

* 去除引物后正反向 reads 的有效长度；

* 双端拼接所需的最小重叠长度。

例如，QIIME 2 的 `denoise-paired` 文档明确要求截断后正反向 reads 仍需保留至少 12 nt 的重叠，具体还要考虑目标片段长度和真实测序质量。

QIIME 2 2024.10.1 documentation

建议增加一个参数计算公式：

\\\[ L\_{\mathrm{overlap}}= L\_F+L\_R-L\_{\mathrm{amplicon}} \\]

其中：

* \\(L\_F\\)：去除引物和截断后正向 reads 的有效长度；

* \\(L\_R\\)：去除引物和截断后反向 reads 的有效长度；

* \\(L\_{\mathrm{amplicon}}\\)：实际扩增片段长度。

要求结果至少满足所用 DADA2 参数设置的最小重叠长度。

不要在教程中把 `250/230` 这样的截断长度当作普遍适用的标准参数。

### **问题11：把短序列过滤与低丰度特征过滤混为一谈**

第 3.2 节标题叫：

> 短序列与低丰度过滤

但你给出的代码实际上是：

```
qiime feature-table filter-features \
  --i-table table.qza \
  --p-min-frequency 10 \
  --p-min-samples 2 \
  --o-filtered-table table-filtered.qza
```

这段命令不是根据序列长度过滤短序列，而是根据特征的总频数和出现样本数筛选特征。

建议把这一节改为：

**低丰度及低出现率特征过滤**

并增加以下解释：

* `--p-min-frequency`：特征在所有样本中的总丰度阈值；

* `--p-min-samples`：特征至少出现于多少个样本；

* 过滤过严会丢失低丰度但真实存在的微生物；

* 过滤阈值需要结合测序深度、研究问题和污染控制结果确定。

你现在给出的“小样本 5/1、大样本 50/5”的建议太随意，不建议作为固定经验规则。更好的方式是给出示例，并明确需要做阈值敏感性分析。

### **问题12：抽平的介绍存在明显过度概括**

你在第 0.3 节写：

> 样本间测序深度不齐时，直接比较 α 多样性会被深度差异带偏，所以要先抽平再比较。

在第 5.1 节又写：

> 做统计检验前仍要抽平。

这两处都需要改。

**抽平并不是所有下游统计分析的通用前提。**

你应该区分三类情况：

| 分析类型                      | 是否推荐统一抽平                                      |
| ------------------------- | --------------------------------------------- |
| QIIME 2 常规 Alpha 多样性比较    | 常用统一测序深度抽平                                    |
| 使用 UniFrac 等常规 Beta 多样性流程 | QIIME 2 的 core metrics 流程会按 sampling depth 抽平 |
| 差异丰度分析                    | 通常使用未抽平的原始计数表，结合方法自身的归一化或模型处理                 |

`core-metrics-phylogenetic` 会在计算多样性指标前按设置的 sampling depth 对特征表进行抽平。低于该深度的样本会被排除。

docs.qiime2.org+1

因此，**不要把 core metrics 输出的抽平表直接作为 ANCOM-BC、MaAsLin3 等差异分析的默认输入。**

建议在教程中专门增加一节：

**测序深度标准化、抽平与下游分析数据选择**

这对于初学者非常重要。

### **问题13：抽平深度的选择标准不应该写成固定的 90%、5000 或 10000**

你原文建议：

> 选一个能保留 ≥90% 样本的最大深度。

以及：

> 如今建议 ≥5000，能做到 10000 以上更稳。

这些都不适合作为强制标准。

抽平深度取决于样本测序量分布、群落复杂度、分析目标以及可以接受的样本损失比例。

例如，不能为了保留 90% 的样本而把深度设得过低，也不能为了得到 10000 reads 而把大量样本排除。

建议补充：

1. 绘制样本测序深度分布。

2. 计算不同抽平深度下的样本保留数量。

3. 对比不同抽平深度下的 Alpha 和 Beta 分析结果。

4. 报告最终抽平深度以及被剔除的样本数量。

5. 对关键结论进行不同深度下的敏感性分析。

### **问题14：Alpha 多样性指标介绍不够准确**

你关于 Good's coverage 的描述：

> 测到的物种占真实物种的比例。

不够准确。

Good's coverage 不是直接测量“已经发现的物种数 / 真实物种数”。它更接近基于单次出现个体比例估计样本覆盖程度的指标，常见估计形式为：

\\\[ C=1-\frac{F\_1}{N} \\]

其中 \\(F\_1\\) 是只出现一次的观测计数，\\(N\\) 是总观测计数。

此外，`core-metrics-phylogenetic` 不会自动计算你列出的全部 Alpha 指标。你列出的 Chao1、Simpson、Margalef、Gleason 等，应当分别说明计算途径。

建议增加：

**常用 Alpha 指数的具体计算命令及对应输出文件**

例如：

```
qiime diversity alpha \
  --i-table table-clean.qza \
  --p-metric chao1 \
  --o-alpha-diversity chao1.qza
```

注意：不同 QIIME 2 版本与指标实现可能存在差异，命令要以当前环境 `qiime diversity alpha --help` 为准。

### **问题15：分类注释中对 SILVA 物种水平的使用需要更谨慎**

你当前写道：

> SILVA 138 细菌/古菌 16S 首选。

这个定位可以保留，但建议增加两点：

第一，数据库版本必须与 QIIME 2 版本匹配。QIIME 2 2024.2 对应的分类器需要注意其 scikit-learn 兼容性，官方资源页面将 2021.4–2024.2 分类器单独列出，并标明相关分类器的 scikit-learn 版本。

library.qiime2.org+1

第二，SILVA 的部分物种水平分类可能不可靠，特别是仅使用短扩增区时。官方分类器资源页面也专门给出了此类提醒。

library.qiime2.org

建议将：

> 得到界门纲目科属种分类。

改成：

> 依据参考数据库对 ASV 代表序列进行分类注释，获得不同分类层级的预测结果。实际能够达到的可靠分类层级取决于扩增区、参考数据库、参考序列覆盖程度及分类器置信度。对于无法可靠区分的近缘物种，应保留在属或更高分类层级，不应强行解释到种水平。

### **问题16：BLAST 的&#x20;**`--p-maxaccepts 3`**&#x20;被解释为取相似度最高的 3 条序列，不准确**

你写：

> 取前 N 条比对的一致性投票。

容易让人认为它取的是相似度排名前 3 的匹配序列。

但 QIIME 2 的 `classify-consensus-blast` 中，`maxaccepts` 是从满足相似度阈值的结果中选取最先接受的 N 条，并不保证它们就是全库中相似度最高的 N 条。

如果希望选择真正的 top N 匹配，可以考虑 `classify-consensus-vsearch`。

docs.qiime2.org+1

建议在教程中加入一个 BLAST 和 VSEARCH 分类注释方法对照表，明确两者在比对和候选序列选择方面的区别。

### **问题17：建树章节的位置不合理，且没有处理特征表与树的对应关系**

你第 8 节自己已经说明：

> 进化树必须在做多样性之前建好。

但目录仍然将系统进化树放在 Alpha、Beta 多样性之后。

这属于明显的目录逻辑问题。

建议把系统发育树放在分类注释之后、群落组成与多样性分析之前。

另外还要补充：

* 建树所用的代表序列应与最终特征表中的特征 ID 对应；

* 进入 Faith PD 和 UniFrac 前，必须保证特征表中的所有特征都存在于树中；

* 如果进行了特征过滤，应重新检查特征表与树尖端 ID 是否匹配。

QIIME 2 对 `core-metrics-phylogenetic` 的要求是：特征表中的每个 feature ID 都必须存在于系统发育树中。树中可以存在额外的 tip，但不能缺少特征表所包含的特征。

docs.qiime2.org

### **问题18：物种组成分析没有沿用宿主污染过滤后的特征表**

这是文件命名和流程衔接的问题。

第 4.3 节得到：

```
--o-filtered-table table-no-host.qza
```

但第 5 节又重新使用：

```
--i-table table-filtered.qza
```

也就是说，虽然你已经执行了线粒体、叶绿体过滤，但后面绘制群落组成柱状图时，又使用了过滤前的表。

这会使前后分析对象不一致。

建议建立统一的特征表命名体系：

| 文件名                  | 具体含义                     |
| -------------------- | ------------------------ |
| `table-asv.qza`      | DADA2 生成的原始 ASV 特征表      |
| `table-filtered.qza` | 低丰度、低出现率过滤后的特征表          |
| `table-clean.qza`    | 排除线粒体、叶绿体以及必要污染特征后的最终特征表 |
| `rep-seqs.qza`       | DADA2 输出的代表序列            |
| `taxonomy.qza`       | 对应代表序列的分类注释              |
| `rooted-tree.qza`    | 与最终特征表兼容的系统发育树           |

第 5 节以后，群落组成、多样性和差异分析应当明确各自使用哪个版本的特征表，不能混着使用。

### **问题19：PICRUSt2 的原理描述需要重写**

你原文：

> 建议用 Greengenes 注释，便于与 PICRUSt 参考树对齐。

这个说法不准确，应该删改。

PICRUSt2 的算法包括将研究样本的 ASV 序列放置到其自身的参考系统发育树中，再基于参考基因组和基因家族进行功能预测，不要求先用 Greengenes 完成外部分类注释。

PMC+1

建议改成：

> PICRUSt2 基于研究样本的代表序列进行系统发育放置，并结合参考基因组信息预测微生物基因家族及潜在代谢通路。其功能预测并非直接测量微生物基因或代谢产物，而是基于参考基因组和系统发育信息进行的推断。

还应该增加：

* NSTI 的含义及其解释；

* NSTI 的样本分布如何展示；

* 功能预测结果如何进行差异分析；

* 为什么不能将 PICRUSt2 结果等同于宏基因组测序得到的真实功能基因丰度。

## **2.3 其他 R 代码也建议系统性修正**

下面这些代码可以直接作为替换参考。

**（1）Rank-Abundance**

```
# comm：行 = 样本，列 = 特征
comm_rel <- decostand(comm, method = "total")

x <- sort(comm_rel["S1", ], decreasing = TRUE)

df <- data.frame(
  rank = seq_along(x),
  abundance = x
)

ggplot(df, aes(rank, abundance)) +
  geom_point(size = 1.5) +
  scale_y_log10() +
  labs(
    x = "Feature rank",
    y = "Relative abundance"
  ) +
  theme_bw()
```

图中建议把原来的“物种等级”改成“特征排序等级”或“ASV/OTU 排序等级”。因为你的图并不保证每个 feature 都能准确鉴定到物种。

**（2）PCA**

```
library(vegan)

# 行 = 样本，列 = 特征
comm <- comm[, colSums(comm) > 0, drop = FALSE]

# Hellinger transformation
comm_hel <- decostand(comm, method = "hellinger")

# PCA
pca <- rda(comm_hel)

sc <- scores(
  pca,
  display = "sites",
  choices = 1:2
)
```

这里不要将 `comm` 再次转置。

另外，不建议将 `PCA 与 PCoA 结果一致`作为支持研究结果的必要条件。它们的输入数据和数学依据不同，结论不一致并不必然意味着分析有问题。

**（3）UPGMA**

```
comm_rel <- decostand(comm, method = "total")

d <- vegdist(
  comm_rel,
  method = "bray"
)

hc <- hclust(
  d,
  method = "average"
)

plot(
  as.dendrogram(hc),
  horiz = TRUE,
  hang = -1
)
```

**（4）NMDS**

你原文中还有一个直接的代码问题：使用了 `meta$Group`，但是这个代码块并没有读入 `meta`。

修正示例：

```
comm_rel <- decostand(comm, method = "total")

nmds <- metaMDS(
  comm_rel,
  distance = "bray",
  k = 2,
  trymax = 100
)

nmds$stress
stressplot(nmds)

plot(nmds, type = "n")

points(
  nmds,
  display = "sites",
  pch = 21,
  bg = as.integer(factor(meta$Group))
)

ordiellipse(
  nmds,
  groups = meta$Group,
  kind = "se",
  conf = 0.95
)
```

`metaMDS()` 的输入可以是 community matrix 或已经计算好的距离对象；使用 community matrix 时，样本应当是行、特征应当是列。

metaMDS • vegan

**（5）RDA**

```
# 确保环境变量按照样本顺序排列
env <- env[rownames(comm), , drop = FALSE]

# RDA
rda_mod <- rda(
  decostand(comm, method = "hellinger") ~ Group + pH + Age,
  data = env
)

# 整体检验
anova(rda_mod, permutations = 999)

# 逐项检验
anova(
  rda_mod,
  by = "term",
  permutations = 999
)

# 边际效应检验
anova(
  rda_mod,
  by = "margin",
  permutations = 999
)

# 共线性
vif.cca(rda_mod)

# 调整后的解释率
RsquareAdj(rda_mod)
```

你原来只介绍了 `by = "term"`。建议补充 `by = "margin"`，并解释两者区别：前者是顺序检验，受变量进入模型的顺序影响；后者是考虑其他模型项之后的边际检验。

**（6）MaAsLin3**

你给出的代码中：

```
maaslin3(
  input_data = feat,
  input_metadata = meta,
  output = "maaslin3_out",
  formula = "~ Group + age + BMI"
)
```

是示意写法，但教程没有说明 `feat` 和 `meta` 从哪里来，也没有建立两者的样本对应关系。

建议补充输入格式示意。MaAsLin3 通常使用行表示样本、列表示特征的丰度矩阵，以及行表示样本、列表示变量的元数据矩阵。

bioconductor.org

# **三、目前的目录结构为什么不够合理？**

我认为你现在的 17 个一级标题是这份教程最大的结构问题之一。

主要存在四个问题。

**第一，核心分析流程和统计拓展方法没有区分。**

例如，第 6 节 Alpha、第 7 节 Beta、第 8 节系统树、第 9 节 Rank-Abundance、第 10 节 PCoA/PCA、第 11 节 UPGMA、第 13 节 RDA/CCA、第 14 节 NMDS。

这些内容不应该全部作为同级、相互独立的一级标题。

其中：

* 系统发育树属于多样性分析的基础准备；

* PCoA 属于 Beta 多样性分析的常规排序结果；

* PCA、NMDS 属于其他排序方法；

* UPGMA 属于基于距离矩阵的聚类；

* Rank-Abundance 属于群落结构描述；

* RDA/CCA 属于环境因子约束排序。

**第二，将 ASV 和 OTU 的分析路径混在了一起。**

DADA2 是 ASV 推断主线；VSEARCH 聚类属于 OTU 相关分析路径。你现在的写法容易让读者将 ASV 推断、OTU 聚类、闭合参考聚类当成连续必经步骤。

**第三，分析顺序存在矛盾。**

系统发育树在 Alpha/Beta 分析之后介绍，但是又要求实际提前执行。

**第四，缺少进入正式分析之前的数据检查。**

例如，实验设计、测序批次、阴性对照、阳性对照、样本编号检查、元数据完整性、原始数据完整性等，没有形成独立模块。

因此，我建议把目录调整为下面这套结构。

# **四、建议采用的新目录结构**

推荐目录

下面这套结构可以作为你后续正式修改 Typst 教程的基础版本。

我把它分成“基础数据处理—核心群落分析—统计拓展—结果与复现”四个逻辑层次。

## **第一部分：16S rRNA 扩增子数据准备与特征表构建**

**一级标题 0：教程说明与分析流程总览**

* 0.1 教程适用范围及分析目标

* 0.2 QIIME 2 2024.2 软件环境与依赖工具

* 0.3 16S rRNA 基因扩增子分析的基本概念

* 0.4 ASV 与 OTU 的概念及分析策略选择

* 0.5 QIIME 2 的 Artifact、Visualization 与数据类型

* 0.6 16S rRNA 扩增子分析总体流程

**一级标题 1：实验设计、样本元数据与原始测序数据准备**

* 1.1 16S rRNA 扩增子测序实验设计

* 1.2 样本元数据文件的整理与检查

* 1.3 双端测序与单端测序文件的命名规则

* 1.4 Manifest 文件的创建与格式规范

* 1.5 阴性对照、阳性对照与 Mock Community

* 1.6 原始 FASTQ 文件完整性检查与 MD5 校验

**一级标题 2：数据导入与原始测序质量评估**

* 2.1 双端测序数据导入 QIIME 2

* 2.2 单端测序数据导入 QIIME 2

* 2.3 导入数据的类型与完整性检查

* 2.4 使用 demux summarize 评估测序质量

* 2.5 使用 FastQC 与 MultiQC 进行辅助质量评估

* 2.6 测序深度分布与异常样本识别

**一级标题 3：原始序列预处理与质量控制**

* 3.1 测序接头与扩增引物识别

* 3.2 使用 Cutadapt 去除扩增引物

* 3.3 序列质量过滤与截断原则

* 3.4 宿主来源序列去除（可选）

* 3.5 测序公司预处理数据的评估与使用

* 3.6 预处理结果检查与参数优化

**一级标题 4：ASV 推断与特征表构建**

* 4.1 DADA2 去噪原理与基本流程

* 4.2 双端测序数据的 DADA2 去噪

* 4.3 单端测序数据的 DADA2 去噪

* 4.4 DADA2 参数选择与双端序列拼接

* 4.5 DADA2 嵌合体识别与去除

* 4.6 DADA2 去噪统计与序列保留率评估

* 4.7 代表序列与 ASV 特征表的生成

* 4.8 其他去噪方案：Deblur（可选）

**一级标题 5：特征表质量控制与过滤**

* 5.1 ASV 特征表基本统计

* 5.2 测序量异常样本识别与过滤

* 5.3 低丰度及低出现率特征过滤

* 5.4 线粒体与叶绿体序列过滤

* 5.5 基于阴性对照的污染特征识别

* 5.6 特征表与代表序列的一致性检查

* 5.7 最终分析特征表的确定

**一级标题 6：物种分类注释与数据库选择**

* 6.1 16S rRNA 参考数据库及版本

* 6.2 SILVA 数据库分类注释

* 6.3 Greengenes2 与 GTDB 数据库

* 6.4 预训练 Naive Bayes 分类器

* 6.5 根据扩增区域提取参考序列并训练分类器

* 6.6 classify-sklearn 分类注释

* 6.7 classify-consensus-vsearch 与 BLAST 注释

* 6.8 分类注释结果统计与可视化

* 6.9 分类注释的分辨率及局限性

**一级标题 7：系统发育树构建**

* 7.1 代表序列多序列比对

* 7.2 比对结果屏蔽与处理

* 7.3 FastTree 系统发育树构建

* 7.4 IQ-TREE 进阶建树（可选）

* 7.5 系统发育树定根

* 7.6 系统发育树与特征表 ID 匹配检查

## **第二部分：群落组成与 Alpha/Beta 多样性分析**

**一级标题 8：微生物群落组成与分类丰度分析**

* 8.1 不同分类水平的特征表合并

* 8.2 分类单元相对丰度计算

* 8.3 门、纲、目、科、属、种水平群落组成

* 8.4 群落组成堆叠柱状图

* 8.5 优势菌群与核心菌群分析

* 8.6 热图及分类丰度可视化

* 8.7 Rank-Abundance 等级丰度曲线

**一级标题 9：Alpha 多样性分析**

* 9.1 Alpha 多样性及常用指标

* 9.2 丰富度、均匀度与系统发育多样性

* 9.3 Alpha 稀释曲线

* 9.4 测序深度与抽平深度选择

* 9.5 Alpha 多样性指数计算

* 9.6 不同组间 Alpha 多样性比较

* 9.7 配对样本与纵向数据的 Alpha 多样性分析

**一级标题 10：Beta 多样性与群落结构差异分析**

* 10.1 Beta 多样性及常用距离指标

* 10.2 Bray-Curtis 与 Jaccard 距离

* 10.3 Weighted UniFrac 与 Unweighted UniFrac

* 10.4 基于距离矩阵的主坐标分析（PCoA）

* 10.5 Beta 多样性组间差异检验

* 10.6 PERMANOVA 分析

* 10.7 ANOSIM 分析

* 10.8 PERMDISP 组内离散度检验

* 10.9 配对与重复测量设计下的 Beta 多样性检验

**一级标题 11：微生物差异丰度分析**

* 11.1 差异丰度分析的统计学基础

* 11.2 传统差异检验方法及其局限

* 11.3 ANCOM 分析

* 11.4 ANCOM-BC 与 ANCOM-BC2 分析

* 11.5 LEfSe 生物标志物分析

* 11.6 MaAsLin3 多因素关联分析

* 11.7 LinDA 差异丰度分析

* 11.8 metagenomeSeq 分析

* 11.9 差异丰度分析的多重检验校正

* 11.10 不同统计方法的结果比较与敏感性分析

## **第三部分：微生物生态关联与进阶分析**

**一级标题 12：环境因子与微生物群落关联分析**

* 12.1 环境因子与群落组成数据准备

* 12.2 DCA 去趋势对应分析

* 12.3 RDA 冗余分析

* 12.4 CCA 典范对应分析

* 12.5 db-RDA 距离约束排序（建议新增）

* 12.6 环境因子拟合分析（envfit）

* 12.7 共线性检查与 VIF

* 12.8 约束排序的置换检验与结果解释

**一级标题 13：其他群落排序与聚类分析**

* 13.1 主成分分析（PCA）

* 13.2 非度量多维尺度分析（NMDS）

* 13.3 层次聚类分析与 UPGMA

* 13.4 不同排序方法的适用条件与结果解读

* 13.5 排序图的统计量与可视化

**一级标题 14：微生物共发生网络分析**

* 14.1 微生物共发生网络的基本原理

* 14.2 组成型数据与相关性分析的局限

* 14.3 SparCC 网络分析

* 14.4 SPIEC-EASI 网络分析

* 14.5 网络构建前的特征过滤与参数选择

* 14.6 网络拓扑指标分析

* 14.7 Zi-Pi 关键节点识别

* 14.8 网络稳定性与敏感性分析

* 14.9 共发生网络的生物学解释边界

**一级标题 15：功能预测与微生物来源追踪（可选）**

* 15.1 16S 功能预测的原理与局限

* 15.2 PICRUSt2 功能预测

* 15.3 Tax4Fun2 功能预测

* 15.4 FAPROTAX 生态功能注释

* 15.5 BugBase 表型预测

* 15.6 SourceTracker2 来源追踪

* 15.7 FEAST 来源追踪

* 15.8 功能预测与来源追踪结果解释

## **第四部分：结果汇总、复现与常见问题**

**一级标题 16：结果汇总、可视化与论文写作**

* 16.1 16S 分析结果的完整统计清单

* 16.2 群落组成结果的图表设计

* 16.3 Alpha/Beta 多样性结果展示

* 16.4 差异丰度结果展示

* 16.5 RDA/CCA/NMDS 等排序图展示

* 16.6 网络分析结果展示

* 16.7 统计结果的报告规范

* 16.8 16S 分析结果的生物学解释与局限性

**一级标题 17：QIIME 2 数据管理、流程复现与常见问题**

* 17.1 QIIME 2 Artifact 的查看与管理

* 17.2 QIIME 2 数据导出与 R 数据导入

* 17.3 BIOM 与 TSV 文件格式转换

* 17.4 项目目录结构与中间文件管理

* 17.5 软件版本、参数和数据库版本记录

* 17.6 命令行日志与计算过程追踪

* 17.7 常见命令报错及解决办法

* 17.8 常见统计分析问题及排查

**附录**

* 附录 A：QIIME 2 2024.2 环境安装

* 附录 B：常用数据库及分类器下载

* 附录 C：QIIME 2 常用命令速查

* 附录 D：R 端常用分析代码

* 附录 E：SRA 数据下载与 Manifest 批量生成

* 附录 F：16S 常用软件与算法原理

* 附录 G：参考文献与官方文档

# **五、建议新增的内容：目前教程还缺少什么？**

我认为下面这些内容比继续增加新的作图方法更重要。

## **5.1 必须新增：阴性对照、阳性对照与污染识别**

你目前几乎没有讲实验污染控制。

这会让一份 16S 分析教程缺失非常关键的实验设计环节。

建议新增：

**（1）阴性对照**

包括 DNA 提取空白和 PCR 空白。用于识别试剂、耗材、实验环境及 PCR 操作产生的污染序列。

**（2）阳性对照和 Mock Community**

用于评估：

* 流程能否检出已知菌群；

* 预期菌群是否被正确识别；

* 不同微生物的扩增偏好；

* 测序和去噪流程是否出现异常。

**（3）污染菌识别**

建议介绍 `decontam` 等工具，说明如何结合阴性对照、污染物出现频率以及样本 DNA 浓度识别潜在污染特征。

特别要强调：不能简单地将低丰度菌都当作污染物，也不能不看阴性对照就直接过滤。

## **5.2 必须新增：实验设计和 Metadata 的质量检查**

你的教程虽然介绍了 metadata 文件格式，但还没有真正说明一个合格的 metadata 应该包含什么。

建议新增一个完整示例：

| sample-id | Group   | Age | Sex | Batch  | SubjectID | Time |
| --------- | ------- | --- | --- | ------ | --------- | ---- |
| S01       | Control | 25  | F   | Batch1 | P01       | T0   |
| S02       | Case    | 32  | M   | Batch1 | P02       | T0   |
| S03       | Control | 25  | F   | Batch2 | P01       | T1   |

需要说明：

* 样本 ID 唯一；

* metadata 样本 ID 和特征表样本 ID 完全对应；

* 连续变量和分类变量的区分；

* 缺失值处理；

* 测序批次效应；

* 重复测量数据的 SubjectID；

* 时间序列变量的整理；

* 分组变量的编码规范。

这部分对于后面的 PERMANOVA、MaAsLin3、ANCOM-BC2 和纵向数据分析尤其重要。

## **5.3 建议新增：纵向与重复测量分析**

你的教程目前多数统计检验都是独立样本比较。

但实际的微生物组研究中，经常有：

* 同一个受试者干预前后采样；

* 同一个受试者在不同时间点采样；

* 多中心、多批次采样；

* 动物实验的多个时间点；

* 配对病例-对照研究。

这些数据不能简单地当作独立样本处理。

建议增加：

* 配对 Wilcoxon 检验；

* 线性混合效应模型；

* 重复测量 PERMANOVA；

* 个体作为随机效应；

* QIIME 2 `q2-longitudinal`；

* MaAsLin3 随机效应模型。

这部分可以显著提升教程的实用价值。

## **5.4 建议新增：核心微生物组分析**

这是我比较建议你增加的一部分。

16S 扩增子分析不仅应该回答：

> 哪些菌丰度最高？

还应该回答：

> 哪些微生物在不同样本或不同组别中稳定出现？

建议新增：

* 核心微生物组的定义；

* Prevalence（出现率）计算；

* Core microbiome 筛选；

* 不同组别核心菌群比较；

* UpSet 图；

* Venn 图；

* 核心菌群的相对丰度和出现率可视化。

尤其要强调：核心菌群的出现率阈值不是固定的，例如 50%、70%、90% 代表不同严格程度，需要根据研究目的定义，并报告阈值。

## **5.5 建议新增：db-RDA 距离约束排序**

你有 RDA、CCA，却没有单独介绍 db-RDA。

我建议把 db-RDA 加进去。

原因是：RDA/CCA 主要针对群落矩阵及其响应模型，而 db-RDA 可以通过距离矩阵开展约束排序，对于基于 Bray-Curtis 等生态距离的群落分析尤其有用。

推荐介绍：

* db-RDA 的基本原理；

* Bray-Curtis 距离矩阵；

* `vegan::capscale()`；

* 环境变量解释度；

* 模型整体置换检验；

* 约束轴解释率。

这样你的环境因子关联分析才更加完整。

## **5.6 建议新增：多重检验与效应量**

你已经在差异分析中提到了 FDR，但目前缺少系统解释。

建议新增：

* 原始 P 值与 FDR-adjusted P 值；

* Benjamini-Hochberg 校正；

* Bonferroni 校正；

* log2 fold change；

* 置信区间；

* 效应量；

* 多组比较与两两比较；

* 统计显著性与生物学意义的区别。

不能只教读者怎样得到一个 P 值，还应该教他们如何判断结果是否有生物学意义。

## **5.7 建议新增：样本和特征过滤后的数据量变化统计**

建议在主流程中加入一张统一的质量控制记录表：

| 处理阶段      | 样本数量 | 特征数量 | 总序列数 | 说明         |
| --------- | ---- | ---- | ---- | ---------- |
| 原始数据      |      | —    |      | 原始 reads   |
| 质量过滤后     |      | —    |      | 质量控制       |
| DADA2 去噪后 |      |      |      | ASV 推断     |
| 嵌合体去除后    |      |      |      | 最终非嵌合体序列   |
| 特征过滤后     |      |      |      | 低丰度和低出现率过滤 |
| 排除污染特征后   |      |      |      | 最终分析特征表    |

这张表可以让读者直观掌握每一步究竟损失了多少数据，也是论文 Methods 和 Supplementary Methods 中经常需要交代的信息。

# **六、网络分析章节需要重点重写**

你目前第 15 节的逻辑问题比较明显，我建议不要只做局部修改。

### **6.1 SPCC、SparCC 和 SPIEC-EASI 不应被描述为同一类算法**

你写道：

> SPCC（稀疏偏相关）、SparCC 与 SPIEC-EASI 本质上都在估计去掉其他类群影响后的稀疏相关/偏相关。

这个概括不准确。

建议将 SPCC 先删除，除非你能提供明确的算法全称、原始论文和实际使用的软件实现。

需要明确区分：

| 方法         | 核心思想          | 结果应如何解释              |
| ---------- | ------------- | -------------------- |
| SparCC     | 针对组成型数据估计相关关系 | 组成型相关性               |
| SPIEC-EASI | 稀疏条件依赖网络推断    | 条件依赖关系               |
| Pearson    | 普通线性相关        | 不适合作为未经处理的相对丰度网络默认方法 |
| Spearman   | 秩相关           | 也可能受组成型约束影响          |

尤其是 SPIEC-EASI：它推断的是条件依赖网络，不能直接把输出邻接矩阵中的每一条边解释成普通的相关系数 \\(r\\)，更不能在没有相应结果依据时给它强行赋予正相关或负相关。

### **6.2 网络构建不能把 20%–30% 出现率当成固定筛选条件**

这只是一个可选示例，不能成为适用于所有数据集的规则。

建议同时说明：

* 样本量；

* 特征数量；

* 特征出现率；

* 特征丰度；

* 稀疏程度；

* 参数选择；

* 网络稳定性；

* 不同过滤阈值下的敏感性分析。

### **6.3 Zi-Pi 不能直接等同于关键物种**

你原文：

> Zi / Pi 都高（或单方面很高）的节点通常被视为关键物种（keystone taxa）。

建议改为：

> Zi-Pi 分析用于识别在网络结构中具有特定连接角色的节点，例如模块枢纽和模块连接者。这些节点可作为潜在的网络结构关键类群候选，但不能仅凭拓扑位置认定其具有生态学意义上的关键物种功能。

网络中心性高，不代表它一定在真实生态系统中具有关键功能。

# **七、建议调整部分章节内容的定位**

我建议你不要把所有分析方法都放在“标准流程”下面。

| 内容                   | 建议定位         | 原因                    |
| -------------------- | ------------ | --------------------- |
| DADA2                | 标准主线         | 现代 ASV 推断常用方案         |
| Deblur               | 可选去噪方法       | 与 DADA2 是替代路线         |
| VSEARCH OTU          | 传统/补充分析路线    | 不应混进 ASV 主线           |
| FastTree             | 标准树构建方案      | 供 Faith PD、UniFrac 使用 |
| IQ-TREE              | 进阶方法         | 不需要每个 16S 数据集都做       |
| Alpha/Beta           | 核心分析         | 微生物群落分析基础             |
| PCoA                 | Beta 分析的常规组成 | 应归入 Beta              |
| PCA                  | 补充排序方法       | 与 PCoA 不应混为一谈         |
| NMDS                 | 补充排序方法       | 应与 PCoA、PCA 集中介绍      |
| UPGMA                | 补充聚类方法       | 归入排序与聚类模块             |
| Rank-Abundance       | 群落结构描述       | 归入群落组成                |
| RDA/CCA/db-RDA       | 环境因子关联       | 单独作为拓展模块              |
| ANCOM-BC2、MaAsLin3   | 差异丰度/关联分析    | 应系统讲清模型与数据输入          |
| 网络分析                 | 进阶生态分析       | 不属于每个 16S 项目必做        |
| PICRUSt2             | 功能预测拓展       | 不能替代宏基因组功能分析          |
| FEAST/SourceTracker2 | 来源追踪拓展       | 依赖 source/sink 采样设计   |

# **八、我认为还应该修改的教程写作方式**

你的教程有不少内容已经不止是命令说明，还包含经验判断。但目前“官方默认值”“推荐参数”和“个人经验值”没有明显区分。

我建议每一个分析小节都统一成下面的格式：

**标准小节模板**

**1. 分析目的与生物学问题**

这一步要回答什么问题，为什么要进行该分析？

**2. 分析原理**

软件或算法具体做了什么，核心统计思想是什么？

**3. 输入文件及其数据类型**

明确列出 `.qza`、`.qzv`、`.tsv`、`.biom` 等输入文件。

**4. 命令及参数解释**

给出可以运行的代码，并逐个解释参数。

**5. 输出结果及质量检查**

告诉读者应当查看哪些输出、如何判断是否运行成功。

**6. 参数选择与常见错误**

区分默认值、示例值、经验值和必须根据数据调整的参数。

**7. 结果解读与生物学意义**

解释输出结果能支持什么结论，不能支持什么结论。

**8. 相关参考文献与官方文档**

给出软件原始论文和版本对应的文档。

这样整个教程会更加像一份正规的生物信息学方法手册，而不是把各类命令和经验总结堆在一起。

此外，每个命令最好加入执行前后的输入输出文件说明，例如：

```
输入：
    demux-trimmed.qza

分析：
    qiime dada2 denoise-paired

输出：
    table-asv.qza
    rep-seqs.qza
    denoising-stats.qza
```

这样读者即使没有接触过 QIIME 2，也能够理解整个文件流向。

# **九、建议增加一张贯穿全篇的文件流转图**

你现在已经有整体流程图，但建议再增加一张更实用的**核心文件流转图**，让读者知道每一步产生的文件究竟供后面的哪一步使用。

## **16S 扩增子 ASV 分析主线**

**原始 FASTQ 数据**

R1 / R2 + Metadata + Manifest

**QIIME 2 导入与原始质量评估**

demux.qza → demux.qzv

**引物去除与质量预处理**

Cutadapt（按需）

**DADA2 去噪**

质量过滤 → 去噪 → 双端拼接 → 去嵌合体

**ASV 特征表**

table-asv.qza

**ASV 代表序列**

rep-seqs.qza

**特征表质量控制**

样本过滤、低丰度过滤、污染及细胞器序列处理

**物种分类注释**

taxonomy.qza

**系统发育树**

rooted-tree.qza

**最终分析数据集**

特征表 + 代表序列 + 分类注释 + 系统发育树 + Metadata

**群落组成**

相对丰度、核心菌群、Rank-Abundance

**Alpha 多样性**

丰富度、均匀度、Faith PD

**Beta 多样性**

距离矩阵、PCoA、PERMANOVA

**差异丰度**

ANCOM-BC2、MaAsLin3、LEfSe

**环境关联**

RDA、CCA、db-RDA

**进阶生态分析**

网络、功能预测、来源追踪

这张图的价值在于：它明确了 ASV 主线的输入输出关系，而且把最终分析分成了多个平行的下游分析模块，不会让读者误以为所有分析都必须按照一条固定顺序执行。

# **十、最后给你一个修改优先级**

目前不建议直接开始增加大量新分析方法。更合理的是先把教程修到可以放心照着执行的程度。

| 优先级   | 修改内容                    | 处理建议     |
| ----- | ----------------------- | -------- |
| 第一优先级 | Cutadapt 与 DADA2 输入文件衔接 | 立即修改     |
| 第一优先级 | Single-end Manifest 格式  | 立即修改     |
| 第一优先级 | ANCOM-BC 输出参数           | 立即修改     |
| 第一优先级 | IQ-TREE 参数名称            | 立即核对并修改  |
| 第一优先级 | LEfSe 的 `-c` 参数         | 立即修改     |
| 第一优先级 | 所有 R 矩阵方向               | 全部重写     |
| 第一优先级 | 抽平与差异分析的关系              | 修改统计学说明  |
| 第二优先级 | ASV/OTU 主线与可选分支         | 重新组织     |
| 第二优先级 | 系统发育树章节位置               | 调整       |
| 第二优先级 | 分类表、过滤表与下游文件统一          | 统一命名和数据流 |
| 第二优先级 | 网络分析原理                  | 重写       |
| 第二优先级 | PICRUSt2 原理             | 重写       |
| 第三优先级 | 核心微生物组                  | 新增       |
| 第三优先级 | 阴性对照与污染识别               | 新增       |
| 第三优先级 | 纵向分析和重复测量               | 新增       |
| 第三优先级 | db-RDA                  | 新增       |
| 第三优先级 | 统计报告和复现性                | 新增       |

还有一个版本方面的提醒：你的教程明确以 QIIME 2 2024.2 为准，但目前在线官方文档中有些页面已经转为更新版本。因此，上面引用的部分新版本文档用于核对算法和参数接口，并不代表所有新版参数都可以不经检查地直接复制到 2024.2。正式定稿时，应在目标环境中逐条核验：

```
qiime info

qiime dada2 denoise-paired --help
qiime cutadapt trim-paired --help
qiime composition ancombc --help
qiime phylogeny iqtree --help
qiime feature-table filter-features --help
```

尤其要固定分类数据库文件、分类器文件和软件环境版本。QIIME 2 官方也明确提示，预训练分类器与 scikit-learn 版本有关，必须匹配对应的 QIIME 2 发行版。

library.qiime2.org

**我的最终建议是：把这份教程定位为“以 DADA2-ASV 为标准主线，兼顾传统 OTU 分析与 R 端群落生态统计的 16S rRNA 扩增子分析手册”。** 不要把所有方法都包装成必做步骤。主流程保证可执行，拓展方法保证解释准确，统计章节保证数据方向和模型适用条件正确，这样它才真正具有长期使用价值。

下一步最值得做的是按照上面的新目录，对原 `index.typ` 逐章重排，并把有问题的命令和 R 代码直接替换成经过核验的版本，而不只是修改标题。
