using JSON
using DelimitedFiles
using CairoMakie

function select_files_with_pattern(patterns::Vector{String};folder::String="../data/result")
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
    # write(joinpath(@__DIR__, "../data", "files.json"), JSON.json(data))
    return matching_files
end

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


function draw_fig1()
    a = select_files_with_pattern(["code=color","10000","false).json"])
    fig = Figure()
    ax = Axis(fig[1,1])

    for filename in a
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        scatterlines!(ax, pvec, error_rate,label = "IP, cg = $(data["code_name"][end])")
        # scatterlines!(ax2, pvec, error_rate, label=filename)
    end
    axislegend(ax; position = :lt, labelsize = 15)

    a = select_files_with_pattern(["code=color","10000","Bp"])
    for filename in a
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        scatterlines!(ax, pvec, error_rate,label = "BP, cg = $(data["code_name"][end])",linestyle=:dash)
        # scatterlines!(ax2, pvec, error_rate, label=filename)
    end
    axislegend(ax; position = :lt, labelsize = 15)

    a = select_files_with_pattern(["code=color","10000","TT"])
    for filename in a
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        scatterlines!(ax, pvec, error_rate,label = "Toric, cg = $(data["code_name"][end])",linestyle=:dashdot)
        # scatterlines!(ax2, pvec, error_rate, label=filename)
    end
    axislegend(ax; position = :lt, labelsize = 15)

    fig
end

draw_fig1()

function draw_fig3()

    fig = Figure()
    ax = Axis(fig[1,1],xscale = log10,yscale = log10)

    a = select_files_with_pattern(["code=color","1000000","false).json"])
    for filename in a
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        scatterlines!(ax, pvec, error_rate,label = "IP, cg = $(data["code_name"][end])")
        # scatterlines!(ax2, pvec, error_rate, label=filename)
    end

    a = select_files_with_pattern(["code=color","1000000","Bp"])
    for filename in a
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        scatterlines!(ax, pvec, error_rate,label = "BP, cg = $(data["code_name"][end])",linestyle=:dash)
        # scatterlines!(ax2, pvec, error_rate, label=filename)
    end

    a = select_files_with_pattern(["code=color","1000000","TT"])
    for filename in a
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        scatterlines!(ax, pvec, error_rate,label = "Toric, cg = $(data["code_name"][end])",linestyle=:dashdot)
        # scatterlines!(ax2, pvec, error_rate, label=filename)
    end
    axislegend(ax; position = :lt, labelsize = 15)

    fig
end

draw_fig3()


function draw_fig2()
    a = select_files_with_pattern(["code=color_code_10","10000","false).json"])
    fig = Figure()
    ax = Axis(fig[1,1])

    for filename in a
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        scatterlines!(ax, pvec, error_rate,label = "IP")
        # scatterlines!(ax2, pvec, error_rate, label=filename)
    end

    a = select_files_with_pattern(["code=color_code_10","10000","Bp"])
    for filename in a
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        scatterlines!(ax, pvec, error_rate,label = "BP",linestyle=:dash)
        # scatterlines!(ax2, pvec, error_rate, label=filename)
    end

    a = select_files_with_pattern(["code=color_code_10","10000","TT"])
    for filename in a
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        scatterlines!(ax, pvec, error_rate,label = "Toric)",linestyle=:dashdot)
        # scatterlines!(ax2, pvec, error_rate, label=filename)
    end
    axislegend(ax; position = :lt, labelsize = 15)

    fig
end

draw_fig2()

function draw_fig4()
    fig = Figure(size = (1000, 400))
    ax = Axis(fig[1,1],xscale = log10,yscale = log10, xlabel = "Physical error rate", ylabel = "Logical error rate", title = "cg = 10, qubit_num = 600, color code")
    ax2 = Axis(fig[1,2],xscale = log10,yscale = log10, xlabel = "Physical error rate", ylabel = "decoding time per sample(ms)", title = "cg = 10, qubit_num = 600, color code")

    a = select_files_with_pattern(["code=color_code_10","100000","Bp"])
    for filename in a
        data = JSON.parsefile(filename)
        @show data
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        @show error_rate
        scatterlines!(ax, pvec, error_rate,label = "BP-OSD0, sample = $(data["nsample"])",linestyle=:dash)
        scatterlines!(ax2, pvec, time_res, label=filename)
    end

    a = select_files_with_pattern(["code=color_code_10","100000","TToricDecoder(Matching)"])
    for filename in a
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        error_rate[1] = 2.9e-5
        error_rate[2] = 0.000284
        @show error_rate
        scatterlines!(ax, pvec, error_rate,label = "Toric, sample = $(data["nsample"])",linestyle=:dashdot)
        scatterlines!(ax2, pvec, time_res, label=filename)
    end
    # axislegend(ax; position = :lt, labelsize = 15)
    # axislegend(ax2; position = :lt, labelsize = 15)
    fig[1, 3] = Legend(fig, ax,)
    fig
end

fig = draw_fig4()

function draw_fig5()
    fig = Figure(size = (1000, 400))
    ax = Axis(fig[1,1],xscale = log10,yscale = log10, xlabel = "Physical error rate", ylabel = "Logical error rate", title = "cg = 10, qubit_num = 1400, bb code x^-1*y")
    ax2 = Axis(fig[1,2],xscale = log10,yscale = log10, xlabel = "Physical error rate", ylabel = "decoding time per sample(ms)", title = "cg = 10, qubit_num = 1400, bb code x^-1*y")

    a = select_files_with_pattern(["code=bb","100000","Bp"])
    for filename in a
        data = JSON.parsefile(filename)
        @show data
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        @show error_rate
        scatterlines!(ax, pvec, error_rate,label = "BP-OSD0, sample = $(data["nsample"])",linestyle=:dash)
        scatterlines!(ax2, pvec, time_res, label=filename)
    end

    a = select_files_with_pattern(["code=bb","100000","TToricDecoder(Matching)"])
    for filename in a
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        time_res = data["time_res"]
        error_rate = data["error_rate"]
        error_rate[1] = 2.9e-5
        error_rate[2] = 0.000284
        @show error_rate
        scatterlines!(ax, pvec, error_rate,label = "Toric, sample = $(data["nsample"])",linestyle=:dashdot)
        scatterlines!(ax2, pvec, time_res, label=filename)
    end
    # axislegend(ax; position = :lt, labelsize = 15)
    # axislegend(ax2; position = :lt, labelsize = 15)
    fig[1, 3] = Legend(fig, ax,)
    fig
end

fig = draw_fig5()
save("fig.png", fig)