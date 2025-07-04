from functions import *
import os
import json
pvec = os.environ.get("pvec")
nsample = os.environ.get("nsample")
folder = os.path.join(os.path.dirname(__file__), "data")

for file in os.listdir(folder):
    if os.path.isfile(os.path.join(folder, file)):
        run_benchmark(os.path.join(folder, file),json.loads(pvec),int(nsample),os.path.join(os.path.dirname(__file__),"..","data","result","ldpc"),os.path.join(os.path.dirname(__file__),"..","data","depolarizing"),os.path.splitext(file)[0])