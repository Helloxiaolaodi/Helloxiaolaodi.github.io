# diversity_analysis

```javascript
1. 1. 简介
A. 什么是qiime2
QIIME 2（Quantitative Insights Into Microbial Ecology 2）是一个用于微生物群落分析的开源工具包，旨在帮助研究人员从生物信息学数据
中获得定量的、高质量的洞察力。它提供了一系列功能强大的工具，用于对微生物组进行序列分析、分类和功能预测。
B. qiime2的发展历程
QIIME 2是QIIME（Quantitative Insights Into Microbial Ecology）的升级版本，从QIIME 1升级到QIIME 2带来了更高的性能、更丰富的功能
和更直观的界面。QIIME2采用了插件机制，使得用户可以根据自己的需求灵活添加或删除功能模块，极大地提高了其灵活性和可扩展性。
C. qiime2在微生物学研究中的应用概述
QIIME2在微生物学研究中扮演着重要角色，可以用于分析来自各种环境样品的微生物组数据，从而揭示微生物的多样性、群落结构以及其
与环境的相互作用。通过qiime2，研究人员可以快速准确地分析海量微生物组数据，帮助揭示微生物在自然环境中的生态功能和作用。
2.II. 16S分析基础
A. 为什么选择16S rRNA基因进行微生物群落研究
在微生物学研究中，16S rRNA基因是一种独特的标记基因，具有高度保守性和变异性。通过对微生物样本中16SrRNA基因的测序和分析，
可以揭示微生物的分类、多样性和群落结构，有助于了解微生物在不同环境中的分布和功能。
B. 16S rRNA基因在微生物分类和鉴定中的作用
16SrRNA基因存在于细菌和古菌的基因组中，不仅在不同微生物种类之间具有保守性区域，也拥有足够的变异性来区分不同的微生物分类
单元。通过对16SrRNA基因序列的比对和系统发育分析，可以对微生物进行分类、鉴定和进化关系的推断。
C. 16S rRNA基因测序技术及数据处理流程概述
16SrRNA基因的测序技术主要包括Sanger测序、454测序、IIlumina测序等，其中Illumina测序由于高通量、低成本成为常用选择。在数据处
理流程中，通常包括序列质量控制、序列拼接、去嵌合体、聚集实体得到操作单元序列（OTUs）、物种注释和群落结构分析等步骤。
3. III. qiime2概述
A. qiime2的核心功能和特点
qiime2（Quantitative Insights Into Microbial Ecology 2）是一个用于生物信息学分析的开源工具，旨在帮助研究者从微生物组数据中获得关
键的见解。其核心功能包括数据导入、质量控制、序列分析、物种分类、群落结构分析、功能预测等。qiime2支持从16S、18S、ITS等多种
核酸测序数据源进行微生物群落分析。
B. qiime2相对于之前版本的优势和改进
相较于之前的Qiime版本，qiime2在功能性和易用性上都有较大的改进。其中最大的优势之一是采用了基于插件的架构，使得用户可以根据
需要选择性地加载不同的分析工具和功能模块，使得qiime2更加灵活和可定制。此外，qiime2还实现了数据格式的统一和数据流的优化，提
高了分析效率和准确性。
C. qiime2的安装和基本操作指南
要安装qiime2，可以通过Anaconda或Miniconda来进行安装和管理。首先创建一个新的环境，然后在环境中安装qiime2。安装完成后，可以
通过命令行或者图形化界面来使用qiime2。基本操作包括数据导入、质量控制、序列处理、分析结果可视化等。用户也可以通过qiime2的官
方文档和教程来学习更多关于qiime2的操作方法。
这是qiime2概述的简要内容，后续章节将会进一步介绍qiime2在16S分析中的具体应用。
4.IV. 16S分析流程及qiime2的应用
在微生物学研究中，对16SrRNA基因进行测序分析是一项常见的研究方法，能够揭示微生物群落的组成结构和功能特征。qiime2作为一款
强大的微生物组学分析工具，为研究人员提供了方便快捷的数据处理和分析功能。下面将介绍16S分析流程及qiime2在各个步骤中的应用。
A. 样本采集与DNA提取
在进行微生物群落分析之前，首先需要采集样本，并对样本中的微生物DNA进行提取。常用的DNA提取方法包括CTAB法、快速提取法等。
采集到的DNA样本将作为进一步16S测序分析的基础。
B. 数据预处理：质量控制和序列拼接
在进行16SrRNA基因测序之后，得到原始的测序数据。接下来需要进行数据的质量控制和序列拼接，去除低质量序列以及将重叠的序列拼
接成完整序列。qiime2提供了丰富的工具和插件来进行数据处理，如DADA2和Deblur等。
C. 物种丰度分析和群落结构分析
通过16S数据分析，可以对微生物群落中不同微生物种类的相对丰度进行分析，进而揭示群落的结构和组成。qiime2提供了多种方法和统计
工具，如OTU聚类分析和物种多样性分析，帮助研究人员更好地理解微生物群落的特征。
D. 功能预测和生态功能分析
除了对微生物群落结构进行分析外，qiime2还支持对微生物功能进行预测和功能分析。通过利用数据库和功能预测工具，可以推断微生物在
群落中的生态功能和代谢途径，为生态系统功能和微生物间相互作用提供更深入的理解。
通过以上步骤，结合qiime2提供的丰富功能和工具，研究人员可以全面地对微生物群落进行16S分析，从而揭示微生物的多样性、组成结构
和功能特征。
5. V. qiime2工具箱及插件
在qiime2中，提供了丰富的工具箱和插件，帮助研究人员快速高效地进行微生物群落分析。下面将介绍一些常用的qiime2工具和功能：A.
常用的qiime2工具和功能介绍:
1. qiime taxa:用于对序列数据进行分类学分析，包括确定OTU的分类信息、物种注释等。
01.
qiime taxa barplot \
02.
--i-table table.qza \
03.
--i-taxonomy taxonomy.qza \
04.
--m-metadata-file sample-metadata.tsv \
05.
--o-visualization taxa-bar-plots.qzv
代码总结：这段代码将产生一个可视化的bar plot，展示每个样本中不同分类水平的物种丰度。
2. qiime diversity:用于进行微生物群落多样性分析，包括Alpha多样性和Beta多样性的计算等。
01.
qiime diversity core-metrics-phylogenetic \
02.
--i-phylogeny rooted-tree.qza \
03.
--i-table table.qza \
04.
--p-sampling-depth 10000 \
05.
--m-metadata-file sample-metadata.tsv \
06.
--output-dir core-metrics-results
代码总结：这段代码将计算样本间的多样性距离，并生成多样性指标的统计结果。
B. qiime2插件的作用和使用方法:
qiime2的插件是扩展功能的集合，用于增强qiime2的功能和灵活性。在使用插件之前，需要安装相应的插件，并按照插件的文档说明进行操
作。例如，安装并使用q2-feature-classifier插件可以实现对序列数据进行分类，提高物种注释的精度和准确性。
C. 示例：使用qiime2进行16S分析的实际操作步骤：
1. 安装qiime2:
01. conda create -n qiime2-2021.8 --file https://data.qiime2.org/distro/core/qiime2-2021.8-conda
2. 导入数据：
01.
qiime tools import \
02.
--type 'SampleData[PairedEndSequencesWithQuality]'\
03.
--input-path demux.qza \
04.
--output-path demux.qza \
05.
--input-format CasavaOneEightSingleLanePerSampleDirFmt
3. 运行质量控制：
01.
qiime dada2 denoise-paired 
02.
--i-demultiplexed-seqs demux.qza \
03.
--p-trim-left-f 13 \
04.
--p-trim-left-r 13 \
05.
--p-trunc-len-f 150 \
06.
--p-trunc-len-r 150 \
07.
--o-representative-sequences rep-seqs-dada2.qza
08.
--o-table table-dada2.qza
以上是关于qiime2工具箱及插件的简要介绍，实际操作步骤可根据具体研究目的和数据情况进行调整和优化。
6. VI. 结语
A. qiime2在16S分析中的优势和局限性
qiime2作为一个功能强大的微生物组学分析平台，具有许多优势，如灵活的工作流程设计、丰富的分析工具、可视化效果优秀等。通过
qiime2，研究者可以更好地理解微生物群落的多样性、功能和生态学特征，为微生物学研究提供了便利。然而，qiime2也存在一些局限性，
比如对于大规模数据处理的效率有待提高，部分模块的算法仍需进一步优化等。
B. 未来qiime2的发展方向和应用前景
随着微生物组学研究的深入和技术的不断发展，qiime2将继续不断优化和更新，加强对于多样性分析、功能预测等方面的支持，提高数据处
理效率和分析精度。未来qiime2有望在微生物组学领域发挥更大作用，为研究者提供更全面、高效的微生物数据分析解决方案。
C. 总结与展望
综上所述，qiime2作为一个开源、功能丰富的微生物组学分析平台，为微生物学研究带来了许多便利和机会。通过学习和掌握qiime2，在
16S分析等领域可以更好地理解和解释微生物群落的结构、功能和生态学意义。随着技术的不断进步和研究的不断深入，相信qiime2将在未
来发展中不断完善，为微生物学研究提供更多可能性，并推动微生物组学领域的发展。让我们共同期待qiime2在未来的发展中取得更大成
就!
```

