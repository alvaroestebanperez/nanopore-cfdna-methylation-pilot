#!/usr/bin/env bash
set -euo pipefail

THREADS="${THREADS:-8}"
REF="${REF:-data/ref/GRCh38.fa}"
POD5_DIR="${POD5_DIR:-data/pod5}"
OUT="${OUT:-results}"

mkdir -p "${OUT}/bam" "${OUT}/qc" "${OUT}/modkit" logs

if [[ ! -f "${REF}" ]]; then
  echo "Reference FASTA not found: ${REF}" >&2
  exit 1
fi

if [[ ! -d "${POD5_DIR}" ]]; then
  echo "POD5 directory not found: ${POD5_DIR}" >&2
  exit 1
fi

if [[ ! -f "${REF}.fai" ]]; then
  samtools faidx "${REF}"
fi

dorado basecaller hac "${POD5_DIR}" \
  --modified-bases 5mCG_5hmCG \
  --reference "${REF}" \
  --min-qscore 10 \
  2> logs/dorado_basecaller.log \
| samtools sort -@ "${THREADS}" -o "${OUT}/bam/basecalled.sorted.bam" -

samtools index "${OUT}/bam/basecalled.sorted.bam"
samtools quickcheck -v "${OUT}/bam/basecalled.sorted.bam"
samtools flagstat -@ "${THREADS}" "${OUT}/bam/basecalled.sorted.bam" > "${OUT}/qc/basecalled.flagstat.txt"

samtools view -@ "${THREADS}" -q 10 -bh \
  -o "${OUT}/bam/mapq10.bam" \
  "${OUT}/bam/basecalled.sorted.bam"

samtools index "${OUT}/bam/mapq10.bam"
samtools flagstat -@ "${THREADS}" "${OUT}/bam/mapq10.bam" > "${OUT}/qc/mapq10.flagstat.txt"

modkit adjust-mods \
  --edge-filter 0 27 \
  "${OUT}/bam/mapq10.bam" \
  "${OUT}/bam/mapq10.edge27.bam"

samtools index "${OUT}/bam/mapq10.edge27.bam"

modkit pileup \
  --ref "${REF}" \
  --threads "${THREADS}" \
  "${OUT}/bam/mapq10.edge27.bam" \
  "${OUT}/modkit/cpg_methylation.bed"

echo "Workflow complete: ${OUT}"

