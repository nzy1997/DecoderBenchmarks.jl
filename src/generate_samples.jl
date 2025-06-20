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

function generate_depolarizing_samples(nvec,pvec, nsample)
    for n in nvec
        for p in pvec
            generate_sample(iid_error(p/3,p/3,p/3,n), nsample, "data/depolarizing/data/n=$(n)_p=$(p)_nsample=$(nsample).txt",110)
        end
    end
end

function get_depolarizing_data(n, p, nsample;ns = nothing)
    filename = "data/depolarizing/data/n=$(n)_p=$(p)_nsample=$(nsample).txt"
    if !isfile(filename)
        generate_depolarizing_samples([n],[p], nsample)
    end
	data = readdlm(filename, Bool)
	if isnothing(ns)
		ns = nsample
	end
	data = Mod2.(data)
	eqs = [TensorQEC.CSSErrorPattern(data[i, 1:n], data[i, n+1:2n]) for i in 1:ns]
	return eqs
end