# ArgoData.jl

Analysis and Processing of 
[Argo](https://argopy.readthedocs.io/en/latest/what_is_argo.html#what-is-argo) ocean data sets.

## Contents

- `GDAC` module to access and retrieve files from Argo server. 
- `MITprof` format of [Forget, et al 2015](http://dx.doi.org/10.5194/gmd-8-3071-2015) for [standard depth data](https://doi.org/10.7910/DVN/EE3C40).
- `MITprof_plots` module (in `examples/`) for `MITprof`.
- `AnalysisMethods` for cost functions and geospatial statistics.
- notebooks : [MITprof](https://euroargodev.github.io/ArgoData.jl/dev/ArgoToMITprof.html) simplified format, [argopy](http://gaelforget.net/notebooks/Argo_argopy.html) API from Julia.

_This package is in early developement stage when breaking changes can be expected._

Argo Float Positions            | Argo Float Profiles (T, S, ...)
:------------------------------:|:---------------------------------:
![float positions](https://user-images.githubusercontent.com/20276764/150622726-61169b99-4320-4069-b113-5edabb9b64fe.png) | ![salinity profiles](https://user-images.githubusercontent.com/20276764/150622766-aee5773d-7fea-4360-9b47-05f68e235499.png)   

Argo Profile Distributions |  Cost Funtions & Uncertainties
:------------------------------:|:---------------------------------:
![distributions](https://user-images.githubusercontent.com/20276764/162872972-dd7fc775-5303-4264-8277-142c02bc1b83.png)  |  ![cost pdf](https://user-images.githubusercontent.com/20276764/162803583-13891235-4809-4a57-b5f6-098083190d6d.png)

