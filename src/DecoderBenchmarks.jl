module DecoderBenchmarks

using DelimitedFiles
using TensorQEC
using Random

export get_depolarizing_data, generate_depolarizing_samples, generate_sample

export generate_code_data
include("codes.jl")
include("generate_samples.jl")

end
