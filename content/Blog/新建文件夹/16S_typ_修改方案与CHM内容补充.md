# 16S rRNA 扩增子教程（QIIME 2 2024.2）修订方案

## 先统一流程定位

对于你当前希望教程复现的 CHM 稿件分析路线，主流程应写为：

**原始 FASTQ → DADA2 去噪（得到 ASV 特征表与代表序列）→ ASV 层面的质量评估 → Greengenes2 closed-reference 99% 映射 → 得到 closed-reference OTU/参考特征表 → taxonomy 注释与系统发育树匹配 → 群落组成、Alpha/Beta 多样性及后续 OTU 层面统计。**

因此，原 Typst 中“DADA2 的 ASV 输出已经是下游唯一终点、closed-reference 只是可选补充”的表达，应改成“**本教程主线在 DADA2 后继续执行 closed-reference mapping**”。但需要保留一个范围说明：这不是所有 16S 研究的普遍强制步骤。QIIME 2 官方将去噪得到的 ASV 作为高分辨率特征，并允许把 DADA2 输出的 `FeatureTable[Frequency]` 与 `FeatureData[Sequence]` 继续交给 q2-vsearch 做 closed-reference clustering；官方也提醒，聚类会降低特征分辨率，只有在需要固定参考特征空间、跨研究映射等明确场景下才应采用。

你的 CHM 稿件的场景正是跨研究整合：不同研究、扩增区和样本的 DADA2 ASV 不能直接当成同一特征空间，因此将 ASV 映射到统一 Greengenes2 backbone。**教程里要写成“本教程指定主线/跨队列整合方案”，而不是“所有项目都必须做 OTU”。**

---

## 一、原 `index.typ` 必须调整的部分

以下位置按当前上传版本 `index.typ` 的行号定位；修改后行号会变化。

### 1. 修改标题下的流程简介（原第 12–16 行）

将原来：

> 质控 → 拼接 → 去嵌合体 → ASV/OTU 与注释 → Alpha/Beta 多样性……

改成类似下面的表述：

> 本教程以 QIIME 2 2024.2 为分析环境，采用 DADA2 进行序列去噪并推断 ASV；在需要跨研究统一特征空间的主线中，进一步将 ASV 通过 Greengenes2 backbone 进行 99% closed-reference mapping，构建参考库定义的 OTU 特征表。群落组成、Alpha/Beta 多样性及基于分类单元的比较分析以该 OTU 表为主要输入；ASV 表及未匹配 ASV 则保留用于序列层面质控、数据库覆盖度评估和 PICRUSt2 等分析。

不要再把“拼接”和“去嵌合体”写成 DADA2 之后必须单独再执行的独立主步骤。对于双端数据，`qiime dada2 denoise-paired` 内部已经包含过滤、去噪、双端拼接和嵌合体处理。

### 2. 修改 0.3 的 ASV/OTU 定义

建议把现有 ASV/OTU 表格扩展成下面四种概念，避免混用：

| 术语 | 本教程中的含义 | 主要用途 |
|---|---|---|
| ASV | DADA2 基于错误模型推断出的精确扩增子序列变体 | 保留高分辨率序列信息；PICRUSt2、数据库覆盖度与未匹配序列分析 |
| de novo OTU | 根据本研究数据内部序列相似度聚类形成的 OTU | 需要传统 OTU 分析、但不依赖固定参考库的场景 |
| closed-reference OTU | ASV 按指定相似度映射到固定参考序列；同一参考序列对应的计数合并 | 本教程的跨研究统一主线 |
| open-reference OTU | 先映射参考库，未匹配序列再进行 de novo 聚类 | 希望保留部分参考库未覆盖序列的替代方案 |

特别说明：本教程中 Greengenes2 99% closed-reference 得到的结果，建议称为“**99% closed-reference OTU 表**”或“**参考库定义的 OTU 特征表**”。它不是 DADA2 的原始 ASV 表，也不是传统意义上不依赖参考库的 de novo 97% OTU。不要把 99% identity 直接等同于物种鉴定成功。

### 3. 修改 0.4 的总流程表与文件命名

建议把主流程的文件名固定下来：

