# 《16S rRNA 扩增子生信分析全流程（QIIME 2 2024.2）》教程全面排查报告（第 2 轮）

> 审计对象：`/home/yanglun/YSD/YL-research-project/index.typ`（当前 1986 行，2026-11-26 版本）。
> 本轮与上一轮的差别：你在上一轮修复后又新增了两处内容（开头的 4 幅流程图、§0.6「三类核心文件解读」、§6 开头的 q2-diversity 动作/指标表），并把第 1 行改回了从 `../index.typ` 导入模板。
> 本报告**自洽完整**：既列出本轮新发现/新引入的问题，也复核了全文既有内容的存活情况。已用 QIIME 2 2024.2 源码（q2-diversity 2024.2.0 tag、qiime2 framework 2024.2.0 tag）与官方 stable 文档逐条核实关键论断。

---

## 一、P0：会导致 Typst 直接编译失败的三个问题

### 1. 第 1 行模板导入路径不存在（编译第一步就断）

```typst
#import "../index.typ": template, tufted
```

- `/home/yanglun/YSD/index.typ` **不存在**（`YSD` 目录树下没有任何 `.typ` 文件）。
- 且 `tufted` 从未被使用；`template` 也只在第 1 行被 import 后即用。
- 你此前那版内联定义是能编译的，这次改回相对导入后整个文件无法编译。

**建议二选一**（推荐 A）：

```typst
// ── 方案 A：直接内联（最省事，单文件自洽）────────────────────────
#let line() = rect(width: 100%, height: 0.7pt, stroke: gray.lighten(50%))

#let template(title: "", description: "", date: none, lang: "zh", body) = {
  set document(title: title, description: description)
  set text(lang: lang, size: 10.5pt)
  set par(justify: true, leading: 0.65em)
  set heading(numbering: none)
  body
}

#import "@preview/tablem:0.3.0": *
#show: template.with(title: "16S rRNA 扩增子生信分析全流程（QIIME 2 2024.2）", ...)
```

```typst
// ── 方案 B：真要外置模板，就先建一个真实存在的模板文件 ──────────
//     /home/yanglun/YSD/YL-research-project/theme.typ
// 内容放 line() 与 template() 的定义，然后：
#import "theme.typ": template, line
```

### 2. 四幅 `#figure(image(...))` 引用的图片全部不存在

```
#figure(image("imgs/00-pipeline-overview.png"), ...)          ← 18–21 行
#figure(image("imgs/amplicon-workflow-xiaoqizheng.png"), ...) ← 23–26 行
#figure(image("imgs/qiime2-principle-fig1.png"), ...)         ← 28–31 行
#figure(image("imgs/qiime2-provenance-fig2.png"), ...)        ← 33–36 行
```

- 目录树里**没有 `imgs/` 目录**，四个 `.png` 一个都不存在 → 编译在第一个 `image()` 就报错。
- 处置建议（按优先次序）：
  a. **把图先补齐**：图 2 可直接从 xiaoqizheng《QIIME2 笔记》截图；图 3/图 4 来自微信文章《QIIME 2：可重复、交互和扩展的微生物组数据分析流程》（链接已核实有效）。图 1 需要自己画（建议用 drawio / BioRender，输出 PNG ≥300 dpi 或直接 SVG/PDF 矢量图——论文图用矢量更稳）。
  b. **图片未就位期间先注释掉这四个 figure 块**，或改用占位符 `#figure(place(#box(width: 100%, height: 8cm, stroke: 1pt gray)[图待补]))`，保证现在能编译出稿。
- 转载他图注意版权：图 2、3、4 都来自他人文章，caption 里已写来源（好），建议再确认原文允许转载（多数公众号文章转载需授权），或在文尾「一点说明」中补充声明。

### 3. 正文与图注里的方括号会被 Typst 吞掉

- 第 20 行（图 1 caption）与第 167 行（主线描述）中：

```typst
… → [Greengenes2 99% closed-reference → OTU 表] → …
```

