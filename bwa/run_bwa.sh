#!/bin/bash
# Default setting
#  I/O
OUTDIR=./bam/
SAMPLE=""
LOG=./log/
EMAIL=""
#  Read Group Info
PLATFORM="ILLUMINA"
#  Binary
BWA=/home/users/tools/bwa/bwa
SAMTOOLS=/home/users/kjyi/tools/samtools/samtools-1.5/bin/samtools
PICARD=/home/users/kjyi/tools/picard/2.15.0/picard.jar
GATK=/home/users/kjyi/tools/GATK/3.8.0/GenomeAnalysisTK.jar
#  References
REF=/home/users/data/01_reference/human_g1k_v37/human_g1k_v37.fasta
INDEL=/home/users/data/02_annotation/01_GATK/01_golden_standard/Mills_and_1000G_gold_standard.indels.b37.vcf
DBSNP=/home/users/data/02_annotation/01_GATK/02_db_snp/dbsnp_138.b37.vcf
#  Computational setting
THREAD=6
MEMORY=8G #not total, per 1 picard process
# Usage
USAGE="Align fastq files using BWA MEM algorithm, sorting, marking duplicates,
realign around indels, BQSR, indexing. Run on torque/PBS system.

Usage: $0 \\
        <--sample_name sample_name> <in1.fa.gz> [in2.fa.gz] \\
        [--outdir outdir] [options]

-s --sample_name  <mandatory>
-o --outdir       $OUTDIR
-l --log          $LOG
-M --mail_address $EMAIL
-p --platform     $PLATFORM
-b --bwa          $BWA
-S --samtools     $SAMTOOLS
-P --picard       $PICARD
-g --gatk         $GATK
-r --reference    $REF
-i --indel        $INDEL
-d --dbsnp        $DBSNP
-t --thread       $THREAD
-m --memory       $MEMORY"
if [ $# == 0 ]; then echo "$USAGE"; exit 0; fi

# Argument parsing
ARGS=( "$@" )
for i in "${!ARGS[@]}"; do
	case "${ARGS[i]}" in
		'') continue;; #skip if element is empty
		-o|--outdir) OUTDIR="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-s|--sample_name) SAMPLE="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-l|--log) LOG="{ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-M|--mail_address) EMAIL="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-p|--platform) PLATFORM="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-h|--help) echo -en "${USAGE}"; exit 1;;
		-b|--bwa) BWA="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-S|--samtools) SAMTOOLS="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-P|--picard) PICARD="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-g|--gatk) GATK="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-r|--reference) REF="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-i|--indel) INDEL="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-d|--dbsnp) DBSNP="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-t|--thread) THREAD="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		-m|--memory) MEMORY="${ARGS[i+1]}"; unset 'ARGS[i+1]';;
		--) unset 'ARGS[i]'; break;; # End of arguments
		*) continue;; # Skip unset if our argument has not been matched
        esac
        unset 'ARGS[i]'
done

FASTQ=(); for i in "${!ARGS[@]}"; do FASTQ+=(${ARGS[i]}); done
FASTQ1=${FASTQ[0]}
FASTQ2=${FASTQ[1]}
EMAIL_SCRIPT=`echo $EMAIL|sed 's/./-m abe -M &/'i`

# Run pipeline
export OUTDIR SAMPLE LOG PLATFORM BWA SAMTOOLS PICARD GATK REF INDEL DBSNP THREAD MEMORY FASTQ1 FASTQ2
SCRIPT=/home/users/kjyi/tools/kjscript/bwa
runBWA=$(qsub -V -q long -l nodes=1:ppn=$THREAD -N bwa_$SAMPLE $EMAIL_SCRIPT $SCRIPT/bwa.qsh)
runPICARD=$(qsub -W depend=afterok:$runBWA -V -q long -l nodes=1:ppn=5 -N picard_$SAMPLE $EMAIL_SCRIPT $SCRIPT/picard.qsh)
runGATK=$(qsub -W depend=afterok:$runPICARD -V -q long -l nodes=1:ppn=$THREAD -N GATK_$SAMPLE $EMAIL_SCRIPT $SCRIPT/gatk.qsh)
