# bash script to call different kinds of scaling scripts for archer2 job submissions. 
callWeakScaling () {
  (
    export PPN=128
    export NX=$((2**6))
    export NY=$((2**7)) 
    export NZ=$((2**7)) 
    export NODE_START=0
    export NODE_END=3
    export IO_START=0
    export IO_END=3
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
    #export NX=$((2**6))
    #export NY=$((2**7)) 
    #export NZ=$((2**7)) 
    export NODE_START=0
    export NODE_END=1
    export IO_START=0
    export IO_END=0
    export ARRAY="0"
    export TIME="00:10:00"
    export DIR=$(pwd)/TEST 
    export MAP=0
    export WAIT=""
    export DARSHAN=0
    sh ./weakScaling.sh
  )
} 

callMAP() {
  (
    export PPN=128
    export NX=$((2**5))
    export NY=$((2**4)) 
    export NZ=$((2**5)) 
    export NODE_START=4
    export NODE_END=4
    export ARRAY="0"
    export TIME="00:20:00"
    export DIR=MAP_PROFILES/STRONG # or weak 
    export MAP=1
    # loop over IO layers for MAP from 0 to 3 
    
    for io in 0 1 3 
    # for io in $(seq 3 3)
    do 
      export IO_START=${io}
      export IO_END=${io} 
      # loop over cases 1 by 1 for MAP # from 1 - 5 
      for case in $(seq 1 5)
      do 
        export CASE_START=${case}
        export CASE_END=${case}
        sh ./weakScaling.sh
      done 
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