- 在 Typst markup 里，`[...]` 是**嵌套 content block**，不是括号字符：编译输出里这对方括号**会被静默删掉**，只剩括号内的文字。两处的「方括号一段是跨研究主线」的视觉强调会完全丢失。
- **修法**：转义括号 `\[Greengenes2 99% closed-reference → OTU 表\]`，或改用其他强调（加粗/括注）。注意：这仅限出现在 markup 正文/图注里的两处（第 20、167 行）；代码块和 `` `…` `` 里的方括号不受影响。

---

## 二、P1：本轮新增章节中的实质性内容错误

### 4. §0.6「③ 物种注释」TSV 示例少了一列（Taxon 列丢失）

当前是（246–250 行附近）：

```text
Feature ID	Taxon	Confidence
d__Bacteria;p__Firmicutes;...;g__Prevotella	0.99
d__Bacteria;p__Bacteroidetes;...;g__Bacteroides	0.98
```

表头三列，数据行却只有两列：**Taxon 列被丢了**，且把分类谱系字符串放到了「Feature ID」的位置。这正好会让初学者弄反 0.6 反复强调的「行 = feature」。应为：

```text
Feature ID	Taxon	Confidence
4b0e4a3b01c…	k__Bacteria;p__Firmicutes;…;g__Prevotella	0.99
7f2c9d1a8e0…	k__Bacteria;p__Bacteroidetes;…;g__Bacteroides	0.98
```

若主线用 GG2 backbone ID，Feature ID 用其真实 ID；若演示 collapse 后的表，Feature ID 那列才是分类串。两种写法应分开示意，别混在同一个示例里（见第 5 条）。

### 5. §0.6「① 特征表」BIOM TSV 示例把「合并后的分类名」当成了「原始特征 ID」

当前示例（211–216 行附近）：

```text
# Constructed from biom file
#OTU ID	S1	S2	S3
d__Bacteria;p__Firmicutes;...;g__Prevotella	120	0	45
```

- `taxa collapse` **做之前**，feature ID 是十六进制哈希/序列 ID，**不是**分类字符串；示例却直接用分类串当行名，与旁边「行 = 特征（首列是特征 ID）」的定义相矛盾。
- 正文 5.1/4.5 又专门讲过「collapse 后 ID 变分类名、别再当 ASV ID 用」。建议示例改成两段：

```text
# 原始特征表（collapse 之前；#OTU ID 列是真实的 feature ID）
# Constructed from biom file
#OTU ID	S1	S2	S3
b5f0b7e7a37b6094…	120	0	45
4b0e4a3b01c1d2e3…	30	88	12
```

```text
# 属水平合并后的表（collapse --p-level 6 之后；ID 变成拼接分类名）
# Constructed from biom file
#OTU ID	S1	S2	S3
d__Bacteria;p__Firmicutes;c__Clostridia;…;g__Prevotella	120	3	45
```

并各配一句「这是哪一个阶段的表」。

### 6. §0.6 谱系前缀 `k__` 与示例/主线用的 `d__` 不一致（小但易混）

- 253 行写「七级谱系 `k__/p__/c__/o__/f__/g__/s__`」，而示例与 GG2 backbone 用的域前缀是 `d__`（第 213、248 行的 `d__Bacteria`）。
- 事实：Greengenes2 / SILVA 138.1 的谱系用 `d__`（domain）开头；老 Greengenes 13_8 / 旧 SILVA 用 `k__`（kingdom）。建议把正文改成 `d__/p__/c__/o__/f__/g__/s__`，加一句「旧库（GG13_8、旧 SILVA）里第一级是 `k__`，看到即知是旧版本谱系」——这还能顺带教读者识别库版本。

### 7. §6.1 指数表「Pielou 均匀度」的 QIIME 2 名称写错了（本轮源码级核实）

6.1 表（866 行）写 QIIME 2 名称 `pielou_evenness`。**在 QIIME 2 2024.2 里这是错的**（已核对 q2-diversity 2024.2.0 源码与官方 stable 文档）：