| 文件 | 含义 | 主要下游用途 |
|---|---|---|
| `table-asv.qza` | DADA2 原始 ASV 计数表 | ASV 层面分析、PICRUSt2、参考库覆盖度 |
| `rep-seqs-asv.qza` | DADA2 ASV 代表序列 | closed-reference mapping、ASV 序列分析 |
| `denoising-stats.qza` | DADA2 分阶段统计 | 质控和嵌合体比例评估 |
| `table-gg2-cr99.qza` | Greengenes2 99% closed-reference OTU 表 | 群落组成、Alpha/Beta、多数 OTU 层面统计 |
| `rep-seqs-gg2-cr99.qza` | 映射后代表参考序列 | 与 OTU 特征 ID 对应的分类注释、序列核查 |
| `unmatched-asvs-gg2.qza` | 未匹配 Greengenes2 的 ASV 序列 | 映射率评估、未覆盖序列分析 |
| `taxonomy-gg2.qza` | 与 closed-reference 表特征 ID 对应的分类注释 | `taxa collapse`、`taxa barplot` |
| `tree-gg2.qza` | 与 closed-reference 特征 ID 对应的参考树或兼容树 | Faith PD、UniFrac |

总流程表应明确区分两条下游支线：

- **OTU 主线：** `table-gg2-cr99.qza` → 分类组成、Alpha/Beta、差异丰度、网络等。
- **ASV 支线：** `table-asv.qza` + `rep-seqs-asv.qza` → PICRUSt2、eHOMD/参考数据库覆盖分析、未匹配 ASV 的进一步鉴定。

### 4. 修改第 1.2 节 Cutadapt 与第 2 节 DADA2 的文件衔接

当前第 1.2 节输出 `demux-trimmed.qza`，但第 2 节命令仍输入 `demux.qza`。必须修正，否则 Cutadapt 结果不会进入 DADA2。

若已用 Cutadapt 去引物，DADA2 命令改为：

```bash
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
  --o-representative-sequences rep-seqs-asv.qza \
  --o-table table-asv.qza \
  --o-denoising-stats denoising-stats.qza
```

以上截断长度仅为演示，必须根据实际质量图、扩增子长度和双端重叠长度确定。如果不执行 Cutadapt、而由 DADA2 按固定长度切除引物，则输入 `demux.qza` 并设置合适的 `--p-trim-left-f/r`。**两套去引物方式二选一，不要重复剪切。**

将第 2 节标题从“序列拼接”改成“DADA2 去噪与 ASV 构建”。在正文中说明：DADA2 的 `denoise-paired` 是去噪主步骤，双端拼接只是其中的内部环节，不应先单独运行 `qiime vsearch join-pairs` 后再将已拼接序列交给 `denoise-paired`。

DADA2 的统计阶段说明需要改成五个阶段：`input`、`filtered`、`denoised`、`merged`、`non-chimeric`。当前文件只写了 input、filtered、merged、non-chimeric，漏掉 denoised。

### 5. 重写第 3 节：不要在 DADA2 后再把 VSEARCH UCHIME 当成必做步骤

将标题改成：

`== 3. DADA2 输出质量审核与 ASV 特征整理`

建议小节为：

- 3.1 DADA2 内部嵌合体识别：DADA2 已在 denoising pipeline 中处理；说明 `non-chimeric` 统计。
- 3.2 按样本检查去噪保留率和嵌合体比例。
- 3.3 ASV 长度分布检查与异常短序列处理。
- 3.4 低丰度/低出现率 ASV 过滤：作为有依据的可选过滤，不要把它写成所有项目固定必做。
- 3.5 线粒体、叶绿体及其他非目标序列识别。
- 3.6 阴性对照、阳性对照和污染特征处理。

把原来第 3.1 节里 `qiime vsearch uchime-denovo` 的命令移动到“非 DADA2 传统 OTU/序列处理路线”或“可选补充方法”中。对已经完成 DADA2 去嵌合体的 ASV 主线，不要再重复跑一遍 denovo UCHIME，除非存在明确的额外质控目的，并且说明为何重复筛查。

原文“多数样本从 input 到 non-chimeric 保留率低于 20% 就说明不可信”应删除。应改成依据每个样本的分阶段损失、质量图、双端拼接率、嵌合体比例、样本深度和实验设计共同判断；20% 不能作为通用停止阈值。

### 6. 把现有 4.1 的 closed-reference 内容提升为第 4 节主流程

建议第 4 节改名：

`== 4. Greengenes2 closed-reference mapping 与 OTU 特征表构建`

新的二级标题：

- 4.1 为什么 DADA2 后还要进行 closed-reference mapping
- 4.2 Greengenes2 参考库与版本选择
- 4.3 ASV 到 Greengenes2 backbone 的 99% 映射
- 4.4 未匹配序列、样本 mapping rate 与队列级质量控制
- 4.5 closed-reference OTU 表统计与过滤
- 4.6 de novo / open-reference 聚类作为替代路线

