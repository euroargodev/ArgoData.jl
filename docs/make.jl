using Documenter, ArgoData, PlutoSliderServer

using Climatology, MITgcm
ENV["DATADEPS_ALWAYS_ACCEPT"]=true
pth=Climatology.MITPROFclim_download()
println(pth)

#python dependencies

run_argopy=true
#Sys.ARCH==:aarch64 ? run_argopy=false : nothing

if run_argopy
  using PythonCall, CondaPkg
  argopy=try
    ArgoData.pyimport(:argopy)
  catch
    ArgoData.conda(:argopy)
    ArgoData.pyimport(:argopy)
  end
end

#make docs
makedocs(;
    modules=[ArgoData],
    format=Documenter.HTML(),
#   format=Documenter.HTML(repolink = "github.com/euroargodev/ArgoData.jl.git"),
    pages=[
        "Home" => "index.md",
        "Examples" => "examples.md",
        "Reference" => "Functionalities.md",
    ],
    repo="https://github.com/euroargodev/ArgoData.jl/blob/{commit}{path}#L{line}",
#   repo = "github.com/euroargodev/ArgoData.jl.git",
#    repo=Remotes.GitHub("euroargodev", "ArgoData.jl"),
    sitename="ArgoData.jl",
    authors="gaelforget <gforget@mit.edu>",
    warnonly = [:cross_references,:missing_docs],
)

#create csv list of floats
files_list=GDAC.files_list()
GDAC.CSV.write("Argo_float_files.csv",files_list)
mv("Argo_float_files.csv",joinpath(@__DIR__,"build", "Argo_float_files.csv"))

#run notebooks
lst=("ArgoToMITprof.jl",)
run_argopy ? lst=(lst...,"Argo_argopy.jl") : nothing
for i in lst
    fil_in=joinpath(@__DIR__,"..", "examples",i)
    fil_out=joinpath(@__DIR__,"build", i[1:end-2]*"html")
    PlutoSliderServer.export_notebook(fil_in)
    mv(fil_in[1:end-2]*"html",fil_out)
    cp(fil_in,fil_out[1:end-4]*"jl")
end

for fil in ["argo_synthetic-profile_index.txt", "ar_index_global_prof.txt"]
    ArgoFiles.scan_txt(fil,do_write=true)
    fil_in=joinpath(tempdir(),fil[1:end-4]*".csv")
    fil_out=joinpath(@__DIR__,"build", fil[1:end-4]*".csv")
    mv(fil_in,fil_out)
end

#deploy docs
deploydocs(;
    repo="github.com/euroargodev/ArgoData.jl",
)
