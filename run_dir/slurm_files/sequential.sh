export CASE=Sequential
export RUNDIR=${PARENT_DIR}/${CASE}/$i
echo "**" $CASE 
echo $RUNDIR 
rm -rf ${RUNDIR}
mkdir -p ${RUNDIR}
lfs setstripe -c -1  ${RUNDIR}
cd ${RUNDIR} 
cp ${CONFIG} . 

if (( ${SLURM_NNODES} > 1  )); then 
  NUM_NODES=${HALF_NODES} 
  END_CORES=${FULL_CORES}

  # sequencing for cpu bind 
  end=$((${END_CORES}-1))
  vals=($(seq 0 1 $(eval echo ${end})))
  bar=$(IFS=, ; echo "${vals[*]}")

  TOTAL_RANKS=$((${NUM_NODES} * ${END_CORES} ))
  HALF_TASKS=$((${SLURM_NNODES}*${SLURM_NTASKS_PER_NODE}/2)) # half the number of total tasks divided between the allocated nodes 

  if (($MAP == 1)); then 
    map -n ${TOTAL_RANKS} --mpiargs="--hint=nomultithread  --distribution=block:block --nodes=${NUM_NODES} --ntasks=${HALF_TASKS} --cpu-bind=map_cpu:${bar[@]}" --profile ${HPCG} --nx=${NX} --ny=${NY} --nz=${NZ} --io=${m} --HT=0
  else
    srun  --hint=nomultithread  --distribution=block:block --nodes=${NUM_NODES} --ntasks=${HALF_TASKS} --cpu-bind=map_cpu:${bar[@]} ${HPCG} --nx=${NX} --ny=${NY} --nz=${NZ} --io=${m} --HT=0 > test.out
  fi 

else
  NUM_NODES=${SLURM_NNODES} 
  END_CORES=${HALF_CORES}
  
  # sequencing for cpu bind 
  end=$((${END_CORES}-1))
  vals=($(seq 0 1 $(eval echo ${end})))
  bar=$(IFS=, ; echo "${vals[*]}")

  TOTAL_RANKS=$((${NUM_NODES} * ${END_CORES} ))
 
  if (($MAP == 1)); then 
    map -n ${TOTAL_RANKS} --mpiargs="--hint=nomultithread  --distribution=block:block --nodes=${NUM_NODES} --ntasks=${HALF_CORES} --cpu-bind=map_cpu:${bar[@]}" --profile ${HPCG} --nx=${NX} --ny=${NY} --nz=${NZ} --io=${m} --HT=0
  else 
    srun  --hint=nomultithread  --distribution=block:block --nodes=${NUM_NODES} --ntasks=${HALF_CORES} --cpu-bind=map_cpu:${bar[@]} ${HPCG} --nx=${NX} --ny=${NY} --nz=${NZ} --io=${m} --HT=0 > test.out
  fi 
fi 

echo "JOB ID"  $SLURM_JOBID >> test.out
echo "JOB NAME" ${SLURM_JOB_NAME} >> test.out
