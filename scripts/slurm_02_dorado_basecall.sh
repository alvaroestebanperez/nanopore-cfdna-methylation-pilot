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

set -euo pipefail

# ---------------------------------------------------------------------------
# Runtime environment
#
# Keep samtools inside the conda environment. Loading the cluster samtools
# module here can make the batch job pick an incompatible libncursesw.

module purge
module load miniconda/3_py10

eval "$(conda shell.bash hook)"
conda activate nanopore

export PATH="${CONDA_PREFIX}/bin:${HOME}/projects/dorado-1.4.0-linux-x64/bin:${PATH}"
export LD_LIBRARY_PATH="${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH:-}"

echo "==> Runtime environment"
echo "HOSTNAME=${HOSTNAME:-unknown}"
echo "CONDA_PREFIX=${CONDA_PREFIX}"
echo "samtools=$(command -v samtools)"
samtools --version
ldd "$(command -v samtools)" | grep ncurses || true
echo "dorado=$(command -v dorado)"
dorado --version

# ---------------------------------------------------------------------------

MODEL_ROOT="${HOME}/fscratch/nanopore_pilot/dorado_models"
MODEL="hac@v5.0.0,5mCG_5hmCG@v2"
POD5="${HOME}/fscratch/nanopore_pilot/data/pod5/5mC_rep1.pod5"
REF="${HOME}/fscratch/nanopore_pilot/data/ref/all_5mers.fa"
BAM_REF="${HOME}/fscratch/nanopore_pilot/data/bam/5mC_rep1.bam"
RESULTS="${HOME}/fscratch/nanopore_pilot/results"
UNSORTED_BAM="${RESULTS}/bam/5mC_rep1.dorado.unsorted.bam"
SORTED_BAM="${RESULTS}/bam/5mC_rep1.dorado.sorted.bam"

mkdir -p "${RESULTS}/bam" "${RESULTS}/qc"

if [[ ! -d "${MODEL_ROOT}" ]]; then
  echo "ERROR: model directory not found: ${MODEL_ROOT}" >&2
  exit 1
fi

if ! find "${MODEL_ROOT}" -maxdepth 1 -mindepth 1 -type d -name '*hac@v5.0.0*' | grep -q .; then
  echo "ERROR: HAC v5.0.0 model not found in ${MODEL_ROOT}" >&2
  echo "Available model directories in ${MODEL_ROOT}:" >&2
  find "${MODEL_ROOT}" -maxdepth 1 -mindepth 1 -type d -printf '  %f\n' >&2
  echo "Download the required model complex before submitting this job:" >&2
  echo "  dorado download --model ${MODEL} --models-directory ${MODEL_ROOT}" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Basecalling + alignment

echo "==> Dorado basecaller"
time dorado basecaller "${MODEL}" "${POD5}" \
  --models-directory "${MODEL_ROOT}" \
  --reference "${REF}" \
  --min-qscore 10 \
  > "${UNSORTED_BAM}" \
  2> "logs/dorado.${SLURM_JOB_ID}.log"

samtools quickcheck -v "${UNSORTED_BAM}"

echo "==> Sort BAM"
samtools sort -@ "${SLURM_CPUS_PER_TASK}" \
  -o "${SORTED_BAM}" \
  "${UNSORTED_BAM}"

echo "==> Index + QC (Track A)"
samtools index "${SORTED_BAM}"
samtools quickcheck -v "${SORTED_BAM}"
samtools flagstat -@ "${SLURM_CPUS_PER_TASK}" \
  "${SORTED_BAM}" \
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
