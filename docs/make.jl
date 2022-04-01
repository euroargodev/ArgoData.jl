using Documenter, ArgoData

makedocs(;
    modules=[ArgoData],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/JuliaOcean/ArgoData.jl/blob/{commit}{path}#L{line}",
    sitename="ArgoData.jl",
    authors="gaelforget <gforget@mit.edu>",
    assets=String[],
)

list_files=GDAC.Argo_files_list()
GDAC.CSV.write("Argo_float_files.csv",list_files)
mv("Argo_float_files.csv",joinpath(@__DIR__,"build", "Argo_float_files.csv"))

deploydocs(;
    repo="github.com/JuliaOcean/ArgoData.jl",
)
