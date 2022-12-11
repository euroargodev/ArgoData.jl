
## Workflows

### Direct Download

Downloading and accessing an Argo file (`wmo=13857` from `folder="aoml"`) is done like this.

```
using ArgoData
input_file=GDAC.download_file("aoml",13857)

using NCDatasets
Dataset(input_file)
```

A list of all `folder,wmo` pairs can be obtained using `files_list=GDAC.files_list()`. And a method to download files in bulk & parallel is presented in [examples/Argo\_distributed\_download.jl](https://github.com/euroargodev/ArgoData.jl/blob/master/examples/Argo_distributed_download.jl).

### `MITprof` Format

👉 [Notebook 1](https://juliaocean.github.io/OceanRobots.jl/dev/Float_Argo.html) 👈 [(code)](https://raw.githubusercontent.com/juliaocean/OceanRobots.jl/master/examples/Float_Argo.jl)

👉 [Notebook 2](ArgoToMITprof.html) 👈 [(code)](https://raw.githubusercontent.com/euroargodev/ArgoData.jl/master/examples/ArgoToMITprof.jl)

The MITprof format is a simple to use version of Argo where profiles have been converted to potential temperature and interpolated to [standard depth levels](https://juliaocean.github.io/OceanRobots.jl/dev/Float_Argo.html).

Formatting an Argo file (`input_file`) into an MITprof file (`output_file`) proceeds as follows.

```
gridded_fields=GriddedFields.load()
output_file=MITprof.format(gridded_fields,input_file)
```

**`MITprofStandard` Data Structure**

The generated file can be accessed normally as a NetCDF file (e.g., `Dataset(output_file)`) or using the convenient `MITprofStandard` data structure.

```
mp=MITprofStandard(output_file)
```

### `MITprof` Sample Files

The original collection of MITprof files from [Forget, et al 2015](http://dx.doi.org/10.5194/gmd-8-3071-2015) is archived [here](https://doi.org/10.7910/DVN/EE3C40). These files can be retrieved as follows.

```
using CSV, DataFrames
tmp = CSV.File("examples/dataverse_files.csv") |> DataFrame
url0="https://dataverse.harvard.edu/api/access/datafile/"
run(`wget --content-disposition $(url0)$(tmp[1,:ID])`)
```

### `argopy` Python API

👉 [Notebook](http://gaelforget.net/notebooks/Argo_argopy.html) 👈 [(code)](https://raw.githubusercontent.com/euroargodev/ArgoData.jl/master/examples/Argo_argopy.jl)

[argopy](https://img.shields.io/readthedocs/argopy?logo=readthedocs) is a python library to access, manipulate, and visualize [Argo data](https://argopy.readthedocs.io/en/latest/what_is_argo.html#what-is-argo). 

The notebook demonstrate how to (1) install `argopy` into `Julia` via [Conda.jl](https://github.com/JuliaPy/Conda.jl) and (2) use `argopy` via [PyCall.jl](https://github.com/JuliaPy/PyCall.jl).
