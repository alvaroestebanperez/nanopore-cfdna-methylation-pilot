#!/usr/bin/env bash

#SBATCH -J samtools_filter
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8gb
#SBATCH --time=00:30:00
#SBATCH --constraint=cal
#SBATCH --error=logs/samtools_filter.%J.err
#SBATCH --output=logs/samtools_filter.%J.out
#SBATCH --mail-user=alvaroesteban1101@gmail.com
#SBATCH --mail-type=END,FAIL

# ---------------------------------------------------------------------------

set -euo pipefail

export PATH="${HOME}/projects/samtools-1.23.1/bin:${PATH}"

mkdir -p "${HOME}/fscratch/nanopore_pilot/results/bam" \
         "${HOME}/fscratch/nanopore_pilot/results/qc"

BAM_IN="${HOME}/fscratch/nanopore_pilot/data/bam/5mC_rep1.bam"
BAM_OUT="${HOME}/fscratch/nanopore_pilot/results/bam/5mC_rep1.filtered.bam"
QC="${HOME}/fscratch/nanopore_pilot/results/qc/5mC_rep1.filtered.flagstat.txt"

samtools view -@ "${SLURM_CPUS_PER_TASK}" -q 10 -bh -o "${BAM_OUT}" "${BAM_IN}"
samtools index "${BAM_OUT}"
samtools quickcheck -v "${BAM_OUT}"
samtools flagstat -@ "${SLURM_CPUS_PER_TASK}" \
  "${BAM_OUT}" \
  > "${QC}"
