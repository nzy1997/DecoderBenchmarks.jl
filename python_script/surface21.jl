using Test
using TensorQEC
using DecoderBenchmarks

@testset "osd" begin
    d = 21
    generate_code_data(SurfaceCode(d,d),"./data/codes/surface21")
    tanner = CSSTannerGraph(SurfaceCode(d,d)).stgz
    Random.seed!(123)
    em = iid_error(0.03,tanner.nq)
    generate_sample(em, 1, "./data/depolarizing/surface21/error.txt", 123)
    # syn = syndrome_extraction(ep, tanner)
    # order = collect(1:tanner.nq)

    # @time osd_error = osd(tanner, order,syn.s)
    # @test syn == syndrome_extraction(osd_error, tanner)
end