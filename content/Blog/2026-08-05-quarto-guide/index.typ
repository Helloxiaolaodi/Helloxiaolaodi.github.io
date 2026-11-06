#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *
#import "@preview/theorion:0.6.0": quote-block

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "科研利器之 Quarto 的安装与使用",
  description: "在 Windows 与 Linux 服务器上安装配置 Quarto，并用它完成科研文档的渲染与发布。",
  date: datetime(year: 2026, month: 8, day: 5),
  lang: "zh",
)

= 科研利器之 Quarto 的安装与使用

本教程基于实际配置经验，系统介绍如何在 Windows 本地环境与 Linux 服务器（CentOS 7）上，从零完成 Quarto 的安装、环境配置及科研文档的渲染与发布。

#line()

== 一、Quarto 概述

Quarto 是由 Posit（原 RStudio）开发的新一代开源科学出版与可重复研究系统。它允许用户在单一 Markdown 文件中混合编写文本、Python 代码、R 代码等，并一键渲染为 HTML、PDF、Word、演示文稿等多种输出格式。

*核心特性：*

- 原生支持多语言混排（Python、R、Julia、Bash、SQL 等）
- 基于纯文本 `.qmd` 格式，天然适配 Git 版本控制与 AI 辅助审查
- 支持外部脚本引用，可自动嵌入执行结果（图表、表格、控制台输出）
- 完整的学术排版能力：交叉引用、数学公式、脚注、边注、响应式布局

#line()

== 二、Quarto 的工作原理

=== 2.1 源文件与渲染产物的关系

理解 `.qmd` 源文件与渲染后 HTML/PDF 之间的区别，是正确使用 Quarto 的基础。

- *`.qmd` 源文件*：纯文本蓝图，包含 Markdown 叙述文本、代码块源码、以及图片路径引用语法。源文件本身不包含任何图表或表格的渲染结果。
- *渲染产物*：经 `quarto render` 处理后生成的 HTML/PDF 等格式文件，包含实际执行输出、嵌入的图表以及格式化表格。

#tablem[
  | 内容类型 | .qmd 源文件 | 渲染产物（HTML/PDF） |
  | :--- | :--- | :--- |
  | Markdown 叙述文本 | ✅ 原始形式 | ✅ 格式化呈现 |
  | 代码源码 | ✅ 原始形式 | ✅ 语法高亮（可选） |
  | 代码执行输出（print 等） | ❌ 不可见 | ✅ 内嵌显示 |
  | 图表 | ❌ 不可见 | ✅ 嵌入显示 |
  | 表格 | ❌ 不可见 | ✅ 格式化显示 |
  | 外部图片引用 `![](path)` | 仅显示路径 | ✅ 图片展示 |
]

简言之，*`.qmd` 源文件是蓝图，渲染产物是成品报告*。在版本控制系统中应提交 `.qmd` 源文件，审稿人或协作者可通过重新渲染获得完整结果。

=== 2.2 `quarto render` 的两种执行模式

根据代码块的配置选项，`quarto render` 有两种工作模式：

*模式一：执行模式（默认）*

代码块被实际执行，输出结果嵌入最终报告。适用于：
- 轻量级数据分析和可视化任务
- 需要实时计算结果的场景

*模式二：排版整合模式（推荐用于已完成计算的结果）*

通过设置 `eval: false` 或在 Markdown 中直接引用已有文件，Quarto 仅执行排版工作：
- 格式化 Markdown 叙述文本
- 对展示类代码块进行语法高亮
- 嵌入外部已有图片
- 读取已有表格数据并渲染为格式化表格

```bash
# 渲染为自包含 HTML（单文件，所有资源内嵌）
quarto render report.qmd --embed-resources
```

在该模式下，Quarto *不会重复执行计算任务*，仅进行内容整合与排版。

=== 2.3 科研工作流中的定位

在典型的计算生物学研究中，Quarto 的定位如下：

```
高性能计算集群（重计算）            本地或服务器（轻量渲染）
─────────────────────────          ────────────────────────
sbatch job.slurm                   quarto render --embed-resources
  ├── 数据质控与预处理                ├── 展示 Slurm 脚本内容
  ├── 统计分析与建模                  ├── 展示 R/Python 脚本内容
  └── 生成结果图表与表格              ├── 嵌入已生成的结果图
                                       ├── 读取并渲染结果表格
                                       └── 输出自包含 HTML 报告
```

#line()

