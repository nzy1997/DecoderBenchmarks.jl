using Test
using DecoderBenchmarks

@testset "generate_depolarizing_samples" begin
    @test generate_sample(10, 0.1) isa Vector{Bool}
end