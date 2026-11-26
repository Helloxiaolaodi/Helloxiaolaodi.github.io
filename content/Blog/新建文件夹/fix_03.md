我重新对照了原始 Typst 教程和 CHM 稿件。你指出的流程问题是对的：**在你这篇 CHM 研究所采用的分析路线中，DADA2 产生 ASV 后，确实还要继续进行 Greengenes2 closed-reference mapping，构建 OTU 特征表。** 前面我把 ASV 作为主流程终点、将 closed-reference 降为可选步骤，不符合你这项研究的实际分析设计。

但需要明确一个方法学边界：这不是所有 16S 项目都必须执行的步骤。QIIME 2 官方支持将 DADA2 输出的 ASV 特征表和代表序列继续进行 closed-reference clustering，同时提醒这种聚类会降低特征分辨率，适用于有明确参考库标准化需求的研究。

QIIME 2 2024.10.1 documentation+1

## **一、你的教程应该采用怎样的核心流程？**

我建议将主线明确调整为：

## **DADA2 → Greengenes2 99% closed-reference → OTU**

**原始 16S FASTQ 数据**

双端或单端 reads

**DADA2 去噪**

质量过滤、错误校正、拼接（双端）、去嵌合体

**ASV 特征表**

table-asv.qza

**ASV 代表序列**

rep-seqs-asv.qza

**Greengenes2 closed-reference mapping**

# **99%**

使用固定版本的 Greengenes2 backbone

**OTU 特征表**

table-gg2-cr99.qza

**未匹配 ASV**

unmatched-asvs.qza

**OTU 主分析数据集**

分类注释 + 参考系统发育树 + Metadata

**群落组成**

**Alpha 多样性**

**Beta 多样性**

**差异丰度**

**环境因子分析**

**微生物网络**

**保留独立的 ASV 分析支线**

PICRUSt2 功能预测、ASV 参考数据库覆盖度评估、未匹配 ASV 的系统发育分析等仍然使用 ASV 数据，不应全部转换为 OTU 后再分析。

这也是你上传的 CHM 稿件实际体现的逻辑：Alpha/Beta 多样性使用 closed-reference OTU 表，而 PICRUSt2 使用质量控制后的 ASV 表。

CHM-manuscripts-1027-1250.docx

## **二、原 Typst 文件具体应该怎么改？**

我建议不要仅仅把原来的 closed-reference 章节提前，而是要同步修改它前后的输入输出文件。

| 原位置      | 修改方式                                      | 重要程度 |
| -------- | ----------------------------------------- | ---- |
| 第 0 节    | 重新定义 ASV、de novo OTU、closed-reference OTU | 必须   |
| 第 1 节    | 补充 DADA2 去噪后的质量审核                         | 必须   |
| 第 2 节    | 改为 DADA2 去噪与 ASV 构建                       | 必须   |
| 第 3 节    | 调整嵌合体去除与 ASV 过滤逻辑                         | 必须   |
| 第 4 节    | 将 Greengenes2 closed-reference 99% 改为主流程  | 必须   |
| 第 5 节    | 分类组成分析改用 closed-reference OTU 表           | 必须   |
| 第 6–8 节  | Alpha、Beta 与树的输入统一为 OTU 表及匹配的参考树          | 必须   |
| 第 12 节   | 差异分析明确使用 OTU/count 表及对应的归一化方法             | 必须   |
| 第 16.4 节 | PICRUSt2 明确走 ASV 支线                       | 必须   |

其中有三个特别需要注意的地方。

**1. 原第 4.1 节的 closed-reference 主线代码应该保留，而不是推倒重写。**

你原文已经有：

```
qiime vsearch cluster-features-closed-reference \
  --i-sequences rep-seqs.qza \
  --i-table table.qza \
  --i-reference-sequences 2024.09.backbone.full-length.fna.qza \
  --p-perc-identity 0.99 \
  --p-threads 12 \
  --p-strand both \
  --o-clustered-table clustered-table.qza \
  --o-clustered-sequences clustered-sequences.qza \
  --o-unmatched-sequences unmatched-sequences.qza
```

这段命令的基本思路是正确的。需要做的是将它提升为 DADA2 后的正式主流程，并统一文件命名。

QIIME 2 的 closed-reference 过程会把匹配到同一参考序列的特征计数合并，并生成未匹配序列文件。

QIIME 2 2024.10.1 documentation+1

**2. downstream 不能继续混用 ASV 表与 OTU 表。**

