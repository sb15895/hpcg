# set -euo pipefail # error handling for bash 
export RUNDIR=TEST
export EXE=$(cd ../ && echo $(pwd))/build/bin/xhpcg

if [ -d ${RUNDIR} ]; then 
	rm -rf ${RUNDIR}
fi 
mkdir ${RUNDIR}
cp config.xml ${RUNDIR}
cd ${RUNDIR} 

if [[ ${1} == 'shm' ]]; then
	echo 'Selecting SHM mode'
	SHARED=1
	HT=0
elif [[ ${1} == 'mp' ]]; then 
	echo 'Selecting MP mode'
	SHARED=0
	HT=1
elif [[ ${1} == 'seq' ]]; then 
	echo 'Selecting default mode'
	SHARED=0
	HT=0
else
	echo 'invalid value for mode'
	exit 
fi 

if [ -n $2 ]; then 
	IO=$2
else 
	IO=0
fi 

NX=16
NY=16
NZ=16
echo IO selected $IO 
mpirun.mpich -n 2 ${EXE}  --nx=${NX} --ny=${NY} --nz=${NZ}\
	--io=${IO} --sh=${SHARED} --HT=${HT}
