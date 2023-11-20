export CASE=Consecutive/${FLAG} 

# setup of directories and copying of config files and make outputs.
source ${SLURM_SUBMIT_DIR}/eq_global_size/setup.sh 

# consecutive uses same number of nodes and tasks per node as passed to slurm, so no need to change those.
NUM_NODES=${SLURM_NNODES} 
END_CORES=${SLURM_NTASKS_PER_NODE}  
NX_UPD=$(( ${NX}*2 )) # Consecutive has 1/2 as many writers, so needs to write 2x more per writer.

# Generate sequence from 0 to PPN 
end=$((${END_CORES}-1))
vals=($(seq 0 1 $(eval echo ${end})))
bar=$(IFS=, ; echo "${vals[*]}")

if (( ${MAP} == 1  )); then 
  TOTAL_RANKS=$(( ${SLURM_NNODES} * ${FULL_CORES} ))
  map --mpi=slurm -n ${TOTAL_RANKS} --mpiargs="--hint=nomultithread  --distribution=block:block" --profile  ${EXE} --HT --nx ${NX} --ny ${NY}  --io ${IO}
else 
  srun  --hint=nomultithread  --distribution=block:block --cpu-bind=map_cpu:${bar[@]} ${EXE} --nx=${NX_UPD} --ny=${NY} --nz=${NZ} --io=${IO} --sh=${SHARED} --HT=${HT} > test.out 
  wait 
  # for testing purposes, global number of nodes/processes are halved from  to match the ranks available to IO server
  if (( ${NUM_NODES} > 1  )); then 
    NODES_TEST=$((${NUM_NODES}/2))
    PPN_TEST=${SLURM_NTASKS_PER_NODE}
  else
    NODES_TEST=${NUM_NODES}
    PPN_TEST=$((${SLURM_NTASKS_PER_NODE}/2)) 
  fi 
  # call test function, main variables are nodes test and ppn test, rest are consistent across cases.
  (
    export NODES_TEST=${NODES_TEST}
    export PPN_TEST=${PPN_TEST}
    export TEST_EXE=${TEST_EXE}; export NX=${NX_UPD}; export NY=${NY}; export NZ=${NZ}; export IO=${IO} 
    sh ${SLURM_SUBMIT_DIR}/eq_global_size/test.sh 
  )
  wait 
fi 

echo "JOB ID"  $SLURM_JOBID >> test.out
echo "JOB NAME" ${SLURM_JOB_NAME} >> test.out
