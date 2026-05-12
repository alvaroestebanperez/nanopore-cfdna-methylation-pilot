#!/usr/bin/env bash

#SBATCH -J download
#SBATCH --ntasks=1
##SBATCH --cpus-per-task=1
#SBATCH --mem=2gb
#SBATCH --time=00:30:00
#SBATCH --constraint=cal
##SBATCH --constraint=dgx
##SBATCH --gres=gpu:1
#SBATCH --error=logs/download.%J.err
#SBATCH --output=logs/download.%J.out
#SBATCH --mail-user=alvaroesteban1101@gmail.com
#SBATCH --mail-type=END,FAIL
##SBATCH --array=1-100

# ---------------------------------------------------------------------------

set -euo pipefail

BASE_URL="https://ont-open-data.s3.amazonaws.com/modbase-validation_2024.10"
DATA="${DATA:-${HOME}/fscratch/nanopore_pilot/data}"

mkdir -p "${DATA}/pod5" "${DATA}/bam" "${DATA}/ref"

echo "==> Track A: POD5"
time wget -c "${BASE_URL}/subset/5mC_rep1.pod5" -P "${DATA}/pod5/"

echo "==> Track B: BAM"
time wget -c "${BASE_URL}/basecalls/5mC_rep1.bam" -P "${DATA}/bam/"

echo "==> Reference"
time wget -c "${BASE_URL}/references/all_5mers.fa" -P "${DATA}/ref/"

echo "==> Checksums"
md5sum "${DATA}/pod5/5mC_rep1.pod5" > "${DATA}/pod5/checksums.md5"
md5sum "${DATA}/bam/5mC_rep1.bam"   > "${DATA}/bam/checksums.md5"
md5sum "${DATA}/ref/all_5mers.fa"   > "${DATA}/ref/checksums.md5"

echo "==> Making POD5 read-only"
chmod -R a-w "${DATA}/pod5/"

echo "==> Done"
ls -lh "${DATA}/pod5/" "${DATA}/bam/" "${DATA}/ref/"
