from functions import *
import os
import json
import numpy as np
pvec = os.environ.get("pvec")
nsample = os.environ.get("nsample")
folder = os.path.join(os.path.dirname(__file__), "data")

pvec = eval(pvec)
if isinstance(pvec, np.ndarray):
    pvec = pvec.tolist()
    
def process_all_files(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            file_path = os.path.join(root, file)
            # Get relative path from the data folder for the output name
            rel_path = os.path.relpath(file_path, folder)
            output_name = os.path.splitext(rel_path)[0]
            run_benchmark(file_path, pvec, int(nsample), os.path.join(os.path.dirname(__file__),"..","data","result","ldpc"), os.path.join(os.path.dirname(__file__),"..","data","depolarizing"), output_name)

process_all_files(folder)