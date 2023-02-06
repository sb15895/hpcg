import matplotlib.pyplot as plt
from matplotlib.pyplot import cm
import pandas as pd
import numpy as np
import pathlib
import os
from glob import glob
from datetime import datetime
import statistics
import re 
import argparse
# import seaborn as sns
# import seaborn.objects as so

localSize = 0.8
ranks = 4
plt.style.use("style.mplstyle")  # matplotlib style sheet

"""
select mapping
"""
mapping = [
    "Consecutive",
    "Hyperthread",
    "Oversubscribe",
    "Sequential"
]


mapping_colour = {
    "Consecutive": "r",
    "Hyperthread": "b",
    "Oversubscribe": "g", 
    "Sequential": "c"
}

def HPCG_iocomp_timers(parentDir):

    """
    Iterate through parent dir to get list of cores 
    """
    dir_list = next(os.walk(parentDir))[1]
    data = {} # main dictionary initialised   

    """
    Iterate over core sizes
    """
    for core_size in dir_list:
        core = core_size.split("_",1)[1] # hardcoded value of only 1 node used 

        """
        Iterate over array sizes 
        """
        data_array = {} 
        array_list = next(os.walk(f"{parentDir}/{core_size}"))[1]
        for arraySize in array_list: 

            layer_list = next(os.walk(f"{parentDir}/{core_size}/{arraySize}"))[1]

            """
            Iterate over I/O layers 
            """
            data_io = {} # dictionary for I/O stuff 
            for ioLayer in layer_list: 

                """
                Iterate over slurm mappings 
                """
                data_mapping = {} 
                slurm_list = next(os.walk(f"{parentDir}/{core_size}/{arraySize}/{ioLayer}"))[1]
                for slurmMapping in slurm_list: 

                    """
                    Iterate over job arrays 
                    """
                    avg = {} 
                    for jobIter in range(3): 
                        
                        filename = f"{parentDir}/{core_size}/{arraySize}/{ioLayer}/{slurmMapping}/{jobIter}/iocomp_timers.txt"

                        """
                        read info from text file 
                        and convert into PD dictionary 
                        """ 
                        mydata = pd.read_csv(filename,index_col=False,skiprows=0) 

                        """
                        average times 
                        """
                        avg[jobIter] = average_function(mydata)
                    
                    """
                    Average over job array
                    add data per slurm mapping
                    """
                    data_mapping[slurmMapping] = average_jobs(avg)

                """
                add data per I/O layer
                """
                data_io[ioLayer] = data_mapping
            
            """
            add data per array size 
            """
            data_array[arraySize] = data_io

        """
        add data per core size 
        """
        data[core] = data_array
    
    print(data)


    
"""
average_function averages loop, wait and comp time per file 
"""
def average_function(mydata): 

    loopTime_avg = mydata['loopTime(s)'].mean() 
    waitTime_avg = mydata[' waitTime(s)'].mean() 
    compTime_avg = mydata['compTime(s)'].mean() 
    avg = {}
    avg["loopTime_avg"] = loopTime_avg
    avg["waitTime_avg"] = waitTime_avg
    avg["compTime_avg"] = compTime_avg
    return(avg) 

"""
average_jobs averages the average loop, wait and comp time over the array of jobs
"""

def average_jobs(avg): 

    loopTime_avg = 0 
    waitTime_avg = 0 
    compTime_avg = 0 

    avg_job = {} 

    for key, value in avg.items():
        # key will be 0,1,2 etc job array submissions
        
        loopTime_avg += avg[key]["loopTime_avg"] 
        waitTime_avg += avg[key]["waitTime_avg"] 
        compTime_avg += avg[key]["compTime_avg"] 
    
    avg_job["loopTime"] = loopTime_avg/3
    avg_job["waitTime"] = waitTime_avg/3
    avg_job["compTime"] = compTime_avg/3

    return(avg_job)








    
