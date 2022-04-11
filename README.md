# ArgoData

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaOcean.github.io/ArgoData.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaOcean.github.io/ArgoData.jl/dev)
[![CI](https://github.com/JuliaOcean/ArgoData.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/JuliaOcean/ArgoData.jl/actions/workflows/ci.yml)
[![DOI](https://zenodo.org/badge/237021498.svg)](https://zenodo.org/badge/latestdoi/237021498)

Argo data processing and analysis. 

- The `GDAC` module functions access and retrieve files from the Argo data servers. 
- `MITprof` supports the format of [Forget, et al 2015](http://dx.doi.org/10.5194/gmd-8-3071-2015) for standard depth data sets like [this one](https://doi.org/10.7910/DVN/EE3C40).

_This package is in early developement stage when breaking changes can be expected._

Argo Float Positions            | Argo Float Profiles (T, S, ...)
:------------------------------:|:---------------------------------:
![float positions](https://user-images.githubusercontent.com/20276764/150622726-61169b99-4320-4069-b113-5edabb9b64fe.png) | ![](https://user-images.githubusercontent.com/20276764/150622766-aee5773d-7fea-4360-9b47-05f68e235499.png)   

Argo Profile Distributions |  Cost Funtions & Uncertainties
:------------------------------:|:---------------------------------:
![salinity profiles](https://user-images.githubusercontent.com/20276764/162780174-29ce0951-1bc7-42a7-8626-113b29d08dc0.png)  |  ![cost_pdf](https://user-images.githubusercontent.com/20276764/162803583-13891235-4809-4a57-b5f6-098083190d6d.png)

