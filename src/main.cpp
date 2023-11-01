
//@HEADER
// ***************************************************
//
// HPCG: High Performance Conjugate Gradient Benchmark
//
// Contact:
// Michael A. Heroux ( maherou@sandia.gov)
// Jack Dongarra     (dongarra@eecs.utk.edu)
// Piotr Luszczek    (luszczek@eecs.utk.edu)
//
// ***************************************************
//@HEADER

/*!
	@file main.cpp

	HPCG routine
 */

// Main routine of a program that calls the HPCG conjugate gradient
// solver to solve the problem, and then prints results.

#ifndef HPCG_NO_MPI
#include <mpi.h>
#endif

#include <fstream>
#include <iostream>
#include <cstdlib>
#ifdef HPCG_DETAILED_DEBUG
using std::cin;
#endif
using std::endl;

#include <vector>

#include "hpcg.hpp"

#include "CheckAspectRatio.hpp"
#include "GenerateGeometry.hpp"
#include "GenerateProblem.hpp"
#include "GenerateCoarseProblem.hpp"
#include "SetupHalo.hpp"
#include "CheckProblem.hpp"
#include "ExchangeHalo.hpp"
#include "OptimizeProblem.hpp"
#include "WriteProblem.hpp"
#include "ReportResults.hpp"
#include "mytimer.hpp"
#include "ComputeSPMV_ref.hpp"
#include "ComputeMG_ref.hpp"
#include "ComputeResidual.hpp"
#include "CG.hpp"
#include "CG_ref.hpp"
#include "Geometry.hpp"
#include "SparseMatrix.hpp"
#include "Vector.hpp"
#include "CGData.hpp"
#include "TestCG.hpp"
#include "TestSymmetry.hpp"
#include "TestNorms.hpp"
#include "adios2_c.h"

#define MAXITER 1 // arbitrary value to set number of compute loops
#define SIZE_PER_ROW 27 // value according to generateProblem.cpp 
// Addition of iocomp header files 
/*!
	Main driver program: Construct synthetic problem, run V&V tests, compute benchmark parameters, run benchmark, report results.

	@param[in]  argc Standard argument count.  Should equal 1 (no arguments passed in) or 4 (nx, ny, nz passed in)
	@param[in]  argv Standard argument array.  If argc==1, argv is unused.  If argc==4, argv[1], argv[2], argv[3] will be interpreted as nx, ny, nz, resp.

	@return Returns zero on success and a non-zero value otherwise.

 */
