# strong scaling 

TIMES=("05:00:00" "05:00:00" "04:00:00" "04:00:00" "03:00:00" "02:00:00" "02:00:00") 

echo $DIR 

NX_LOCAL=$((${NX} * 2)) # multiplying by 2 cos strong scaling halves the array for remainder 0.  
NY_LOCAL=${NY}
NZ_LOCAL=${NZ}

iter=0 # counter that increments and decides on which variables get halved. 
# iterate through number of nodes 
for i in $(seq ${NODE_START} ${NODE_END}) # 1 till 16 nodes 
do 
  # check if TIME variable is set from runscript. If not then set it from the array. 
  if [[ -n $TIME ]];
  then 
    TIME_VAR=${TIME} 
  else
    TIME_VAR=${TIMES[${iter}]} 
  fi 

  # get local values from the global specified for the number of nodes given. 
  # balance arrays so that no array is less than 16
  NUM_NODES=$((2**${i}))

  if [[ $(( $iter % 3)) == 0 ]] ; 
  then 
    NX_LOCAL=$((${NX_LOCAL}/2)) 
  fi 
  if [[ $(( $iter % 3)) == 1 ]] ; 
  then 
    NY_LOCAL=$((${NY_LOCAL}/2)) 
  fi 
  if [[ $(( $iter % 3)) == 2 ]] ; 
  then 
    NZ_LOCAL=$((${NZ_LOCAL}/2)) 
  fi 
  
  ((iter++))
  FILESIZE_GLOBAL=$((${NX} * ${NY} * ${NZ} * 8 * 128/ 2**20)) 
  FILESIZE_LOCAL=$((${NX_LOCAL} * ${NY_LOCAL} * ${NZ_LOCAL} * 8/ 2**10)) 
  echo NODES ${NUM_NODES} ARRAY SIZE ${NX_LOCAL} x ${NY_LOCAL} x ${NZ_LOCAL} Local size ${FILESIZE_LOCAL}KiB Global size ${FILESIZE_GLOBAL}MiB JOB ARRAY ${ARRAY} TIME ${TIME_VAR} IO ${IO_START} to ${IO_END} 

  sbatch --export=ALL,SIZE=${SIZE_LOCAL},NX=${NX_LOCAL},NY=${NY_LOCAL},NZ=${NZ_LOCAL},DIR=${DIR},IO_START=${IO_START},IO_END=${IO_END},FLAG=${FLAG} --qos=standard --nodes=${NUM_NODES} --ntasks-per-node=${PPN} --time=${TIME_VAR} --array=${ARRAY}  archer2.slurm 
done 

