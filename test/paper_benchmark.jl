using Test
using JSON

@testset "paper benchmark presets" begin
    smoke = paper_benchmark_config(:smoke)
    @test smoke.distances == [4]
    @test smoke.pvec == [0.01]
    @test smoke.max_sim == 32
    @test smoke.max_error == 8
    @test smoke.workers == 1
    @test smoke.seed == UInt64(0x20260607)

    full = paper_benchmark_config(:full)
    @test full.distances == [4, 6, 8, 10]
    @test full.pvec == [
        0.0001, 0.0002, 0.0005, 0.001, 0.002,
        0.005, 0.008, 0.01, 0.015, 0.02,
    ]
    @test full.max_sim == 1_000_000_000
    @test full.max_error == 2_000
    @test full.workers == 120
    @test full.seed == UInt64(0x20260607)
    @test_throws ArgumentError paper_benchmark_config(:unknown)
end

@testset "paper decoder construction" begin
    mktempdir() do temp
        paths = materialize_paper_input(4, temp)
        components = paper_decoder(4, paths)
        @test string(components.code) == "bbx^-1y_4"
        @test string(components.decoder) == "TToricDecoder(Matching)"
    end
end

@testset "deterministic paper point" begin
    config = paper_benchmark_config(:smoke)
    mktempdir() do first_dir
        mktempdir() do second_dir
            first = run_paper_point(config, 4, 0.01, first_dir)
            second = run_paper_point(config, 4, 0.01, second_dir)
            @test first.nsim == second.nsim
            @test first.error_count == second.error_count
            @test first.seed == second.seed == config.seed
            @test first.worker_count == second.worker_count == 1

            first_file = only(readdir(first_dir; join=true))
            first_json = JSON.parsefile(first_file)
            @test first_json["distance"] == 4
            @test first_json["p"] == 0.01
            @test first_json["nsim"] == first.nsim
            @test first_json["error_count"] == first.error_count
            @test first_json["seed"] == Int(config.seed)
            @test first_json["worker_count"] == 1
        end
    end
end

@testset "stable point seeds" begin
    seed = paper_seed(UInt64(7), 4, 0.01, 1)
    @test seed == paper_seed(UInt64(7), 4, 0.01, 1)
    @test seed != paper_seed(UInt64(7), 4, 0.01, 2)
    @test seed == UInt64(0x1c0f6158d71471dc)
    @test_throws ArgumentError paper_seed(UInt64(7), 4, 0.01, 0)
end

@testset "logical worker partition" begin
    config = PaperBenchmarkConfig(
        mode=:test,
        distances=[4],
        pvec=[0.01],
        max_sim=5,
        max_error=2,
        workers=3,
        seed=UInt64(7),
    )
    jobs = DecoderBenchmarks._paper_jobs(config, nothing, nothing, 4, 0.01)
    @test getfield.(jobs, :worker_index) == [1, 2, 3]
    @test getfield.(jobs, :max_sim) == [2, 2, 1]
    @test sum(getfield.(jobs, :max_sim)) == config.max_sim
    @test getfield.(jobs, :seed) == [
        paper_seed(config.seed, 4, 0.01, worker_index)
        for worker_index in 1:config.workers
    ]
end