例如你原来的群落组成分析：

```
qiime taxa collapse \
  --i-table table-filtered.qza \
  --i-taxonomy taxonomy.qza \
  --p-level 6 \
  --o-collapsed-table table-l6.qza
```

应该改为：

```
qiime taxa collapse \
  --i-table table-gg2-cr99.qza \
  --i-taxonomy taxonomy-gg2.qza \
  --p-level 6 \
  --o-collapsed-table table-gg2-l6.qza
```

这里的 `taxonomy-gg2.qza` 必须与 closed-reference OTU 表的 feature ID 对应。不能直接将原始 ASV 的 taxonomy 文件拿来处理 ID 已经改变的 OTU 表。

Greengenes2 2024.09 提供不同命名空间的分类与系统发育文件，因此尤其要注意 reference sequence、taxonomy、tree 的 ID 一致性。

GitHub+1

**3. 增加 mapping rate 质控。**

这是你原教程目前相对欠缺、但 CHM 稿件非常有价值的内容。

建议至少计算：

\\\[ Mapping\ rate = \frac{\text{成功映射到参考库的 reads}} {\text{进入 closed-reference 的 ASV reads}} \times100\\% \\]

同时展示每个样本和每个 BioProject 的 mapping rate 分布。

你的 CHM 稿件还使用了队列级筛选规则：超过 30% 样本的嵌合体比例高于 25% 时排除该队列；排除 mapping rate 为 0 的样本；队列整体 mapping rate 低于 70% 时排除该队列。这些值得在教程中作为跨队列整合案例详细说明，但应注明它们是该研究的具体 QC 标准，而不是通用硬性阈值。

CHM-manuscripts-1027-1250.docx

## **三、从 CHM DOCX 中还能补充哪些内容？**

我认为这份稿件对你的教程有很大的补充价值。尤其是 STAR Methods 部分，里面有不少比一般 16S 分析教程更接近真实高水平文章的数据处理和统计分析方法。

以下是我筛选后最值得纳入的内容。

