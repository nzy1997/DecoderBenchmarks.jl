using Test
using DecoderBenchmarks
using TensorQEC

@testset "generate_sample and read" begin
    filename = joinpath(@__DIR__, "test.txt")
    nsample = 10
    nqubit = 20
    p = 0.1
    @test generate_sample(iid_error(p,p,p,nqubit),nsample,filename,110) isa Nothing

    eq = get_depolarizing_data(nqubit,p,nsample;filename = filename)
    @test eq isa Vector{CSSErrorPattern{Vector{Mod2}}}
    @test length(eq) == nsample
    @test length(eq[1].xerror) == nqubit
    rm(filename)
end

@testset "generate_depolarizing_samples" begin
    nvec = [10,20]
    pvec = [0.1,0.2]
    nsample = 10
    dirname = joinpath(@__DIR__, "data")
    mkpath(dirname)
    @test generate_depolarizing_samples(nvec,pvec,nsample;dirname = dirname) isa Nothing
    @test isfile(joinpath(dirname, "n=10_p=0.1_nsample=10.txt"))
    @test isfile(joinpath(dirname, "n=20_p=0.2_nsample=10.txt"))
    rm(dirname;recursive=true)
end