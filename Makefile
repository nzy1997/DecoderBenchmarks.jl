JL = julia --project

init:
	$(JL) -e 'using Pkg; Pkg.instantiate()'

update:
	$(JL) -e 'using Pkg; Pkg.update(); Pkg.precompile()'

init-conda:
	./bin/install_conda

init-ldpc:
	./ldpc/setup

generate-error-samples:
	$(JL) -e 'using DecoderBenchmarks;using TensorQEC; mkpath(joinpath(@__DIR__,"data","depolarizing")); generate_depolarizing_samples($(nvec), $(pvec), $(nsample), joinpath(@__DIR__,"data","depolarizing"))'

generate-code-data:
	$(JL) -e 'using DecoderBenchmarks;using TensorQEC; generate_code_data($(codevec),joinpath(@__DIR__,"data","codes"))'

benchmark-TensorQEC:
	$(JL) -e 'using DecoderBenchmarks;using TensorQEC; run_benchmark($(codevec), $(pvec), $(nsample), $(decoder), joinpath(@__DIR__,"data","result","TensorQEC"), joinpath(@__DIR__,"data","depolarizing");log_file="log.txt", filename_prefix=joinpath(@__DIR__,"data","result","files.txt"), relative_path="data/result/TensorQEC")'

benchmark-ldpc:
	mkdir -p ldpc/data
	$(JL) -e 'using DecoderBenchmarks;using TensorQEC; generate_code_data($(codevec),joinpath(@__DIR__,"ldpc","data"))'
	./ldpc/run
	rm -rf ldpc/data

generate-plotting-data:
	$(JL) -e 'include(joinpath(@__DIR__,"visualize","generate_plotting_data.jl"));select_files_with_pattern($(patterns))'

benchmark-TensorQEC-Gurobi:
	$(JL) -e 'using DecoderBenchmarks,Gurobi;using TensorQEC; run_benchmark($(codevec), $(pvec), $(nsample), IPDecoder(Gurobi.Optimizer,false), joinpath(@__DIR__,"data","result","TensorQEC"), joinpath(@__DIR__,"data","depolarizing");log_file="log.txt", filename_prefix=joinpath(@__DIR__,"data","result","files.txt"), relative_path="data/result/TensorQEC")'

benchmark-ldpc-benchcode:
	./ldpc/run

.PHONY: init generate-error-samples update make-data-path benchmark-TensorQEC benchmark-ldpc generate-plotting-data