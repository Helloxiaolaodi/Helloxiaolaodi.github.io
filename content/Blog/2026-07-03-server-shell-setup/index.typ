#import "../index.typ": template, tufted
#import "@preview/tablem:0.3.0": *
#import "@preview/theorion:0.6.0": quote-block

// 如需生成 RSS feed，必须填写 title、description 和 date 元数据
#show: template.with(
  title: "科研江湖之服务器的界面设置方案",
  description: "一套围绕科研服务器真实场景的 Bash 终端优化方案：Conda、ble.sh、tmux、zoxide、fzf、ripgrep、bat 等。",
  date: datetime(year: 2026, month: 7, day: 3),
  lang: "zh",
)

= 科研江湖之服务器的界面设置方案

== 不仅查数量，还查文件是否相同
有时候两个文件夹的数量一样，但里面的文件可能不一样。如果你想确认这两个文件夹里的文件名是否完全一模一样，可以使用 diff 命令：
diff -rq /home/user/input/humann3/ /backup/user/humann3/
== 直接统计所有文件数量（递归查询）
如果你想统计文件夹内所有的文件总数（包含子文件夹里面的文件），可以使用 find 结合 wc -l 命令。分别运行以下两条命令，对比输出的数字：
find /home/user/input/humann3/ -type f | wc -l
find /backup/user/humann3/ -type f | wc -l


这篇手册记录的是我在服务器账号下最终采用的一套 Bash 终端优化方案。它不是单纯追求炫酷，而是围绕科研服务器的真实使用场景来做取舍：无 root 权限、长期 SSH 登录、依赖 Conda、频繁切目录、频繁查脚本和日志、需要稳定而不是花哨。

整套方案尽量克制，不引入 `eza`、`Starship` 和 Slurm alias，只保留真正高频、稳定且长期有收益的部分：`Conda`、`ble.sh`、`nvm`、`tmux`、`zoxide`、`fzf`、`ripgrep`、`bat`、`csvtk`，以及 `.bashrc` 中最关键的交互 shell 隔离、历史记录优化和 `PATH` 管理。

== 0. Slurm模板
=== 0.1 批处理脚本

```bash
#!/bin/bash
#SBATCH --job-name=plot_pcoa
#SBATCH --partition=cu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=60G
#SBATCH --time=24:00:00
#SBATCH --output=logs/plot_pcoa_%j.out
#SBATCH --error=logs/plot_pcoa_%j.err
#SBATCH --exclude=cu01
#SBATCH --nodelist=cu02

set -euo pipefail

# ============================================================
# 1. 网络存储路径定义 (请根据实际情况修改)
# ============================================================
NET_PROJ_DIR="/home/yanglun/your_project_path"
NET_IN_DIR="${NET_PROJ_DIR}/input"
NET_OUT_DIR="${NET_PROJ_DIR}/output"
mkdir -p "${NET_PROJ_DIR}/logs" "${NET_OUT_DIR}"

# ============================================================
# 2. 本地工作区建立 & Trap 自动清理设置
# ============================================================
# 将临时目录限制在你的个人专属文件夹下，避免与其他用户冲突
LOCAL_BASE="/tmp/yanglun"
LOCAL_SCRATCH="${LOCAL_BASE}/job_${SLURM_JOB_ID}"

LOCAL_IN_DIR="${LOCAL_SCRATCH}/input"
LOCAL_OUT_DIR="${LOCAL_SCRATCH}/output"

# 【关键】绑定 Trap 命令：退出时不仅清理本地文件，还要关闭后台监控进程
trap '
    echo "[$(date)] Job exited. Stopping monitor and cleaning up..."
    kill ${MONITOR_PID} 2>/dev/null || true
    rm -rf "${LOCAL_SCRATCH}"
' EXIT

mkdir -p "${LOCAL_IN_DIR}" "${LOCAL_OUT_DIR}"

# ============================================================
# 3. 数据搬运与断点续传检查
# ============================================================
echo "[$(date)] Start moving data to local node: $(hostname)..."
# 将输入数据拉取到本地
cp -r "${NET_IN_DIR}/"* "${LOCAL_IN_DIR}/"

# 断点续传逻辑：如果网络存储已有部分输出，先同步到本地，防止重复计算
if [ "$(ls -A ${NET_OUT_DIR})" ]; then
    cp -r "${NET_OUT_DIR}/"* "${LOCAL_OUT_DIR}/"
fi
echo "[$(date)] Data movement completed."

# ============================================================
# 4. 启动后台监控 (定期检查本地输出)
# ============================================================
# 这个括号里的代码会在后台并行运行，每隔一段时间检查一次 LOCAL_OUT_DIR
(
    while true; do
        sleep 1800  # 每 30 分钟 (1800秒) 检查一次
        echo "--- [Monitor $(date)] Local output check ---"
        echo "Current size of ${LOCAL_OUT_DIR}: $(du -sh "${LOCAL_OUT_DIR}" | cut -f1)"
        echo "Latest files modified:"
        ls -lt "${LOCAL_OUT_DIR}" | head -n 5
        echo "----------------------------------------------"
    done
) &
MONITOR_PID=$! # 记录监控进程的 PID，供 trap 在结束时杀掉

# ============================================================
# 5. 运行核心任务 (针对本地路径)
# ============================================================
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK
export OPENBLAS_NUM_THREADS=$SLURM_CPUS_PER_TASK

set +u
source /home/yanglun/miniconda3/bin/activate maaslin3
set -u

echo "=========================================="
echo "Start time: $(date)"
echo "Working in: ${LOCAL_SCRATCH}"
echo "=========================================="

# 切换到本地目录执行，确保程序默认的 ./ 路径都在高速硬盘上
cd "${LOCAL_SCRATCH}"

# 【注意】在此运行你的代码时，请确保代码内部读取的是 LOCAL_IN_DIR，输出到 LOCAL_OUT_DIR
# 例如：Rscript ${LOCAL_IN_DIR}/plot_analysis.R --input ${LOCAL_IN_DIR} --output ${LOCAL_OUT_DIR}
Rscript ${LOCAL_IN_DIR}/plot_analysis.R

echo "=========================================="
echo "End time: $(date)"
echo "=========================================="

# ============================================================
# 6. 将结果拷回主存储 (打扫战场)
# ============================================================
echo "[$(date)] Calculation finished. Copying results back to Network Storage..."
cp -r "${LOCAL_OUT_DIR}/"* "${NET_OUT_DIR}/"
echo "[$(date)] All tasks completed successfully."
```

