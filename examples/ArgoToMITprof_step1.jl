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

# ## Input File
#
# 1. Choose one Argo float (e.g., `wmo=6900900`)
# 1. Download file to temporary folder (if needed).
# 1. Set up file names and parameters (`meta`)
# 1. Open file for lazy access (`data`)

# +
wmo=6900900

url0="https://data-argo.ifremer.fr/dac/coriolis/"
input_url=url0*"/$(wmo)/$(wmo)_prof.nc"
input_file=joinpath(tempdir(),"$(wmo)_prof.nc")
output_file=joinpath(tempdir(),"$(wmo)_MITprof.nc")

!isfile(input_file) ? fil=Downloads.download(input_url,input_file) : nothing

meta=ArgoTools.meta(input_file,output_file)

fil=joinpath(tempdir(),"ar_greylist.txt")
isfile(fil) ? meta["greylist"]=GDAC.greylist(fil) : nothing

data=Dataset(input_file)
# -

# ## Read Profile
#
# Let's read the first T/S profile from the input file (`prof`) and set up the data structure (`prof_std`) that will be used when interpolating to standard levels.

m=51
prof=ArgoTools.GetOneProfile(data,m);

nz=length(meta["z_std"])
prof_std=ArgoData.ProfileStandard(nz);

# +
#for verification, record intermediate step:
prof_step0=(T=prof.T, S=prof.S, P=prof.pressure)

#display date
data["JULD"][m]
# -

# ## Process Profile
#
# 1. Conversions, as specified in `meta`.
# 1. Interpolation to standard depth levels.

# +
#various conversions (as specified in `meta`):
ArgoTools.prof_convert!(prof,meta)

#for verification, record intermediate step:
prof_step1=(T=prof.T, S=prof.S, D=prof.depth);
# -

#interpolate to standard depth levels
ArgoTools.prof_interp!(prof,prof_std,meta)

#first series of tests
ArgoTools.prof_test_set1!(prof,prof_std,meta)

# ## Verification / CI

#verification / CI
k=findall((!ismissing).(prof_step0.P))[50]
println(prof_step0.P[k]==937.0)

prof_step0.T[k]

#verification / CI
println(prof_step1.T[k]==2.8032383695780343)

# ## Verification / Visual

scatter(prof_step0.S,prof_step0.T,title="Temperature-Salinity relationship",
    label="original levels",xlabel="psu",ylabel="degree C")
scatter!(prof_std.S,prof_std.T,color=:red,
    label="standard levels",legend = :topright)

# + {"cell_style": "center"}
scatter(prof_step1.T,-prof_step1.D,title="Potential Temperature",
    label="original levels",xlabel="degree C",ylabel="m")
scatter!(prof_std.T,-meta["z_std"],color=:red,ylims=(-2000.0,0.0),
    label="standard levels",legend = :bottomright)

# + {"cell_style": "center"}
scatter(prof_step1.S,-prof_step1.D,title="Salinity",
    label="original levels",xlabel="psu",ylabel="m")
scatter!(prof_std.S,-meta["z_std"],color=:red,ylims=(-2000.0,0.0),
    label="standard levels",legend = :topright)
# -

