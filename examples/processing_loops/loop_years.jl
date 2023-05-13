using Distributed

@everywhere begin
    
    using ArgoData, Dates
    using NCDatasets, CSV, DataFrames, Glob

    """
        subset(mp::MITprofStandard,selection::BitVector)

    ```
    mp=MITprofStandard(list1[1])
    mp1=subset(mp, (year.(mp.date).>=1999) .* (year.(mp.date).<2000))
    mp=MITprofStandard(list1[2])
    mp2=subset(mp, (year.(mp.date).>=1999) .* (year.(mp.date).<2000))
    mp3=combine(mp1,mp2)
    ```
    """
    function subset(mp::MITprofStandard,selection::BitVector)
        ii=findall(selection)
        if !isempty(ii)
            MITprofStandard(tempname()*"_MITprof.nc",
            mp.lon[ii],mp.lat[ii],mp.date[ii],mp.depth,mp.ID[ii],
            mp.T[ii,:],mp.Te[ii,:],mp.Tw[ii,:],
            mp.S[ii,:],mp.Se[ii,:],mp.Sw[ii,:])
        else
            missing
        end
    end

    function combine(mp1::MITprofStandard,mp2::MITprofStandard)
        !(mp1.depth==mp2.depth) ? error("inconsistent depths") : nothing
        MITprofStandard(tempname()*"_MITprof.nc",
        vcat(mp1.lon,mp2.lon),vcat(mp1.lat,mp2.lat),vcat(mp1.date,mp2.date),
        mp1.depth,vcat(mp1.ID,mp2.ID),
        vcat(mp1.T,mp2.T),vcat(mp1.Te,mp2.Te),vcat(mp1.Tw,mp2.Tw),
        vcat(mp1.S,mp2.S),vcat(mp1.Se,mp2.Se),vcat(mp1.Sw,mp2.Sw)
        )
    end

    function combine(mps)
        MITprofStandard(tempname()*"_MITprof.nc",
            vcat([mp.lon for mp in mps]...),
            vcat([mp.lat for mp in mps]...),
            vcat([mp.date for mp in mps]...),
            mps[1].depth[:],
            vcat([mp.ID for mp in mps]...),
            vcat([mp.T for mp in mps]...),
            vcat([mp.Te for mp in mps]...),
            vcat([mp.Tw for mp in mps]...),
            vcat([mp.S for mp in mps]...),
            vcat([mp.Se for mp in mps]...),
            vcat([mp.Sw for mp in mps]...),
        )
    end

    sublist(list,y0,y1) = list.file[findall( (list.y0.<=y0).*(list.y1.>=y1) )]
    sublist(list,y0) = sublist(list,y0,y0)

    function write(fil::String,mp,mpref)

        iPROF = size(mp.T,1) 
        iDEPTH = size(mp.T,2)

        NCDataset(fil,"c") do ds
            defDim(ds,"iPROF",iPROF)
            defDim(ds,"iDEPTH",iDEPTH)
            ds.attrib["title"] = "MITprof file created by ArgoData.jl"
        end

        list_variables=(:lon,:lat,:date,:depth,:T,:Te,:Tw,:S,:Se,:Sw)
        [ArgoData.MITprof.defVar_fromVar(fil,getfield(mpref,var)) for var in list_variables]
        
        ds=NCDataset(fil,"a")

        for var in list_variables
            tmp=getfield(mp,var)
            tmpref=getfield(mpref,var)
            if ndims(tmp)==1
                ds[name(tmpref)].=tmp
            else
                ds[name(tmpref)].=tmp
            end
        end
        
        #add ID, YYYYMMDD, HHMMSS
        
        t=Dates.julian2datetime.(Dates.datetime2julian(DateTime(0,1,1)) .+mp.date)
        ymd=Dates.year.(t)*1e4+Dates.month.(t)*1e2+Dates.day.(t)
        hms=Dates.hour.(t)*1e4+Dates.minute.(t)*1e2+Dates.second.(t)
 
        defVar(ds,"prof_ID",Int64,("iPROF",))
        defVar(ds,"prof_YYYYMMDD",Float64,("iPROF",))
        defVar(ds,"prof_HHMMSS",Float64,("iPROF",))

        ds["prof_YYYYMMDD"].=ymd
        ds["prof_HHMMSS"].=ymd
        ds["prof_ID"].=parse.(Int,mp.ID)

        close(ds)
    end

    ##

    path0="/projects/data/"

    fil0=joinpath(path0,"MITprof_Argo.csv")
    list0=CSV.read(fil0,DataFrame)

    list1=glob("MITprof_Argo/*.nc",path0)

    output_path=joinpath(path0,"MITprof_Argo_yearly")

    year1=2017
end #@everywhere begin


@sync @distributed for m in 1:nworkers()
    YEAR=year1 .+ (m-1)
    list2=sublist(list0,YEAR)

    println("year $(YEAR) step 1")

    mps=MITprofStandard[]
    for fil in list2
        mp=MITprofStandard(	joinpath(path0,"MITprof_Argo",fil) )
        da=Dates.julian2datetime.(Dates.datetime2julian(DateTime(0,1,1)) .+mp.date)
        mp=subset(mp, (year.(da).==YEAR))
        (!ismissing(mp))&&(!isempty(mp.lon)) ? push!(mps,mp) : nothing #println("skip $(fil)")
    end

    if !isempty(mps)
        println("year $(YEAR) step 2")
        mpc=combine(mps)
        mpref=MITprofStandard(list1[1])
        fil=joinpath(output_path,"MITprof_Argo_$(YEAR).nc")
        println(fil)
        write(fil,mpc,mpref)
    end
end