#### 4.3 主线命令建议

Greengenes2 2024.09 的官方 FTP 提供 `2024.09.backbone.full-length.fna.qza` 等 QIIME 2 Artifact；建议固定版本路径，而不要用会随时间变化的 `current` 路径。下载：

```bash
mkdir -p reference/greengenes2_2024.09
cd reference/greengenes2_2024.09

wget -c https://ftp.microbio.me/greengenes_release/2024.09/2024.09.backbone.full-length.fna.qza
wget -c https://ftp.microbio.me/greengenes_release/2024.09/2024.09.backbone.tax.qza
```

先核对 Artifact 类型和版本：

```bash
qiime tools peek 2024.09.backbone.full-length.fna.qza
qiime tools peek 2024.09.backbone.tax.qza
qiime vsearch cluster-features-closed-reference --help
```

然后执行 closed-reference：

```bash
qiime vsearch cluster-features-closed-reference \
  --i-table table-asv.qza \
  --i-sequences rep-seqs-asv.qza \
  --i-reference-sequences reference/greengenes2_2024.09/2024.09.backbone.full-length.fna.qza \
  --p-perc-identity 0.99 \
  --p-strand both \
  --p-threads 8 \
  --o-clustered-table table-gg2-cr99.qza \
  --o-clustered-sequences rep-seqs-gg2-cr99.qza \
  --o-unmatched-sequences unmatched-asvs-gg2.qza
```

说明：

1. 输入必须是一对对应的 DADA2 输出：`FeatureTable[Frequency]` 和 `FeatureData[Sequence]`，不能只给代表序列而不提供计数表。
2. `--p-perc-identity 0.99` 是你 CHM 稿件采用的研究设定，不是适用于所有 16S 扩增区的通用阈值。教程需要解释它是为了与该研究中的 Greengenes2 backbone 对齐。
3. 映射到同一个参考序列的多个 ASV，其样本内 counts 会合并到对应参考特征；未达到相似度阈值的 ASV 不进入 clustered table，而由 unmatched 序列输出保留。
4. `cluster-features-closed-reference` 的输出 feature ID 继承参考序列/聚类中心的 ID，不再是原始 DADA2 ASV ID。因此，下游 taxonomy 必须和新表的 feature ID 对应。
5. 不要把 ASV 的 taxonomy.qza 直接拿来给 closed-reference OTU 表 `table-gg2-cr99.qza` 做 `taxa collapse`，除非已经确认 ID 一一对应。通常两者 ID 空间不同。

#### 4.4 mapping rate 需要作为独立质控

建议增加定义：

\[
\text{Mapping rate}_i =
\frac{\text{sample }i\text{ 中映射到参考库的 reads}}{\text{sample }i\text{ 输入 closed-reference 的 ASV reads}}\times100\%
\]

队列/项目层面的总 mapping rate 建议明确使用“映射 reads 总和 / 输入 reads 总和”的加权比率；如果实际脚本计算的是各样本 mapping rate 的算术平均，则必须按实际实现报告，不能混用两种定义。

可以将原始 ASV 表与 closed-reference OTU 表导出 BIOM/TSV 后，在 R 中计算：

```r
read_biom_tsv <- function(file) {
  x <- read.delim(
    file, row.names = 1, skip = 1,
    check.names = FALSE, comment.char = ""
  )
  as.matrix(x) # BIOM TSV：行 = feature，列 = sample
}

asv <- read_biom_tsv("asv/feature-table.tsv")
cr  <- read_biom_tsv("closed-reference/feature-table.tsv")

common_samples <- intersect(colnames(asv), colnames(cr))
asv <- asv[, common_samples, drop = FALSE]
cr  <- cr[, common_samples, drop = FALSE]

input_reads  <- colSums(asv)
mapped_reads <- colSums(cr)

mapping_qc <- data.frame(
  sample_id = common_samples,
  input_reads = input_reads,
  mapped_reads = mapped_reads,
  mapping_rate = mapped_reads / input_reads
)

write.table(
  mapping_qc, "sample_mapping_rate.tsv",
  sep = "\t", quote = FALSE, row.names = FALSE
)
```

以上矩阵方向与 `biom convert --to-tsv` 的常规导出方向一致：行是 feature，列是 sample。计算前仍应检查两个表的样本 ID、样本顺序与样本集合完全匹配。

