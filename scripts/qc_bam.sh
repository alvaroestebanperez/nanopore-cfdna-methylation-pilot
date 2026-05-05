#!/usr/bin/env bash
set -euo pipefail

THREADS="${THREADS:-8}"
BAM="${BAM:?Set BAM to the input BAM path}"
OUT="${OUT:-results/qc}"

mkdir -p "${OUT}"

samtools quickcheck -v "${BAM}"
samtools flagstat -@ "${THREADS}" "${BAM}" > "${OUT}/flagstat.txt"
samtools idxstats "${BAM}" > "${OUT}/idxstats.tsv"
samtools stats -@ "${THREADS}" "${BAM}" > "${OUT}/samtools.stats.txt"

samtools view -c -F 4 "${BAM}" > "${OUT}/mapped_read_count.txt"
samtools view -c -f 4 "${BAM}" > "${OUT}/unmapped_read_count.txt"

samtools view "${BAM}" \
  | awk '{print $5}' \
  | sort -n \
  | uniq -c \
  > "${OUT}/mapq_distribution.txt"

echo "QC complete: ${OUT}"