```javascript
Alpha和Beta多样性分析
一、介绍
QIIME 2的多样性分析可通过q2-diversity插件获得，该插件支持计算alpha和beta多样性指标，应用相关的统计测试以及生成交互式可视化。我们将首先应用核心指标系统发生方法，该方法将FeatureTable [Frequency]稀疏到用户指定的深度，计算多个alpha和beta多样性指标，并使用Emperor为每个指标生成主坐标分析（PCoA）图、 Beta多样性指标。默认情况下计算的指标是：

Alpha diversity
香农的多样性指数（衡量社区富裕程度的指标） Shannon’s diversity index (a quantitative measure of community richness) Observed Features (a qualitative measure of community richness)
观察到的特征（对社区丰富度的定性度量） Faith’s Phylogenetic Diversity (a qualitiative measure of community richness that incorporates phylogenetic relationships between the features)
Faith的系统发育多样性（一种定性的衡量社区丰富程度的方法，其中纳入了特征之间的系统发育关系）
均匀度（或Pielou的均匀度；衡量社区均匀度的指标） Evenness (or Pielou’s Evenness; a measure of community evenness)
Beta多样性
雅卡德距离（定性度量社区差异） Jaccard distance (a qualitative measure of community dissimilarity)
Bray-Curtis距离（社区差异的定量度量） Bray-Curtis distance (a quantitative measure of community dissimilarity)
未加权的UniFrac距离（结合特征之间的系统发育关系的社区差异的定性度量） unweighted UniFrac distance (a qualitative measure of community dissimilarity that incorporates phylogenetic relationships between the features)
加权UniFrac距离（结合特征之间的系统发育关系的社区差异的定量度量） weighted UniFrac distance (a quantitative measure of community dissimilarity that incorporates phylogenetic relationships between the features)
二、命令行
需要为此脚本提供的一个重要参数是–p-sampling-depth，它是均匀的采样（即稀疏度）深度。 因为大多数多样性度量标准对不同样本之间的不同采样深度敏感，所以此脚本将随机地将每个样本的计数子采样到为此参数提供的值。

例如，如果您提供–p-sampling-depth 500，则此步骤将对每个样本中的计数进行二次采样而不进行替换，以便结果表中的每个样本的总数为500。如果任何样本的总数小于此值，这些样本将从多样性分析中删除。

选择此值很棘手。 我们建议您通过查看上面创建的table.qzv文件中提供的信息来做出选择。 选择一个尽可能高的值（以便每个样本保留更多的序列），同时排除尽可能少的样本。

查看table.qzv，尤其是该可视化文件中的“ Sample Detail”选项卡。 对于 –p-sampling-depth，您选择通过什么值？ 根据此选择，您的分析中将排除多少个样本？ 您将在 core-metrics-phylogenetic 命令中分析多少个总序列？

比如，我看到样本中，reads数最少的为 17890

qiime diversity core-metrics-phylogenetic --i-phylogeny rooted-tree.qza  --i-table table.qza  --p-sampling-depth 17890  --m-metadata-file sample-metadata.tsv --output-dir core-metrics-results
说明：

rooted-tree.qza 来自进化树分析那一步
table.qza 来自dada2，序列聚类那一步
17890来自，所有样本中样本reads数最小的那个
sample-metadata.tsv 最开始创造的样本数据
在计算了多样性指标之后，我们可以开始在样品元数据的背景下探索样品的微生物组成

分析数据可视化展现

我们将在此进行 Faith Phylogenetic Diversity（衡量社区丰富程度）和evenness指标的操作。

qiime diversity alpha-group-significance --i-alpha-diversity core-metrics-results/faith_pd_vector.qza 	--m-metadata-file sample-metadata.tsv --o-visualization core-metrics-results/faith-pd-group-significance.qzv

qiime diversity alpha-group-significance --i-alpha-diversity core-metrics-results/evenness_vector.qza --m-metadata-file sample-metadata.tsv --o-visualization core-metrics-results/evenness-group-significance.qzv
qzv可以在 https://view.qiime2.org/ 查看

qiime diversity beta-group-significance –i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza –m-metadata-file sample-metadata.tsv –m-metadata-column body-site –o-visualization core-metrics-results/unweighted-unifrac-body-site-significance.qzv –p-pairwise

参考资料
https://docs.qiime2.org/2020.6/tutorials/moving-pictures/
```

```javascript
作者：小看山路
链接：
来源：知乎
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

16S微生物生信分析全流程：从下机数据到高分图表，新手零门槛吃透！做微生物组科研，谁还没被16S rRNA测序分析难住过？原始数据无从下手、看不懂论文里的PCoA/LEfSe图、分析流程记不全漏步骤，是多数生信新手的常态。作为常年深耕微生物组数据的科研人，我把16S rRNA生信分析全流程浓缩成干货版，无晦涩术语、全是实操要点，零基础跟着做，就能轻松产出论文级图表，收藏这一篇就够！一、核心逻辑：16S测序分析的底层逻辑16S rRNA是细菌与古菌的保守标记基因，是微生物群落研究的“金标准”，适配肠道、土壤、水体等各类样本，可快速鉴定物种、解析群落结构。整套分析逻辑清晰，核心分为**质控打底→注释定种→多样性找规律→差异锁菌群→功能挖机制→关联深解析**六大模块，环环相扣，完全对标SCI论文分析标准，新手按步骤操作绝不踩坑。二、全流程拆解：五步搞定核心分析模块1：数据质控+物种注释｜根基步骤，错一步全白费下机原始数据含大量无效序列，**无质控的分析结果全是伪数据**，这一步是重中之重。核心操作：完成双端序列拼接，剔除低质量碱基、引物接头与短序列，经去噪、去除嵌合体，得到高质量ASV/OTU特征序列；物种注释：将优质序列比对Silva、Greengenes等权威数据库，完成门-纲-目-科-属水平分类，生成物种丰度表；论文图表：物种组成柱状图、属水平热图，直观展示样本基础菌群结构。模块2：群落多样性分析｜论文核心，必做必懂多样性分析是16S研究的灵魂，分为α、β多样性，直接解答微生物研究两大核心问题，是论文结果板块的核心内容。✅ α多样性：单样本物种丰富度衡量单个样本内物种数量多少、分布是否均匀，核心看Chao1（物种总数）、Shannon（丰富度+均匀度）指数，搭配稀释曲线验证测序深度，曲线平缓即说明数据量足够。✅ β多样性：样本间群落差异度分析不同组别样本的群落结构差异，常用PCoA、NMDS分析+Anosim显著性检验，图表中组别聚类越分开，说明群落差异越显著，核心出图为PCoA散点图、层级聚类树，是高分文章高频图表。模块3：差异物种筛选｜锁定文章创新关键多样性分析后，需精准锁定组间差异核心菌群，这是文章创新点的核心来源。首选LEfSe分析筛选标志性差异菌群（结合LDA分值），搭配Wilcoxon检验验证显著性，明确富集菌群。常用图表：LEfSe进化分支图、差异物种热图，一眼定位关键功能菌，避免研究泛泛而谈。模块4：功能预测与富集｜提升论文深度16S测序不直接测功能，而功能预测是从“物种描述”到“机制解析”的关键一步，能大幅提升论文档次。常用工具：PICRUSt2（通用）、FAPROTAX（环境样本专属）；可视化：功能气泡图、通路弦图，关联菌群与功能机制，增强研究说服力。模块5：关联分析+网络构建｜高分加分项想冲高分论文，必须做关联与网络分析，揭示菌群间、菌群与环境的隐秘关系。通过Mantel检验、Spearman相关性分析菌群与pH、有机质等环境因子的关联；构建共发生网络识别核心Hub菌群，分析物种共生/拮抗关系。核心图表：相关性热图、共发生网络图，是高分文章的标配高端图表。三、新手避坑3大要点（亲测干货）质控绝不偷懒：低质量序列、嵌合体必须彻底剔除，否则后续结果完全无效；数据库选对：肠道样本优先Greengenes，土壤/环境样本优先Silva，注释准确率翻倍；统计学必做：所有差异分析需标注P值/FDR值，无统计学意义的结果严禁使用。四、写在最后16S微生物生信分析流程固定、逻辑清晰，无需死记硬背，理清步骤、抓好质控与统计学检验，哪怕是零基础新手，也能快速完成从原始数据到论文图表的全流程。
```

# **Alpha多样性**

