using Test
using DecoderBenchmarks
using TensorQEC
using JSON

@testset "generate_sample and read" begin
    filename = joinpath(@__DIR__, "test.dat")
    nsample = 10
    nqubit = 20
    p = 0.1
    @test generate_sample(iid_error(p,p,p,nqubit),nsample,filename,110) isa Nothing

    eq = get_depolarizing_data(nsample,filename)
    @test eq isa Vector{CSSErrorPattern{Vector{Mod2}}}
    @test length(eq) == nsample
    @test length(eq[1].xerror) == nqubit
    rm(filename)
end

@testset "generate_depolarizing_samples" begin
    nvec = [10,20]
    pvec = [0.1,0.2]
    nsample = 10
    dirname = joinpath(@__DIR__, "tempfolder")
    mkpath(dirname)
    @test generate_depolarizing_samples(nvec,pvec,nsample,dirname) isa Nothing
    @test isfile(joinpath(dirname, "n=10_p=0.1_nsample=10.dat"))
    @test isfile(joinpath(dirname, "n=20_p=0.2_nsample=10.dat"))
    rm(dirname;recursive=true)
end

@testset "generate_code_data" begin
    code = SurfaceCode(9,9)
    dirname = joinpath(@__DIR__, "tempfolder")
    mkpath(dirname)
    generate_code_data(code,dirname,"surface_code")
    data = JSON.parsefile(joinpath(dirname, "surface_code.json"))
    nq = data["qubit_num"]
    ns = data["stabilizer_num"]
    @test nq == 81
    @test ns == 80
    @test data["code_name"] == "$code"
    @test reshape(data["pcm"],ns,2*nq) == Int.(TensorQEC.stabilizers2bimatrix(stabilizers(code)).matrix)
    @test reshape(data["logical_x"],1,nq) == Int.(logical_operator(CSSTannerGraph(code))[1])
    @test reshape(data["logical_z"],1,nq) == Int.(logical_operator(CSSTannerGraph(code))[2])
    rm(dirname;recursive=true)
end

@testset "generate_sample (flip) and read" begin
    filename = joinpath(@__DIR__, "test.dat")
    nsample = 10
    nqubit = 20
    p = 0.1
    @test generate_sample(iid_error(p,nqubit),nsample,filename,110) isa Nothing

    eq = DecoderBenchmarks.get_flip_data(nsample,filename)
    @test eq isa Vector{Vector{Mod2}}
    @test length(eq) == nsample
    @test length(eq[1]) == nqubit
    rm(filename)
end