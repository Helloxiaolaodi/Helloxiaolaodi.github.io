#import "../index.typ": template, tufted

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "生信常用命令速查：Linux / Conda / Slurm / QIIME 2 / R / Python / Git",
  description: "面向 26 级同学的生信常用命令速查：Linux Shell、Conda、Slurm、QIIME 2、R、Python 与 Git 的日常操作与排错速查。",
  date: datetime(year: 2026, month: 6, day: 6),
  lang: "zh",
)

= 生信常用命令速查：Linux / Conda / Slurm / QIIME 2 / R / Python / Git

== （1）Shell

=== pwd / ls / du / df / free

```bash
pwd                     # 看自己在哪个目录
ls -lh                  # 用 K/M/G 显示大小
ls -la                  # 连隐藏文件一起看
du -sh ./               # 当前目录总共多大
du -sh * | sort -hr     # 各子目录大小，从大到小
df -h                   # 看磁盘各分区的使用情况
free -h                 # 看内存用了多少
```

=== touch / mkdir / cp / mv / rm / cd

```bash
touch file.txt                              # 建个空文件
mkdir -p project/{data/{raw,clean},results,scripts,logs}  # 一次性把项目目录结构建好
cp source.txt dest.txt                      # 复制文件
cp -r dir1/ dir2/                           # 复制整个目录
mv old_name.txt new_name.txt                # 移动 / 改名
rm -i file.txt                              # 删之前先问一下

cd /home/user/project/         # 用绝对路径进入
cd ../                         # 返回上一级
cd ~                           # 回主目录
cd -                           # 回到上一个所在位置
```

=== namei / 查看权限

```bash
namei -mo /home/user/project_dir/results_dir/

# 看文件权限
ls -l file.txt
# 输出大概是这样：-rwxr-xr-x  1 user group  1024 Jan 01 12:00 file.txt
#        │└┬┘└┬┘└┬┘
#        │ │  │  └── 其他人的权限 (r-x)
#        │ │  └───── 同组的权限 (r-x)
#        │ └──────── 文件所有者的权限 (rwx)
#        └────────── 文件类型（- 普通文件, d 目录, l 软链接）
#
# 权限字符含义：
#   r (read)    = 读，能看文件内容 / 能列目录
#   w (write)   = 写，能改文件 / 能在目录里增删文件
#   x (execute) = 执行，能运行程序 / 能进入目录
#   -           = 没有这项权限
```

=== chmod

```bash
# 第一步：先给上级目录加上"可进入"权限（x），否则没法 cd 进去
# 只对同组开放（比较安全）
chmod g+x /home/user
chmod g+x /home/user/project_dir

# 对所有人开放（小心：谁都能进）
chmod a+x /home/user
chmod a+x /home/user/project_dir

# 第二步：开放目标目录和里面文件的读、进入权限
# 注意 -R g+rX / a+rX 里的大写 X：只给目录或本来就可执行的文件加执行权限，
# 普通数据文件不会被误加上可执行权限
# 只给同组读和进入
chmod -R g+rX /home/user/project_dir/results_dir/

# 所有人都能读、能进
chmod -R a+rX /home/user/project_dir/results_dir/

chmod 750 script.sh    # rwxr-x--- → 所有者7, 同组5, 其他人0（脚本，只有同组能用）
chmod 644 data.txt     # rw-r--r-- → 所有者6, 同组4, 其他人4（数据，谁都能读）
```

=== scp / rsync

```bash
# scp：一次性传输
# 本地传到远程
scp local_file.txt user@server:/home/user/
scp -r local_dir/ user@server:/home/user/

# 从远程拉回本地
scp user@server:/home/user/file.txt ./
scp user@server:/home/user/results.qzv ./   # 可以拿到 view.qiime2.org 上看

# rsync：增量同步，适合大文件
# 注意：源路径末尾有没有斜杠 '/'，决定是"把内容塞进去"还是"把整个文件夹塞进去"
rsync -avhP local_dir/ user@server:/remote/dir/
rsync -avhP --exclude='*.tmp' user@server:/remote/ ./local/

# 常用参数
# -a 归档模式（保留权限、时间戳、链接等）
# -v 显示过程
# -h 人类可读的大小
# -P 显示进度 + 支持断点续传
# --exclude='*.tmp' 排除某类文件
rsync -avhP --exclude='*.log' src/ dst/

# 只复制文件名里不含 annotation 的文件
rsync -av --exclude="*annotation*" /home/user/dir/ /home/user/dir02/

# 例子：后台同步大文件（支持断点续传）
# ⚠️ 注意：同步 60G 数据要花不短时间
nohup rsync -ah --progress /backup/user/project/bins/ /home/user/project/input/bins/ > /home/user/project/input/copy.log 2>&1 &

# 看是不是还在同步
ps aux | grep rsync | grep -v grep
# 实时看日志
tail -f /home/user/project/input/copy.log
# 看已经复制了多少
du -sh /home/user/project/input/bins/

# 复制完核对一下
# 对比文件数量
find /backup/user/project/bins/ -type f | wc -l
find /home/user/project/input/bins/ -type f | wc -l

# 对比总大小
du -sh /backup/user/project/bins/
du -sh /home/user/project/input/bins/
```

