#!/bin/bash
# ~/src/star/run_star.sh
tmp=~/.`shuf -i 1-1000 -n 1`
cat <<EOF | ~kjyi/src/arg_parser.sh > $tmp
#Align fastq files using STAR (2-pass protocol), mark duplicates,
#Split'N'Trim, and base quality recalibration. Run on Torque/PBS system.
#
# Usage: $0 \ 
#	<--sample_name 'text'> <in1.fa.gz> [in2.fa.gz] \  
#	[options]
#
-s|--sample_name	sample_name		''	Output prefix
--outdir_star		outdir_star		./star
--outdir_rsem		outdir_rsem		./rsem
--reference		reference		hg19	[hg19|hg38|mm10|any_path_to_fasta_file] hg19,hg38,mm10 > will change star_index, rsem_reference, sjdbGTFfile setting
--star_index		star_index		~kjyi/ref/hg19/star_index
--rsem_ref		rsem_ref		~kjyi/ref/hg19/rsem_reference
--sjdbGTFfile		sjdbGTFfile		~kjyi/ref/gencode.v27lift37.gtf	Annotation in GTF format
--rsem_max_frag_len	rsem_max_frag_len	1000
--rsem_estimate_rspd	rsem_estimate_rspd	true
--is_stranded		is_stranded		false	
-t|--thread		THREAD			4
--log			log			./log
--memory		MEMORY		8G	memory usage in picard, gatk, and rnaseqc 8G
--memory_star		memory_star		31gb	memory usage in star 31gb
-m|--mail_address		mail_address		''	
--star			star		~kjyi/tools/STAR/STAR-2.5.4b/bin/Linux_x86_64/STAR
--picard		picard		~kjyi/tools/picard/2.15.0/picard.jar
--gatk			gatk		~kjyi/tools/GATK/3.8.0/GenomeAnalysisTK.jar
--samtools		samtools	~kjyi/tools/samtools/samtools-1.5/bin/samtools
--java			java		/usr/java/jre1.7.0_80/bin/java	java for rnaseqc, 1.7
--rnaseqc		rnaseqc		~kjyi/tools/RNA-SeQC/1.1.9/RNA-SeQC.jar
--platform		platform	'ILLUMINA'
--library		library		''
--outFilterMultimapNmax		outFilterMultimapNmax		'20'
--alignSJoverhangMin		alignSJoverhangMin		'8'
--alignSJDBoverhangMin		alignSJDBoverhangMin		'1'
--outFilterMismatchNmax		outFilterMismatchNmax		'999'
--outFilterMismatchNoverLmax	outFilterMismatchNoverLmax	'0.1'
--alignIntronMin		alignIntronMin			'20'
--alignIntronMax		alignIntronMax			'1000000'
--alignMatesGapMax		alignMatesGapMax		'1000000'
--outFilterType			outFilterType			'BySJout'
--outFilterScoreMinOverLread	outFilterScoreMinOverLread	'0.33'
--outFilterMatchNminOverLread	outFilterMatchNminOverLread	'0.33'
--limitSjdbInsertNsj		limitSjdbInsertNsj		'1200000'
--outSAMstrandField		outSAMstrandField		'intronMotif'
--outFilterIntronMotifs		outFilterIntronMotifs		'None'	Use 'RemoveNoncanonical' for Cufflinks compatibility
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
--gatk_flags			gatk_flags	allow_potentially_misencoded_quality_scores	Optional flags for GATK	
--script_out			script_out			''	if specified, dont run, but just make script
--process			process			'all'	all|star|rsem|rnaseqc|star,rsem|rsem,rnaseqc

EOF
. $tmp && rm $tmp
FASTQ=(); for i in "${!ARGS[@]}"; do FASTQ+=(${ARGS[i]}); done
export FASTQ1=${FASTQ[0]}
export FASTQ2=${FASTQ[1]}
EMAIL_SCRIPT=`echo $mail_address|sed 's/./-m abe -M &/'`

case $reference in
	hg19)
	       	reference=~kjyi/ref/hg19.fa 
		star_index=~kjyi/ref/hg19/star_index
		rsem_ref=~kjyi/ref/hg19/rsem_reference
		sjdbGTFfile=~/kjyi/ref/gencode.v27lift37.gtf
		;;
	hg38)
	       	reference=~kjyi/ref/hg38.fa 
		star_index=~kjyi/ref/hg38/star_index
		rsem_ref=~kjyi/ref/rsem_reference
		sjdbGTFfile=~/kjyi/ref/gencode.v27.gtf
		;;
	mm10) 
		reference=~kjyi/ref/mm10.fa 
		star_index=~kjyi/ref/mm10/star_index
		rsem_ref=~kjyi/ref/mm10/rsem_reference
		sjdbGTFfile=~kjyi/ref/gencode.vM16.gtf
		;;
