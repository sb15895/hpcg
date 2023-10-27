rm *.btr 
rm *.txt
rm *.h5 
rm *.dat
# mpirun.mpich -n 2 ../bin/xhpcg --nx=16 --ny=16 --nz=16 --io=1 --sh=0
# mpirun.mpich -n 2 ../bin/xhpcg --nx=16 --ny=16 --nz=16 --io=1 --sh=1
mpirun.mpich -n 2 ../bin/xhpcg --nx=16 --ny=16 --nz=16 --io=1 --HT=1
