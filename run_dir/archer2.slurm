#!/bin/bash --login
#SBATCH --job-name=iocomp
#SBATCH --nodes=1
#SBATCH --tasks-per-node=2
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --account=e609
#SBATCH --partition=standard 
#SBATCH --qos=lowpriority
#SBATCH --array=0-2

module swap PrgEnv-cray/8.0.0 PrgEnv-gnu
module load cmake 
module use /work/y07/shared/archer2-lmod/dev
module load xthi 
module swap craype-network-ofi craype-network-ucx 
module swap cray-mpich cray-mpich-ucx 
module load cray-hdf5-parallel

# Setup environment
export PPN=${SLURM_NTASKS_PER_NODE}
export OMP_NUM_THREADS=1
export TEST=${SLURM_SUBMIT_DIR}/test
export IOCOMP_DIR=/work/e609/e609/shr203/iocomp
export ADIOS2_DIR=/work/e609/e609/shr203/opt/gnu/8.0.0/ADIOS2
export HPCG=/work/e609/e609/shr203/hpcg/build/bin/xhpcg
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${ADIOS2_DIR}/lib64:${IOCOMP_DIR}/lib

# Make new directory 
IOLAYERS=("MPIIO" "HDF5" "ADIOS2_HDF5" "ADIOS2_BP4" "ADIOS2_BP5") # assign IO layer array 
SIZE=16
i=${SLURM_ARRAY_TASK_ID} 
HALF_CORES=$((${SLURM_NTASKS_PER_NODE}/2)) 
FULL_CORES=$((${SLURM_NTASKS_PER_NODE})) 
for m in {0..4}
do 
  export PARENT_DIR=${SLURM_SUBMIT_DIR}/6Feb/${SLURM_NNODES}_${SLURM_NTASKS_PER_NODE}/${SIZE}/${IOLAYERS[${m}]}

  # Case 1 
    export CASE=Sequential
    export RUNDIR=${PARENT_DIR}/${CASE}/$i
    echo "**" $CASE 
    rm -rf ${RUNDIR}
    mkdir -p ${RUNDIR}
    lfs setstripe -c -1  ${RUNDIR}
    cd ${RUNDIR} 
    cp ${IOCOMP_DIR}/test/config.xml . 
    end=$((${HALF_CORES}-1))
    vals=($(seq 0 1 $(eval echo ${end})))
    bar=$(IFS=, ; echo "${vals[*]}")
    srun --cpu-bind=verbose --hint=nomultithread  --distribution=block:block --ntasks=${HALF_CORES} --nodes=1  --cpu-bind=map_cpu:${bar[@]}  ${HPCG} --nx=${SIZE} --ny=${SIZE} --nz=${SIZE} --io=${i} --HT=0 > test.out
    wait 

  # Case 2
    export CASE=Oversubscribe
    export RUNDIR=${PARENT_DIR}/${CASE}/$i
    echo "**" $CASE 
    rm -rf ${RUNDIR}
    mkdir -p ${RUNDIR}
    lfs setstripe -c -1  ${RUNDIR}
    cd ${RUNDIR} 
    end=$((${HALF_CORES}-1))
    vals=($(seq 0 1 $(eval echo ${end})))
    bar=$(IFS=, ; echo "${vals[*]}")
    srun  --cpu-bind=verbose --hint=nomultithread --distribution=block:block --ntasks=${FULL_CORES} --nodes=1 --overcommit --cpu-bind=map_cpu:${bar[@]}  ${HPCG} --nx=${SIZE} --ny=${SIZE} --nz=${SIZE} --io=${i} --HT=1 > test.out
    wait 

  # Case 3
    export CASE=Hyperthread
    export RUNDIR=${PARENT_DIR}/${CASE}/$i
    echo "**" $CASE 
    rm -rf ${RUNDIR}
    mkdir -p ${RUNDIR}
    lfs setstripe -c -1  ${RUNDIR}
    cd ${RUNDIR} 
    # seq 1
    end=$((${HALF_CORES}-1))
    vals=($(seq 0 1 $(eval echo ${end})))
    # seq 2 
    end=$((${HALF_CORES}+128-1))
    start=128
    vals_HT=($(seq $(eval echo ${start}) 1 $(eval echo ${end})))
    updated=("${vals[@]}" "${vals_HT[@]}")
    bar=$(IFS=, ; echo "${updated[*]}")
    srun  --cpu-bind=verbose --hint=multithread --distribution=block:block --ntasks=${FULL_CORES} --nodes=1 --cpu-bind=map_cpu:${bar[@]} ${HPCG} --nx=${SIZE} --ny=${SIZE} --nz=${SIZE} --io=${i} --HT=1 > test.out
    wait

  # Case 4
    export CASE=Consecutive
    export RUNDIR=${PARENT_DIR}/${CASE}/$i
    echo "**" $CASE 

    rm -rf ${RUNDIR}
    mkdir -p ${RUNDIR}
    lfs setstripe -c -1  ${RUNDIR}
    cd ${RUNDIR} 
    end=$((${FULL_CORES}-1))
    vals=($(seq 0 1 $(eval echo ${end})))
    bar=$(IFS=, ; echo "${vals[*]}")
    srun --cpu-bind=verbose --hint=nomultithread  --distribution=block:block --ntasks=${FULL_CORES} --nodes=1 --cpu-bind=map_cpu:${bar[@]} ${HPCG} --nx=${SIZE} --ny=${SIZE} --nz=${SIZE} --io=${i} --HT=1 > test.out
  done 

module list  2>&1 | tee -a test.out 

echo "JOB ID"  $SLURM_JOBID >> test.out
echo "JOB NAME" ${SLURM_JOB_NAME} >> test.out


