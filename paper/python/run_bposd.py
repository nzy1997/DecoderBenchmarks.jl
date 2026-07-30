import argparse
import hashlib
import json
import math
import shutil
import sys
import tarfile
import tempfile
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path, PurePosixPath

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY_ROOT / "ldpc"))

import numpy as np
from ldpc.mod2 import nullspace, rank, row_basis

from functions import (  # noqa: E402
    BP_OSD_PARAMETERS,
    run_seeded_worker,
    worker_seed,
)


BPOSD_LOGICAL_GRID = [
    0.0001,
    0.0002,
    0.0005,
    0.001,
    0.002,
    0.005,
    0.008,
    0.01,
    0.015,
    0.02,
    0.03,
    0.04,
    0.056,
    0.06,
    0.12,
    0.15,
    0.2,
]
BPOSD_TIMING_GRID = [0.01, 0.015, 0.02, 0.03, 0.04, 0.06, 0.12, 0.15, 0.2]
PAPER_DISTANCES = (4, 6, 8, 10)
PAPER_SEED = 20260607


def _dense_uint8(matrix):
    if hasattr(matrix, "toarray"):
        matrix = matrix.toarray()
    return np.atleast_2d(np.asarray(matrix, dtype=np.uint8)) % 2


def _gf2_rank(matrix):
    matrix = np.atleast_2d(np.asarray(matrix, dtype=np.uint8))
    if matrix.size == 0 or matrix.shape[0] == 0 or matrix.shape[1] == 0:
        return 0
    return int(rank(matrix))


def _gf2_row_basis(matrix, ncols=None):
    matrix = np.atleast_2d(np.asarray(matrix, dtype=np.uint8))
    if matrix.size == 0 or matrix.shape[0] == 0:
        columns = matrix.shape[1] if ncols is None else ncols
        return np.zeros((0, columns), dtype=np.uint8)
    return _dense_uint8(row_basis(matrix))


def _independent_rows(space_basis, subspace_basis):
    space_basis = _gf2_row_basis(space_basis)
    subspace_basis = _gf2_row_basis(subspace_basis, ncols=space_basis.shape[1])
    current = [row.copy() for row in subspace_basis]
    current_rank = _gf2_rank(subspace_basis)
    selected = []

    for row in space_basis:
        trial = np.asarray(current + [row], dtype=np.uint8)
        trial_rank = _gf2_rank(trial)
        if trial_rank > current_rank:
            selected.append(row.copy())
            current.append(row.copy())
            current_rank = trial_rank

    expected = _gf2_rank(space_basis) - _gf2_rank(subspace_basis)
    if len(selected) != expected:
        raise ValueError(
            "failed to construct logical operator basis: "
            f"expected {expected} rows, got {len(selected)}"
        )
    if not selected:
        return np.zeros((0, space_basis.shape[1]), dtype=np.uint8)
    return np.asarray(selected, dtype=np.uint8)


def compute_css_logicals(hx, hz):
    hx_basis = _gf2_row_basis(hx, ncols=hx.shape[1])
    hz_basis = _gf2_row_basis(hz, ncols=hz.shape[1])
    logical_z = _independent_rows(_dense_uint8(nullspace(hx_basis)), hz_basis)
    logical_x = _independent_rows(_dense_uint8(nullspace(hz_basis)), hx_basis)
    if logical_x.shape[0] != logical_z.shape[0]:
        raise ValueError(
            "logical X/Z rank mismatch: "
            f"{logical_x.shape[0]} vs {logical_z.shape[0]}"
        )
    return logical_x, logical_z


def materialize_paper_input(distance, output_root):
    if distance not in PAPER_DISTANCES:
        raise ValueError("distance must be one of 4, 6, 8, 10")
    input_root = REPOSITORY_ROOT / "paper" / "inputs"
    manifest = json.loads((input_root / "manifest.json").read_text())
    entry = manifest["distances"][str(distance)]
    archive = input_root / entry["archive"]
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    if digest != entry["sha256"]:
        raise ValueError(f"paper input checksum mismatch for distance {distance}")

    expected = sorted(entry["members"])
    destination = Path(output_root) / f"d{distance}"
    destination.mkdir(parents=True, exist_ok=False)
    with tarfile.open(archive, "r:gz") as bundle:
        members = bundle.getmembers()
        if sorted(member.name for member in members) != expected:
            raise ValueError("paper input archive members do not match the manifest")
        for member in members:
            path = PurePosixPath(member.name)
            if path.is_absolute() or ".." in path.parts or not member.isfile():
                raise ValueError(f"unsafe paper input member: {member.name!r}")
            source = bundle.extractfile(member)
            if source is None:
                raise ValueError(f"paper input member is unreadable: {member.name!r}")
            with source, (destination / member.name).open("wb") as target:
                shutil.copyfileobj(source, target)
    return destination


