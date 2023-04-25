PPN=16
for x in {0..4}
do 
  NUM_NODES=$((2**x)) 
  for IO in {0..2}
  do 
    if ((x<2)) # different times for different number of nodes 
    then 
      TIME_VAR=10:00:00
    else
      TIME_VAR=20:00:00
    fi 
    echo IO ${IO} PPN ${PPN} NODES ${NUM_NODES} TIME ${TIME_VAR}
    sbatch --export=ALL,m=${IO} --ntasks-per-node=${PPN} --nodes=${NUM_NODES} --time=${TIME_VAR} archer2.slurm 
  done 
done 
