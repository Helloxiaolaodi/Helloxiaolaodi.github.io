修改版比前一稿扎实了很多：ANCOM-BC2 默认 `holm` 已被多处文档确认；QIIME 2 的 `composition ancombc` 确实输出 Artifact 而非直接 qzv，需要 `tabulate` 转表；DADA2 `--p-chimera-method` 默认 `consensus` 也准确；PERMDISP 作为 PERMANOVA 配套检查的定位，和主流文献的做法一致。你主动修掉的“单端 manifest 三列”“LEfSe `-c` 用列号”“`ancombc` 输出不是 qzv”“去噪保留率无固定 20% 阈值”这几处，都是前稿里的硬伤，改得对。

但仍有几处需要修正或不妥，以及结构上残留的“目录与正文逻辑打架”的问题。下面按优先级列出。

---

## 一、仍需修正的具体问题

**（1）`ancombc` 输出的描述可以更精确。** 你写“2024.2 的 ancombc 输出的是差异丰度 Artifact，不是 qzv”，方向对，但容易让读者以为“没有可视化”。实际是：`--o-differentials` 输出 `FeatureData[DifferentialAbundance]` Artifact，QIIME 2 **不提供内置的 qzv 可视化器**把该 Artifact 直接转成图；但可以用 `qiime composition tabulate` 生成包含 lfc、p、q 值的表 qzv，也可以用 `qiime composition da-barplot` 画差异条形图（以当前文档为准）。建议改成：“`ancombc` 输出 Artifact，QIIME 2 不直接提供该 Artifact 的 qzv 可视化；用 `composition tabulate` 转表，或 `da-barplot` 出图，再导出 TSV 进 R。”

**（2）`--p-adj-method` 的默认值可以在 ANCOM-BC 小节里显式写出。** 你在 12.3 的 R 注释里已经说了“ANCOM-BC2 默认 holm，这里显式改 BH”，这很好。但在 12.1 的 QIIME 2 `ancombc` 命令段，可以补一句“`ancombc` 的 `--p-adj-method` 默认也是 `holm`，若要与全文 BH 统一，需显式传 `--p-adj-method BH`”。这不是错误，而是让 QIIME 2 段和 R 段的校正口径一致，避免读者以为 QIIME 2 默认就是 BH。

**（3）LEfSe 的 `-c` 参数细节可以再收紧。** 你写“`-c` 是类别变量所在的列编号（整数，从 1 开始），不是列名字符串；`-f r` 表示输入为相对丰度”，方向对。但 `lefse_format_input.py` 的 `-c` 实际是**整数列索引**，且 LEfSe 官方文档通常建议 `-c` 指向**第一列**（即 class 列放在输入表的第一列），`-f r` 用于 `run_lefse.py` 时对输入做相对丰度转换。你目前把 `-f r` 放在 `lefse_format_input.py` 行，语义上不够精确：`-f` 是 `run_lefse.py` 的参数，不是 format 脚本的参数。建议改成：

```bash
# 先把 class 列放在第一列，-c 1 表示用第 1 列作为 class
lefse_format_input.py otu_table.txt otu.in -c 1
run_lefse.py otu.in otu.res -l 4.0 -f r
```

或者至少加一句“`-f r` 属于 `run_lefse.py`，不在 `lefse_format_input.py` 上”。这会影响学生直接复制命令。

**（4）PERMDISP 的 R 代码可以补一句“先于或平行于 PERMANOVA 报告”。** 你现在的写法“PERMDISP 不是可选项，而是 PERMANOVA 的标准配套检查”是对的，代码里 `betadisper` + `permutest` 也给了。但顺序上可以更明确：**在结果解读时，先看 PERMDISP 的 P 值；若 PERMDISP 显著，PERMANOVA 的 R² 不能直接解释为“组成差异”，而需要说明“组间离散度也不一致”**。这不只是代码问题，是报告规范问题。建议在 PERMDISP 代码后加一句解读模板。


## 二、目录结构残留的“逻辑矛盾”

你在第 8 节开头写了一句很诚实的话：“目录里它排在第 8 节，但请把它的命令提前到第 6、7 节之前执行。”**这句话本身说明目录结构还没有修好。** 一本给硕士生的教程，不应该让读者“跳过第 8 节去做第 6 节，再回来做第 8 节”。

前一轮建议的“7 章结构”没有被采纳，但至少有一处需要动：**把“系统进化树”从第 8 节前移，合并进第 6 节或第 7 节之前，作为 Alpha/Beta 的前置步骤。** 最低成本的改法：在“Alpha 多样性”之前插入一个二级节，比如在第 6 节开头加 `=== 6.0 建树（Faith PD / UniFrac 的前置）`，把第 8 节的命令放进去，第 8 节只保留“树的查看与美化”和“建树策略讨论”。这样目录顺序和正文执行顺序就一致了，不需要大改章号。

