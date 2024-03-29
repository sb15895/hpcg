TASKS_TEST=$(( ${NODES_TEST} * ${PPN_TEST} )) 
echo TESTING with ${NODES_TEST} nodes and ${TASKS_TEST} tasks ${PPN_TEST} tasks per node.
srun  --hint=nomultithread --distribution=block:block --nodes=${NODES_TEST} --ntasks-per-node=${PPN_TEST} --ntasks=${TASKS_TEST} ${TEST_EXE} --nx ${NX} --ny ${NY} --nz ${NZ} --io ${IO} >> test.out
