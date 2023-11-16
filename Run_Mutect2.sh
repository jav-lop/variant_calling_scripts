#!/bin/bash
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=lopezj3@ccf.org
#SBATCH --job-name=M2_PoN
#SBATCH -n 4
#SBATCH --mem 20000
#SBATCH -N 1
#SBATCH -o m2_PoN_%A-%a.o%j
#SBATCH --array=1-95
		
module load GenomeAnalysisTk/4.1.9.0
module load samtools

####################################
### Define variables / filepaths ###
####################################

#Input list with all the bam filepaths to run the array over
input_filelist="bam_files.txt"

file=$(cat ${input_filelist} | sed -n ${SLURM_ARRAY_TASK_ID}p)

#basename for output file naming
bn=`echo $file | sed s/.b37.aligned.duplicates_marked.recalibrated.bam// | sed 's=.*bams/=='`	

#filepaths for needed files
gatk_filepath="/cm/shared/apps/GenomeAnalysisTk/4.1.9.0/gatk"
reference="/mnt/beegfs/lopezj3/references/b37/human_g1k_v37.fasta"
intervals="/mnt/beegfs/lopezj3/references/b37/Gene_panel_intervals.bed"
panel_of_normals="24_samples.pon.vcf.gz"
biallelic_gnomad_exomes="/mnt/beegfs/lopezj3/references/gnomad/biallelic.gnomad.exomes.sites.vcf.gz"

#filepath for where to put results
result_loc=`echo $(pwd)/`

 ### Call Initial variants

CALL_VARIANTS()
{
    ${gatk_filepath} Mutect2 \
      -L ${intervals} \
      -R ${reference} \
      -I ${file} \
      -O ${result_loc}${bn}.b37.M2.vcf.gz \
      -germline-resource ${biallelic_gnomad_exomes} \
      --panel-of-normals ${panel_of_normals} \
      --f1r2-tar-gz ${result_loc}${bn}.f1r2.tar.gz
}


 ### Generate additional files necessary for FilterMutectCalls

M2_SUPPLEMENTARY_FILES()
{
    ${gatk_filepath} LearnReadOrientationModel \
      -I ${result_loc}${bn}.f1r2.tar.gz \
      -O ${result_loc}${bn}.read-orientation-model.tar.gz

    ${gatk_filepath} GetPileupSummaries \
      -I ${file} \
      -V ${biallelic_gnomad_exomes} \
      -L ${biallelic_gnomad_exomes} \
      -O ${result_loc}${bn}.getpileupsummaries.table

    ${gatk_filepath} CalculateContamination \
      -I ${result_loc}${bn}.getpileupsummaries.table \
      -O ${result_loc}${bn}.calculatecontamination.table
}

 ### Filter initial variants using FilterMutectCalls

FILTER_M2()
{
    ${gatk_filepath} FilterMutectCalls \
      -R ${reference} \
      -V ${result_loc}${bn}.b37.M2.vcf.gz \
      --contamination-table ${result_loc}${bn}.calculatecontamination.table \
      --ob-priors ${result_loc}${bn}.read-orientation-model.tar.gz \
      -O ${result_loc}${bn}.b37.M2.filtered.vcf.gz
}

CALL_VARIANTS
M2_SUPPLEMENTARY_FILES
FILTER_M2