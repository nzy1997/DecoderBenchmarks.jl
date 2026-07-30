const PAPER_INPUT_DISTANCES = (4, 6, 8, 10)

function _paper_input_manifest()
    JSON.parsefile(joinpath(pkgdir(DecoderBenchmarks), "paper", "inputs", "manifest.json"))
end

function _validate_paper_members(headers, expected_members)
    actual_members = sort([header.path for header in headers])
    actual_members == expected_members || throw(ArgumentError(
        "paper input archive members do not match the manifest",
    ))

    for header in headers
        parts = split(replace(header.path, '\\' => '/'), '/'; keepempty=true)
        safe_path = !isabspath(header.path) && !any(==(".."), parts)
        safe_path && header.type == :file || throw(ArgumentError(
            "paper input archive contains an unsafe member: $(repr(header.path))",
        ))
    end
end

"""
    materialize_paper_input(distance, output_root) -> NamedTuple

Verify and extract one curated paper decoder input archive below `output_root`.
Only the three matrix files recorded in the checked-in manifest are accepted.
"""
function materialize_paper_input(distance::Int, output_root::AbstractString)
    distance in PAPER_INPUT_DISTANCES || throw(ArgumentError(
        "distance must be one of 4, 6, 8, 10",
    ))

    manifest = _paper_input_manifest()
    entry = manifest["distances"][string(distance)]
    input_root = joinpath(pkgdir(DecoderBenchmarks), "paper", "inputs")
    archive = joinpath(input_root, entry["archive"])
    actual_sha256 = bytes2hex(sha256(read(archive)))
    actual_sha256 == entry["sha256"] || throw(ArgumentError(
        "paper input archive checksum mismatch for distance $distance",
    ))

    expected_members = sort(String.(entry["members"]))
    headers = open(GzipDecompressorStream, archive) do stream
        Tar.list(stream)
    end
    _validate_paper_members(headers, expected_members)

    destination = joinpath(output_root, "d$distance")
    mkpath(output_root)
    open(GzipDecompressorStream, archive) do stream
        Tar.extract(stream, destination; copy_symlinks=false, set_permissions=false)
    end

    return (
        check_matrix = joinpath(destination, "check_matrix.txt"),
        row_transformation = joinpath(destination, "row_transformation.txt"),
        column_transformation = joinpath(destination, "column_transformation.txt"),
    )
end