== 三、Windows 本地环境安装

=== 3.1 安装 Quarto

*方法一：通过包管理器安装（推荐）*

打开 PowerShell：

```powershell
winget install Quarto.Quarto
```

*方法二：手动安装*

访问 #link("https://quarto.org/docs/download/")[Quarto 官方下载页面]，下载 `.msi` 安装程序，双击运行并按照向导完成安装。

=== 3.2 验证安装

```powershell
quarto --version
```

正常输出示例：`1.10.18`

=== 3.3 配置 Python 环境

#quote-block[
*注意：* 应避免安装 Microsoft Store 版本的 Python，其特殊路径和权限限制可能导致 Quarto 无法正确识别。
]

```powershell
# 推荐安装 Python 3.12（兼容性最佳）
winget install Python.Python.3.12
```

安装过程中务必勾选 *"Add Python to PATH"* 选项。

安装完成后，配置 Jupyter 及常用科学计算库：

```powershell
pip install jupyter matplotlib numpy pandas scipy
```

=== 3.4 配置 R 环境（可选）

```powershell
winget install RProject.R
```

在 R 控制台中安装必要的包：

```r
install.packages("knitr")
install.packages("rmarkdown")
```

=== 3.5 验证完整环境

```powershell
quarto check
```

该命令将检查所有依赖组件。Python 和 R 应均显示 `OK` 状态。如 Python 显示 `(None)`，请参考第十节常见问题排查。

#line()

== 四、Linux 服务器环境安装（CentOS 7，无 root 权限）

CentOS 7 预装的 glibc 版本为 2.17，较新的 Quarto 版本（v1.5+）需要 glibc 2.18 以上。因此需使用专门为 RHEL 7 编译的兼容版本。

=== 4.1 系统环境诊断

```bash
uname -a
ldd --version
cat /etc/os-release
```

确认输出为 CentOS 7 且 glibc 版本为 2.17。

=== 4.2 下载与安装兼容版本

```bash
# 创建用户级软件目录
mkdir -p ~/softwares
cd ~/softwares

# 下载 Quarto 1.4.557 RHEL7 专用构建
wget --no-check-certificate https://github.com/quarto-dev/quarto-cli/releases/download/v1.4.557/quarto-1.4.557-linux-rhel7-amd64.tar.gz

# 解压
tar -xzvf quarto-1.4.557-linux-rhel7-amd64.tar.gz

# 将可执行文件路径加入环境变量
echo 'export PATH="$HOME/softwares/quarto-1.4.557/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 验证安装
quarto --version
```

=== 4.3 配置 Python 环境（通过 conda）

假定 conda 中已存在名为 `python3.9-env` 的 Python 环境：

```bash
conda activate python3.9-env

# 安装必要依赖
pip install jupyter matplotlib numpy pandas scipy tabulate ipykernel

# 注册 Jupyter 内核
python -m ipykernel install --user --name python3.9 --display-name "Python 3.9"
```

=== 4.4 配置 R 环境（通过 conda，可选）

假定 conda 中已存在名为 `r-env` 的 R 环境：

```bash
conda activate r-env

# 安装 IRkernel 并注册
R -e "install.packages('IRkernel', repos='https://mirrors.tuna.tsinghua.edu.cn/CRAN')"
R -e "IRkernel::installspec(name = 'r-env', displayname = 'R (r-env)')"
```

=== 4.5 在 base 环境安装 Jupyter 入口

```bash
conda activate base
conda install jupyter -y
```

=== 4.6 验证内核配置

```bash
jupyter kernelspec list
```

期望输出中包含 `python3.9` 和 `r-env`（如已安装 R）。

=== 4.7 Quarto 版本兼容性参考

#tablem[
  | Quarto 版本 | 最低 glibc 要求 | CentOS 7 兼容性 |
  | :--- | :--- | :--- |
  | v1.6.x 及以上 | 2.18+ | ❌ 不兼容 |
  | v1.5.x | 2.18+ | ❌ 不兼容 |
  | *v1.4.557 (RHEL7 构建)* | *2.17* | *✅ 兼容* |
  | v1.4 标准构建 | 2.18+ | ❌ 不兼容 |
]

#line()

== 五、终端中文显示配置

=== 5.1 MobaXterm 客户端设置

