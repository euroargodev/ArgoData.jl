
using ArgoData, Downloads
#using CSV, DataFrames

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

gridded_fields=GriddedFields.load()

output_file=MITprof.MITprof_format(meta,gridded_fields,input_file,meta["fileOut"])
