# bash script to call different kinds of scaling scripts for archer2 job submissions. 
callWeakScaling () {
  (
    export PPN=128
    export NX=$((2**6))
    export NY=$((2**7)) 
    export NZ=$((2**7)) 
    export NODE_START=0
    export NODE_END=4
    export IO_START=2
    export IO_END=2
    export ARRAY="0-2"
    export TIME="04:00:00"
    export CASE_START=0
    export CASE_END=4
    export MAP=0
    export WAIT=""
    export DARSHAN=0
    export DIR=$(pwd)/OUTPUT/v2.1.0/WEAK/COL_WRT_DIS
    sh ./weakScaling.sh
  ) 
}

callStrongScaling () {
  (
    export PPN=128
    export NX=$((2**6))
    export NY=$((2**7)) 
    export NZ=$((2**7)) 
    export NODE_START=0
    export NODE_END=0
    export IO_START=0
    export IO_END=0
    export ARRAY="0"
    export TIME="00:10:00"
    export DIR=OUTPUT/v2.0.0/STRONG/GLOBALSIZE_8GB/100COMPUTE
    sh strongScaling.sh
  )
} 

callTest () {
  (
    export PPN=128
    export NX=$((2**5))
    export NY=$((2**5)) 
    export NZ=$((2**5)) 
    export NODE_START=3
    export NODE_END=3
    export IO_START=0
    export IO_END=0
    export ARRAY="0"
    export TIME="00:05:00"
    export MAP=1
    export WAIT="--wait"
    export DARSHAN=0
    export DIR=$(pwd)/TEST/ARM
    for CASE in $(seq 0 4)
    do 
      export CASE_START=${CASE}
      export CASE_END=${CASE}
      sh ./weakScaling.sh
    done 
  )
} 

callMAP() {
  (
    export PPN=128
    export NX=$((2**6))
    export NY=$((2**7)) 
    export NZ=$((2**7)) 
    export NODE_START=3
    export NODE_END=3
    export IO_START=0
    export IO_END=0
    export ARRAY="0"
    export TIME="00:30:00"
    export MAP=1
    export WAIT="--wait"
    export DARSHAN=0
    export DIR=$(pwd)/PROFILING/ARM_MAP/v2.1.0
    for CASE in $(seq 0 0)
    do 
      export CASE_START=${CASE}
      export CASE_END=${CASE}
      sh ./weakScaling.sh
    done 
  )
}

# Command line arguments 
if [[ $1 == 'map' ]]
then 
  callMAP
elif  [[ $1 == 'weak' ]]
then  
  callWeakScaling
elif  [[ $1 == 'strong' ]]
then
  callStrongScaling 
elif  [[ $1 == 'test' ]]
then
  callTest 
elif  [[ $1 == 'darshan' ]]
then
  callDARSHAN 
else
  echo 'Invalid argument' 
fi 
