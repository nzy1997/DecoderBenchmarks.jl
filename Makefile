JL = julia --project

init:
	$(JL) -e 'using Pkg; Pkg.instantiate()'

update:
	$(JL) -e 'using Pkg; Pkg.update(); Pkg.precompile()'

init-visualize:
	$(JL) -e 'using Pkg; Pkg.activate("visualize"); Pkg.develop(path="."); Pkg.instantiate(); Pkg.precompile()'

update-visualize:
	$(JL) -e 'using Pkg; Pkg.activate("visualize"); Pkg.update(); Pkg.precompile()'

make-data-path:
	$(JL) -e 'using DecoderBenchmarks; mkpath("data/depolarizing"); mkpath("data/result")'

generate-surface-samples:
	$(JL) -e 'using DecoderBenchmarks; generate_depolarizing_samples(collect(3:2:21).^2, collect(0.01:0.01:0.2), 10000, "data/depolarizing")'

run-benchmark-surface-BP:
	$(JL) -e 'using DecoderBenchmarks;using TensorQEC; for d in $(dmax) run_benchmark(SurfaceCode(d,d), collect(0.01:0.01:0.2), 10000, BPDecoder(), 10000, "data/result/surface_BP", "data/depolarizing";log_file="log.txt") end'

plot:
	$(JL) -e 'using Pkg; Pkg.activate("visualize"); include("visualize/viz.jl"); draw("data/result")'

generate-BBcode-samples:
	$(JL) -e 'using DecoderBenchmarks; generate_depolarizing_samples([144], [0.001], 10000, "data/depolarizing")'

run-benchmark-BBcode-BP:
	$(JL) -e 'using DecoderBenchmarks;using TensorQEC;run_benchmark(BivariateBicycleCode(6,12, ((3,0),(0,1),(0,2)), ((0,3),(1,0),(2,0))), [0.001], 10000, BPDecoder(), 10000, "data/result/BBcode", "data/depolarizing";log_file="log.txt")'


.PHONY: init generate-depolarizing-samples update make-data-path init-visualize update-visualize plot generate-surface-samples run-benchmark-surface-BP generate-BBcode-samples run-benchmark-BBcode-BP
