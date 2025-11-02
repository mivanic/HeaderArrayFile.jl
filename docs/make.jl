using HeaderArrayFile
using Documenter

DocMeta.setdocmeta!(HeaderArrayFile, :DocTestSetup, :(using HeaderArrayFile); recursive=true)


const _PAGES = [
    "API Reference" => ["index.md"],
]


makedocs(;
    modules=[HeaderArrayFile],
    authors="Maros Ivanic and Mitch Phillipson",
    sitename="HeaderArrayFile.jl",
    format=Documenter.HTML(;
        canonical="https://github.com/mivanic/HeaderArrayFile.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=_PAGES
)

deploydocs(;
    repo = "github.com/mivanic/HeaderArrayFile.jl",
    devbranch = "main",
    branch = "gh-pages",
    push_preview = true
)