```javascript
Alpha（α）：这是某个特定栖息地内部的“局部多样性”/指的是评价单个样本内部 的物种丰富度与均匀度。它关注的不是两个样本之间有多像，而是一个样本里到底有多少种微生物，以及它们分布是否均衡。
包括物种丰富度（它对所有物种一视同仁，无论其多稀有）、香农指数（Shannon,它将每个物种按照其相对丰度加权，是使用最广泛的“有效物种数”）、​辛普森指数（它给予常见物种极大的权重，对稀有物种几乎“视而不见”）。
在16S rRNA测序、宏基因组等研究中，α多样性常用于描述菌群复杂度。一般来说，丰富度越高，样本内检测到的物种越多。 均匀度越高，说明各物种的丰度分布越接近，不会被少数菌完全主导。α多样性常被用于疾病组与对照组比较。它不是诊断结论，但能提示菌群生态状态是否发生变化。
例如，某些研究中，疾病状态可能伴随多样性下降，提示菌群生态位受损。但要注意，α多样性变化只能说明“群落结构变了”，不能直接推出致病机制。 后续仍需结合差异菌、β多样性、功能分析和临床变量一起解释。
2. 常用指标怎么理解
2.1 物种丰富度指标
最常见的丰富度指标包括Observed species、Chao1和ACE。

Observed species ，即实际观察到的物种数。
Chao1 ，偏重估计“未被完全测到的稀有物种”。
ACE ，也是估计丰富度的指标，更关注低丰度OTU。
简单理解，Observed species是“看见了多少”，Chao1和ACE是“推测实际可能有多少”。如果测序深度不足，Observed species往往会低估真实丰富度。

2.2 物种均匀度指标
均匀度常看Shannon和Simpson。

Shannon指数 同时反映丰富度和均匀度，越大通常表示多样性越高。
Simpson指数 更敏感于优势菌，常用于判断是否被少数菌主导。
要特别注意不同软件的表达方式。有些结果里，Simpson值越大表示多样性越低，有些会使用倒数或互补形式。解读前必须先确认指标定义。 这是很多初学者最容易出错的地方。

3. 实操中最关键的3个步骤
3.1 先确认数据质量，再谈多样性
α多样性不是直接从原始序列算出来的。前面必须完成质控、拼接、去嵌合体和OTU/ASV构建。否则低质量reads会虚增或虚减物种数，导致结果失真。

常规检查包括：

Raw tags、Clean tags、Effective tags是否合理。
Q20、Q30是否达到基本要求。
样本间测序量是否差异过大。
是否存在明显离群样本。
如果基础质控不过关，后面的α多样性没有解释价值。

3.2 统一抽平深度，避免测序量偏差
不同样本的测序量不一致时，α多样性容易被“深度差异”影响。常见做法是进行稀释分析或抽平处理，让样本在相对可比的深度上计算多样性。

判断标准通常看稀释曲线：

曲线趋于平坦，说明新增测序量带来的新物种很少。
曲线仍快速上升，说明测序深度可能不足。
稀释曲线不平稳时，不建议仓促解读α多样性。 否则样本间差异可能只是测序量不同，而不是菌群本身不同。

3.3 统计比较要和分组设计一致
α多样性比较通常用于两组或多组之间。统计方法要依据数据分布选择。常见是t检验、Wilcoxon秩和检验或Kruskal-Wallis检验。

在临床研究中，还应同步记录：

年龄
性别
用药史
饮食
抗生素暴露
疾病分期
因为这些因素都可能影响菌群。如果分组不平衡，α多样性的差异未必来自疾病本身。

4. 结果解读时要避开的误区
4.1 不要把“显著差异”直接等同于“生物学意义大”
统计学显著，只说明组间差异不是偶然。它不代表差异一定足够大，也不代表可以直接指导临床决策。

有时两个组的Shannon差异显著，但实际效应量很小。相反，也可能因为样本量不足而未检出差异。所以需要同时看P值、效应量和分布图。

4.2 不要只看一个指标
单一指标容易误导。比如：

Chao1升高，说明丰富度可能上升。
但Shannon不变，提示均匀度没有明显改善。
Simpson下降，可能说明优势菌更集中。
因此，最好联合观察多个指标，而不是只拿一个数下结论。丰富度和均匀度回答的问题本来就不同。

4.3 不要忽视可视化
箱线图、散点图、柱状图各有用途。箱线图适合看组间分布和离群值，散点图更适合看个体差异。对于医学生和科研人员，建议优先关注原始点分布，而不是只看均值。

如果样本量较小，个体波动很大，图上即使有差异，也应谨慎解释。小样本研究更适合做探索，不宜过度外推。

5. 从数据到结论，如何形成规范分析路径
5.1 推荐的分析顺序
一个相对规范的α多样性分析流程如下：

完成测序质控和OTU/ASV构建。
检查稀释曲线和样本覆盖度。
计算Observed species、Chao1、ACE、Shannon、Simpson。
按组别绘制箱线图或小提琴图。
进行组间统计检验。
结合临床信息解释结果。
这个流程的核心是，先保证数据可比，再讨论差异是否真实存在。

5.2 如何把结果写进论文
论文中建议避免绝对化表述。可以写成：

“与对照组相比，病例组Shannon指数下降，提示群落均匀度降低。”
“Chao1指数无显著差异，提示丰富度变化有限。”
“结果提示菌群生态结构发生改变，但仍需进一步机制验证。”
这种写法更符合E-E-A-T原则，也更符合审稿人的预期。结论要克制，证据要充分。

5.3 α多样性与β多样性要联动看
α多样性回答的是“每个样本内部如何”。β多样性回答的是“样本之间是否不同”。如果只看α多样性，可能看不出组间群落结构的整体分离。

在实际研究中，常见情况是：

α多样性无差异，但β多样性有明显分离。
α多样性下降，同时β多样性也显著改变。
这说明菌群变化并不只有“多或少”的问题，还包括群落结构重排。因此，α多样性只是第一步，不是终点。

6. 实战中的效率提升与工具选择
6.1 自建分析常见痛点
很多团队在α多样性分析上耗时较长，主要卡在数据整理、图表规范化和统计解释。尤其是多组比较、重复样本和临床变量纳入时，分析链条会迅速变复杂。

对于医学生、医生和科研人员来说，真正的效率瓶颈往往不是“不会算”，而是“不会规范地串起整个流程”。这也是为什么越来越多研究者会借助成熟平台来完成标准化分析。

6.2 借助解螺旋提升分析效率
如果你希望把更多时间放在科研问题本身，而不是反复处理数据格式和出图细节，解螺旋可以帮助你把α多样性分析流程做得更规范。 从质控、统计到可视化，能更高效地输出可用于论文和汇报的结果，减少低级错误和重复劳动。

总结Conclusion
α多样性分析的核心，是评估单个样本内部的物种丰富度与均匀度。它依赖高质量数据、合理抽平、正确统计和谨慎解读。只有把指标含义、分析流程和临床背景结合起来，结果才有研究价值。 如果你希望更高效地完成微生物组数据分析和图表输出，可以进一步了解解螺旋，让标准化分析帮助你更快得到可靠结论。
```

```javascript
QIIME 2分析主要包括序列处理分析、物种组成分析、Alpha多样性分析、Beta多样性分析、物种差异与标志物种分析、关联网络分析和功能潜能预测共7大分析模块，每个模块下又包含多种分析方法和步骤。
01、 物种组成分析
在这一模块中，最常用的就是“分类学组成分析”了：可以通过堆积柱状图，展现各个/各组群落样本中，微生物的物种组成，主要用于描述群落样本中的优势物种的丰度及其变化规律。图中，每一个柱子代表一个群落样本或一个分组，每种颜色代表某一特定分类水平下（门/纲/目/科/属/种）的一种微生物，柱子越长，对应物种的丰度就越高。
此外，我们也可以通过“Krona物种组成图”，对物种组成进行交互展示。与上述堆积柱状图不同，Krona分析是以圈图的形式展示，从内到外依次代表域、门、纲、目、科、属、种共7个分类水平，并可以点击进入对应分类水平的物种类群；扇形的大小反映了不同分类单元的相对丰度，各个分类单元以不同的颜色加以区分。

在Krona圈图展示页面的左上方，提供了多个图形可视化选项，可通过点击相应按钮调整图形的尺寸和显示的分类水平深度等；同时，点击图形中某一分类单元，将在圈图右上方显示其在各分类层次中所占的比例。

一般而言，Krona分析常用于比较各个分组的总体群落组成的差异，且能够通过圈图同时展现各个分类水平的物种组成特征。因此，可以作为堆积柱状图的替代方案，在研究报告中加以应用。
02、 Alpha多样性分析
Alpha多样性是微生态学研究中的重要评价标准之一，主要通过Alpha多样性指数的大小，来衡量各个/各组群落样本中微生物物种的多样性、丰富度、均匀度、覆盖度等等。目前云分析支持7种最常见Alpha多样性指数的计算，每种指数的具体意义与详细用法，可以通过“附录”进行查询。总体而言， Chao1和Observed species指数表征丰富度，Shannon和Simpson指数表征多样性，Faith’s PD指数表征基于进化的多样性，Pielou’s evenness指数表征均匀度，Good’s coverage指数表征覆盖度：
更详细的算法说明请参见：

http://scikit-bio.org/docs/latest/generated/skbio.diversity.alpha.html

对于分析得到的每个群落样本的Alpha多样性指数，可以通过箱线图来展示比较组间Alpha多样性指数的差异大小。图中，每一个箱子代表一个分组，组与组之间的差异可以通过箱子内的中位线的高低来表征，中位线相差越大，则两组间的多样性差异越大。箱子上方的P值指示该多样性指数在所有分组之间是否具有显著差异；而箱子上方的直线，则指示直线两端所属的分组，是否具有显著差异，直线上的星号越多，显著性越强。
```

