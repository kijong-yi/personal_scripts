#!/bin/bash
#PBS -j oe
##PBS -e /dev/null
##PBS -o /dev/null
cd $PBS_O_WORKDIR
if [[ "x$FASTQ2" = "x" ]];then paired_end=false; else paired_end=true; fi &&
mkdir -p $outdir_rsem &&
mkdir -p $log &&
input_absolute_path=`readlink -f $outdir_star/${sample_name}Aligned.toTranscriptome.out.bam` &&
rsem_ref_abs=`readlink -f $rsem_ref` &&
outdir_rsem_abs=`readlink -f $outdir_rsem` &&
log_abs=`readlink -f $log` &&
cat <<EOF > $log/$sample_name.02.rsem.log &&
# Output files list
- Genes 	$outdir_star/$sample_name.rsem.genes.results
- Isoforms 	$outdir_star/$sample_name.rsem.isoforms.results

# Command
python3 ~kjyi/src/star/RSEM.py \\ 
	-o $outdir_rsem_abs \\ 
	--max_frag_len $rsem_max_frag_len \\ 
	--estimate_rspd $rsem_estimate_rspd \\ 
	--is_stranded $is_stranded \\ 
	--paired_end $paired_end \\ 
	--threads $THREAD \\ 
	$rsem_ref_abs $input_absolute_path $sample_name &> $log/$sample_name.02.rsem.log &&
mv $log/$sample_name.02.rsem.log $log/$sample_name.02.rsem.done.log
EOF
python3 ~kjyi/src/star/RSEM.py \
	-o $outdir_rsem \
	--max_frag_len $rsem_max_frag_len \
	--estimate_rspd $rsem_estimate_rspd \
	--paired_end $paired_end \
	--threads $THREAD \
	$rsem_ref_abs $input_absolute_path $sample_name &>>$log/$sample_name.02.rsem.log &&
mv $log/$sample_name.02.rsem.log $log/$sample_name.02.rsem.done.log
if [ -f $log/$sample_name.02.rsem.log ]; then
	mv $log/$sample_name.02.rsem.log $log/$sample_name.02.rsem.fail.log 
fi
