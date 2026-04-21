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
        "Home"                    => "index.md",
        "Introduction"            => "introduction.md",
        "Set Operations"          => "set_operations.md",
        "Morphological Operations" => "morphology.md",
        "Blob Analysis"           => "blob_analysis.md",
        "Reference"               => "reference.md",
    ],
)

deploydocs(;
    repo="github.com/schrpe/Regions.jl",
)
