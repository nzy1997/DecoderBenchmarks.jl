using DecoderBenchmarks
using JSON

const NORMALIZED_DISTANCES = (4, 6, 8, 10)

function _canonical_json(io::IO, value)
    if value isa AbstractDict
        keyed = Dict(string(key) => item for (key, item) in pairs(value))
        keys_in_order = sort(collect(keys(keyed)))
        write(io, '{')
        for (index, key) in enumerate(keys_in_order)
            index > 1 && write(io, ',')
            JSON.print(io, key)
            write(io, ':')
            _canonical_json(io, keyed[key])
        end
        write(io, '}')
    elseif value isa NamedTuple
        _canonical_json(io, Dict(pairs(value)))
    elseif value isa AbstractVector || value isa Tuple
        write(io, '[')
        for (index, item) in enumerate(value)
            index > 1 && write(io, ',')
            _canonical_json(io, item)
        end
        write(io, ']')
    elseif value isa AbstractFloat
        isfinite(value) || throw(ArgumentError("canonical JSON does not support non-finite numbers"))
        JSON.print(io, value)
    elseif value isa Integer || value isa AbstractString || value isa Bool || value === nothing
        JSON.print(io, value)
    else
        throw(ArgumentError("unsupported canonical JSON value: $(typeof(value))"))
    end
end

function _profile_payload(pvec, nsim, error_count; h)
    intervals = map(zip(nsim, error_count)) do (sample_count, failures)
        profile_likelihood_interval(sample_count, failures; h=Float64(h))
    end
    return Dict(
        "error_count" => Int.(error_count),
        "error_rate" => Float64.(error_count) ./ Int.(nsim),
        "interval" => Dict(
            "estimate" => [point.estimate for point in intervals],
            "high" => [point.high for point in intervals],
            "likelihood_ratio" => Float64(h),
            "low" => [point.low for point in intervals],
        ),
        "nsim" => Int.(nsim),
        "pvec" => Float64.(pvec),
    )
end

function _only_archive_entry(entries, kind, distance)
    matches = filter(entries) do item
        item.entry["kind"] == kind && item.entry["distance"] == distance
    end
    length(matches) == 1 || throw(ArgumentError(
        "expected one $kind archive for distance $distance, found $(length(matches))",
    ))
    return only(matches)
end

function _normalized_payload(archive_root)
    metadata = archive_metadata(archive_root)
    entries = verified_archive_entries(archive_root)
    h = Float64(metadata["statistics"]["likelihood_ratio"])
    logical_error = Dict{String, Any}()
    decoding_time = Dict{String, Any}()

    for distance in NORMALIZED_DISTANCES
        unitary = _only_archive_entry(entries, "unitary_logical", distance)
        bposd_items = filter(entries) do item
            item.entry["kind"] == "bposd_logical" &&
                item.entry["distance"] == distance
        end
        sort!(bposd_items; by=item -> Float64(only(item.data["pvec"])))
        length(bposd_items) == 17 || throw(ArgumentError(
            "expected 17 BP-OSD points for distance $distance",
        ))

        bposd_pvec = [Float64(only(item.data["pvec"])) for item in bposd_items]
        length(unique(bposd_pvec)) == length(bposd_pvec) || throw(ArgumentError(
            "duplicate BP-OSD probabilities for distance $distance",
        ))
        logical_error[string(distance)] = Dict(
            "bposd" => merge(
                _profile_payload(
                    bposd_pvec,
                    [Int(only(item.data["nsim"])) for item in bposd_items],
                    [Int(only(item.data["error_count"])) for item in bposd_items];
                    h,
                ),
                Dict("source_files" => [item.entry["curated_path"] for item in bposd_items]),
            ),
            "unitary" => merge(
                _profile_payload(
                    unitary.data["pvec"],
                    unitary.data["nsim"],
                    unitary.data["error_count"];
                    h,
                ),
                Dict("source_files" => [unitary.entry["curated_path"]]),
            ),
        )

        unitary_timing = _only_archive_entry(entries, "unitary_timing", distance)
        bposd_timing = _only_archive_entry(entries, "bposd_timing", distance)
        decoding_time[string(distance)] = Dict(
            "bposd" => Dict(
                "pvec" => Float64.(bposd_timing.data["pvec"]),
                "source_files" => [bposd_timing.entry["curated_path"]],
                "time_res" => Float64.(bposd_timing.data["time_res"]),
            ),
            "unitary" => Dict(
                "pvec" => Float64.(unitary_timing.data["pvec"]),
                "source_files" => [unitary_timing.entry["curated_path"]],
                "time_res" => Float64.(unitary_timing.data["time_res"]),
            ),
        )
    end

    provenance_files = [
        Dict(
            "curated_path" => item.entry["curated_path"],
            "sha256" => item.entry["sha256"],
        ) for item in entries
    ]
    return Dict(
        "dataset_class" => metadata["dataset_class"],
        "decoding_time" => decoding_time,
        "distances" => collect(NORMALIZED_DISTANCES),
        "logical_error" => logical_error,
        "provenance" => Dict(
            "environment" => metadata["environment"],
            "files" => provenance_files,
            "input_provenance" => metadata["input_provenance"],
            "methods" => metadata["methods"],
            "noise_model" => metadata["noise_model"],
            "selection" => metadata["selection"],
            "source_commits" => metadata["source_commits"],
            "stopping_rule" => metadata["stopping_rule"],
            "timing" => metadata["timing"],
        ),
        "schema_version" => 1,
        "seed_status" => metadata["seed_status"],
        "statistics" => metadata["statistics"],
    )
end

function export_normalized_archive(
    output_root::AbstractString;
    archive_root::AbstractString=paper_archive_root(),
)
    destination_root = abspath(output_root)
    mkpath(destination_root)
    destination = joinpath(destination_root, "decoding_benchmark.json")
    payload = _normalized_payload(archive_root)
    open(destination, "w") do io
        _canonical_json(io, payload)
        write(io, '\n')
    end
    return destination
end

function main(args)
    length(args) == 1 || throw(ArgumentError(
        "usage: export_normalized.jl OUTPUT_DIRECTORY",
    ))
    path = export_normalized_archive(only(args))
    println("wrote canonical archived decoder data to $path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
