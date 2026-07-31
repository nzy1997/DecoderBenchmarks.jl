using Dates
using JSON
using SHA

const DISTANCES = (4, 6, 8, 10)
const BPOSD_GRID = [
    0.0001,
    0.0002,
    0.0005,
    0.001,
    0.002,
    0.005,
    0.008,
    0.01,
    0.015,
    0.02,
    0.03,
    0.04,
    0.056,
    0.06,
    0.12,
    0.15,
    0.2,
]
const DECODERBENCHMARKS_SOURCE_COMMIT = "7a7d3bddbc98bc7b2f2d36ba49edd05dcf63de2d"
const TENSORQEC_SOURCE_COMMIT = "9ffb8a918614efe4efeaeaafc7017da876af603d"

portable_path(parts...) = replace(joinpath(parts...), '\\' => '/')

function source_timestamp(path)
    value = unix2datetime(stat(path).mtime)
    return Dates.format(value, dateformat"yyyy-mm-ddTHH:MM:SS.sss") * "Z"
end

function require_source_file(path)
    isfile(path) || error("missing archived source file: $path")
    islink(path) && error("archived source file must not be a symlink: $path")
    return path
end

function copy_entry!(
    source_root,
    staging_root,
    source_path,
    curated_path;
    kind,
    decoder_series,
    distance,
)
    require_source_file(source_path)
    destination = joinpath(staging_root, split(curated_path, '/')...)
    mkpath(dirname(destination))
    cp(source_path, destination)
    read(source_path) == read(destination) || error("archive copy changed bytes: $source_path")

    data = JSON.parsefile(source_path)
    common = (
        curated_path = curated_path,
        decoder_series = decoder_series,
        distance = distance,
        source_file_mtime_utc = source_timestamp(source_path),
        kind = kind,
        original_basename = basename(source_path),
        sha256 = bytes2hex(sha256(read(source_path))),
        size_bytes = filesize(source_path),
        source_relative_path = replace(relpath(source_path, source_root), '\\' => '/'),
    )
    return common, data
end

function logical_entry(common, data)
    return merge(common, (
        failures = Int.(data["error_count"]),
        maximum_failures = Int(data["max_error"]),
        maximum_samples = Int(data["nsample"]),
        nsim = Int.(data["nsim"]),
        p_grid = Float64.(data["pvec"]),
    ))
end

function timing_entry(common, data)
    return merge(common, (
        p_grid = Float64.(data["pvec"]),
        samples = Int(data["nsample"]),
    ))
end

function exact_source(source_root, relative_path)
    return require_source_file(joinpath(source_root, split(relative_path, '/')...))
end

function select_bposd_sources(source_root, distance)
    folder = joinpath(source_root, "ldpc", "ldpc")
    candidates = filter(readdir(folder; join=true)) do path
        name = basename(path)
        startswith(name, "code=bbx_d$(distance)_") &&
            endswith(name, "_decoder=BpOsdDecoder.json")
    end

    by_probability = Dict{Float64, Vector{Tuple{String, Dict{String, Any}}}}()
    for path in candidates
        data = JSON.parsefile(path)
        length(data["pvec"]) == 1 || error("BP-OSD point must contain one p value: $path")
        probability = Float64(only(data["pvec"]))
        push!(get!(by_probability, probability, []), (path, data))
    end
    sort(collect(keys(by_probability))) == BPOSD_GRID || error(
        "unexpected BP-OSD grid for distance $distance",
    )

    return map(BPOSD_GRID) do probability
        candidates_at_p = by_probability[probability]
        maximum_nsim = maximum(Int(data["nsim"][1]) for (_, data) in candidates_at_p)
        winners = filter(candidates_at_p) do (_, data)
            Int(data["nsim"][1]) == maximum_nsim
        end
        length(winners) == 1 || error(
            "BP-OSD selection is tied for distance $distance, p=$probability",
        )
        return only(winners)
    end
end

