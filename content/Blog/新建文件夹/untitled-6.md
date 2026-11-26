# 《16S rRNA 扩增子生信分析全流程（QIIME 2 2024.2）》教程排查报告

> - 审查对象：`/home/yanglun/YSD/YL-research-project/index.typ`（约 1686 行）
> - 审查日期：2026-11-26
> - 行号均指 `index.typ` 中的行号。
> - 分级说明：
>   - 🔴 **必须修正**：会让文档编译失败、流程跑不通、用到不存在的参数，或直接导致错误结论；
>   - 🟠 **建议修正**：技术表述有误/易误导、代码有隐患；
>   - 🟡 **一致性与细节**：前后不一致、命名不统一、交叉引用错位；
>   - 🔵 **补充完善建议**：可选但能明显提升教程质量的增补项（按章节给出具体写法）。

---

## 一、🔴 编译层面硬伤（文档当前无法编译）

### 1. `#import "../index.typ"` 指向不存在的文件
- 位置：`index.typ:1`
- 问题：第 1 行 `#import "../index.typ": template, tufted` 所指的 `/home/yanglun/YSD/index.typ` **不存在**（已核实）。
整个文档没有任何 `template` / `tufted` / `line()` 的定义来源。
- 后果：Typst 编译在第一行即报 `file not found`；正文里的 `#show: template.with(...)` 与全文多处 `#line()` 全部失效。
- 修法：确认这个 `.typ` 是从博客模板仓库拷出来的，把真正的模板 `index.typ` 一并放到上
级目录（或本项目内改用 `#import "template.typ": ...`），或者把 `template`、`line()`、
`tufted` 的定义内联进本文件。

### 2. `tufted` 导入但从未使用
- 位置：`index.typ:1`
- 问题：`tufted` 在正文中从未出现（只用了 `template` 与 `tablem` 的 `#tablem`），属于无
用导入。
- 修法：要么删掉 `tufted`，要么在正文使用。

### 3. 流程图 `imgs/00-pipeline-overview.png` 不存在
- 位置：`index.typ:21`
- 问题：项目里没有 `imgs/` 目录（已核实），`image("imgs/00-pipeline-overview.png")` 编
译时报错。
- 修法：补图，或先用文字流程示意占位；同时检查 `.gitignore` 是否把图片目录排除（这样
即使本地有图也不会进仓库）。

---

## 二、🔴 技术性错误（流程跑不通 / 结论错误 / 参数不存在）

### 1. "官方 V3–V4 预训练分类器"并不存在
- 位置：`index.typ:1434`（附录 B 最后一段）
- 原文："必须换成 V3–V4 引物重新截取参考后再训练，或直接用官方 V3–V4 预训练分类器。"
- 问题：QIIME 2 官方 data-resources 的预训练分类器只有 515F/806R（`silva-138-99-515-806-nb-classifier.qza` 等），**没有官方 341F/806R（V3–V4）预训练分类器**。官方论坛对 341F/806R 数据的推荐正是"自己用 `extract-reads` 训练"，与本教程附录 B 的命令一致——那半句"或直接用官方 V3–V4 预训练分类器"应删除。
- 另注：官方 515-806 分类器在 ~2021 年后重新训练过（训练序列带引物区）；下载时按当前
QIIME 2 的 sklearn 版本选 URL（`https://data.qiime2.org/classifiers/sklearn-1.4.2/...`
形式），旧版链接不能与新版环境混用。

### 2. PCA 的"等价写法"其实不等价
- 位置：`index.typ:973`
- 原文（代码注释）："等价写法：`prcomp(decostand(comm, "hellinger"), scale. = TRUE)`"
- 问题：`rda()` 无约束时默认**只中心化、不按变量缩放**（协方差型 PCA）；`prcomp(..., scale. = TRUE)` 是把每个特征缩放到单位方差（相关型 PCA），结果不同。已用 vegan + varespec 数据数值验证：`rda(H~1)` 等于 `prcomp(H, scale.=FALSE)`；`rda(H~1, scale=TRUE)` 才等于 `prcomp(H, scale.=TRUE)`。
- 修法：改成 `# 等价写法：prcomp(decostand(comm, "hellinger"), center = TRUE, scale. = FALSE)`，并补一句"若用 scale.=TRUE 得到的是相关型 PCA，等价于 rda(..., scale=TRUE)，与 rda 默认结果不同"。

### 3. Gleason 多样性指数公式写错
- 位置：`index.typ:719`
- 原文：`Gleason    R  = S / ln(A)          # A 为个体数或样本数`
- 问题：两种"标准"在文献里并存、必须注明约定：（1）Gleason (1922) 的种-面积关系原始形
式确为 `d = S/ln(A)`（A=抽样**面积**）；（2）16S/多样性手册语境常用的离散变体是
`(S − 1)/log₂(N)`（Margalef `(S−1)/ln N` 只差对数底）。教程写 `S/ln(A)` 而注释"A 为个
体数或样本数"是含混的——计数数据没有"面积"，以 N 代 A 后分子应为 S，与 Margalef 差
"减 1"的偏移，读者极易把它当 Margalef 的另一种写法直接套算。
- 修法：统一为 `Gleason  R = (S − 1) / log₂(N)` 并加注"另有种-面积关系原始形式 S/ln(A)
（A=面积），两者不可混用"；或删掉该行（Margalef 已能代表对数型丰富度指数）。

### 4. 分支 B 的 trim-left 20/20 与 1.2 节引物长度对不上
- 位置：`index.typ:299-302`
- 问题：1.2 节的引物 341F 长 17 bp（`CCTACGGGNGGCWGCAG`）、805R 长 21 bp
（`GACTACHVGGGTATCTAATCC`），trim-left 应为 **17/21**；分支 B 写 20/20。正文还说
"515F 约 17–19 bp"，实际两种 515F 变体都是 19 bp（17 bp 是 341F）。
- 修法：分支 B 拆成两套注释：V3–V4 → trim-left 17/21；V4 → 19/20（806R 20 bp）；并强
调"以你实际引物长度为准"。

### 5. 示例 250/230 截断若用于 V3–V4 会直接拼不上
- 位置：`index.typ:291`、`index.typ:302`
- 问题：V3–V4 扩增长度 ≈460 bp 时，`--p-trunc-len-f 250 --p-trunc-len-r 230` 加
trim-left 20 后有效长度 230/210，重叠区 = 230+210−460 = **−20 bp**，`denoise-paired`
会大面积 merge 失败（用正文自己给出的 `L_overlap = L_F + L_R − L_amplicon` 一验即知）。
250/230 只适合 V4 单区。
- 修法：按"扩增区"分别给出示例（V4：250/230；V3–V4：如 280/210 或按你的质量图定），
并让读者代入自己的 `L_amplicon` 做自检。

### 6. ANCOM 示例结论前后矛盾（属水平 vs ASV）
- 位置：`index.typ:1043`
- 原文："ANCOM 在属水平只检出 *1 个*差异显著类群（*Pleomorphomonas* 属的一个 ASV）"
- 问题：输入是 `table-gg2-l6.qza`（属水平 collapsed 表），特征 ID 就是属级类群，不可能
再是"一个 ASV"。
- 修法：改为"属水平表中检出 1 个显著差异属"。已联网核对原始出处（刘永鑫等
《利用 QIIME 2 分析微生物 16S rRNA 基因扩增子序列》Bio-protocol 2019;9(6):e3197，
DOI `10.21769/BioProtoc.3197`）：其结果是属水平差异（*Pleomorphomonas*），
并非"一个 ASV"——确认为笔误。
- 另核对：该教程测试数据是拟南芥根际 18 个样本；本文 `index.typ:1665` 写"3 组 × 6 =
18 样本"，与 Bio-protocol 原文描述（对照生长箱 vs 盐胁迫根际，两处理、多批次）不完全一
致，建议按原文再核对一次分组数。

