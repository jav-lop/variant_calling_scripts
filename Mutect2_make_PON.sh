#!/bin/bash
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=lopezj3@ccf.org
#SBATCH --job-name=pon
#SBATCH -n 4
#SBATCH --mem 20000
#SBATCH -o pon.o%j

module load bcftools
module load htslib
module load GenomeAnalysisTk

bcftools merge \
	-m none \
	-l PoN_filenames.txt \
	-Oz \
	-o gene_panel.autopsy_normals.hg19.M2.vcf.gz \
	--threads 4

tabix gene_panel.autopsy_normals.hg19.M2.vcf.gz

gatk CreateSomaticPanelOfNormals \
        -L ~/beegfs/references/b37/Gene_panel_intervals.chr.bed \
        -R ~/beegfs/references/b37/hg19.fa \
	-V gene_panel.autopsy_normals.hg19.M2.vcf.gz \
	-O gene_panel.autopsy_PON.vcf.gz