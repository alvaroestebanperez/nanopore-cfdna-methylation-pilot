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

## Picasso cluster — working norms

This workflow is designed to run on the Picasso HPC cluster (`alvaroep@picasso3.scbi.uma.es`).
Follow these rules every session.

---

### 1. Always use tmux

Never work directly in the SSH session. If the connection drops, any running terminal process dies.

```bash
# First login of the project
tmux new -s nano

# Every subsequent login
tmux attach -t nano

# Check active sessions
tmux ls
```

Recommended layout: two panels side by side. Left panel for commands; right panel running `watch -n 10 squeue -u alvaroep` to monitor the job queue at all times.

Detach safely with `Ctrl+B, D`. The session keeps running after you disconnect.

---

### 2. Login node rules

The login node (`picasso3`) is a shared gateway — do not run compute-heavy tasks on it.

| Allowed on login node | Never on login node |
|-----------------------|---------------------|
| `sbatch`, `scancel`, `squeue` | `dorado basecaller` |
| `module load`, `module avail` | `samtools sort/view` on large files |
| `ls`, `less`, `grep`, `diff` | `modkit pileup` |
| `wget` downloads | any long-running loop over large data |
| `git` commands | |

All heavy computation must go through `sbatch` scripts.
Interactive exploration of small outputs (`less`, `head`, `tail -f`) is fine.

---

### 3. Two-filesystem rule

Picasso has two distinct storage areas with different quotas and purposes.

| Area | Path | Quota | Contents |
|------|------|-------|----------|
| Home | `~/projects/nanopore_pilot/` | 95 GB | scripts, logs, git repos |
| Scratch | `~/fscratch/nanopore_pilot/` | 0.93 TB | raw data, results, models |

`~/fscratch/` is a cluster symlink — always use this prefix, never the full path `/fscratch/alvaroep/`.
Check the scratch purge policy with SCBI before relying on long-term storage there.

Expected layout on the cluster:

```text
~/projects/nanopore_pilot/
├── scripts/        ← sbatch job scripts (version-controlled here)
└── logs/           ← Slurm .out / .err files and tool logs

~/fscratch/nanopore_pilot/
├── data/
│   ├── pod5/       ← raw POD5 files (read-only after download)
│   ├── bam/        ← input BAMs (pre-basecalled, if any)
│   └── ref/        ← reference genome + index
├── results/
│   ├── bam/        ← sorted, filtered, edge-adjusted BAMs
│   ├── qc/         ← flagstat, idxstats, samtools stats outputs
│   └── modkit/     ← CpG methylation BED files
└── dorado_models/  ← downloaded Dorado model directories
```

---

### 4. GPU partition — Dorado only

Dorado basecalling requires a GPU. All other tools (samtools, modkit) run on CPU nodes.

```bash
# In any sbatch script that runs Dorado:
#SBATCH --partition=gpu_partition
#SBATCH --gres=gpu:1
```

GPU nodes: `exa[01-04]`. Do not request GPU resources for samtools or modkit jobs — it wastes allocation.

---

### 5. Loading modules

```bash
module load dorado/0.8.1
```

Confirm available versions for other tools before writing sbatch scripts:

```bash
module avail 2>&1 | grep -i samtools
module avail 2>&1 | grep -i modkit
```

Do not hardcode module versions in scripts without first checking what is installed.

---

### 6. Downloading data

Use `wget -c` (resumable). Do not use `aws s3 cp --no-sign-request` — it has a known bug on this cluster.

```bash
# Correct
wget -c <url> -P ~/fscratch/nanopore_pilot/data/pod5/

# Wrong — do not use on Picasso
aws s3 cp --no-sign-request s3://... ~/fscratch/...
```

After every download, verify integrity and record the checksum:

```bash
md5sum ~/fscratch/nanopore_pilot/data/pod5/file.pod5
# record the hash in data/README.md alongside the source URL and download date
```

---

### 7. Job submission and monitoring

```bash
# Submit a job
sbatch ~/projects/nanopore_pilot/scripts/job_name.sh

# Check queue
squeue -u alvaroep

# Cancel a job
scancel <JOBID>

# Follow log live (in tmux right panel or second terminal)
tail -f ~/projects/nanopore_pilot/logs/<JOBID>.err
```

Slurm output files go to `~/projects/nanopore_pilot/logs/`. Add these directives to every sbatch script:

```bash
#SBATCH --output=logs/%j.out
#SBATCH --error=logs/%j.err
```

`%j` expands to the job ID automatically.

---

### 8. Raw data is read-only

Once POD5 files are downloaded, remove write permissions immediately:

```bash
chmod -R a-w ~/fscratch/nanopore_pilot/data/pod5/
```

Never modify raw signal files. If reprocessing is needed, re-run basecalling from the original POD5s.

---

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