### 7. `table-filtered.qza` 生成后从未被使用
- 位置：`index.typ:379-392`
- 问题：3.2 生成了 `table-filtered.qza`，但 4.2 映射的输入仍是未过滤的 `table-asv.qza`
，下游全部走 `table-gg2-cr99.qza` → `table-clean.qza`，`table-filtered.qza` 再没出现。
- 修法：明确它的定位（ASV 支线常规操作；cr99 主线映射前可选使用，并报告是否过滤）。

### 8. `table-gg2-l6.qza` 重复创建且两次输入不同
- 位置：`index.typ:551-556`（4.5，从 `table-gg2-cr99`）与 `index.typ:626-636`（5.1，从
`table-clean`）
- 问题：同名产物两处生成，一个未去线粒体/叶绿体、一个已过滤；两段都跑则 5.1 覆盖 4.5，
内容不一致。
- 修法：4.5 只示范用法并用临时名；正式 `table-gg2-l6.qza` 只在 5.1 生成。

### 9. `taxonomy-gg2.qza` 被引用但从未生成
- 位置：`index.typ:155`（0.4 关键文件表）、`index.typ:1459`（附录 C 导出）
- 问题：正文中注释始终直接用 `2024.09.backbone.tax.qza`，没有任何步骤产出
`taxonomy-gg2.qza`，但 0.4 表和附录 C 都要它。
- 修法：在 4.2/4.5 加一行说明（如 `cp 2024.09.backbone.tax.qza taxonomy-gg2.qza` 或直
接引用 backbone tax），并在 0.4 表中标注其来源。

### 10. 附录 C：`--show-importable-formats/types` 在 2024.2 已被移除
- 位置：`index.typ:1493-1497`
- 问题：`qiime tools import --show-importable-formats` / `--show-importable-types` 这两个
旗标在 QIIME 2 2024.2 中**已不存在**（已对照 q2cli 2024.2 源码核实；2024.2 的
`qiime tools import` 只有 `--type/--input-path/--output-path/--input-format/--validate-level`）。
- 修法：换成 2024.2 官方教程使用的等效命令：
  ```bash
  qiime tools list-types
  qiime tools list-formats --importable
  ```

### 11. QIIME 2 的 PERMANOVA 输出并不含 R²（多处正文口径错误）
- 位置：`index.typ:836`（"报告时同时给出 R²（解释度）与 P 值"）、`index.typ:843`（三检验
对比表中 PERMANOVA 行写"统计量 R²"）、`index.typ:863`（报告规范模板"R²=…"）、
`index.typ:1326`（16.2 "Beta 用 PERMANOVA（报 R²、P）"）
- 问题：2024.2 的 `beta-group-significance --p-method permanova` 底层是 scikit-bio 0.5.8
的 `permanova()`，输出仅含**伪 F 统计量、样本数、组数、P 值、置换次数**，没有 R²（已对
q2-diversity 2024.2 源码核实，2024.10 也未加入）。教程要求读者"同时报告 R²"，但 QIIME 2
这条命令给不出来，新手会卡在这里。
- 修法（三选一，正文需写清）：
  1. R² 用 `qiime diversity adonis`（封装 vegan::adonis，输出含 R²）拿；
  2. R 端 `vegan::adonis2(d_bc ~ Group, data=meta)`（教程 7.2 的 R 代码本来就给 R²，保
证口径一致）；
  3. 或把所有"PERMANOVA 报 R²"的句子改成"报告伪 F 与 P 值（R² 请用 `diversity adonis`
或 R 端 `adonis2` 计算）"。
- 顺带修正 843 行表格：QIIME 2 的 PERMANOVA 统计量是**伪 F**；"R²"仅属于
adonis/adonis2。

### 12. manifest 只支持 TSV，正文与附录 E 都写成 CSV
- 位置：`index.typ:347`（2.1 的 `--input-path manifest.csv`）、`index.typ:1538-1543`（附
录 E 生成 `manifest.csv` 用逗号分隔）
- 问题：manifest 导入格式（`PairedEndFastqManifestPhred33V2` 等 V2 格式）只解析**制表符
分隔**的文件（官方文档写明 "The manifest file is a tab-separated text file"；q2-types
解析器为 excel-tab 方言），CSV 逗号分隔不在支持之列（已核对 2024.2 文档与 q2-types 源
码）。
- 修法：附录 E 的 `printf` 改成 tab 分隔、文件名改 `.tsv`；2.1 的 `manifest.csv` 同样改
TSV。
- 另注（附录 E 小问题）：`PairedEndFastqManifestPhred33V2` 的三列**列名必须精确**为
`sample-id`、`forward-absolute-filepath`、`reverse-absolute-filepath`；首列表头写
`id`/`sampleid`/`sample id` 也兼容，但推荐与正文一致用 `sample-id`。

### 13. Deblur 机制描述错误（"85% Greengenes 相似度"不对）
- 位置：`index.typ:1509`
- 原文："Deblur 会丢弃与 85% Greengenes 相似度过低的序列，速度通常快于 DADA2"
- 问题：2024.2 文档原文是：Deblur 用 **Greengenes 13_8 的 88% OTU 集**做参考，仅通过
SortMeRNA 比对（宽松 e-value）判断"该序列是否可能是 16S"，本质是 **16S 正向过滤器**
（positive filter），不是"低于某个相似度阈值就丢弃"——85% 这个数字在官方文档中不存在。
- 修法：改为"Deblur 用 Greengenes 13_8 88% OTU 集做 16S 正向过滤（SortMeRNA 比对），
只保留疑似 16S 的序列；其他参数：`--p-trim-length` 必填、`--p-min-reads`（默认 10）、
`--p-min-size`（默认 2），只处理正向 reads"。

### 14. 参考链接：`docs.qiime2.org/2024.2/` 现已 404
- 位置：`index.typ:1612`
- 问题：QIIME 2 已将各版本（含 2024.2）的 per-release 文档下线，改为新文档站；旧文档全
部存档于 Zenodo（DOI `10.5281/zenodo.24082639`）。教程声称"以 2024.2 为准"，正文开头还
推荐读者看 `docs.qiime2.org/2024.2`，这个链接现在是坏的。
- 修法：参考列表加一行"2024.2 官方文档存档（Zenodo DOI 10.5281/zenodo.24082639）"，并
把"以官方 2024.2 文档为最终依据"的提示改为"以当前版本文档/`--help` 为准（旧版本文档已
归档）"。

### 15. `gg-13-8-99-515-806-nb-classifier.qza` 已不在 2024.2 官方推荐列表中
- 位置：`index.typ:1439`
- 问题：2024.2 data-resources 页明确宣布 Greengenes2 取代 GG 13_8，官方页面只列 weighted
GG 13_8 分类器与 **Greengenes2 的 `gg_2022_10_backbone.v4.nb.qza`**；旧的
`gg-13-8-99-515-806-nb-classifier.qza` 虽仍可从 `/2024.2/common/` 下载（实测存在），但已
属遗留资源。教程主线恰恰是 Greengenes2，这一行反而推荐了过时分类器。
- 修法：改为推荐 `gg_2022_10_backbone.v4.nb.qza`（Greengenes2 V4 分类器），并把
gg-13-8 标注为"遗留（legacy），仅兼容旧文献/PICRUSt 老流程时使用"。
- 加分项：既然主线用 Greengenes2 backbone，ASV 支线注释可同时给"SILVA 分类器（正文现
状）+ Greengenes2 分类器（与 backbone 口径一致）"两种方案并说明差别。

