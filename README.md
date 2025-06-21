# Decoder Benchmarks

[![Build Status](https://github.com/nzy1997/DecoderBenchmarks.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/nzy1997/DecoderBenchmarks.jl/actions/workflows/CI.yml?query=branch%3Amain)

This repository contains the code for generating the samples for benchmarking the decoder performance. It is based on the [TensorQEC](https://github.com/nzy1997/TensorQEC.jl) package.

## Usage

Clone the repository and run the following command in the root directory to generate samples:
```bash
# generate samples
generate_depolarizing_samples(n_samples=100, n_qubits=10, p=0.01)
```

## Samples

Samples of the depolarizing channel are available at [OneDrive](https://hkustgz-my.sharepoint.com/:f:/g/personal/jinguoliu_hkust-gz_edu_cn/Eo4RiKqgPrFEj_ghttddtzwBrJb7Qajj2Q2CcZeTydAxyA?e=vrd9k1). The codes include:
- Surface code with $d = 9$ and $d = 21$ (TODO: more).
- BBCode [[144, 12, 12]].