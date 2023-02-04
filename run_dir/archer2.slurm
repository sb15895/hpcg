#!/bin/bash --login
#SBATCH --job-name=iocomp
#SBATCH --nodes=1
#SBATCH --tasks-per-node=2
#SBATCH --cpus-per-task=1
#SBATCH --time=00:01:00
#SBATCH --account=e609
#SBATCH --partition=standard 
#SBATCH --qos=lowpriority
##SBATCH --array=0-1

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
for i in {0..4}
do 
  export RUN_DIR=${SLURM_SUBMIT_DIR}/${SLURM_JOB_ID}/${SLURM_NNODES}_${SLURM_NTASKS_PER_NODE}/${IOLAYERS[${i}]}
  echo ${RUN_DIR} 
  rm -rf ${RUN_DIR} 
  mkdir -p ${RUN_DIR}
  lfs setstripe -c -1  ${RUN_DIR}
  cd ${RUN_DIR} 
  cp ${IOCOMP_DIR}/test/config.xml . 
  srun ${HPCG} --nx=${SIZE} --ny=${SIZE} --nz=${SIZE} --io=${i} --HT=1 > test.out
done 

module list  2>&1 | tee -a test.out 

echo "JOB ID"  $SLURM_JOBID >> test.out
echo "JOB NAME" ${SLURM_JOB_NAME} >> test.out


