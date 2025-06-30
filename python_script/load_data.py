import numpy as np

def load_H(path):
    file = open(path, 'r')
    data = file.readlines()
    ns = len(data)
    nq = len(data[0].split())
    H = np.zeros((ns, nq),dtype=np.uint8)
    for k in range(len(data)):
        H[k,:] = np.array(data[k].split(),dtype=np.uint8)
    file.close()
    return H

def load_e(path):
    file = open(path, 'r')
    data = file.readlines()
    e = np.zeros((len(data),len(data[0].split())),dtype=np.uint8)
    for k in range(len(data)):
        e[k,:] = np.array(data[k].split(),dtype=np.uint8)
    file.close()
    return e