function build_archive(source_root, staging_root)
    entries = Any[]

    for distance in DISTANCES
        name = "code=bbx^-1y_$(distance)_pmin=0.0001_pmax=0.02_" *
            "nsample=1000000000_maxerror=2000_workers=120_" *
            "decoder=TToricDecoder(Matching).json"
        source = exact_source(source_root, portable_path("TensorQEC", name))
        curated = portable_path("raw", "unitary-logical", name)
        common, data = copy_entry!(
            source_root,
            staging_root,
            source,
            curated;
            kind="unitary_logical",
            decoder_series="Layer Decoupling / unweighted MWPM",
            distance,
        )
        push!(entries, logical_entry(common, data))
    end

    for distance in DISTANCES
        name = "Time_code=bbx^-1y_$(distance)_pmin=0.01_pmax=0.2_" *
            "nsample=10000_decoder=TToricDecoder(Matching).json"
        source = exact_source(source_root, portable_path("TensorQEC", name))
        curated = portable_path("raw", "unitary-timing", name)
        common, data = copy_entry!(
            source_root,
            staging_root,
            source,
            curated;
            kind="unitary_timing",
            decoder_series="Layer Decoupling / unweighted MWPM",
            distance,
        )
        push!(entries, timing_entry(common, data))
    end

    for distance in DISTANCES
        name = "Time_code=bbx^-1y_$(distance)_pmin=0.01_pmax=0.2_" *
            "nsample=10000_decoder=BpOsdDecoder.json"
        source = exact_source(source_root, portable_path("ldpc", name))
        curated = portable_path("raw", "bposd-timing", name)
        common, data = copy_entry!(
            source_root,
            staging_root,
            source,
            curated;
            kind="bposd_timing",
            decoder_series="BP-OSD",
            distance,
        )
        push!(entries, timing_entry(common, data))
    end

    for distance in DISTANCES
        for (source, data) in select_bposd_sources(source_root, distance)
            curated = portable_path("raw", "bposd-logical", "d$distance", basename(source))
            common, copied_data = copy_entry!(
                source_root,
                staging_root,
                source,
                curated;
                kind="bposd_logical",
                decoder_series="BP-OSD",
                distance,
            )
            copied_data == data || error("BP-OSD source changed while archiving: $source")
            push!(entries, logical_entry(common, data))
        end
    end

    length(entries) == 80 || error("expected 80 archived files, found $(length(entries))")
    provenance = (
        dataset_class = "archived",
        environment = (
            status = "not_recorded",
            cpu = "not_recorded",
            os = "not_recorded",
            julia_version = "not_recorded",
            python_version = "not_recorded",
            package_versions = "not_recorded",
            limitation = "Historical result files contain no runtime environment metadata.",
        ),
        files = entries,
        input_provenance = (
            status = "not_recorded",
            limitation = "The original matrix-generation command and source revision were not recorded; the curated input archives are preserved by SHA-256.",
        ),
        methods = (
            bposd = (
                decoder = "BP-OSD",
                osd_method = "OSD_0",
                osd_order = 0,
                prior = "matched_per_point",
                serial_schedule = true,
                bp_iterations = 100,
                product_sum = true,
            ),
            unitary = (
                decoder = "TToricDecoder(Matching)",
                matching_weights = "unweighted",
            ),
        ),
        schema_version = 1,
        seed_status = "not_recorded",
        selection = (
            bposd_logical = "largest recorded nsim for each (distance, p); ties are rejected",
            bposd_timing = "10,000-sample timing series for distances 4, 6, 8, and 10",
            unitary_logical = "maximum_samples=1,000,000,000, maximum_failures=2,000, workers=120",
            unitary_timing = "10,000-sample timing series for distances 4, 6, 8, and 10",
        ),
        source_commits = (
            DecoderBenchmarks = DECODERBENCHMARKS_SOURCE_COMMIT,
            TensorQEC = TENSORQEC_SOURCE_COMMIT,
        ),
        statistics = (
            interval = "profile likelihood",
            likelihood_ratio = 1000.0,
        ),
        timing = (
            included = ["decoder call"],
            excluded = [
                "compilation",
                "error sampling",
                "syndrome generation",
                "syndrome validation",
                "process startup",
                "file I/O",
            ],
        ),
    )

    open(joinpath(staging_root, "provenance.json"), "w") do io
        JSON.print(io, provenance, 2)
    end
    return provenance
end

function curate_archive(source_root, output_root)
    source_root = abspath(source_root)
    output_root = abspath(output_root)
    isdir(source_root) || error("source result directory does not exist: $source_root")
    ispath(output_root) && error("output path already exists: $output_root")
    mkpath(dirname(output_root))
    mktempdir(dirname(output_root)) do temp
        staging_root = joinpath(temp, "archive")
        mkpath(staging_root)
        provenance = build_archive(source_root, staging_root)
        mv(staging_root, output_root)
        return provenance
    end
end

function main(args)
    length(args) == 2 || error(
        "usage: curate_paper_archive.jl SOURCE_RESULT_DIR OUTPUT_ARCHIVE_DIR",
    )
    provenance = curate_archive(args[1], args[2])
    println("curated $(length(provenance.files)) archived result files in $(abspath(args[2]))")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