```javascript
#!/bin/bash
#SBATCH --job-name=alpha_div
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -p cu
#SBATCH --mem=10G
#SBATCH -o output/alpha_div_%a.out
#SBATCH -e output/alpha_div_%a.err
#SBATCH --array=1
#SBATCH --exclude=cu01

source aactivate QIIME2_ENV

study_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" ../../data/project_list.txt | tr -d '\r\n')

### mkdir alpha file
mkdir /beegfs/dongbiao/oral/${study_id}/results/alpha
path=/beegfs/dongbiao/oral/${study_id}/results/alpha

### getting oral metadata and biom file for qiiem2 input
filter_metadata_for_QIIME2.py \
    ../../data/projects/${study_id}/metadata_v2.csv \
    /beegfs/dongbiao/oral/${study_id}/results/DADA2.biom \
    ${path}

### import biom to QIIME2 and metadata
qiime tools import \
  --type 'FeatureTable[Frequency]' \
  --input-path ${path}/DADA2.biom \
  --input-format BIOMV210Format \
  --output-path ${path}/feature-table.qza
qiime feature-table rarefy \
  --i-table ${path}/feature-table.qza \
  --p-sampling-depth 1000 \
  --o-rarefied-table ${path}/rarefied-table.qza

### build tree
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path ${path}/rep-seqs.fasta \
  --output-path ${path}/rep-seqs.qza
  
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences ${path}rep-seqs.qza \
  --o-alignment ${path}/aligned-rep-seqs.qza \
  --o-masked-alignment ${path}/masked-aligned-rep-seqs.qza \
  --o-tree ${path}/unrooted-tree.qza \
  --o-rooted-tree ${path}/rooted-tree.qza

### caculate alpha diversity
# Shannon
qiime diversity alpha \
  --i-table ${path}/rarefied-table.qza \
  --p-metric shannon \
  --o-alpha-diversity ${path}/shannon.qza

# Observed Features
qiime diversity alpha \
  --i-table ${path}/rarefied-table.qza \
  --p-metric observed_features \
  --o-alpha-diversity ${path}/observed-features.qza

# Simpson 
qiime diversity alpha \
  --i-table ${path}/rarefied-table.qza \
  --p-metric simpson \
  --o-alpha-diversity ${path}/simpson.qza

# Faith's PD
qiime diversity alpha-phylogenetic \
  --i-table ${path}/rarefied-table.qza \
  --i-phylogeny ${path}/rooted-tree.qza \
  --p-metric faith_pd \
  --o-alpha-diversity ${path}/faith-pd.qza
```


\

# **Beta多样性**

```javascript
Beta（β）：这是不同栖息地之间物种组成的“差异性”。
Beta多样性分析主要用于比较各样本中微生物群落整体结构的差异。通过QIIME 2云分析，我们共计算了4种常见的Beta多样性距离，每种距离均可用于Beta多样性分析，但都有针对性的应用场景。对于这4种距离的介绍，可以参见“附录 / 附表 / Beta多样指数简介”：
具体的分析内容，主要包括PCoA分析、NMDS分析、层次聚类分析和组间差异分析：
1、 距离矩阵与PCoA分析

PCoA分析中即我们常见的主坐标分析，一般通过二维或三维散点图来进行展示。图中，每个点代表一个微生物群落样本，不同样本或分组用不同颜色/图形表示，点与点在坐标轴上的投影距离越远，则对应两个群落样本中的整体组成结构差异越大。同时，坐标轴括号中的百分比，代表了对应的坐标轴所能解释的样本差异数据（距离矩阵）的比例。

比如下图中A组与B组的群落样本，在PCoA1轴上的投影距离较远，但在PCoA2轴上的投影距离很近，表明两组群落样本在第一轴的维度上具有较大差异，但在第二轴的维度上却很相似；第一轴解释了约22.2%的样本间差异，而第二轴则解释了约18.3%的样本间差异。
当然，我们也可以通过QIIME 2专有的QZV文件，在网站中（https://view.qiime2.cn/）实现三维可视化展示
2、 NMDS分析

NMDS分析即非量度多维尺度分析，与PCoA相似，每个点代表一个群落样本，不同样本或分组用不同颜色/图形表示。与PCoA不同的是，NMDS分析不用参考投影距离，而是直接通过样本之间直线距离的远近，衡量群落组成结构的差异大小。因此，可近似认为两点之间的距离越近（远），表明两个样本中微生物群落的整体组成结构差异越小（大）。

另外，图片上方的Stress值表明分析结果的应力值，可用于衡量分析结果的可靠性。一般而言，当Stress值小于0.2时，NMDS分析的结果较可靠。
3、 层次聚类分析

层次聚类分析由左右两部分组成：左图代表群落样本的层次聚类树图，右图代表物种组成的堆叠柱状图。

左图中，样本根据彼此之间的相似度聚类，样本间的分支长度越短、聚类效果越好，则两样本的群落整体组成结构越相似；右图默认显示丰度排名前10（或分析时自定义的个数）的属水平（或分析时自定义的分类水平）微生物组成，丰度越高，柱子长度越长。下图示例中，A、B、C三组样本分别聚类形成三个分枝，表明三组群落样本的整体组成结构有明显差异；同时，A组样本中，A02和A05样本，与组内其它样本的整体组成结构有较大不同，形成了独立的聚类分枝。而右图的物种组成，则从优势物种丰度分布的角度，进一步展现了上述的群落组成结构差异。
4、 组间差异分析

组间差异分析用于比较组内差异与组间差异。具体而言，组内差异指的是指定分组内的群落样本之间的距离大小，组间差异是指该分组内的群落样本，与其余各分组的样本间的距离大小。距离值通过箱线图进行展示，以体现各组内/组间比较的差异大小。箱的上下端线代表上下四分位数（Interquartile range，IQR）；箱中的横线代表中位数；箱外延伸的上下触须的边缘，对应1.5倍的IQR范围之内的极值（最大值和最小值）；在触须边缘外部的点，表示离群的异常值。

图形上方可以指定组内/组间比较所需参考的分组。图中，第一个箱线图代表组内差异，中位线越低、触须越短，则表明组内差异越小、组内群落样本的重复性越好。其余箱线图则代表指定分组与其余各分组间的组间差异，中位线越高，表明组间差异越大（一般而言，一个理想的研究设计，应当是组内差异显著小于组间差异的）。
同时，我们也提供组间两两差异比较的P值与Q值，P值或Q值小于0.05时，一般认为有统计学意义的显著性。
```

```javascript
生态学家用α多样性和β多样性来描述物种在生境内和和生境间的多样性，综合评价总体的多样性。α多样性描述的是物种内的丰富度、多样性、均匀度等指标，因此也被称为生境内多样性，通常用箱线图来展现特征，用稀疏曲线样来评估测序深度。β多样性指沿着环境梯度的变化，不同群落之间物种组成的差异性或是更替的速率，因此也被称为生境间多样性，通用PCoA图来展示不同样或者组本间距离。

小果以前的文章曾用过qiime2的这个软件来得到特征表和特征序列，它不仅可以解决前期的数据处理的部分，用于分析多样性的分析也是非常方便的。

α，β多样性数据分析:
1、可以打包输出多样性指数，根据数据绘制箱线图。

qiime diversity core-metrics-phylogenetic \
--i-phylogeny rooted-tree.qza \
--i-table table.qza \
--p-sampling-depth 14208\
--m-metadata-file Seed-matadata.tsv \
--output-dir core-metrics-results
进化关系faith-PD、evenness数值可视化、香浓指数可视化、物种数目可视化等可视化，XXX代表打包输出的任意一种多样性指数的qza文件
qiime diversity alpha-group-significance \
--i-alpha-diversity core-metrics-results/XXX.qza \
--m-metadata-file metadata.tsv \
--o-visualization core-metrics-results/XXX.qzv
2、也可以根据自己的需要计算α多样性和β多样性

qiime diversity alpha-rarefaction \
--i-table table_filtered.qza \
--i-phylogeny rooted_tree.qza \
--p-metrics chao1 shannon simpson observed_otus pielou_e faith_pd  goods_coverage \
--p-max-depth 14208 \ 
--m-metadata-file map.txt 
--o-visualization alpha-rarefaction
说明：--p-metrics选择不同的参数
qiime diversity beta-phylogenetic \
--i-table table_filtered.qza \
--i-phylogeny rooted-tree.qza \
--p-metric [weighted_unifrac|unweighted_unifrac] \#选择参数 
--o-distance-matrix unweighted_unifrac_distance_matrix.qza#输出qza格式文件
说明：考虑进化关系计算β多样性
qiime diversity beta \ 
--i-table table.qza \#输入OTU表
--p-metric [correlation|sokalmichener|russellrao|hamming|rogerstanimoto|chebyshev|cityblock|kulsinski|sqeuclidean|braycurtis|yule|matching|jaccard|canberra|euclidean|seuclidean|sokalsneath|wminkowski|dice|mahalanobis|cosine]\#选择参数
--o-distance-matrix unweighted_unifrac_distance_matrix.qza #输出qza格式文件
qiime diversity core-metrics \
--i-table table_filtered.qza \
--m-metadata-file map.txt 
--p-sampling-depth 14208 \
--output-dir bdiv
说明：不考虑进化关系计算β多样性

以上所有输出的后缀为.qzv的格式的文件都可以在https://view.qiime2.org网站上拖动查看数据的分析结果，非常方便。如果对于图片的展示结果并不满意，可以用R进行绘图。
Aphla绘图：
一般用箱线图来展示Aphla的结果。

df <- read.table("./Shannon.txt",header = T,sep = "\t")
#这里处理数据的过程可以根据实际情况而定
head(df)

p <- ggplot(df,aes(group,Chao1)) + geom_boxplot(aes(fill=group)) + theme_set(theme_bw())

#用ggplot绘制箱线图，其它的Aphla多样性指数也是一样的绘制相应的图

Beta多样性指数
beta 多样性指数也一般用PCA、NMDS呈现，用两组检验进行验证。在小果的以前的文章中也有详细的讲解过怎样做PCA图，对于NMDS分析也可以用R中的venn包实现。具体的操作需要一篇新的文章才能讲完。

下图为PCA图和NMDS展示的Beta多样性的分析。



通过qiime2强大的扩增子分析平台我们不仅可以处理前期的丰度表数据，也能够利用其分析多样性分析，并能够用可视化结果。但是往往放在论文中的图片都是经过无数次的打磨的。因此我们在得到数据结果的基础上需要对数据进行更好的图形呈现。这也是无数R开发工作者在努力的目标，为科研添一点美感～

好了，这样我们微生物组的多样性就分析完成了。小伙伴们如果有什么问题就和小果讨论吧～
```


