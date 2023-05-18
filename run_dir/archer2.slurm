#!/bin/bash --login
#SBATCH --job-name=hpcg
#SBATCH --nodes=1
#SBATCH --tasks-per-node=16
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00
#SBATCH --account=e609
#SBATCH --partition=standard 
#SBATCH --qos=lowpriority

module swap PrgEnv-cray/8.0.0 PrgEnv-gnu
module load cmake 
module use /work/y07/shared/archer2-lmod/dev
module load xthi 
module swap craype-network-ofi craype-network-ucx 
module swap cray-mpich cray-mpich-ucx 
module load cray-hdf5-parallel
module load arm/forge/22.1.3

# Setup environment
export PPN=${SLURM_NTASKS_PER_NODE}
export OMP_NUM_THREADS=1
# iocomp gnu dir 
export IOCOMP_DIR=/work/e609/e609/shr203/opt/gnu/8.0.0/iocomp
export LD_LIBRARY_PATH=${IOCOMP_DIR}/lib:${LD_LIBRARY_PATH} 
export ADIOS2_DIR=/work/e609/e609/shr203/opt/gnu/8.0.0/ADIOS2
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${ADIOS2_DIR}/lib64
export HPCG=/work/e609/e609/shr203/hpcg/build/bin/xhpcg
export CONFIG=/work/e609/e609/shr203/hpcg/run_dir/config.xml 
MAP=0 # map options 

# Make new directory 
IOLAYERS=("MPIIO" "HDF5" "ADIOS2_HDF5" "ADIOS2_BP4" "ADIOS2_BP5") # assign IO layer array 
i=${SLURM_ARRAY_TASK_ID} 
HALF_CORES=$((${SLURM_NTASKS_PER_NODE}/2)) 
FULL_CORES=$((${SLURM_NTASKS_PER_NODE})) 
HALF_NODES=$((${SLURM_NNODES}/2))
SIZE=$((${NX}*${NY}*${NZ}/(2**20))) # size in MiB 

echo "Job started " $(date +"%T") # start time
for m in $(seq ${IO_start} ${IO_end}) 
do 
  export PARENT_DIR=${SLURM_SUBMIT_DIR}/${DIR}/${SLURM_NNODES}_${SLURM_NTASKS_PER_NODE}/${SIZE}/${IOLAYERS[${m}]}

  # Case 1 
  source ${SLURM_SUBMIT_DIR}/slurm_files/sequential.sh

 # # Case 2
 # source ${SLURM_SUBMIT_DIR}/slurm_files/oversubscribe.sh 
 # wait 

  # Case 3
  source ${SLURM_SUBMIT_DIR}/slurm_files/hyperthread.sh 
  wait 

  # Case 4
  source ${SLURM_SUBMIT_DIR}/slurm_files/consecutive.sh
done 

echo $(module list) 

# runtime given by: 
echo "Job ended " $(date +"%T") # end time 
