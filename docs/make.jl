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

files_list=GDAC.files_list()
GDAC.CSV.write("Argo_float_files.csv",files_list)
mv("Argo_float_files.csv",joinpath(@__DIR__,"build", "Argo_float_files.csv"))

deploydocs(;
    repo="github.com/JuliaOcean/ArgoData.jl",
)
