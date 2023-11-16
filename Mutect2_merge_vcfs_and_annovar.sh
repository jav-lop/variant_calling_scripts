#!/bin/bash
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=lopezj3@ccf.org
#SBATCH --job-name=M2_merge_annovar
#SBATCH -n 4
#SBATCH --mem 30000
#SBATCH -o M2_merge_annovar.o%j

module load bcftools/current
module load annovar/2019Oct24
#module load GenomeAnalysisTk/current

#vcf file list input file
declare vcf_list="vcf_filenames.txt"

#Define outputfolder for annovar input file
declare ANNOVARdir="/mnt/beegfs/lopezj3/data_new/Mutect2/annovar"
mkdir -p $ANNOVARdir

# Define input vcf file PATH for selection
declare VCFdir="/mnt/beegfs/lopezj3/data_new/Mutect2"

# Define input vcf file NAME without the .vcf ending
declare VCFname="Nov11.gene_panels.duplicates_marked.somatic.M2.24_pon.pass_only"

declare annovardb="/mnt/beegfs/lopezj3/references/humandb"

MERGE()
{
#only variants which PASS FilterMutectCalls are kept
bcftools merge \
	-m none \
	-f PASS \
	-l ${vcf_list} \
	-o ${VCFdir}/${VCFname}.vcf \
	--threads 4
}

CONVERT()
{
convert2annovar.pl -format vcf4 ${VCFdir}/${VCFname}.vcf -outfile ${VCFdir}/${VCFname}.avinput -allsample -withfreq -include
grep -m 1 -e "INFO[[:blank:]]FORMAT" ${VCFdir}/${VCFname}.vcf | cut -f 10- > ${VCFdir}/HEAD2
printf CHR_anno'\t'START'\t'STOP'\t'A1_anno'\t'A2_anno'\t'MAF'\t'QUAL'\t'zero'\t'CHR_vcf'\t'POS_vcf'\t'dbSNPid'\t'A1_anno'\t'A2_anno'\t'QUAL'\t'FILTER'\t'zero'\t'FORMAT'\n' > ${VCFdir}/HEAD1
paste ${VCFdir}/HEAD1 ${VCFdir}/HEAD2 > ${VCFdir}/${VCFname}.avinput.HEADER
#rm ${VCFdir}/HEAD1
#rm ${VCFdir}/HEAD2
cat ${VCFdir}/${VCFname}.avinput.HEADER ${VCFdir}/${VCFname}.avinput | cut -f 7,8,11,16 --complement > $ANNOVARdir/${VCFname}.txt

# clean unneeded files
#rm ${VCFdir}/${VCFname}*
}

ANNOTATE()
{
table_annovar.pl $ANNOVARdir/${VCFname}.txt ${annovardb} -buildver hg19 -out $ANNOVARdir/${VCFname} -remove -otherinfo -protocol refGene,MPC_CL2019,ExACv2-MTR_CL2019,gnomad211_exome,gnomad211_genome,topMed,kaviar_20150923,hrcr1,DiscovEHR_GHS_Freeze_50_minAF0.001,UK10K-3781WGS_20160215_freq,GoNL-498WGS_r5_freq,2KJPN-2049WGS_tommo_20170126_hc_v1_freq,abraom,gme,cg69,avsnp150,cadd13,dbnsfp35c,revel,dbnsfp31a_interpro,dbscsnv11,clinvar_20200316,intervar_20180118 -operation g,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f -nastring NA
}

MERGE
CONVERT
ANNOTATE
