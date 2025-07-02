import numpy as np
import json
from ldpc import BpOsdDecoder
import time
import os

def load_e(path):
    file = open(path, 'r')
    data = file.readlines()
    e = np.zeros((len(data),len(data[0].split())),dtype=np.uint8)
    for k in range(len(data)):
        e[k,:] = np.array(data[k].split(),dtype=np.uint8)
    file.close()
    return e

def load_code_data(path):
    data = json.loads(open(path).read())
    nq = data["qubit_num"]
    ns = data["stabilizer_num"]
    H = np.array(data["pcm"])
    H = H.reshape(2*nq,ns).T
    lx = np.array(data["logical_x"]).reshape(-1,nq)
    lz = np.array(data["logical_z"]).reshape(-1,nq)

    nl = lx.shape[0]
    l = np.concatenate((np.concatenate((np.zeros((nl,nq),dtype=int),lz),axis=1),np.concatenate((lx,np.zeros((nl,nq),dtype=int)),axis=1)),axis=0)
    return H,l

def check_logical_error(errored_qubits1, errored_qubits2, lz):
    diff = errored_qubits1 - errored_qubits2
    for row in lz:
        if np.sum(row * diff) % 2 != 0:
            return True
    return False

def run_bp_osd(H,e,error_rate,l):
    time_sum = 0
    bp_osd = BpOsdDecoder(
                H,
                error_rate = error_rate,
                bp_method = 'product_sum',
                max_iter = 100,
                schedule = 'serial',
                osd_method = 'OSD_0', #set to OSD_0 for fast solve
                osd_order = 0
            )
    error_count = 0
    for i in range(e.shape[0]):
        syn = H@np.transpose(e[i,:])%2
        start_time = time.time()
        decoding = bp_osd.decode(syn)
        end_time = time.time()
        time_sum += end_time - start_time
        if check_logical_error(decoding,e[i,:],l):
            error_count += 1
    return time_sum/e.shape[0], error_count/e.shape[0]

def run_benchmark(Hpath,pvec,nsample,result_dir,data_dir):
    os.makedirs(result_dir, exist_ok=True)
    time_res = []
    error_rate = []
    H,l = load_code_data(Hpath)
    n = H.shape[1] // 2
    for p in pvec:
        e = load_e(data_dir + f"n={n}_p={p}_nsample={nsample}.dat")
        time_sum, error_count = run_bp_osd(H,e,p,l)
        time_res.append(time_sum)
        error_rate.append(error_count)
    data = { "pvec" : pvec, "nsample" : nsample, "time_res" : time_res, "error_rate" : error_rate }
    with open(result_dir + f"/code=surface_code_{n}_pvec={pvec}_nsample={nsample}_decoder=BpOsdDecoder.json", "w") as f:
        json.dump(data, f)
    return time_res, error_rate

