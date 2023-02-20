    export CASE=Consecutive
    export RUNDIR=${PARENT_DIR}/${CASE}/$i
    echo "**" $CASE 
    rm -rf ${RUNDIR}
    mkdir -p ${RUNDIR}
#    lfs setstripe -c -1  ${RUNDIR}
    cd ${RUNDIR} 
    end=$((${FULL_CORES}-1))
    vals=($(seq 0 1 $(eval echo ${end})))
    bar=$(IFS=, ; echo "${vals[*]}")
		echo $bar
#    srun --cpu-bind=verbose --hint=nomultithread  --distribution=block:block --ntasks=${FULL_CORES} --nodes=1 --cpu-bind=map_cpu:${bar[@]} ${HPCG} --nx=${SIZE} --ny=${SIZE} --nz=${SIZE} --io=${i} --HT=1 > test.out
