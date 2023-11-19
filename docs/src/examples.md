
The `One Argo Float` notebook demonstrates various functionalities of the `ArgoData.jl` package, which are further documented below.

👉 [One Argo Float](https://juliaocean.github.io/OceanRobots.jl/dev/examples/Float_Argo.html) 👈 [(code)](https://raw.githubusercontent.com/juliaocean/OceanRobots.jl/master/examples/Float_Argo.jl)

## Download From Argo Data Center

Downloading and accessing an Argo file (`wmo=13857` from `folder="aoml"`) is done like this.

```@example main
using ArgoData
input_file=GDAC.download_file("aoml",13857)
```

You can then simply access the file content using [NCDatasets.jl](https://github.com/Alexander-Barth/NCDatasets.jl#readme).

```@example main
using NCDatasets
ds=Dataset(input_file)
keys(ds)
```

A list of all `folder,wmo` pairs can be obtained using `files_list=GDAC.files_list()`. And a method to download files in bulk & parallel is presented in [examples/Argo\_distributed\_download.jl](https://github.com/euroargodev/ArgoData.jl/blob/master/examples/Argo_distributed_download.jl).

## Argo on Standard Depth Levels

A more complete version of the workflow presented below is in this notebook:

👉 [from Argo to MITprof](../ArgoToMITprof.html) 👈 [(code)](https://raw.githubusercontent.com/euroargodev/ArgoData.jl/master/examples/ArgoToMITprof.jl)

### The `MITprof` Format

The MITprof format is a simple to use version of Argo where profiles have been converted to potential temperature and interpolated to [standard depth levels](https://juliaocean.github.io/OceanRobots.jl/dev/examples/Float_Argo.html).

Turning an Argo file (`input_file`) into an MITprof file (`output_file`) proceeds as follows. 

1. gridded fields are retrieved. These climatologies enable quality control of the data and scientific applications in step 2.
2. read the Argo file and process it. The observed profiles are interpolated to standard depth levels, converted to potential temperature, quality controled, and appended climatological profiles. 

!!! note
    For more detail on the use of climatologies, representation error estimation, and model-data `cost functions`, see Forget et al 2015, Forget 2011, Forget and Wunsch 2007.

```@example main
output_file=input_file[1:end-7]*"MITprof.nc" # hide
isfile(output_file) ? mv(output_file,tempname()) : nothing # hide
gridded_fields=GriddedFields.load()
output_file=MITprof.format(gridded_fields,input_file)
ds2=Dataset(output_file)
keys(ds2)
```

### Associated Data Structure

The generated file can be accessed normally as a NetCDF file (e.g., `Dataset(output_file)`) or using the convenient `MITprofStandard` data structure.

```@example main
mp=MITprofStandard(output_file)
```

### Sample `MITprof` Files

The full set of MITprof profiles processed in 2023 from the [Argo](https://argo.ucsd.edu/) data base is available in [this Dataverse](https://doi.org/10.7910/DVN/7HLV09). This dataset can be explored and retrieved using [Dataverse.jl](https://github.com/gdcc/Dataverse.jl#readme).

```@example
using Dataverse
doi="https://doi.org/10.7910/DVN/7HLV09"
lst=Dataverse.file_list(doi)
Dataverse.file_download(lst,lst.filename[2],tempdir())
```

Another example is the original collection of MITprof files from [Forget, et al 2015](http://dx.doi.org/10.5194/gmd-8-3071-2015) is archived in [this Dataverse](https://doi.org/10.7910/DVN/EE3C40). This contains an earlier versio of Argo along with complementary datasets.

```@example
using Dataverse
doi="https://doi.org/10.7910/DVN/EE3C40"
lst=Dataverse.file_list(doi)
```

## Argo via Python API

The python library called [argopy](https://img.shields.io/readthedocs/argopy?logo=readthedocs) provides more ways to access, manipulate, and visualize [Argo data](https://argopy.readthedocs.io/en/latest/what_is_argo.html#what-is-argo). The notebook below demonstrates how you can : 

1. install `argopy` into `Julia` via [Conda.jl](https://github.com/JuliaPy/Conda.jl)
2. use `argopy` from Julia via [PyCall.jl](https://github.com/JuliaPy/PyCall.jl)

👉 [Notebook](http://gaelforget.net/notebooks/Argo_argopy.html) 👈 [(code)](https://raw.githubusercontent.com/euroargodev/ArgoData.jl/master/examples/Argo_argopy.jl)