=== cat / head / unzip / tar

```bash
# 小文件：直接看全文
cat smallfile.txt
cat -n file.txt              # 带行号

# 大文件：分页看
less bigfile.txt             # 可以按 `/` 搜索，`g/G` 跳到开头/结尾
more bigfile.txt             # 老版本

# 看开头 / 结尾
head -n 20 file.txt          # 前 20 行
tail -n 50 file.txt          # 后 50 行
tail -f analysis.log         # 实时盯日志（看分析进度的神器）

# 压缩文件不解压直接看
zcat file.txt.gz | head -n 20
zless file.txt.gz

# 解压到当前目录
unzip archive.zip

# 解压到指定目录（目录不存在会自动建）
unzip archive.zip -d /home/user/target_dir/

# 解压 .tar.gz 到当前目录（最常用）
tar -xzvf porTraits-DB.tar.gz
```

=== grep / sed / awk

```bash
# grep：搜索
grep "BRCA1" annotation.gff           # 基本搜索
grep -c "^>" sequences.fasta          # 统计 FASTA 有多少条序列
grep -v "^#" variants.vcf             # 反向匹配（排除注释行）
grep -i "error" pipeline.log          # 忽略大小写
grep -n "ERROR" log                   # 显示行号
grep -r "pattern" ./                  # 递归搜索

# sed：流编辑器
sed 's/old/new/g' file.txt            # 全局替换
sed -i 's/chr/chrom_/g' bed.txt       # 直接改原文件
sed -n '10,20p' file.txt              # 取出 10-20 行
sed '/^#/d' file.vcf                  # 删掉注释行
sed -i.bak 's/old/new/g' important.txt   # 改之前自动备份

# awk：按列处理
awk '{print $1, $3}' data.tsv         # 取指定列
awk -F',' '{print $2}' data.csv       # 指定分隔符
awk '$3 > 1000 {print $0}' bed.txt    # 按条件过滤
awk 'NR>1 {sum+=$2} END {print sum}' file.txt   # 求和
awk 'NR%4==2 {print length($0)}' *.fastq | sort | uniq -c   # 统计序列长度

# 列出某列的所有唯一值（列名不一定叫这个）
awk -F'\t' 'NR==1{for(i=1;i<=NF;i++) if($i=="site_cleaned") c=i; next} {print $c}' \
/home/user/projects/metadata.tsv | sort -u

# 如果列号已知（比如第 5 列），更简单：
FILE="/home/user/projects/metadata.tsv"
cut -f5 $FILE | tail -n +2 | sort -u
```

== （2）Conda

=== 常用命令速查

```bash
conda env list                              # 查看所有环境
conda create -n name python=3.11            # 创建环境
conda activate name                         # 激活环境
conda deactivate                            # 退出环境
mamba install pkg                           # 安装包
mamba remove pkg                            # 卸载包
conda list                                  # 看装了哪些包
conda update conda                          # 升级 conda
conda config --set channel_priority strict  # 设置严格优先级
conda env export > environment.yml          # 导出环境配置
```

=== 查看环境

```bash
# 查看所有环境
conda env list
conda info --envs                  # 效果一样

# 查看当前环境信息
conda info
conda -V                           # conda 版本

# 看当前环境装了哪些包
conda list
conda list -n env_name             # 看指定环境
conda list | grep numpy            # 找某个包

# 加载并激活服务器上的公用环境
module load miniconda/4.9.2&&source activate&&conda env list
```

=== 创建 / 激活 / 删除环境

