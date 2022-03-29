# ArgoData.jl

Argo data processing and analysis. 

- The `GDAC` module functions access and retrieve files from the Argo data servers. 
- `MITprof` supports the format of [Forget, et al 2015](http://dx.doi.org/10.5194/gmd-8-3071-2015) for standard depth data sets like [this one](https://doi.org/10.7910/DVN/EE3C40).

_This package is in early developement stage when breaking changes can be expected._

```@index
```

## Workflows

Downloading and accessing an Argo file can simply be done like this.

```
using Downloads, NCDatasets

wmo=6900900
url0="https://data-argo.ifremer.fr/dac/coriolis/"
input_url=url0*"/$(wmo)/$(wmo)_prof.nc"
input_file=joinpath(tempdir(),"$(wmo)_prof.nc")
fil=Downloads.download(input_url,input_file)
Dataset(fil)
```

Formatting of an Argo file (`input_file`) into an MITprof file (`output_file`) proceeds as follows.

```
using ArgoData

meta=ArgoTools.meta(input_file,output_file)
gridded_fields=GriddedFields.load()
MITprof.MITprof_format(meta,gridded_fields,input_file,output_file)
```

For additional detail, please refer to the [examples/ArgoToMITprof.jl](https://github.com/JuliaOcean/ArgoData.jl/blob/master/examples/ArgoToMITprof.jl) example.

## Functions

```@autodocs
Modules = [MITprof,GDAC]
Order   = [:type,:function]
```

```@docs
ProfileNative
ProfileStandard
```

