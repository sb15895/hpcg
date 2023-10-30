rm *.csv *.out *.txt *.h5 *.dat 
rm -rf *.bp5 *.bp4
export HPCG_BIN=/home/shrey/Coding/hpcg/build/bin/xhpcg
export CONFIG=/home/shrey/Coding/hpcg/run_dir/config.xml
echo "Testing .. HT off" 
for i in {0..0}
do 
	export TESTDIR=/home/shrey/Coding/hpcg/run_dir/test/DIR/${i}
	rm -rf ${TESTDIR} 
	mkdir ${TESTDIR} 
	cd ${TESTDIR}  
	cp ${CONFIG} .  
	$OMPI_DIR/bin/mpirun -n 1 ${HPCG_BIN} --nx=16 --ny=16 --nz=16 --io=${i} #--HT
done 

#echo "Testing .. HT on" 
#for i in {0..0}
#do 
#	export TESTDIR=/home/shrey/Coding/hpcg/run_dir/test/ASYNC/${i}
#	rm -rf ${TESTDIR} 
#	mkdir ${TESTDIR} 
#	cd ${TESTDIR}  
#	cp ${CONFIG} .  
#	$OMPI_DIR/bin/mpirun -n 1 ${HPCG_BIN} --nx=32 --ny=16 --nz=16 --io=${i} --HT
#done 