+ 右键当前会话标签页 → *Change terminal settings...*
+ 在 *Terminal* 选项卡中，将 *Charset* 设置为 `UTF-8 (unicode)`
+ 在 *Terminal font* 设置中选择支持中文的字体（如 `KaiTi`），注意避免选择带 `@` 前缀的竖排字体
+ 断开当前会话并重新连接以使设置生效

=== 5.2 服务器端环境配置

```bash
# 配置 locale
echo 'export LC_ALL=en_US.utf8' >> ~/.bashrc
source ~/.bashrc
```

若使用 ble.sh 终端增强工具，可能需要在 `~/.blerc` 中额外配置编码：

```bash
echo 'bleopt input_encoding=C' >> ~/.blerc
```

#line()

== 六、快速入门：构建第一个 Quarto 文档

=== 6.1 创建测试文档

```bash
mkdir -p ~/quarto-test
cd ~/quarto-test
```

使用文本编辑器（如 vim）创建 `test.qmd`：

````markdown
---
title: "Quarto 功能测试"
engine: jupyter
jupyter: python3.9
---

## 数据处理测试

```{python}
import numpy as np
import pandas as pd

data = pd.DataFrame({
    "x": range(1, 11),
    "y": [i**2 for i in range(1, 11)]
})

print(data.to_markdown(index=False))
```

## 可视化测试

```{python}
#| fig-cap: "y = x² 函数曲线"
#| fig-width: 6
#| fig-height: 4

import matplotlib.pyplot as plt

plt.plot(data["x"], data["y"], marker="o", linewidth=2, color="blue")
plt.title("y = x²")
plt.xlabel("x")
plt.ylabel("y")
plt.grid(True, alpha=0.3)
plt.show()
```
````

=== 6.2 执行渲染

```bash
# 标准渲染（生成 HTML 及独立的资源文件夹）
quarto render test.qmd

# 自包含渲染（推荐：所有资源内嵌于单一 HTML 文件）
quarto render test.qmd --embed-resources
```

终端输出中显示 `Executing` 和 `Done` 表示渲染成功。

=== 6.3 下载渲染产物至本地

#tablem[
  | 方法 | 操作步骤 |
  | :--- | :--- |
  | MobaXterm 文件浏览器 | 在左侧面板导航至目标目录，选中文件后右键下载 |
  | 命令行打包 | `tar -czf report.tar.gz test.html test_files/`，随后下载压缩包 |
  | 自包含 HTML（推荐） | 使用 `--embed-resources` 选项，仅需下载单一 `.html` 文件 |
]

#line()

== 七、实战模板：整合已有脚本与计算结果

本节展示科研实践中的典型应用场景：*计算任务已在集群完成，Quarto 负责整合脚本内容与结果图表，生成可发布的报告*。

=== 7.1 推荐的项目目录结构

```
project/
├── report.qmd                  # 主文档
├── scripts/
│   ├── run_analysis.slurm       # Slurm 提交脚本
│   ├── analysis.R               # R 分析脚本
│   └── plot.py                  # Python 绘图脚本
├── output/
│   ├── figure1.png
│   ├── figure2.png
│   ├── result_table.csv
│   └── rarefaction.tsv
└── logs/                        # Slurm 作业日志
```

=== 7.2 完整 .qmd 模板

以下模板演示如何将 Slurm 脚本、R 脚本、Python 脚本、结果图表和表格整合至单一文档中。

````markdown
---
title: "Analysis Report: Global Sampling Distribution and Pipeline"
author: "Author Name"
date: "2026-08-05"
engine: jupyter
jupyter: python3.9
---

# Methods

## Analysis Pipeline

The analysis workflow for this study is described below:

```markdown
{{< include pipeline-content.md >}}
```

## Slurm Job Submission Scripts

### R Analysis: Sampling Distribution

The following script submits the R analysis job to the cluster. It is displayed
for documentation purposes only; actual computation was performed on the server.

```bash
#!/bin/bash
#SBATCH --job-name=analysis_job
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=12:00:00
#SBATCH --mem=32G

module load R/4.3.0
Rscript scripts/analysis.R

echo "Analysis complete"
```

**Submission command:** `sbatch scripts/run_analysis.slurm`

### Python Analysis: Saturation Curve

```bash
#!/bin/bash
#SBATCH --job-name=saturation_curve
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --time=06:00:00
#SBATCH --mem=16G

module load python/3.9
python scripts/plot.py

echo "Analysis complete"
```

**Submission command:** `sbatch scripts/run_python.slurm`

## R Analysis Script

Displayed for documentation purposes only.