### 16. 附录 A：conda 发行版清单 URL 的 Python 版本写错
- 位置：`index.typ:1405`
- 原文：`wget https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.2-py39-linux-conda.yml`
- 问题：`py39` 路径实测 **404**；2024.2 的正确文件名是 **`qiime2-amplicon-2024.2-py38-linux-conda.yml`**（实测 302 → 200，解析到
`https://raw.githubusercontent.com/qiime2/distributions/dev/2024.2/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml`）。照抄附录 A 新手第一步就会失败。
- 修法：改 `py38`（并提醒后续版本 python 版本会变，2024.10 已是 py310；以 `data.qiime2.org` 当前页面为准）。

### 17. SparCC 命令演示的参数含义错误，且原仓库已失效
- 位置：`index.typ:1254-1261`（15.3）、`index.typ:1673`（参考链接）
- 问题：
  1. 原版 `python SparCC.py ... -i 10 -c sparcc_corr.txt -a sparcc_pvals.txt -x 100` 中
     `-a/--algo` 是**选算法**（SparCC/pearson/spearman/kendall），`-x/--xiter` 是剔除高相关对的迭代次数
     （默认 10），**都和 P 值无关**；把输出文件名传给 `-a` 会直接算错。
  2. P 值在 SparCC 里是独立两步：`MakeBootstraps.py` 生成置换表 → 对每个置换跑 SparCC →
     `PseudoPvals.py` 合成 P 值；没有一条命令能连算。
  3. 官方仓库 `bitbucket.org/yonatanf/sparcc` **已因长期不活跃被 Bitbucket 停用**（实测 404
     说明页）；`index.typ:1673` 的参考链接是坏的。
- 修法：
  ```bash
  # 原版 Python（镜像：github.com/TankMermaid/sparcc）
  python SparCC.py otu_table.txt -i 10 -c sparcc_corr.txt          # 只出相关
  python MakeBootstraps.py otu_table.txt -n 100 -t permutation_#.csv -p ./   # 置换
  # 对每个 permutation 表跑 SparCC 后：
  python PseudoPvals.py sparcc_corr.txt permutation_#.csv 100 -o sparcc_pvals.txt -t two_sided
  # 或直接用 C++ 重写版（更常用）：
  fastspar -c otu_table_counts.tsv -o sparcc_out -i 30
  ```
  参考链接补：FastSpar（`github.com/scwatts/fastspar`，bioconda 可装）、原版代码镜像
  `github.com/TankMermaid/sparcc`。

### 18. LEfSe：命令名与参数归属都需要改（`-f r` 的说法恰好说反了）
- 位置：`index.typ:1055-1063`（12.2）
- 问题（从 SegataLab/lefse v1.1.2 的 setup.py console_scripts 与脚本源码核实）：
  1. 当前版本命令名是 **`lefse_format_input.py`、`lefse_run.py`、`lefse_plot_res.py`**（教程
     用的 `run_lefse.py` / `plot_res.py` 是无前缀旧版名，装的不是新版时就直接报
     command not found；也不存在 `lefse-plot_res.py` 这种连字符写法）。
  2. 教程声称"`-f r` 是 `run_lefse.py` 的参数（输入按相对丰度处理）…别把它误放到
     `lefse_format_input.py` 上"——**正好弄反**：`lefse_format_input.py` 的 `-f c|r` 控制
     features 在行（r，默认）还是列（c）；而 `lefse_run.py` 自己的 `-f` 是 bootstrap 子采样
     比例（默认 0.67），把 `-f r` 传给 run 步会被静默当成 0.67。
  3. `lefse_run.py` 的 `-l`（LDA 阈值）**默认是 2.0**，`-l 4.0` 是显式选择（合法，但应说明默
     认值是 2.0）；其 `-c` 是 Curtis's approach 开关，**不是** class 列——class/subclass/subject
     的列号 `-c/-s/-u` 只属于 `lefse_format_input.py`（教程把 class 列说成第一列的用法是
     对的，但参数归属的说明要重写）。
- 修法（可用的三行模板）：
  ```bash
  lefse_format_input.py otu_table.txt otu.in -c 1 -o 1000000   # -c 1 = class 列
  lefse_run.py otu.in otu.res -l 4.0                            # 默认 -l 2.0
  lefse_plot_res.py otu.res lefse.png
  ```

### 19. 附录 B：R 端 `addSpecies` 的 SILVA 文件名错误
- 位置：`index.typ:1446`
- 原文：`addSpecies(taxa, "silva_v138.1_assignSpecies.fa.gz")`
- 问题：DADA2 的 SILVA 138.1 训练数据（Zenodo DOI `10.5281/zenodo.4587955`）中实际文件
  名是 **`silva_species_assignment_v138.1.fa.gz`**（79MB）；`silva_v138.1_assignSpecies...`
  是 v132 时代的旧命名，照抄会下载/引用失败。`silva_nr99_v138.1_train_set.fa.gz`（
  assignTaxonomy 用）是对的。
- 修法：
  ```r
  taxa <- assignTaxonomy(seqtab.nochim, "silva_nr99_v138.1_train_set.fa.gz", multithread = TRUE)
  taxa <- addSpecies(taxa, "silva_species_assignment_v138.1.fa.gz")  # 种水平精确匹配
  ```

### 20. 6.0 建树处让读者"直接用 GG2 参考树"却没给正确的文件名（backbone 没有树文件）
- 位置：`index.typ:690` 及 `index.typ:1680`（参考库链接）
- 问题：Greengenes2 2024.09 release 里**不存在** `2024.09.backbone.nwk` 或
  `…backbone.full-length.nwk`（实测 404）；可直接当作 UniFrac/Faith PD 树用的是
  **`2024.09.phylogeny.{md5,asv,id}.nwk(.qza)`**（README 推荐 16S/去噪表用 md5 版；
  `.nwk.qza` 已是 QIIME 2 artifact，无需再 import）。目前正文只有一句"优先下载/使用同版
  本参考树"，没有文件名，读者找不到。
- 修法（补命令）：
  ```bash
  wget https://ftp.microbio.me/greengenes_release/2024.09/2024.09.phylogeny.md5.nwk.qza
  # 直接作为 --i-phylogeny 用；或选 asv/id 版本
  ```
  同节确认：`2024.09.backbone.full-length.fna.qza` 与 `2024.09.backbone.tax.qza` 两个文件
  名教程写法正确（实测存在）。

### 21. 附录 E：`fastq-dump` 没有 `--threads` 选项
- 位置：`index.typ:1535`
- 问题：从 sra-tools 3.4.1 二进制里核实，fastq-dump 的参数集**不含 threads**（它是单线程
  设计）；`--threads`/`-e` 是 **fasterq-dump** 的选项。照抄会报 unrecognized option。
- 修法：改用 `fasterq-dump --split-3 --threads 8 <acc>.sra --outdir rawdata`（并给
  fastq-dump 作为兼容备选，去掉 `--threads`）。顺带：`prefetch --option-file` 全局选项确实
  存在、SRA runinfo CSV 接口 2026 年实测仍可用（这两处教程写法没问题）。

