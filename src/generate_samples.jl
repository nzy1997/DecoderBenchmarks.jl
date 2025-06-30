"""
    generate_sample(em::IndependentDepolarizingError, num_samples::Int,filename::String,seed::Int)

Generate `num_samples` samples of the error model `em` and save them to `filename`.

### Inputs
- `em::IndependentDepolarizingError`: The error model to generate samples from.
- `num_samples::Int`: The number of samples to generate.
- `filename::String`: The file to save the samples to.
- `seed::Int`: The seed for the random number generator.
"""
function generate_sample(em::IndependentDepolarizingError, num_samples::Int, filename::String, seed::Int)
    data = zeros(Bool, num_samples, 2 * length(em.px))
    Random.seed!(seed)
    for i in 1:num_samples
        error_qubits = random_error_qubits(em)
        data[i, :] .= (getfield.(error_qubits.xerror, :x)..., getfield.(error_qubits.zerror, :x)...)
    end
    writedlm(filename, Int.(data))
    return nothing
end

function generate_sample(em::IndependentFlipError, num_samples::Int, filename::String, seed::Int)
    data = zeros(Bool,num_samples,length(em.p))
    Random.seed!(seed)
    for i in 1:num_samples
        error_qubits = random_error_qubits(em)
        data[i,:] .= getfield.(error_qubits,:x)
    end
    writedlm(filename, Int.(data))
    return nothing
end

"""
    generate_depolarizing_samples(nvec::Vector{Int}, pvec::Vector{Float64}, nsample::Int, dirname::String; seed=110)

Generate `nsample` samples of the depolarizing error model for each `n` in `nvec` and `p` in `pvec` and save them to `joinpath(dirname, "n=\$(n)_p=\$(p)_nsample=\$(nsample).txt")`.

### Inputs
- `nvec::Vector{Int}`: The vector of qubit numbers to generate samples for.
- `pvec::Vector{Float64}`: The vector of error probabilities to generate samples for.
- `nsample::Int`: The number of samples to generate for each `n` and `p`.
- `dirname::String`: The directory to save the samples to.
- `seed::Int`: The seed for the random number generator.
"""
function generate_depolarizing_samples(nvec::Vector{Int}, pvec::Vector{Float64}, nsample::Int, dirname::String; seed=110)
    for n in nvec
        for p in pvec
            filename = joinpath(dirname, "n=$(n)_p=$(p)_nsample=$(nsample).txt")
            generate_sample(iid_error(p / 3, p / 3, p / 3, n), nsample, filename, seed)
        end
    end
    return nothing
end

"""
    get_depolarizing_data(n::Int, p::Float64, nsample::Int, dirname::String;ns = nothing)
    get_depolarizing_data(ns::Int,filename::String)

Get the data for the depolarizing error model for `n` qubits and `p` error probability and `ns` samples from `filename`.

### Inputs
- `n::Int`: The number of qubits to generate samples for.
- `p::Float64`: The error probability.
- `nsample::Int`: The number of samples to generate.
- `ns::Int`: The number of samples to return. If `ns` is not provided, all samples are returned.
- `filename::String`: The file contains the samples.
- `dirname::String`: The directory contains the samples.

### Outputs
- `eqs::Vector{CSSErrorPattern{Vector{Mod2}}}`: The error patterns.
"""
function get_depolarizing_data(n::Int, p::Float64, nsample::Int, dirname::String;ns = nothing)
    filename = joinpath(dirname, "n=$(n)_p=$(p)_nsample=$(nsample).txt")
    if isnothing(ns)
        ns = nsample
    end
    return get_depolarizing_data(ns, filename)
end

function get_depolarizing_data(ns::Int, filename::String)
    @assert isfile(filename) "Data file not found: $filename, please generate one with: `generate_depolarizing_samples`"
    data = readdlm(filename, Bool)
    data = Mod2.(data)
    n = size(data, 2) ÷ 2
    eqs = [TensorQEC.CSSErrorPattern(data[i, 1:n], data[i, n+1:2n]) for i in 1:ns]
    return eqs
end


function get_flip_data(ns::Int, filename::String)
    @assert isfile(filename) "Data file not found: $filename, please generate one with: `generate_sample`"
    data = readdlm(filename, Bool)
    data = Mod2.(data)
    eqs = [data[i,:] for i in 1:ns]
    return eqs
end
