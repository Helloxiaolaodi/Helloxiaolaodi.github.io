#!/bin/bash
#SBATCH -J dada2_download_test
#SBATCH -p cu
#SBATCH -N 1
#SBATCH -c 4
#SBATCH --mem=30G
#SBATCH -t 2-24:00:00
#SBATCH -a 2,5
#SBATCH -o logs/dada2_download_%j_%a.out
#SBATCH -e logs/dada2_download_%j_%a.err
#SBATCH --exclude=cu01,cu06

# 0. Logs & Environment Preparation
mkdir -p logs
source /home/yanglun/miniconda3/bin/activate micro

# 1. Core Variables
base_dir="/home/yanglun/YSD/YL-research-project/data_collection/time_series/Periodontitis"
study_list="/home/yanglun/YSD/YL-research-project/data_collection/time_series/Periodontitis/dataset_list_Periodontitis.txt"

# Pick the study_id for this array task
study_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${study_list}")
[[ -n "$study_id" ]] || { echo "ERROR: No study_id for task ${SLURM_ARRAY_TASK_ID}"; exit 1; }
echo "Task ${SLURM_ARRAY_TASK_ID}: ${study_id}"

file_path="${base_dir}/${study_id}"
mkdir -p "${file_path}"/{sra,intermediate,rawdata,results,temp}

# 2. Fetch SRA List
curl -s "https://trace.ncbi.nlm.nih.gov/Traces/sra-db-be/runinfo?acc=${study_id}" | \
    awk -F ',' 'NR>1 {print $1}' | grep -E '^[SDE]RR' | tr -d '\r' > "${file_path}/sample.txt"
[[ -s "${file_path}/sample.txt" ]] || { echo "ERROR: Fetch failed."; exit 1; }

# 3. Download & Convert
srun prefetch --option-file "${file_path}/sample.txt" --output-directory "${file_path}/sra" || true

shopt -s nullglob
sra_files=("${file_path}/sra"/*/*.sra)
[[ ${#sra_files[@]} -gt 0 ]] || { echo "ERROR: No SRA files."; exit 1; }
ls "${file_path}/sra"/*/*.sra | awk -F'/' '{print $(NF-1)}' > "${file_path}/sample_downloaded.txt"

# Print successfully downloaded count
echo "Downloaded: $(wc -l < "${file_path}/sample_downloaded.txt") / $(wc -l < "${file_path}/sample.txt")"

while read -r run_id; do
    echo "Dump: ${run_id}"
    srun fastq-dump --split-3 --threads 4 "${file_path}/sra/${run_id}/${run_id}.sra" --outdir "${file_path}/rawdata"
done < "${file_path}/sample_downloaded.txt"

find "${file_path}/rawdata" -name "*.fastq" -print -quit | grep -q . || { echo "ERROR: No FASTQ."; exit 1; }

# 4. Generate Manifest
printf 'SampleID,absolute-filepath,direction\n' > "${file_path}/manifest.csv"
for fq in "${file_path}/rawdata"/*.fastq; do
    sid=$(basename "$fq" .fastq)
    [[ "$sid" == *_2 ]] && continue
    printf '%s,%s,forward\n' "${sid%_1}" "$(realpath "$fq")" >> "${file_path}/manifest.csv"
done

# 5. Missing Check & Wrap Up
missing_count=$(comm -23 <(sort -u "${file_path}/sample.txt") <(sort -u "${file_path}/sample_downloaded.txt") | wc -l)
if [[ $missing_count -eq 0 ]]; then
    echo "${study_id}: ALL SUCCESS"
    EXIT_CODE=0
else
    echo "${study_id}: WARNING, ${missing_count} sample(s) missing:"
    comm -23 <(sort -u "${file_path}/sample.txt") <(sort -u "${file_path}/sample_downloaded.txt")
    EXIT_CODE=1
fi

echo "End: $(date), Exit: $EXIT_CODE"
exit $EXIT_CODE
