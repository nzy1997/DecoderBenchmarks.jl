using DecoderBenchmarks
using Test

include("paper_inputs.jl")
include("paper_benchmark.jl")

@testset "generate sample" begin
    include("generate_sample.jl")
end

@testset "run benchmark" begin
    include("runbenchmark.jl")
end