=== 0.2数组任务

```bash
#!/bin/bash
#SBATCH --job-name=batch_dada2
#SBATCH --partition=cu
#SBATCH --array=1-100%5
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=08:00:00
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --exclude=cu01

set -euo pipefail

# ============================================================
# 1. 识别当前子任务与路径定义
# ============================================================
# 从 samples.txt 中获取当前任务对应的样本名
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt | tr -d '\r\n')

NET_IN_DIR="/path/to/input"
# 每个样本专属的网络输出目录
NET_OUT_DIR="/path/to/results/${SAMPLE}"
mkdir -p "${NET_OUT_DIR}"

# 提前进行断点续传检查：如果 done 文件已存在，直接退出当前子任务
if [ -f "${NET_OUT_DIR}/${SAMPLE}.done" ]; then
    echo "skip ${SAMPLE}, already done."
    exit 0
fi

# ============================================================
# 2. 本地工作区建立 & Trap 自动清理设置
# ============================================================
# 数组任务使用 ARRAY_JOB_ID 和 ARRAY_TASK_ID 确保每个并行任务的文件夹独立
LOCAL_BASE="/tmp/yanglun"
LOCAL_SCRATCH="${LOCAL_BASE}/job_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
LOCAL_IN_DIR="${LOCAL_SCRATCH}/input"
LOCAL_OUT_DIR="${LOCAL_SCRATCH}/output"

trap '
    echo "[$(date)] Array task exited. Stopping monitor and cleaning up..."
    kill ${MONITOR_PID} 2>/dev/null || true
    rm -rf "${LOCAL_SCRATCH}"
' EXIT

mkdir -p "${LOCAL_IN_DIR}" "${LOCAL_OUT_DIR}"

# ============================================================
# 3. 数据搬运
# ============================================================
echo "[$(date)] Moving data for ${SAMPLE} to local node: $(hostname)..."
# 针对当前样本，仅拷贝它需要的文件，切勿把整个 input 库拷过来
cp "${NET_IN_DIR}/${SAMPLE}"* "${LOCAL_IN_DIR}/"

# ============================================================
# 4. 启动后台监控 (定期检查本地输出)
# ============================================================
(
    while true; do
        sleep 600  # 数组任务时间可能较短，每 10 分钟 (600秒) 检查一次
        echo "--- [Monitor ${SAMPLE}] ---"
        du -sh "${LOCAL_OUT_DIR}" || true
        ls -lt "${LOCAL_OUT_DIR}" | head -n 3 || true
    done
) &
MONITOR_PID=$!

# ============================================================
# 5. 运行核心任务 (针对本地路径)
# ============================================================
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK
export OPENBLAS_NUM_THREADS=$SLURM_CPUS_PER_TASK

echo "Processing sample: ${SAMPLE}"

# 执行你的命令，输入输出全部指向本地 LOCAL 目录
your_command --sample "$SAMPLE" \
             --input "${LOCAL_IN_DIR}" \
             --output "${LOCAL_OUT_DIR}"

# ============================================================
# 6. 结果回传与标记完成
# ============================================================
echo "[$(date)] Task finished for ${SAMPLE}. Copying back..."
cp -r "${LOCAL_OUT_DIR}/"* "${NET_OUT_DIR}/"

# 在网络存储打上完成标记
touch "${NET_OUT_DIR}/${SAMPLE}.done"
echo "[$(date)] Array task ${SLURM_ARRAY_TASK_ID} completed."
```

