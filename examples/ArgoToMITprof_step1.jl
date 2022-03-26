# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     cell_metadata_json: true
#     formats: ipynb,jl:light
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.5'
#       jupytext_version: 1.11.3
#   kernelspec:
#     display_name: Julia 1.7.2
#     language: julia
#     name: julia-1.7
# ---

using ArgoData, DataFrames, CSV, NCDatasets, Plots

# ## parameter files

# +
fil="ArgoToMITprof.yml"
meta=ArgoTools.mitprof_interp_setup(fil)
greylist=DataFrame(CSV.File(meta["dirIn"]*"../ar_greylist.txt"));

meta
# -

# ## read file, get profile

f=1
println(meta["dirIn"]*meta["fileInList"][f])
argo_data=Dataset(meta["dirIn"]*meta["fileInList"][f])
haskey(argo_data.dim,"N_PROF") ? np=argo_data.dim["N_PROF"] : np=NaN

m=1
prof=ArgoTools.GetOneProfile(argo_data,m)

nz=length(meta["z_std"])
prof_std=ArgoData.ProfileStandard(
    Array{Union{Float64,Missing},1}(undef,nz),
    Array{Union{Float64,Missing},1}(undef,nz),
    Array{Union{Float64,Missing},1}(undef,nz),
    Array{Union{Float64,Missing},1}(undef,nz)
)

# +
#for verification, record intermediate step:
prof_step0=(T=prof.T, S=prof.S, P=prof.pressure)

argo_data["JULD"][1]
# -

# ## process profile

# +
#various conversions (if meta says so):
ArgoTools.prof_convert!(prof,meta)

#for verification, record intermediate step:
prof_step1=(T=prof.T, S=prof.S, D=prof.depth)
# -

#interpolate to standard depth levels
ArgoTools.prof_interp!(prof,prof_std,meta)

# ## verification / CI

#verification / CI
k=findall((!ismissing).(prof_step0.P))[200]
println(prof_step0.P[k]==401.799987792968724)

#verification / CI
println(prof_step1.T[200]==13.80094224720384374)

# ## verification / visual

scatter(prof_step0.S,prof_step0.T,title="temperature-salinity")
scatter!(prof_std.S,prof_std.T,leg=:none)

# + {"cell_style": "center"}
scatter(prof_step1.T,-prof_step1.D,title="temperature")
scatter!(prof_std.T,-meta["z_std"],ylims=(-2000.0,0.0),leg=:none)

# + {"cell_style": "center"}
scatter(prof_step1.S,-prof_step1.D,title="salinity")
scatter!(prof_std.S,-meta["z_std"],ylims=(-2000.0,0.0),leg=:none)
# -