```r
# scripts/analysis.R
# Generates the global sampling distribution map.
# See scripts/analysis.R for the full implementation.
```

## Python Analysis Script

Displayed for documentation purposes only.

```python
# scripts/plot.py
# Performs rarefaction curve analysis.
# See scripts/plot.py for the full implementation.
```

---

# Results

## Figure 1: Analysis Pipeline and Global Distribution

![Figure 1: Complete analysis pipeline and global geographic distribution.](output/figure1.png)

Figure 1 displays the full analysis workflow alongside the worldwide
distribution of samples included in this study.

## Figure 2: Alternate Visualization

![Figure 2: Alternative layout of the sampling distribution.](output/figure2.png)

Figure 2 provides an alternative visualization of the sample distribution
across geographic regions.

## Table 1: Rarefaction Curve Statistics

```{python}
#| label: tbl-rarefaction
#| tbl-cap: "Rarefaction curve analysis results"

import pandas as pd

df = pd.read_csv("output/rarefaction.tsv", sep="\t")
print(df.to_markdown(index=False))
```

Table @tbl-rarefaction presents species richness estimates at varying
sequencing depths, confirming sufficient coverage across all samples.

---

# Discussion

Key findings of this study include:

- **Global coverage**: Samples span multiple continents, enabling robust
  cross-regional comparisons.
- **Sufficient sequencing depth**: Rarefaction curves reach a plateau,
  confirming that sequencing depth is adequate for downstream analyses.
- **Reproducible workflow**: All analysis steps are encapsulated in
  version-controlled R and Python scripts, executed via Slurm on the HPC
  cluster.

---

# Appendix: File Inventory

| File | Description |
|:---|:---|
| `scripts/run_analysis.slurm` | Slurm submission script for R analysis |
| `scripts/analysis.R` | R script for distribution map |
| `scripts/run_python.slurm` | Slurm submission script for Python analysis |
| `scripts/plot.py` | Python script for rarefaction curve |
| `output/figure1.png` | Main composite figure |
| `output/figure2.png` | Alternate figure layout |
| `output/rarefaction.tsv` | Rarefaction curve statistics |
| `pipeline-content.md` | Analysis pipeline description |
| `logs/` | Slurm job log files |
````

=== 7.3 渲染命令

```bash
quarto render report.qmd --embed-resources
```

执行后将生成自包含的 `report.html` 文件，所有图片和表格均已内嵌。

#line()

== 八、代码块用法参考

=== 8.1 执行模式选项

#tablem[
  | 选项 | 含义 | 典型应用场景 |
  | :--- | :--- | :--- |
  | 默认（无显式设置） | 执行代码并显示输出 | 轻量级实时分析 |
  | \`\# | eval: false\` | 仅展示源码，不执行 |
  | \`\# | echo: false\` | 执行但不显示源码 |
  | \`\# | echo: true\` | 显示源码（默认行为） |
]

=== 8.2 代码块类型指南

*可执行代码块（由 Jupyter 内核执行）：*

仅当代码块标记为 `{python}` 或 `{r}` 时，Quarto 才会将其交由 Jupyter 内核执行。此类代码块适用于读取数据、生成轻量图表或快速计算的场景。

````markdown
```{python}
#| label: my-chunk
#| fig-cap: "My Figure"

import matplotlib.pyplot as plt
plt.plot([1, 2, 3], [4, 5, 6])
plt.show()
```
````

*展示类代码块（不执行，仅语法高亮）：*

对于仅需展示代码内容而无需执行的场景（如 Slurm 脚本、已完成计算的分析脚本），使用普通代码块标记（`bash`、`r`、`python`，不加花括号）。普通代码块不会被 Jupyter 执行，仅进行语法高亮渲染。

````markdown
```bash
#!/bin/bash
#SBATCH --job-name=myjob
#SBATCH --nodes=1
module load R
Rscript analysis.R
```

```r
# R script content for display only
library(ggplot2)
```

```python
# Python script content for display only
import pandas as pd
```
````

=== 8.3 引用外部图片

对于已在集群上生成的结果图表，可通过标准 Markdown 语法直接引用：

```markdown
![Figure caption describing the content.](output/figure1.png)
```

该方法不触发任何代码执行，仅将指定图片嵌入报告。

#line()

== 九、PDF 渲染说明

在服务器端渲染 PDF 需要 LaTeX 环境支持。如系统未安装 LaTeX，可使用以下方法之一：

=== 9.1 安装 TinyTeX（推荐）

Quarto 提供一键安装轻量级 LaTeX 发行版的命令：

```bash
quarto install tinytex
```

该命令将 TinyTeX 安装至用户目录，无需 root 权限。

=== 9.2 通过 conda 安装

```bash
conda install -c conda-forge tectonic -y
```

然后在 `.qmd` 文件 YAML 头部指定 `pdf-engine: tectonic`。

=== 9.3 使用浏览器打印功能

如上述方法均不可用，可在本地浏览器中打开已生成的 HTML 文件，通过 `Ctrl + P` 另存为 PDF。该方法无需额外依赖，中文渲染效果良好。

=== 9.4 中文字体配置（仅 PDF 渲染时需要）

若需在服务器端渲染含中文内容的 PDF，需在 YAML 头部添加字体配置：

```yaml
pdf-engine: xelatex
include-in-header:
  - text: |
      \usepackage{xeCJK}
      \setCJKmainfont{WenQuanYi Micro Hei}
      \setCJKsansfont{WenQuanYi Micro Hei}
      \setCJKmonofont{WenQuanYi Micro Hei Mono}