```bash
# 创建新环境（一个项目一个环境比较好）
conda create -n myenv python=3.11
mamba create -n bioenv python=3.10 numpy pandas    # 用 mamba 更快

# 激活
conda activate myenv
# 或者这样激活
source /home/sanduo/miniconda3/bin/activate checkm2_env
# 退出
conda deactivate

# 删除环境
conda remove -n myenv --all
# 删之前先确认一下有没有建过：
conda env list | grep mag_rna_trna
```

=== 安装包

```bash
# 装包（尽量用 mamba）
mamba install numpy pandas
mamba install -c conda-forge --override-channels r-treemapify
mamba install -c https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/ --override-channels r-treemapify
conda install numpy=1.26               # 指定版本
conda install -c conda-forge gdal      # 从指定 channel 装
conda install -n env_name pkg          # 不激活环境也能装

# 更新 / 卸载
conda update numpy

# 搜索
conda search scipy
```

=== 设置镜像源

```bash
# 看当前有哪些源
conda config --show channels

# 添加 conda-forge（一般首选）
conda config --add channels conda-forge
conda config --add channels bioconda      # 生信常用

# 严格按优先级来（避免不同源混用出问题）
conda config --set channel_priority strict

# 安装时显示 channel 地址（方便排查）
conda config --set show_channel_urls yes

# 换成清华镜像，速度更快
site=https://mirrors.tuna.tsinghua.edu.cn/anaconda
conda config --add channels ${site}/pkgs/main/
conda config --add channels ${site}/cloud/conda-forge/
conda config --add channels ${site}/cloud/bioconda/
```

=== 清理缓存

```bash
# 清理缓存（用久了悄悄占几个 G 很正常）
conda clean --all
conda clean --tarballs     # 只清压缩包

# 回滚到出问题前的版本
conda list --revisions
conda install --revision 2
```

== （3）Slurm

=== 查看资源

```bash
# 看分区和节点状态
sinfo                                          # 分区概览
sinfo -N                                       # 按节点显示
sinfo -N | grep idle                           # 只看空闲节点
sinfo -o "%P %a %l %D %t %N"                   # 自定义输出格式
scontrol show node cu01                        # 节点信息
scontrol show partition                        # 分区信息
scontrol show job 12345                        # 作业信息

# 详细资源信息
scontrol show nodes | grep -E 'NodeName=|CPUAlloc=|CPUTot='
# 看自己当前跑的任务，以及 cu01~cu10 节点的内存情况
squeue -u $USER --format="%.10i %.8j %.4C %.6m %.6D %R" && echo "---" && for node in cu{01..10}; do echo "=== $node ==="; ssh $node "free -h" | grep -E "total|Mem"; done

# 看任务状态
squeue                                         # 所有任务
squeue -u username                             # 指定用户

# 任务详情 / 事后统计
scontrol show job <jobid>                      # 配置详情
sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,ReqMem,ReqCPUS
seff <jobid>                                   # 资源利用率（用来调下次申请多少）
```

=== top

```bash
# top：实时看系统状态和进程占用

# 直接输入就能运行：
top

# 上半部分是系统整体状态：
#   load average：最近 1 / 5 / 15 分钟的平均负载
#   Tasks：任务总数，以及运行、休眠、停止、僵尸进程各多少
#   %Cpu(s)：CPU 使用情况（用户态 us、内核态 sy、空闲 id、等 IO 的 wa 等）
#   Mem / Swap：物理内存和交换分区使用情况
#
# 例：
#   top - 12:25:40 up 911 days, 11 users, load average: 12.77, 12.82, 11.99
#   Tasks: 630 total, 2 running, 626 sleeping, 2 stopped, 0 zombie
#   %Cpu(s): 11.5 us, 0.6 sy, 87.8 id, 0.0 wa
#
# 其中：
#   us 用户态占用的比例
#   sy 内核态占用的比例
#   id CPU 空闲比例
#   wa 等磁盘或 IO 的时间比例

# 下半部分是每个进程的详细信息：
#   PID / USER：进程号 / 所属用户
#   PR / NI：优先级 / nice 值
#   VIRT / RES：虚拟内存 / 实际占用的物理内存
#   S：进程状态（R 运行中, S 休眠, D 不可中断睡眠, T 已停止, Z 僵尸）
#   %CPU / %MEM：占用的 CPU / 内存百分比
#   TIME+：累计占用的 CPU 时间
#   COMMAND：进程名或启动命令

# 常用交互键：
#   q 退出   P 按 CPU 排序   M 按内存排序   N 按 PID 排序
#   k 结束进程   1 显示每个 CPU 核心的情况

# 在集群上，top 常用来判断：
#   节点忙不忙、有没有高负载进程、作业是不是真用上了申请的 CPU、
#   内存紧不紧张、有没有 IO 等待或异常进程堆积

# 注意：load average 不是 CPU 使用率，而是一段时间内在运行或等待的任务数，
# 判断节点忙不忙要结合 CPU 核数一起看。
```

