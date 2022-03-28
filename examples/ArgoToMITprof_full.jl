
using ArgoData, Downloads, NCDatasets
#using CSV, DataFrames

##

using MeshArrays
γ=GridSpec("LatLonCap",MeshArrays.GRID_LLC90)
Γ=GridLoad(γ,option="full")
msk=MITprof.NaN_mask(Γ)

using OceanStateEstimation
pth=MITPROFclim_path
OceanStateEstimation.MITPROFclim_download()

T=MITprof.MonthlyClimatology(pth*"T_OWPv1_M_eccollc_90x50.bin",msk)
S=MITprof.MonthlyClimatology(pth*"S_OWPv1_M_eccollc_90x50.bin",msk)
σT=MITprof.AnnualClimatology(pth*"sigma_T_nov2015.bin",msk)
σS=MITprof.AnnualClimatology(pth*"sigma_S_nov2015.bin",msk)

##

fil="../examples/ArgoToMITprof.yml"
meta=ArgoTools.mitprof_interp_setup(fil)
#greylist=DataFrame(CSV.File(meta["dirIn"]*"../ar_greylist.txt"));

#f=1
#fil=meta["dirIn"]*meta["fileInList"][f]; println(fil)

wmo=6900900
url0="https://data-argo.ifremer.fr/dac/coriolis/"
input_url=url0*"/$(wmo)/$(wmo)_prof.nc"
input_file=joinpath(tempdir(),"$(wmo)_prof.nc")
!isfile(input_file) ? fil=Downloads.download(input_url,input_file) : nothing
meta["fileOut"]="$(wmo)_MITprof.nc"

gridded_fields=(Γ=Γ,msk,T=T,S=S,σT=σT,σS=σS)

output_file=MITprof.MITprof_format(meta,gridded_fields,input_file,meta["fileOut"])
