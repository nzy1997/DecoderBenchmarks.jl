using Test
using TOML

@testset "paper command surface" begin
    root = normpath(joinpath(@__DIR__, ".."))
    makefile = read(joinpath(root, "Makefile"), String)
    readme = read(joinpath(root, "README.md"), String)
    project = TOML.parsefile(joinpath(root, "Project.toml"))
    @test occursin("paper-smoke:", makefile)
    @test occursin("paper/run_logical_error.jl smoke", makefile)
    @test occursin("paper/run_timing.jl smoke", makefile)
    @test occursin("paper-bposd-test:", makefile)
    @test occursin("paper-bposd-smoke:", makefile)
    @test occursin("paper/python/run_bposd.py --mode smoke", makefile)
    @test occursin("make paper-python-init", readme)
    @test occursin("make paper-bposd-test", readme)
    @test occursin("Julia 1.11 or later", readme)
    @test project["compat"]["julia"] == "1.11"
    @test occursin("paper-logical-full:", makefile)
    @test occursin("paper-timing-full:", makefile)
    @test isfile(joinpath(root, "paper", "run_logical_error.jl"))
    @test isfile(joinpath(root, "paper", "run_timing.jl"))
end