def load_paper_code(distance, output_root):
    input_dir = materialize_paper_input(distance, output_root)
    check_matrix = np.atleast_2d(
        np.loadtxt(input_dir / "check_matrix.txt", dtype=np.uint8)
    ) % 2
    if check_matrix.shape[1] % 2:
        raise ValueError("paper check matrix must have 2n columns")
    n = check_matrix.shape[1] // 2
    left = check_matrix[:, :n]
    right = check_matrix[:, n:]
    has_left = np.any(left, axis=1)
    has_right = np.any(right, axis=1)
    if np.any(has_left & has_right):
        raise ValueError("paper check matrix is not in CSS block form")
    hx = left[has_left & ~has_right]
    hz = right[has_right & ~has_left]
    logical_x, logical_z = compute_css_logicals(hx, hz)
    if np.any((hx @ logical_z.T) % 2) or np.any((hz @ logical_x.T) % 2):
        raise ValueError("derived logical operators do not commute with stabilizers")
    logicals = np.vstack(
        (
            np.hstack((np.zeros_like(logical_z), logical_z)),
            np.hstack((logical_x, np.zeros_like(logical_x))),
        )
    ).astype(np.uint8, copy=False)
    return check_matrix, logicals


def _run_worker(arguments):
    return run_seeded_worker(**arguments)


def run_bposd_point(
    check_matrix,
    logicals,
    distance,
    physical_error_rate,
    max_sim,
    max_error,
    base_seed,
    workers,
):
    if workers < 1:
        raise ValueError("workers must be positive")
    simulations, extra = divmod(max_sim, workers)
    worker_max_error = max(1, math.ceil(max_error / workers))
    jobs = [
        {
            "check_matrix": check_matrix,
            "logicals": logicals,
            "distance": distance,
            "physical_error_rate": physical_error_rate,
            "max_sim": simulations + (worker_index < extra),
            "max_error": worker_max_error,
            "base_seed": base_seed,
            "worker_index": worker_index,
        }
        for worker_index in range(workers)
    ]
    if workers == 1:
        worker_results = [_run_worker(jobs[0])]
    else:
        with ProcessPoolExecutor(max_workers=workers) as executor:
            worker_results = list(executor.map(_run_worker, jobs))

    result = {
        **BP_OSD_PARAMETERS,
        "distance": distance,
        "physical_error_rate": physical_error_rate,
        "nsim": sum(item["nsim"] for item in worker_results),
        "error_count": sum(item["error_count"] for item in worker_results),
        "decode_seconds": sum(item["decode_seconds"] for item in worker_results),
        "seed": int(base_seed),
        "worker_count": workers,
        "worker_seeds": [item["seed"] for item in worker_results],
    }
    return result


def parse_arguments():
    parser = argparse.ArgumentParser(description="Run the seeded paper BP-OSD benchmark.")
    parser.add_argument("--mode", choices=("smoke", "full"), required=True)
    parser.add_argument("--distance", type=int, choices=PAPER_DISTANCES, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--physical-error-rate", type=float)
    parser.add_argument("--workers", type=int, default=1)
    parser.add_argument("--seed", type=int, default=PAPER_SEED)
    parser.add_argument("--max-sim", type=int)
    parser.add_argument("--max-error", type=int)
    return parser.parse_args()


def main():
    args = parse_arguments()
    pvec = (
        [args.physical_error_rate]
        if args.physical_error_rate is not None
        else ([0.01] if args.mode == "smoke" else BPOSD_LOGICAL_GRID)
    )
    max_sim = args.max_sim if args.max_sim is not None else (
        5 if args.mode == "smoke" else 1_000_000_000
    )
    max_error = args.max_error if args.max_error is not None else (
        5 if args.mode == "smoke" else 2_000
    )

    with tempfile.TemporaryDirectory() as temp:
        check_matrix, logicals = load_paper_code(args.distance, temp)
        points = [
            run_bposd_point(
                check_matrix=check_matrix,
                logicals=logicals,
                distance=args.distance,
                physical_error_rate=p,
                max_sim=max_sim,
                max_error=max_error,
                base_seed=args.seed,
                workers=args.workers,
            )
            for p in pvec
        ]

    data = points[0] if len(points) == 1 else {
        "mode": args.mode,
        "distance": args.distance,
        "seed": args.seed,
        "points": points,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    print(
        f"paper BP-OSD mode={args.mode} distance={args.distance} "
        f"points={len(points)} workers={args.workers} seed={args.seed} "
        f"output={args.output}"
    )


if __name__ == "__main__":
    main()
