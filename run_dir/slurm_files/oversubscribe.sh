export CASE=Oversubscribe
export RUNDIR=${PARENT_DIR}/${CASE}/$i
echo "**" $CASE 
echo $RUNDIR
rm -rf ${RUNDIR}
mkdir -p ${RUNDIR}
lfs setstripe -c -1  ${RUNDIR}
cd ${RUNDIR} 
cp ${CONFIG} . 

# give sequence of cpu mappings 
if (( ${SLURM_NNODES} > 1  )); then 
  NUM_NODES=${HALF_NODES} 
  END_CORES=${FULL_CORES} 
else
  NUM_NODES=${SLURM_NNODES} 
  END_CORES=${HALF_CORES}
fi 

end=$((${END_CORES}-1))
vals=($(seq 0 1 $(eval echo ${end})))
bar=$(IFS=, ; echo "${vals[*]}")

if ((${MAP} == 1)); then 
  echo "MAP is on"
  TOTAL_RANKS=$((${NUM_NODES} * ${FULL_CORES}))
  map -n ${TOTAL_RANKS} --mpiargs="--hint=nomultithread --distribution=block:block --nodes=${NUM_NODES} --cpu-bind=map_cpu:${bar[@]} --overcommit" --profile  ${HPCG} --nx=${NX} --ny=${NY} --nz=${NZ} --io=${m} --HT=1
else 
  srun --hint=nomultithread --distribution=block:block --nodes=${NUM_NODES} --cpu-bind=map_cpu:${bar[@]} --overcommit ${HPCG} --nx=${NX} --ny=${NY} --nz=${NZ} --io=${m} --HT=1 > test.out
fi 

echo "JOB ID"  $SLURM_JOBID >> test.out
echo "JOB NAME" ${SLURM_JOB_NAME} >> test.out
