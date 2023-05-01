## Weak scaling 

# fixed at 16 tasks per node
PPN=16
# array parameters 
NX=256
NY=256
NZ=128
# number of nodes, as power of 2s
NODE_START=0
NODE_END=4
# directory 
DIR=v1.1.4
# I/O layers range 
IO_START=0
IO_END=0 # Just till MPIIO  
# time for job  
TIMES=("05:00:00" "06:00:00" "06:00:00" "07:00:00" "07:00:00") 
ARRAY="0-2"

echo $DIR 
SIZE=$(( (${NX}*${NY}*${NZ}*8*27) / 2**20 )) # local size of output data in MiB 
# iterate through number of nodes 
for i in $(seq ${NODE_START} ${NODE_END}) # 1 till 16 nodes 
do 

  TIME_VAR=${TIMES[${i}]} 
  NUM_NODES=$((2**${i}))
  # iterate through number of I/O layers 
  for IO in $(seq ${IO_START} ${IO_END}) 
  do 
    echo NODES ${NUM_NODES} PPN ${PPN} IO ${IO} to ${IO}  TIME ${TIME_VAR} SIZE ${NX} x ${NY} x ${NZ} = ${SIZE}MiB 
    sbatch --export=ALL,DIR=${DIR},NX=${NX},NY=${NY},NZ=${NZ},IO_start=${IO},IO_end=${IO} --ntasks-per-node=${PPN} --nodes=${NUM_NODES} --time=${TIME_VAR} --array=${ARRAY} archer2.slurm 
  done 

done 