esac
export reference star_index rsem_ref sjdbGTFfile

# run pipeline
arguments="FASTQ1,FASTQ2,$arguments"
SCRIPT=~kjyi/src/star
if [ "x$script_out" == "x" ]; then
	case $process in
		all)
			runSTAR=$(qsub -q day -l nodes=1:ppn=$THREAD -l mem=$memory_star -N STAR_${sample_name:0:11} $EMAIL_SCRIPT -v $arguments $SCRIPT/star.sh)
			runRSEM=$(qsub -q day -l nodes=1:ppn=$THREAD -l mem=$MEMORY -N RSEM_${sample_name:0:11} $EMAIL_SCRIPT -v $arguments -W depend=afterok:$runSTAR $SCRIPT/rsem.sh)
			runRNASEQC=$(qsub -V -q day -l nodes=1:ppn=$THREAD -l mem=$MEMORY -N RNASeQC_${sample_name:0:8} $EMAIL_SCRIPT $SCRIPT/rnaseqc.sh -v $arguments -W depend=afterok:$runRSEM)
echo STAR 	$sample_name	$runSTAR
echo RSEM 	$sample_name	$runRSEM
echo RNA-SeQC 	$sample_name	$runRNASEQC
			;;
		star)
			runSTAR=$(qsub -q day -l nodes=1:ppn=$THREAD -l mem=$memory_star -N STAR_${sample_name:0:11} $EMAIL_SCRIPT -v $arguments $SCRIPT/star.sh)
echo STAR 	$sample_name	$runSTAR
			;;
		rsem)
			runRSEM=$(qsub -q day -l nodes=1:ppn=$THREAD -l mem=$MEMORY -N RSEM_${sample_name:0:11} $EMAIL_SCRIPT -v $arguments $SCRIPT/rsem.sh)
echo RSEM 	$sample_name	$runRSEM
			;;
		rnaseqc)
			runRNASEQC=$(qsub -V -q day -l nodes=1:ppn=$THREAD -l mem=$MEMORY -N RNASeQC_${sample_name:0:8} $EMAIL_SCRIPT $SCRIPT/rnaseqc.sh -v $arguments)
echo RNA-SeQC 	$sample_name	$runRNASEQC
			;;
		rsem,rnaseqc)
			runRSEM=$(qsub -q day -l nodes=1:ppn=$THREAD -l mem=$MEMORY -N RSEM_${sample_name:0:11} $EMAIL_SCRIPT -v $arguments $SCRIPT/rsem.sh)
			runRNASEQC=$(qsub -V -q day -l nodes=1:ppn=$THREAD -l mem=$MEMORY -N RNASeQC_${sample_name:0:8} $EMAIL_SCRIPT $SCRIPT/rnaseqc.sh -v $arguments -W depend=afterok:$runRSEM)
echo RSEM 	$sample_name	$runRSEM
echo RNA-SeQC 	$sample_name	$runRNASEQC
			;;
		star,rsem)
			runSTAR=$(qsub -q day -l nodes=1:ppn=$THREAD -l mem=$memory_star -N STAR_${sample_name:0:11} $EMAIL_SCRIPT -v $arguments $SCRIPT/star.sh)
			runRSEM=$(qsub -q day -l nodes=1:ppn=$THREAD -l mem=$MEMORY -N RSEM_${sample_name:0:11} $EMAIL_SCRIPT -v $arguments -W depend=afterok:$runSTAR $SCRIPT/rsem.sh)
echo STAR 	$sample_name	$runSTAR
echo RSEM 	$sample_name	$runRSEM
			;;
	esac
else
	echo "#!/bin/bash
# ENV" > $script_out
	args=`echo $arguments | sed 's/,/ /g'`
	for i in $args;do
		echo $i=\"`printenv $i`\" >> $script_out
	done	
	cat <<EOF >> $script_out
# STAR
`cat $SCRIPT/star.sh | grep -v "#PBS" | grep -v "#!/bin/bash" | grep -v 'cd $PBS_O_WORKDIR'`

# RSEM
`cat $SCRIPT/rsem.sh | grep -v "#PBS" | grep -v "#!/bin/bash" | grep -v 'cd $PBS_O_WORKDIR'`

# RNA-SeQC
`cat $SCRIPT/rnaseqc.sh | grep -v "#PBS" | grep -v "#!/bin/bash"| grep -v 'cd $PBS_O_WORKDIR'`
EOF

fi
