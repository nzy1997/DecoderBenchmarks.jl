using JSON
using SHA
using Test

@testset "paper archive" begin
    metadata = archive_metadata()
    @test metadata["schema_version"] == 1
    @test metadata["dataset_class"] == "archived"
    @test metadata["seed_status"] == "not_recorded"
    @test metadata["environment"]["status"] == "not_recorded"
    @test metadata["environment"]["cpu"] == "not_recorded"
    @test metadata["environment"]["os"] == "not_recorded"
    @test metadata["input_provenance"]["status"] == "not_recorded"
    @test metadata["source_commits"]["DecoderBenchmarks"] ==
        "7a7d3bddbc98bc7b2f2d36ba49edd05dcf63de2d"
    @test metadata["source_commits"]["TensorQEC"] ==
        "9ffb8a918614efe4efeaeaafc7017da876af603d"

    entries = metadata["files"]
    @test count(entry -> entry["kind"] == "unitary_logical", entries) == 4
    @test count(entry -> entry["kind"] == "unitary_timing", entries) == 4
    @test count(entry -> entry["kind"] == "bposd_timing", entries) == 4
    @test count(entry -> entry["kind"] == "bposd_logical", entries) == 68

    archive_root = paper_archive_root()
    for entry in entries
        relative_path = entry["curated_path"]
        @test !isabspath(relative_path)
        @test all(part -> part != "..", splitpath(relative_path))
        @test basename(relative_path) == entry["original_basename"]
        @test !isabspath(entry["source_relative_path"])
        path = joinpath(archive_root, relative_path)
        @test isfile(path)
        @test bytes2hex(sha256(read(path))) == entry["sha256"]
    end

    point = archived_unitary_point(4, 0.0001)
    @test point.error_count == 2_040
    @test point.nsim == 1_088_545
    @test archived_unitary_time(4, 0.01) == 5.317783355712891e-6

    verified = verified_archive_entries()
    @test length(verified) == length(entries)
    for distance in (4, 6, 8, 10)
        selected = filter(
            item -> item.entry["kind"] == "bposd_logical" &&
                item.entry["distance"] == distance,
            verified,
        )
        @test length(selected) == 17
        @test issorted([item.data["pvec"][1] for item in selected])
        @test length(unique(item.data["pvec"][1] for item in selected)) == 17
    end
end

@testset "reject damaged paper archive" begin
    source_root = paper_archive_root()
    first_entry = first(archive_metadata()["files"])

    mktempdir() do temp
        damaged_root = joinpath(temp, "archive")
        cp(source_root, damaged_root)
        open(joinpath(damaged_root, first_entry["curated_path"]), "a") do io
            write(io, '\n')
        end
        @test_throws ArgumentError verified_archive_entries(damaged_root)
    end

    mktempdir() do temp
        damaged_root = joinpath(temp, "archive")
        cp(source_root, damaged_root)
        provenance_path = joinpath(damaged_root, "provenance.json")
        metadata = JSON.parsefile(provenance_path)
        metadata["files"][1]["curated_path"] = "../outside.json"
        open(provenance_path, "w") do io
            JSON.print(io, metadata, 2)
        end
        @test_throws ArgumentError verified_archive_entries(damaged_root)
    end

    for (field, replacement) in (
        ("size_bytes", first_entry["size_bytes"] + 1),
        ("p_grid", [0.987654321]),
    )
        mktempdir() do temp
            damaged_root = joinpath(temp, "archive")
            cp(source_root, damaged_root)
            provenance_path = joinpath(damaged_root, "provenance.json")
            metadata = JSON.parsefile(provenance_path)
            metadata["files"][1][field] = replacement
            open(provenance_path, "w") do io
                JSON.print(io, metadata, 2)
            end
            @test_throws ArgumentError verified_archive_entries(damaged_root)
        end
    end
end
