# ArgoData.jl

Argo data processing and analysis. 

- The `GDAC` module functions access and retrieve files from the Argo data servers. 
- `MITprof` supports the format of [Forget, et al 2015](http://dx.doi.org/10.5194/gmd-8-3071-2015) for standard depth data sets like [this one](https://doi.org/10.7910/DVN/EE3C40).

_This package is in early developement stage when breaking changes can be expected._

```@index
```

## Functions

```@autodocs
Modules = [MITprof,GDAC]
Order   = [:type,:function]
```

```@docs
ProfileNative
ProfileStandard
```

