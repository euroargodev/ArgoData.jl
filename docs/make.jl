using Documenter, ArgoData, PlutoSliderServer
import Pkg, PyCall, Conda

using Climatology, MITgcm
ENV["DATADEPS_ALWAYS_ACCEPT"]=true
pth=Climatology.MITPROFclim_download()
println(pth)

#python dependencies

if Sys.ARCH!==:aarch64
  method="external"
  if method=="external"
    tmpfile=joinpath(tempdir(),"pythonpath.txt")
    run(pipeline(`which python`,tmpfile)) #external python path
    ENV["PYTHON"]=readline(tmpfile)
  else
    ENV["PYTHON"]=""
  end
  Pkg.build("PyCall")
  ArgoData.conda(:argopy)
  argopy=ArgoData.pyimport(:argopy)
end

#make docs
makedocs(;
    modules=[ArgoData],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
        "Examples" => "examples.md",
        "Reference" => "Functionalities.md",
    ],
    repo="https://github.com/euroargodev/ArgoData.jl/blob/{commit}{path}#L{line}",
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
Sys.ARCH!==:aarch64 ? lst=(lst...,"Argo_argopy.jl") : nothing
for i in lst
    fil_in=joinpath(@__DIR__,"..", "examples",i)
    fil_out=joinpath(@__DIR__,"build", i[1:end-2]*"html")
    PlutoSliderServer.export_notebook(fil_in)
    mv(fil_in[1:end-2]*"html",fil_out)
    cp(fil_in,fil_out[1:end-4]*"jl")
end

#deploy docs
deploydocs(;
    repo="github.com/euroargodev/ArgoData.jl",
)
