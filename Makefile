JL = julia --project

init:
	$(JL) -e 'using Pkg; Pkg.instantiate()'

update:
	$(JL) -e 'using Pkg; Pkg.update(); Pkg.precompile()'

generate-depolarizing-samples:
	$(JL) -e 'using DecoderBenchmarks; generate_depolarizing_samples($(n_samples), $(n_qubits), $(p))'

.PHONY: init generate-depolarizing-samples
