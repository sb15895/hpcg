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
    data_io = {} # dictionary for I/O stuff 
    for core_size in dir_list:
        core = core_size.split("_",1)[1] # hardcoded value of only 1 node used 
        layer_list = next(os.walk(f"{parentDir}/{core_size}"))[1]
        
        """
        Iterate over I/O layers 
        """
        for ioLayer in layer_list: 

            filename = f"{parentDir}/{core_size}/{ioLayer}/iocomp_timers.txt"

            """
            read info from text file 
            and convert into PD dictionary 
            """ 
            mydata = pd.read_csv(filename,index_col=False,skiprows=0) 

            """
            average times 
            """
            avg = {} 
            avg = average_function(mydata) 

            """
            add data per I/O layer
            """
            data_io[filename] = avg 
        
        """
        add data per core size 
        """
        data[core] = data_io

    print(data)

    

def average_function(mydata): 

    loopTime_avg = mydata['loopTime(s)'].mean() 
    waitTime_avg = mydata[' waitTime(s)'].mean() 
    compTime_avg = mydata['compTime(s)'].mean() 
    avg = {}
    avg[loopTime_avg] = loopTime_avg
    avg[waitTime_avg] = waitTime_avg
    avg[compTime_avg] = compTime_avg
    return(avg) 









    
