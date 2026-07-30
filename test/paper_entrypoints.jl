using Test

@testset "paper command surface" begin
    root = normpath(joinpath(@__DIR__, ".."))
    makefile = read(joinpath(root, "Makefile"), String)
    @test occursin("paper-smoke:", makefile)
    @test occursin("paper-logical-full:", makefile)
    @test occursin("paper-timing-full:", makefile)
    @test isfile(joinpath(root, "paper", "run_logical_error.jl"))
    @test isfile(joinpath(root, "paper", "run_timing.jl"))
end
