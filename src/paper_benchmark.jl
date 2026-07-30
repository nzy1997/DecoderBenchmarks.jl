Base.@kwdef struct PaperBenchmarkConfig
    mode::Symbol
    distances::Vector{Int}
    pvec::Vector{Float64}
    max_sim::Int
    max_error::Int
    workers::Int
    seed::UInt64
end

function paper_benchmark_config(mode::Symbol)
    if mode == :smoke
        return PaperBenchmarkConfig(
            mode=mode,
            distances=[4],
            pvec=[0.01],
            max_sim=32,
            max_error=8,
            workers=1,
            seed=UInt64(0x20260607),
        )
    elseif mode == :full
        return PaperBenchmarkConfig(
            mode=mode,
            distances=[4, 6, 8, 10],
            pvec=[
                0.0001, 0.0002, 0.0005, 0.001, 0.002,
                0.005, 0.008, 0.01, 0.015, 0.02,
            ],
            max_sim=1_000_000_000,
            max_error=2_000,
            workers=120,
            seed=UInt64(0x20260607),
        )
    end
    throw(ArgumentError("paper benchmark mode must be :smoke or :full"))
end

function paper_seed(base::UInt64, distance::Int, p::Float64, worker::Int)::UInt64
    worker > 0 || throw(ArgumentError("worker index must be positive"))
    payload = string(base, ':', distance, ':', repr(p), ':', worker)
    digest = sha256(codeunits(payload))
    return foldl(
        (acc, byte) -> (acc << 8) | UInt64(byte),
        digest[1:8];
        init=UInt64(0),
    )
end

function paper_decoder(distance::Int, paths)
    code = TensorQEC.FileCode(paths.check_matrix, "bbx^-1y_$distance")
    row = TensorQEC.Mod2.(readdlm(paths.row_transformation, Bool))
    column = TensorQEC.Mod2.(readdlm(paths.column_transformation, Bool))
    decoder = TensorQEC.TToricDecoder(row, column, 4, 3, distance^2)
    return (; code, decoder)
end

function _paper_worker(job)
    state = _get_benchmark_state(job.code, job.decoder)
    error_model = iid_error(job.p / 3, job.p / 3, job.p / 3, state.n)
    rng = Xoshiro(job.seed)
    decode_seconds = 0.0
    error_count = 0
    nsim = 0

    while nsim < job.max_sim && error_count < job.max_error
        error_pattern = random_error_pattern(rng, error_model)
        syndrome = syndrome_extraction(error_pattern, state.tanner)
        start_time = time_ns()
        result = decode(state.ct, syndrome)
        decode_seconds += (time_ns() - start_time) / 1.0e9

        nsim += 1
        syndrome == syndrome_extraction(result.error_pattern, state.tanner) || error(
            "decoder correction does not match the measured syndrome",
        )
        check_logical_error(
            result.error_pattern,
            error_pattern,
            state.lx,
            state.lz,
        ) && (error_count += 1)
    end

    return (; nsim, error_count, decode_seconds, seed=job.seed)
end

function _paper_jobs(config, code, decoder, distance, p)
    simulations, extra_simulations = divrem(config.max_sim, config.workers)
    worker_max_error = max(1, cld(config.max_error, config.workers))
    return [(
        code=code,
        decoder=decoder,
        p=p,
        max_sim=simulations + (worker_index <= extra_simulations),
        max_error=worker_max_error,
        seed=paper_seed(config.seed, distance, p, worker_index),
        worker_index=worker_index,
    ) for worker_index in 1:config.workers]
end

function _run_paper_jobs(config, jobs)
    config.workers == 1 && return [_paper_worker(only(jobs))]

    worker_processes = Distributed.workers()
    length(worker_processes) == config.workers || throw(ArgumentError(
        "paper benchmark requires exactly $(config.workers) worker processes; " *
        "found $(length(worker_processes))",
    ))
    futures = [
        Distributed.remotecall_eval(Main, process, :(using DecoderBenchmarks))
        for process in worker_processes
    ]
    foreach(fetch, futures)
    return Distributed.pmap(_paper_worker, jobs)
end

function run_paper_point(
    config::PaperBenchmarkConfig,
    distance::Int,
    p::Float64,
    output_dir::AbstractString,
)
    distance in config.distances || throw(ArgumentError(
        "distance $distance is not part of the $(config.mode) preset",
    ))
    p in config.pvec || throw(ArgumentError(
        "physical error rate $(repr(p)) is not part of the $(config.mode) preset",
    ))

    worker_results = mktempdir() do temp
        paths = materialize_paper_input(distance, temp)
        components = paper_decoder(distance, paths)
        jobs = _paper_jobs(config, components.code, components.decoder, distance, p)
        _run_paper_jobs(config, jobs)
    end

    result = (
        distance=distance,
        p=p,
        nsim=sum(worker.nsim for worker in worker_results),
        error_count=sum(worker.error_count for worker in worker_results),
        decode_seconds=sum(worker.decode_seconds for worker in worker_results),
        seed=config.seed,
        worker_count=config.workers,
    )

    mkpath(output_dir)
    filename = "logical-d$(distance)-p$(repr(p))-seed$(config.seed).json"
    open(joinpath(output_dir, filename), "w") do io
        write(io, JSON.json(Dict(string(key) => value for (key, value) in pairs(result))))
    end
    return result
end
