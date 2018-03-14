#!/bin/bash
##PBS -e /dev/null
#PBS -j oe
##PBS -o /dev/null
cd $PBS_O_WORKDIR
cmd_sjdbGTFfile=`echo $sjdbGTFfile|sed 's/./--sjdbGTFfile &/'` &&
twoPass=`echo $sjdbFileChrStartEnd|sed 's/.*/--twopassMode Basic/'` &&
unzip=`echo $FASTQ1|grep ".gz"|sed 's/.*/--readFilesCommand zcat/'` &&
cmd_sjdbFileChrStartEnd=`echo $sjdbFileChrStartEnd|sed 's/./--sjdbFileChrStartEnd &/'` &&
if [ $chimSegmentMin -gt 0 ]; then
	cmd_chim="--chimSegmentMin $chimSegmentMin --chimJunctionOverhangMin $chimJunctionOverhangMin --chimOutType $chimOutType --chimMainSegmentMultNmax $chimMainSegmentMultNmax"
fi &&
cmd_library=`echo $library|sed 's/./LB:&/'` &&
cmd_platform=`echo $platform|sed 's/./PL:&/'` &&
outSAMattrRGline="ID:$sample_name SM:$sample_name $cmd_library $cmd_platform" &&
mkdir -p $outdir_star &&
mkdir -p $log &&
cat << EOF > $log/$sample.01star.log &&
# Output files list
bam_file		$outdir_star/${sample}Aligned.sortedByCoord.out.bam
bam_index		$outdir_star/${sample}Aligned.sortedByCoord.out.bam.bai
transcriptome_bam	$outdir_star/${sample}Aligned.toTranscriptome.out.bam
chimeric_junctions	$outdir_star/${sample}Chimeric.out.junction
chimeric_bam_file	$outdir_star/${sample}Chimeric.out.sorted.bam
chimeric_bam_index	$outdir_star/${sample}Chimeric.out.sorted.bam.bai
read_counts		$outdir_star/${sample}ReadsPerGene.out.tab
junctions		$outdir_star/${sample}SJ.out.tab
junctions_pass1		$outdir_star/${sample}_STARpass1/SJ.out.tab
log1			$outdir_star/${sample}Log.final.out
log2			$outdir_star/${sample}Log.out
log3			$outdir_star/${sample}Log.progress.out

# Input command
$star --runMode alignReads --runThreadN $THREAD --genomeDir $star_index \\ 
	--readFilesIn $FASTQ1 $FASTQ2 $unzip \\ 
	--outFileNamePrefix $outdir_star/$sample_name \\ 
	$cmd_sjdbGTFfile $twoPass \\ 
	--outFilterMultimapNmax $outFilterMultimapNmax \\ 
	--alignSJoverhangMin $alignSJoverhangMin \\ 
	--alignSJDBoverhangMin $alignSJDBoverhangMin \\ 
	--outFilterMismatchNmax $outFilterMismatchNmax \\ 
	--outFilterMismatchNoverLmax $outFilterMismatchNoverLmax \\ 
	--alignIntronMin $alignIntronMin \\ 
	--alignIntronMax $alignIntronMax \\ 
	--alignMatesGapMax $alignMatesGapMax \\ 
	--outFilterType $outFilterType \\ 
	--outFilterScoreMinOverLread $outFilterScoreMinOverLread \\ 
	--outFilterMatchNminOverLread $outFilterMatchNminOverLread \\ 
	--limitSjdbInsertNsj $limitSjdbInsertNsj \\ 
	--outSAMstrandField $outSAMstrandField \\ 
	--outFilterIntronMotifs $outFilterIntronMotifs \\ 
	--alignSoftClipAtReferenceEnds $alignSoftClipAtReferenceEnds \\ 
	--quantMode $quantMode \\ 
	--outSAMtype $outSAMtype \\ 
	--outSAMunmapped $outSAMunmapped \\ 
	--outSAMattributes $outSAMattributes \\ 
	--outSAMattrRGline $outSAMattrRGline \\ 
	--genomeLoad $genomeLoad \\ 
	$cmd_chim $cmd_sjdbFileChrStartEnd &> $log/$sample_name.01.star.log &&
