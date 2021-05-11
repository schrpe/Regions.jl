using Regions
using Documenter

DocMeta.setdocmeta!(Regions, :DocTestSetup, :(using Regions); recursive=true)

makedocs(;
    modules=[Regions],
    authors="schrpe",
    repo="https://github.com/schrpe/Regions.jl/blob/{commit}{path}#{line}",
    sitename="Regions.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://schrpe.github.io/Regions.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/schrpe/Regions.jl",
)
