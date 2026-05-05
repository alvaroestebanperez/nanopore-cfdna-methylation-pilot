# MinION-style cfDNA methylation workflow

This document describes a first bioinformatics pilot for nanopore cfDNA methylation data. It is designed for learning and reproducibility, not clinical interpretation.

## Goal

Given nanopore raw or basecalled data, produce:

- an aligned BAM with native 5mC/5hmC tags;
- sorted and indexed BAM files;
- basic alignment QC;
- a MAPQ-filtered BAM;
- a BAM with terminal methylation calls adjusted;
- a CpG methylation BED file from `modkit pileup`.

## Expected inputs

Full path from raw signal:

```text
data/pod5/*.pod5
data/ref/GRCh38.fa
```

Lighter path from an existing modified-base BAM:

```text
data/bam/input.bam
data/ref/GRCh38.fa
```

The BAM must contain modified-base tags (`MM` and `ML`) for methylation analysis.

Check modified-base tags:

```bash
samtools view data/bam/input.bam | head -1 | grep -o "MM:Z:[^[:space:]]*"
samtools view data/bam/input.bam | head -1 | grep -o "ML:B:C[^[:space:]]*"
```

If both commands return nothing, the BAM probably does not contain methylation calls.

## Folder layout

```bash
mkdir -p nanopore_lau_like_pilot/{data/pod5,data/bam,data/ref,results/qc,results/bam,results/modkit,logs,scripts}
cd nanopore_lau_like_pilot
```

Meaning:

```text
data/pod5/      raw nanopore signal files
data/bam/       existing BAMs if basecalling was already done
data/ref/       reference genome FASTA and indexes
results/qc/     summary reports
results/bam/    sorted, filtered, adjusted BAMs
results/modkit/ methylation tables
logs/           terminal logs and job output
scripts/        reusable shell scripts
```

## Reference preparation

```bash
samtools faidx data/ref/GRCh38.fa
cut -f1,2 data/ref/GRCh38.fa.fai | head
```

Human references may use `chr1` or `1`. Keep chromosome naming consistent across BAM, reference, BED, and any annotation files.

## Full path: POD5 to aligned modified-base BAM

```bash
find data/pod5 -name "*.pod5" | wc -l
du -sh data/pod5
```

Run Dorado with modified-base calling and alignment:

```bash
dorado basecaller hac data/pod5 \
  --modified-bases 5mCG_5hmCG \
  --reference data/ref/GRCh38.fa \
  --min-qscore 10 \
  2> logs/dorado_basecaller.log \
| samtools sort -@ 8 -o results/bam/basecalled.sorted.bam -

samtools index results/bam/basecalled.sorted.bam
samtools quickcheck -v results/bam/basecalled.sorted.bam
samtools flagstat results/bam/basecalled.sorted.bam > results/qc/basecalled.flagstat.txt
```

If `samtools quickcheck` prints nothing, the BAM passed the structural check.

## Lighter path: existing BAM to QC

```bash
samtools quickcheck -v data/bam/input.bam
samtools sort -@ 8 -o results/bam/input.sorted.bam data/bam/input.bam
samtools index results/bam/input.sorted.bam
samtools flagstat results/bam/input.sorted.bam > results/qc/input.flagstat.txt
```

Set:

```bash
BAM="results/bam/input.sorted.bam"
```

If starting from Dorado output:

```bash
BAM="results/bam/basecalled.sorted.bam"
```

## BAM inspection

```bash
samtools view -H "$BAM" | head
samtools view "$BAM" | head
samtools idxstats "$BAM" > results/qc/idxstats.tsv
samtools stats "$BAM" > results/qc/samtools.stats.txt
samtools view -c -F 4 "$BAM"
samtools view -c -f 4 "$BAM"
samtools view "$BAM" | awk '{print $5}' | sort -n | uniq -c | tail
```

## Filter poor alignments

MAPQ 10 is a practical first-pass filter.

```bash
samtools view -@ 8 -q 10 -bh \
  -o results/bam/mapq10.bam \
  "$BAM"

samtools index results/bam/mapq10.bam
samtools flagstat results/bam/mapq10.bam > results/qc/mapq10.flagstat.txt
```

Set:

```bash
BAM="results/bam/mapq10.bam"
```

## Adjust terminal methylation calls

Native cfDNA methylation calls can show read-end artefacts due to jagged-end repair. For a first pilot, keep the filtered BAM and create a second adjusted BAM.

```bash
modkit adjust-mods \
  --edge-filter 0 27 \
  results/bam/mapq10.bam \
  results/bam/mapq10.edge27.bam

samtools index results/bam/mapq10.edge27.bam
```

Set:

```bash
BAM="results/bam/mapq10.edge27.bam"
```

## Generate CpG methylation pileup

```bash
modkit pileup \
  --ref data/ref/GRCh38.fa \
  --threads 8 \
  "$BAM" \
  results/modkit/cpg_methylation.bed
```

Inspect:

```bash
head results/modkit/cpg_methylation.bed
wc -l results/modkit/cpg_methylation.bed
```

## Success criteria

The pilot is technically successful if:

- `samtools quickcheck` passes on BAM outputs;
- the MAPQ-filtered BAM still contains mapped reads;
- modified-base tags are present before `modkit`;
- `modkit pileup` produces a non-empty BED file;
- chromosome naming is consistent;
- every produced file can be explained in one sentence.

Do not claim biological success from this pilot alone.

## Lau 2023 to MinION adaptation

What carries over:

- native cfDNA methylation logic;
- PCR-free preference;
- read-level thinking;
- QC gates around read yield, alignment, fragment length, and methylation calls.

What changes:

- PromethION throughput becomes MinION pilot throughput;
- R9.4.1/Guppy/Megalodon becomes R10.4.1/Dorado/modkit;
- ONT's newer cfDNA methylation correction context should be considered;
- first-pass outputs are QC and CpG summaries, not a full tumour/immune classifier.