=== 0.3傻瓜式操作
```bash
# ==============================================================================
# Slurm 模板拆解说明：铁打的营盘（固定不变） 与 流水的兵（自定义业务）
# ==============================================================================

# ==============================================================================
# 一、 绝对不要动 / 强烈建议保留的代码（固定不变的框架）
# 这些代码构成了符合服务器管理员要求的“安全基石”。
# 它们负责保护登录节点、保护网络 I/O、并在任务意外中断时自动清理垃圾。
# ==============================================================================

# 1. 脚本声明与安全模式
# 确保脚本在遇到任何错误或未定义变量时立即停止，防止产生不可预期的脏数据。
#!/bin/bash
set -euo pipefail

# 2. 避开登录节点的指令
# 管理员明确要求不能在登录节点上运行计算。保留这行可以确保任务永远不被调度到 cu01。
#SBATCH --exclude=cu01

# 3. 多线程资源绑定
# 防止 R、Python 等底层计算库“偷跑”占用超过申请的 CPU 核心数，避免被系统强行杀掉。
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK
export OPENBLAS_NUM_THREADS=$SLURM_CPUS_PER_TASK

# 4. 本地专属目录生成规则
# 为你个人（yanglun）在节点本地划分绝对安全的自留地，依靠 JOB_ID 命名，绝不冲突。
# (单任务使用)
LOCAL_BASE="/tmp/yanglun"
LOCAL_SCRATCH="${LOCAL_BASE}/job_${SLURM_JOB_ID}"
# (数组任务使用)
# LOCAL_SCRATCH="${LOCAL_BASE}/job_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"

# 5. Trap 自动清理功能（自毁程序）
# 核心安全机制。保证无论任务怎么死掉，都不会在 /tmp 留下垃圾。
trap '
    echo "[$(date)] Job exited. Stopping monitor and cleaning up..."
    kill ${MONITOR_PID} 2>/dev/null || true
    rm -rf "${LOCAL_SCRATCH}"
' EXIT

# 6. 打扫战场的拷贝命令
# 固定将本地计算产生的所有结果一揽子拷回网络存储。
cp -r "${LOCAL_OUT_DIR}/"* "${NET_OUT_DIR}/"


# ==============================================================================
# 二、 必须由你自定义的代码（灵活修改的业务逻辑）
# 这部分代码每次跑新任务时，你都需要仔细检查并修改为你当前真实的业务需求。
# ==============================================================================

# 1. 资源申请区（Slurm 参数）
#SBATCH --job-name=你的任务名
#SBATCH --cpus-per-task=你需要几个CPU
#SBATCH --mem=你需要多少内存 (如 60G, 250G)
#SBATCH --time=需要运行多久 (如 24:00:00)
#SBATCH --array=1-100%5 # (仅限 0.2 数组任务，设定有多少个样本及并发数)

# 2. 网络主存储路径定义
# 告诉脚本你的真实数据在哪个网络硬盘里。
NET_PROJ_DIR="/home/yanglun/你的具体项目路径"
NET_IN_DIR="${NET_PROJ_DIR}/你的输入文件夹"
NET_OUT_DIR="${NET_PROJ_DIR}/你的输出文件夹"

# 3. 数据拉取规则（按需调整）
# 模板里默认是拉取整个文件夹：
cp -r "${NET_IN_DIR}/"* "${LOCAL_IN_DIR}/"
# 如果你只需要拉取特定文件，需要修改成：
# cp "${NET_IN_DIR}/data.csv" "${LOCAL_IN_DIR}/"

# 4. 环境激活
source /home/yanglun/miniconda3/bin/activate 你的具体环境名称 (如 qiime2, r-env, maaslin3)

# 5. 核心运行命令（你的核心业务）
# 你必须将这部分替换为你真实要跑的命令
# 唯一的要求是：所有涉及输入输出的路径，必须使用 ${LOCAL_IN_DIR} 和 ${LOCAL_OUT_DIR}
Rscript ${LOCAL_IN_DIR}/plot_analysis.R
# 或者
# your_command --input ${LOCAL_IN_DIR}/data --output ${LOCAL_OUT_DIR}/result


# ==============================================================================
# 三、 可以微调的辅助代码（后台监控模块）
# 方便你在排队跑任务时，能实时看一下本地到底有没有生成文件
# ==============================================================================

while true; do
    sleep 1800  # <--- 可以自定义这个数值
    
    # 调整说明：
    # sleep 1800 代表每半小时打印一次日志。
    # 如果你的任务很快（比如只有十分钟），你可以把它改成 sleep 120（两分钟打印一次）；
    # 如果你的任务跑七天七夜，你可以改成 sleep 7200（两小时一次），避免日志文件变得极其庞大。
    
    # ... (检查目录大小的命令代码)
done
```

== 1. 最终效果与适用场景

这套环境适合以下场景：

- 在 Linux 服务器或 HPC 集群上长期使用 Bash
- 主要工作是 Python、R、Shell、Node.js 相关脚本管理
- 需要 Conda 环境隔离
- 经常 SSH 断线重连，需要 `tmux` 保持会话
- 经常在很多目录、脚本、日志之间切换
- 经常需要在终端快速预览、切割和过滤大型 CSV/TSV 数据表

最终保留的组件如下：

- `Conda`：环境隔离底座
- `ble.sh`：Bash 语法高亮和增强交互
- `nvm`：Node.js 版本管理
- `tmux`：远程会话持久化
- `zoxide`：智能目录跳转
- `fzf`：模糊筛选
- `ripgrep`：高速全文搜索
- `bat`：高亮查看文本和代码
- `csvtk`：跨平台且高速的 CSV/TSV 处理利器

== 2. 预先检查：先确认哪些已安装、哪些还没配

在做任何修改之前，建议先盘点当前账号环境，避免重复安装，也方便后续排错。

=== 2.1 检查命令是否已在当前 `PATH` 中可用

```bash
for x in conda tmux zoxide fzf rg bat csvtk; do
  if command -v "$x" >/dev/null 2>&1; then
    printf '%-8s OK   %s\n' "$x" "$(command -v "$x")"
  else
    printf '%-8s MISS\n' "$x"
  fi
done
```

=== 2.2 检查 `.bashrc` 中关键配置是否存在

```bash
grep -n 'conda initialize' ~/.bashrc
grep -n 'source ~/.local/share/blesh/ble.sh' ~/.bashrc
grep -n 'NVM_DIR' ~/.bashrc
grep -n 'HISTSIZE' ~/.bashrc
grep -n 'zoxide init bash' ~/.bashrc
grep -n 'fzf --bash' ~/.bashrc
grep -n "alias cat='bat --paging=never'" ~/.bashrc
```

=== 2.3 检查 Conda 是否关闭了 `base` 自动激活

```bash
conda config --show auto_activate
```

理想输出：

```bash
auto_activate: False
```

=== 2.4 检查历史记录优化是否生效

```bash
echo "HISTSIZE=$HISTSIZE"
echo "HISTFILESIZE=$HISTFILESIZE"
echo "HISTCONTROL=$HISTCONTROL"
shopt -p histappend
printf '%s\n' "$PROMPT_COMMAND"
```

=== 2.5 检查基础文件路径是否存在

```bash
ls ~/.local/share/blesh/ble.sh
ls ~/.nvm/nvm.sh
ls ~/.nvm/bash_completion
```

== 3. 当前账号的完整 `.bashrc` 正式版配置

下面这份就是当前推荐的正式版 `.bashrc`。它保留了原有 `Conda`、`PS1`、`ble.sh`、`nvm`，并加入交互 shell 隔离、历史记录优化、`zoxide`、`fzf`、`bat` 配置。

