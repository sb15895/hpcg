#include <stdio.h>
#include <mpi.h>
#include <stdlib.h>  
#include <string.h> 
#include <assert.h> 
#include <math.h>
#include "test.h"

void HPCG_tests(struct test_params *testParams, struct iocomp_params *iocompParams,  MPI_Comm comm)
{ 
	int myRank; 
	MPI_Comm_rank(comm, &myRank); 
	double sol;

	int passed, failed; 
	passed = 0; 
	failed = 0; 

	// initialise data buffer to store data read locally 
	double* read_ptr = NULL; 

	// Initialise 
	sol = 1.0; // expected solution

	// filenames for the different windows 
	char readFile[100]; 

	char ext[5][10] = {".dat", ".h5", ".h5", "", ""}; 

	for(int iter = 0; iter < AVGLOOPCOUNT; iter++)
	{
		snprintf(readFile, sizeof(readFile), "x_%i%s",iter, ext[testParams->io]);

		if( (myRank==0) && (testParams->verbose==true) ){
			printf("Verification tests starting for filename %s \n", readFile); 
		} 
		// read data from readFile  
		read_ptr = readFiles(testParams, iocompParams, readFile); 
		if(read_ptr == NULL)
		{
			if( (myRank==0) && (testParams->verbose==true) ){
				printf("Filename %s does not exist. \n", readFile); 
			} 
			failed++; 
			break; 
		} 

		// verify data by checking value by value with STREAM code simulator,
		// value returned tells if the tests passed 
		int test = valueCheck(iocompParams, read_ptr, sol, readFile); 

		// sync all values of test, if multiplication comes back as 0 it means
		// verification failed by a particular rank 
		int test_reduced = 0; 
		MPI_Reduce(&test, &test_reduced, 1, MPI_INT, MPI_PROD, 0, comm); 

		// if all processes return true then verification passes. 
		if(test_reduced == 0)
		{
			if( (myRank==0) && (testParams->verbose==true) )
			{	
				printf("Verification failed for filename %s \n", readFile); 
			} 
			failed++; 
		} 
		else
		{
			if( (myRank==0) && (testParams->verbose==true) )
			{	
				printf("Verification passed for filename %s \n", readFile); 
			} 
			passed++; 
		}
#ifndef NODELETE
		if(myRank==0) 
		{
			if(testParams->verbose==true)
			{	
				printf("Deleting file %s \n", readFile); 
			} 
			deleteFilesTest(readFile); 
		} 
		MPI_Barrier(comm); 
#endif 
	} 

	free(read_ptr); 
	read_ptr = NULL; 
	if(!myRank) {
		printf("Verification tests finished. %i tests passed and %i tests failed. \n", passed, failed); 
	} 
} 
