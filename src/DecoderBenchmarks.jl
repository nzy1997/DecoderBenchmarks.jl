module DecoderBenchmarks

using DelimitedFiles
using Distributed
using TensorQEC
using Random
using Dates
using CodecZlib
using SHA
using Tar
import JSON

export get_depolarizing_data, generate_depolarizing_samples, generate_sample

export generate_code_data, run_benchmark, run_benchmark_time

export materialize_paper_input

include("codes.jl")
include("generate_samples.jl")
include("runbenchmark.jl")
include("paper_inputs.jl")
end
