using DecoderBenchmarks
using Test

include("paper_inputs.jl")
include("paper_benchmark.jl")
include("paper_entrypoints.jl")
include("profile_likelihood.jl")
include("paper_archive.jl")
include("paper_export.jl")

@testset "generate sample" begin
    include("generate_sample.jl")
end

@testset "run benchmark" begin
    include("runbenchmark.jl")
end
