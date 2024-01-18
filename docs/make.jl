using MTH229Lite
using Documenter
using PlotlyDocumenter

DocMeta.setdocmeta!(MTH229Lite, :DocTestSetup, :(using MTH229Lite); recursive=true)

makedocs(;
    modules=[MTH229Lite],
    authors="jverzani <jverzani@gmail.com> and contributors",
    repo="https://github.com/jverzani/MTH229Lite.jl/blob/{commit}{path}#{line}",
    sitename="MTH229Lite.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jverzani.github.io/MTH229Lite.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Reference/API" => "reference.md",
    ],
)

deploydocs(;
    repo="github.com/jverzani/MTH229Lite.jl",
    devbranch="main",
)
