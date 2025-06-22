"""
    generate_sample(em::IndependentDepolarizingError, num_samples::Int,filename::String,seed::Int)

Generate `num_samples` samples of the error model `em` and save them to `filename`.

### Inputs
- `em::IndependentDepolarizingError`: The error model to generate samples from.
- `num_samples::Int`: The number of samples to generate.
- `filename::String`: The file to save the samples to.
- `seed::Int`: The seed for the random number generator.
"""
function generate_sample(em::IndependentDepolarizingError, num_samples::Int,filename::String,seed::Int)
    data = zeros(Bool,num_samples,2*length(em.px))
    Random.seed!(seed)
    for i in 1:num_samples
        error_qubits = random_error_qubits(em)
        data[i,:] .= (getfield.(error_qubits.xerror,:x)...,getfield.(error_qubits.zerror,:x)...)
    end
    writedlm(filename, data)
    return nothing
end

"""
    generate_depolarizing_samples(nvec,pvec, nsample;dirname = nothing,seed = 110)

Generate `nsample` samples of the depolarizing error model for each `n` in `nvec` and `p` in `pvec` and save them to `joinpath(dirname, "n=\$(n)_p=\$(p)_nsample=\$(nsample).txt")`. If `dirname` is not provided, the samples are saved to `joinpath(@__DIR__, "data", "depolarizing")`.

### Inputs
- `nvec::Vector{Int}`: The vector of qubit numbers to generate samples for.
- `pvec::Vector{Float64}`: The vector of error probabilities to generate samples for.
- `nsample::Int`: The number of samples to generate for each `n` and `p`.
- `dirname::String`: The directory to save the samples to. If `dirname` is not provided, the samples are saved to `joinpath(@__DIR__, "data", "depolarizing")`.
- `seed::Int`: The seed for the random number generator.
"""
function generate_depolarizing_samples(nvec::Vector{Int},pvec::Vector{Float64}, nsample::Int;dirname = nothing,seed = 110)
    for n in nvec
        for p in pvec
            if isnothing(dirname)
                dirname = joinpath(@__DIR__, "data", "depolarizing")
            end
            filename = joinpath(dirname, "n=$(n)_p=$(p)_nsample=$(nsample).txt")
            generate_sample(iid_error(p/3,p/3,p/3,n), nsample, filename,seed)
        end
    end
    return nothing
end

"""
    get_depolarizing_data(n::Int, p::Float64, nsample::Int;ns = nothing,filename = nothing)

Get the data for the depolarizing error model for `n` qubits and `p` error probability and `ns` samples from `filename`.

### Inputs
- `n::Int`: The number of qubits to generate samples for.
- `p::Float64`: The error probability.
- `nsample::Int`: The number of samples to generate.
- `ns::Int`: The number of samples to return. If `ns` is not provided, all samples are returned.
- `filename::String`: The file to save the samples to. The default is `joinpath(@__DIR__, "data", "depolarizing", "n=\$(n)_p=\$(p)_nsample=\$(nsample).txt")`.
"""
function get_depolarizing_data(n::Int, p::Float64, nsample::Int;ns = nothing,filename = nothing)
    if isnothing(filename)
        filename = joinpath(@__DIR__, "data", "depolarizing", "n=$(n)_p=$(p)_nsample=$(nsample).txt")
    end
    @assert isfile(filename) "Data file not found: $filename, please generate one with: `generate_depolarizing_samples($n, $p, $nsample)`"
	data = readdlm(filename, Bool)
	if isnothing(ns)
		ns = nsample
	end
	data = Mod2.(data)
	eqs = [TensorQEC.CSSErrorPattern(data[i, 1:n], data[i, n+1:2n]) for i in 1:ns]
	return eqs
end