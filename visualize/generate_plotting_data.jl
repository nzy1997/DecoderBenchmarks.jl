using JSON
using DelimitedFiles

function select_files_with_pattern(patterns::Vector{String};folder::String="data/result")
    matching_files = String[]
    file_count = 0
    for (root, dirs, files) in walkdir(folder)
        for file in files
            if all(occursin(pattern, file) for pattern in patterns)
                file_count += 1
                push!(matching_files, joinpath(root, file))
            end
        end
    end
    data = Dict("file_count" => file_count, "files" => matching_files)
    write(joinpath(@__DIR__, "data", "files.json"), JSON.json(data))
    return matching_files
end

# a = select_files_with_pattern(["code=SurfaceCode","10000"])

function collect_all_files_with_pattern(;folder::String="data/result")
    rm(joinpath(@__DIR__, "../", "data/result", "files.txt"), force=true)
    res_file = open(joinpath(@__DIR__, "../", "data/result", "files.txt"),"a")
    for (root, dirs, files) in walkdir(folder)
        for file in files
            if file != "files.txt"
                write(res_file,"$(joinpath(root, file))\n")
            end
        end
    end
    close(res_file)
end

collect_all_files_with_pattern()