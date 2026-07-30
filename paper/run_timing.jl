using DecoderBenchmarks
using JSON
using Random
using TensorQEC

const PAPER_TIMING_GRID = [0.01, 0.015, 0.02, 0.03, 0.04, 0.056, 0.06, 0.12, 0.15, 0.2]
const TIMING_EXCLUSIONS = [
    "compilation",
    "error_sampling",
    "syndrome_generation",
    "syndrome_validation",
    "process_startup",
    "file_io",
]

function timing_mode(args)
    length(args) == 1 || throw(ArgumentError("usage: run_timing.jl smoke|full"))
    mode = Symbol(only(args))
    mode in (:smoke, :full) || throw(ArgumentError("timing mode must be smoke or full"))
    return mode
end

function run_timing_point(distance, p, warmup, samples, seed, output_dir)
    mktempdir() do temp
        paths = materialize_paper_input(distance, temp)
        components = paper_decoder(distance, paths)
        tanner = TensorQEC.CSSTannerGraph(components.code)
        compiled = TensorQEC.compile(components.decoder, tanner)
        error_model = TensorQEC.iid_error(
            p / 3,
            p / 3,
            p / 3,
            tanner.stgz.nq,
        )
        rng = Xoshiro(paper_seed(seed, distance, p, 1))
        decode_seconds = 0.0

        for sample_index in 1:(warmup + samples)
            error_pattern = TensorQEC.random_error_pattern(rng, error_model)
            syndrome = TensorQEC.syndrome_extraction(error_pattern, tanner)
            start_time = time_ns()
            result = TensorQEC.decode(compiled, syndrome)
            elapsed = (time_ns() - start_time) / 1.0e9
            syndrome == TensorQEC.syndrome_extraction(result.error_pattern, tanner) || error(
                "decoder correction does not match the measured syndrome",
            )
            sample_index > warmup && (decode_seconds += elapsed)
        end

        data = Dict(
            "distance" => distance,
            "p" => p,
            "decoder" => "TToricDecoder(Matching)",
            "seed" => seed,
            "timing_scope" => "decode_call_only",
            "warmup" => warmup,
            "samples" => samples,
            "decode_seconds" => decode_seconds,
            "average_decode_seconds" => decode_seconds / samples,
            "excluded" => TIMING_EXCLUSIONS,
        )
        mkpath(output_dir)
        filename = "timing-d$(distance)-p$(repr(p))-seed$(seed).json"
        open(joinpath(output_dir, filename), "w") do io
            write(io, JSON.json(data))
        end
    end
end

mode = timing_mode(ARGS)
distances = mode == :smoke ? [4] : [4, 6, 8, 10]
pvec = mode == :smoke ? [0.01] : PAPER_TIMING_GRID
warmup = mode == :smoke ? 1 : 100
samples = mode == :smoke ? 4 : 10_000
seed = UInt64(0x20260607)
root = normpath(joinpath(@__DIR__, ".."))
output_dir = joinpath(root, "build", "paper", string(mode), "timing")
println(
    "paper timing benchmark mode=$mode distances=$distances pvec=$pvec " *
    "warmup=$warmup samples=$samples seed=$seed scope=decode_call_only",
)

for distance in distances, p in pvec
    run_timing_point(distance, p, warmup, samples, seed, output_dir)
    println("paper timing point distance=$distance p=$p seed=$seed")
end
