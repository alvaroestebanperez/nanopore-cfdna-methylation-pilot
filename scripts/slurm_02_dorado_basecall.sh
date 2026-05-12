#!/usr/bin/env bash

#SBATCH -J dorado_basecall
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32gb
#SBATCH --time=02:00:00
##SBATCH --constraint=cal
#SBATCH --constraint=dgx
#SBATCH --gres=gpu:1
#SBATCH --error=logs/dorado_basecall.%J.err
#SBATCH --output=logs/dorado_basecall.%J.out
#SBATCH --mail-user=alvaroesteban1101@gmail.com
#SBATCH --mail-type=END,FAIL
##SBATCH --array=1-100

# ---------------------------------------------------------------------------

export PATH="${HOME}/projects/dorado-1.4.0-linux-x64/bin:${PATH}"
export PATH="${HOME}/projects/samtools-1.23.1/bin:${PATH}"

set -euo pipefail

MODEL="${HOME}/fscratch/nanopore_pilot/dorado_models/dna_r10.4.1_e8.2_400bps_hac@v5.0.0_5mCG_5hmCG@v2"
POD5="${HOME}/fscratch/nanopore_pilot/data/pod5/5mC_rep1.pod5"
REF="${HOME}/fscratch/nanopore_pilot/data/ref/all_5mers.fa"
BAM_REF="${HOME}/fscratch/nanopore_pilot/data/bam/5mC_rep1.bam"
RESULTS="${HOME}/fscratch/nanopore_pilot/results"

mkdir -p "${RESULTS}/bam" "${RESULTS}/qc"

# ---------------------------------------------------------------------------
# Basecalling + alignment

echo "==> Dorado basecaller"
time dorado basecaller "${MODEL}" "${POD5}" \
  --reference "${REF}" \
  --min-qscore 10 \
  2> "logs/dorado.${SLURM_JOB_ID}.log" \
| samtools sort -@ "${SLURM_CPUS_PER_TASK}" \
  -o "${RESULTS}/bam/5mC_rep1.dorado.sorted.bam"

echo "==> Index + QC (Track A)"
samtools index "${RESULTS}/bam/5mC_rep1.dorado.sorted.bam"
samtools quickcheck -v "${RESULTS}/bam/5mC_rep1.dorado.sorted.bam"
samtools flagstat -@ "${SLURM_CPUS_PER_TASK}" \
  "${RESULTS}/bam/5mC_rep1.dorado.sorted.bam" \
  > "${RESULTS}/qc/5mC_rep1.dorado.flagstat.txt"

# ---------------------------------------------------------------------------
# Compare with pre-basecalled BAM (Track B)

echo "==> QC Track B (reference BAM)"
samtools flagstat -@ "${SLURM_CPUS_PER_TASK}" \
  "${BAM_REF}" \
  > "${RESULTS}/qc/5mC_rep1.original.flagstat.txt"

echo "==> Comparison"
echo "--- Track A (Dorado) ---"
cat "${RESULTS}/qc/5mC_rep1.dorado.flagstat.txt"
echo "--- Track B (ONT pre-basecalled) ---"
cat "${RESULTS}/qc/5mC_rep1.original.flagstat.txt"

echo "==> Done"
