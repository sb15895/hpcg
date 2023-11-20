export CASE=Sequential

# setup of directories and copying of config files and make outputs.
source ${SLURM_SUBMIT_DIR}/eq_global_size/setup.sh 

# sequential also uses same number of tasks and cores as slurm options.
# tests also same as there is no splitting between io and compute 
NUM_NODES=${SLURM_NNODES} 
END_CORES=${SLURM_NTASKS_PER_NODE}

# sequencing for cpu bind 
end=$((${END_CORES}-1))
vals=($(seq 0 1 $(eval echo ${end})))
bar=$(IFS=, ; echo "${vals[*]}")

if (( ${MAP} == 1  )); then 
  TOTAL_RANKS=$((${NUM_NODES}*${END_CORES}))
  map --mpi=slurm -n ${TOTAL_RANKS} --mpiargs="--hint=nomultithread  --distribution=block:block --nodes=${NUM_NODES} --ntasks=${HALF_CORES} --cpu-bind=map_cpu:${bar[@]}" --profile  ${EXE} --nx ${NX} --ny ${NY} --io ${IO}
else 
  srun  --hint=nomultithread  --distribution=block:block --nodes=${NUM_NODES} --ntasks-per-node=${END_CORES} --cpu-bind=map_cpu:${bar[@]} ${EXE} --nx=${NX} --ny=${NY} --nz=${NZ} --io=${IO} --sh=${SHARED} --HT=${HT} > test.out
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