你的 CHM 稿件中采用了以下**队列级数据集筛选规则**：去噪后，若一个队列中超过 30% 的口腔样本嵌合体比例高于 25%，则排除该队列；closed-reference 后排除 mapping rate 为 0 的样本；若某队列口腔样本总体 mapping rate 低于 70%，则排除该队列。教程可以把这些列为“该研究的示范性规则”，但必须注明它们是该大型跨队列研究的预设 QC criteria，不是所有单队列项目都必须套用的统一阈值。

### 7. 修改 taxonomy 注释：必须保证特征 ID 对齐

原 4.3 节主要是对 DADA2 原始 `rep-seqs.qza` 用 SILVA 分类器。若你的主分析对象已经变成 `table-gg2-cr99.qza`，则需要把 taxonomy 一节拆成两个层次：

- **ASV taxonomy（可选支线）：** 对 `rep-seqs-asv.qza` 做 SILVA/Greengenes2 分类，供原始 ASV 注释或未匹配序列探索。
- **Closed-reference OTU taxonomy（主线）：** taxonomy 必须与 `rep-seqs-gg2-cr99.qza` / `table-gg2-cr99.qza` 的 reference feature ID 对齐，优先使用对应 Greengenes2 release 的参考分类信息。

Greengenes2 2024.09 提供 backbone sequence 与 taxonomy 文件，也提供树/分类文件的 ASV、ID、MD5 等不同命名空间。必须确认当前 OTU 表使用的 ID namespace 和 taxonomy/tree 文件中的 ID namespace 一致。可以先运行 `qiime tools peek` 检查 Artifact 类型，再选用能匹配该类型的分类注释方法。不要把 2024.09 的 reference sequence 与另一个版本的 taxonomy 或 tree 混用。

注释完成后，原来第 5 节（分类水平合并与相对丰度）和 `taxa barplot` 的输入表，均应由 `table-filtered.qza` 改为经过 QC 的 `table-gg2-cr99.qza` 或其最终过滤版本；对应 taxonomy 必须使用 `taxonomy-gg2.qza`。

### 8. 修改系统发育树章节与 Alpha/Beta 输入

将系统发育树章节移到 Alpha/Beta 多样性章节之前。你上传的 CHM 稿件中，Beta 多样性使用 Greengenes2 reference phylogenetic tree，并在 closed-reference OTU 表上计算 UniFrac；因此教程的主线应优先讲如何使用与 closed-reference feature IDs 完全匹配的 Greengenes2 参考树。

关键检查：

- OTU 表中的每个 feature ID 都必须存在于树的 tip labels 中；
- 树、taxonomy、OTU 表必须来自同一 Greengenes2 release / ID namespace；
- 若无法保证 reference tree 与 closed-reference OTU ID 匹配，则不能仅凭文件名相似就直接运行 UniFrac；需要先进行 ID 集合核查，必要时对映射后的代表序列重新建树，并明确这不是原版 Greengenes2 reference tree。

Alpha/Beta 主线建议写成：

- `qiime diversity alpha`：输入 `table-gg2-cr99.qza`，明确是否对表抽平；
- `qiime diversity core-metrics-phylogenetic`：输入 `table-gg2-cr99.qza` 与匹配的 `tree-gg2.qza`，用于 UniFrac、Faith PD 及相关排序；
- 若设置 sampling depth，报告抽平深度、被排除样本数和敏感性检查；不要把 1,000 reads 当作通用推荐值。

你 CHM 稿件中的 UniFrac sampling depth = 1,000 是该数据集在文章中的方法设定，不应在教程中写成通用标准。稿件方法还区分了 Alpha 与 Beta：Alpha 指数通过 `qiime diversity alpha` 计算；Beta 的 UniFrac 通过 `core-metrics-phylogenetic` 在 1,000 reads 抽平后计算。因此不能把文章的方法简化成“所有 Alpha、Beta 指标都统一抽平到 1,000”。

### 9. 修改 PICRUSt2 的输入：明确它走 ASV 支线

原第 16.4 节将 PICRUSt2 描述为“建议用 Greengenes 注释，便于与 PICRUSt 参考树对齐”，建议改写。

本教程应明确：**PICRUSt2 以 DADA2 质量控制后的 ASV 表和 ASV 代表序列为输入，不要因为下游群落多样性使用 closed-reference OTU 表，就把 PICRUSt2 输入也换成 OTU 表。** 你的 CHM 稿件 Methods 明确写的是 quality-controlled oral 16S ASV table，经 PICRUSt2 将 ASV 放置到参考系统发育树上，预测 EC、KO 和 MetaCyc pathway，并用 weighted NSTI 评估预测置信度。

新增内容：