\
```javascript
# QIIME2 2020.11分析流程

## 0. 软件安装
	# 仅限在Linux/Mac系统中运行，
	# Windows用户使用服务器、内置子系列(支持右键粘贴)或VirtualBox虚拟机中的Linux运行
	# 详细教程参阅官网https://docs.qiime2.org/2020.11/，或QIIME2教程专辑 https://mp.weixin.qq.com/s/vlc2uIaWnPSMhPBeQtPR4w


## 1. 准备工作

	# 设置工作目录，如服务器为~/qiime2，Win子系统C盘中为
	wd=/mnt/c/qiime2/
	# 进入工作目录
	mkdir -p ${wd}
	cd ${wd}
	# 激活QIIME2工作环境，旧版conda使用source替换conda运行
	conda activate qiime2-2020.11

	# 准备样本元信息metadata、原始数据seq/*.fastq和manifest
	# 下载示例元数据供参考
	wget -c http://210.75.224.110/github/MicrobiomeProtocol/e2.QIIME2/metadata.txt
	# 下载测试数据供测试流程，按GSA的CRA(批次)和CRR(样品)编号下载数据
    mkdir -p seq
  	awk '{system("wget -c ftp://download.big.ac.cn/gsa/"$5"/"$6"/"$6"_f1.fq.gz -O seq/"$1"_1.fq.gz")}' \
        <(tail -n+2 metadata.txt)
   	awk '{system("wget -c ftp://download.big.ac.cn/gsa/"$5"/"$6"/"$6"_r2.fq.gz -O seq/"$1"_2.fq.gz")}' \
        <(tail -n+2 metadata.txt)
	# 检查文件大小，确定是否下载完整或正常
	ls -lsh seq
	# 根据metadata生成manifest文件
	awk 'NR==1{print "sample-id\tforward-absolute-filepath\treverse-absolute-filepath"} \
	  NR>1{print $1"\t$PWD/seq/"$1"_1.fq.gz\t$PWD/seq/"$1"_2.fq.gz"}' \
	  metadata.txt > manifest

	# 数据导入qiime2，格式为双端33格式
	qiime tools import \
	  --type 'SampleData[PairedEndSequencesWithQuality]' \
	  --input-path manifest \
	  --output-path demux.qza \
	  --input-format PairedEndFastqManifestPhred33V2
	# fq文件1G用时7m，fq.gz压缩格式仅34s


## 2. 生成特征表和代表序列

### 方法1. DADA2 (慢，依赖R和Python包多容易报错)

	# 支持多线程加速，服务器0/96p, 34m；24p, 44m；8p, 77m；1p, 462m
	# Win10下12线程65m，机时538分
	time qiime dada2 denoise-paired \
	  --i-demultiplexed-seqs demux.qza \
	  --p-n-threads 12 \
	  --p-trim-left-f 29 --p-trim-left-r 18 \
	  --p-trunc-len-f 0 --p-trunc-len-r 0 \
	  --o-table dada2-table.qza \
	  --o-representative-sequences dada2-rep-seqs.qza \
	  --o-denoising-stats denoising-stats.qza
	# 确定使用dada2结果并导入主流程
	cp dada2-table.qza table.qza
	cp dada2-rep-seqs.qza rep-seqs.qza

### 方法2. 外部导入特征表和代表序列(常用)，详见附录


### 特征表和代表序列统计

	qiime feature-table summarize \
	  --i-table table.qza \
	  --o-visualization table.qzv \
	  --m-sample-metadata-file metadata.txt
	qiime feature-table tabulate-seqs \
	  --i-data rep-seqs.qza \
	  --o-visualization rep-seqs.qzv
	# 下载qzv在线查看，dada2只有1千多个ASV


## 3. Alpha和beta多样性分析

### 构建进化树用于多样性分析 53s
	qiime phylogeny align-to-tree-mafft-fasttree \
	  --i-sequences rep-seqs.qza \
	  --o-alignment aligned-rep-seqs.qza \
	  --o-masked-alignment masked-aligned-rep-seqs.qza \
	  --o-tree unrooted-tree.qza \
	  --o-rooted-tree rooted-tree.qza

### 计算核心多样性 
	# 13s，采样深度通常选择最小值，来自table.qzv
	qiime diversity core-metrics-phylogenetic \
	  --i-phylogeny rooted-tree.qza \
	  --i-table table.qza \
	  --p-sampling-depth 7000 \
	  --m-metadata-file metadata.txt \
	  --output-dir core-metrics-results

### Alpha多样性组间显著性分析和可视化
	# 7s, 可选的alpha指数有 faith_pd、shannon、observed_features、evenness
	index=observed_features
	qiime diversity alpha-group-significance \
	  --i-alpha-diversity core-metrics-results/${index}_vector.qza \
	  --m-metadata-file metadata.txt \
	  --o-visualization core-metrics-results/${index}-group-significance.qzv

### Alpha多样性稀疏曲线
	# 25s, max-depth选最大值，来自table.qzv
	qiime diversity alpha-rarefaction \
	  --i-table table.qza \
	  --i-phylogeny rooted-tree.qza \
	  --p-max-depth 10000 \
	  --m-metadata-file metadata.txt \
	  --o-visualization alpha-rarefaction.qzv
	# 结果有observed_otus, shannon, 和faith_pd三种指数可选

### Beta多样性组间显著性分析和可视化
	# 可选的beta指数有 unweighted_unifrac、bray_curtis、weighted_unifrac和jaccard
	# 7s, 指定分组是减少计算量，置换检验较耗时
	distance=weighted_unifrac
	column=Group
	qiime diversity beta-group-significance \
	  --i-distance-matrix core-metrics-results/${distance}_distance_matrix.qza \
	  --m-metadata-file metadata.txt \
	  --m-metadata-column ${column} \
	  --o-visualization core-metrics-results/${distance}-${column}-significance.qzv \
	  --p-pairwise


## 4. 物种组成分析

	### 物种注释
	# 4m classifier_gg_13_8_99_V5-V7.qza 是我用V5-V7训练的文件，详见附录或官方教程
	qiime feature-classifier classify-sklearn \
	  --i-classifier classifier_gg_13_8_99_V5-V7.qza \
	  --i-reads rep-seqs.qza \
	  --o-classification taxonomy.qza
	# 可视化物种注释
	qiime metadata tabulate \
	  --m-input-file taxonomy.qza \
	  --o-visualization taxonomy.qzv

	# 堆叠柱状图展示
	qiime taxa barplot \
	  --i-table table.qza \
	  --i-taxonomy taxonomy.qza \
	  --m-metadata-file metadata.txt \
	  --o-visualization taxa-bar-plots.qzv


## 5. 差异分析ancom

	# 格式化特征表，添加伪计数，7s
	qiime composition add-pseudocount \
	  --i-table table.qza \
	  --o-composition-table comp-table.qza

	# 计算差异特征，指定分组类型比较，7m
	column=Group
	time qiime composition ancom \
	  --i-table comp-table.qza \
	  --m-metadata-file metadata.txt \
	  --m-metadata-column ${column} \
	  --o-visualization ancom-${column}.qzv

	# 按属水平合并，并统计
	## 按属水平合并，6s
	qiime taxa collapse \
	  --i-table table.qza \
	  --i-taxonomy taxonomy.qza \
	  --p-level 6 \
	  --o-collapsed-table table-l6.qza
	# 格式化特征表，添加伪计数，6s
	qiime composition add-pseudocount \
	  --i-table table-l6.qza \
	  --o-composition-table comp-table-l6.qza
	# 计算差异属，指定分组类型比较，16s
	qiime composition ancom \
	  --i-table comp-table-l6.qza \
	  --m-metadata-file metadata.txt \
	  --m-metadata-column ${column} \
	  --o-visualization l6-ancom-${column}.qzv



# 附录

## 1. qiime2 2020.11安装


	# Conda下载、安装
	wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
	bash Miniconda3-latest-Linux-x86_64.sh -b -f
	# 添加至默认环境
	~/miniconda2/bin/conda init
	# 下载软件安装清单，有410个软件，通过4个conda频道安装，但在google服务器下载困难
	# wget -c https://data.qiime2.org/distro/core/qiime2-2020.11-py36-linux-conda.yml
	# 下载失败时，可在 https://github.com/YongxinLiu/QIIME2ChineseManual 下载或使用备用链接
	wget -c http://210.75.224.110/github/QIIME2ChineseManual/2020.11/qiime2-2020.11-py36-linux-conda.yml
	# conda安装QIIME 2(仅运行1次)，我用时33m，供参考，主要由网速决定
	conda env create -n qiime2-2020.11 --file qiime2-2020.11-py36-linux-conda.yml

	# 进入工作环境
	conda activate qiime2-2020.11


## 2. 物种注释数据训练集

	# 下载数据库文件(greengenes)
	wget -c ftp://greengenes.microbio.me/greengenes_release/gg_13_5/gg_13_8_otus.tar.gz
	# 国内备用链接
	# wget -c http://210.75.224.110/db/GreenGenes/gg_13_8_otus.tar.gz
	# 解压
	tar -zxvf gg_13_8_otus.tar.gz
	
	# 使用rep_set文件中的99_otus.fasta数据和taxonomy中的99_OTU_taxonomy.txt数据作为参考物种注释
	# 导入参考序列，50s
	qiime tools import \
	  --type 'FeatureData[Sequence]' \
	  --input-path gg_13_8_otus/rep_set/99_otus.fasta \
	  --output-path 99_otus.qza
	# 导入物种分类信息，6s
	qiime tools import \
	  --type 'FeatureData[Taxonomy]' \
	  --input-format HeaderlessTSVTaxonomyFormat \
	  --input-path gg_13_8_otus/taxonomy/99_otu_taxonomy.txt \
	  --output-path ref-taxonomy.qza

	# Train the classifier（训练分类器）——全长，30m
	time qiime feature-classifier fit-classifier-naive-bayes \
	  --i-reference-reads 99_otus.qza \
	  --i-reference-taxonomy ref-taxonomy.qza \
	  --o-classifier classifier_gg_13_8_99.qza
	  
	# 引物提取参考序列的扩增区段 Extract reference reads
	# 常用Greengenes 13_8 99% OTUs from 341F CCTACGGGNGGCWGCAG/805R GACTACHVGGGTATCTAATCC region of sequences（分类器描述），提供测序的引物序列，截取对应的区域进行比对，达到分类的目的。
	# 本次使用799F-1193R, 8m
	time qiime feature-classifier extract-reads \
	  --i-sequences 99_otus.qza \
	  --p-f-primer AACMGGATTAGATACCCKG \
	  --p-r-primer ACGTCATCCCCACCTTCC \
	  --o-reads ref-seqs.qza

	# Train the classifier（训练分类器）
	# 基于筛选的指定区段，生成实验特异的分类器，14m
	time qiime feature-classifier fit-classifier-naive-bayes \
	  --i-reference-reads ref-seqs.qza \
	  --i-reference-taxonomy ref-taxonomy.qza \
	  --o-classifier classifier_gg_13_8_99_V5-V7.qza

### 常见问题3：scikit-learn版本不兼容，重新构建训练集即可

	Plugin error from feature-classifier:
	  The scikit-learn version (0.21.2) used to generate this artifact does not match the current version of scikit-learn installed (0.22.1). Please retrain your classifier for your current deployment to prevent data-corruption errors.
	Debug info has been saved to /tmp/qiime2-q2cli-err-5ngzk2hm.log

### 常见问题4. 外部导入特征表和代表序列(常用)

	# 上传其他流程生成的OTU表otutab.txt和代表序列otus.fa
	wget -c http://210.75.224.110/github/MicrobiomeProtocol/e2.QIIME2/otutab.txt
	wget -c http://210.75.224.110/github/MicrobiomeProtocol/e2.QIIME2/otus.fa
	# 转换文本为Biom1.0，注意biom --version 2.1.5/8可以，2.1.7报错
	biom convert -i otutab.txt -o otutab.biom \
	  --table-type="OTU table" --to-json
	# 导入特征表，9s
	qiime tools import --input-path otutab.biom \
	  --type 'FeatureTable[Frequency]' --input-format BIOMV100Format \
	  --output-path table.qza
	# 导入代表序列，8s
	qiime tools import --input-path otus.fa \
	  --type 'FeatureData[Sequence]' \
	  --output-path rep-seqs.qza

### 常见问题5. 导出特征表和代表序列

    # 导出特征表为biom格式
    qiime tools export \
      --input-path table.qza \
      --output-path feature-table
    # 转换为tsv格式
    biom convert -i feature-table/feature-table.biom \
      -o feature-table/feature-table.txt \
      --to-tsv
    # 删除注释行
    sed -i '/# Const/d' feature-table/feature-table.txt
    
    # 导出代表序列
    qiime tools export \
      --input-path rep-seqs.qza \
      --output-path rep-seqs
    
    # 导出物种注释
    qiime tools export \
      --input-path taxonomy.qza \
      --output-path taxonomy
    
```