=== 提交 / 取消任务

```bash
# 提交
sbatch job_script.slurm

# 取消
scancel <jobid>
scancel -u $USER                     # 取消自己所有任务

# 稳妥一点：先停 pending，再停 running
# 取消 pending（可以一起取消）
squeue -h -j <jobid> -t PD -o "%i" | xargs -r -n 20 scancel

# 取消 running：每次三个，隔一分钟，给节点留时间清理
squeue -h -j <jobid> -t R -o "%i" | head -n 3 | xargs -r scancel
sleep 60
squeue -h -j <jobid> -t R -o "%i" | head -n 3 | xargs -r scancel
```

== （4）Qiime2

=== 激活环境 / 查看 biom

```bash
# 激活 QIIME 环境
conda activate qiime2-2024.2

# 看 biom 文件的 header 概览
biom head -i /home/user/data/DADA2.biom | head -n 10

# 看汇总统计（样本数、特征数、稀疏度等）
biom summarize-table -i /home/user/data/biom_all_qc.biom | head -n 10

# biom 和 tsv 互转
biom convert -i feature-table.biom -o feature-table.tsv --to-tsv
biom convert -i feature-table.tsv -o feature-table.biom \
             --table-type="OTU table" --to-hdf5
```

=== 导出

```bash
# 标准导出
qiime tools export \
  --input-path table.qza \
  --output-path ./table_output

biom convert \
  -i ./table_output/feature-table.biom \
  -o ./table_output/feature-table.tsv \
  --to-tsv

# 导出 taxonomy 表
qiime tools export \
  --input-path taxonomy.qza \
  --output-path ./taxonomy_output

# 导出 rooted tree 为 NWK 格式
qiime tools export \
  --input-path rooted-tree.qza \
  --output-path ./exported-rooted-tree
```

=== nohup 后台运行

```bash
nohup qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table table_gg2_id99_24409_56564_v5.qza \
  --p-sampling-depth 1000 \
  --m-metadata-file sample-metadata.tsv \
  --p-n-jobs 27 \
  --output-dir core-metrics-results > diversity.log 2>&1 &

# nohup    退出登录后命令继续跑
# > log    标准输出重定向到日志
# 2>&1     标准错误也重定向到同一个日志
# &        放到后台运行
```

=== 统计序列条数

```bash
# 方法一：直接用 Linux 命令（不用装 QIIME 2）

# 文件总行数（含标题行、序列行、空行）
unzip -p 2024.09.seqs.fna.qza "*/data/*" | wc -l

# 序列条数（"有多少条序列"）推荐
unzip -p 2024.09.seqs.fna.qza "*/data/*" | grep -c "^>"

# 方法二：用 QIIME 2（官方做法）

# 1) 先把 .qza 导出到目录
qiime tools export \
  --input-path 2024.09.seqs.fna.qza \
  --output-path exported_seqs_dir

# 2) 统计（导出后通常叫 dna-sequences.fasta）
# 总行数
wc -l exported_seqs_dir/*.fasta
# 序列条数（推荐）
grep -c "^>" exported_seqs_dir/*.fasta
```

== （5）R

=== 查看 R 包

```r
# 1. 列出要检查的包
my_packages <- c("data.table", "ggplot2", "dplyr")

# 2. 找出哪些还没装
missing_packages <- my_packages[!(my_packages %in% installed.packages()[,"Package"])]

# 3. 输出结果
if(length(missing_packages) > 0) {
  message("注意：以下 R 包还没安装：")
  print(missing_packages)
} else {
  message("不错，要用的包都装好了。")
}
```

=== 安装 R 包

