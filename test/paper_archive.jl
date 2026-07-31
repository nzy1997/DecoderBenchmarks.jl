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
    @test metadata["noise_model"]["name"] == "independent_depolarizing_pauli"
    @test metadata["noise_model"]["single_qubit_probabilities"] == Dict(
        "I" => "1-p",
        "X" => "p/3",
        "Y" => "p/3",
        "Z" => "p/3",
    )
    @test metadata["stopping_rule"]["parallel_budget"] ==
        "ceil_remaining_per_worker_then_sum"
    @test metadata["stopping_rule"]["maximum_aggregate_failures"] ==
        "maximum_failures + workers - 1"
    @test metadata["stopping_rule"]["maximum_aggregate_samples"] ==
        "maximum_samples + workers - 1"
    @test metadata["source_commits"]["DecoderBenchmarks"] ==
        "7a7d3bddbc98bc7b2f2d36ba49edd05dcf63de2d"
    @test metadata["source_commits"]["TensorQEC"] ==
        "9ffb8a918614efe4efeaeaafc7017da876af603d"

    entries = metadata["files"]
    @test count(entry -> entry["kind"] == "unitary_logical", entries) == 4
    @test count(entry -> entry["kind"] == "unitary_timing", entries) == 4
    @test count(entry -> entry["kind"] == "bposd_timing", entries) == 4
    @test count(entry -> entry["kind"] == "bposd_logical", entries) == 68

    logical_entries = filter(
        entry -> entry["kind"] in ("unitary_logical", "bposd_logical"),
        entries,
    )
    @test maximum(maximum(entry["failures"]) for entry in logical_entries) == 2_089
    for entry in logical_entries
        worker_match = match(r"workers=(\d+)", entry["original_basename"])
        @test worker_match !== nothing
        worker_count = parse(Int, only(worker_match.captures))
        @test maximum(entry["failures"]) <=
            entry["maximum_failures"] + worker_count - 1
        @test maximum(entry["nsim"]) <=
            entry["maximum_samples"] + worker_count - 1
    end

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