### 22. 附录 F：FAPROTAX `collapse_table.py` 的 `-c/-d` 语义需按当前版本修正
- 位置：`index.typ:1591`
- 问题（以官方最新 FAPROTAX 1.2.12 包内 `collapse_table.py` v1.3.7 的 argparse 实证）：
  1. `-c/--comment_prefix`（默认已就是 `'#'`）是**注释前缀**，不是"分类注释列"；写 `-c "#"`
     等于什么都没配；
  2. `-d` 在当前版本是 `--row_names_are_in_column`（行名列，按名或 0 起始索引）——旧版本
     它才是"分隔符"，`-d ";"` 在新版含义完全不同；
  3. 分类注释列应通过 `--row_names_are_in_column` 指定行名列所在位置（配合 `-c` 前缀识别
     注释行）。
- 修法：
  ```bash
  python collapse_table.py -i otu_table.txt -g groups.txt -o func.tsv \
    -c '#' --row_names_are_in_column taxonomy -v
  ```
  并注明"该命令对脚本版本（v1.2.x 与 v1.3.7）敏感，跑前先 `-h` 看本机版本"。

### 23. `view.qiime2.cn` 证书已过期
- 位置：`index.typ:42`、`index.typ:1522`
- 问题：该镜像站点仍解析且返回 QIIME 2 View 页面，但 TLS 证书已于 2024-10-28 过期（实测
  `SEC_ERROR_EXPIRED_CERTIFICATE`），主流浏览器默认会拒绝连接。
- 修法：加一句"镜像证书曾过期、浏览器可能警告"，或直接改推荐 view.qiime2.org +
  本地部署 view（`q2view`）。

### 24. `MuMIn::r2()` 这个函数不存在
- 位置：`index.typ:1377`（17.2："报告边际 R² 与条件 R²（`MuMIn::r2()`）"）
- 问题：本地实测 `exists("r2", asNamespace("MuMIn")) == FALSE`——MuMIn 里没有 `r2()`；
  正确函数是 **`MuMIn::r.squaredGLMM(fit)`**（对 lmer 模型返回 `R2m` 边际 / `R2c` 条
  件），或者用 **`performance::r2(fit)`**（= Nakagawa R²）。
- 修法：
  ```r
  MuMIn::r.squaredGLMM(mod)   # 读 R2m（边际）、R2c（条件）
  # 或 performance::r2(mod)
  ```

### 25. 参考链接与版本化 docs 路径批量失效
- 位置：`index.typ:1612`（2024.2 文档）、`index.typ:1682`（2024.10 otu-clustering）、
  `index.typ:1673`（SparCC bitbucket）
- 问题：docs.qiime2.org 的**所有版本化路径**（2022.10 … 2025.x）现已 404，只保留
  `/en/stable/` 与 `/en/latest/`；旧 otu-clustering 教程并入新 how-to：
  `https://docs.qiime2.org/en/stable/how-to-guides/cluster-reads-into-otus/`。
  SparCC bitbucket 已停用（见 17）。
- 修法：统一改为 `en/stable` 路径 + Zenodo 存档说明；geekdaxue 链接务必保留章节后缀（裸
  目录会 404，教程现链接带了章节，没问题）。

---

## 三、🟠 表述/代码有隐患（易误导或踩坑）

### 1. R 端 DADA2 代码片段缺一步，数值说法也不对
- 位置：`index.typ:324-340`
- 问题：
  1. 代码直接用 `seqtab`，但片段里没有 `seqtab <- makeSequenceTable(mergers)`，会报找
不到对象；
  2. "`truncLen=c(240,160)` 与 `--p-trunc-len-f/-r` 完全对应"——正文命令用的是
250/230，两者不对应；应改成"参数格式对应（向量顺序 F, R）"。
- 修法：
  ```r
  mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, verbose = TRUE)
  seqtab  <- makeSequenceTable(mergers)               # ← 缺了这一步
  seqtab.nochim <- removeBimeraDenovo(seqtab, method = "consensus", multithread = TRUE)
  ```

### 2.（复查后确认无误）7.1 "core-metrics-phylogenetic 四种距离矩阵"
- 位置：`index.typ:820`
- 结论：联网核实 2024.2 的 `core-metrics-phylogenetic` 默认确实输出 **4 种距离矩阵**
（unweighted_unifrac、weighted_unifrac、jaccard、bray_curtis）及对应 PCoA/emperor 图；
Alpha 默认为 faith_pd、observed_features、shannon、evenness。教程原表述正确。

### 2b. 但 4.1 节"QIIME 2 是否直接支持"处的一个细节
- 位置：`index.typ:751-757`（6.1 的循环）
- 检查：`alpha-group-significance` **没有** `--p-pairwise` 参数（它的可视化中自动计算
pairwise Kruskal–Wallis + FDR），教程循环里没传该参数，无误；注意别把 `beta-group-significance`
的 `--p-pairwise` 想当然挪过去。

### 3. SpiecEasi/SparCC 应喂计数，不要预先 relative-frequency
- 位置：`index.typ:1230`（15.2 第 1 步）
- 问题：流程第 1 步写"属水平相对丰度表（`taxa collapse` + `relative-frequency`）"，但
SPIEC-EASI/SparCC 都在计数（或 CLR）空间建模；spiec.easi 默认 `norm.method="prop"` 会自
己归一化，预先转相对丰度反而多余且丢失信息。
- 修法：改为"属水平**计数表**，由 SpiecEasi/SparCC 内部归一化与 CLR"。

### 4. 0.4 总览表把 `decorana` 放进 RDA/CCA 行
- 位置：`index.typ:137`
- 问题：`decorana` 做的是 DCA（排序诊断），不是 RDA/CCA 的代表命令。
- 修法：把 DCA 单独注明或在 13.1 独立成行。

### 5. 附录 C `--header-key taxonomy` 的前提没写
- 位置：`index.typ:1504-1507`
- 问题：仅当 BIOM 已含 taxonomy 观察元数据时有效；从纯 `FeatureTable` 导出的 biom 没有
注释，该参数会报错。
- 修法：补一句前提说明（或改从 collapsed 表导出）。

### 6. "见第 16 节的设计说明"承诺未兑现
- 位置：`index.typ:660`
- 问题：16.1 只有原则建议，没有可运行的 barplot 重绘代码。
- 修法：在 16.1 加 10–20 行 ggplot2 重绘骨架。

### 7. 附录 E 的 prefetch/fastq-dump 细节
- 位置：`index.typ:1534-1543`
- 问题：①（已核实，见二.21）`fastq-dump` 无 `--threads` 选项；②（已核实）SRA runinfo
CSV 接口与 `prefetch --option-file` 教程写法**正确**，无需改动；③`prefetch
--output-directory sra` 的产物通常是**扁平**的 `sra/<acc>.sra` 而非嵌套
`sra/<acc>/<acc>.sra`，此点未在官方文档固定承诺，建议按实际输出调整。
- 修法：改用 `fasterq-dump --split-3 --threads 8`；转换前先 `ls` 确认实际路径。

### 8. 共识模板里的 `MaAsLin2` 与本节 `maaslin3` 不一致
- 位置：`index.typ:1102`
- 问题：12.3 演示的是 `maaslin3`，末段却写"ANCOM-BC2 / LinDA / MaAsLin2（或 ALDEx2）"。
- 修法：统一命名或注明"MaAsLin2（稳定）/MaAsLin3（新版）均可"。

### 9. "短读长建树不可靠"与 cr99 主线自建树的表述打架
- 位置：`index.typ:690` 与 `index.typ:884`
- 问题：6.0 命令的输入 `rep-seqs-gg2-cr99.qza` 是 closed-reference 聚类的输出，其中代表
序列是**参考库的全长 16S**，不是 250–460 bp 短读长；用它 de novo 建树不踩"深层分支不可
靠"的坑。
- 修法：在 6.0/8.1 写清楚"短读长建树不可靠"只针对 ASV 支线；cr99 主线的 de novo 树用全
长参考序列，质量可用，GG2 参考树更省时且与 backbone 严格一致。