```

#quote-block[
*注意：* 上述 `include-in-header` 配置仅在 PDF 渲染时生效。渲染 HTML 时请移除此配置，否则该内容将在正文中原样显示。
]

#line()

== 十、常见问题排查

#tablem[
  | 问题 | 可能原因 | 解决方法 |
  | :--- | :--- | :--- |
  | `Python 3 installation....(None)` | Python 未被 Quarto 识别 | 确认 Python 已加入系统 PATH；如为 Microsoft Store 版本，需替换为官方发行版 |
  | `glibc_2.18 not found` | Quarto 版本与 CentOS 7 不兼容 | 安装 RHEL7 专用构建（v1.4.557） |
  | `No module named 'matplotlib'` | Python 环境缺少必要依赖 | `pip install matplotlib` |
  | `Jupyter kernel not found` | Jupyter 内核未注册 | `python -m ipykernel install --user --name 环境名` |
  | R 代码块未执行 | v1.4.557 对多内核切换支持有限 | 将 R 代码转换为 Python 实现，或将 R 分析写入独立的 `.qmd` 文件 |
  | HTML 中图片无法显示 | 资源文件夹 `_files/` 未同步下载 | 同时下载该文件夹，或使用 `--embed-resources` 选项生成自包含文件 |
  | `include-in-header` 内容显示在正文中 | LaTeX 配置被 HTML 渲染引擎误读 | 渲染 HTML 时从 YAML 头部移除 `include-in-header`，仅在 PDF 渲染时添加 |
  | PDF 渲染失败：`xelatex not found` | 系统未安装 LaTeX | 执行 `quarto install tinytex` 或通过浏览器将 HTML 打印为 PDF |
  | 终端中文显示异常 | 终端编码或字体配置不正确 | 设置 Charset 为 UTF-8，选择支持中文的等宽字体 |
]

#line()

== 十一、推荐工作流

+ *集群端*：通过 Slurm 提交计算任务，产出结果图表与表格
+ *编辑端*：在本地使用 VS Code（配合 Quarto 扩展）或 RStudio 编写 `.qmd` 报告
+ *内容组织*：使用展示类代码块（不含 `{python}` 标记）引用脚本内容，使用 `![](path)` 语法嵌入结果图表，使用可执行代码块（含 `{python}` 标记）读取并渲染结果表格
+ *渲染*：`quarto render report.qmd --embed-resources`
+ *版本控制*：仅将 `.qmd` 源文件纳入 Git 管理，渲染产物（`.html`、`_files/`）加入 `.gitignore`
+ *分发*：将自包含 HTML 文件发送给合作者或作为期刊补充材料提交

#line()

== 十二、命令速查

```bash
# 环境检查
quarto check

# 基础渲染
quarto render report.qmd

# 自包含 HTML 渲染（推荐用于分发）
quarto render report.qmd --embed-resources

# PDF 渲染（需要 LaTeX 环境）
quarto render report.qmd --to pdf

# Word 文档渲染
quarto render report.qmd --to docx

# 查看已注册的 Jupyter 内核
jupyter kernelspec list

# 注册新的 Python 内核
python -m ipykernel install --user --name 环境名 --display-name "显示名称"

# 安装 TinyTeX（用于 PDF 渲染支持）
quarto install tinytex
```
