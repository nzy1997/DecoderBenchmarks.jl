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

export PaperBenchmarkConfig, paper_benchmark_config, paper_seed
export paper_decoder, run_paper_point

include("codes.jl")
include("generate_samples.jl")
include("runbenchmark.jl")
include("paper_inputs.jl")
include("paper_benchmark.jl")
end