### 10.（已核查解决，结论并入二.18）LEfSe 参数归属与命令名问题
- 位置：`index.typ:1055-1063`
- 结论（从 SegataLab/lefse v1.1.2 setup.py 与脚本源码核实）：`-c`（class 列号）与
`-f c|r`（features 行/列布局，默认 r）都属于 **`lefse_format_input.py`**；教程把 `-f r`
说成 run_lefse 的参数、并声称"别把 `-f r` 放到 format_input 上"——**方向说反了**，实际
归 `-f r` 于 run_lefse 才会被静默误用（该 `-f` 是 bootstrap 子采样比例）。当前版命令名是
`lefse_format_input.py` / `lefse_run.py` / `lefse_plot_res.py`。详细修法见二.18。

### 11. "CHM 稿件"是读者无法理解的内部代称
- 位置：`index.typ:776`
- 修法：改成"（例如本文引用的某篇样本累积分析手稿）"或删除出处代称。

### 12.（已核查解决，结论并入二.22）FAPROTAX `collapse_table.py` 参数
- 位置：`index.typ:1591`
- 结论（以官方 FAPROTAX 1.2.12 内 collapse_table.py v1.3.7 argparse 实证）：`-c` 是**注释
前缀**（默认即 `'#'`），教程的 `-c "#"` 等于没配；`-d` 在当前版本是
`--row_names_are_in_column`（旧行名/注释列定位），教程的 `-d ";"` 在新版下含义错误。修法
见二.22。

---

## 四、🟡 一致性、命名与交叉引用问题

1. **1.5 节交叉引用错位**：`index.typ:238` 写"`taxa filter-table`（4.3 节）"，应为
**4.5**（3.3 的 `index.typ:397` 就写对了）。
2. **引物新旧版本前后不一**：1.2 给新版 515F-Y/806R（`GTGYCAGCMGCCGCGGTAA` /
`GGACTACNVGGGTWTCTAAT`），附录 B `extract-reads` 用旧版（`GTGCCAGCMGCCGCGGTAA` /
`GGACTACHVGGGTWTCTAAT`）。建议一处并排列出两套并提醒"以你实验实际引物为准"。
3. **4.1 vsearch 聚类示例用通用名 `table.qza`/`rep-seqs.qza`**（`index.typ:433-441`），
与本文固定命名 `table-asv.qza`/`rep-seqs-asv.qza` 不一致。
4. **Pielou 的 QIIME 2 名称**（`index.typ:708`）：写 `evenness`，准确指标名是
`pielou_evenness`。
5. **附录 C 与 4.3 重复定义 `read_biom_tsv`**（`index.typ:493-497` 与
`index.typ:1473-1478`）：建议 4.3 处改为"函数见附录 C"以免两份将来不同步。
6. **参考文献版本混用**：Otu clustering 链接指向 `docs.qiime2.org/2024.10/`
（`index.typ:1682`），全篇宣称 2024.2；建议统一或注明版本差异。
7. **0.4 表 `rep-seqs-gg2-cr99.qza` 描述**（`index.typ:153`）：建议改为"映射后特征的代
表序列（= 命中的 Greengenes2 参考序列本身）"。
8. **附录 C EMP 导入未提 `--input-format`**（`index.typ:1499-1502`）：目录导入可省；单
zip 输入需 `--input-format EMPEmbeddedSequences`，补一句分支说明。
9. **第 15 节标题仍写 "SPCC"**（`index.typ:1209`），但 15.1 自己澄清了"SPCC 不是
SparCC 的别名"；标题改成"共发生网络分析（SparCC / SPIEC-EASI）"。
10. **12.1 "火山图"**（`index.typ:1047`）：ANCOM 输出是 W 值/检测比与差异条形图，没有
火山图；表述可换成"结果以差异条形图（按 W 值排序）展示"。
11. **6.1 "被静默删除"措辞**（`index.typ:745`）：QIIME 2 抽平时会打印"样本被移除"的提示
（q2-feature-table 的 rarefy 显式过滤低于深度的样本），严格说不是"静默"；建议改为"会被
直接剔除（运行日志有提示，但 qzv 视图不直观）"，并保留"运行前务必确认"的建议。
12. **三个 R 包的安装来源易误导**：SpiecEasi、ANCOMBC、maaslin3 **都不在 CRAN**（
SpiecEasi 已从 CRAN 下架，只能 GitHub/BiocManager/bioconda；ANCOMBC 是 Bioconductor 包；
maaslin3 是 `BiocManager::install("biobakery/maaslin3")`）。教程虽未写安装命令，但建议
补一行安装方式，避免读者 `install.packages("SpiecEasi")` 失败。
13. **LinDA 原理表述可更精确**（12.3 表，`index.typ:1087`）："log-ratio 线性模型"宜写成
"对 CLR 变换后的数据拟合线性模型 + 组成效应偏差校正（ME correction），渐近 FDR 控制"
（Zhou et al. 2022, Genome Biology）。

---

## 五、参数级核查结论（联网核实）

> 核查方法：官方 2024.2 文档（已下线，从 Zenodo 存档 DOI `10.5281/zenodo.24082639` 提取
> 源码级 .rst）+ 官方 conda 通道 `qiime2/label/r2024.2` 的 q2 插件包源码交叉验证。

### 5.1 QIIME 2 2024.2 命令与参数（逐条 verdict）

**教程用法正确、确认放心的条目**（均已对照 2024.2 文档/源码）：

| 教程中的用法 | 结论 |
| --- | --- |
| `cluster-features-closed-reference` 有 `--p-strand`（'plus'/'both'，默认 'plus'）且 `--p-threads 0` = 每核一线程 | ✅ 正确（`index.typ:469`） |
| `composition ancombc` 输入 Frequency 表、`--p-adj-method` 默认 holm（可选 BH）、输出 `FeatureData[DifferentialAbundance]` | ✅ 正确；`composition tabulate` 2024.2 就存在（更早于 2022.11） |
| `composition ancom` 需先 `add-pseudocount`；ANCOM-BC 不需要 | ✅ 正确 |
| `diversity alpha-rarefaction`：`--p-iterations` 默认 10；`--p-steps` 默认 10 | ✅ 正确（可补提 `--p-steps`） |
| `classify-consensus-blast`：`--p-maxaccepts`(默认 10)、`--p-perc-identity`(默认 0.8)、`--p-query-cov`(默认 0.8)、`--p-min-consensus`(范围 (0.5,1]，默认 0.51)；线程参数是 `--p-num-threads`；`--p-strand` 默认 both | ✅ 教程给的自定参数合法 |
| `dada2 denoise-paired`：`--p-min-overlap` 默认 12（Range≥4）、`--p-max-ee-f/-r` 默认 2.0、`--p-trunc-q` 默认 2、`--p-chimera-method` 默认 consensus、`--p-n-threads 0` = 用满核心 | ✅ 正确；另存在 `--p-pooling-method`（independent/pseudo，低丰度敏感样本可用 pseudo） |
| `feature-table filter-features`（`--p-min-frequency`/`--p-min-samples`）；`taxa filter-table --p-exclude mitochondria,chloroplast --p-mode contains` | ✅ 正确 |
| `cutadapt trim-paired --p-front-f/--p-front-r/--p-discard-untrimmed`；线程参数为 `--p-cores` | ✅ 正确 |
| `phylogeny align-to-tree-mafft-fasttree`、`diversity pcoa`、`emperor plot`、`vsearch uchime-denovo`、`cluster-features-open-reference`、`dereplicate-sequences` | ✅ 均存在 |
| `tools import --type 'SampleData[PairedEndSequencesWithQuality]' --input-format PairedEndFastqManifestPhred33V2` | ✅ 与官方教程一致 |
| `metadata tabulate` 查看 `denoising-stats.qza` | ✅ 官方 moving-pictures 教程同款用法 |

