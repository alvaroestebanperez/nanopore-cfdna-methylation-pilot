#!/usr/bin/env bash

#SBATCH -J dorado_basecall
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32gb
#SBATCH --time=02:00:00
#SBATCH --constraint=dgx
#SBATCH --gres=gpu:1
#SBATCH --error=logs/dorado_basecall.%J.err
#SBATCH --output=logs/dorado_basecall.%J.out
#SBATCH --mail-user=alvaroesteban1101@gmail.com
#SBATCH --mail-type=END,FAIL
##SBATCH --array=1-100

# ---------------------------------------------------------------------------
module load dorado/0.8.1
module load samtools/1.17 # Confirm that samtools is available for indexing the BAM file after basecalling
MODEL="${HOME}/fscratch/nanopore_pilot/dorado_models/dna_r10.4.1_e8.2_400bps_hac@v5.0.0_5mCG_5hmCG@v2"
# Confirm that the model file exists at the specified path. Adjust if necessary.

dorado basecall --model "${MODEL}" \
    --input "${DATA}/pod5/5mC_rep1.pod5" \
    --output "${DATA}/bam/5mC_rep1.dorado.bam" \
    --modified-bases 5mC_5hmCG \
    --reference "${DATA}/ref" \
    2> logs/dorado_basecall.%J.log \
    | samtools sort -@ "$SLURM_CPUS_PER_TASK" -o "${RESULTS}/bam/5mC_rep1.dorado.sorted.bam"

    samtools flagstat "${RESULTS}/bam/5mC_rep1.dorado.sorted.bam" > "${RESULTS}/bam/5mC_rep1.dorado.flagstat.txt"
    samtools flagstat "${DATA}/bam/5mC_rep1.bam" > "${RESULTS}/bam/5mC_rep1.original.flagstat.txt"