[An error occurs when applying meta metadata. - User Support - QIIME 2 Forum](https://images.openai.com/static-rsc-4/wB6CfnXsnjgCuTAV4xw9re287NN6fYGQvOH4Sdg_dZWJMxnmB26wqdW686Gc6wxjJNPJqaxLsC8TRLxGzRh3KS7yPn3RcSMKrdQU1OaHoePK3fzO4tuTjGDgQ0CXghVV-XHO8W0122SPkwNTVz-3LC3kxkaGoKp2mhy7ZdxbH-g?purpose=inline)

**1. Metadata 标准化及跨研究数据整理**

增加 BioProject、Run、Subject ID、采样时间点、口腔采样部位、测序平台、扩增区、疾病状态等字段的整理；补充技术重复去重、缺失值处理、原始论文核对和 metadata 追溯。

强烈推荐新增

[How 16S rRNA sequencing revolutionizes microbiome research | CD Genomics posted on the topic | LinkedIn](https://images.openai.com/static-rsc-4/oMhsBI1tt5lVD0nba6oiXx-3pDMky5J5FjdKYhFKR2g2xQVA57Mzar5dWg8HNDF8hu79jd9Y5-s74csT2u8nAwMazJMwPPoh6O2fCec-TPBv_YG2XA70QEx_hLLdzHnst0oL5UTpeMsdL3tJRFomKUK5UzOr5w8AzOgGdvhiKlQ?purpose=inline)

**2. 16S 扩增区域核验**

稿件使用 ASV 序列与全长大肠杆菌 16S rRNA 参考序列 J01695.2 比对，核验 V1–V9 扩增区域。建议在教程中新增扩增区确认、扩增区不一致对分类注释及跨队列比较的影响。

强烈推荐新增

[Characterization and Demonstration of Mock Communities as Control Reagents for Accurate Human Microbiome Community Measurements - PMC](https://images.openai.com/static-rsc-4/OWkq5I3q2UGBlKvayJaqmgnU9UXHtJe_UmCEAIk6PU0zQvBGKRFu6GI37OrdjB0fl4Vi8OFAxzWBqb8iFrbqk3TfVvRK7hv2X3Z-UmKQR40Q6qb2clrRRbXGSTLqB1oWUMqXj9DqB8hFwpgEqo9F978X5G4sG90AiBt2SWOtNNg?purpose=inline)

**3. 阴性对照、Mock Community 与污染识别**

补充 extraction blank、PCR negative control、阳性对照、decontam，以及基于阴性对照建立污染特征目录的分析思路。不能简单把低丰度菌都当作污染菌。

必须补充

[Checking your browser - reCAPTCHA](https://images.openai.com/static-rsc-4/sPcToFRhIkSEBrrSSLisY1gtVacI314ahvavrbfOLtGSx_unFByI6LRJNs5yd_o8-vD1RpcPI32vP1FQaVb7HylSKqkLDDC1f0019VFRvkG30-mjMIlQXIcbJHgFKsR6PVMZZsNQilg1E5Uh2d4kBTERBOkE9_jC2jhGnTIUmxU?purpose=inline)

**4. Sample-based rarefaction / 物种累积曲线**

补充稿件中 1 至约 80,000 个样本规模、每个规模随机抽样 150 次、使用 GAM 平滑的分析方法。一定要与单样本测序深度稀释曲线分开介绍。

推荐新增

[16  Differential abundance – Orchestrating Microbiome Analysis](https://images.openai.com/static-rsc-4/wcqfhiLLEtT8eZAawnOdtAhfVUKffBObf2-AlCk6TSrNFuk1xIRCJi88gL5aJbrExg1Sw44jZ1NIEDKxY7sKCnXKHqpy27d-DuE81m4upqH6tKTChlI85upYv1eKPHwKcHhTWJROZL9elmQu9PXFBJQzuvv9sEYym5ZKe099XDc?purpose=inline)

**5. 多方法差异丰度共识分析**

LinDA、MaAsLin2、ANCOM-BC2 三种方法联合分析；至少两个方法支持、方向一致、各自通过 BH 校正才定义共识差异菌。还包括同一 BioProject 匹配健康对照和混合效应建模。

强烈推荐新增

[Frontiers | Effects of rotation corn on potato yield, quality, and soil microbial communities](https://images.openai.com/static-rsc-4/q5Bqfl2H4dM-CGffJstuO8cSrduXtQk3kdkRm4iTA4BDt964jQQFei18XpD4Yv8feypAAEyf4zEFb-P_P6mF9QVM1Zgsm5hYy-OwMVLtk7xu5T21FlwPG_Gv4QVeGts_A5SFTvtugCVGWa7wOzyBLnOg6zOSbel_cPHX47grPVA?purpose=inline)

**6. 跨队列共识网络**

先在各个 BioProject 内按健康与疾病分组构建网络，再使用 NetMoss 整合；使用 Louvain 社区发现、模块枢纽和连接者分析。这比把所有队列混在一起计算相关网络更值得学习。

推荐新增

[Gut microbiome dysbiosis across early Parkinson’s disease, REM sleep behavior disorder and their first-degree relatives | Nature Communications](https://images.openai.com/static-rsc-4/AWBFv75v6DH9wKqr5jqxFKrJE4ouU2CQhf0DAnGRfSGCm2bU2cpoCOifa-HOwrbwvqe7jONvV15ijYVbHe-ES8k_YK83kMhMwwuiRRwvInDRoBbFGBcGZfzRDPK6fl0WFtYt4H0ymQQYfEoACLWHo353WBTCQXX4VeQwkILN2a4?purpose=inline)

**7. 机器学习与跨研究验证**

增加随机森林、年龄预测、疾病分类、AUC、MAE、R²，以及 Leave-One-Study-Out（LOSO）交叉验证。特别说明不能让训练集和测试集同时包含同一研究的样本，却将结果解释为跨队列泛化能力。

推荐新增

[High-Resolution Detection of Translocation of Oral Bacteria to the Gut - S. Kageyama, S. Sakata, J. Ma, M. Asakawa, T. Takeshita, M. Furuta, T. Ninomiya, Y. Yamashita, 2023](https://images.openai.com/static-rsc-4/wRCoyDH3CzjkW5P1gB6VwtIQQxuDUVpUFQoP86iRyO27LsAdUDvS6O0HNgLsRkqlDvEUY09GySz3j4sYbtG4eamB6gvpxKrh_s-uva5kAllB0MDTY8Q4z9W55O4k-YhT5tJ9thg43kvi-wDRZJ27j3UnWFzrY2mwFZWyXGUevgk?purpose=inline)

**8. 配对样本、纵向分析和 SourceTracker2**

增加 Subject ID 与时间点配对、同队列随机非配对参照、Source/Sink 定义、Unknown 来源及 Gibbs sampling。特别强调来源追踪是模型估计，不是直接观测到微生物转移。

进阶模块

[pplacer: linear time maximum-likelihood and Bayesian phylogenetic placement of sequences onto a fixed reference tree | BMC Bioinformatics | Springer Nature Link](https://images.openai.com/static-rsc-4/F58XxGfS0wF9ph-OvP5AAKagBFjtSYR1drx6EE7LQrJxV4wiyCZWCkydurUHCmiIU88kqOA5N12qQY3qzPmpwYds8C2FPO4k3jkaW2htgJSwBDGCGWFHOO-eV4fdl7uCuDVig81Dk5TbkQw9YjOENT1wghoJdG21GIT6Ksl4h5M?purpose=inline)

**9. 未匹配 ASV 的系统发育放置**

稿件利用 SEPP 将低参考相似度 ASV 放置到 Greengenes2 参考树，再利用 TreeCluster 定义 phylotypes。这可以作为数据库覆盖度研究的高级章节。

进阶模块

这些具体方法分别来自稿件的数据整理、序列处理、OTU 聚类、多样性、差异分析、网络和 SourceTracker2 等 Methods 部分。

CHM-manuscripts-1027-1250.docx

## **四、我建议的最终一级目录**

综合现有教程与 CHM 稿件，我建议最终定为：

| 一级标题                                   | 主要内容                               |
| -------------------------------------- | ---------------------------------- |
| 0. 教程说明与分析总览                           | 环境、ASV/OTU、数据流                     |
| 1. 实验设计、Metadata 与数据准备                 | 实验设计、公共数据、样本配对                     |
| 2. 原始数据导入与质量评估                         | Manifest、FASTQ、demux               |
| 3. 原始序列预处理                             | Cutadapt、接头和引物去除                   |
| 4. DADA2 去噪与 ASV 构建                    | 双端/单端去噪、拼接、嵌合体                     |
| 5. ASV 质量审核与污染过滤                       | 长度、污染、细胞器及异常样本                     |
| 6. Greengenes2 closed-reference OTU 构建 | 99% mapping、未匹配 ASV                |
| 7. Mapping rate 与数据集质量控制               | 样本和 BioProject 级别                  |
| 8. 分类注释与特征表整理                          | Greengenes2 taxonomy、分类水平合并        |
| 9. 系统发育树构建与匹配                          | Reference tree、Faith PD、UniFrac    |
| 10. 群落组成及核心菌群                          | 丰度、出现率、Rank-Abundance              |
| 11. Alpha 多样性                          | Shannon、丰富度、抽平、稀释曲线                |
| 12. Beta 多样性                           | Bray-Curtis、UniFrac、PCoA、PERMANOVA |
| 13. 差异丰度分析                             | ANCOM-BC2、LinDA、MaAsLin            |
| 14. 环境因子关联                             | RDA、CCA、db-RDA                     |
| 15. 其他排序与聚类                            | PCA、NMDS、UPGMA                     |
| 16. 微生物网络分析                            | SparCC、SPIEC-EASI、NetMoss          |
| 17. ASV 支线功能预测                         | PICRUSt2、NSTI、EC、KO、MetaCyc        |
| 18. 高级分析                               | 配对/纵向、SourceTracker2、机器学习、SEPP     |
| 19. 结果整理、统计报告与可复现性                     | 图表、效应量、多重检验、项目管理                   |
| 附录                                     | 软件安装、数据库、SRA 下载、R 代码、故障排查          |

## **五、我已经整理好的 Typst 修改文件**

**16S****\_****typ****\_****修改方案与CHM内容补充.md**

包含原文件具体修改位置、closed-reference 命令、mapping rate R 代码、从 CHM Methods 挖掘出的新增内容、建议目录及剩余错误清单。

已生成

下载 Typst 修改方案与补充内容

最后还有一个不能忽略的版本问题：CHM 稿件的 Key Resources Table 使用的是 QIIME 2 2026.04，而你的教程固定为 2024.2。因此，稿件中的方法学逻辑可以直接作为参考，但命令必须在 2024.2 环境中逐项核验，尤其是 Greengenes2 插件、分类注释和系统发育树的 Artifact 兼容性。

CHM-manuscripts-1027-1250.docx

**我最建议你接下来优先完成的是：先把第 4–9 节，也就是 DADA2 → ASV → Greengenes2 closed-reference → OTU → taxonomy → phylogenetic tree 这一整段重构完整。** 这是整个教程的数据主干，后续所有下游分析章节都应该以它明确产生的 OTU 表为主输入，同时保留 ASV 支线。
