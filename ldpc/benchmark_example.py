import os

import numpy as np
from functions import run_benchmark


def run_selected_files(code_files, pvec, max_sim, max_error, workers, log_file):
    result_dir = os.path.join(os.path.dirname(__file__), "..", "data", "result", "ldpc")
    for file_path in code_files:
        output_name = os.path.splitext(os.path.basename(file_path))[0]
        run_benchmark(
            file_path,
            pvec,
            max_sim,
            max_error,
            result_dir,
            output_name,
            workers=workers,
            log_file=log_file,
        )


def main():
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    code_files = [
        os.path.join(project_root, "data", "codes", "SurfaceCode(3, 3).json"),
        os.path.join(project_root, "data", "codes", "SurfaceCode(5, 5).json"),
        os.path.join(project_root, "data", "codes", "SurfaceCode(7, 7).json"),
    ]
    pvec = np.arange(0.01, 0.21, 0.01).tolist()
    max_sim = 100
    max_error = 100
    workers = 6
    log_file = os.path.join(project_root, "log.txt")

    missing = [path for path in code_files if not os.path.isfile(path)]
    if missing:
        raise FileNotFoundError(f"Missing code files: {missing}")

    run_selected_files(code_files, pvec, max_sim, max_error, workers, log_file)


if __name__ == "__main__":
    main()
