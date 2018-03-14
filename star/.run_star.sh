#!/bin/bash
# run_star2.sh
# Default settingdat
tmp=~/.`shuf -i 1-1000 -n 1`
cat <<EOF | ~/src/arg_parser.sh > $tmp
#Align fastq files using STAR (2-pass protocol), mark duplicates,
#Split'N'Trim, and base quality recalibration. Run on Torque/PBS system.
#
# Usage: $0 \ 
#	<--sample_name 'text'> <in1.fa.gz> [in2.fa.gz] \ 
#	[--outdir 'path'] [options]
#
-s|--sample_name	sample_name	''	Output prefix
-o|--outdir		outdir		./
--star_index		star_index	~kjyi/ref/star_index
--reference		reference	~kjyi/ref/hg19.fa
--rsem_ref		rsem_ref	~kjyi/ref/rsem_reference
--sjdbGTFfile		sjdbGTFfile	''	Annotation in GTF format
-t|--thread		THREAD		6
--log			log		./log
--memory		MEMORY		8G
--mail_address		mail_address	''
--star			star		~kjyi/tools/STAR/STAR-2.5.4b/bin/Linux_x86_64/STAR
--picard		picard		~kjyi/tools/picard/2.15.0/picard.jar
--gatk			gatk		~kjyi/tools/GATK/3.8.0/GenomeAnalysisTK.jar
--samtools		samtools	~kjyi/tools/samtools/samtools-1.5/bin/samtools
--platform		platform	'ILLUMINA'
--library		library		''
--outFilterMultimapNmax		outFilterMultimapNmax		20
--alignSJoverhangMin		alignSJoverhangMin		8
--alignSJDBoverhangMin		alignSJDBoverhangMin		1
--outFilterMismatchNmax		outFilterMismatchNmax		999
--outFilterMismatchNoverLmax	outFilterMismatchNoverLmax	'0.1'
--alignIntronMin		alignIntronMin			'20'
--alignIntronMax		alignIntronMax			'1000000'
--alignMatesGapMax		alignMatesGapMax		'1000000'
--outFilterType			outFilterType			'BySJout'
--outFilterScoreMinOverLread	outFilterScoreMinOverLread	'0.33'
--outFilterMatchNminOverLread	outFilterMatchNminOverLread	'0.33'
--limitSjdbInsertNsj		limitSjdbInsertNsj		'1200000'
--outSAMstrandField		outSAMstrandField		'intronMotif'
--outFilterIntronMotifs		outFilterIntronMotifs		''	Use 'RemoveNoncanonical' for Cufflinks compatibility
--alignSoftClipAtReferenceEnds	alignSoftClipAtReferenceEnds	'Yes'
--quantMode			quantMode			'TranscriptomeSAM GeneCounts'
--outSAMtype			outSAMtype			'BAM Unsorted'
--outSAMunmapped		outSAMunmapped			'Within'	Keep unmapped reads in output BAM
--outSAMattributes		outSAMattributes		'NH HI AS nM NM ch'
--chimSegmentMin		chimSegmentMin			'15'	Minimum fusion segment length
--chimJunctionOverhangMin	chimJunctionOverhangMin		'15'	Minimum overhang for a chimeric junction
--chimOutType			chimOutType			'WithinBAM SoftClip'
--chimMainSegmentMultNmax	chimMainSegmentMultNmax		'1'
--genomeLoad			genomeLoad			'NoSharedMemory'
--sjdbFileChrStartEnd		sjdbFileChrStartEnd		''	Input file as chr<tab>star<tab>end<tab>strand splice jx
EOF
. $tmp && rm $tmp

FASTQ=(); for i in "${!ARGS[@]}"; do FASTQ+=(${ARGS[i]}); done
FASTQ1=${FASTQ[0]}
FASTQ2=${FASTQ[1]}
EMAIL_SCRIPT=`echo $EMAIL|sed 's/./-m abe -M &/'`

# run pipeline
arguments="FASTQ1,FASTQ2,$arguments"
SCRIPT=`dirname $0`
runSTAR=$(qsub -q long -l nodes=1:ppn=$THREAD -N star_$SAMPLE $EMAIL_SCRIPT $SCRIPT/star.qsh -v $arguments)
runRSEM=$(qsub -q long -l nodes=1:ppn=$THREAD -N rsem_$SAMPLE $EMAIL_SCRIPT $SCRIPT/rsem.qsh -v $arguments -W afterok=$runSTAR)
runRNASEQC=$(qsub -V -q long -l nodes=1:ppn=$THREAD -N rnaseqc_$SAMPLE $EMAIL_SCRIPT $SCRIPT/rnqseqc.qsh -v $arguments -W afterok=$runRNASEQC)
