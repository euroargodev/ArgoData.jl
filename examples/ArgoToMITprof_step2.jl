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

include("ArgoToMITprof_step1.jl")

do_plot=true

# ## Left after step 1
#
# ```
# # %load standardized data set:
# if ~dataset.skipSTEP1;
#   MITprofCur=MITprof_load([dataset.dirOut dataset.fileOut]);
# else;
#   MITprofCur=MITprof_load([dataset.dirIn dataset.fileIn]);
# end;
#
# MITprofCur=profiles_prep_locate(dataset,MITprofCur);
#
# MITprofCur.prof_Tflag=zeros(size(MITprofCur.prof_T));
# MITprofCur.prof_Sflag=zeros(size(MITprofCur.prof_S));
#
# # %instrumental + representation error profile:
# MITprofCur=profiles_prep_weights(dataset,MITprofCur,sigma);
#
# [MITprofCur]=profiles_prep_tests_cmpatlas(dataset,MITprofCur,atlas);
#
# # %overwrite file with completed arrays:
# MITprof_write([dataset.dirOut dataset.fileOut],MITprofCur);
#
# # %specify atlas names:
# ncid=ncopen([dataset.dirOut dataset.fileOut],'write');
# if isfield(MITprofCur,'prof_T'); ncaddAtt(ncid,'prof_Testim','long_name','pot. temp. atlas (OCCA | PHC in arctic| WOA in marginal seas)'); end;
# if isfield(MITprofCur,'prof_S'); ncaddAtt(ncid,'prof_Sestim','long_name','salinity atlas (OCCA | PHC in arctic| WOA in marginal seas)'); end;
# ncclose(ncid);
#
# if ~strcmp(dataset.coord,'depth'); mygrid=[]; atlas=[]; sigma=[]; end;
# ```

# ## load gridded fields
#
# - grid : ECCO global grid (LLC90; incl. land mask).
# - monthly T/S mean climatology (jan,feb, .. dec)
# - annual T/S variance climatology (non-seasonal)
#
# **Note: the following remains to be implemented.**
#
# ```
# % error variance bounds
# for kk=1:size(sigma.T{1},3);
#   % cap sigma.T(:,:,kk) to ..
#   tmp1=convert2vector(sigma.T(:,:,kk).*mygrid.mskC(:,:,kk));
#   tmp1(tmp1==0)=NaN;
#   tmp2=prctile(tmp1,5);%... its fifth percentile...
#   tmp2=max(tmp2,1e-3);%... or 1e-3 instrumental error floor:
#   tmp1(tmp1<tmp2|isnan(tmp1))=tmp2;
#   sigma.T(:,:,kk)=convert2vector(tmp1).*mygrid.mskC(:,:,kk);
#   % cap sigma.S(:,:,kk) to ..
#   tmp1=convert2vector(sigma.S(:,:,kk).*mygrid.mskC(:,:,kk));
#   tmp1(tmp1==0)=NaN;
#   tmp2=prctile(tmp1,5);%... its fifth percentile...
#   tmp2=max(tmp2,1e-3);%... or 1e-3 instrumental error floor:
#   tmp1(tmp1<tmp2|isnan(tmp1))=tmp2;
#   sigma.S(:,:,kk)=convert2vector(tmp1).*mygrid.mskC(:,:,kk);
# end;
# ```

# +
using MeshArrays

γ=GridSpec("LatLonCap",MeshArrays.GRID_LLC90)
Γ=GridLoad(γ,option="full")
msk=MITprof.NaN_mask(Γ)

"Done"

# +
using OceanStateEstimation

pth=MITPROFclim_path

T=MITprof.MonthlyClimatology(pth*"T_OWPv1_M_eccollc_90x50.bin",msk)
S=MITprof.MonthlyClimatology(pth*"S_OWPv1_M_eccollc_90x50.bin",msk)

σT=MITprof.AnnualClimatology(pth*"sigma_T_nov2015.bin",msk)
σs=MITprof.AnnualClimatology(pth*"sigma_S_nov2015.bin",msk)

"Done"
# -

# ### Plot maps via interpolation

# +
function interpolate_map(Γ)
    lon=[i for i=-179.5:1.0:179.5, j=-89.5:1.0:89.5]
    lat=[j for i=-179.5:1.0:179.5, j=-89.5:1.0:89.5]
    (f,i,j,w)=InterpolationFactors(Γ,vec(lon),vec(lat))
    (f=f,i=i,j=j,w=w,lon=vec(lon[:,1]),lat=vec(lat[1,:]))
end

🌐=interpolate_map(Γ);   
# -

ni,nj=length(🌐.lon),length(🌐.lat)
σTm=Array{Float64,3}(undef,(ni,nj,50))
for k=1:50
    tmp=Interpolate(σT[:,k],🌐.f,🌐.i,🌐.j,🌐.w)
    σTm[:,:,k]=reshape(tmp,(ni,nj))
end

# +
using Plots

if do_plot
    contourf(🌐.lon,🌐.lat,log10.(transpose(σTm[:,:,20]).^2),clims=(-2.5,1.0),title="log10(temperature variance) at 300m")
end
# -

if do_plot
    tmp=Interpolate(T[:,20,6],🌐.f,🌐.i,🌐.j,🌐.w)
    contourf(🌐.lon,🌐.lat,tmp,clims=(-2.0,20.0),title="temperature in June at 300m")
end

# ### Uncertainty Profile
#
# The result is expressed as a least-squares weight.
#
# 1. spatial interpolation
# 2. vertical interpolation
# 3. combine instrumental and representation error
#
# **Note: σT needs to account for bounds.**

# +
#1. spatial interpolation

(f,i,j,w)=InterpolationFactors(Γ,prof.lon,prof.lat)
📚=(f=f,i=i,j=j,w=w)
# -

prof_σT=[Interpolate(σT[:,k],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
prof_σT[1:5]

# +
#2. vertical interpolation

using Dierckx
# -

x=-Γ.RC
y=prof_σT
jj=findall(isfinite.(y))
xi=meta["z_std"]
spl = Spline1D(x[jj], y[jj], k=1, bc="nearest")

if do_plot
    plot(prof_σT,Γ.RC,label="native", legend = :bottomright,marker=:+, xlabel="degree K", ylabel="depth")
    plot!(spl(xi)[1:55],-xi[1:55],label="interpolated",marker=:x)
end

# +
#inspect the interpolation behavior:
#plot(spl(0.1:0.1:200))

# +
#3. combine instrumental and representation error

T_weight=1 ./(spl(meta["z_std"]).^2 .+ prof_std.T_ERR.^2)
T_weight[1:5]
# -

# ### Seasonal Climatology Profile

# +
#4. spatio-temporal interpolation

fac,rec=ArgoTools.monthly_climatology_factors(prof.date)
# -

prof_T1=[Interpolate(T[:,k,rec[1]],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
prof_T2=[Interpolate(T[:,k,rec[1]],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
prof_T0=fac[1]*prof_T1+fac[2]*prof_T2;

# +
x=-Γ.RC
y=prof_T0
jj=findall(isfinite.(y))
yi=meta["z_std"]
spl = Spline1D(x[jj], y[jj], k=1, bc="nearest")

prof_Tclim=spl(yi)
prof_Tclim[1:5]
# -

if do_plot
    plot(prof_Tclim,-yi,marker=:x,label="climatology", legend = :bottomright, xlabel="degree C", ylabel="depth")
    plot!(prof_std.T[1:55],-yi[1:55],marker=:o,label="data")
end