```bash
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# Only run the rest for interactive shells
case $- in
  *i*) ;;
  *) return ;;
esac

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/user/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/user/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/user/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/user/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH="$HOME/miniconda3/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

__hist_sync() {
  history -a
  history -n
}

case ";${PROMPT_COMMAND:-};" in
  *";__hist_sync;"*) ;;
  "") PROMPT_COMMAND="__hist_sync" ;;
  *) PROMPT_COMMAND="__hist_sync; $PROMPT_COMMAND" ;;
esac

export PS1='[\[\e[01;92m\]\u@\h\[\e[0m\] \[\e[01;94m\]\W\[\e[0m\]]\$ '
source ~/.local/share/blesh/ble.sh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

eval "$(zoxide init bash)"

# Keep fzf conservative with ble.sh
FZF_CTRL_T_COMMAND=
FZF_CTRL_R_COMMAND=
FZF_ALT_C_COMMAND=
eval "$(fzf --bash)"

alias cat='bat --paging=never'
```

重新加载：

```bash
source ~/.bashrc
```

重新加载后验证：

```bash
command -v conda tmux zoxide fzf rg bat csvtk
type z
type zi
alias cat
printf '%s\n' "$PROMPT_COMMAND"
```

== 4. 最小改动版 `.bashrc`

如果不想一次性引入太多配置，只想在现有 `.bashrc` 基础上做最小改动，那么只保留下面这几部分就够了：交互 shell 隔离、`~/.local/bin`、历史记录优化、`zoxide`、`bat`。`fzf` 可以后加。

```bash
# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

case $- in
  *i*) ;;
  *) return ;;
esac

export PATH="$HOME/.local/bin:$PATH"

HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

__hist_sync() {
  history -a
  history -n
}

case ";${PROMPT_COMMAND:-};" in
  *";__hist_sync;"*) ;;
  "") PROMPT_COMMAND="__hist_sync" ;;
  *) PROMPT_COMMAND="__hist_sync; $PROMPT_COMMAND" ;;
esac

eval "$(zoxide init bash)"
alias cat='bat --paging=never'
```

这版的特点是：

- 不碰 `conda init` 代码块
- 不碰你现有 `PS1`
- 不碰 `ble.sh`
- 不碰 `nvm`
- 只补最核心的效率增强

== 5. 各工具的功能、检查、配置、验证与使用

=== 5.1 Conda：隔离科研环境的底座

`Conda` 的价值不在美观，而在稳定。它负责把 Python、R、Node.js 等相关依赖隔离开，避免系统环境和个人环境互相污染。

*功能优势*

- 隔离不同项目的依赖版本
- 避免系统 Python 被误改
- 适合无 root 权限的服务器环境

*检查是否已安装*

```bash
command -v conda
conda --version
```

*检查是否已接入 `.bashrc`*

```bash
grep -n 'conda initialize' ~/.bashrc
```

*配置操作*

```bash
# 初始化 Conda 的 Bash 环境，将配置写入 .bashrc
/home/user/miniconda3/bin/conda init bash
# 配置全局选项：关闭 base 默认环境的自动激活
conda config --set auto_activate false
```

*检查配置成功*

```bash
conda config --show auto_activate
conda env list
```

*使用方法*

```bash
conda activate ai-cli
conda deactivate
```

=== 5.2 `ble.sh`：给 Bash 增加现代交互体验

`ble.sh` 的定位是增强 Bash，而不是替代 Bash。它主要提供更舒服的行编辑、语法高亮和历史交互。

*功能优势*

- Bash 输入阶段更清晰
- 命令高亮和交互体验更好
- 不需要迁移到 zsh

*检查是否已安装*

```bash
ls ~/.local/share/blesh/ble.sh
```

*检查是否已接入 `.bashrc`*

```bash
grep -n 'source ~/.local/share/blesh/ble.sh' ~/.bashrc
```

*配置操作*

```bash
# 引入并激活 ble.sh，以提供语法高亮等增强交互特性
source ~/.local/share/blesh/ble.sh
```

*检查配置成功*

重开终端，输入错误命令如：

```bash
sls
```

若输入阶段出现明显高亮差异，说明已生效。

*使用方法*

继续按 Bash 原有习惯使用即可。

=== 5.3 `nvm`：管理 Node.js 版本

`nvm` 用于在同一账号下切换不同版本的 Node.js。只要后续需要不同版本的 Node CLI，它就很有价值。

*功能优势*

- 同一账号下管理多个 Node.js 版本
- 不依赖系统包管理器
- 与个人目录安装兼容

*检查是否已安装*

```bash
ls ~/.nvm/nvm.sh
ls ~/.nvm/bash_completion
```

*检查是否已接入 `.bashrc`*

```bash
grep -n 'NVM_DIR' ~/.bashrc
```

*配置操作*