```javascript
# QIIME2 2021.2分析流程
	
	# 注：本文以QIIME 2 2021.2版本为例，访问https://docs.qiime2.org/或查询最新版
	
## 0. 软件安装
	# 仅限在Linux/Mac系统中运行
	# Windows用户可选使用服务器、内置Linux子系列Ubuntu(支持右键粘贴)或VirtualBox虚拟机中的Linux运行
	# 详细教程参阅官网https://docs.qiime2.org/2021.2/，或中文教程见宏基因组公众号 https://mp.weixin.qq.com/s/5jQspEvH5_4Xmart22gjMA QIIME2教程部分
	# 安装代码见附录

## 1. 准备工作

	# 设置工作目录，如服务器为~/qiime2，Win子系统C盘中为
	wd=/mnt/c/qiime2/
	# 进入工作目录
	mkdir -p ${wd}
	cd ${wd}
	# 激活QIIME2工作环境，旧版conda使用source替换conda运行
	conda activate qiime2-2021.2

	# 准备样本元信息metadata、原始数据seq/*.fastq和manifest
	# 下载示例元数据供参考
	wget -c http://210.75.224.110/github/MicrobiomeProtocol/e2.QIIME2/metadata.txt
	# 下载测试数据供测试流程，按GSA的CRA(批次)和CRR(样品)编号下载数据
    mkdir -p seq
  	awk '{system("wget -c ftp://download.big.ac.cn/gsa/"$5"/"$6"/"$6"_f1.fq.gz -O seq/"$1"_1.fq.gz")}' \
        <(tail -n+2 metadata.txt)
   	awk '{system("wget -c ftp://download.big.ac.cn/gsa/"$5"/"$6"/"$6"_r2.fq.gz -O seq/"$1"_2.fq.gz")}' \
        <(tail -n+2 metadata.txt)
	# 检查文件大小，确定是否下载完整或正常
	ls -lsh seq
	# 根据metadata生成manifest文件
	awk 'NR==1{print "sample-id\tforward-absolute-filepath\treverse-absolute-filepath"} \
	  NR>1{print $1"\t$PWD/seq/"$1"_1.fq.gz\t$PWD/seq/"$1"_2.fq.gz"}' \
	  metadata.txt > manifest

	# 数据导入qiime2，格式为双端33格式
	qiime tools import \
	  --type 'SampleData[PairedEndSequencesWithQuality]' \
	  --input-path manifest \
	  --output-path demux.qza \
	  --input-format PairedEndFastqManifestPhred33V2
	# fq文件1G用时7m，fq.gz压缩格式仅34s


## 2. 生成特征表和代表序列

### 方法1. DADA2 (慢，依赖R和Python包多容易报错)

	# 支持多线程加速，服务器0/96p, 34m；24p, 44m；8p, 77m；1p, 462m
	# Win10下12线程65m，机时538分
	time qiime dada2 denoise-paired \
	  --i-demultiplexed-seqs demux.qza \
	  --p-n-threads 0 \
	  --p-trim-left-f 29 --p-trim-left-r 18 \
	  --p-trunc-len-f 0 --p-trunc-len-r 0 \
	  --o-table dada2-table.qza \
	  --o-representative-sequences dada2-rep-seqs.qza \
	  --o-denoising-stats denoising-stats.qza
	# 确定使用dada2结果并导入主流程
	cp dada2-table.qza table.qza
	cp dada2-rep-seqs.qza rep-seqs.qza

### 方法2. 外部导入特征表和代表序列(常用)，详见附录


### 特征表和代表序列统计

	qiime feature-table summarize \
	  --i-table table.qza \
	  --o-visualization table.qzv \
	  --m-sample-metadata-file metadata.txt
	qiime feature-table tabulate-seqs \
	  --i-data rep-seqs.qza \
	  --o-visualization rep-seqs.qzv
	# 下载qzv在线查看，dada2只有1千多个ASV


## 3. Alpha和beta多样性分析

### 构建进化树用于多样性分析 53s
	qiime phylogeny align-to-tree-mafft-fasttree \
	  --i-sequences rep-seqs.qza \
	  --o-alignment aligned-rep-seqs.qza \
	  --o-masked-alignment masked-aligned-rep-seqs.qza \
	  --o-tree unrooted-tree.qza \
	  --o-rooted-tree rooted-tree.qza

### 计算核心多样性 
	# 13s，采样深度通常选择最小值，来自table.qzv
	qiime diversity core-metrics-phylogenetic \
	  --i-phylogeny rooted-tree.qza \
	  --i-table table.qza \
	  --p-sampling-depth 7000 \
	  --m-metadata-file metadata.txt \
	  --output-dir core-metrics-results

### Alpha多样性组间显著性分析和可视化
	# 7s, 可选的alpha指数有 faith_pd、shannon、observed_features、evenness
	index=observed_features
	qiime diversity alpha-group-significance \
	  --i-alpha-diversity core-metrics-results/${index}_vector.qza \
	  --m-metadata-file metadata.txt \
	  --o-visualization core-metrics-results/${index}-group-significance.qzv

### Alpha多样性稀疏曲线
	# 25s, max-depth选最大值，来自table.qzv
	qiime diversity alpha-rarefaction \
	  --i-table table.qza \
	  --i-phylogeny rooted-tree.qza \
	  --p-max-depth 10000 \
	  --m-metadata-file metadata.txt \
	  --o-visualization alpha-rarefaction.qzv
	# 结果有observed_otus, shannon, 和faith_pd三种指数可选

### Beta多样性组间显著性分析和可视化
	# 可选的beta指数有 unweighted_unifrac、bray_curtis、weighted_unifrac和jaccard
	# 7s, 指定分组是减少计算量，置换检验较耗时
	distance=weighted_unifrac
	column=Group
	qiime diversity beta-group-significance \
	  --i-distance-matrix core-metrics-results/${distance}_distance_matrix.qza \
	  --m-metadata-file metadata.txt \
	  --m-metadata-column ${column} \
	  --o-visualization core-metrics-results/${distance}-${column}-significance.qzv \
	  --p-pairwise


## 4. 物种组成分析

	### 物种注释
	# 4m classifier_gg_13_8_99_V5-V7.qza 是我用V5-V7训练的文件，详见附录或官方教程
	qiime feature-classifier classify-sklearn \
	  --i-classifier classifier_gg_13_8_99_V5-V7.qza \
	  --i-reads rep-seqs.qza \
	  --o-classification taxonomy.qza
	# 可视化物种注释
	qiime metadata tabulate \
	  --m-input-file taxonomy.qza \
	  --o-visualization taxonomy.qzv

	# 堆叠柱状图展示
	qiime taxa barplot \
	  --i-table table.qza \
	  --i-taxonomy taxonomy.qza \
	  --m-metadata-file metadata.txt \
	  --o-visualization taxa-bar-plots.qzv


## 5. 差异分析ancom

	# 格式化特征表，添加伪计数，7s
	qiime composition add-pseudocount \
	  --i-table table.qza \
	  --o-composition-table comp-table.qza

	# 计算差异特征，指定分组类型比较，7m
	column=Group
	time qiime composition ancom \
	  --i-table comp-table.qza \
	  --m-metadata-file metadata.txt \
	  --m-metadata-column ${column} \
	  --o-visualization ancom-${column}.qzv

	# 按属水平合并，并统计
	## 按属水平合并，6s
	qiime taxa collapse \
	  --i-table table.qza \
	  --i-taxonomy taxonomy.qza \
	  --p-level 6 \
	  --o-collapsed-table table-l6.qza
	# 格式化特征表，添加伪计数，6s
	qiime composition add-pseudocount \
	  --i-table table-l6.qza \
	  --o-composition-table comp-table-l6.qza
	# 计算差异属，指定分组类型比较，16s
	qiime composition ancom \
	  --i-table comp-table-l6.qza \
	  --m-metadata-file metadata.txt \
	  --m-metadata-column ${column} \
	  --o-visualization l6-ancom-${column}.qzv



# 附录

## 1. qiime2 2021.2安装

	# Conda下载、安装(已安装过跳过)
	wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
	bash Miniconda3-latest-Linux-x86_64.sh -b -f
	# 添加至默认环境
	~/miniconda3/bin/conda init
	
	# 方法1. 下载软件安装清单安装，访问 https://docs.qiime2.org/ 查看最新版
	# 有410多个软件，通过4个conda频道安装
	# 官方地址下载，但在google服务器下载存在困难
	# wget -c https://data.qiime2.org/distro/core/qiime2-2021.2-py36-linux-conda.yml
	# 下载失败时，可尝试在 https://github.com/YongxinLiu/QIIME2ChineseManual 下载或使用如下备用链接
	wget -c http://210.75.224.110/github/QIIME2ChineseManual/2021.2/qiime2-2021.2-py36-linux-conda.yml
	# conda安装QIIME 2(仅运行1次)，我用时33m，供参考，主要由网速决定
	time conda env create -n qiime2-2021.2 --file qiime2-2021.2-py36-linux-conda.yml

	# 方法2. 下载安装包解压安装(可能存在问题)
	# 在已经安装qiime2的系统中安装conda-pack实现打包
	conda install -c conda-forge conda-pack
	n=qiime2-2021.2
	conda pack -n ${n} -o ${n}.tar.gz
    # 添加权限，方便下载和别人使用
    chmod 755 ${n}.tar.gz
    # 下载我的安装包，933M
    wget -c http://210.75.224.110/db/conda/${n}.tar.gz
    # 新建文件夹存放环境为miniconda2或3
    mkdir -p ~/miniconda2/envs/${n}
    tar -xvzf ${n}.tar.gz -C ~/miniconda2/envs/${n}
    # 激活环境
    source ~/miniconda2/envs/${n}/bin/activate
	# 或启动环境
	conda activate qiime2-2021.2


## 2. 物种注释数据训练集

	# 下载数据库文件(greengenes)
	wget -c ftp://greengenes.microbio.me/greengenes_release/gg_13_5/gg_13_8_otus.tar.gz
	# 国内备用链接
	# wget -c http://210.75.224.110/db/GreenGenes/gg_13_8_otus.tar.gz
	# 解压
	tar -zxvf gg_13_8_otus.tar.gz
	
	# 使用rep_set文件中的99_otus.fasta数据和taxonomy中的99_OTU_taxonomy.txt数据作为参考物种注释
	# 导入参考序列，50s
	qiime tools import \
	  --type 'FeatureData[Sequence]' \
	  --input-path gg_13_8_otus/rep_set/99_otus.fasta \
	  --output-path 99_otus.qza
	# 导入物种分类信息，6s
	qiime tools import \
	  --type 'FeatureData[Taxonomy]' \
	  --input-format HeaderlessTSVTaxonomyFormat \
	  --input-path gg_13_8_otus/taxonomy/99_otu_taxonomy.txt \
	  --output-path ref-taxonomy.qza

	# Train the classifier（训练分类器）——全长，30m
	time qiime feature-classifier fit-classifier-naive-bayes \
	  --i-reference-reads 99_otus.qza \
	  --i-reference-taxonomy ref-taxonomy.qza \
	  --o-classifier classifier_gg_13_8_99.qza
	  
	# 引物提取参考序列的扩增区段 Extract reference reads
	# 常用Greengenes 13_8 99% OTUs from 341F CCTACGGGNGGCWGCAG/805R GACTACHVGGGTATCTAATCC region of sequences（分类器描述），提供测序的引物序列，截取对应的区域进行比对，达到分类的目的。
	# 本次使用799F-1193R, 8m
	time qiime feature-classifier extract-reads \
	  --i-sequences 99_otus.qza \
	  --p-f-primer AACMGGATTAGATACCCKG \
	  --p-r-primer ACGTCATCCCCACCTTCC \
	  --o-reads ref-seqs.qza

	# Train the classifier（训练分类器）
	# 基于筛选的指定区段，生成实验特异的分类器，14m
	time qiime feature-classifier fit-classifier-naive-bayes \
	  --i-reference-reads ref-seqs.qza \
	  --i-reference-taxonomy ref-taxonomy.qza \
	  --o-classifier classifier_gg_13_8_99_V5-V7.qza

### 常见问题3：scikit-learn版本不兼容，重新构建训练集即可

	Plugin error from feature-classifier:
	  The scikit-learn version (0.21.2) used to generate this artifact does not match the current version of scikit-learn installed (0.22.1). Please retrain your classifier for your current deployment to prevent data-corruption errors.
	Debug info has been saved to /tmp/qiime2-q2cli-err-5ngzk2hm.log

### 常见问题4. 外部导入特征表和代表序列(常用)

	# 上传其他流程生成的OTU表otutab.txt和代表序列otus.fa
	wget -c http://210.75.224.110/github/MicrobiomeProtocol/e2.QIIME2/otutab.txt
	wget -c http://210.75.224.110/github/MicrobiomeProtocol/e2.QIIME2/otus.fa
	# 转换文本为Biom1.0，注意biom --version 2.1.5/8可以，2.1.7报错
	biom convert -i otutab.txt -o otutab.biom \
	  --table-type="OTU table" --to-json
	# 导入特征表，9s
	qiime tools import --input-path otutab.biom \
	  --type 'FeatureTable[Frequency]' --input-format BIOMV100Format \
	  --output-path table.qza
	# 导入代表序列，8s
	qiime tools import --input-path otus.fa \
	  --type 'FeatureData[Sequence]' \
	  --output-path rep-seqs.qza

### 常见问题5. 导出特征表和代表序列

    # 导出特征表为biom格式
    qiime tools export \
      --input-path table.qza \
      --output-path feature-table
    # 转换为tsv格式
    biom convert -i feature-table/feature-table.biom \
      -o feature-table/feature-table.txt \
      --to-tsv
    # 删除注释行
    sed -i '/# Const/d' feature-table/feature-table.txt
    
    # 导出代表序列
    qiime tools export \
      --input-path rep-seqs.qza \
      --output-path rep-seqs
    
    # 导出物种注释
    qiime tools export \
      --input-path taxonomy.qza \
      --output-path taxonomy
    
```


