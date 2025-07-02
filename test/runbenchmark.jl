using DecoderBenchmarks
using TensorQEC
using Test

@testset "run_benchmark" begin
    d = 3
    code = SurfaceCode(d,d)
    pvec = [0.1,0.2]
    nsample = 10
    result_dir = joinpath(@__DIR__, "tempfolder/result")
    data_dir = joinpath(@__DIR__, "tempfolder/depolarizing")
    mkpath(data_dir)
    mkpath(result_dir)

    generate_depolarizing_samples([d*d],pvec,nsample,data_dir)

    run_benchmark(code,pvec,nsample,BPDecoder(),result_dir,data_dir)
    @test isfile(joinpath(result_dir, "code=$(code)_pvec=$(pvec)_nsample=$(nsample)_decoder=$(BPDecoder()).json"))
    data = JSON.parsefile(joinpath(result_dir, "code=$(code)_pvec=$(pvec)_nsample=$(nsample)_decoder=$(BPDecoder()).json"))
    @test data["code_name"] == "$code"
    @test data["pvec"] == pvec
    @test data["nsample"] == nsample
    @test data["decoder"] == "$(BPDecoder())"
    @test data["time_res"] isa Vector
    @test data["error_rate"] isa Vector
    rm(joinpath(@__DIR__, "tempfolder");recursive=true)
end