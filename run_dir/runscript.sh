# bash script to perform global scaling on stream 
# export SIZE variable to archer2 slurm script 

# tasks per node
PPN=128

# array parameters 
NX=$((2**6)) 
NY=$((2**6)) 
NZ=$((2**6)) 

# node start and end as power of 2s 
NODE_START=1
NODE_END=7

# I/O selection range 
IO_START=0
IO_END=0

# Job numbers for averaging 
ARRAY="1-2"

# time per job for custom time
# TIME="01:00:00"

# weak scaling script and directory
# DIR=OUTPUT/v2.0.0/TESTING
# DIR=TESTING
# source weakScaling.sh 

# directory for strong scaling 
DIR=v2.0.0/STRONG/GLOBAL_256MiB
source strongScaling.sh 

