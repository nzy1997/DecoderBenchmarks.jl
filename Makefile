JL = julia --project

init:
	$(JL) -e 'using Pkg; Pkg.instantiate()'

update:
	$(JL) -e 'using Pkg; Pkg.update(); Pkg.precompile()'

init-conda:
	./bin/install_conda

init-ldpc:
	./ldpc/setup

generate-surface-samples:
	$(JL) -e 'using DecoderBenchmarks;using TensorQEC; mkpath(joinpath("data","depolarizing")); mkpath(joinpath("data","surface_code")); generate_depolarizing_samples(collect(3:2:21).^2, collect(0.01:0.01:0.2), 10000, joinpath("data","depolarizing")); for d in 3:2:21  generate_code_data(SurfaceCode(d,d),joinpath("data","surface_code"),"surface_code_$$d") end'

run-benchmark-surface-BP:
	$(JL) -e 'using DecoderBenchmarks;using TensorQEC; for d in 3:2:11 run_benchmark(SurfaceCode(d,d), collect(0.01:0.01:0.2), 10000, BPDecoder(), joinpath("data","surface_code","result","TensorQEC_BP"), joinpath("data","depolarizing");log_file="log.txt") end'

run-benchmark-ldpc-surface-BP:
	./ldpc/run

.PHONY: init generate-depolarizing-samples update make-data-path generate-surface-samples run-benchmark-surface-BP