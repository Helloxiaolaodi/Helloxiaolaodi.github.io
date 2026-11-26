#!/bin/bash
#SBATCH -J closed_reference
#SBATCH -p cu
#SBATCH -N 1
#SBATCH -c 14
#SBATCH --mem=30G
#SBATCH -t 9-24:00:00
#SBATCH -a 1-7
#SBATCH -o logs/closed_reference_%j_%a.out
#SBATCH -e logs/closed_reference_%j_%a.err
#SBATCH --exclude=cu01,cu06

# 0. Logs & Environment Preparation
mkdir -p logs
source /home/yanglun/miniconda3/etc/profile.d/conda.sh
conda activate qiime2-2024.2

# 1. Core Variables
base_dir="/home/yanglun/YSD/YL-research-project/data_collection/time_series/Periodontitis"
study_list="${base_dir}/dataset_list_Periodontitis.txt"
reference="${base_dir}/2024.09.backbone.full-length.fna.qza"

# Pick the study_id for this array task
study_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${study_list}" | tr -d '\r\n')
[[ -n "$study_id" ]] || { echo "ERROR: No study_id for task ${SLURM_ARRAY_TASK_ID}"; exit 1; }
file_path="${base_dir}/${study_id}"
echo "Task ${SLURM_ARRAY_TASK_ID}: ${study_id}"

[[ -f "${file_path}/results/ASVs_counts.tsv" ]] || { echo "ERROR: No ASVs_counts.tsv, run DADA2 analysis first"; exit 1; }
[[ -f "${file_path}/results/ASVs.fa" ]] || { echo "ERROR: No ASVs.fa, run DADA2 analysis first"; exit 1; }

# 2. Convert & Import
biom convert \
    -i "${file_path}/results/ASVs_counts.tsv" \
    -o "${file_path}/results/ASVs_counts.biom" \
    --table-type="OTU table" \
    --to-hdf5 \
    || { echo "ERROR: BIOM conversion failed"; exit 1; }

qiime tools import \
    --input-path "${file_path}/results/ASVs.fa" \
    --output-path "${file_path}/results/rep-seqs.qza" \
    --type 'FeatureData[Sequence]' \
    || { echo "ERROR: rep-seqs import failed"; exit 1; }

qiime tools import \
    --input-path "${file_path}/results/ASVs_counts.biom" \
    --type 'FeatureTable[Frequency]' \
    --input-format BIOMV210Format \
    --output-path "${file_path}/results/table.qza" \
    || { echo "ERROR: feature table import failed"; exit 1; }

# 3. Closed-Reference Clustering
qiime vsearch cluster-features-closed-reference \
    --i-sequences "${file_path}/results/rep-seqs.qza" \
    --i-table "${file_path}/results/table.qza" \
    --i-reference-sequences "${reference}" \
    --p-perc-identity 0.99 \
    --p-threads 12 \
    --p-strand both \
    --o-clustered-table "${file_path}/results/clustered-table.qza" \
    --o-clustered-sequences "${file_path}/results/clustered-sequences.qza" \
    --o-unmatched-sequences "${file_path}/results/unmatched-sequences.qza" \
    || { echo "ERROR: closed-reference clustering failed"; exit 1; }

# 4. Export Clustered Table
qiime tools export \
    --input-path "${file_path}/results/clustered-table.qza" \
    --output-path "${file_path}/results/extracted-feature-table" \
    || { echo "ERROR: export failed"; exit 1; }

# 5. Wrap Up
echo "${study_id}: ALL SUCCESS"
ls -lh "${file_path}/results"/clustered-* "${file_path}/results/extracted-feature-table"/
echo "End: $(date), Exit: 0"
