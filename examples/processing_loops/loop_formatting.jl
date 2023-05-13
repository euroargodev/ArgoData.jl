
using Distributed

@everywhere begin
    
    using ArgoData, Glob, NCDatasets, Statistics

    greylist=GDAC.grey_list()
    gridded_fields=GriddedFields.load()

    path0="/projects/data/usgodae.org/pub/outgoing/argo/dac/"
    path1="/projects/data/MITprof_Argo/"

    list=glob("*/*/*_prof.nc",path0)
    list1=glob("*.nc",path1)    
    tmp1=findall([sum(occursin.(basename(f),list1)) for f in list].==0)
    list=list[tmp1]
    
    n_to_do=length(list)
    n_per_worker=Int(ceil(n_to_do/nworkers()))
    #n_per_worker=min(250,n_per_worker)
    
end

@distributed for m in 1:nworkers()
    ii=collect((m-1)*n_per_worker+1:min(n_to_do,m*n_per_worker))
    println("$(ii[1]) to $(ii[end])")
    for input_file in list[ii]
        println(basename(input_file))

        output_file=joinpath(path1,basename(input_file))
        meta=ArgoTools.meta(input_file,output_file)
        meta["greylist"]=greylist

        MITprof.format(meta,gridded_fields,input_file,output_file)        
    end
end
