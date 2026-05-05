# Nanopore cfDNA methylation pilot

Learning-oriented workflow for a MinION-style cfDNA methylation bioinformatics pilot.

The goal is to process nanopore raw or basecalled data into aligned BAM files with native methylation calls and CpG methylation summaries using current Oxford Nanopore tooling.

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
- Optional: SLURM for cluster execution

## Status

Early pilot. This repository is for workflow learning and reproducibility, not clinical interpretation.

## Data policy

No patient data, raw clinical sequencing files, or internal collaborator data should be committed to this repository. Examples should use synthetic data or public datasets with clear reuse permission.

## Scientific context

This workflow is inspired by native nanopore cfDNA methylation approaches such as Lau et al. 2023, adapted as a small MinION-style bioinformatics pilot using current Dorado/modkit tooling.
