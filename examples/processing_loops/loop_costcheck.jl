
using Distributed

@everywhere begin
    
    using DataFrames, CSV, Glob, NCDatasets, Statistics

    path="/projects/data/MITprof_Argo/"
    list=glob("*.nc",path)    
    
    function check_cost(fil; doPrint=false)
        ds=Dataset(fil)

        costT=ds["prof_Tweight"].* ((ds["prof_T"]-ds["prof_Testim"]).^2)
        ii=findall( ((!ismissing).(costT)).+(ds["prof_Tweight"].>0).>1 )
        jT=mean(costT[ii])
        doPrint ? println("mean T cost = $(jT) ") : nothing

        costS=ds["prof_Sweight"].* ((ds["prof_S"]-ds["prof_Sestim"]).^2)
        ii=findall( ((!ismissing).(costS)).+(ds["prof_Sweight"].>0).>1 );
        jS=mean(costS[ii])
        doPrint ? println("mean S cost = $(jS) ") : nothing

        close(ds)
        
        ismissing(jT) ? jT=NaN : nothing
        ismissing(jS) ? jS=NaN : nothing

        return DataFrame(jT=jT,jS=jS,file=basename(fil))
    end
    
    n_to_do=length(list)
    n_per_worker=Int(ceil(n_to_do/nworkers()))
    #n_per_worker=min(3,n_per_worker)    
end

@distributed for m in 1:nworkers()
    ii=collect((m-1)*n_per_worker+1:min(n_to_do,m*n_per_worker))
    c=DataFrame(jT=Float32[], jS=Float32[],file=String[])
    println("$(ii[1]) to $(ii[end])")
    [append!(c,check_cost(fil)) for fil in list[ii]]
    f=joinpath(tempdir(),"MITprof_cost_p$(m).csv")
    CSV.write(f,c)    
end
