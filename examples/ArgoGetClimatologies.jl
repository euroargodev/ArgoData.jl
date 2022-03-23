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

include("ArgoToMITprof.jl")

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
#
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

# ```
#     for tt=1:12;
#         fldT(:,:,:,tt)=read_bin('T_OWPv1_M_eccollc_90x50.bin',tt).*mygrid.mskC;
#         fldS(:,:,:,tt)=read_bin('S_OWPv1_M_eccollc_90x50.bin',tt).*mygrid.mskC;
#     end;
#
#     fprintf(['loading uncertainties from ' dirClim ' ...\n']);
#     sigma.T=read_bin([dirClim 'sigma_T_nov2015.bin']);
#     sigma.S=read_bin([dirClim 'sigma_S_nov2015.bin']);
#     disp('... uncertainties have been loaded');
#
#     % error variance bounds
#     for kk=1:size(sigma.T{1},3);
#       # # # # # # %cap sigma.T(:,:,kk) to ...
#       tmp1=convert2vector(sigma.T(:,:,kk).*mygrid.mskC(:,:,kk));
#       tmp1(tmp1==0)=NaN;
#       tmp2=prctile(tmp1,5);%... its fifth percentile...
#       tmp2=max(tmp2,1e-3);%... or 1e-3 instrumental error floor:
#       tmp1(tmp1<tmp2|isnan(tmp1))=tmp2;
#       sigma.T(:,:,kk)=convert2vector(tmp1).*mygrid.mskC(:,:,kk);
#       # # # # # # %cap sigma.S(:,:,kk) to ...
#       tmp1=convert2vector(sigma.S(:,:,kk).*mygrid.mskC(:,:,kk));
#       tmp1(tmp1==0)=NaN;
#       tmp2=prctile(tmp1,5);%... its fifth percentile...
#       tmp2=max(tmp2,1e-3);%... or 1e-3 instrumental error floor:
#       tmp1(tmp1<tmp2|isnan(tmp1))=tmp2;
#       sigma.S(:,:,kk)=convert2vector(tmp1).*mygrid.mskC(:,:,kk);
#     end;
#
#
# #tmp_weight=1./(sig_out.^2+sig_instr.^2);
# #eval(['MITprofCur.prof_' vv 'weight=tmp_weight;']);
# ```

# +
using MeshArrays

γ=GridSpec("LatLonCap",MeshArrays.GRID_LLC90)
Γ=GridLoad(γ,option="full")
(f,i,j,w)=InterpolationFactors(Γ,prof["lon"],prof["lat"])
XC=Interpolate(Γ.XC,f,i,j,w)
YC=Interpolate(Γ.YC,f,i,j,w)

#[prof["lon"] XC]
#[prof["lat"] YC]

# +
using OceanStateEstimation

pth=MITPROFclim_path
msk=write(Γ.hFacC)
msk[findall(msk.>0.0)].=1.0
msk[findall(msk.==0.0)].=NaN
msk=read(msk,Γ.hFacC)

function MonthlyClimatology(fil,msk)
    fid = open(fil)
    tmp = Array{Float32,4}(undef,(90,1170,50,12))
    read!(fid,tmp)
    tmp = hton.(tmp)
    close(fid)
    
    T=MeshArray(γ,Float64,50,12)
    for tt=1:12
        T[:,:,tt]=msk*read(tmp[:,:,:,tt],T[:,:,tt])
    end

    return T
end

function AnnualClimatology(fil,msk)
    fid = open(fil)
    tmp=Array{Float32,3}(undef,(90,1170,50))
    read!(fid,tmp)
    tmp = hton.(tmp)
    close(fid)

    T=MeshArray(γ,Float64,50)
    T=msk*read(convert(Array{Float64},tmp),T)
    return T
end

T=MonthlyClimatology(pth*"T_OWPv1_M_eccollc_90x50.bin",msk)
S=MonthlyClimatology(pth*"S_OWPv1_M_eccollc_90x50.bin",msk)

σT=AnnualClimatology(pth*"sigma_T_nov2015.bin",msk)
σs=AnnualClimatology(pth*"sigma_S_nov2015.bin",msk)

#heatmap(T[2,20,3])
#heatmap(σT[2,20])
# -

# ### Plot maps via interpolation

lon=[i for i=-179.5:1.0:179.5, j=-89.5:1.0:89.5]
lat=[j for i=-179.5:1.0:179.5, j=-89.5:1.0:89.5]
(f,i,j,w)=InterpolationFactors(Γ,vec(lon),vec(lat))

σTm=Array{Float64,3}(undef,(360,180,50))
for k=1:50
    tmp=Interpolate(σT[:,k],f,i,j,w)
    σTm[:,:,k]=reshape(tmp,size(lon))
end

using Plots
contourf(vec(lon[:,1]),vec(lat[1,:]),log10.(transpose(σTm[:,:,20])),clims=(-2.5,0.75))

tmp=Interpolate(T[:,20,6],f,i,j,w)
contourf(vec(lon[:,1]),vec(lat[1,:]),tmp,clims=(-2.0,30.0))

ii=1
prof["lon"][ii],prof["lat"][ii]

# +
#1. spatial interpolation

(f,i,j,w)=InterpolationFactors(Γ,prof["lon"][ii],prof["lat"][ii])
# -

tmp=[Interpolate(σT[:,k],f,i,j,w)[1] for k=1:50]

plot(tmp,Γ.RC)

# +
#2. vertical interpolation

using Dierckx
# -

x=-Γ.RC
y=tmp
jj=findall(isfinite.(y))
yi=meta["z_std"][1:55]
spl = Spline1D(x[jj], y[jj], k=1, bc="nearest")

plot(spl(yi),-yi)

plot(spl(0.1:0.1:200))