int main(int argc, char * argv[]) {
	// iocomp - wall time starts, ends definition 
	double walltimeStart, walltimeEnd; 
#ifndef HPCG_NO_MPI
	MPI_Init(&argc, &argv);
#endif

	walltimeStart = MPI_Wtime(); 

	MPI_Comm globalComm; // replace every MPI_COMM_WORLD with comm  
	MPI_Comm_dup(MPI_COMM_WORLD, &globalComm); 

	HPCG_Params params;

	/* iocomp -> initialisation of iocompParams */ 
	struct iocomp_params iocompParams; // iocomp -> struct declared 
	HPCG_Init(&argc, &argv, params, &iocompParams, globalComm); // HPCG init contains iocomp init functions, and ioServerinitialiser.  
	MPI_Comm comm = iocompParams.compServerComm; // assign computeServerComm to the communicator 

	local_int_t nx,ny,nz;
	
	nx = (local_int_t)params.nx;
	ny = (local_int_t)params.ny;
	nz = (local_int_t)params.nz;

	// Check if QuickPath option is enabled.
	// If the running time is set to zero, we minimize all paths through the program
	bool quickPath = (params.runningTime==0);

	int size = params.comm_size, rank = params.comm_rank; // Number of MPI processes, My process ID


#ifdef HPCG_DETAILED_DEBUG
	if (size < 100 && rank==0) HPCG_fout << "Process "<<rank<<" of "<<size<<" is alive with " << params.numThreads << " threads." <<endl;

	if (rank==0) {
		char c;
		std::cout << "Press key to continue"<< std::endl;
		std::cin.get(c);
	}
#ifndef HPCG_NO_MPI
	MPI_Barrier(comm);
#endif
#endif

	int ierr = 0;  // Used to check return codes on function calls


	ierr = CheckAspectRatio(0.125, nx, ny, nz, "local problem", rank==0, comm);
	if (ierr)
		return ierr;

	/////////////////////////
	// Problem setup Phase //
	/////////////////////////

#ifdef HPCG_DEBUG
	double t1 = mytimer();
#endif

	// Construct the geometry and linear system
	Geometry * geom = new Geometry;
	GenerateGeometry(size, rank, params.numThreads, params.pz, params.zl, params.zu, nx, ny, nz, params.npx, params.npy, params.npz, geom);

	ierr = CheckAspectRatio(0.125, geom->npx, geom->npy, geom->npz, "process grid", rank==0, comm);
	if (ierr)
		return ierr;

	// Use this array for collecting timing information
	std::vector< double > times(10,0.0);

	double setup_time = mytimer();

	SparseMatrix A;
	InitializeSparseMatrix(A, geom, comm);

	Vector b, x, xexact;
	GenerateProblem(A, &b, &x, &xexact, &iocompParams);
	SetupHalo(A);
	int numberOfMgLevels = 4; // Number of levels including first
	SparseMatrix * curLevelMatrix = &A;
	for (int level = 1; level< numberOfMgLevels; ++level) {
		GenerateCoarseProblem(*curLevelMatrix);
		curLevelMatrix = curLevelMatrix->Ac; // Make the just-constructed coarse grid the next level
	}

	setup_time = mytimer() - setup_time; // Capture total time of setup
	times[9] = setup_time; // Save it for reporting

	curLevelMatrix = &A;
	Vector * curb = &b;
	Vector * curx = &x;
	Vector * curxexact = &xexact;
	for (int level = 0; level< numberOfMgLevels; ++level) {
		CheckProblem(*curLevelMatrix, curb, curx, curxexact, comm);
		curLevelMatrix = curLevelMatrix->Ac; // Make the nextcoarse grid the next level
		curb = 0; // No vectors after the top level
		curx = 0;
		curxexact = 0;
	}


	CGData data;
	InitializeSparseCGData(A, data);



	////////////////////////////////////
	// Reference SpMV+MG Timing Phase //
	////////////////////////////////////

	// Call Reference SpMV and MG. Compute Optimization time as ratio of times in these routines

	local_int_t nrow = A.localNumberOfRows;
	local_int_t ncol = A.localNumberOfColumns;

	Vector x_overlap, b_computed;
	InitializeVector(x_overlap, ncol, NULL); // Overlapped copy of x vector
	InitializeVector(b_computed, nrow, NULL); // Computed RHS vector


	// Record execution time of reference SpMV and MG kernels for reporting times
	// First load vector with random values
	FillRandomVector(x_overlap);

	int numberOfCalls = 10;
	if (quickPath) numberOfCalls = 1; //QuickPath means we do on one call of each block of repetitive code
	double t_begin = mytimer();
	for (int i=0; i< numberOfCalls; ++i) {
		ierr = ComputeSPMV_ref(A, x_overlap, b_computed); // b_computed = A*x_overlap
		if (ierr) HPCG_fout << "Error in call to SpMV: " << ierr << ".\n" << endl;
		ierr = ComputeMG_ref(A, b_computed, x_overlap); // b_computed = Minv*y_overlap
		if (ierr) HPCG_fout << "Error in call to MG: " << ierr << ".\n" << endl;
	}
	times[8] = (mytimer() - t_begin)/((double) numberOfCalls);  // Total time divided by number of calls.
#ifdef HPCG_DEBUG
	if (rank==0) HPCG_fout << "Total SpMV+MG timing phase execution time in main (sec) = " << mytimer() - t1 << endl;
#endif

	///////////////////////////////
	// Reference CG Timing Phase //
	///////////////////////////////

#ifdef HPCG_DEBUG
	t1 = mytimer();
#endif
	int global_failure = 0; // assume all is well: no failures

	int niters = 0;
	int totalNiters_ref = 0;
	double normr = 0.0;
	double normr0 = 0.0;
	int refMaxIters = 50;
	numberOfCalls = 1; // Only need to run the residual reduction analysis once

	// Compute the residual reduction for the natural ordering and reference kernels
	std::vector< double > ref_times(9,0.0);
	double tolerance = 0.0; // Set tolerance to zero to make all runs do maxIters iterations
	int err_count = 0;
	for (int i=0; i< numberOfCalls; ++i) {
		ZeroVector(x);
		ierr = CG_ref( A, data, b, x, refMaxIters, tolerance, niters, normr, normr0, &ref_times[0], true);
		if (ierr) ++err_count; // count the number of errors in CG
		totalNiters_ref += niters;
	}
	if (rank == 0 && err_count) HPCG_fout << err_count << " error(s) in call(s) to reference CG." << endl;
	double refTolerance = normr / normr0;

	// Call user-tunable set up function.
	double t7 = mytimer();
	OptimizeProblem(A, data, b, x, xexact);
	t7 = mytimer() - t7;
	times[7] = t7;
#ifdef HPCG_DEBUG
	if (rank==0) HPCG_fout << "Total problem setup time in main (sec) = " << mytimer() - t1 << endl;
#endif

#ifdef HPCG_DETAILED_DEBUG
	if (geom->size == 1) WriteProblem(*geom, A, b, x, xexact);
#endif


	//////////////////////////////
	// Validation Testing Phase //
	//////////////////////////////

#ifdef HPCG_DEBUG
	t1 = mytimer();
#endif
	TestCGData testcg_data;
	testcg_data.count_pass = testcg_data.count_fail = 0;
	TestCG(A, data, b, x, testcg_data);

	TestSymmetryData testsymmetry_data;
	TestSymmetry(A, b, xexact, testsymmetry_data);

#ifdef HPCG_DEBUG
	if (rank==0) HPCG_fout << "Total validation (TestCG and TestSymmetry) execution time in main (sec) = " << mytimer() - t1 << endl;
#endif

#ifdef HPCG_DEBUG
	t1 = mytimer();
#endif

	//////////////////////////////
	// Optimized CG Setup Phase //
	//////////////////////////////

	niters = 0;
	normr = 0.0;
	normr0 = 0.0;
	err_count = 0;
	int tolerance_failures = 0;

	int optMaxIters = 10*refMaxIters;
	int optNiters = refMaxIters;
	double opt_worst_time = 0.0;

	std::vector< double > opt_times(9,0.0);

	// Compute the residual reduction and residual count for the user ordering and optimized kernels.
	for (int i=0; i< numberOfCalls; ++i) {
		ZeroVector(x); // start x at all zeros
		double last_cummulative_time = opt_times[0];
		ierr = CG( A, data, b, x, optMaxIters, refTolerance, niters, normr, normr0, &opt_times[0], true);
		if (ierr) ++err_count; // count the number of errors in CG
		if (normr / normr0 > refTolerance) ++tolerance_failures; // the number of failures to reduce residual

		// pick the largest number of iterations to guarantee convergence
		if (niters > optNiters) optNiters = niters;

		double current_time = opt_times[0] - last_cummulative_time;
		if (current_time > opt_worst_time) opt_worst_time = current_time;
	}

#ifndef HPCG_NO_MPI
	// Get the absolute worst time across all MPI ranks (time in CG can be different)
	double local_opt_worst_time = opt_worst_time;
	MPI_Allreduce(&local_opt_worst_time, &opt_worst_time, 1, MPI_DOUBLE, MPI_MAX, comm);
#endif


	if (rank == 0 && err_count) HPCG_fout << err_count << " error(s) in call(s) to optimized CG." << endl;
	if (tolerance_failures) {
		global_failure = 1;
		if (rank == 0)
			HPCG_fout << "Failed to reduce the residual " << tolerance_failures << " times." << endl;
	}

	///////////////////////////////
	// Optimized CG Timing Phase //
	///////////////////////////////

	// Here we finally run the benchmark phase
	// The variable total_runtime is the target benchmark execution time in seconds

	double total_runtime = params.runningTime;
	//int numberOfCgSets = int(total_runtime / opt_worst_time) + 1; // Run at least once, account for rounding
	int numberOfCgSets = MAXITER; // set value as 10 


#ifdef HPCG_DEBUG
	if (rank==0) {
		HPCG_fout << "Projected running time: " << total_runtime << " seconds" << endl;
		HPCG_fout << "Number of CG sets: " << numberOfCgSets << endl;
	}
#endif

	/* This is the timed run for a specified amount of time. */

	optMaxIters = optNiters;
	double optTolerance = 0.0;  // Force optMaxIters iterations
	TestNormsData testnorms_data;
	testnorms_data.samples = numberOfCgSets;
	testnorms_data.values = new double[numberOfCgSets];

	/* iocomp - define variables */ 
	double loopTime[numberOfCgSets]; 
	double waitTime[numberOfCgSets]; 
	double compTime[numberOfCgSets]; 
	double sendTime[numberOfCgSets]; 
	double wallTime; 
	MPI_Request requestMatrix; 
	
	char fileName[50]; // to avoid the C++ to C const char[] to char* warning 

	for (int i=0; i< numberOfCgSets; ++i) {
		loopTime[i] = MPI_Wtime(); // iocomp - start loop timer 	

		// iocomp - activate windows in case of shared memory 
		winActivateInfo(&iocompParams, x.values); 
		snprintf(fileName, sizeof(fileName), "x_%i", i); 
		preDataSend(&iocompParams, x.values, fileName); 

		// HPCG compute loop and record compute time 
		compTime[i] = MPI_Wtime(); // iocomp - start computational timer 
		ZeroVector(x); // Zero out x
		
		ierr = CG( A, data, b, x, optMaxIters, optTolerance, niters, normr, normr0, &times[0], true);
		compTime[i] = MPI_Wtime() - compTime[i];  

		// iocomp - send data/post win complete and record times send times
		sendTime[i] = MPI_Wtime();  
		dataSend(x.values, &iocompParams, &requestMatrix, nrow); 
		sendTime[i] = MPI_Wtime() - sendTime[i];  
	
		if (ierr) HPCG_fout << "Error in call to CG: " << ierr << ".\n" << endl;

		if (rank==0) HPCG_fout << "Call [" << i << "] Scaled Residual [" << normr/normr0 << "]" << endl;
		testnorms_data.values[i] = normr/normr0; // Record scaled residual from this run

		// iocomp - test data sends
		dataSendTest(&iocompParams, &requestMatrix, x.values);   
		winTestInfo(&iocompParams, x.values);
		dataSendInfo(&iocompParams); 

		// iocomp - wait for matrix data to be sent fully and record timers
		waitTime[i] = MPI_Wtime();  
		dataWait(&iocompParams,&requestMatrix, x.values, fileName);  
		dataSendInfo(&iocompParams); 
		waitTime[i] = MPI_Wtime() - waitTime[i]; // iocomp - end wait timer 

		loopTime[i] = MPI_Wtime() - loopTime[i]; // iocomp - loop timer end 
	}

	// All processors are needed here.
#ifdef HPCG_DEBUG
	double residual = 0;
	ierr = ComputeResidual(A.localNumberOfRows, x, xexact, residual);
	if (ierr) HPCG_fout << "Error in call to compute_residual: " << ierr << ".\n" << endl;
	if (rank==0) HPCG_fout << "Difference between computed and exact  = " << residual << ".\n" << endl;
#endif

	// Test Norm Results
	ierr = TestNorms(testnorms_data);

	/* Send data from computeServer to ioServerComm */ 
	stopSend(&iocompParams); // send ghost message to stop MPI_Recvs 
	wallTime = MPI_Wtime() - walltimeStart; // calculate wall time after finalising io servers 
	
	// dealloc superMatrix NA to shared Mem 
	// free(superMatrix); 
	// superMatrix = NULL; 


	/*
	 * MPI Reduction for timers 
	 */ 
	// inits
	double loopTime_Reduced[numberOfCgSets]; 
	double waitTime_Reduced[numberOfCgSets]; 
	double compTime_Reduced[numberOfCgSets]; 
	double sendTime_Reduced[numberOfCgSets]; 
	double wallTime_Reduced; 
	// MPI reduce operations 	
	MPI_Reduce(loopTime,loopTime_Reduced, numberOfCgSets, MPI_DOUBLE, MPI_MAX, 0, comm);  
	MPI_Reduce(compTime,compTime_Reduced, numberOfCgSets, MPI_DOUBLE, MPI_MAX, 0, comm);  
	MPI_Reduce(sendTime,sendTime_Reduced, numberOfCgSets, MPI_DOUBLE, MPI_MAX, 0, comm);  
	MPI_Reduce(waitTime,waitTime_Reduced, numberOfCgSets, MPI_DOUBLE, MPI_MAX, 0, comm);  
	MPI_Reduce(&wallTime,&wallTime_Reduced, 1, MPI_DOUBLE, MPI_MAX, 0, comm);  


	/* iocomp - open and write to file by rank 0 */ 
	if(rank == 0)
	{
		std::ofstream myfile;
		myfile.open ("iocomp_timers.csv"); 
		myfile<<"iter,loopTime(s),compTime(s),sendTime(s),waitTime(s),wallTime(s)"<<endl; 
		for (int i=0; i< numberOfCgSets; ++i) {
			myfile<<i<<","<<loopTime_Reduced[i]<<","<<compTime_Reduced[i]<<","<<sendTime_Reduced[i]<<","<<waitTime_Reduced[i]<<","<<wallTime_Reduced<<endl; //iocomp - write to text file 
		} 
		/* iocomp - close file  */ 
		myfile.close(); 
	}

	////////////////////
	// Report Results //
	////////////////////

	// Report results to YAML file
	ReportResults(A, numberOfMgLevels, numberOfCgSets, refMaxIters, optMaxIters, &times[0], testcg_data, testsymmetry_data, testnorms_data, global_failure, quickPath);

	// Clean up
	DeleteMatrix(A); // This delete will recursively delete all coarse grid data
	DeleteCGData(data);
	DeleteVector(x, &iocompParams); // overloaded function to finalise windows if shared windows used.
	DeleteVector(b);
	DeleteVector(xexact);
	DeleteVector(x_overlap);
	DeleteVector(b_computed);
	delete [] testnorms_data.values;

	HPCG_Finalize();
	printf("after HPCG finalise \n"); 
	
#ifndef HPCG_NO_MPI
	MPI_Finalize();
#endif
	return 0;
}
