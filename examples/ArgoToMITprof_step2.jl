# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
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

# ## Outline
#
# 1. Start From Step 1 Result
# 1. Uncertainty Profiles
# 1. Seasonal Climatologies
# 1. MITprof File Creation

include("ArgoToMITprof_step1.jl")

using Plots
do_plot=true

# ## Load Gridded Fields
#
# - grid : ECCO global grid (LLC90; incl. land mask).
# - monthly T/S mean climatology (jan,feb, .. dec)
# - annual T/S variance climatology (non-seasonal)

gridded_fields=GriddedFields.load();

# ## Uncertainty Profiles
#
# The result is expressed as a least-squares weight.
#
# 1. spatial interpolation
# 2. vertical interpolation
# 3. combine instrumental and representation error
#
# **Note: σT,σS may still need to account for bounds at this point.**

# +
#1. spatial interpolation

(f,i,j,w)=GriddedFields.InterpolationFactors(gridded_fields.Γ,prof.lon,prof.lat)
📚=(f=f,i=i,j=j,w=w)

# +
prof_σT=[GriddedFields.Interpolate(gridded_fields.σT[:,k],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
prof_σS=[GriddedFields.Interpolate(gridded_fields.σS[:,k],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]

prof_σT_step1=prof_σT #for visual verification

prof_σT[1:5]

# +
#2. vertical interpolation

z_std=meta["z_std"]
prof_σT=ArgoTools.interp_z(-gridded_fields.Γ.RC,prof_σT,z_std)
prof_σT[1:5]
# -

if do_plot
    plot(prof_σT_step1,gridded_fields.Γ.RC,label="native", legend = :bottomright,marker=:+, xlabel="degree K", ylabel="depth")
    plot!(prof_σT[1:55],-z_std[1:55],label="interpolated",marker=:x)
end

# +
#3. combine instrumental and representation error

prof_std.Tweight.=1 ./(prof_σT.^2 .+ prof_std.T_ERR.^2)
prof_std.Tweight[1:5]

# +
#4. salinity

prof_σS=ArgoTools.interp_z(-gridded_fields.Γ.RC,prof_σS,z_std)
prof_std.Sweight.=1 ./(prof_σS.^2 .+ prof_std.S_ERR.^2)
prof_std.Sweight[1:5]
# -

# ## Seasonal Climatology Profiles

# +
#4. spatio-temporal interpolation

(fac0,fac1,rec0,rec1)=GriddedFields.monthly_climatology_factors(prof.date[1])
# -

prof_T0=[GriddedFields.Interpolate(gridded_fields.T[rec0][:,k],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
prof_T1=[GriddedFields.Interpolate(gridded_fields.T[rec1][:,k],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50];

prof_std.Testim.=ArgoTools.interp_z(-gridded_fields.Γ.RC,fac0*prof_T0+fac1*prof_T1,z_std)
prof_std.Testim[1:5]

if do_plot
    plot(prof_std.Testim,-z_std,marker=:x,label="climatology", legend = :bottomright, xlabel="degree C", ylabel="depth")
    plot!(prof_std.T[1:55],-z_std[1:55],marker=:o,label="data")
end

# +
#4. spatio-temporal interpolation

prof_S0=[GriddedFields.Interpolate(gridded_fields.S[rec0][:,k],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
prof_S1=[GriddedFields.Interpolate(gridded_fields.S[rec1][:,k],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50];
# -

prof_std.Sestim.=ArgoTools.interp_z(-gridded_fields.Γ.RC,fac0*prof_S0+fac1*prof_S1,z_std)
prof_std.Sestim[1:5]

ArgoTools.prof_test_set2!(prof_std,meta);

# ## MITprof File Creation

# +
meta["fileOut"]=joinpath(tempdir(),"MITprof_example.nc")
isfile(meta["fileOut"]) ? rm(meta["fileOut"], force=true) : nothing

MITprof.write(meta,[prof],[prof_std])
# -

# ### Show Global Maps (via interpolation)

# +
function interpolate_map(Γ)
    lon=[i for i=-179.5:1.0:179.5, j=-89.5:1.0:89.5]
    lat=[j for i=-179.5:1.0:179.5, j=-89.5:1.0:89.5]
    (f,i,j,w)=GriddedFields.InterpolationFactors(Γ,vec(lon),vec(lat))
    (f=f,i=i,j=j,w=w,lon=vec(lon[:,1]),lat=vec(lat[1,:]))
end

🌐=interpolate_map(gridded_fields.Γ);   
# -

ni,nj=length(🌐.lon),length(🌐.lat)
σTm=Array{Float64,3}(undef,(ni,nj,50))
σSm=Array{Float64,3}(undef,(ni,nj,50))
for k=1:50
    tmp=GriddedFields.Interpolate(gridded_fields.σT[:,k],🌐.f,🌐.i,🌐.j,🌐.w)
    σTm[:,:,k]=reshape(tmp,(ni,nj))
    tmp=GriddedFields.Interpolate(gridded_fields.σS[:,k],🌐.f,🌐.i,🌐.j,🌐.w)
    σSm[:,:,k]=reshape(tmp,(ni,nj))
end

if do_plot
    contourf(🌐.lon,🌐.lat,log10.(transpose(σTm[:,:,20]).^2),clims=(-2.5,1.0),title="log10(temperature variance) at 300m")
end

if do_plot
    tmp1=GriddedFields.Interpolate(gridded_fields.T[6][:,20],🌐.f,🌐.i,🌐.j,🌐.w)
    contourf(🌐.lon,🌐.lat,tmp1,clims=(-2.0,20.0),title="temperature in June at 300m")
end


