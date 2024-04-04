export HPCG_DIR=$(echo $(cd ../ && pwd)) 
export HPCG_EXE=${HPCG_DIR}/build/bin/xhpcg
export CONFIG=${HPCG_DIR}/run_dir/config.xml
export TEST_EXE=${HPCG_DIR}/test/test
export TEST_PARENT_DIR=${HPCG_DIR}/test
echo ${TEST_EXE} 

setup() {
	rm -rf ${TEST_DIR} 
	mkdir -p ${TEST_DIR} 
	cd ${TEST_DIR} 
	cp ${CONFIG} . 
	# echo Testing in directory:; echo ${TEST_DIR} 
} 

weakscaling() {
	for CORES in $(seq ${CORES_START} 2 ${CORES_END});
	do 
		for i in $(seq ${ARRAY_START} ${ARRAY_END});
		do 
			NX=$((2**${i})) 
			NY=$((2**${i})) 
			NZ=$((2**${i})) 

			for IO in $(seq ${IO_START} ${IO_END});
			do	
				if [ -z ${FLAG} ]; then 
					export FLAG_DIR='NOSPLIT' 
					NX_TEST=${NX}
				else
					export FLAG_DIR=${FLAG}
					NX_TEST=$((${NX}/2))
				fi 
				TEST_DIR=${TEST_PARENT_DIR}/${FLAG_DIR}/${CORES}/${NX}/${NY}/${IO}
				echo "Testing for ${CORES} cores, array size ${NX} x ${NY} x ${NZ} IO lib ${IO} for $FLAG_DIR configuration"
				echo DIRECTORY: 
				echo $TEST_DIR
				echo "" 
				setup
				mpirun.mpich -n ${CORES} ${HPCG_EXE} --nx=${NX} --ny=${NY} --nz=${NZ} --io=${IO} --HT=${HT_VAL} --sh=${SH_VAL}
				echo "" 
				sleep 2
				# if flag activated then only half ranks are writing and global size is
				# also halved. 
				mpirun.mpich -n ${CORES} ${TEST_EXE} --nx ${NX_TEST} --ny ${NY} --nz ${NZ} --io ${IO} --v 
				echo "" 
				sleep 2
			done 
		done
	done 
} 

# MPI cores
CORES_START=4
CORES_END=4

# controls NX, NY, NZ parameters
ARRAY_START=2
ARRAY_END=2

# IO libraries selection 
IO_START=0
IO_END=0

#echo "Testing no split case ..."
#HT_VAL=0
#SH_VAL=0
#weakscaling
#
#echo "Testing message copy case ..."
#FLAG=HT
#HT_VAL=1
#SH_VAL=0
#weakscaling 

echo "Testing shared case ..."
FLAG=shared
HT_VAL=0
SH_VAL=1
weakscaling 
