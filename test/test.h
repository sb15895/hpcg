#include <mpi.h>
#include <stdbool.h>
#include <adios2_c.h>
#include <stdio.h>
#include <stdlib.h>  
#include <string.h> 
#include "iocomp.h"

#define KERNELS 1 
#define AVGLOOPCOUNT 10
#define NODESIZE 128
#define NUMWIN 1 

// test parameters structure 
struct test_params{
	int LOOP_COUNT; 
	// sizes
	size_t localDataSize; 
	size_t globalDataSize; 
	char* fullResults_filename[KERNELS]; 
	int writeFreq; // compute steps per writing
	int numWrites; // max number of writes  

	// command line args 
	bool HT_flag, sharedFlag, testFlag, verbose; 
	int nx, ny,nz, io; 

	// file object for debug 
	char debugFile[100]; 
	FILE* debug; 
}; 
extern struct test_params testParams; 

void arguments(struct test_params* testParams, int argc, char** argv); 
int valueCheck(struct iocomp_params *iocompParams, double* iodata_test, double val, char* filename); 
double* readFiles(struct test_params *testParams, struct iocomp_params *iocompParams, char* readFile); 
void HPCG_tests(struct test_params *testParams, struct iocomp_params *iocompParams,  MPI_Comm comm); 
bool file_exists (char *filename); 
void deleteFilesTest(char* fileName); 