```bash
# 声明 NVM 的目标安装与存储目录
export NVM_DIR="$HOME/.nvm"
# 若 nvm 主脚本存在，则加载它
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# 若 nvm 自动补全脚本存在，则加载它以增强输入体验
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

*检查配置成功*

```bash
command -v nvm
nvm --version
```

*使用方法*

```bash
# 列出服务器/本地已安装的所有 Node.js 版本
nvm ls
# 下载并安装 Node.js 20 大版本
nvm install 20
# 在当前终端会话中切换到 Node.js 20 版本
nvm use 20
```

=== 5.4 `tmux`：远程会话的保险层

`tmux` 是 SSH 用户最值得依赖的基础工具。断线后会话不丢，长任务和多窗口协作都更稳。

*功能优势*

- SSH 断线后会话仍保留
- 可拆分窗口并排查看任务和日志
- 适合长期远程工作

*检查是否已安装*

```bash
command -v tmux
tmux -V
```

*配置操作*

当前系统已提供：

```bash
# 系统自带路径，直接调用即可
/usr/bin/tmux
```

*检查配置成功*

```bash
tmux new -s test
```

如果能进入会话，则说明可用。退出测试：

```bash
exit
```

*使用方法*

```bash
# 创建一个名为 work 的后台持久化会话
tmux new -s work
# 连接到已存在且在后台运行的 work 会话
tmux attach -t work
# 罗列当前运行的所有 tmux 会话
tmux ls
# 在外部直接关闭并清理名为 work 的会话
tmux kill-session -t work
```

=== 5.5 `zoxide`：智能目录跳转

`zoxide` 是整个方案里收益最高的工具之一。它会记住你常去的目录，让 `cd` 长路径这件事变得基本不再需要手打。

*功能优势*

- 减少输入长路径
- 常用目录跳转更快
- Bash 集成自然

*检查是否已安装*

```bash
command -v zoxide
zoxide --version
```

*无 root 安装操作*

```bash
# 确保在当前用户下创建专门存放二进制可执行文件的目录
mkdir -p ~/.local/bin
# 建立安全的临时目录
tmpdir="$(mktemp -d)"
# 切换进临时目录，如果失败直接退出脚本
cd "$tmpdir" || exit 1

# 从 GitHub 下载 zoxide 对应的预编译二进制压缩包
curl -fLO [https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.9/zoxide-0.9.9-x86_64-unknown-linux-musl.tar.gz](https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.9/zoxide-0.9.9-x86_64-unknown-linux-musl.tar.gz)
# 解压缩下载好的归档文件
tar -xzf zoxide-0.9.9-x86_64-unknown-linux-musl.tar.gz
# 将解压后的可执行程序安装到 ~/.local/bin，并赋予执行权限(755)
install -m 755 zoxide ~/.local/bin/zoxide

# 安装完毕返回用户主目录
cd ~
# 删除不再使用的临时工作目录以释放空间
rm -rf "$tmpdir"
```

*配置操作*

```bash
# 将存放可执行程序的个人 bin 目录加入全局路径（使其全局可用）
export PATH="$HOME/.local/bin:$PATH"
# 在 Bash 中初始化 zoxide 并注入其核心跳转逻辑
eval "$(zoxide init bash)"
```

*检查配置成功*

```bash
command -v zoxide
type z
type zi
```

*使用方法*

```bash
# 模糊匹配并跳转到名为 normal-scripts 的最常用目录
z normal-scripts
# 模糊匹配并跳转到名字中包含 notes 的目录
z notes
# 打开交互式菜单（需结合 fzf 效果更好），供你选择想跳转的目标
zi
```

=== 5.6 `fzf`：模糊筛选器

`fzf` 是很多命令行增强玩法的基础组件。即使先采用保守接入，它也已经足够实用。

*功能优势*

- 模糊筛选文件、目录、历史记录
- 可与 `zoxide`、`rg` 组合使用
- 扩展空间大

*检查是否已安装*

```bash
command -v fzf
fzf --version
```

*无 root 安装操作*

```bash
# 确保在当前用户下创建存放可执行文件的目录
mkdir -p ~/.local/bin
# 建立系统层面的随机安全临时目录
tmpdir="$(mktemp -d)"
# 切入临时目录，若操作失败则安全退出
cd "$tmpdir" || exit 1

