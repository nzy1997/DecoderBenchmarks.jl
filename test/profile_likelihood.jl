using Test

@testset "profile likelihood interval" begin
    zero = profile_likelihood_interval(10_000_000, 0; h=1000.0)
    @test zero.estimate == 0.0
    @test zero.low == 0.0
    @test zero.high ≈ log(1000.0) / 10_000_000 rtol=1e-5

    point = profile_likelihood_interval(1_088_545, 2_040; h=1000.0)
    @test point.estimate == 2_040 / 1_088_545
    @test 0.0 < point.low < point.estimate < point.high < 1.0
    @test point.low ≈ 0.0017241678059600049 rtol=1e-12
    @test point.high ≈ 0.0020323834596710486 rtol=1e-12

    historical = profile_likelihood_interval(10, 5; h=9.0)
    @test historical.low ≈ 0.20183646055279336 rtol=1e-12
    @test historical.high ≈ 0.7981635394472066 rtol=1e-12

    certain = profile_likelihood_interval(10, 10; h=1000.0)
    @test certain.estimate == certain.high == 1.0
    @test 0.0 < certain.low < 1.0

    @test_throws ArgumentError profile_likelihood_interval(0, 0)
    @test_throws ArgumentError profile_likelihood_interval(10, -1)
    @test_throws ArgumentError profile_likelihood_interval(10, 11)
    @test_throws ArgumentError profile_likelihood_interval(10, 1; h=0.5)
end
