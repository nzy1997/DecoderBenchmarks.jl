using JSON
using Test

include(normpath(joinpath(@__DIR__, "..", "paper", "export_normalized.jl")))

@testset "canonical paper archive export" begin
    mktempdir() do temp
        first_root = joinpath(temp, "first")
        second_root = joinpath(temp, "second")
        first = export_normalized_archive(first_root)
        second = export_normalized_archive(second_root)

        @test basename(first) == "decoding_benchmark.json"
        @test read(first) == read(second)
        @test startswith(read(first, String), "{\"dataset_class\":")

        payload = JSON.parsefile(first)
        @test payload["schema_version"] == 1
        @test payload["dataset_class"] == "archived"
        @test payload["seed_status"] == "not_recorded"
        @test payload["provenance"]["environment"]["status"] == "not_recorded"
        @test payload["provenance"]["input_provenance"]["status"] == "not_recorded"
        @test payload["distances"] == [4, 6, 8, 10]

        unitary = payload["logical_error"]["4"]["unitary"]
        @test unitary["pvec"][1] == 0.0001
        @test unitary["nsim"][1] == 1_088_545
        @test unitary["error_count"][1] == 2_040
        @test unitary["interval"]["estimate"][1] == 2_040 / 1_088_545

        bposd = payload["logical_error"]["4"]["bposd"]
        @test length(bposd["pvec"]) == 17
        @test issorted(bposd["pvec"])
        @test payload["decoding_time"]["4"]["unitary"]["time_res"][1] ==
            5.317783355712891e-6
    end
end