- `qiime diversity alpha --p-metric` 的合法取值是 **`pielou_e`**（`simpson_e`、`goods_coverage`、`chao1`、`observed_features`、`shannon`、`margalef` 等同理可查 `--help`）。
- `core-metrics` / `core-metrics-phylogenetic` 输出的 artifact 名是 **`evenness_vector.qza`**、结果表列名是 **`evenness`**（源码 `_core_metrics.py`：`('evenness_vector', SampleData[AlphaDiversity])`，描述为 "Vector of Pielou's evenness values by sample"）。
- `pielou_evenness` 传给 `--p-metric` 会直接报 *metric not found* 一类错误。

你新加的 §6 开头指标清单里写 `pielou_e` 是**对的**；把 6.1 表统一改成：

```
| Pielou 均匀度 | `pielou_e`（命令用名；core-metrics 输出列名为 `evenness`，即 evenness_vector.qza） | 均匀度 | 越接近 1 越均匀 |
```

顺带把 6.3/6.1 里 `for idx in shannon observed_features faith_pd evenness` 的循环写成对应 `*_vector.qza` 的文件名（这段本来就是对的，别被改乱）。

### 8. §0.6 元数据首列 `#SampleID` 的说法——核实无误，但建议主推 `sample-id`

已核对 QIIME 2 2024.2 框架源码（`qiime2/metadata/base.py`）：合法 ID 列名包括——

- 大小写不敏感：`id`、`sampleid`、`sample id`、`sample-id`、`featureid`、`feature id`、`feature-id`；
- 精确匹配（向后兼容）：`#SampleID`、`#Sample ID`、`#OTUID`、`#OTU ID`、`sample_name`（Qiita）。

所以 0.6 与 0.2 写「`#SampleID` 或 `sample-id`」**都对、都能过校验**。建议：正文主推 `sample-id`（官方文档的现行写法、最不会踩坑），`#SampleID` 标注为「QIIME 1/BIOM 兼容写法，同样被接受」。

---

## 三、上一轮修复内容的存活核查（结论：全部健在，注意别回退）

逐章复核了全文（0.1–17、附录 A–F、参考文献），上一轮应用的所有修正**仍然在文件里**，关键项抽查确认：

| 位置 | 已修复内容 | 存活 |
| :--- | :--- | :--- |
| 0.2 | manifest.tsv TSV V2 三列格式 | ✅ |
| 0.3/0.4 | 关键文件表（taxonomy-gg2 = backbone.tax 复制生成等） | ✅ |
| 0.5 | metadata 质控 + Batch 入表 | ✅ |
| 1.2 | 引物长度 bp 计数 + 新旧 V4 引物提示 | ✅ |
| 2 节 | trim-left 19/20、`L_overlap = L_F + L_R − L_amplicon ≥ 12` 公式块、V3–V4 重算警告 | ✅ |
| 2.1 | R-DADA2（`dadaRs`、`makeSequenceTable`、`removeBimeraDenovo`） | ✅ |
| 3.2 | filter-samples `--p-where` 定位段落 | ✅ |
| 4.5 | `cp 2024.09.backbone.tax.qza taxonomy-gg2.qza`、cr99-l6-demo、classify 参数表、`gg_2022_10_backbone.v4.nb.qza` | ✅ |
| 5.1/5.2 | `taxonomy-gg2.qza`、collapse ID 注 | ✅ |
| 6.0 | GG2 参考树 wget（`2024.09.phylogeny.md5.nwk.qza`）、无 backbone 树提示 | ✅ |
| 6.1 | Gleason 离散变体注、抽平深度敏感性 | ✅ |
| 7.2 | 伪 F/R²（`qiime diversity adonis`）、PERMDISP/betadisper | ✅ |
| 8.1 | iqtree + `midpoint-root`、SEPP/GG2 参考树说明 | ✅ |
| 12.1–12.3 | ancom 无协变量、ancombc `--p-adj-method BH`、LEfSe 参数归属、SparCC bootstrap 两步、MaAsLin3/ANCOMBC 非 CRAN | ✅ |
| 15 章 | SparCC 镜像/FastSpar、microeco、Zi–Pi 表述 | ✅ |
| 16.4 | PICRUSt2 full-pipeline、预测 vs 测量、SourceTracker2 前提 | ✅ |
| 17 章 | LOSO、NetMoss、r.squaredGLMM | ✅ |
| 附录 A–F | py38 2024.2 清单、分类器 sklearn URL、Biom 注释行读法、`list-types/list-formats`、fasterq-dump `--threads`、biom `--header-key`、v1.3.7 FAPROTAX 参数、view.qiime2.cn 证书 | ✅ |
| 参考文献 | docs.qiime2.org per-release 404、Zenodo 存档、SparCC 镜像、OTU clustering 新路径、MaAsLin3 刊名 | ✅ |

