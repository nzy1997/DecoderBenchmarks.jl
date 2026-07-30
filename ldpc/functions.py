import json
import hashlib
import math
import os
import time
from concurrent.futures import ProcessPoolExecutor
from datetime import datetime

import numpy as np
from ldpc import BpOsdDecoder


BP_OSD_PARAMETERS = {
    "decoder": "BP-OSD",
    "prior": "matched_per_point",
    "bp_method": "product_sum",
    "bp_schedule": "serial",
    "bp_max_iter": 100,
    "osd_method": "OSD_0",
    "osd_order": 0,
}


def worker_seed(base_seed, distance, physical_error_rate, worker_index):
    if worker_index < 0:
        raise ValueError("worker_index must be non-negative")
    payload = (
        f"{int(base_seed)}:{int(distance)}:"
        f"{float(physical_error_rate)!r}:{int(worker_index)}"
    )
    digest = hashlib.sha256(payload.encode("utf-8")).digest()
    return int.from_bytes(digest[:8], byteorder="big", signed=False)


def make_bp_osd_decoder(check_matrix, physical_error_rate):
    return BpOsdDecoder(
        check_matrix,
        error_rate=physical_error_rate,
        bp_method=BP_OSD_PARAMETERS["bp_method"],
        max_iter=BP_OSD_PARAMETERS["bp_max_iter"],
        schedule=BP_OSD_PARAMETERS["bp_schedule"],
        osd_method=BP_OSD_PARAMETERS["osd_method"],
        osd_order=BP_OSD_PARAMETERS["osd_order"],
    )

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

_DEFAULT_BATCH_SIZE = 256
_WORKER_STATE = None


def _make_worker_state(H, l, n, seed_base=None):
    seed = None
    if seed_base is not None:
        seed = int(seed_base) + (os.getpid() % 100000)
    return {
        "H": H,
        "l": l,
        "n": n,
        "decoders": {},
        "rng": np.random.default_rng(seed),
    }


def _init_worker(H, l, n, seed_base):
    global _WORKER_STATE
    _WORKER_STATE = _make_worker_state(H, l, n, seed_base)


def _get_decoder(state, error_rate):
    decoder = state["decoders"].get(error_rate)
    if decoder is None:
        decoder = make_bp_osd_decoder(state["H"], error_rate)
        state["decoders"][error_rate] = decoder
    return decoder


def _sample_depolarizing_batch(state, p, batch_size):
    r = state["rng"].random((batch_size, state["n"]))
    z = (r >= (p / 3)) & (r < p)
    x = r < (2 * p / 3)
    return np.concatenate((z, x), axis=1).astype(np.uint8)


def _run_chunk_with_state(state, p, max_sim, max_error, batch_size):
    time_sum = 0.0
    error_count = 0
    nsim = 0
    decoder = _get_decoder(state, p)
    while nsim < max_sim and error_count < max_error:
        remaining = max_sim - nsim
        batch = min(batch_size, remaining)
        e_batch = _sample_depolarizing_batch(state, p, batch)
        for i in range(batch):
            syn = state["H"] @ np.transpose(e_batch[i, :]) % 2
            start_time = time.perf_counter()
            decoding = decoder.decode(syn)
            time_sum += time.perf_counter() - start_time
            nsim += 1
            if not np.array_equal(state["H"] @ decoding % 2, syn):
                raise AssertionError("Decoded syndrome does not match.")
            if check_logical_error(decoding, e_batch[i, :], state["l"]):
                error_count += 1
            if error_count >= max_error or nsim >= max_sim:
                break
    return time_sum, nsim, error_count


def run_seeded_worker(
    check_matrix,
    logicals,
    distance,
    physical_error_rate,
    max_sim,
    max_error,
    base_seed,
    worker_index,
):
    seed = worker_seed(base_seed, distance, physical_error_rate, worker_index)
    state = {
        "H": np.asarray(check_matrix, dtype=np.uint8),
        "l": np.asarray(logicals, dtype=np.uint8),
        "n": np.asarray(check_matrix).shape[1] // 2,
        "decoders": {},
        "rng": np.random.default_rng(seed),
    }
    time_sum, nsim, error_count = _run_chunk_with_state(
        state,
        float(physical_error_rate),
        int(max_sim),
        int(max_error),
        _DEFAULT_BATCH_SIZE,
    )
    return {
        "nsim": nsim,
        "error_count": error_count,
        "decode_seconds": time_sum,
        "seed": seed,
        "worker_index": int(worker_index),
    }


def _benchmark_chunk(job):
    p, max_sim, max_error, batch_size = job
    return _run_chunk_with_state(_WORKER_STATE, p, max_sim, max_error, batch_size)

