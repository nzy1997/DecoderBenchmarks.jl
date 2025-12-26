using DecoderBenchmarks
using TensorQEC
using Gurobi
using DelimitedFiles

d = 10
c = TensorQEC.FileCode(joinpath(@__DIR__,"../data","codes","bbx^-1y_$(d).txt"), "bbx^-1y_$(d)")
row_transformation = TensorQEC.Mod2.(readdlm(joinpath(@__DIR__,"../data","codes","bbx^-1y_$(d)_row_transformation.txt"), Bool))
column_transformation = TensorQEC.Mod2.(readdlm(joinpath(@__DIR__,"../data","codes","bbx^-1y_$(d)_column_transformation.txt"), Bool))

# run_benchmark(c,[0.0001,0.0002,0.0005,0.001,0.002,0.005,0.008,0.01,0.015,0.02], 1000, 1000, TToricDecoder(row_transformation,column_transformation,4,3,d^2), joinpath(@__DIR__,"../data","result","TensorQEC");log_file="log.txt")

run_benchmark_time(c,[0.0001,0.0002,0.0005,0.001,0.002,0.005,0.008,0.01,0.015,0.02], 1000, TToricDecoder(row_transformation,column_transformation,4,3,d^2), joinpath(@__DIR__,"../data","result","TensorQEC"))