**唯二例外**就是本报告第一、二部分列出的新引入/新写错项：第 1 行导入、四幅图、两处方括号、§0.6 两处示例、6.1 Pielou 命名——修复时请勿顺手回退其他段落。

---

## 四、本轮已逐条核实无误的新增论断（可放心保留）

1. **§6 开头的 q2-diversity 动作表（803–815 行）**：动作名全部正确——`core-metrics`、`core-metrics-phylogenetic`、`alpha`、`alpha-phylogenetic`、`beta`、`beta-phylogenetic`、`alpha-group-significance`、`beta-group-significance`、`alpha-rarefaction`、`pcoa`、`pcoa-biplot`、`mantel`、`procrustes-analysis` 均存在于 q2-diversity（stable 文档 + 2024.2 源码目录 `_ordination.py`/`_procrustes.py` 一致）。
2. **`beta-group-significance --p-method` 取值**：`('permanova', 'anosim', 'permdisp')`，与表格写法完全一致（2024.2 源码核对）。
3. **β 指标拼写 `braycurtis`**：`qiime diversity beta --p-metric` 用 scikit-bio 拼写 `braycurtis`（无下划线）；`bray_curtis` 只出现在 core-metrics 的**输出文件名**（`bray_curtis_distance_matrix.qza` 等）。表格里区分这两种语境是对的，建议再补一句明示（见第七部分建议 3）。
4. **α 指标名**：`shannon`、`simpson`、`chao1`、`observed_features`、`faith_pd`、`goods_coverage`、`pielou_e`、`margalef`、`simpson_e` 等均在 2024.2 的合法 metric 集内（`qiime diversity alpha --p-metric` Choices 已核对）。
5. **mantel / procrustes 的输入**：`mantel` 吃两个 `DistanceMatrix`；`procrustes-analysis` 吃两个 `PCoAResults`（排序坐标），表格「距离矩阵(×2) / PCoA(×2)」表述正确。
6. **微信文章链接**：`https://mp.weixin.qq.com/s/gz2G4RQ3IBF21AYrPRQdIA` 有效，标题即《QIIME 2：可重复、交互和扩展的微生物组数据分析流程》，与图 3/图 4 caption 所引一致。（注意：它与参考文献「微信公众号系列（9 篇）」里的 `kAw1y_MXEhFAXzK5ZpZFWA`《QIIME 2 基础流程》是**不同的号/文章**，二者并存不算错误，但建议把这第 10 篇补进参考列表分组，避免读者以为链接笔误。）
7. **xiaoqizheng 教程链接**：HTTP 200，有效。
8. **§0.6 其余论断**：特征表/元数据/注释的行列方向、vegan 转置陷阱、`skip = 1` 读 BIOM、`Confidence` 仅 classify-sklearn 输出、collapse 后 ID 变分类名——全部正确。
9. 10.1–17 章与附录各段中此前修复的命令/参数（`diversity pcoa`、`core-metrics` 输出四矩阵、`evenness` 循环、`adonis` 用法、iqtree、SparCC/FastSpar、full-pipeline 等）与 2024.2 行为一致。

---

