using DecoderBenchmarks
using TensorQEC
using Gurobi
using DelimitedFiles

# generate_depolarizing_samples([144], 0.001:0.001:0.01, 100, joinpath(@__DIR__,"../data","depolarizing"))
# c = BivariateBicycleCode(6,12, ((3,0),(0,1),(0,2)), ((0,3),(1,0),(2,0)))
# generate_code_data([c],joinpath(@__DIR__,"../data","codes"))


# run_benchmark(c, 0.001:0.001:0.01, 100, 100, BPDecoder(), joinpath(@__DIR__,"../data","result","TensorQEC");log_file="log.txt", filename_prefix=joinpath(@__DIR__,"../data","result","files.txt"), relative_path="data/result/TensorQEC")

# run_benchmark(c, 0.001:0.001:0.01, 100, 100, IPDecoder(Gurobi.Optimizer, false), joinpath(@__DIR__,"../data","result","TensorQEC");log_file="log.txt", filename_prefix=joinpath(@__DIR__,"../data","result","files.txt"), relative_path="data/result/TensorQEC")

# for d in [2,3,4,5]
#     c = DecoderBenchmarks.FileCode(joinpath(@__DIR__,"../data","codes","color_code_$(d).txt"), "color_code_$(d)")

#     run_benchmark(c, [0.001,0.002,0.005,0.008,0.01], 1000000, 1000000, IPDecoder(Gurobi.Optimizer, false), joinpath(@__DIR__,"../data","result","TensorQEC");log_file="log.txt", filename_prefix=joinpath(@__DIR__,"../data","result","files.txt"), relative_path="data/result/TensorQEC")
# end


# for d in [10]
#     @show d
#     c = TensorQEC.FileCode(joinpath(@__DIR__,"../data","codes","color_code_$(d).txt"), "color_code_$(d)")
#     row_transformation = TensorQEC.Mod2.(readdlm(joinpath(@__DIR__,"../data","codes","color_code_$(d)_row_transformation.txt"), Bool))
#     column_transformation = TensorQEC.Mod2.(readdlm(joinpath(@__DIR__,"../data","codes","color_code_$(d)_column_transformation.txt"), Bool))

#     run_benchmark(c,[0.001,0.002,0.005], 1000000, 1000000, TToricDecoder(row_transformation,column_transformation,1,2,d^2), joinpath(@__DIR__,"../data","result","TensorQEC");log_file="log.txt", filename_prefix=joinpath(@__DIR__,"../data","result","files.txt"), relative_path="data/result/TensorQEC")
# end

# for d in [10]
#     @show d
#     c = TensorQEC.FileCode(joinpath(@__DIR__,"../data","codes","color_code_$(d).txt"), "color_code_$(d)")
#     row_transformation = TensorQEC.Mod2.(readdlm(joinpath(@__DIR__,"../data","codes","color_code_$(d)_row_transformation.txt"), Bool))
#     column_transformation = TensorQEC.Mod2.(readdlm(joinpath(@__DIR__,"../data","codes","color_code_$(d)_column_transformation.txt"), Bool))

#     run_benchmark(c,[0.001,0.002,0.005,0.008,0.01,0.015,0.02], 100000, 100000, TToricDecoder(row_transformation,column_transformation,1,2,d^2), joinpath(@__DIR__,"../data","result","TensorQEC");log_file="log.txt", filename_prefix=joinpath(@__DIR__,"../data","result","files.txt"), relative_path="data/result/TensorQEC")
# end

# for d in [10]
#     @show d
#     c = TensorQEC.FileCode(joinpath(@__DIR__,"../data","codes","bbx^-1y_$(d).txt"), "bbx^-1y_$(d)")
#     row_transformation = TensorQEC.Mod2.(readdlm(joinpath(@__DIR__,"../data","codes","bbx^-1y_$(d)_row_transformation.txt"), Bool))
#     column_transformation = TensorQEC.Mod2.(readdlm(joinpath(@__DIR__,"../data","codes","bbx^-1y_$(d)_column_transformation.txt"), Bool))

#     run_benchmark(c,[0.001,0.002,0.005,0.008,0.01,0.015,0.02], 100000, 100000, TToricDecoder(row_transformation,column_transformation,4,3,d^2), joinpath(@__DIR__,"../data","result","TensorQEC");log_file="log.txt", filename_prefix=joinpath(@__DIR__,"../data","result","files.txt"), relative_path="data/result/TensorQEC")
# end

for d in [10]
    @show d
    c = TensorQEC.FileCode(joinpath(@__DIR__,"../data","codes","bbx^-1y_$(d).txt"), "bbx^-1y_$(d)")
    row_transformation = TensorQEC.Mod2.(readdlm(joinpath(@__DIR__,"../data","codes","bbx^-1y_$(d)_row_transformation.txt"), Bool))
    column_transformation = TensorQEC.Mod2.(readdlm(joinpath(@__DIR__,"../data","codes","bbx^-1y_$(d)_column_transformation.txt"), Bool))

    run_benchmark(c,[0.005,0.008,0.01,0.015,0.02], 100000, 500, TToricDecoder(row_transformation,column_transformation,4,3,d^2), joinpath(@__DIR__,"../data","result","TensorQEC");log_file="log.txt", filename_prefix=joinpath(@__DIR__,"../data","result","files.txt"), relative_path="data/result/TensorQEC")
end
