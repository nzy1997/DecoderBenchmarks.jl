using DecoderBenchmarks
using TensorQEC
using Test

@testset "run_benchmark" begin
    d = 3
    code = SurfaceCode(d,d)
    pvec = [0.1,0.2]
    nsample = 10
    ns = 10
    result_dir = joinpath(@__DIR__, "tempfolder/result")
    data_dir = joinpath(@__DIR__, "tempfolder/depolarizing")
    mkpath(data_dir)
    mkpath(result_dir)

    generate_depolarizing_samples([d*d],pvec,nsample,data_dir)

    run_benchmark(code,pvec,nsample,BPDecoder(),ns,result_dir,data_dir)
    @test isfile(joinpath(result_dir, "Time_$(code)_pvec=$(pvec)_nsample=$(nsample)_decoder=$(BPDecoder())_ns=$(ns).txt"))
    @test isfile(joinpath(result_dir, "Error_rate_$(code)_pvec=$(pvec)_nsample=$(nsample)_decoder=$(BPDecoder())_ns=$(ns).txt"))
    @test isfile(joinpath(result_dir, "log.txt"))
    rm(joinpath(@__DIR__, "tempfolder");recursive=true)
end