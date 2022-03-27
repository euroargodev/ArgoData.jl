
using ArgoData, CSV, DataFrames, NCDatasets, Downloads

##

using MeshArrays
γ=GridSpec("LatLonCap",MeshArrays.GRID_LLC90)
Γ=GridLoad(γ,option="full")
msk=MITprof.NaN_mask(Γ)

using OceanStateEstimation
pth=MITPROFclim_path
T=MITprof.MonthlyClimatology(pth*"T_OWPv1_M_eccollc_90x50.bin",msk)
S=MITprof.MonthlyClimatology(pth*"S_OWPv1_M_eccollc_90x50.bin",msk)
σT=MITprof.AnnualClimatology(pth*"sigma_T_nov2015.bin",msk)
σS=MITprof.AnnualClimatology(pth*"sigma_S_nov2015.bin",msk)

##

fil="ArgoToMITprof.yml"
meta=ArgoTools.mitprof_interp_setup(fil)
#greylist=DataFrame(CSV.File(meta["dirIn"]*"../ar_greylist.txt"));
nz=length(meta["z_std"])

#f=1
#fil=meta["dirIn"]*meta["fileInList"][f]; println(fil)

url0="https://data-argo.ifremer.fr/dac/coriolis/"; wmo=6900900
fil=Downloads.download(url0*"/$(wmo)/$(wmo)_prof.nc")
meta["fileOut"]="$(wmo)_MITprof.nc"

argo_data=Dataset(fil)
haskey(argo_data.dim,"N_PROF") ? np=argo_data.dim["N_PROF"] : np=NaN

profiles=Array{ArgoData.ProfileNative,1}(undef,np)
profiles_std=Array{ArgoData.ProfileStandard,1}(undef,np)

for m in 1:np
    println(m)

    prof=ArgoTools.GetOneProfile(argo_data,m)
    prof_std=ArgoData.ProfileStandard(nz)

    ArgoTools.prof_convert!(prof,meta)
    ArgoTools.prof_interp!(prof,prof_std,meta)

    ##

    (f,i,j,w)=InterpolationFactors(Γ,prof.lon,prof.lat)
    📚=(f=f,i=i,j=j,w=w)

    prof_σT=[Interpolate(σT[:,k],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
    prof_σS=[Interpolate(σS[:,k],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]

    prof_σT=ArgoTools.interp1(-Γ.RC,prof_σT,meta["z_std"])
    prof_σS=ArgoTools.interp1(-Γ.RC,prof_σS,meta["z_std"])

    #3. combine instrumental and representation error
    prof_std.Tweight.=1 ./(prof_σT.^2 .+ prof_std.T_ERR.^2)
    prof_std.Sweight.=1 ./(prof_σS.^2 .+ prof_std.S_ERR.^2)

    ##

    fac,rec=ArgoTools.monthly_climatology_factors(prof.date)

    tmp1=[Interpolate(T[:,k,rec[1]],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
    tmp2=[Interpolate(T[:,k,rec[1]],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
    prof_std.Testim.=ArgoTools.interp1(-Γ.RC,fac[1]*tmp1+fac[2]*tmp2,meta["z_std"])

    tmp1=[Interpolate(S[:,k,rec[1]],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
    tmp2=[Interpolate(S[:,k,rec[1]],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
    prof_std.Sestim.=ArgoTools.interp1(-Γ.RC,fac[1]*tmp1+fac[2]*tmp2,meta["z_std"])

    #

    profiles[m]=prof
    profiles_std[m]=prof_std
end

##

MITprof.MITprof_write(meta,profiles,profiles_std)