def run_benchmark(
    Hpath,
    pvec,
    max_sim,
    max_error,
    result_dir,
    code_name,
    workers=1,
    seed_base=None,
    log_file=None,
):
    os.makedirs(result_dir, exist_ok=True)
    time_res = []
    error_rate = []
    nsim_res = []
    error_count_res = []
    H, l = load_code_data(Hpath)
    n = H.shape[1] // 2
    worker_count = max(1, int(workers))
    batch_size = _DEFAULT_BATCH_SIZE
    print(
        f"benchmark start code={code_name} workers={worker_count} "
        f"max_sim={max_sim} max_error={max_error} pvec={pvec}"
    )

    if worker_count > 1:
        with ProcessPoolExecutor(
            max_workers=worker_count,
            initializer=_init_worker,
            initargs=(H, l, n, seed_base),
        ) as executor:
            for p in pvec:
                print(f"p={p} start")
                time_sum = 0.0
                error_count = 0
                nsim = 0
                while nsim < max_sim and error_count < max_error:
                    remaining_sim = max_sim - nsim
                    remaining_error = max_error - error_count
                    chunk_sim = max(1, math.ceil(remaining_sim / worker_count))
                    chunk_err = max(1, math.ceil(remaining_error / worker_count))
                    jobs = [
                        (p, chunk_sim, chunk_err, batch_size)
                        for _ in range(worker_count)
                    ]
                    for chunk_time, chunk_nsim, chunk_error in executor.map(
                        _benchmark_chunk, jobs
                    ):
                        time_sum += chunk_time
                        nsim += chunk_nsim
                        error_count += chunk_error
                avg_time = time_sum / nsim if nsim else 0.0
                err_rate = error_count / nsim if nsim else 0.0
                time_res.append(avg_time)
                error_rate.append(err_rate)
                nsim_res.append(nsim)
                error_count_res.append(error_count)
                print(
                    f"p={p} done nsim={nsim} error_count={error_count} "
                    f"time_avg={avg_time} error_rate={err_rate}"
                )
                if log_file is not None:
                    with open(log_file, "a") as f:
                        f.write(
                            "n={n} p={p} max_sim={max_sim} max_error={max_error} "
                            "nsim={nsim} error_count={error_count} decoder=BpOsdDecoder "
                            "average_time={avg_time} error_rate={err_rate} run {timestamp}\n".format(
                                n=n,
                                p=p,
                                max_sim=max_sim,
                                max_error=max_error,
                                nsim=nsim,
                                error_count=error_count,
                                avg_time=avg_time,
                                err_rate=err_rate,
                                timestamp=datetime.now(),
                            )
                        )
    else:
        state = _make_worker_state(H, l, n, seed_base)
        for p in pvec:
            print(f"p={p} start")
            time_sum, nsim, error_count = _run_chunk_with_state(
                state, p, max_sim, max_error, batch_size
            )
            avg_time = time_sum / nsim if nsim else 0.0
            err_rate = error_count / nsim if nsim else 0.0
            time_res.append(avg_time)
            error_rate.append(err_rate)
            nsim_res.append(nsim)
            error_count_res.append(error_count)
            print(
                f"p={p} done nsim={nsim} error_count={error_count} "
                f"time_avg={avg_time} error_rate={err_rate}"
            )
            if log_file is not None:
                with open(log_file, "a") as f:
                    f.write(
                        "n={n} p={p} max_sim={max_sim} max_error={max_error} "
                        "nsim={nsim} error_count={error_count} decoder=BpOsdDecoder "
                        "average_time={avg_time} error_rate={err_rate} run {timestamp}\n".format(
                            n=n,
                            p=p,
                            max_sim=max_sim,
                            max_error=max_error,
                            nsim=nsim,
                            error_count=error_count,
                            avg_time=avg_time,
                            err_rate=err_rate,
                            timestamp=datetime.now(),
                        )
                    )

    data = {
        "pvec": pvec,
        "nsample": max_sim,
        "max_error": max_error,
        "nsim": nsim_res,
        "error_count": error_count_res,
        "time_res": time_res,
        "error_rate": error_rate,
        "decoder": "BpOsdDecoder",
        "code_name": code_name,
    }
    pmin = min(pvec)
    pmax = max(pvec)
    filename = (
        f"code={code_name}_pmin={pmin}_pmax={pmax}_nsample={max_sim}"
        f"_maxerror={max_error}_workers={worker_count}_decoder=BpOsdDecoder.json"
    )
    with open(os.path.join(result_dir, filename), "w") as f:
        json.dump(data, f)
    return time_res, error_rate, nsim_res, error_count_res


def run_benchmark_time(
    Hpath,
    pvec,
    max_sim,
    result_dir,
    code_name,
    init_num=100,
    seed_base=None,
):
    os.makedirs(result_dir, exist_ok=True)
    time_res = []
    H, l = load_code_data(Hpath)
    n = H.shape[1] // 2
    state = _make_worker_state(H, l, n, seed_base)
    warmup = int(init_num)
    total_sim = int(max_sim)
    batch_size = _DEFAULT_BATCH_SIZE
    print(
        f"benchmark time start code={code_name} max_sim={max_sim} pvec={pvec}"
    )

    for p in pvec:
        print(f"p={p} start")
        decoder = _get_decoder(state, p)
        time_sum = 0.0
        total_iters = warmup + total_sim
        processed = 0
        while processed < total_iters:
            batch = min(batch_size, total_iters - processed)
            e_batch = _sample_depolarizing_batch(state, p, batch)
            for i in range(batch):
                syn = state["H"] @ e_batch[i, :] % 2
                start_time = time.time()
                decoding = decoder.decode(syn)
                end_time = time.time()
                if processed + i >= warmup:
                    time_sum += end_time - start_time
                if not np.array_equal(state["H"] @ decoding % 2, syn):
                    raise AssertionError("Decoded syndrome does not match.")
            processed += batch

        avg_time = time_sum / total_sim if total_sim else 0.0
        time_res.append(avg_time)

    data = {
        "pvec": pvec,
        "nsample": max_sim,
        "decoder": "BpOsdDecoder",
        "code_name": code_name,
        "time_res": time_res,
    }
    pmin = min(pvec)
    pmax = max(pvec)
    filename = (
        f"Time_code={code_name}_pmin={pmin}_pmax={pmax}"
        f"_nsample={max_sim}_decoder=BpOsdDecoder.json"
    )
    with open(os.path.join(result_dir, filename), "w") as f:
        json.dump(data, f)
    return time_res
