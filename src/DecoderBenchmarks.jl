module DecoderBenchmarks

using DelimitedFiles
using Distributed
using TensorQEC
using Random
using Dates
import JSON

export get_depolarizing_data, generate_depolarizing_samples, generate_sample

export generate_code_data, run_benchmark, run_benchmark_time

include("codes.jl")
include("generate_samples.jl")
include("runbenchmark.jl")
end