```javascript
第一章：微生物菌群多样性扩增子测序分析概述及数据准备

1.1 微生物菌群研究的测序方法该如何选择？

（1）微生物菌群研究能做什么？

（2）微生物菌群研究方法？

（3）扩增子测序扩增区域选择

（4）菌群研究文章案例分享

1.2 Windows系统数据分析环境介绍及搭建

（1）扩增子分析环境概述

（2）在Windows系统中上安装Linux子系统

（3）在Windows系统上安装Docker

（4）加载并使用课程提供Docker镜像

1.3 Linux系统数据分析环境介绍及搭建

（1）在Linux服务器上安装Docker

（2）加载并使用课程提供Docker镜像

1.4 QIIME2扩增子分析流程详解

（1）QIIME2分析流程概述

（2）数据导入为QIIME2格式

（3）使用QIIME2去噪和聚类ASV/OTU

（4）物种分类和分类学分析

（5）特征过滤

（6）进化树构建和导出

1.5 实操分析：从原始数据到特征表

（1）分析流程使用方法及注意事项

（2）分析实战：基于原始数据生成特征表和代表序列

（3）结果解读

第二章：物种注释和差异比较分析

2.1 聚类特征表的预处理

（1）实战操作：对数据进行抽平、筛选、过滤

（2）实战操作：不同聚类水平的统计

（3）聚类特征表的结果解读

2.2 物种组成及可视化：堆积柱状图

（1）实战操作：按照样本或分组统计物种丰度

（2）实战操作：自定义标准筛选优势物种

（3）实战操作：基于优势物种绘制堆积柱状图

（4）物种组成分析和分析图的结果解读

2.3 物种组成及可视化：热图

（1）实战操作：基于优势物种绘制热图

（2）物种组成热图结果解读

2.4 物种组成及可视化：韦恩图/花瓣图

（1）实战操作：组间样本物种组成水平的韦恩图和花瓣图绘制

（2）组间共有、特有物种的特征结果解读

2.5 差异分析及差异柱状图绘制

（1）实战操作：样本间物种丰度差异分析数据整理

（2）实战操作：差异柱状图绘制

（3）物种差异柱状图结果解读

2.6 物种差异分析之线性判别分析（LEfSe分析）

（1）LEfSe分析的原理和样本数据要求

（2）实战操作：使用LEfSe分析差异物种和绘制结果图

（3）LEfSe分析结果图表解读

第三章：样本α多样性分析及可视化

3.1 alpha多样性指数计算和结果可视化

（1）不同α多样性指数的生物学意义和选用指南

（2）实战操作：各样本α多样性指数的计算

（3）实战操作：基于α多样性指数绘制各样本箱线图

（4）实战操作：α多样性指数的组间差异分析和差异图绘制

（5）关于α多样性指数分析各类结果的解读

3.2 alpha多样性稀释曲线分析

（1）稀释曲线和物种积累曲线的生物学意义

（2）实战操作：稀释曲线和物种积累曲线可视化绘制

（3）结果解读：如何评估测序量和样本量的饱和度

第四章：样本β多样性分析及可视化

4.1 层级聚类树分析

（1）实战操作：多样本间层级聚类树分析和可视化

（2）结果解读：如何基于层级聚类树评估样本间微生物菌群组成相似性

4.2 样本间主成分分析（PCA分析）

（1）实战操作：基于菌群丰度数据分析样本间PCA并可视化

（2）结果解读：PCA分析的生物学意义、参数选择和异常样本筛选

4.3 样本间PCoA_NMDS_ANOSIM分析

（1）实战操作：基于菌群丰度分析样本间PCoA并可视化

（2）实战操作：基于菌群丰度分析样本间NMDS并可视化

（3）实战操作：使用ANOSIM分析验证组间相似性

（4）结果解读：PCoA、NMDS、ANOSIM分析的生物学意义、参数选择、组间相似性评估

4.4 样本间偏最小二乘法判别分析（PLS-DA分析）

（1）实战操作：基于菌群丰度数据分析样本间PLS-DA并可视化

（2）结果解读：PLS-DA分析的生物学意义、参数选择、组间相似性评估

第五章：基于16S rRNA基因、18S rRNA基因及ITS序列预测菌群功能

5.1 使用PICRUSt2软件进行功能基因预测

（1）基于PICRUSt2功能预测原理和所需数据库

（2）实战操作：使用PICRUSt2进行功能预测和可视化

（3）PICRUSt2功能预测的结果解读和结果应用
```