**教程需要修正或补充的条目**（详细修法见第二节相应条目）：

| 教程中的用法 | 结论 |
| --- | --- |
| `tools import --show-importable-formats/types`（`index.typ:1495-1496`） | ❌ 2024.2 已移除 → `qiime tools list-types` / `qiime tools list-formats --importable` |
| PERMANOVA 报告 R²（`index.typ:836/843/863/1326`） | ❌ QIIME 2 的 permanova 输出只有伪 F、P 等；R² 需 `diversity adonis` 或 R 端 `adonis2` |
| CSV manifest（`index.typ:347, 1538-1543`） | ❌ manifest 仅支持 TSV（tab 分隔） |
| "Deblur 丢弃与 85% Greengenes 相似度过低的序列"（`index.typ:1509`） | ❌ 实为用 Greengenes 13_8 **88%** OTU 做 SortMeRNA 16S 正向过滤 |
| `gg-13-8-99-515-806-nb-classifier.qza` 推荐（`index.typ:1439`） | ⚠️ 遗留资源；2024.2 官方推荐 `gg_2022_10_backbone.v4.nb.qza`（Greengenes2 V4 分类器） |
| `docs.qiime2.org/2024.2` 链接（`index.typ:1612`） | ❌ 已 404，旧文档存档在 Zenodo（DOI `10.5281/zenodo.24082639`） |
| "官方 V3–V4 预训练分类器"（`index.typ:1434`） | ❌ 不存在；官方分类器仅 515-806（V4）及全长 |
| `qiime phylogeny iqtree`（`index.typ:878-882`） | ⚠️ 存在且 `--p-n-cores` 正确（支持 'auto'），`--p-substitution-model` 默认 'MFP' 不是必填；但 iqtree **只输出 Unrooted 树**，若要用于 core-metrics 需先 `qiime phylogeny midpoint-root`；更省事用 pipeline `align-to-tree-mafft-iqtree`（同输出 rooted tree） |
| `beta-group-significance --p-pairwise`（`index.typ:832`） | ✅ 正确（该参数属于 beta 命令；alpha 命令无此参数但自动做 pairwise） |

**SILVA 文件 URL 确认**：`https://data.qiime2.org/2024.2/common/silva-138-99-seqs.qza` 与
`silva-138-99-tax.qza` 真实有效（实测 302→S3 可下载，MD5 已核对）；另有
`silva-138-99-seqs-515-806.qza` / `silva-138-99-tax-515-806.qza`（截短版）——附录 B 训练
示例若用截短版可省 `extract-reads`，建议在教程中并列给出。

### 5.2 数据库、URL 与独立工具核查（直接 HTTP 实测）

| 教程中的条目 | 位置 | 结论 |
| --- | --- | --- |
| GG2 `2024.09.backbone.full-length.fna.qza`、`2024.09.backbone.tax.qza` | 455-459 | ✅ 文件名正确（release 目录实测存在：fna 63MB、tax 4.5MB；另有 v4 版序列/分类器、`00README`） |
| GG2 "backbone 树" | 690 | ❌ release 中**没有** backbone 命名的树（`2024.09.backbone.nwk`、`…backbone.full-length.nwk` 实测 404）；可用的是 `2024.09.phylogeny.{md5,asv,id}.nwk(.qza)`（见二.20） |
| conda yml `…2024.2-py39-linux-conda.yml` | 1405 | ❌ 404；正确为 **py38**（见二.16） |
| `https://data.qiime2.org/2024.2/common/silva-138-99-seqs.qza`、`silva-138-99-tax.qza` | 571-572 | ✅ 有效（实测 302→S3，MD5 已核对） |
| `silva-138-99-515-806-nb-classifier.qza` | 1438 | ✅ 存在（注意 ~2021 年重训练版本差异） |
| `gg-13-8-99-515-806-nb-classifier.qza` | 1439 | ⚠️ 文件可下载但已不在 2024.2 官方推荐列表（见二.15）|
| `view.qiime2.cn` | 42, 1522 | ⚠️ 可访问但 TLS 证书 2024-10-28 已过期（见二.23） |
| MENA `http://ieg4.rccc.ou.edu/mena/` | 1300, 1674 | ✅ 2025-01-15 起恢复在线且该域名即当前官方地址（需免费注册登录）；论坛上流传的 shinyapps 新地址实测 404，勿采用 |
| SparCC bitbucket | 1258, 1673 | ❌ 仓库被 Bitbucket 因不活跃停用；flag 语义错误（见二.17）；替代 FastSpar |
| LEfSe 命令名/参数 | 1054-1063 | ❌ 命令名与 `-f` 归属错误（见二.18） |
| dada2 SILVA 138.1 文件名 | 1445-1446 | ❌ `addSpecies` 文件名错误 → `silva_species_assignment_v138.1.fa.gz`（Zenodo 4587955 实测） |
| `protocols.hostmicrobe.org/microbio/qiime2` | 1616 | ✅ 有效（16S QIIME2 全流程协议页） |
| geekdaxue QIIME2-doc-zh 链接 | 1615 | ✅ 有效（需带章节后缀，教程已带） |
| docs.qiime2.org 版本化链接（2024.2 / 2024.10 otu-clustering） | 1612, 1682 | ❌ 全部 404 → 改 `en/stable/how-to-guides/cluster-reads-into-otus/`（见二.25） |
| q2-greengenes2 插件 | 1681 | ✅ 链接有效；插件实际命令为 `non-v4-16s`、`taxonomy-from-table`、`filter-features`、`collapse-multifurcation` 等（教程未误写 `update-backbone`/`features-to-file`，保持不写即可） |
| SRA runinfo API `trace.ncbi.nlm.nih.gov/Traces/sra-db-be/runinfo` | 1530 | ✅ 2026 实测 200 仍可用；CSV 首列即 Run |
| `prefetch --option-file` | 1534 | ✅ sra-tools 全局选项存在 |
| `fastq-dump --threads` | 1535 | ❌ 选项不存在（见二.21）→ `fasterq-dump --threads` |
| q2-picrust2 | 1349 | ⚠️ 教程未给出命令名；正确命令是 **`qiime picrust2 full-pipeline`**（不是 `pipeline`），输入 `--i-table`/`--i-seq`，配 `--p-placement-tool sepp --p-hsp-method pic --p-max-nsti 2`（wiki 教程实测）；`--p-max-nsti 2` 默认值 2 写法正确 |
| FAPROTAX collapse_table.py | 1591 | ❌ 当前版（v1.3.7）`-c`=注释前缀、`-d`=行名列定位；见二.22 |
| Deblur "85% Greengenes" | 1509 | ❌ 实为 88% OTUs + SortMeRNA 正向过滤（见二.13） |
| `sourcetracker2 gibbs -i … -m … -o …` | 1599 | ✅ 与 SourceTracker2 官方用法一致（`-o` 是输出目录；官方仓库已迁至 `caporaso-lab/sourcetracker2`，旧 `danknights` 地址已失效） |