rm -rf $outdir_star/${sample_name}_STARgenome &&
rm -rf $outdir_star/${sample_name}_STARtmp &&
$samtools sort --threads $THREAD -o $outdir_star/${sample_name}Aligned.sortedByCoord.out.bam $outdir_star/${sample_name}Aligned.out.bam &>> $log/$sample_name.01.star.log &&
rm $outdir_star/${sample_name}Aligned.out.bam &&
$samtools index $outdir_star/${sample_name}Aligned.sortedByCoord.out.bam &>> $log/$sample_name.01.star.log

if [ $chimSegmentMin -gt 0 ]; then
	$samtools sort --threads $THREAD -o $outdir_star/${sample_name}Chimeric.out.sorted.bam $outdir_star/${sample_name}Chimeric.out.sam &>> $log/$sample_name.01.star.log &&
	rm $outdir_star/${sample_name}Chimeric.out.sam &&
	$samtools index $outdir_star/${sample_name}Chimeric.out.sorted.bam &>> $log/$sample_name.01.star.log
fi

EOF
$star --runMode alignReads --runThreadN $THREAD --genomeDir $star_index \
	--readFilesIn $FASTQ1 $FASTQ2 $unzip \
	--outFileNamePrefix $outdir_star/$sample_name \
	$cmd_sjdbGTFfile $twoPass \
	--outFilterMultimapNmax $outFilterMultimapNmax \
	--alignSJoverhangMin $alignSJoverhangMin \
	--alignSJDBoverhangMin $alignSJDBoverhangMin \
	--outFilterMismatchNmax $outFilterMismatchNmax \
	--outFilterMismatchNoverLmax $outFilterMismatchNoverLmax \
	--alignIntronMin $alignIntronMin \
	--alignIntronMax $alignIntronMax \
	--alignMatesGapMax $alignMatesGapMax \
	--outFilterType $outFilterType \
	--outFilterScoreMinOverLread $outFilterScoreMinOverLread \
	--outFilterMatchNminOverLread $outFilterMatchNminOverLread \
	--limitSjdbInsertNsj $limitSjdbInsertNsj \
	--outSAMstrandField $outSAMstrandField \
	--outFilterIntronMotifs $outFilterIntronMotifs \
	--alignSoftClipAtReferenceEnds $alignSoftClipAtReferenceEnds \
	--quantMode $quantMode \
	--outSAMtype $outSAMtype \
	--outSAMunmapped $outSAMunmapped \
	--outSAMattributes $outSAMattributes \
	--outSAMattrRGline $outSAMattrRGline \
	--genomeLoad $genomeLoad \
	$cmd_chim $cmd_sjdbFileChrStartEnd &>> $log/$sample_name.01.star.log &&
rm -rf $outdir_star/${sample_name}_STARgenome &&
rm -rf $outdir_star/${sample_name}_STARtmp &&
$samtools sort --threads $THREAD -o $outdir_star/${sample_name}Aligned.sortedByCoord.out.bam $outdir_star/${sample_name}Aligned.out.bam &>> $log/$sample_name.01.star.log &&
rm $outdir_star/${sample_name}Aligned.out.bam &&
$samtools index $outdir_star/${sample_name}Aligned.sortedByCoord.out.bam &>> $log/$sample_name.01.star.log &&
if [ $chimSegmentMin -gt 0 ]; then
	$samtools sort --threads $THREAD -o $outdir_star/${sample_name}Chimeric.out.sorted.bam $outdir_star/${sample_name}Chimeric.out.sam &>> $log/$sample_name.01.star.log &&
	rm $outdir_star/${sample_name}Chimeric.out.sam &&
	$samtools index $outdir_star/${sample_name}Chimeric.out.sorted.bam &>> $log/$sample_name.01.star.log
fi &&
mv $log/$sample_name.01.star.log $log/$sample_name.01.star.done.log 
if [ -f $log/$sample_name.01.star.log ];then
	mv $log/$sample_name.01.star.log $log/$sample_name.01.star.fail.log
fi
