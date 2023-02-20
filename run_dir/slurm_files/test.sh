#!/bin/bash --login
# Setup environment
export SLURM_NTASKS_PER_NODE=16
export SLURM_NNODES=2
export SLURM_SUBMIT_DIR=/home/shrey/Coding/hpcg/run_dir
# Make new directory 
IOLAYERS=("MPIIO" "HDF5" "ADIOS2_HDF5" "ADIOS2_BP4" "ADIOS2_BP5") # assign IO layer array 
SIZE=16
FULL_CORES=$((${SLURM_NTASKS_PER_NODE})) 
HALF_CORES=$((${FULL_CORES}/2)) 

for m in {0..4}
do 
  export PARENT_DIR=${SLURM_SUBMIT_DIR}/6Feb/${SLURM_NNODES}_${SLURM_NTASKS_PER_NODE}/${SIZE}/${IOLAYERS[${m}]}

  # Case 1 
	source ${SLURM_SUBMIT_DIR}/slurm_files/sequential.sh
	wait 
  # Case 2
	source ${SLURM_SUBMIT_DIR}/slurm_files/oversubscribe.sh 
	wait 
  # Case 3
	source ${SLURM_SUBMIT_DIR}/slurm_files/hyperthread.sh 
	wait 
  # Case 4
	source ${SLURM_SUBMIT_DIR}/slurm_files/oversubscribe.sh
	wait 

done 