## 五、P2：呈现与排版建议（主要针对四幅新图）

1. **图编号统一**：现在 caption 里出现「附图1」「图2」两种口径（图 3、4 引用的原文编号）。建议正文用自动编号：
   ```typst
   #set figure(gap: 1.2em)
   // caption 内不再手写「附图1」这类编号，让 #figure 自动出「Figure 1」
   ```
   并把原文自带编号改为「（转载自…图 1）」的括注形式。
2. **图 1 caption 过长**（约 160 字一句话），拆成两句：流程链 + 一句「据参考资料与 BMKCloud 分析框架整理」。
3. **正文引用图片**：目前 4 幅图在开头却无任何正文引用。建议 §0 开头加一句「全流程见图 1；QIIME 2 的数据承载与 provenance 机制见第 3、4 幅图，对应 0.1 节」。
4. **`tufted` 导入残留**：第 1 行 import 里的 `tufted` 没有任何使用（若按方案 A 内联即可删掉）。同理检查未用的 `@preview/tablem` 以外的包。
5. **图片资源管理**：建议建 `imgs/README.md`，记录每张图的来源 URL、抓取日期、许可（他人文章需授权转载）、重绘工具；这样日后换站点/换版本可追溯。
6. **图 2/3/4 是位图截图**：若来源是矢量图（公众号图多为位图），尽量重绘或用高分辨率（≥2× 显示宽）；图 1 是自绘流程图建议直接画成 SVG/PDF。
7. **`#link` 在 caption 内**：四幅图 caption 含链接，视觉上会让图注很长；可以把「来源」合并成一条短链或脚注。

---

## 六、P2/P3：继续完善教程的可选增量（上一轮遗留 + 新增）

上一轮报告中这些「建议加新内容」的项仍未做，按价值排序：

1. **端到端完整示例**（价值最高）：用文末提到的拟南芥根际 18 样本测试数据（CRA002352）从头到尾跑一遍主线，把每一步的真实输出（样本保留数、去噪保留率、mapping 率、抽平深度选择过程）做成一张「数字结果表」附在文末或做成独立 walk-through 章节。读者按此可自检自己每步结果是否在合理范围。
2. **三代全长 16S（PacBio/ONN→ONT）一节**：CCS/lima/isoseq → 拼接为全长 → 直接 denoise；引物/分类器/树的策略与短读长不同，0.1 节既然声明「不覆盖」，就值得给一页「三代流程速览 + 参考文献」当出口。百迈客 v2.6 的 CCS/lima 参数（已在参考文献列表）可作素材。
3. **多队列合并（merge/collate）一节**：`qiime feature-table merge`（merge-seqs）/ `qiime metadata merge`？准确说：多项目合并用 `qiime feature-table merge` + `merge-taxa`（同命名空间时）或走 GG2 closed-reference 强制统一特征空间（本文 4 章主线）；再补 metadata 纵向合并（R 里 `rbind` + Batch/Study 列）与批次效应评估（PERMANOVA strata、`deseq2`? 否——用混合模型/adonis strata）。与 17.4 呼应成节。
4. **表格与公式编号**：全文 `#tablem` 众多而无编号，交叉引用只能靠「6.1 的表」这样的说法。建议关键表格加 `caption` + `#table numbering`。
5. **§0.6 加一个「三表对齐自检」代码块**（顺着新增章节的自然收尾）：
   ```r
   # 对齐自检：三张表共用同一套 feature ID / sample-id
   stopifnot(identical(rownames(asv), rownames(tax)))    # 特征表行 ↔ 注释行（collapse 前）
   stopifnot(identical(colnames(asv), rownames(meta)))   # 特征表列 ↔ 元数据行
   setdiff(rownames(asv), rownames(tax))                 # 差集应为空
   ```