# 静默并允许重定向下载 fzf 的 Linux 压缩包
curl -fLO [https://github.com/junegunn/fzf/releases/download/v0.73.1/fzf-0.73.1-linux_amd64.tar.gz](https://github.com/junegunn/fzf/releases/download/v0.73.1/fzf-0.73.1-linux_amd64.tar.gz)
# 释放压缩包内的文件
tar -xzf fzf-0.73.1-linux_amd64.tar.gz
# 将 fzf 的二进制文件复制到 PATH 目录，并加上执行权限
install -m 755 fzf ~/.local/bin/fzf

# 返回最顶层目录
cd ~
# 强制且递归地清空并删除临时目录
rm -rf "$tmpdir"
```

*配置操作*

为降低和 `ble.sh` 的冲突风险，先采用保守配置：

```bash
# 将 fzf 绑定的 Ctrl-T (文件搜索) 热键置空，防止干扰
FZF_CTRL_T_COMMAND=
# 将 fzf 绑定的 Ctrl-R (历史记录) 热键置空，交回给原生功能或 ble.sh
FZF_CTRL_R_COMMAND=
# 将 fzf 绑定的 Alt-C (目录跳转) 热键置空
FZF_ALT_C_COMMAND=
# 注册 fzf 的基础补全功能和环境到 Bash 
eval "$(fzf --bash)"
```

*检查配置成功*

```bash
command -v fzf
grep -n 'fzf --bash' ~/.bashrc
```

*使用方法*

```bash
# 递归列出当前文件夹下所有常规文件，用管道传给 fzf 让你实时模糊选择
find . -type f | fzf
# 输出所有历史命令，配合 fzf 进行高频翻找过滤
history | fzf
# 用 ripgrep 先粗筛出含有 'TODO' 的行，再交由 fzf 让你精确定位
rg 'TODO' . | fzf
```

=== 5.7 `ripgrep`：高速全文搜索

`ripgrep` 是服务器上最值得替代传统 `grep -R` 的工具之一。搜索快，默认行为也更适合项目目录。

*功能优势*

- 搜索速度快
- 更适合代码和配置目录
- 常用参数少，默认就好用

*检查是否已安装*

```bash
command -v rg
rg --version
```

*无 root 安装操作*

```bash
# 创建个人应用存放目录
mkdir -p ~/.local/bin
# 申请分配一个临时文件夹
tmpdir="$(mktemp -d)"
# 跳转到此文件夹，遇到异常停止后续执行
cd "$tmpdir" || exit 1

# 从 GitHub 拉取指定版本的 ripgrep 包
curl -fLO [https://github.com/BurntSushi/ripgrep/releases/download/15.1.0/ripgrep-15.1.0-x86_64-unknown-linux-musl.tar.gz](https://github.com/BurntSushi/ripgrep/releases/download/15.1.0/ripgrep-15.1.0-x86_64-unknown-linux-musl.tar.gz)
# 拆包提取出内部内容
tar -xzf ripgrep-15.1.0-x86_64-unknown-linux-musl.tar.gz
# 找到深层目录中的 rg 执行程序，移交到环境调用的 bin 目录下
install -m 755 ripgrep-15.1.0-x86_64-unknown-linux-musl/rg ~/.local/bin/rg

# 返回根目录并安全着陆
cd ~
# 消除临时作业区的磁盘占用
rm -rf "$tmpdir"
```

*配置操作*

```bash
# 确保个人可执行目录加入系统调用的优先通道，保证 rg 能被搜到
export PATH="$HOME/.local/bin:$PATH"
```

*检查配置成功*

```bash
command -v rg
rg --version
```

*使用方法*

```bash
# 以最快速度在当前目录下查找带有 TODO 的代码/文本段落
rg 'TODO'
# 限定目标在 scripts 目录，匹配所有带有 'sample_id' 字符串的上下文
rg 'sample_id' scripts
# 强行指定搜索 ~/.bashrc 文件内的 'conda'，同时打印行号 (-n)
rg -n 'conda' ~/.bashrc
# 限定搜索目标仅为 Python 类型文件 (-t py)，并搜寻导入 pandas 的行
rg -t py 'import pandas'
```

=== 5.8 `bat`：高亮查看文件

`bat` 最适合看脚本、配置文件和日志片段。相比原生 `cat`，它在可读性上提升非常明显。

*功能优势*

- 支持语法高亮和行号
- 看脚本和配置更清晰
- 适合做快速预览

*检查是否已安装*

```bash
command -v bat
bat --version
```

*无 root 安装操作*

```bash
# 确保 PATH 载入用的 bin 存在
mkdir -p ~/.local/bin
# 借用系统命令开启独立临时空间
tmpdir="$(mktemp -d)"
# 切入，防意外终止
cd "$tmpdir" || exit 1

# 将高亮查看器 bat 的安装包下载到此临时空间
curl -fLO [https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz](https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz)
# 抽出包体内的所有附带文件
tar -xzf bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz
# 精准提取 bat 主程序并授予 755 执行权放到调用链路中
install -m 755 bat-v0.26.1-x86_64-unknown-linux-musl/bat ~/.local/bin/bat

# 操作完成后复位到当前账户
cd ~
# 销毁无用的临时文件
rm -rf "$tmpdir"
```

*配置操作*

```bash
# 用带语法高亮特性的 bat 平替传统的 cat；强制不分页展示(--paging=never) 以符合 cat 习惯
alias cat='bat --paging=never'
```

*检查配置成功*

```bash
command -v bat
bat --version
alias cat
```

*使用方法*

```bash
# 直接调用 bat 对 ~/.bashrc 进行高度可视化的源码渲染读取
bat ~/.bashrc
# 通过刚才设立的别名(alias)，像平常一样用 cat，但享受 bat 的展示效果
cat ~/.bashrc
# 让 bat 强制打印行号 (-n)，适用于找代码错误
bat -n script.py
```

=== 5.9 `csvtk`：命令行下的表格数据处理利器

在跑大规模数据流时，如果动辄要把 GB 级的特征表或元数据表导进 R/Python 才能预览或过滤，效率太低。`csvtk` 是一个用 Go 语言编写的高性能 CSV/TSV 处理工具，在终端直接对大表格进行切片、过滤、统计，极其好用。

*功能优势*

- 速度极快且内存占用极低，能轻松应对几万行到上百万行的数据矩阵。
- 原生支持多线程处理，且语法逻辑类似 SQL 和常见的文本处理管道。
- 支持无缝处理压缩文件（直接读取 `.tsv.gz` 等），无需提前解压。

*检查是否已安装*

```bash
command -v csvtk
csvtk version
```

*无 root 安装操作*

```bash
# 确保个人可执行目录存在
mkdir -p ~/.local/bin
# 开启安全临时工作区
tmpdir="$(mktemp -d)"
# 切入临时目录，遇错则退出
cd "$tmpdir" || exit 1

# 从 GitHub 下载 csvtk (此处以目前常见版本为例)
curl -fLO https://github.com/shenwei356/csvtk/releases/download/v0.30.0/csvtk_linux_amd64.tar.gz
# 解压缩
tar -xzf csvtk_linux_amd64.tar.gz
# 安装到调用路径并赋予执行权限
install -m 755 csvtk ~/.local/bin/csvtk

# 退回主目录
cd ~
# 清理临时文件
rm -rf "$tmpdir"
```

*配置操作*

只要保证 `~/.local/bin` 已经在 `.bashrc` 的 `PATH` 中即可，无需额外配置环境变量。

*检查配置成功*

```bash
command -v csvtk
csvtk version
```

*使用方法*

```bash
# 漂亮地在终端里对齐预览表头和前几行数据内容 (支持 TSV 时需加 -t 参数)
csvtk pretty -t metadata.tsv | head -n 20
# 快速查看表格的维度（多少行，多少列）
csvtk dim data.csv
# 获取表头的所有列名，方便后续精准调用
csvtk headers -t metadata.tsv
# 获取表头的所有列名及其列号，方便后续精准调用
csvtk headers -v -t metadata.tsv
csvtk headers -t metadata.tsv | cat -n
csvtk headers -t metadata.tsv | nl

# CSV 格式（用英文逗号 , 分隔的），要把 -t 换成 -d ','（或者直接去掉分隔符参数，因为 csvtk 默认就是处理 CSV 逗号分隔的）
csvtk headers -v metadata.tsv
csvtk headers metadata.tsv | cat -n
csvtk headers metadata.tsv | nl
# 自动提取某列的所有唯一值，并按出现频率从高到低排序（不需要统计频数, 用csvtk cut 和 Linux 原生的 sort -u 结合）
csvtk freq -f country_cleaned -n -r "metadata.tsv" 
csvtk cut -f country_cleaned "metadata.tsv" | tail -n +2 | sort -u
# (注意：csvtk 默认处理的是逗号分隔的 CSV 文件，而你的文件是 .tsv格式。因此需要加上 -t 或 --tabs 参数，明确告诉 csvtk 这是一个用制表符分隔的文件。)
csvtk freq -t -f country_cleaned -n -r "metadata.tsv"
csvtk cut -t -f country_cleaned "metadata.tsv" | tail -n +2 | sort -u

# 查看唯一值的总个数
csvtk freq -f pair_bioproject -n -r "metadata.tsv" | tail -n +2 | wc -l

# 查找包含 NA 或空白的样本
csvtk grep -f country_cleaned -p "NA" "metadata.tsv" | csvtk pretty
csvtk grep -f country_cleaned -r -p "^$" "metadata.tsv"
# 大招！同时检查 "NA"、"NaN" 或空白（极力推荐）
csvtk filter2 -f '$country_cleaned == "NA" || $country_cleaned == "NaN" || $country_cleaned == ""' "metadata.tsv"

# 得到 country_cleaned 和 continent_group 的对应关系
csvtk cut -t -f country_cleaned,continent_group "metadata.tsv" | sort -u
csvtk freq -t -f country_cleaned,continent_group "metadata.tsv"
csvtk freq -t -f country_cleaned,continent_group -n -r "metadata.tsv"
```

== 6. 新工具统一安装命令

如果需要从零开始重装 `zoxide`、`fzf`、`ripgrep`、`bat`，可以直接执行下面整组命令。整个过程不需要 root，只写入 `~/.local/bin`。

```bash
# 保证存放可执行程序的本地基础目录被成功创建
mkdir -p ~/.local/bin
# 申请独占的安全临时目录并保存其路径
tmpdir="$(mktemp -d)"
# 跳转过去作为工作台，如果失败则退出保护
cd "$tmpdir" || exit 1

# 流程1：下载并部署 fzf（交互式模糊查找工具）
curl -fLO [https://github.com/junegunn/fzf/releases/download/v0.73.1/fzf-0.73.1-linux_amd64.tar.gz](https://github.com/junegunn/fzf/releases/download/v0.73.1/fzf-0.73.1-linux_amd64.tar.gz)
tar -xzf fzf-0.73.1-linux_amd64.tar.gz
install -m 755 fzf ~/.local/bin/fzf

# 流程2：下载并部署 zoxide（智能 cd 替代品，记录使用频次）
curl -fLO [https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.9/zoxide-0.9.9-x86_64-unknown-linux-musl.tar.gz](https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.9/zoxide-0.9.9-x86_64-unknown-linux-musl.tar.gz)
tar -xzf zoxide-0.9.9-x86_64-unknown-linux-musl.tar.gz
install -m 755 zoxide ~/.local/bin/zoxide

# 流程3：下载并部署 ripgrep (rg)（极其高速的代码级别文本搜索利器）
curl -fLO [https://github.com/BurntSushi/ripgrep/releases/download/15.1.0/ripgrep-15.1.0-x86_64-unknown-linux-musl.tar.gz](https://github.com/BurntSushi/ripgrep/releases/download/15.1.0/ripgrep-15.1.0-x86_64-unknown-linux-musl.tar.gz)
tar -xzf ripgrep-15.1.0-x86_64-unknown-linux-musl.tar.gz
install -m 755 ripgrep-15.1.0-x86_64-unknown-linux-musl/rg ~/.local/bin/rg

# 流程4：下载并部署 bat（代替 cat 的带语法高亮文件预览工具）
curl -fLO [https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz](https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz)
tar -xzf bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz
install -m 755 bat-v0.26.1-x86_64-unknown-linux-musl/bat ~/.local/bin/bat

# 流程5：下载并部署 csvtk（极速 CSV/TSV 表格处理工具）
curl -fLO https://github.com/shenwei356/csvtk/releases/download/v0.30.0/csvtk_linux_amd64.tar.gz
tar -xzf csvtk_linux_amd64.tar.gz
install -m 755 csvtk ~/.local/bin/csvtk

# 所有工具部署完毕后返回主目录
cd ~
# 垃圾回收：抹除临时占用的文件与文件夹
rm -rf "$tmpdir"
```

安装完后执行：

```bash
# 激活 ~/.bashrc 以导入新增环境变量和设置
source ~/.bashrc
# 检测新安装的所有应用是否在当前环境的 PATH 优先级内成功响应
command -v zoxide fzf rg bat tmux csvtk
# 分别检查并核对工具版本号，确保非坏包
zoxide --version
fzf --version
rg --version
bat --version
csvtk version
```

== 7. 高频使用姿势

配置完成后，平时最常用的通常就是下面这些动作。

=== 7.1 快速跳目录

```bash
# 基于以往使用习惯，算法智能匹配出 normal-scripts 的绝对路径并带入
z normal-scripts
# 跳转到历史上带 notes 的高频目录
z notes
# 如果有多个相似 notes 目录，按 zi 唤起 fzf 列表进行上下键选中
zi
```

=== 7.2 搜索脚本和配置

```bash
# 快速定位出 Bash 配置文件中和历史条数(HISTSIZE)有关的地方
rg 'HISTSIZE' ~/.bashrc
# 在目前所在目录下的所有层级中全面寻找 'sample_id' 的身影
rg 'sample_id' .
# 针对指定的类型（如只搜 .py 后缀文件）排查 import os 的声明
rg -t py 'import os'
```

=== 7.3 预览配置和代码

```bash
# 使用 bat 让没有扩展名的 .bashrc 也能呈现良好的 Shell 语法高亮
bat ~/.bashrc
# 通过上面设置的 alias 'bat --paging=never' 直接预览
cat ~/.bashrc
# 预览脚本全貌
bat script.py
```

=== 7.4 用 `fzf` 做筛选

```bash
# 将系统搜索出的全部平铺文件交给 fzf 做按键级过滤寻找
find . -type f | fzf
# 通过 history 列出长长的一串执行记录，借 fzf 极速翻出曾敲过的复杂指令
history | fzf
# 结合技：rg 先把带有 TODO 的代码片筛出，fzf 再让你人工去细分选择要处理的项
rg 'TODO' . | fzf
```

=== 7.5 用 `tmux` 挂长期会话

```bash
# 建一个干净的且不受网络掉线影响的名为 work 的守护进程环境
tmux new -s work
# 连接到你之前断开或是挂在后台的那个 work 会话
tmux attach -t work
# 看看目前你起了哪些不同名字的任务会话窗口
tmux ls
```

=== 7.6 用 `csvtk` 切割过滤表格数据

当需要处理超大规模的采样表格时，可以不用启动编程环境，在命令行直接秒出结果：

```bash
# 从大规模的元数据表中（假设是 TSV 格式），单独抽取出 "SampleID" 和 "Group" 这两列
csvtk cut -t -f SampleID,Group metadata.tsv > subset.tsv

# 结合正则过滤：精准保留以 "P-" 为前缀的主队列样本（去掉非主队列），并写入新文件
csvtk grep -t -f SampleID -p "^P-" metadata.tsv > primary_cohort.tsv

# 利用管道做组合拳：先筛选带有特定特征的样本行，再将它们美观地展示在终端
csvtk grep -t -f BMI_Category -p "Obese" metadata.tsv | csvtk pretty -t | head -n 30
```

== 8. 注意事项

这套配置虽然已经比较稳，但在服务器环境里仍然有几条边界需要明确。

- 不要手改 `conda init` 自动生成的大代码块，只在外部补配置。
- 交互 shell 隔离必须放在 `.bashrc` 前部，否则 `ble.sh`、`fzf`、alias 可能污染非交互 shell。
- `fzf` 已采用保守初始化，先不抢 `Ctrl-R`、`Ctrl-T`、`Alt-C`，是为了降低和 `ble.sh` 的冲突概率。
- `alias cat='bat --paging=never'` 适合交互终端，不建议把这种 alias 的行为带进脚本。
- `~/.local/bin` 必须加入 `PATH`，否则即使工具已安装，重登后也会表现为“命令不存在”。
- 如果服务器网络受限，GitHub 下载链接可能失败，此时需要换镜像或手动上传二进制文件。
- `tmux` 虽然系统已提供，但如果你后续引入自己的 `~/.tmux.conf`，需要单独验证快捷键和终端兼容性。

== 9. 常见故障排查

=== 9.1 明明装了工具，重登后却提示 `command not found`

先检查：

```bash
echo "$PATH"
command -v zoxide fzf rg bat csvtk
```

如果 `~/.local/bin` 不在 `PATH` 中，说明 `.bashrc` 没有正确加载，或者 `export PATH="$HOME/.local/bin:$PATH"` 没放对位置。

=== 9.2 `z` 命令不存在，但 `zoxide` 命令存在

检查：

```bash
command -v zoxide
grep -n 'zoxide init bash' ~/.bashrc
type z
```

这通常说明 `eval "$(zoxide init bash)"` 没有被执行，或者 `.bashrc` 没重新加载。

=== 9.3 `fzf` 存在，但交互行为不明显

先检查：

```bash
command -v fzf
grep -n 'fzf --bash' ~/.bashrc
```

这里属于预期行为。当前配置是保守模式，没有开启默认快捷键抢占。你仍然可以直接使用：

```bash
find . -type f | fzf
history | fzf
```

=== 9.4 `cat` 显示变成了彩色输出，不适合某些场景

这是因为：

```bash
alias cat='bat --paging=never'
```

临时绕过 alias：

```bash
\cat file.txt
command cat file.txt
```

如果长期不想覆盖原生 `cat`，可改成：

```bash
alias b='bat --paging=never'
```

=== 9.5 多个终端的历史记录没有同步

检查：

```bash
shopt -p histappend
printf '%s\n' "$PROMPT_COMMAND"
```

如果 `PROMPT_COMMAND` 里没有 `__hist_sync`，说明历史同步逻辑没被正确拼进去。

=== 9.6 `ble.sh` 和 `fzf` 看起来有按键冲突

当前方案已经通过下面三行做了保守处理：

```bash
FZF_CTRL_T_COMMAND=
FZF_CTRL_R_COMMAND=
FZF_ALT_C_COMMAND=
```

如果你后面主动开启了 `fzf` 快捷键，又出现冲突，建议先回退到这三行空置状态。

=== 9.7 `source ~/.bashrc` 后报错

先做语法检查：

```bash
bash -n ~/.bashrc
```

再分段定位：

```bash
sed -n '1,220p' ~/.bashrc
```

最常见的问题是手动粘贴时把多行压成了一行，或者漏掉了引号、分号、换行。

== 10. 最终结论

一套真正适合服务器科研账号的终端配置，不应该把重点放在花哨提示符上，而应该先把稳定性和高频效率动作做好。对我这套环境来说，最核心的收益来自这几件事：

- `Conda` 负责环境隔离
- `ble.sh` 负责更舒服的 Bash 交互
- `tmux` 负责远程会话稳定性
- `zoxide` 负责目录跳转效率
- `fzf` 负责模糊筛选
- `ripgrep` 负责全文搜索
- `bat` 负责高亮阅读
- csvtk 负责数据预处理和表格流洗筛
- `.bashrc` 的交互隔离和历史同步负责整个终端体验的底层稳定

如果后续还要继续加工具，我的顺序仍然是：先补 `fd`，再考虑 `direnv`，最后才考虑 `Starship` 这一类偏外观的组件。
