export CASE=Hyperthread/${FLAG}

# setup of directories and copying of config files and make outputs.
source ${SLURM_SUBMIT_DIR}/eq_global_size/setup.sh 

# Hyperthreads use 2x number of tasks as rest 
NUM_NODES=${SLURM_NNODES} 
END_CORES=${SLURM_NTASKS_PER_NODE}
NUM_TASKS=$(( ${END_CORES}*${NUM_NODES}*2 )) 

# Generate sequence such that the normal cores and HT cores(normal cores + 128) are stacked and seperated with a comma.   
# seq 1 
end=$((${END_CORES}-1))
vals=($(seq 0 1 $(eval echo ${end})))

# seq 2 
end=$((${END_CORES}+128-1))
start=128
vals_HT=($(seq $(eval echo ${start}) 1 $(eval echo ${end})))
updated=("${vals[@]}" "${vals_HT[@]}")
bar=$(IFS=, ; echo "${updated[*]}")

if (( ${MAP} == 1  )); then 
  map -n $TOTAL_RANKS --mpiargs="--hint=multithread --distribution=block:block  --nodes=${NUM_NODES} --cpu-bind=map_cpu:${bar[@]}" --profile ${EXE} --HT --size ${SIZE} --io ${IO} > test.out
else 
  srun  --hint=multithread --distribution=block:block  --nodes=${NUM_NODES} --ntasks=${NUM_TASKS} --cpu-bind=map_cpu:${bar[@]} ${EXE} --nx=${NX} --ny=${NY} --nz=${NZ} --io=${IO} --sh=${SHARED} --HT=${HT} > test.out
  wait
  # call test function, main variables are nodes test and ppn test, rest are consistent across cases.
  (
    export NODES_TEST=${NUM_NODES}
    export PPN_TEST=${END_CORES}
    export TEST_EXE=${TEST_EXE}; export NX=${NX}; export NY=${NY}; export NZ=${NZ}; export IO=${IO} 
    sh ${SLURM_SUBMIT_DIR}/eq_global_size/test.sh 
  )
  wait 
fi 

echo "JOB ID"  $SLURM_JOBID >> test.out
echo "JOB NAME" ${SLURM_JOB_NAME} >> test.out
