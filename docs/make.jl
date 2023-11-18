using Documenter, ArgoData, PlutoSliderServer

#python dependencies
if false
import Pkg, PyCall, Conda

tmpfile=joinpath(tempdir(),"pythonpath.txt")
run(pipeline(`which python`,tmpfile)) #external python path
ENV["PYTHON"]=readline(tmpfile)
#ENV["PYTHON"]=""
Pkg.build("PyCall")
Conda.add("argopy")

argopy=PyCall.pyimport("argopy")
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
)

#create csv list of floats
files_list=GDAC.files_list()
GDAC.CSV.write("Argo_float_files.csv",files_list)
mv("Argo_float_files.csv",joinpath(@__DIR__,"build", "Argo_float_files.csv"))

#run notebooks
lst=("ArgoToMITprof.jl",)
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
