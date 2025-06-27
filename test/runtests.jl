using DecoderBenchmarks
using Test

@testset "generate sample" begin
    include("generate_sample.jl")
end

@testset "run benchmark" begin
    include("runbenchmark.jl")
end