- PICRUSt2 输入文件与输出模块；
- EC、KO、MetaCyc 三类预测结果的含义；
- NSTI 及 weighted NSTI 的解释；
- 预测结果是基于参考基因组/系统发育信息的推断，不是实际宏基因组测量；
- ASV 和 OTU 两条数据支线不能混为同一个 feature table。

---

## 二、从 CHM DOCX 中值得补充进 Typst 的内容

下面这些内容是从你上传的 `CHM-manuscripts-1027-1250.docx` 的 STAR Methods / Quantification and Statistical Analysis 中提炼的。它们比单纯增加更多作图命令更能提升教程的实际科研价值。

### A. 数据整理和 Metadata 质量控制（建议新增为独立一级标题）

稿件按 BioProject/研究逐个建目录，每个队列保留原始 manifest、原论文、整理后的 metadata 和可复现整理脚本；对照论文和补充材料，统一元数据变量，并删除阴性对照、阳性 mock community 和非目标样本。建议教程补充：

- 样本 ID、Run ID、Subject ID、BioProject ID 的区别；
- 同一受试者多个口腔部位、多个时间点和技术重复样本的编码；
- 记录样本来源、测序平台、引物/高变区、疾病状态、年龄、性别、BMI、采样部位、国家/地区和批次；
- 不可从原始 metadata 或论文确认的变量应保留 NA，不要主观补值；
- 同一受试者同一部位同一时间点的技术重复，是否合并/去重必须预先定义。

### B. 16S 高变区的序列级核查（新增到 Metadata / 原始序列质量控制）

稿件没有完全依赖研究论文或 SRA metadata 提供的 V1–V9 区域说明，而是将 ASV 序列与全长 *E. coli* 16S rRNA 参考序列 GenBank J01695.2 比对，并按 V1–V9 坐标核实扩增区域。

教程可新增“根据 ASV 序列核验扩增区”模块，提醒读者：

- SRA metadata 中的 `target_subfragment` 或论文描述可能缺失或不一致；
- 不同扩增区域会影响分类注释、参考库匹配率和跨研究可比性；
- 对跨研究整合，应该把 sequencing region 作为重要技术变量记录，在分析中进行分层或协变量调整。

### C. 阴性对照与污染序列识别（建议作为必须介绍的 QC 子章）

稿件中污染识别不是简单删除低丰度 ASV，而是：先检查 extraction/sequencing controls，建立 control-derived contaminant catalogue；再根据序列相似性和分类学信息排查潜在污染物，并参考已报道的常见试剂污染菌。

建议教程补充：

- extraction blank 与 PCR negative control 的用途；
- mock community 的阳性质量评估作用；
- `decontam` 的 prevalence/frequency 思路；
- 阴性对照 ASV 与正式样本 ASV 的序列相似性检查；
- 不能仅凭低丰度、低出现率就认定污染；
- 污染过滤前后样本测序量、特征数和主要结果是否稳定。

稿件使用“control-derived ASV ≥97% identity”及相关 genus 级排除作为一个具体研究方案。建议作为案例展示，明确不是可复制到所有项目的默认污染规则。

### D. 跨队列 QC 的两层阈值体系（新增到 closed-reference mapping 小节）

稿件展示了两个不同层面的 QC：

1. **序列/样本层面：** 单样本 chimera proportion、单样本 Greengenes2 mapping rate；
2. **队列层面：** 某队列异常样本比例、队列总体 mapping rate。

这比单纯检查总 reads 或 ASV 数更适合多队列整合。教程可以加入一个 QC 汇总表，记录每个 BioProject 的样本数、DADA2 成功率、嵌合体比例分布、closed-reference mapping rate 分布、排除样本数和最终保留数。

### E. 参考库映射后的未匹配 ASV 不能直接丢弃（新增到 closed-reference 章节）

稿件将 `unmatched`/低相似度 ASV 作为数据库覆盖度研究的输入，而不是把它们全部当成错误序列。建议教程明确区分：

- 对 OTU 主线：未匹配 ASV 不进入 closed-reference OTU 表；
- 对序列多样性/新颖类群探索：保留 unmatched ASV，结合 eHOMD、SILVA、Greengenes2、BLAST/VSEARCH 和系统发育放置继续鉴定；
- 未匹配并不自动等于新物种，也可能来自扩增区差异、序列质量、污染、嵌合体或参考库缺口。

可以新增“参考库覆盖度分析”的进阶小节，说明按 identity threshold（如 ≥97%、70–97%）统计 ASV 数、reads 占比和样本 prevalence；要明确 identity 是相对于指定 reference、按何种 alignment coverage 计算。

