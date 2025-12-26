using DecoderBenchmarks
using TensorQEC
using Test
using JSON

@testset "run_benchmark" begin
    d = 3
    code = SurfaceCode(d,d)
    pvec = [0.1,0.2]
    max_sim = 10
    max_error = 3
    result_dir = joinpath(@__DIR__, "tempfolder/result")
    mkpath(result_dir)

    run_benchmark(code,pvec,max_sim,max_error,BPDecoder(),result_dir)
    worker_count = 1
    pmin = minimum(pvec)
    pmax = maximum(pvec)
    @test isfile(joinpath(result_dir, "code=$(code)_pmin=$(pmin)_pmax=$(pmax)_nsample=$(max_sim)_maxerror=$(max_error)_workers=$(worker_count)_decoder=$(BPDecoder()).json"))
    data = JSON.parsefile(joinpath(result_dir, "code=$(code)_pmin=$(pmin)_pmax=$(pmax)_nsample=$(max_sim)_maxerror=$(max_error)_workers=$(worker_count)_decoder=$(BPDecoder()).json"))
    @test data["code_name"] == "$code"
    @test data["pvec"] == pvec
    @test data["nsample"] == max_sim
    @test data["max_error"] == max_error
    @test data["decoder"] == "$(BPDecoder())"
    @test data["time_res"] isa Vector
    @test data["error_rate"] isa Vector
    @test length(data["nsim"]) == length(pvec)
    @test length(data["error_count"]) == length(pvec)
    rm(joinpath(@__DIR__, "tempfolder");recursive=true)
end
