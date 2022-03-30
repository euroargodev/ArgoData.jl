using ArgoData, Downloads, NCDatasets, Statistics

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
isfile(fil) ? meta["greylist"]=GDAC.greylist(fil) : nothing

gridded_fields=GriddedFields.load()
output_file=MITprof.MITprof_format(meta,gridded_fields,input_file,output_file)

##

ds=Dataset(output_file)

tmp_cost=ds["prof_Sweight"].* ((ds["prof_S"]-ds["prof_Sestim"]).^2)
ii=findall( ((!ismissing).(tmp_cost)).+(ds["prof_Sweight"].>0).>1 );
println(mean(tmp_cost[ii]))
#1.365848840650727
#1.3658547749903598

tmp_cost=ds["prof_Tweight"].* ((ds["prof_T"]-ds["prof_Testim"]).^2);
ii=findall( ((!ismissing).(tmp_cost)).+(ds["prof_Tweight"].>0).>1 );
println(mean(tmp_cost[ii]))
#1.4125672446566286
#1.41256622801185
