using ArgoData, Downloads

##

wmo=6900900
url0="https://data-argo.ifremer.fr/dac/coriolis/"
input_url=url0*"/$(wmo)/$(wmo)_prof.nc"
input_file=joinpath(tempdir(),"$(wmo)_prof.nc")
output_file=joinpath(tempdir(),"$(wmo)_MITprof.nc")

!isfile(input_file) ? fil=Downloads.download(input_url,input_file) : nothing
isfile(output_file) ? rm(output_file) : nothing

##

meta=ArgoTools.meta(input_file,output_file)

fil=joinpath(tempdir(),"ar_greylist.txt")
isfile(fil) ? meta["greylist"]=greylist(fil) : nothing

gridded_fields=GriddedFields.load()
output_file=MITprof.MITprof_format(meta,gridded_fields,input_file,output_file)