```r
# 1) CRAN 官方源（最常用）
install.packages("dplyr")
install.packages(c("dplyr", "ggplot2", "tidyr"))

# 2) Bioconductor（生信专用）
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("DESeq2")
BiocManager::install(c("edgeR", "limma"))

# 3) GitHub（开发版 / 小众包）
install.packages("devtools")
devtools::install_github("user/repo")
# 或者用更轻量的 remotes
install.packages("remotes")
remotes::install_github("ChiLiubio/microeco")

# 4) 换国内镜像加速
options(repos = c(CRAN = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/"))
options(BioC_mirror = "https://mirrors.tuna.tsinghua.edu.cn/bioconductor")
# 也可以只在安装时临时指定
install.packages("sf", repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")

# 5) 在集群上用 Conda/Mamba 装（解决 C++ 等底层依赖）
# 用 mamba 比 conda 快很多；镜像源配置见上面 Conda 章节
conda activate r-env
mamba install r-cairo r-ggrastr r-treemapify

# 也可以按环境名指定：
mamba install -n r-env r-cairo r-ggrastr

# 或按绝对路径指定（最严谨，适合写进自动化脚本）：
mamba install -p /home/user/miniconda3/envs/r-env r-cairo r-ggrastr
```

=== 加载 / 更新 R 包

```r
library(dplyr)               # 加载包（失败会报错）
require(dplyr)               # 加载包（失败只返回 FALSE）

# 看已安装的包
installed.packages()[,"Package"]

# 帮助文档
library(help = ggplot2)
?ggplot                      # 查某个函数
??geom_point                 # 模糊搜索

# 更新包
update.packages()
update.packages(ask = FALSE)
```

=== 读取数据

```r
# === 数据读写 ===
df <- read.csv("file.csv", header = TRUE)
write.csv(df, "out.csv", quote = TRUE, row.names = FALSE)
saveRDS(df, "df.rds"); df <- readRDS("df.rds")

# === 查看数据结构 ===
str(df); summary(df); head(df, 10); tail(df, 3)
dim(df); nrow(df); ncol(df); names(df)

# === 取子集 ===
df[df$col1 == "A", c("col1", "col2")]
subset(df, col1 == "A", select = c(col1, col2))

# === dplyr 管道 ===
library(dplyr)
df %>%
  filter(group == "A") %>%
  select(id, value) %>%
  mutate(log_value = log2(value + 1)) %>%
  group_by(category) %>%
  summarise(mean_val = mean(log_value, na.rm = TRUE)) %>%
  arrange(desc(mean_val))

# === 条件判断 ===
df$sex <- ifelse(grepl("F", df$sample), "F", "M")
df <- df %>% mutate(status = case_when(
  grepl("^CT", status) ~ "CT",
  grepl("^IgAN", status) ~ "IgAN",
  is.na(status) ~ NA_character_,
  TRUE ~ "HC"
))

# === 字符串处理（stringr）===
library(stringr)
str_detect(x, "pattern")
str_replace(x, "old", "new")
str_split(x, "_")
str_extract(x, "[0-9]+")

# === ggplot2 ===
library(ggplot2)
ggplot(df, aes(x = pc1, y = pc2, color = group)) +
  geom_point(size = 3) +
  labs(x = "PCoA1 (32.5%)", y = "PCoA2 (18.7%)") +
  theme_bw()
```

== （6）Python

=== 安装环境

```python
# 方法一：用 Conda（生信里最省事）
mamba create -n myproj python=3.11
mamba install -n myproj pandas numpy scipy scikit-learn

# 方法二：venv（轻量的纯 Python 项目）
python -m venv .venv
source .venv/bin/activate           # Linux/Mac
# .venv\Scripts\activate            # Windows
pip install pandas numpy

# pip 换国内源加速
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pkg_name

# 导出 / 重建依赖
pip freeze > requirements.txt
pip install -r requirements.txt
```

=== pandas

```python
import pandas as pd

# 读取（注意：QIIME 导出的 tsv 要写 sep='\t'）
df = pd.read_csv("data.tsv", sep="\t", comment="#")
df = pd.read_csv("data.csv", dtype={"sample_id": str}, low_memory=False)

# 写出
df.to_csv("out.csv", index=False)
df.to_csv("out.tsv", sep="\t", index=False)

# 重命名 / 重设索引
df = df.rename(columns={"sample_id": "#SampleID"})
df = df.set_index("#SampleID")

# 过滤和变换
df_sub = df.query("group == 'A' and reads > 1000")
df["log_reads"] = np.log10(df["reads"] + 1)

# 分组聚合
df.groupby("group")["reads"].agg(["mean", "std", "count"])

# 合并
merged = pd.merge(df1, df2, on="sample_id", how="inner")
```

