#/bin/bash
rm -rf $HOME/.myscreen
mkdir -p $HOME/.myscreen
for i in 0 1 2 3 4 5 6 7;do
	ssh -x bnode$i ls /var/run/screen/S-$USER ">" $HOME/.myscreen/$i &
done
wait
cat $HOME/.myscreen/* > $HOME/.myscreen/all
cat $HOME/.myscreen/all
if [ -s $HOME/.myscreen/all ];then 
	echo -en "Type a node number to reattach, or type 0 to open a new one"; read -p "" node
else
	echo "No screen session detected"; node=0
fi
echo $node
if [[ "${node}" == "0" ]]; then
	HOSTNAME=$(hostname)
	if [[ "${HOSTNAME}"=="bnode0" ]];then
		echo -en "How many CPUs will you use? (default=2)"; read -p "" ncpu
		echo -en "How much memory will you use? (default=4gb)"; read -p "" mem 
		[[ ncpu=="" ]] && ncpu=2
		[[ mem=="" ]] && mem=4gb
		echo "Submitting ticket: -l number of CPU=$ncpu, memory=$mem"
		eval qsub -I -l nodes=1:ppn=$ncpu -l mem=$mem screen

	else
		echo "Please back to bnode0 or restart shell if you are in activated interacting PBS shell"
		exit 1
	fi
else
	echo Please type screen -R to reattach session
	ssh -t bnode${node} screen -d -r
fi
