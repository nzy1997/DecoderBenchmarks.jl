module DecoderBenchmarks

using DelimitedFiles
using TensorQEC
using Random
using Dates

export get_depolarizing_data, generate_depolarizing_samples, generate_sample

export generate_code_data, run_benchmark

include("codes.jl")
include("generate_samples.jl")
include("runbenchmark.jl")
end