== （7）Git

=== 配置

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
git config --global core.editor "vim"
git config --global init.defaultBranch main

# 看配置
git config --list
```

=== clone

```bash
# 在当前目录初始化一个新仓库
git init

# 从远程克隆（会自动加上 origin）
git clone https://github.com/user/project.git
git clone git@github.com:user/project.git my-dir   # 指定目录名 + SSH 方式
```

=== commit

```bash
# 看状态
git status
git diff                    # 工作区 vs 暂存区
git diff --staged           # 暂存区 vs 上一次提交

# 暂存
git add file.txt            # 单个文件
git add .                   # 当前目录的所有改动
git add -p file.txt         # 分块暂存

# 提交
git commit -m "feat: 添加 PCoA 绘图脚本"
git commit -am "docs: 更新 README"   # -a 只对已跟踪的文件生效

# 看历史
git log
git log --oneline -10       # 最近十条，一行一条
git show <commit>           # 某次提交的详细内容
```

=== reset

```bash
# 丢掉工作区对某个文件的改动（还没 add）
git restore file.txt

# 撤销暂存（已经 add，想重新选）——防止误提交大的中间文件
git restore --staged .
git restore --staged file.txt

# 回退到某个提交，保留工作区的修改
git reset --soft <commit>

# 回退到某个提交，暂存区和工作区也一起回退（还没 push 时常用）
git reset --hard <commit>      # ⚠️ 危险：会丢掉没提交的修改

# 用一次新提交"抵消"某次历史提交（已经 push 时更安全）
git revert <commit>
```

=== branch

```bash
# 查看
git branch                  # 只看本地分支，* 是当前分支
git branch -a               # 连远程跟踪分支一起看
git branch -vv              # 看本地分支跟踪的上游

# 创建 / 切换（建议用 switch）
git switch -c feature/foo   # 新建并切换
git switch main             # 切换分支
# 旧写法也还很常见
git checkout -b feature/foo

# 合并
git merge develop           # 把 develop 合并进当前分支

# 删除
git branch -d feature/foo   # 删除已合并的分支
git branch -D feature/foo   # 强制删除
git push origin --delete feature/foo   # 删除远程分支
```

=== pull / push

```bash
# 看远程
git remote -v
git remote show origin

# 抓取与拉取
git fetch origin              # 只更新 origin/*，本地分支不动
git pull                      # 相当于 fetch + merge
git pull --rebase             # 相当于 fetch + rebase，保持线性历史

# 推送
git push                      # 已经设置上游的直接推
git push -u origin HEAD       # 第一次推送并建立跟踪
git push -u origin feature/my-work
```

=== proxy

```bash
# ========================================================
# 代理：git push 报 443 错误，多半是代理设置不对
# ========================================================

# 第一步：清掉旧的代理设置
git config --global --unset http.proxy
git config --global --unset https.proxy

# 第二步：按自己常用的端口重新设置（比如 7890）
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy https://127.0.0.1:7890

# 第三步：用完之后撤掉
# 平时能直连的话，代理只是临时用一下，不用了记得撤，免得白白耗流量
git config --global --unset http.proxy
git config --global --unset https.proxy

# 最后：确认代理都清干净了
git config --global --get http.proxy
git config --global --get https.proxy
```

=== stash

```bash
git stash                 # 把工作区的改动收起来
git stash list            # 看 stash 列表
git stash pop             # 恢复最近一次 stash，同时删除记录
git stash apply           # 恢复但保留 stash 记录
```

=== gitignore

```bash
# 大文件 / 中间结果
*.bam
*.sam
*.fastq
*.fastq.gz
*.qza
*.qzv
results/
intermediate/

# 环境和缓存
.venv/
__pycache__/
.ipynb_checkpoints/
.Rhistory
.RData

# IDE
.vscode/
.idea/
.DS_Store

# 敏感配置
.env
config.local.yaml
```

=== 总结：协作流程

```bash
# 1) 先拉最新代码再开发
git switch develop
git pull origin develop
git switch -c feature/pcoa-plot

# ... 改代码 ...
git add .
git commit -m "feat: 添加 PCoA 绘图脚本"
git push -u origin feature/pcoa-plot

# 2) 然后去 GitHub / GitLab 网页上提 Pull Request / Merge Request

# 3) 把远程 main 同步到当前分支
git fetch origin
git merge origin/main
# 或者保持线性历史
git rebase origin/main
```
