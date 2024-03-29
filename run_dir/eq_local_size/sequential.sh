export CASE=Sequential

# setup of directories and copying of config files and make outputs.
source ${SLURM_SUBMIT_DIR}/eq_local_size/setup.sh 

if (( ${SLURM_NNODES} > 1  )); then 
  NUM_NODES=$((${SLURM_NNODES}/2))  
  END_CORES=${SLURM_NTASKS_PER_NODE}
  # half the number of total tasks divided between the allocated nodes.
  NUM_TASKS=$((${SLURM_NNODES}*${SLURM_NTASKS_PER_NODE}/2))  
else 
  NUM_NODES=${SLURM_NNODES} 
  END_CORES=$((${SLURM_NTASKS_PER_NODE}/2))
  NUM_TASKS=$((${SLURM_NTASKS_PER_NODE}/2))  
fi

# sequencing for cpu bind 
end=$((${END_CORES}-1))
vals=($(seq 0 1 $(eval echo ${end})))
bar=$(IFS=, ; echo "${vals[*]}")

if (( ${MAP} == 1  )); then 
  TOTAL_RANKS=$((${NUM_NODES}*${END_CORES}))
  map --mpi=slurm -n ${TOTAL_RANKS} --mpiargs="--hint=nomultithread  --distribution=block:block --nodes=${NUM_NODES} --ntasks=${NUM_TASKS} --cpu-bind=map_cpu:${bar[@]}" --profile  --perf-metrics="instructions; cpu-cycles; cache-misses; cache-references;" ${EXE} --nx=${NX} --ny=${NY} --nz=${NZ} --io=${IO} --sh=${SHARED} --HT=${HT} > test.out 
  wait 
  # delete file outputs from map run as they are not going to be tested. 
  rm *.dat 
  rm *.h5 
  rm -rf x_* 
else 
  srun  --hint=nomultithread  --distribution=block:block --nodes=${NUM_NODES} --ntasks=${NUM_TASKS} --cpu-bind=map_cpu:${bar[@]} ${EXE} --nx=${NX} --ny=${NY} --nz=${NZ} --io=${IO} --sh=${SHARED} --HT=${HT} > test.out
  wait 
  echo TESTING with ${NUM_NODES} nodes and ${NUM_TASKS} tasks ${END_CORES} tasks per node.
  srun  --nodes=${NUM_NODES} --ntasks-per-node=${END_CORES} --ntasks=${NUM_TASKS} ${TEST_EXE} --nx ${NX} --ny ${NY} --nz ${NZ} --io ${IO} >> test.out
  wait 
fi 

echo "JOB ID"  $SLURM_JOBID >> test.out
echo "JOB NAME" ${SLURM_JOB_NAME} >> test.out
