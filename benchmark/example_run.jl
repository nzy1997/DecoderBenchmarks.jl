using DecoderBenchmarks
using TensorQEC
using DelimitedFiles

for d in [3,5,7]
    c = SurfaceCode(d,d)
    run_benchmark(c,0.01:0.01:0.2, 100, 100, IPDecoder(), joinpath(@__DIR__,"../data","result","TensorQEC");log_file="log.txt")
end
