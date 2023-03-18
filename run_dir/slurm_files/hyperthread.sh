export CASE=Hyperthread
export RUNDIR=${PARENT_DIR}/${CASE}/$i
echo "**" $CASE 
echo $RUNDIR
rm -rf ${RUNDIR}
mkdir -p ${RUNDIR}
lfs setstripe -c -1  ${RUNDIR}
cd ${RUNDIR} 
cp ${CONFIG} . 

# if more than 1 node, then HT uses half the number of nodes. 
if (( ${SLURM_NNODES} > 1  )); then 
  NUM_NODES=${HALF_NODES} 
else
  NUM_NODES=${SLURM_NNODES} 
fi 

# if more than 1 node, then HT uses half the number of nodes. 
if (( ${SLURM_NNODES} > 1  )); then 
  NUM_NODES=${HALF_NODES} 
  END_CORES=${FULL_CORES} 
else
  NUM_NODES=${SLURM_NNODES} 
  END_CORES=${HALF_CORES}
fi 

# seq 1
end=$((${END_CORES}-1))
vals=($(seq 0 1 $(eval echo ${end})))

# seq 2 
end=$((${END_CORES}+128-1))
start=128
vals_HT=($(seq $(eval echo ${start}) 1 $(eval echo ${end})))
updated=("${vals[@]}" "${vals_HT[@]}")
bar=$(IFS=, ; echo "${updated[*]}")

srun  --hint=multithread --distribution=block:block  --nodes=${NUM_NODES} --cpu-bind=map_cpu:${bar[@]} ${HPCG} --nx=${SIZE} --ny=${SIZE} --nz=${SIZE} --io=${m} --HT=1 > test.out

echo "JOB ID"  $SLURM_JOBID >> test.out
echo "JOB NAME" ${SLURM_JOB_NAME} >> test.out
