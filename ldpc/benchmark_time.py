import os

from functions import run_benchmark_time


def run_selected_files(code_files, pvec, max_sim, init_num):
    result_dir = os.path.join(os.path.dirname(__file__), "..", "data", "result", "ldpc")
    for file_path in code_files:
        output_name = os.path.splitext(os.path.basename(file_path))[0]
        run_benchmark_time(
            file_path,
            pvec,
            max_sim,
            result_dir,
            output_name,
            init_num=init_num,
        )


def main():
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    code_files = [
        os.path.join(project_root, "data", "codes", "bbx^-1y_10.json"),
    ]
    pvec = [0.0001, 0.0002, 0.0005, 0.001, 0.002, 0.005, 0.008, 0.01, 0.015, 0.02]
    max_sim = 10000
    init_num = 100

    missing = [path for path in code_files if not os.path.isfile(path)]
    if missing:
        raise FileNotFoundError(f"Missing code files: {missing}")

    run_selected_files(code_files, pvec, max_sim, init_num)


if __name__ == "__main__":
    main()
