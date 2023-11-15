# strong scaling 

TIMES=("07:00:00" "07:00:00" "07:00:00" "08:00:00" "08:00:00" "08:00:00") 

echo $DIR 

# iterate through number of nodes 
for i in $(seq ${NODE_START} ${NODE_END}) # 1 till 16 nodes 
do 
  # check if TIME variable is set from runscript. If not then set it from the array. 
  if [[ -n $TIME ]];
  then 
    TIME_VAR=${TIME} 
  else
    TIME_VAR=${TIMES[${i}]} 
  fi 

  # get local values from the global specified for the number of nodes given 
  NUM_NODES=$((2**${i}))
  NX_LOCAL=$((${NX}/${NUM_NODES})) 
  FILESIZE_GLOBAL=$((${NX} * ${NY} * ${NZ} * 8 * 128/ 2**20)) 
  FILESIZE_LOCAL=$((${NX_LOCAL} * ${NY} * ${NZ} * 8/ 2**20)) 
  echo NODES ${NUM_NODES} ARRAY SIZE ${NX_LOCAL} x ${NY} x ${NZ} Local size ${FILESIZE_LOCAL}MiB Global size ${FILESIZE_GLOBAL}MiB JOB ARRAY ${ARRAY} TIME ${TIME_VAR} IO ${IO_START} to ${IO_END} 

  sbatch --export=ALL,SIZE=${SIZE_LOCAL},NX=${NX},NY=${NY},NZ=${NZ},DIR=${DIR},IO_START=${IO_START},IO_END=${IO_END},FLAG=${FLAG} --qos=standard --nodes=${NUM_NODES} --ntasks-per-node=${PPN} --time=${TIME_VAR} --array=${ARRAY}  archer2.slurm 
done 

