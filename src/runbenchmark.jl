"""
    run_benchmark(code::TensorQEC.QuantumCode,pvec::Vector{Float64},nsample::Int,decoder::TensorQEC.AbstractDecoder,result_dir::String,data_dir::String)
    
Run the benchmark for the decoder `decoder` on the code `code` with the error probability `pvec` and save the result to `result_dir`. `data_dir` contains the data for the depolarizing error model.

### Inputs
- `code::TensorQEC.QuantumCode`: The quantum code.
- `pvec::Vector{Float64}`: The error probabilities.
- `nsample::Int`: The number of samples that each error pattern file contains.
- `decoder::TensorQEC.AbstractDecoder`: The decoder.
- `result_dir::String`: The directory to save the result.
- `data_dir::String`: The directory contains the error pattern files.

### Outputs
- `time_res::Vector{Float64}`: The average time of the decoder.
- `error_rate::Vector{Float64}`: The error rate of the decoder.
"""
function run_benchmark(code::TensorQEC.QuantumCode,pvec::Vector{Float64},nsample::Int,decoder::TensorQEC.AbstractDecoder,result_dir::String,data_dir::String;log_file = nothing)
    time_res = Float64[]
    error_rate = Float64[]
    tanner = CSSTannerGraph(code)
    n = tanner.stgz.nq
    ct = compile(decoder, tanner)
    lx,lz = logical_operator(tanner)
    mkpath(result_dir)
    for p in pvec
        eqs = get_depolarizing_data(n, p, nsample, data_dir)
        time_sum = 0.0
        error_count = 0
        for eq in eqs
            syn = syndrome_extraction(eq,tanner)
            time_start = time()
            deres = decode(ct, syn)
            time_end = time()
            time_sum += time_end - time_start
            check_logical_error(deres.error_qubits,eq,lx,lz) && (error_count += 1)
        end
        push!(time_res,time_sum/nsample)
        push!(error_rate,error_count/nsample)
        if !isnothing(log_file)
            file = open(log_file,"a")
            write(file,"n=$(n) p=$(p) nsample=$(nsample) decoder=$(decoder) average_time=$(time_sum/nsample) error_rate=$(error_count/nsample) run $(now())\n")
            close(file)
        end
    end
    data = Dict("code_name" => "$code", "pvec" => pvec, "nsample" => nsample, "decoder" => "$decoder", "time_res" => time_res, "error_rate" => error_rate)
    write(joinpath(result_dir, "code=$(code)_pvec=$(pvec)_nsample=$(nsample)_decoder=$(decoder).json"), JSON.json(data))
    # writedlm(joinpath(result_dir, "Time_$(code)_pvec=$(pvec)_nsample=$(nsample)_decoder=$(decoder)_ns=$(ns).txt"),[pvec, time_res])
    # writedlm(joinpath(result_dir, "Error_rate_$(code)_pvec=$(pvec)_nsample=$(nsample)_decoder=$(decoder)_ns=$(ns).txt"),[pvec, error_rate])
    return (;time_res, error_rate)
end