### F. Alpha diversity 的跨队列混合效应模型（新增到 Alpha 统计检验）

稿件使用 Shannon diversity 作为响应变量，将 sex、age group、sampling site、16S variable region、continent 作为固定效应，将 BioProject 设为随机截距，以处理跨研究异质性。

教程建议增加：

- 为什么合并多个 BioProject 后不能把所有样本都当成完全独立观测；
- 固定效应与随机效应的区别；
- `lme4::lmer()` / `lmerTest` 的基本模型；
- complete-case 样本量与队列数量必须报告；
- marginal R² 与 conditional R² 的区别；
- 多因素模型的参考水平和协变量共线性检查。

这是跨队列研究的示范，不要替代单队列设计下的普通两组/多组比较。

### G. 差异丰度分析：多方法共识，而不是只选一个 P 值（强烈建议补充）

稿件在属水平结合 LinDA、MaAsLin2、ANCOM-BC2，并要求至少两个方法支持、方向一致、各方法 BH-adjusted p ≤ 0.05，才定义共识差异属。

可增加“多方法共识分析”模块：

- 为什么不同差异丰度方法可能产生不同结果；
- LinDA、MaAsLin2、ANCOM-BC2 的数据输入与模型差异；
- 同一结果需比较方向一致性，而不只是显著/不显著；
- 在疾病研究中，优先使用同一 BioProject 的 matched healthy controls，减少跨研究批次混杂；
- 低出现率特征过滤阈值需预先定义，并对敏感性进行检查；
- 效应量方向要写清楚，例如正系数代表 disease-enriched 还是 control-enriched。

注意：你现有 Typst 写 MaAsLin3；CHM 稿件此处实际使用 MaAsLin2。可保留 MaAsLin3 作为新版方法介绍，但应新增 MaAsLin2 的历史/案例说明，不能把两者版本名混写。

### H. 样本数累积曲线与测序深度稀释曲线的区别（新增到 Alpha / 群落丰富度）

稿件对 1–约 80,000 个样本规模的 compendium 做 sample-based rarefaction：每个样本规模随机抽样 150 次，统计不同分类层级的独特 taxa 数量，计算均值并用 `mgcv` GAM 平滑。

建议在 Typst 中明确区分两类曲线：

- **Sequencing-depth rarefaction curve：** 固定样本，改变 reads 抽样深度，评估单个样本的测序深度与多样性估计；
- **Sample-based species accumulation/rarefaction curve：** 改变样本数量，观察整个研究/compendium 随采样规模增加能发现多少 taxa。

稿件中的 150 次迭代、GAM `y ~ s(x, bs = "cs")` 是样本累积曲线案例，可作为一个进阶 R 模块补充，不要与 QIIME 2 `alpha-rarefaction` 混在一起。

### I. 跨队列网络的共识构建（新增到网络分析）

稿件的网络方法值得补充，因为它不是把所有研究简单合并后直接算一次相关：

1. 在每个 BioProject 内分别按 healthy/disease 分层；
2. 组内低出现属过滤（案例阈值：少于 5 个样本检测到则排除）；
3. 使用 SparCC（在 SpiecEasi 环境下实现）推断队列内关联；
4. 使用 NetMoss 整合各队列网络；
5. 仅保留在足够比例的队列中方向一致、且 pooled association 达到阈值的边；
6. 用 Louvain 识别模块；
7. 用 Zi/Pi 或 within-module degree/participation coefficient 描述节点的网络角色。

需要补充“跨队列一致性”概念，并强调节点/边是统计关联，不直接证明互作或因果。稿件中的 `|r| ≥ 0.20`、60% 网络一致性和 50 次 Louvain restart 是具体研究阈值，作为案例而非默认标准。

### J. 机器学习与跨研究验证（新增到高级分析）

稿件提供了两种很有价值的验证设计：

- 年龄预测：按口腔部位分别建模，报告 MAE、R²、Spearman ρ；
- 疾病分类：使用 leave-one-study-out (LOSO) cross-validation，每次留出一个 BioProject 作为独立测试集，降低模型利用研究批次特征而获得虚高性能的风险。

教程可新增“微生物组机器学习”章节，介绍：

- 训练/验证/测试拆分；
- 不能随机按样本拆分后让同一队列同时进入训练和测试，除非研究目标确实是队列内预测；
- LOSO 或 grouped CV 用于跨队列泛化；
- 类别不平衡、特征筛选和数据预处理应在训练折内部完成，防止数据泄漏；
- AUC、MAE、R²、Spearman 相关、置信区间和外部验证。

