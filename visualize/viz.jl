using DelimitedFiles
using CairoMakie


function draw(result_dir)
    fig_error = Figure()
    ax_error = Axis(fig_error[1, 1], xlabel = "Physical Error Rate",
    ylabel = "Logical Error Rate")

    fig_time = Figure()
    ax_time = Axis(fig_time[1, 1], xlabel = "Physical Error Rate",
    ylabel = "Time(s)")

    for f in readdir(result_dir)
        if startswith(f, "Error_rate")
            data = readdlm(joinpath(result_dir, f))
            lines!(ax_error, data[1,:], data[2,:])
        elseif startswith(f, "Time")
            data = readdlm(joinpath(result_dir, f))
            lines!(ax_time, data[1,:], data[2,:])
        end
    end

    # fig_error[1, 2] = Legend(fig_error, ax_error)
    # fig_time[1, 2] = Legend(fig_time, ax_time)

    fig_error, fig_time
    save("visualize/error_rate.svg", fig_error)
    save("visualize/time.svg", fig_time)
end

draw("data/result")