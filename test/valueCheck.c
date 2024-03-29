#include <math.h>
#include "test.h"
int valueCheck(struct iocomp_params *iocompParams, double* iodata_test, double val, char* filename)
{
	int test = 1; 
	double toleranceVal = pow(10,-10); 
	for(int i = 0; i < iocompParams->localDataSize; i++)
	{
		if( abs( iodata_test[i] - val ) > toleranceVal)
		{
			printf("Verification failed for index %i for filename %s, read data=%lf, correct val=%lf \n", 
					i, filename, iodata_test[i], val); 
			test = 0; 
			break; 
		}
	} 
	return(test); 
} 
