   export CASE=Oversubscribe
   export RUNDIR=${PARENT_DIR}/${CASE}/$i
   echo "**" $CASE 
	 echo $RUNDIR
   rm -rf ${RUNDIR}
   mkdir -p ${RUNDIR}
#   lfs setstripe -c -1  ${RUNDIR}
   cd ${RUNDIR} 
   end=$((${HALF_CORES}-1))
   vals=($(seq 0 1 $(eval echo ${end})))
   bar=$(IFS=, ; echo "${vals[*]}")
	 echo $bar
#   srun  --cpu-bind=verbose --hint=nomultithread --distribution=block:block --ntasks=${FULL_CORES} --nodes=1 --overcommit --cpu-bind=map_cpu:${bar[@]}  ${HPCG} --nx=${SIZE} --ny=${SIZE} --nz=${SIZE} --io=${i} --HT=1 > test.out