### K. 配对/纵向样本设计与随机对照比较（新增到纵向分析）

稿件对口腔–肠道同个体配对的比较很有参考价值：先通过 Subject ID 与采样时间点建立配对，再与同 BioProject、同 health-status stratum 中随机抽取的非配对样本比较，作为“不同个体”的参考分布。

教程建议新增：

- subject/timepoint/site 的复合配对 ID；
- 技术重复去重；
- 配对 Wilcoxon 或配对距离比较；
- 同一 BioProject/健康状态内 random-unpaired controls；
- 重复测量用混合效应模型或适当的 repeated-measures PERMANOVA；
- 不可将配对样本当作互相独立样本进行普通检验。

### L. SourceTracker2 的 source/sink 设计（新增到来源追踪）

稿件的 source tracking 将每一个 gut sample 作为 sink，将该个体配对的 oral sample(s) 作为 named source environment，其余无法解释的部分归入 Unknown；低于 1,000 reads 的配对样本被排除，source/sink rarefied 到 1,000 reads 后再进行 Gibbs sampling。

教程应重点讲清：

- source 与 sink 的定义；
- 采样设计决定来源追踪是否可解释；
- SourceTracker2 的 Unknown fraction 不是可忽略的噪声；
- 预测的来源比例是模型估计，不是直接观测到的转移事件；
- 深度阈值和抽平深度必须根据研究设计确定。

### M. 低参考相似度 ASV 的系统发育放置（高级拓展）

稿件利用 SEPP 将未充分匹配 eHOMD 的 ASV 放置到 Greengenes2 系统发育树，再用 TreeCluster 按最大 clade distance 定义 phylotypes。这是很有价值的“参考库缺口研究”拓展，建议放在“高级序列鉴定/参考库覆盖度”中，而不是放在常规 16S 必做步骤。

### N. 统计可复现性和资源记录（新增到项目管理附录）

建议给每个队列保存四类文件：原始 manifest、原始论文、最终 curated metadata、metadata curation script；同时保存 accession、下载日期、MD5、软件版本、参考数据库版本、完整命令和 log。这样后续批量复现、队列排除和审稿人追问时有明确依据。

---

## 三、建议的最终目录顺序

不需要把所有方法拆成很多同级章节。建议按真正的数据流重排为：

1. 教程说明、环境和分析策略
2. 研究设计、样本 Metadata 与公共数据准备
3. 数据导入与原始测序质量评估
4. Cutadapt 去引物与原始序列预处理
5. DADA2 去噪与 ASV 特征表构建
6. ASV 质量控制、嵌合体评估、污染与 organelle 过滤
7. Greengenes2 closed-reference 99% 映射与 OTU 表构建
8. Mapping rate、未匹配 ASV 与队列层面 QC
9. 分类注释与最终 OTU 表整理
10. 系统发育树及特征 ID 匹配
11. 群落组成与核心菌群分析
12. Alpha 多样性与测序深度评估
13. Beta 多样性、PCoA 与 PERMANOVA/PERMDISP
14. 差异丰度与多方法共识分析
15. 环境因子约束排序（RDA/CCA/db-RDA）
16. 其他排序和聚类（PCA/NMDS/UPGMA）
17. 网络分析与跨队列网络共识
18. ASV 支线：PICRUSt2、参考库覆盖度和 phylotype 分析
19. 配对/纵向分析、SourceTracker2 与机器学习（高级模块）
20. 结果报告、可视化、数据管理与复现
21. 附录：安装、数据库、SRA 下载、BIOM/R 导入与故障排查

---

## 四、即使不挖掘 DOCX，当前 Typst 仍需修正的已知错误

