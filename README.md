# Decoder Benchmarks

[![Build Status](https://github.com/nzy1997/DecoderBenchmarks.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/nzy1997/DecoderBenchmarks.jl/actions/workflows/CI.yml?query=branch%3Amain)

This repository contains the code for generating the samples for benchmarking the decoder performance. It is based on the [TensorQEC](https://github.com/nzy1997/TensorQEC.jl) package.

## Usage

Clone the repository and run the following command in the root directory to install the dependencies:
```bash
make init
```

To generate the code data, run the following command:
```bash
codevec=[SurfaceCode(3,3),SurfaceCode(5,5),SurfaceCode(7,7)] make generate-code-data
```
Here the `codevec` is a vector of codes, the code names are the same as the ones in the `TensorQEC` package. You can check [here](https://nzy1997.github.io/TensorQEC.jl/dev/generated/codes/) for the available codes in the `TensorQEC` package.

The code data is generated in the `data/codes` directory as a json file, named as `code_name.json`. This file contains the following information:
- `code_name`: The name of the code.
- `qubit_num`: The number of physical qubits.
- `stabilizer_num`: The number of stabilizers.
- `pcm`: The parity check matrix.
- `logical_x`: The logical X operator.
- `logical_z`: The logical Z operator.

To benchmark the performance of the codes or decoders, first we generate the error samples.
```bash
nvec=[3,5,7,9,11].^2 pvec=0.01:0.01:0.05 nsample=100 make generate-error-samples
```
The `nvec` is a vector of the qubit numbers, the `pvec` is a vector of the error rates, and the `nsample` is the number of samples to generate.

The samples are generated in the `data/depolarizing` directory as a dat file, named as `n=n_p=p_nsample=nsample.dat`. The samples are saved as a matrix of size `nsample` by `2 * num_qubits`. The first `num_qubits` columns are the Z error qubits and the last `num_qubits` columns are the X error qubits.

Then we can run the benchmark with the decoders in the `TensorQEC` package.
```bash
codevec=[SurfaceCode(3,3),SurfaceCode(5,5),SurfaceCode(7,7)] pvec=[0.01,0.02] nsample=100 decoder="BPDecoder()" make benchmark-TensorQEC
```
The `decoder` is the decoder to use. The benchmark results are saved in the `data/result/TensorQEC` directory as a json file, named as `code=code_name_pvec=pvec_nsample=nsample_decoder=decoder.json`. The information includes
- `code_name`: The name of the code.
- `pvec`: The error probabilities.
- `nsample`: The number of samples.
- `decoder`: The decoder.
- `time_res`: The average decoding time.
- `error_rate`: The logical error rate.

To run the benchmarks for python packages like [ldpc](https://github.com/quantumgizmos/ldpc), we first install a conda environment with the following command:
```bash
make init-conda
```

Then run the following command to install the dependencies:
```bash
make init-ldpc
```

Then run the following command to run the benchmark:
```bash
codevec=[SurfaceCode(3,3),SurfaceCode(5,5),SurfaceCode(7,7)] pvec=[0.01,0.02] nsample=100 make benchmark-ldpc
```
The results are saved in the `data/result/ldpc` directory as a json file with similar format as the `TensorQEC` results.

## Samples

Samples of the depolarizing channel are available at [OneDrive](https://hkustgz-my.sharepoint.com/:f:/g/personal/jinguoliu_hkust-gz_edu_cn/Eo4RiKqgPrFEj_ghttddtzwBrJb7Qajj2Q2CcZeTydAxyA?e=vrd9k1). The codes include:
- Surface code with $d = 9$ and $d = 21$ (TODO: more).
- BBCode [[144, 12, 12]].