\
# Reference

<https://d2rs-2026spring.github.io/lecture6-r-microbiome-analysis/>

<https://wenku.csdn.net/column/4ydpke7d59>

<https://xizhihui.github.io/2018/10/15/%E6%89%A9%E5%A2%9E%E5%AD%90%E6%B5%8B%E5%BA%8F-QIIME2%E4%BD%BF%E7%94%A8%E7%A4%BA%E4%BE%8B/>

<https://docs.qiime2.org/en/latest/references/plugins/diversity/>

<https://forum.qiime2.org/t/qiime-2-4-moving-pictures-2018-11/7598>

<https://qinqianshan.com/bioinformatics/16s/>

<https://yjpweb.cn/tutorials/16s-qiime2.html>

<https://www.cnblogs.com/leezx/p/7053199.html>

<https://www.maimengkong.com/?post=1575>

<https://qinqianshan.com/bioinformatics/16s/defining-and-interpreting-otus/>

<https://qinqianshan.com/bioinformatics/16s/qiime-biom/>

<https://qinqianshan.com/bioinformatics/16s/qiime-mapping/>

<https://qinqianshan.com/bioinformatics/16s/rarefaction-curve/>

<https://qinqianshan.com/bioinformatics/16s/uchime-chimera/>

<https://qinqianshan.com/bioinformatics/16s/taxonomy-db/>

<https://qinqianshan.com/bioinformatics/16s/qiime2-introduction/>

<https://qinqianshan.com/bioinformatics/16s/install-qiime2/>

<https://qinqianshan.com/bioinformatics/16s/qiime2-load/>

<https://qinqianshan.com/bioinformatics/16s/qiime2-demux/>

<https://qinqianshan.com/bioinformatics/16s/qiime2-feture/>

<https://qinqianshan.com/bioinformatics/16s/qiime2-phylo-tree/>

<https://qinqianshan.com/bioinformatics/16s/qiime2-alpha-beta/>

<https://qinqianshan.com/bioinformatics/16s/unifrac/>

<https://qinqianshan.com/bioinformatics/16s/r-vegdist/>

[https://qinqianshan.com/bioinformatics/16s/permanova/](https://qinqianshan.com/bioinformatics/16s/batch-download-micro/)

<https://qinqianshan.com/bioinformatics/16s/diversity-index-and-richness-index/>

<https://qinqianshan.com/bioinformatics/16s/%CE%B1-diversity/>

<https://qinqianshan.com/bioinformatics/16s/faith-phylogenetic/>

<https://qinqianshan.com/bioinformatics/16s/%CE%B2-diversity/>

<https://qinqianshan.com/bioinformatics/16s/%CE%B3-diversity/>

<https://qinqianshan.com/bioinformatics/16s/batch-download-micro/>

<https://cloud.tencent.com/developer/article/2708345>

<https://www.fanshouji.com/mpb-shen-zhen-ji-yin-zu-suo-liu-yong-xin-zu-shi-yong/>

<https://wenku.csdn.net/column/3v5qomi7ft>

<https://asa-blog.netlify.app/p/amplicon-workflow/>

<https://forum.qiime2.org/t/qiime-2-3-2018-11/7599>

<https://www.modb.pro/db/564077>

<https://xiaoqizheng.github.io/biological_data_analysis/qiime2.html>

<https://protocols.hostmicrobe.org/microbio/qiime2>

<https://geekdaxue.co/read/QIIME2-doc-zh/2-Tutorial-03-Experienced-Driver-Guide-Experience.md>

<https://wxredian.com/art?id=7f12749202f1bc1e8a400468f26f6f8b>

<https://mp.weixin.qq.com/s/kAw1y_MXEhFAXzK5ZpZFWA?scene=1>

<https://mp.weixin.qq.com/s/JZysXeveO-_dkuDQVJrptg?scene=1>

<https://mp.weixin.qq.com/s/oJSJT1CP260g6Rorkzxyng?scene=1>

<https://mp.weixin.qq.com/s/s8kb8HJImEE-RG9S9YQqMw?scene=1>

<https://mp.weixin.qq.com/s/O36ansiLRB--nXQK7ivWKw?scene=1>

<https://mp.weixin.qq.com/s/_vU_PkDTTun9scZxA6wp5Q?scene=1>

<https://mp.weixin.qq.com/s/qqKerJTyI8Lz9NQL68hgzA?scene=1>

<https://mp.weixin.qq.com/s/1YOctkvcii0hIYbLy3DnFg?scene=1>

<https://mp.weixin.qq.com/s/KgNzy_TWcQjO4firXeadZQ?scene=1>

<https://benjjneb.github.io/dada2/tutorial.html>


帮我基于这些网站上的内容和这些文件"D:\\YL2026\\launch\\Helloxiaolaodi_Blog.github.io\\content\\Blog\\新建文件夹\\2003554使用QIIME 2分析微生物组16S rRNA基因扩增子测序数据_final.docx"和"D:\\YL2026\\launch\\Helloxiaolaodi_Blog.github.io\\content\\Blog\\新建文件夹\\微生物多样性分析方法介绍v2.6百迈客.pdf"的内容帮我写出：1、 数据质量评估及QC\n2、 序列拼接\n3、 去除嵌合体及短序列分析\n4、 OTU统计分析及注释\n5、 物种丰度统计及群落组成分析\n6、 Alpha多样性分析\n    6.1 Alpha多样性指数分析\n    6.2 物种多样性稀释曲线\n7、 Beta多样性分析\n8、 系统进化树分析\n9、 Rank-Abundance分析\n10、 样品间主坐标分析（PCoA）\n样品间主成分分析（PCA）

11、 样品非加权配对平均法聚类分析（UPGMA）\n12、 组间显著性差异分析\n13、 RDA/CCA分析\n14、 非度量多维尺度分析（NMDS）等等的跟16S测序相关的生信分析教程，可以以qiime2（2024.2版本）为主线来把这些生信分析串起来，给硕士研究生阅读学习用的。你可以参考"D:\\YL2026\\launch\\Helloxiaolaodi_Blog.github.io\\content\\Blog\\2026-11-17-slurm-guide"中的typ文件的结构来写，在D:\\YL2026\\launch\\Helloxiaolaodi_Blog.github.io\\content\\Blog中新生成一个包含typ文件的文件夹。分成一级标题二级标题等标题，能抓取到一些网站的图片放到这个typ文件中也可以。你可以再从其他网站上搜集整理跟16S测序相关的生信分析内容，都放到这个typ文件中。