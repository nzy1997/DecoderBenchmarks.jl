include("plotting_functions.jl")

function draw_fig6()
    fig = Figure(size = (1300, 400))
    ax = Axis(fig[1,1],xscale = log10,yscale = log10, xlabel = "Physical error rate", ylabel = "Logical error rate", title = "d = 10 Toric code, qubit_num = 1400, bb code x^-1*y")
    ax2 = Axis(fig[1,2],xscale = log10,yscale = log10, xlabel = "Physical error rate", ylabel = "Decoding time per sample(s)", title = "d = 10 Toric code, qubit_num = 1400, bb code x^-1*y")

    a = select_files_with_pattern(["code=bb","100000","Bp","pmin"])
    for filename in a
        data = JSON.parsefile(filename)
        # @show data
        pvec = data["pvec"]
        nsim = Int.(data["nsim"])
        error_count = Int.(data["error_count"])
        time_res = data["time_res"]
        lows, avs, highs = sinter_like_fit_binomial(nsim, error_count, 1000.0)
        avs_plot, ylow, yhigh = prepare_errorbar_data(avs, lows, highs)
        errorbars!(ax,pvec, avs_plot, ylow, yhigh,
        whiskerwidth = 10)
        scatterlines!(ax, pvec, avs_plot,label = "BP-OSD0",linestyle=:dash)
        # scatterlines!(ax2, pvec, time_res, label="BP-OSD0, sample = $(data["nsample"])")
    end

    a = select_files_with_pattern(["Time","code=bb","10000","Bp"])
    for filename in a
        data = JSON.parsefile(filename)
        # @show data
        pvec = data["pvec"]
        time_res = data["time_res"]
        # @show error_rate
        scatterlines!(ax2, pvec, time_res,label = "BP-OSD0",linestyle=:dash)
        # scatterlines!(ax2, pvec, time_res, label="BP-OSD0, sample = $(data["nsample"])")
    end

    a = select_files_with_pattern(["code=bb","1000","TToricDecoder(Matching)","workers=6"])
    for filename in a
        @show filename
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        nsim = Int.(data["nsim"])
        error_count = Int.(data["error_count"])
        lows, avs, highs = sinter_like_fit_binomial(nsim, error_count, 1000.0)
        @show avs
        avs_plot, ylow, yhigh = prepare_errorbar_data(avs, lows, highs)
        errorbars!(ax,pvec, avs_plot, ylow, yhigh,
        whiskerwidth = 10)
        scatterlines!(ax, pvec, avs_plot,label = "Toric Matching")
    end

    a = select_files_with_pattern(["Time","code=bb","1000","TToricDecoder(Matching)"])
    for filename in a
        @show filename
        data = JSON.parsefile(filename)
        pvec = data["pvec"]
        time_res = data["time_res"]
        scatterlines!(ax2, pvec, time_res, label="Toric Matching")
    end
    # fig[1, 2] = Legend(fig, ax,)
    fig[1, 3] = Legend(fig, ax2,)
    fig
end

fig = draw_fig6()
save("fig6.png", fig)

println("Hello from Julia on HPC")
println("Julia version: ", VERSION)
println("Threads: ", Threads.nthreads())
