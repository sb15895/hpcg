# bash script to perform global scaling on stream 
# export SIZE variable to archer2 slurm script 

# tasks per node
PPN=128

# array parameters test 
NX=$((2**6)) 
NY=$((2**7)) 
NZ=$((2**7)) 

# node start and end as power of 2s 
NODE_START=0
NODE_END=5

# I/O selection range 
IO_START=0
IO_END=3

# Job numbers for averaging 
ARRAY="0-2"

# time per job for custom time
# TIME="00:10:00"

# weak scaling script and directory
DIR=OUTPUT/v2.0.0/EQ_GLOBAL_SIZE
source weakScaling.sh 

# directory for strong scaling 
# DIR=v2.0.0/STRONG/GLOBAL_256MiB
# source strongScaling.sh 

