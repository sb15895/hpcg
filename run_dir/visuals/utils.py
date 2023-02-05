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

def HPCG_iocomp_timers(path):


    """
    Iterate through sub directories to get the full path 
    """ 

    # filename = f'{path}/1_2/ADIOS2_BP4/iocomp_timers.txt'
    filename = '/Users/sbhardwa/Library/CloudStorage/OneDrive-UniversityofEdinburgh/Coding/hpcg/run_dir/4Feb/1_2/ADIOS2_BP4/iocomp_timers.txt'

    """
    read info from text file 
    and convert into PD dictionary 
    """ 

    mydata = pd.read_csv(filename,index_col=False,skiprows=0) 

    """
    average times 
    """

    average_function(mydata) 

    

def average_function(mydata): 

    loopTime_avg = mydata['loopTime(s)'].mean() 
    waitTime_avg = mydata[' waitTime(s)'].mean() 
    compTime_avg = mydata['compTime(s)'].mean() 








    
