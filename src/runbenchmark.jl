const _benchmark_cache = Dict{Tuple{String,String}, Any}()

function _get_benchmark_state(code::TensorQEC.QuantumCode, decoder::TensorQEC.AbstractDecoder)
    key = (string(code), string(decoder))
    return get!(_benchmark_cache, key) do
        tanner = CSSTannerGraph(code)
        ct = compile(decoder, tanner)
        lx, lz = logical_operator(tanner)
        n = tanner.stgz.nq
        (; tanner, ct, lx, lz, n)
    end
end

function _benchmark_chunk(job)
    code, decoder, p, max_sim, max_error = job
    state = _get_benchmark_state(code, decoder)
    em = iid_error(p / 3, p / 3, p / 3, state.n)
    time_sum = 0.0
    error_count = 0
    nsim = 0
    while nsim < max_sim && error_count < max_error
        eq = random_error_pattern(em)
        syn = syndrome_extraction(eq, state.tanner)
        time_start = time()
        deres = decode(state.ct, syn)
        time_end = time()
        time_sum += time_end - time_start
        nsim += 1
        @assert syn == syndrome_extraction(deres.error_pattern, state.tanner)
        check_logical_error(deres.error_pattern, eq, state.lx, state.lz) && (error_count += 1)
    end
    return (; time_sum, nsim, error_count, n=state.n)
end

"""
    run_benchmark(code::TensorQEC.QuantumCode,pvec::AbstractVector,max_sim::Int,max_error::Int,decoder::TensorQEC.AbstractDecoder,result_dir::String)
    
Run the benchmark for the decoder `decoder` on the code `code` with the error probability `pvec` and save the result to `result_dir`. Error patterns are generated on the fly (no files are read or written). For each `p`, the simulation stops when either `max_sim` samples or `max_error` logical errors is reached. If multiple worker processes are available, each `p` is simulated in parallel across workers; in that case, `max_error` can be exceeded by a small amount due to chunked parallel execution. The result is saved as a json file with the name `"code=\$(code)_pvec=\$(pvec)_nsample=\$(max_sim)_maxerror=\$(max_error)_workers=\$(worker_count)_decoder=\$(decoder).json"`. The information includes
- `code_name`: The name of the code.
- `pvec`: The error probabilities.
- `nsample`: The maximum number of samples.
- `max_error`: The maximum number of logical errors.
- `nsim`: The actual number of samples for each `p`.
- `error_count`: The logical error count for each `p`.
- `decoder`: The decoder.
- `time_res`: The average decoding time.
- `error_rate`: The logical error rate.

### Inputs
- `code::TensorQEC.QuantumCode`: The quantum code.
- `pvec::AbstractVector`: The error probabilities.
- `max_sim::Int`: The maximum number of simulated samples for each `p`.
- `max_error::Int`: The maximum number of logical errors for each `p`.
- `decoder::TensorQEC.AbstractDecoder`: The decoder.
- `result_dir::String`: The directory to save the result.

### Outputs
- `time_res::Vector{Float64}`: The average time of the decoder.
- `error_rate::Vector{Float64}`: The error rate of the decoder.
- `nsim::Vector{Int}`: The number of simulated samples for each `p`.
- `error_count::Vector{Int}`: The number of logical errors for each `p`.
"""
function run_benchmark(code::TensorQEC.QuantumCode,pvec::AbstractVector,max_sim::Int,max_error::Int,decoder::TensorQEC.AbstractDecoder,result_dir::String;log_file = nothing, filename_prefix = nothing, relative_path = nothing)
    time_res = Float64[]
    error_rate = Float64[]
    nsim_res = Int[]
    error_count_res = Int[]
    mkpath(result_dir)
    workers_list = Distributed.workers()
    if !isempty(workers_list)
        futures = [Distributed.remotecall_eval(Main, w, :(using DecoderBenchmarks)) for w in workers_list]
        foreach(fetch, futures)
    end

    for p in pvec
        time_sum = 0.0
        error_count = 0
        nsim = 0
        n = 0
        if isempty(workers_list)
            res = _benchmark_chunk((code, decoder, p, max_sim, max_error))
            time_sum += res.time_sum
            error_count += res.error_count
            nsim += res.nsim
            n = res.n
        else
            while nsim < max_sim && error_count < max_error
                remaining_sim = max_sim - nsim
                remaining_error = max_error - error_count
                chunk_sim = max(1, cld(remaining_sim, length(workers_list)))
                chunk_err = max(1, cld(remaining_error, length(workers_list)))
                inputs = [(code, decoder, p, chunk_sim, chunk_err) for _ in 1:length(workers_list)]
                results = Distributed.pmap(_benchmark_chunk, inputs)
                for res in results
                    time_sum += res.time_sum
                    error_count += res.error_count
                    nsim += res.nsim
                    n = res.n
                end
            end
        end

        avg_time = nsim == 0 ? 0.0 : time_sum / nsim
        err_rate = nsim == 0 ? 0.0 : error_count / nsim
        push!(time_res, avg_time)
        push!(error_rate, err_rate)
        push!(nsim_res, nsim)
        push!(error_count_res, error_count)
        if !isnothing(log_file)
            file = open(log_file,"a")
            write(file,"n=$(n) p=$(p) max_sim=$(max_sim) max_error=$(max_error) nsim=$(nsim) error_count=$(error_count) decoder=$(decoder) average_time=$(avg_time) error_rate=$(err_rate) run $(now())\n")
            close(file)
        end
    end
    worker_count = isempty(workers_list) ? 1 : length(workers_list)
    data = Dict(
        "code_name" => "$code",
        "pvec" => pvec,
        "nsample" => max_sim,
        "max_error" => max_error,
        "nsim" => nsim_res,
        "error_count" => error_count_res,
        "decoder" => "$decoder",
        "time_res" => time_res,
        "error_rate" => error_rate,
    )
    write(joinpath(result_dir, "code=$(code)_pvec=$(pvec)_nsample=$(max_sim)_maxerror=$(max_error)_workers=$(worker_count)_decoder=$(decoder).json"), JSON.json(data))
    if !isnothing(filename_prefix)
        file = open(filename_prefix,"a")
        write(file, "$(relative_path)/code=$(code)_pvec=$(pvec)_nsample=$(max_sim)_maxerror=$(max_error)_workers=$(worker_count)_decoder=$(decoder).json\n")
        close(file)
    end
    return (;time_res, error_rate, nsim=nsim_res, error_count=error_count_res)
end

function run_benchmark(codevec::AbstractVector,pvec::AbstractVector,max_sim::Int,max_error::Int,decoder::TensorQEC.AbstractDecoder,result_dir::String;log_file = nothing, filename_prefix = nothing, relative_path = nothing)
    for code in codevec
        run_benchmark(code,pvec,max_sim,max_error,decoder,result_dir;log_file=log_file, filename_prefix=filename_prefix, relative_path=relative_path)
    end
    return nothing
end
