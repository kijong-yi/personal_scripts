#!/bin/bash
tmp=~/.`shuf -i 1-10000 -n 1`
cat <<EOF | ~kjyi/src/arg_parser.sh > $tmp
#Build sample-expression matrix
#
# Usage: $0 \ 
#	[-t star|rsem|rpkm|fpkm|tpm] <input_files> [input files..]
#
-t|--type	type	star	
EOF
. $tmp && rm $tmp
args=${ARGS[*]}
case $type in 
	star)
		echo -en "Sample\t"
		cut -f1 ${ARGS[1]}| tr '\n' '\t'; echo ""
		for i in $args; do
			name=`basename $i | sed 's/ReadsPerGene.out.tab//'`
			echo -en "$name\t"; 
			cut -f2 $i | tr '\n' '\t';echo "";
	       	done
		;;
	rsem)
		continue
		;;
	rpkm)
		continue
		;;
	fpkm)
		continue
		;;
	tpm)
		continue
		;;
esac
