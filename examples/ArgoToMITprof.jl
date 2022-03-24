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

# +
#for verification, record intermediate step:
T_step0=prof["T"]; S_step0=prof["S"]; p_step0=prof["p"];

argo_data["JULD"][1]
# -

# ## process profile

# +
#various conversions (if meta says so):
ArgoTools.prof_convert!(prof,meta)

#for verification, record intermediate step:
T_step1=prof["T"]; S_step1=prof["S"]; D_step1=prof["depth"];
# -

#interpolate to standard depth levels
ArgoTools.prof_interp!(prof,meta)

# ## verification / CI

#verification / CI
k=findall((!ismissing).(p_step0))[200]
println(p_step0[k]==401.799987792968724)

#verification / CI
println(T_step1[200]==13.80094224720384374)

# ## verification / visual

scatter(S_step0,T_step0,title="temperature-salinity")
scatter!(prof["S"],prof["T"],leg=:none)

# + {"cell_style": "center"}
scatter(T_step1,-D_step1,title="temperature")
scatter!(prof["T"],-meta["z_std"],ylims=(-2000.0,0.0),leg=:none)

# + {"cell_style": "center"}
scatter(S_step1,-D_step1,title="salinity")
scatter!(prof["S"],-meta["z_std"],ylims=(-2000.0,0.0),leg=:none)
# -