6. **§6 动作表后加一句防背书声明**：「各动作的 `--p-metric` 取值集合随版本变化，用 `qiime diversity alpha --help` / `beta --help` 现查，别背清单」——现在表下已有类似句，但可移进表格说明行更醒目。
7. **`braycurtis` vs `bray_curtis` 语境注**：在 §6 指标清单或 7.1 转换表处加一句：「`--p-metric braycurtis`（scikit-bio 拼写，命令用）；`bray_curtis_distance_matrix.qza`（core-metrics 输出文件名）——两种拼写分别属于命令参数与产物命名，别混写」。
8. **图与 0.3/0.4 文件名口径核对**：补画图 1 时，流程图节点名建议直接用正文固定文件名（`table-asv.qza`、`table-gg2-cr99.qza`、`taxonomy-gg2.qza`…），图与文一一对齐，避免读者对不上号。
9. **（小）0.4 关键文件表可加「生成自哪一节」列**，与 0.6 的「用途」互补，方便查表回跳。

---

## 七、修复优先级总表

| 级别 | 项 | 位置 | 概要 |
| :--- | :--- | :--- | :--- |
| **P0** | 1 | 第 1 行 | `#import "../index.typ"` 路径不存在 → 换内联 template 或建 theme.typ |
| **P0** | 2 | 18–36 行 | 4 幅 `imgs/*.png` 全部缺失 → 补图或先注释/占位 |
| **P0** | 3 | 20、167 行 | markup 里的 `[...]` 被吃掉 → `\[...\]` 或改强调方式 |
| **P1** | 4 | §0.6 ③ | taxonomy TSV 示例缺 Taxon 列、Feature ID 放了分类串 |
| **P1** | 5 | §0.6 ① | BIOM 示例把合并后分类名当原始特征 ID，分两阶段重写 |
| **P1** | 6 | §0.6 ③ | `k__` → `d__`（加新旧库前缀说明） |
| **P1** | 7 | §6.1 表 | `pielou_evenness` → `pielou_e`（命令名）；core-metrics 输出名 `evenness` |
| **P2** | 8 | §0.6/0.2 | 主推 `sample-id`，`#SampleID` 标为兼容写法（核实后两者均可用，非错误） |
| **P2** | 五.1–7 | 18–36 行 | 图编号/caption 长度/正文引用/版权/资源管理 |
| **P2/P3** | 六.1–9 | — | walkthrough、三代 16S、多队列合并、表格编号、自检块、语境注 |

**核实无误、无需修改的清单**：§6 动作表与全部 metric 拼写（`braycurtis`/`pielou_e` 等）、`--p-method permanova/anosim/permdisp`、mantel/procrustes 输入类型、微信 gz2G4… 链接与标题、xiaoqizheng 链接、metadata 首列 `#SampleID`/`sample-id` 的合法性、§0.6 的行列方向与 ID 对齐论述，以及第三部分列出的全部既有修复。

---

## 附：本轮核实所用的一手依据

- QIIME 2 framework 2024.2.0 源码 `qiime2/metadata/base.py`：`SUPPORTED_ID_HEADERS`（确认 `#SampleID` 精确匹配、`sample-id` 大小写不敏感均接受）。
- q2-diversity 2024.2.0 源码：`_core_metrics.py`（evenness_vector/Shannon/observed_features/faith_pd 输出命名）、`plugin_setup.py`（beta-group-significance 的 `('permanova','anosim','permdisp')`；procrustes-analysis 输入为 `PCoAResults`；pcoa/pcoa-biplot/mantel 注册）、`tests/test_beta.py`（`metric='braycurtis'`）、`tests/test_alpha_rarefaction.py`（`metrics=('observed_features','shannon','pielou_e')`）。
- 官方 stable 文档 diversity 插件参考页（docs.qiime2.org/en/stable/references/plugins/diversity/）：α/Bβ metric 全集（`braycurtis`、`aitchison`、`jensenshannon`、`euclidean`、`pielou_e`、`simpson_e`、`goods_coverage`…）。
- WeChat 文章抓取：`gz2G4RQ3IBF21AYrPRQdIA` → 《QIIME 2：可重复、交互和扩展的微生物组数据分析流程》（og:title 核对）。
