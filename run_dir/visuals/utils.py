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
import fnmatch
# import seaborn as sns
# import seaborn.objects as so

localSize = 0.8
ranks = 4
plt.style.use("style.mplstyle")  # matplotlib style sheet

"""
select mapping
"""
slurmMappingList = [
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
    for coreSize in dir_list:
        core = coreSize.split("_",1)[1] # hardcoded value of only 1 node used 

        """
        Iterate over array sizes 
        """
        data_array = {} 
        array_list = next(os.walk(f"{parentDir}/{coreSize}"))[1]
        for arraySize in array_list: 

            layer_list = next(os.walk(f"{parentDir}/{coreSize}/{arraySize}"))[1]

            """
            Iterate over I/O layers 
            """
            data_io = {} # dictionary for I/O stuff 
            for ioLayer in layer_list: 

                """
                Iterate over slurm mappings 
                """
                data_mapping = {} 
                slurm_list = next(os.walk(f"{parentDir}/{coreSize}/{arraySize}/{ioLayer}"))[1]
                for slurmMapping in slurm_list: 

                    """
                    Iterate over job arrays 
                    """
                    avg = {} 
                    for jobIter in range(3): 
                        
                        filename = f"{parentDir}/{coreSize}/{arraySize}/{ioLayer}/{slurmMapping}/{jobIter}/iocomp_timers.txt"

                        """
                        Total data taken 
                        """
                        for file in os.listdir(f"{parentDir}/{coreSize}/{arraySize}/{ioLayer}/{slurmMapping}/{jobIter}"):
                            if fnmatch.fnmatch(file,"HPCG-Benchmark*.txt"):
                                print(file)

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
    
    return(data)

    
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

"""
plot function 
"""
def plot_HPCG(data):

    coreSize = "2"
    arraySize = "16"
    slurmMapping = "Hyperthread"
    ioLayer = "MPIIO"

    x = data[coreSize][arraySize][ioLayer][slurmMapping]
    print(x)


"""
effective HPCG bandwidth obtained by total data/ total time taken 
"""
def effectiveBW_HPCG(data):
    totalDataSize = 0.00292909
    fig1, ax1 = plt.subplots(2, 2,figsize=(10,8),sharey=True)
    
    coreSizeList = ["2"] 
    arraySize = "16"
     
    ioLayerList = [
        "MPIIO",
        "HDF5", 
        "ADIOS2_BP4",
        "ADIOS2_BP5"
    ] 
    
    width_=0.4
    ioLayer_count = 0

    """
    bar plot, x axis = core count, y axis = effective B/W, bar plots shown  
    """
    for ioLayer in ioLayerList: 
        
        slurm_count = 0

        for slurmMapping in slurmMappingList:
            
            core_count = 0

            for coreSize in coreSizeList:
                
                loopTime = data[coreSize][arraySize][ioLayer][slurmMapping]["loopTime"]
                i=int(ioLayer_count/2)
                j=int(ioLayer_count%2)
                bw = (totalDataSize/loopTime) 
                ax1[i,j].bar(slurm_count*width_ + core_count , bw,width=width_, color=mapping_colour[slurmMapping],capsize=10)
                core_count = core_count + 1 
            
            slurm_count = slurm_count+1

        ioLayer_count = ioLayer_count+1 # sub plots are divided per ioLayer 

    """
    ticks for each subplot
    """
    for x in range(4):
        i = int(x/2)
        j = int(x%2)
        ax1[i,j].set_xticks(np.arange(len(coreSizeList))+width_*len(slurmMappingList)/2-width_/2) 
        ax1[i,j].set_xticklabels(coreSizeList)
        ax1[i,j].title.set_text(ioLayerList[x])
        ax1[i,j].set_yscale('log')

        for key, value in mapping_colour.items():
            ax1[i,j].bar(x=0,height=0,label = key,color = value) # dummy plots to label compute and total time

    fig1.supxlabel('Number of compute processes')
    fig1.supylabel('Effective average memory bandwidth (GB/s)')
    ax1[0,0].legend() # legend only in 1st quad
    fig1.tight_layout() 
    # plt.rcParams['grid.alpha'] = 0.5 # grid lines bit less visible
    # plt.rcParams['grid.linewidth'] = 0.1 # grid lines bit less visible
    plt.show() 
    # if (name == None):
    #     name = "STREAM_BW"
    # saveName = f"{name}_{datetime.now().strftime('%d,%m,%Y,%H,%M')}"
    # save_or_show(saveName,flag,plt,data)

    
