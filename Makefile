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

generate-depolarizing-samples:
	$(JL) -e 'using DecoderBenchmarks; generate_depolarizing_samples([9], collect(0.01:0.01:0.1), 1000, "data/depolarizing")'

run-benchmark:
	$(JL) -e 'using DecoderBenchmarks;using TensorQEC; run_benchmark(SurfaceCode(3,3), collect(0.01:0.01:0.1), 1000, BPDecoder(), 1000, "data/result", "data/depolarizing")'

plot:
	$(JL) -e 'using Pkg; Pkg.activate("visualize"); include("visualize/viz.jl"); draw("data/result")'

.PHONY: init generate-depolarizing-samples update run-benchmark make-data-path init-visualize update-visualize plot