### 5.3 R 包与统计概念核查（一手源码 + 本地 R 数值验证）

**确认正确的条目**（无需改动）：

| 教程声明 | 结论 |
| --- | --- |
| SpiecEasi：`spiec.easi(X, method='mb', lambda.min.ratio=1e-2, nlambda=20, sel.criterion='stars', pulsar.params=list(rep.num=50, ncores=4))`；`getStability`/`getRefit`/`adj2igraph` | ✅ 全部与 SpiecEasi 源码/README 一致（README 示例几乎逐字相同）；`pulsar.params` 是现行参数（弃用的是 `icov.select*`）；StARS 目标阈值默认 0.05，`getStability()` 结果"接近 0.05"解读正确；注意 `sel.criterion` 必须直接传给 `spiec.easi` 而非放进 `pulsar.params` |
| ANCOM-BC2：`ancombc2(data=physeq, fix_formula="Group+BMI+Age", p_adj_method="BH", group="Group")`；默认校正 holm | ✅ 与 Bioconductor ANCOMBC 2.16.0 的 man 页一致；`group` 参数存在（structural zeros 与 global/pairwise 检测需要）；`data` 也接受 matrix/data.frame（需配套 `meta_data` 参数） |
| maaslin3：`maaslin3(input_data, input_metadata, output, formula="~ …")` | ✅ 与 biobakery/maaslin3 README 一致（新发现：该文 Nickols et al. Nat Methods 2026）；默认 normalization='TSS'、transform='LOG'、`max_significance=0.1`——若引用默认值注意 0.1 不是 0.05 |
| metagenomeSeq = 零膨胀高斯（ZIG） | ✅ 正确；vignette 现推荐更新的 ZILN（`fitFeatureModel`），可加一句 |
| Good's coverage C = 1 − F₁/N | ✅ 标准 Good (1953) 估计量 |
| Alatalo Ea = (1/ΣPi² − 1)/(exp(H′) − 1) | ✅ 标准 Alatalo (1981) |
| Whittaker βw、Cody βc、Wilson–Shmida βT、BC/Jaccard 公式 | ✅ 均为标准定义 |
| DCA 梯度长度 >4 / 3–4 / <3 选型规则 | ✅ Lepš & Šmilauer 标准经验规则（教程已自带"Hellinger 变换后含义会变"的限定，好）；注意该规则基于未变换原始丰度数据这一点教程已写对 |
| Zi–Pi 阈值（module hubs Zi>2.5 Pi<0.62 等） | ✅ Guimerà & Amaral 2005 / Olesen et al. 2007 标准；仅边界（恰 2.5/0.62）归属不同文献略有差异 |
| vegan 各函数：`metaMDS(d, k=2, trymax=100)`（d 可为 dist 对象，已数值验证）、`wisconsin(sqrt(comm))`（经典 bray 前处理配方）、`ordiellipse(kind="se", conf=0.95)`、`ordiR2step`/`ordistep`/`vif.cca`/`RsquareAdj`/`capscale(dist~., data=env)`、`specaccum`、`radfit`、`decostand` | ✅ 全部存在且用法正确（本地 R 数值验证） |
| Faith's PD `picante::pd(comm, phy, include.root=TRUE)`；QIIME 2 faith_pd 亦用有根树 | ✅ 与 picante 1.8.4 man 页一致 |
| Pielou J = H′/ln S | ✅ 标准 |
| decontam `isContaminant(seqtab, method="prevalence", neg=…)` | ✅ 用法正确（neg 需为与样本等长的逻辑向量；frequency 法需 `conc`；默认阈值 P<0.1） |
| Boruta（shadow features 随机森林）、pROC、caret、UpSetR/ComplexUpset/dendextend/pvclust/aplot/patchwork | ✅ 全部为真实包且用途描述正确 |
| FEAST = EM 方法 | ✅ GitHub 源码确认（`FEAST()` 含 EM_iterations） |

**需修正的条目**（修法见第二节）：

| 教程声明 | 结论 |
| --- | --- |
| `MuMIn::r2()`（`index.typ:1377`） | ❌ 函数不存在 → `MuMIn::r.squaredGLMM()` 或 `performance::r2()`（见二.24） |
| `prcomp(..., scale.=TRUE)` 与 `rda(~1)` "等价"（`index.typ:973`） | ❌ 数值验证不等价；见二.2 |
| Gleason 公式（`index.typ:719`） | ⚠️ 需注明约定（见二.3） |
| SpiecEasi/ANCOMBC/maaslin3 安装 | ⚠️ 均不在 CRAN（见四.12） |

---

## 六、🔵 补充完善建议（按优先级）

### A. 补充规范的学术引用（影响最大）
"参考与延伸阅读"目前只有博客/教程/微信公众号链接（大量二手来源），**没有一篇主要方法
学原始文献**。建议新增"主要方法文献"一节：
- QIIME 2：Bolyen et al. 2019, Nature Biotechnology
- DADA2：Callahan et al. 2016, Nature Methods
- Greengenes2：McDonald et al.（PLoS Comput Biol, greengenes2）
- SILVA：Quast et al. 2013（+ v138 更新）；GTDB：Parks et al. / Reeves et al.
- UniFrac：Lozupone & Knight 2005；Faith PD：Faith 1992
- ANCOM：Mandal et al. 2015；ANCOM-BC：Lin & Peddada 2020 Microbiome
- LinDA：Zhou, He, Chen & Zhang 2022, **Genome Biology 23:95**（DOI
10.1186/s13059-022-02655-5，注意不是 Microbiome）；MaAsLin2/3：Huttenhower 组（MaAsLin3
见 Nickols et al., Nat Methods 2026）
- LEfSe：Segata et al. 2011 Genome Biology；Metastats：White et al. 2009
- PICRUSt2：Douglas et al. 2020；Tax4Fun2：Wemheuer et al. 2020；FAPROTAX：Louca et
al. 2016
- SparCC：Friedman & Alm 2012；SPIEC-EASI：Kurtz et al. 2015
- Zi–Pi：Guimerà & Amaral 2005 / Olesen et al. 2007 PNAS
- DCA/RDA 选型：Lepš & Šmilauer；vegan：Oksanen et al.
- 正文已点名但未列出的：Stackebrandt & Goebel 1994（4.1）、Edgar 2018、Yarza et al.
2014
- 承诺过的"某大型跨队列研究"QC 阈值（`index.typ:513`）也应补出处。

### B. 建议增补的章节
1. **完整示例数据集走查**：现通篇是命令说明书，缺"从 raw data 到最终图"的实例（如
Bio-protocol 拟南芥根际 18 样本数据）。加一节"完整示例跑查"，给出每步真实输出数值（保
留率、ASV 数、抽平深度选择、PCoA 首轴解释率），供新手对照自查。
2. **样本级过滤**：补
   ```bash
   qiime feature-table filter-samples \
     --i-table table-clean.qza --m-metadata-file metadata.tsv \
     --p-where "Group='control'" --o-filtered-table table-control.qza
   ```
   以及按测序深度过滤的示例。
3. **"表的使用场合"决策总表**：table-asv / table-filtered / table-gg2-cr99 /
table-clean / table-gg2-l2、l6 / comp-l6 / 抽平表——每行注明生成步骤与允许、禁止的下游
用途。
4. **多队列合并章节**：既把 closed-reference 定位为跨研究主线，就应补
`qiime feature-table merge`、`merge-seqs` 与 metadata 合并去重的做法，并接 4.3 的 QC。
5. **批次效应演示**：0.5 强调 Batch 入表，但 7.2 没有示范：
   ```r
   adonis2(d_bc ~ Group + Batch, data = meta, permutations = 999)
   # 或限定置换：adonis2(d_bc ~ Group, data = meta, strata = meta$Batch, permutations = how(nperm=999))
   ```
   并可提 QIIME 2 原生 `qiime diversity adonis`（多协变量 PERMANOVA）。
