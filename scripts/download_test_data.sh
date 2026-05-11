#!/usr/bin/env bash
set -euo pipefail

BASE="https://ont-open-data.s3.amazonaws.com/modbase-validation_2024.10"
DATA="${DATA:-${HOME}/fscratch/nanopore_pilot/data}"

mkdir -p "${DATA}/bam" "${DATA}/pod5" "${DATA}/ref"

echo "==> Track B: BAM"
wget -c "${BASE}/basecalls/5mC_rep1.bam" -P "${DATA}/bam/"

echo "==> Reference"
wget -c "${BASE}/references/all_5mers.fa" -P "${DATA}/ref/"

echo "==> Track A: POD5"
wget -c "${BASE}/subset/5mC_rep1.pod5" -P "${DATA}/pod5/"

echo "==> Done"
ls -lh "${DATA}/bam/" "${DATA}/ref/" "${DATA}/pod5/"
