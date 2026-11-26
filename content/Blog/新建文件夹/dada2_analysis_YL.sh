#!/bin/bash
#SBATCH -J dada2_analysis
#SBATCH -p cu
#SBATCH -N 1
#SBATCH -c 14
#SBATCH --mem=30G
#SBATCH -t 9-24:00:00
#SBATCH -a 1-7
#SBATCH -o logs/dada2_analysis_%j_%a.out
#SBATCH -e logs/dada2_analysis_%j_%a.err
#SBATCH --exclude=cu01,cu06

# 0. Logs & Environment Preparation
mkdir -p logs
source /home/yanglun/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-2024.2

# 1. Core Variables
base_dir="/home/yanglun/YSD/YL-research-project/data_collection/time_series/Periodontitis"
study_list="${base_dir}/dataset_list_Periodontitis.txt"
r_script="${base_dir}/dada2_YL.r"

study_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${study_list}" | tr -d '\r\n')
[[ -n "$study_id" ]] || { echo "ERROR: No study_id for task ${SLURM_ARRAY_TASK_ID}"; exit 1; }
file_path="${base_dir}/${study_id}"
echo "Task ${SLURM_ARRAY_TASK_ID}: ${study_id}"

[[ -f "${file_path}/manifest.csv" ]] || { echo "ERROR: No manifest.csv, run step1 download first"; exit 1; }
find "${file_path}/rawdata" -name "*.fastq" -print -quit | grep -q . || { echo "ERROR: No FASTQ"; exit 1; }

# 2. QIIME2 Import & Quality Plot
qiime tools import \
    --type 'SampleData[SequencesWithQuality]' \
    --input-path "${file_path}/manifest.csv" \
    --output-path "${file_path}/demux.qza" \
    --input-format SingleEndFastqManifestPhred33V2

qiime demux summarize \
    --i-data "${file_path}/demux.qza" \
    --o-visualization "${file_path}/demux.qzv"
echo "Quality plot done: ${file_path}/demux.qzv (check on https://view.qiime2.org/ for truncLen)"

# 3. DADA2 Analysis (R, needs micro env; qiime2 env must be deactivated first)
conda deactivate
module load R/4.1.3
source /home/yanglun/miniconda3/bin/activate micro

Rscript "${r_script}" "${file_path}" trim || { echo "ERROR: DADA2 analysis failed"; exit 1; }

# 4. Output Check & Wrap Up
missing_files=""
for f in ASVs_counts.tsv ASVs.fa; do
    [[ -f "${file_path}/results/${f}" ]] || missing_files="${missing_files} ${f}"
done
if [[ -z "$missing_files" ]]; then
    echo "${study_id}: ALL SUCCESS"
    ls -lh "${file_path}/results"/ASVs_counts.tsv "${file_path}/results"/ASVs.fa
    EXIT_CODE=0
else
    echo "${study_id}: WARNING, missing output:${missing_files}"
    EXIT_CODE=1
fi

echo "End: $(date), Exit: $EXIT_CODE"
exit $EXIT_CODE