6. **Mantel 检验 / bioenv**：接第 13 节环境因子，补
`vegan::mantel(d_bc, dist(env), permutations=999)` 与 `bioenv()`。
7. **Alpha 组间检验的 R 端完整替代**：Kruskal–Wallis + Dunn post-hoc（`rstatix::dunn_test`）+ 效应量，说明与 QIIME 2 内置 FDR 两两比较的对应关系。
8. **三代全长 16S 提示段**：参考文献提到"三代 CCS/lima 参数出自百迈客 v2.6"，正文却完全没覆盖 PacBio/ONT 全长 16S 的差异（无需拼接、全长建树、分类器不同）。要么删引用，要么补半页速览。
9. **QIIME 2 侧常见报错速查表**（报错原文 → 原因 → 解法）：
   - `Feature IDs found in the table are missing from the tree`（过滤顺序导致 tip 不齐）
   - sklearn 版本不匹配（预训练分类器与当前 env）
   - DADA2 大量 `merged=0`（overlap 不足 → 对应二节 4/5）
   - 大量 Unassigned（引物区/方向不匹配）
   - unmatched 过多（perc-identity 太严、扩增区与 backbone 不匹配）
10. **可复现基建**：`renv`/`conda env export` 固定版本、Docker/Singularity、
Snakemake/Nextflow 管道化、固定随机种子（permutation、metaMDS、SpiecEasi 稳定性选择均
有随机性）。

### C. 现有章节再完善的具体点
- **0.5**：给最小 `metadata.tsv` 头部示例，并示范
`qiime metadata tabulate --m-input-file metadata.tsv --o-visualization metadata.qzv` 自
检。
- **1.2**：补 `--p-error-rate`（默认 0.1）说明、IUPAC 引物写法不变提示、trim 后重跑
`demux summarize` 验证长度变化；顺带补 3′ 接头场景 `--p-adapter-r`。
- **1.5**：fastp 参数逐条注释（`-u 30` = 未达阈值碱基比例上限），并明确"去宿主在
import 之前"的顺序。
- **2**：加"参数自检公式卡"：`L_overlap = (trunc_f − trim_f) + (trunc_r − trim_r) −
L_amplicon ≥ min_overlap`，配 V4 / V3–V4 两个数字例子。
- **3.4**：补污染报告口径（判定多少特征为污染、剔除前后 Alpha/Beta 变化）。
- **4.2**：补"映射率过低如何处理（示例阈值 + 报告写法）"。
- **4.5**：补 confidence 阈值敏感性提示（0.5/0.7/0.9 各跑一次对比属级一致性）。
- **5.1**：说明 collapse 后特征 ID 是拼接的属名字符串；属水平表做 ANCOM 时 ID 形式。
- **6.1**：给"抽平深度敏感性"表格模板（深度 / 保留样本数 / KW P / PERMANOVA R²）。
- **7.2**：补 `beta-group-significance --p-method permdisp` 的完整命令（正文只在表格里
提到）。
- **9**：多组 Rank-Abundance 画法（`pivot_longer` + 分面），提醒纵轴 log10 相对丰度。
- **10**：补 emperor 导出与 R 端 PCoA 复算（`cmdscale(d, eig=TRUE)` / `ape::pcoa`）。
- **12.1**：补 `--p-covariates`/`--p-confounders` 说明及 R 端 ancombc2 的适用设计。
- **13**：补 `envfit` 代码（正文只提了名字没给命令）。
- **14**：补 stress 阈值出处（如 Clarke 1993），并说明 metaMDS 结果受随机起点影响、
`set.seed()` 的作用。
- **15**：补 igraph 导出 GraphML/边表到 Gephi 的代码与节点属名标注。
- **17.2**：给 `q2-longitudinal` 完整命令示例（现在只列了名字）。
- **附录 B**：注明训练与查询的序列方向问题（`--p-read-orientation`）。
- **附录 E**：补 `esearch/efetch`（Entrez Direct）作为 runinfo 的备选、完整
`comm -23` 对比代码。

### D. 呈现与结构建议
1. 表格多但无表号与表题；建议加 caption（`#figure(kind: table, caption: ...)`）便于交叉
引用。
2. 交叉引用统一格式并逐个复查（本文已发现 1.5 节指向错节号）。
3. 开头加"适用范围与不适用范围"段（ITS 真菌流程、三代全长、shotgun 宏基因组、2024.2
之后 API 变化等）。
4. 加"版本历史"与"如何引用本文"。
5. 中英术语首次出现并列（如 rarefaction = 抽平/稀化）。
6. 每节末尾加"本节产出文件"一行，与 0.4 关键文件表呼应。

---

## 七、修改优先级速览

| 优先级 | 事项 | 位置 |
| --- | --- | --- |
| P0 | 修 `#import "../index.typ"` 与 `imgs/` 缺失，让文档可编译 | 1, 21 |
| P0 | 附录 A yml URL py39→py38（照抄即失败） | 1405 |
| P0 | 删除"官方 V3–V4 预训练分类器"的说法 | 1434 |
| P0 | 修 250/230 + trim20 与 V3–V4 的合并失败矛盾、trim-left 数值 | 291, 299-302 |
| P0 | PERMANOVA R² 口径（QIIME 2 无 R²，用 adonis/adonis2） | 836/843/863/1326 |
| P0 | `--show-importable-formats/types` 已移除 → `list-types`/`list-formats` | 1495-1496 |
| P0 | SparCC `-a/-x` 语义错误、bitbucket 失效 → FastSpar | 1258, 1673 |
| P0 | LEfSe 命令名与 `-f r` 归属说反 | 1055-1063 |
| P0 | manifest 仅支持 TSV（正文与附录 E 的 CSV） | 347, 1538-1543 |
| P1 | R 端 addSpecies 文件名、Deblur 88% 描述、GG2 参考树文件名、FAPROTAX 参数、`MuMIn::r2()` 不存在 | 1446/1509/690/1591/1377 |
| P1 | 修 prcomp/rda 等价性、Gleason 公式、ANCOM"属 vs ASV"矛盾 | 973, 719, 1043 |
| P1 | 统一 `taxonomy-gg2.qza`、`table-gg2-l6`、`table-filtered` 生成与使用 | 155/387/551/626/1459 |
| P1 | 修 R 端 DADA2 缺 `makeSequenceTable` | 324-340 |
| P2 | view.qiime2.cn 证书过期、docs 版本化链接失效、gg-13-8 分类器遗留标注 | 42/1522, 1612/1682, 1439 |
| P2 | SpiecEasi 输入用计数、MaAsLin2/3 命名、Pielou 指标名、交叉引用错位等 | 见三/四节 |
| P3 | 补方法学文献、示例数据集、样本级过滤、批次效应演示、可复现基建 | 第六节 |

**统计**：共排查出 🔴 必须修正 25 项、🟠 建议修正 12 项、🟡 一致性问题 13 项、🔵 增补建议
20 项（截至本报告定稿）。另有 7 项经核查确认教程原写法正确（见五.1 正确条目表），无需改动。

<!-- 全部三个联网核查 agent 的结论已并入第五节（5.1 QIIME 2 命令 / 5.2 数据库与工具 / 5.3 R 包与统计），报告到此定稿。 -->
