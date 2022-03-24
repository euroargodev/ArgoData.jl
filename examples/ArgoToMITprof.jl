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

# +
using ArgoData, DataFrames, CSV, NCDatasets, Plots

fil="ArgoToMITprof.yml"
meta=DownloadArgo.mitprof_interp_setup(fil)
greylist=DataFrame(CSV.File(meta["dirIn"]*"../ar_greylist.txt"));
# -

meta

f=1
println(meta["dirIn"]*meta["fileInList"][f])
argo_data=Dataset(meta["dirIn"]*meta["fileInList"][f])
haskey(argo_data.dim,"N_PROF") ? np=argo_data.dim["N_PROF"] : np=NaN

m=1
prof=DownloadArgo.GetOneProfile(argo_data,m)

k=findall((!ismissing).(prof["T"]))[200]
prof["p"][k]-401.799987792968724

scatter(prof["S"],prof["T"])

# + {"cell_style": "split"}
#scatter(prof["T"],-prof["p"])

# + {"cell_style": "split"}
#scatter(prof["S"],-prof["p"])
# +
lonlatISbad=false
(prof["lat"]<-90.0)|(prof["lat"]>90.0) ? lonlatISbad=true : nothing
(prof["lon"]<-180.0)|(prof["lon"]>360.0) ? lonlatISbad=true : nothing

#if needed then reset lon,lat after issuing a warning
lonlatISbad==true ? println("warning: out of range lon/lat was reset to 0.0,-89.99") : nothing 
lonlatISbad ? (prof["lon"],prof["lat"])=(0.0,-89.99) : nothing

#if needed then fix longitude range to 0-360
(~lonlatISbad)&(prof["lon"]>180.0) ? prof["lon"]-=360.0 : nothing


# +
#if needed then convert pressure to depth
(~meta["inclZ"])&(~lonlatISbad) ? DownloadArgo.prof_PtoZ!(prof,meta) : nothing
println(prof[meta["var_out"][1]][200]-398.625084513574966)

#if needed then convert T to potential temperature θ
meta["TPOTfromTINSITU"] ? DownloadArgo.prof_TtoΘ!(prof,meta) : nothing
println(prof["T"][200]-13.80094224720384374)

T_step1=prof["T"]; S_step1=prof["S"]; D_step1=prof["depth"];

#interpolate to standard depth levels
DownloadArgo.prof_interp!(prof,meta)

# + {"cell_style": "center"}
scatter(T_step1,-D_step1,title="temperature")
scatter!(prof["T"],-meta["z_std"])

# + {"cell_style": "center"}
scatter(S_step1,-D_step1,title="salinity")
scatter!(prof["S"],-meta["z_std"])
# -
# ## Interpolation coefficients for monthly climatology

# +
using Dates

"""
    monthly_climatology_factors(date)

if `ff(rec)` returns one time record then `monthly_climatology_factors(date)`
provides the factors to interpolate as follows

```
ff(x)=sin((x-0.5)/12*2pi)
fac,rec=time_params(prof["date"])

gg=fac[1]*ff(rec[1])+fac[2]*ff(rec[2])
(ff(rec[1]),gg,ff(rec[2]))
```
"""
function monthly_climatology_factors(date)
    
    tmp2=ones(13,1)*[1991 1 1 0 0 0]; tmp2[1:12,2].=(1:12); tmp2[13,1]=1992.0;
    tmp2=[DateTime(tmp2[i,:]...) for i in 1:13]
    
    tim_fld=tmp2 .-DateTime(1991,1,1); 
    tim_fld=1/2*(tim_fld[1:12]+tim_fld[2:13])    
    tim_fld=[tim_fld[i].value for i in 1:12]/86400/1000
    
    tim_fld=[tim_fld[12]-365.0;tim_fld...;tim_fld[1]+365.0]
    rec_fld=[12;1:12;1]
    
#    year0=floor(profIn["ymd"]/1e4)    
    year0=year(DateTime(0,1,1)+Day(Int(floor(date))))
    date0=DateTime(year0,1,1)-DateTime(0)

    date0=date0.value/86400/1000    
    tim_prof=date-date0
    tim_prof>365.0 ? tim_prof=365.0 : nothing

    #tim_fld,rec_fld,tim_prof

    tt=maximum(findall(tim_fld.<=tim_prof))
    a0=(tim_prof-tim_fld[tt])/(tim_fld[tt+1]-tim_fld[tt])
    
    return (1-a0,a0),(rec_fld[tt],rec_fld[tt+1])
end

ff(x)=sin((x-0.5)/12*2pi)
fac,rec=time_params(prof["date"])

gg=fac[1]*ff(rec[1])+fac[2]*ff(rec[2])
(ff(rec[1]),gg,ff(rec[2]))
# -


