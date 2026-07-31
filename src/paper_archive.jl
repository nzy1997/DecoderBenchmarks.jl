paper_archive_root() = normpath(joinpath(@__DIR__, "..", "paper", "archive"))

function archive_metadata(archive_root::AbstractString=paper_archive_root())
    provenance_path = joinpath(archive_root, "provenance.json")
    isfile(provenance_path) || throw(ArgumentError(
        "paper archive provenance is missing: $provenance_path",
    ))
    metadata = JSON.parsefile(provenance_path)
    metadata["schema_version"] == 1 || throw(ArgumentError(
        "unsupported paper archive schema version",
    ))
    metadata["seed_status"] == "not_recorded" || throw(ArgumentError(
        "archived paper data must be labelled seed_status=not_recorded",
    ))
    return metadata
end

function _verified_archive_path(archive_root::AbstractString, relative_path::AbstractString)
    isabspath(relative_path) && throw(ArgumentError(
        "archive paths must be relative: $relative_path",
    ))
    components = splitpath(relative_path)
    any(component -> component == "..", components) && throw(ArgumentError(
        "archive paths must not contain '..': $relative_path",
    ))
    isempty(components) && throw(ArgumentError("archive path must not be empty"))

    root = abspath(archive_root)
    path = abspath(joinpath(root, relative_path))
    relative = relpath(path, root)
    (relative == ".." || startswith(relative, ".." * string(Base.Filesystem.path_separator))) &&
        throw(ArgumentError("archive path escapes its root: $relative_path"))
    isfile(path) || throw(ArgumentError("archived result is missing: $relative_path"))
    islink(path) && throw(ArgumentError("archived result must not be a symlink: $relative_path"))
    return path
end

function _validate_archive_summary(entry, data, path)
    relative_path = entry["curated_path"]
    filesize(path) == Int(entry["size_bytes"]) || throw(ArgumentError(
        "archive size mismatch for $relative_path",
    ))
    Float64.(data["pvec"]) == Float64.(entry["p_grid"]) || throw(ArgumentError(
        "archive probability grid mismatch for $relative_path",
    ))

    kind = entry["kind"]
    if kind in ("unitary_logical", "bposd_logical")
        Int.(data["nsim"]) == Int.(entry["nsim"]) || throw(ArgumentError(
            "archive sample-count summary mismatch for $relative_path",
        ))
        Int.(data["error_count"]) == Int.(entry["failures"]) || throw(ArgumentError(
            "archive failure-count summary mismatch for $relative_path",
        ))
        Int(data["nsample"]) == Int(entry["maximum_samples"]) || throw(ArgumentError(
            "archive maximum-samples summary mismatch for $relative_path",
        ))
        Int(data["max_error"]) == Int(entry["maximum_failures"]) || throw(ArgumentError(
            "archive maximum-failures summary mismatch for $relative_path",
        ))
    elseif kind in ("unitary_timing", "bposd_timing")
        Int(data["nsample"]) == Int(entry["samples"]) || throw(ArgumentError(
            "archive timing-samples summary mismatch for $relative_path",
        ))
    else
        throw(ArgumentError("unsupported archive kind for $relative_path: $kind"))
    end
    return nothing
end

function verified_archive_entries(archive_root::AbstractString=paper_archive_root())
    metadata = archive_metadata(archive_root)
    entries = get(metadata, "files", nothing)
    entries isa AbstractVector || throw(ArgumentError(
        "paper archive provenance must contain a files array",
    ))

    return map(entries) do entry
        relative_path = entry["curated_path"]
        path = _verified_archive_path(archive_root, relative_path)
        expected = lowercase(entry["sha256"])
        occursin(r"^[0-9a-f]{64}$", expected) || throw(ArgumentError(
            "invalid archive SHA-256 for $relative_path",
        ))
        actual = bytes2hex(sha256(read(path)))
        actual == expected || throw(ArgumentError(
            "archive SHA-256 mismatch for $relative_path",
        ))
        data = JSON.parsefile(path)
        _validate_archive_summary(entry, data, path)
        return (; entry, data, path)
    end
end

function _archive_series(kind::AbstractString, distance::Integer; archive_root=paper_archive_root())
    matches = filter(verified_archive_entries(archive_root)) do item
        item.entry["kind"] == kind && item.entry["distance"] == distance
    end
    length(matches) == 1 || throw(ArgumentError(
        "expected one $kind archive for distance $distance, found $(length(matches))",
    ))
    return only(matches).data
end

function _series_index(data, p::Real)
    index = findfirst(==(Float64(p)), Float64.(data["pvec"]))
    index === nothing && throw(ArgumentError("physical error rate $p is not archived"))
    return index
end

function archived_unitary_point(
    distance::Integer,
    p::Real;
    archive_root::AbstractString=paper_archive_root(),
)
    data = _archive_series("unitary_logical", distance; archive_root)
    index = _series_index(data, p)
    return (
        p = Float64(data["pvec"][index]),
        nsim = Int(data["nsim"][index]),
        error_count = Int(data["error_count"][index]),
        time_res = Float64(data["time_res"][index]),
    )
end

function archived_unitary_time(
    distance::Integer,
    p::Real;
    archive_root::AbstractString=paper_archive_root(),
)
    data = _archive_series("unitary_timing", distance; archive_root)
    return Float64(data["time_res"][_series_index(data, p)])
end
