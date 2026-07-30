using DecoderBenchmarks
using Distributed

function benchmark_mode(args)
    length(args) == 1 || throw(ArgumentError("usage: run_logical_error.jl smoke|full"))
    mode = Symbol(only(args))
    mode in (:smoke, :full) || throw(ArgumentError(
        "logical-error mode must be smoke or full",
    ))
    return mode
end

mode = benchmark_mode(ARGS)
config = paper_benchmark_config(mode)
if mode == :full
    length(workers()) == config.workers || throw(ArgumentError(
        "full mode requires exactly $(config.workers) worker processes; " *
        "start it with `julia --project -p $(config.workers) paper/run_logical_error.jl full`",
    ))
end

root = normpath(joinpath(@__DIR__, ".."))
output_dir = joinpath(root, "build", "paper", string(mode), "logical")
println(
    "paper logical benchmark " *
    "mode=$(config.mode) distances=$(config.distances) pvec=$(config.pvec) " *
    "max_sim=$(config.max_sim) max_error=$(config.max_error) " *
    "workers=$(config.workers) seed=$(config.seed)",
)

for distance in config.distances, p in config.pvec
    result = run_paper_point(config, distance, p, output_dir)
    println(
        "paper logical point distance=$(result.distance) p=$(result.p) " *
        "nsim=$(result.nsim) error_count=$(result.error_count) seed=$(result.seed)",
    )
end
