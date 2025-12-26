include("sinter_like_fit_binomial.jl")
using Test

@testset "sinter_like_fit_binomial" begin
    low,av,high = sinter_like_fit_binomial(10, 5, 9)
    @test low ≈ 0.202 atol=1e-3
    @test av ≈ 0.5 atol=1e-3
    @test high ≈ 0.798 atol=1e-3
end

