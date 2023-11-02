#!/bin/bash --login
#SBATCH --job-name=hpcg
#SBATCH --nodes=1
#SBATCH --tasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=00:05:00
#SBATCH --account=e609
#SBATCH --partition=standard 
#SBATCH --qos=standard

export HPCG_DIR=$(cd ${SLURM_SUBMIT_DIR}/../ && pwd) 

# different module loads. Swap cray env to gnu env 
module swap PrgEnv-cray/8.0.0 PrgEnv-gnu
module load cmake 
module use /work/y07/shared/archer2-lmod/dev
module swap craype-network-ofi craype-network-ucx 
module swap cray-mpich cray-mpich-ucx 
module load cray-hdf5-parallel

# Setup environment
export IOCOMP_DIR=/work/e609/e609/shr203/opt/gnu/8.0.0/iocomp/2.0.0
export ADIOS2_DIR=/work/e609/e609/shr203/opt/gnu/8.0.0/ADIOS2
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${ADIOS2_DIR}/lib64:${IOCOMP_DIR}/lib
# export HPCG=/work/e609/e609/shr203/hpcg/build/bin/xhpcg
export EXE=${HPCG_DIR}/build/bin/xhpcg
export CONFIG=${HPCG_DIR}/run_dir/config.xml 

# avg jobs directories
iter=${SLURM_ARRAY_TASK_ID}

# flag for archer2 runs 
export FI_OFI_RXM_SAR_LIMIT=64K

# Setup environment
export PPN=${SLURM_NTASKS_PER_NODE}
export OMP_NUM_THREADS=1

# Make new directory 
IOLAYERS=("MPIIO" "HDF5" "ADIOS2_HDF5" "ADIOS2_BP4" "ADIOS2_BP5") # assign IO layer array 
SIZE=$(( ${NX}*${NY}*${NZ}*8 / 2**20 )) # local size in MiB

#switch off MAP 
MAP=0

echo "Job started " $(date +"%T") # start time

for IO in $(seq ${IO_START} ${IO_END})
do 
  export PARENT_DIR=${SLURM_SUBMIT_DIR}/${DIR}/${SLURM_NNODES}_${SLURM_NTASKS_PER_NODE}/${SIZE}MiB/${IOLAYERS[${IO}]}

  # Case 1 
  export SHARED=0; export HT=0
	source ${SLURM_SUBMIT_DIR}/slurm_files/sequential.sh
	wait 

  # Case 2
  export SHARED=0; export HT=1; export FLAG=HT
	source ${SLURM_SUBMIT_DIR}/slurm_files/hyperthread.sh 
	wait 

  # Case 3
  export SHARED=1; export HT=0; export FLAG=shared
	source ${SLURM_SUBMIT_DIR}/slurm_files/hyperthread.sh 
	wait 

  # Case 4
  export SHARED=0; export HT=1; export FLAG=HT
	source ${SLURM_SUBMIT_DIR}/slurm_files/consecutive.sh
	wait 

  # Case 5
  export SHARED=1; export HT=0; export FLAG=shared
	source ${SLURM_SUBMIT_DIR}/slurm_files/consecutive.sh
	wait 
done 

echo $(module list) 

# runtime given by: 
echo "Job ended " $(date +"%T") # end time 
