using JSON
using SHA
using DelimitedFiles
using Tar
using Test

@testset "paper input manifest" begin
    root = normpath(joinpath(@__DIR__, ".."))
    manifest = JSON.parsefile(joinpath(root, "paper", "inputs", "manifest.json"))
    @test manifest["provenance"]["status"] == "not_recorded"
    @test occursin("not recorded", lowercase(manifest["provenance"]["limitation"]))
    @test sort(parse.(Int, collect(keys(manifest["distances"])))) == [4, 6, 8, 10]
    for distance in (4, 6, 8, 10)
        entry = manifest["distances"][string(distance)]
        archive = joinpath(root, "paper", "inputs", entry["archive"])
        @test isfile(archive)
        @test bytes2hex(sha256(read(archive))) == entry["sha256"]
        @test sort(entry["members"]) == [
            "check_matrix.txt",
            "column_transformation.txt",
            "row_transformation.txt",
        ]
    end
end

@testset "materialize paper inputs" begin
    mktempdir() do temp
        paths = materialize_paper_input(4, temp)
        @test all(isfile, values(paths))
        @test size(readdlm(paths.check_matrix, Bool)) == (224, 448)
        @test size(readdlm(paths.row_transformation, Bool)) == (224, 224)
        @test size(readdlm(paths.column_transformation, Bool)) == (448, 448)
        @test_throws ArgumentError materialize_paper_input(5, temp)
    end
end

@testset "reject unsafe paper input members" begin
    expected = ["check_matrix.txt"]
    @test_throws ArgumentError DecoderBenchmarks._validate_paper_members(
        [Tar.Header("../check_matrix.txt", :file, 0o644, 0, "")],
        expected,
    )
    @test_throws ArgumentError DecoderBenchmarks._validate_paper_members(
        [Tar.Header("/check_matrix.txt", :file, 0o644, 0, "")],
        expected,
    )
    @test_throws ArgumentError DecoderBenchmarks._validate_paper_members(
        [Tar.Header("check_matrix.txt", :symlink, 0o777, 0, "outside")],
        expected,
    )
end