| 位置 | 需要修改的地方 |
|---|---|
| 0.2 | SingleEndFastqManifestPhred33V2 应使用两列 Manifest：`sample-id`、`absolute-filepath`；当前写三列旧格式与 V2 不匹配。 |
| 1.2 → 2 | 若运行 Cutadapt，DADA2 输入必须用 `demux-trimmed.qza`；不要又回到 `demux.qza`。 |
| 2 | DADA2 denoising stats 漏写 `denoised` 阶段。 |
| 3.1 | 已走 DADA2 主线时不要将 VSEARCH uchime-denovo 再列为重复的必做去嵌合体步骤。 |
| 4.1 | closed-reference 应提升到 DADA2 后的主线，不再只作为可选段落；de novo/open-reference 放在对照/替代方案。 |
| 4.2–5 | 统一 downstream 文件名：以 `table-gg2-cr99.qza` 和对应 `taxonomy-gg2.qza` 为主，避免 ASV 表和 OTU 表交叉误用。 |
| 5.1 | “做统计检验前仍要抽平”错误。差异丰度分析通常使用 count table 并由模型做归一化/偏差校正；Alpha/Beta 的深度处理要按具体指标和方法决定。 |
| 7.1 | R 中 BIOM 导出的矩阵通常是行=feature、列=sample；`vegdist` 前要转为行=sample、列=feature。Jaccard 若要 presence/absence，应明确设置 `binary=TRUE`。 |
| 8 | 系统发育树章节在目录中应移动到 Alpha/Beta 之前；更重要的是保证 tree tips 与最终 OTU feature IDs 匹配。 |
| 9 | Rank-Abundance 读取 BIOM 表后要先转置为样本×特征，再按样本行提取。 |
| 10.2 | PCA 代码的矩阵方向、零特征过滤和二次转置需要修正。 |
| 11 | UPGMA 的 Bray-Curtis 距离输入也要先转置为样本×特征。 |
| 12.1 | QIIME 2 `composition ancombc` 输出参数应为 `--o-differentials`，不是 `--o-visualization`；再单独进行结果可视化。 |
| 12.2 | LEfSe `-c` 是类别列编号，不是 metadata 列名字符串；输入表还必须先转成 LEfSe 格式。 |
| 13 | RDA 当前 `decostand(t(mat),...)` 的方向应核查；`vegan` 群落矩阵应是行=样本、列=特征，并保证环境表顺序一致。 |
| 14 | NMDS 的 `vegdist(dat)` 输入方向需要修正，且代码中 `meta` 必须先实际读入并按样本 ID 排序。 |
| 15 | 不应把 SparCC 与 SPIEC-EASI 都概括成偏相关；也不要把网络拓扑中心性直接等同于生态学 keystone taxa。 |
| 16.4 | PICRUSt2 需要明确使用 ASV 支线；NSTI 是预测置信度参考，不等于真实功能测量。 |

---

## 五、从 CHM DOCX 复制方法时要特别标出的限制

1. **软件版本不同：** 你的 Typst 教程固定 QIIME 2 2024.2，而 CHM 稿件 Key Resources Table 写的是 QIIME 2 2026.04。研究设计/方法原理可借鉴，所有命令参数必须在 2024.2 环境中通过 `--help` 实际核验。
2. **测序策略不同：** CHM compendium 因为混有单端和双端研究，只使用 forward/R1 reads。你的常规双端单项目流程不应照搬为只用 R1；应按数据类型选 `denoise-paired` 或 `denoise-single`。
3. **抽平深度是研究特定选择：** 稿件 UniFrac 的 sampling depth = 1,000 reads 不应写成普遍推荐值。
4. **QC 阈值是项目规则：** 30% 样本 chimera rate >25%、零 mapping 样本排除、队列整体 mapping rate <70% 是该跨队列 compendium 的纳入规则，不是统一行业标准。
5. **ASV 和 OTU 分支不能混用：** 稿件的 PICRUSt2 用 quality-controlled ASV table；Alpha/Beta 使用 closed-reference OTU table。
6. **差异分析方法版本不同：** 稿件用 LinDA、MaAsLin2、ANCOM-BC2；Typst 当前写 MaAsLin3。可以同时介绍，但不能把两个版本写成同一软件或互换参数。
7. **采样单位/重复结构重要：** 多个研究整合时 BioProject 是重要批次/随机效应层级；同一个体跨部位/时间点的数据必须保留 SubjectID、timepoint 和 pairing 关系。

---

## 参考来源

- 你上传的 CHM 稿件：DADA2 → ASV 处理 → Greengenes2 99% closed-reference mapping、队列级 chimera/mapping QC、OTU 表用于 Alpha/Beta、ASV 表用于 PICRUSt2、差异分析、网络、纵向配对与 SourceTracker2 方法。
- QIIME 2 2024.10 的 q2-vsearch OTU clustering 文档（可用于确认 DADA2 输出作为 closed-reference 输入的接口逻辑；你的 2024.2 环境仍需本机 `--help` 核验）：https://docs.qiime2.org/2024.10/tutorials/otu-clustering/
- Greengenes2 2024.09 官方文件索引：https://ftp.microbio.me/greengenes_release/2024.09/
- q2-greengenes2 官方说明：https://github.com/biocore/q2-greengenes2/
