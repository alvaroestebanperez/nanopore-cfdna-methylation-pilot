# Nanopore cfDNA methylation pilot

Learning-oriented workflow for a MinION-style cfDNA methylation bioinformatics pilot.

The goal is to process nanopore raw or basecalled data into aligned BAM files with native methylation calls and CpG methylation summaries using current Oxford Nanopore tooling.

This repository is designed as a first reproducible bridge between wet-lab liquid biopsy questions and command-line nanopore bioinformatics. It is not a clinical pipeline.

## Workflow

```text
POD5 -> Dorado basecalling + 5mC/5hmC calling -> aligned BAM
     -> samtools QC/filtering
     -> modkit read-end adjustment
     -> modkit pileup
     -> CpG methylation BED
```

## Tools

- Dorado
- samtools
- modkit
- Bash
- Conda or mamba for environment management
- Optional: SLURM for cluster execution

## Repository structure

```text
.
├── README.md
├── docs/
│   ├── workflow.md
│   └── data-policy.md
├── envs/
│   └── nanopore.yml
├── examples/
│   └── README.md
└── scripts/
    ├── qc_bam.sh
    └── run_minion_methylation_pilot.sh
```

## Quick start

Create the environment:

```bash
conda env create -f envs/nanopore.yml
conda activate nanopore-cfdna
```

Check the core tools:

```bash
dorado --version
samtools --version
modkit --version
```

Run the full POD5-to-CpG workflow:

```bash
THREADS=8 \
REF=data/ref/GRCh38.fa \
POD5_DIR=data/pod5 \
OUT=results \
./scripts/run_minion_methylation_pilot.sh
```

Run BAM QC only:

```bash
THREADS=8 \
BAM=results/bam/mapq10.edge27.bam \
OUT=results/qc \
./scripts/qc_bam.sh
```

## Status

Early pilot. This repository is for workflow learning and reproducibility, not clinical interpretation.

## Data policy

No patient data, raw clinical sequencing files, or internal collaborator data should be committed to this repository. Examples should use synthetic data or public datasets with clear reuse permission.

See [docs/data-policy.md](docs/data-policy.md).

## Scientific context

This workflow is inspired by native nanopore cfDNA methylation approaches such as Lau et al. 2023, adapted as a small MinION-style bioinformatics pilot using current Dorado/modkit tooling.

Key idea: before attempting biological interpretation, first prove that the technical path works:

- the input data are valid;
- the reference genome is indexed;
- the BAM is sorted and indexed;
- mapped reads remain after MAPQ filtering;
- modified-base tags are present;
- read-end methylation calls can be adjusted;
- `modkit pileup` produces a non-empty CpG methylation table.
