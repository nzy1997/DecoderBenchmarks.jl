using DecoderBenchmarks
using Documenter

DocMeta.setdocmeta!(DecoderBenchmarks, :DocTestSetup, :(using DecoderBenchmarks); recursive=true)

makedocs(;
    modules=[DecoderBenchmarks],
    authors="nzy1997",
    sitename="DecoderBenchmarks.jl",
    format=Documenter.HTML(;
        canonical="https://nzy1997.github.io/DecoderBenchmarks.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/nzy1997/DecoderBenchmarks.jl",
    devbranch="main",
)
