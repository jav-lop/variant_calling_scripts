#!/bin/bash
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=lopezj3@ccf.org
#SBATCH --job-name=Mutect2
#SBATCH -n 4
#SBATCH --mem 20000
#SBATCH -o mutect2_PON_%A-%a.o%j
#SBATCH --array=1-28
		
gatk_filepath="/cm/shared/apps/GenomeAnalysisTk/4.1.9.0/gatk"
sample=$(cat PON_samples.txt | sed -n ${SLURM_ARRAY_TASK_ID}p)
result_loc=`pwd`
file=`echo ~/beegfs/Nov_panels/hg19_aligned_bams/${sample}.hg19.aligned.duplicates_marked.recalibrated.bam`	

${gatk_filepath} Mutect2 \
      -L ~/beegfs/references/b37/Gene_panel_intervals.chr.bed \
      -R ~/beegfs/references/b37/hg19.fa \
      -I ${file} \
      --max-mnp-distance 0 \
      -O ${result_loc}/${sample}.b37.M2.vcf.gz 