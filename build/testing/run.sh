# remove HPCG output text files 
rm *.txt 
# remove I/O output files
rm *.h5 
rm *.dat 
rm -rf x_*
# remove btr files
rm *.btr
# run code 
mpirun.mpich -n 2 ../bin/xhpcg --nx=16 --ny=16 --nz=16 --io=3 --sh=1