另外，第 17 节“进阶与跨研究模块”内容质量不错（metadata 质控、core microbiome、配对/纵向、LOSO、跨队列网络），但**它放在“从结果到论文”之后、附录之前，作为一级标题的定位有些尴尬**。硕士生读到第 16 节已经准备收尾，第 17 节容易被跳过。可以考虑把 17.1（metadata 质控）**前移到第 0 节或第 1 节**作为独立子节——它本来就是“准备工作”的一部分，而且是决定后续统计能否做的前置条件；17.2–17.5 保留为“选读”没有问题。


## 三、内容上仍建议补充的点

**（5）差异丰度的“共识”原则可以给一个可操作的最小模板。** 你 12.3 已经写了“ANCOM-BC2 / LinDA / MaAsLin2 取共识”，但没有说“具体怎么取”。可以补一句操作定义：“对每个特征，若至少两个方法在 BH 校正后均显著（q ≤ 0.05），且 log fold change 方向一致，才列入共识差异特征；只在一个方法中显著的，作为方法特异性候选单独报告。”这比“取交集”更稳健，因为三个方法都显著的交集往往太小，而“两个方向一致”在敏感性和可重复性之间平衡更好。

**（6）SEPP / 参考树放置作为建树策略，可以写得更具体。** 你在 8.1 末尾提了一句“SEPP 片段插入到参考树或直接用 Greengenes2 放置”，方向对，但**没有给出命令或工具名**。对于 closed-reference 主线，其实有一个很自然的选项：**直接使用 Greengenes2 backbone 自带的参考树**（与 `table-gg2-cr99.qza` 特征 ID 对齐的树），而不需要从 ASV 代表序列 de novo 建树。如果你能在 8.1 补一句“若主线走 GG2 closed-reference，优先下载/使用与 2024.09 backbone 同版本的参考树，确保 tip 与 `table-gg2-cr99.qza` 的 feature ID 一一对应；de novo FastTree 只作为 ASV 支线的备选”，会显著降低学生的建树出错率。

**（7）`core-metrics-phylogenetic` 的 `--p-sampling-depth` 可以补一个“敏感性检查”的具体做法。** 你写了“对关键结论做不同深度的敏感性分析”，但没有说怎么做。可以给一个最小示例：选 2–3 个候选深度（例如能保留 100% 样本的最大深度、保留 ≥95% 样本的深度、保留 ≥90% 样本的深度），分别跑 Alpha 的 Kruskal–Wallis 和 Beta 的 PERMANOVA，看显著性和效应量方向是否稳定；若不稳定，在方法中报告“结论对抽平深度敏感”，而不是只报一个深度下的 P 值。

**（8）网络分析的“阈值敏感性”可以给出一个可重复的最小流程。** 15.5 写了“换不同阈值/相关方法重跑，结论稳定才可信”，但没有操作化。可以补一句：“至少在 |r| ≥ 0.5 / 0.6 / 0.7 三档阈值下各建一次网络，记录节点数、边数、模块度和 Hub 列表的重叠比例；若 Hub 集合在三档之间高度不稳定，网络结论不应作为主要发现。”

**（9）附录 C 的 R 导入模块有一个小问题：`comment.char = ""` 与 `skip = 1` 的组合需要确认。** BIOM 转 TSV 的首行通常是 `# Constructed from biom file`，`skip = 1` 跳过它是合理的；但有些 BIOM 版本的注释行可能不止一行，或者首行不是注释而是表头。更稳的写法是先读前几行判断，或者直接用 `read.delim(..., comment.char = "#")` 让 R 跳过所有 `#` 开头的行，而不是硬编码 `skip = 1`。你的 `read_biom_tsv()` 封装本身是好的，但可以在注释里补一句“若首行不是 `# Constructed from biom file`，需按实际文件调整 `skip`”。


## 四、一个小的术语一致性问题

你在 0.4 的总览表里把 PCA 的命令写成 `prcomp` / `rda(~1)`，这很好，已经避开了前稿的混淆。但在 10.2 的 R 代码里，`rda(decostand(comm, method = "hellinger"))` **没有写 `~ 1`**。虽然 `rda()` 不带公式时默认就是无约束 PCA，但在教学文本里显式写成 `rda(decostand(comm, "hellinger") ~ 1)` 或 `prcomp()` 会更不容易让学生误以为“`rda` 也可以带公式做 PCA 和 RDA 的任意切换”。建议在 10.2 的注释里补一句“不带公式的 `rda()` = PCA；带 `~ 环境因子` 才是 RDA”。


**总结**：这一版的技术准确度已经明显提升，ANCOM-BC2 默认方法、`ancombc` 输出性质、PERMDISP 定位、DADA2 内建去嵌合体等关键判断都有文档支撑。剩下的优先级是：① 把“系统进化树”在目录/正文顺序上前移，消除“跳节”的矛盾；② 修正 LEfSe `-f r` 的归属和 `ancombc` 输出的表述；③ 把差异丰度共识、建树参考树、抽平敏感性、网络阈值敏感性这几处从“提了一句”变成“给一个可操作的最小模板”。