module MITprof

using Dates, MeshArrays, NCDatasets, OrderedCollections, UnPack, Glob, DataFrames

import ArgoData.ProfileNative
import ArgoData.ProfileStandard
import ArgoData.MITprofStandard
import ArgoData.ArgoTools
import ArgoData.GriddedFields
import ArgoData.GDAC

## writing MITprof files

"""
    MITprof.write(meta,profiles,profiles_std;path="")

Create an MITprof file from meta data + profiles during `MITprof.format`.

```
MITprof.write(meta,profiles,profiles_std)
```
"""
function write(meta::Dict,profiles::Array,profiles_std::Array;path="")

    isempty(path) ? p=tempdir() : p=path
    fil=joinpath(p,meta["fileOut"])

    z=Float64.(meta["depthLevels"])
    k=findall((z.>=meta["depthRange"][1]) .& (z.<=meta["depthRange"][2]))

    iPROF = length(profiles[:])
    iDEPTH = length(k)
    iINTERP = 4
    lTXT = 30
    
    ##
    
    NCDataset(fil,"c") do ds
        defDim(ds,"iPROF",iPROF)
        defDim(ds,"iDEPTH",iDEPTH)
        defDim(ds,"iINTERP",iINTERP)
        defDim(ds,"lTXT",lTXT)
        ds.attrib["title"] = "MITprof file created by ArgoData.jl (WIP)"
    end

    ##

    NCDataset(fil,"a") do ds
      defVar(ds,"prof_depth",z[k],("iDEPTH",),
            attrib = OrderedDict(
         "units" => "m",
         "_FillValue" => -9999.,
         "long_name" => "Depth"
      ))
    end
    
    ##
    
    data1 = Array{Union{Missing, Float64}, 1}(undef, iPROF)
    
    ##
    
    [data1[i]=profiles[i].lon[1] for i in 1:iPROF]
    ncwrite_1d(data1,fil,"prof_lon","Longitude (degree East)","degrees_east")

    [data1[i]=profiles[i].lat[1] for i in 1:iPROF]
    ncwrite_1d(data1,fil,"prof_lat","Latitude (degree North)","degrees_north")

    [data1[i]=profiles[i].date[1] for i in 1:iPROF]
    ncwrite_1d(data1,fil,"prof_date","Julian day since Jan-1-0000"," ") ##need units
    
    [data1[i]=profiles[i].ymd[1] for i in 1:iPROF]
    ncwrite_1d(data1,fil,"prof_YYYYMMDD","year (4 digits), month (2 digits), day (2 digits)"," ") ##need units

    [data1[i]=profiles[i].hms[1] for i in 1:iPROF]
    ncwrite_1d(data1,fil,"prof_HHMMSS","hour (2 digits), minute (2 digits), second (2 digits)"," ") ##need units

# 	double prof_basin(iPROF) ;
# 	double prof_point(iPROF) ;

    ##

    data = Array{Union{Missing, Float64}, 2}(undef, iPROF, iDEPTH)
    
    ##
    
    [data[i,:].=profiles_std[i].T[k] for i in 1:iPROF]
    ncwrite_2d(data,fil,"prof_T","Temperature","degree_Celsius")

    [data[i,:].=profiles_std[i].Tweight[k] for i in 1:iPROF]
    ncwrite_2d(data,fil,"prof_Tweight","Temperature least-square weight","(degree C)^-2")

    [data[i,:].=profiles_std[i].Testim[k] for i in 1:iPROF]
    ncwrite_2d(data,fil,"prof_Testim","Temperature atlas (monthly clim.)","degree_Celsius")

# 	double prof_Terr(iPROF, iDEPTH) ;
# 	double prof_Tflag(iPROF, iDEPTH) ;

    ##

    [data[i,:].=profiles_std[i].S[k] for i in 1:iPROF]
    ncwrite_2d(data,fil,"prof_S","Salinity","psu")

    [data[i,:].=profiles_std[i].Sweight[k] for i in 1:iPROF]
    ncwrite_2d(data,fil,"prof_Sweight","Salinity least-square weight","(psu)^-2")

    [data[i,:].=profiles_std[i].Sestim[k] for i in 1:iPROF]
    ncwrite_2d(data,fil,"prof_Sestim","Salinity atlas (monthly clim.)","psu")

# 	double prof_Serr(iPROF, iDEPTH) ;
# 	double prof_Sflag(iPROF, iDEPTH) ;

    fil
end

##

"""
    write(fil::String,mp::MITprofStandard)

Create an MITprof file from an MITprofStandard input.  
"""
write(fil::String,mp::MITprofStandard) = write(fil,[mp])

"""
    write(fil::String,mps::Vector{MITprofStandard})

Create an MITprof file from a vector of MITprofStandard inputs.  
"""
function write(fil::String,mps::Vector{MITprofStandard})

    nps=cumsum([size(mps[i].T,1) for i in 1:length(mps)])

    iPROF = nps[end]
    iDEPTH = size(mps[1].T,2)
    iINTERP = 4
    lTXT = 30

    NCDataset(fil,"c") do ds
        defDim(ds,"iPROF",iPROF)
        defDim(ds,"iDEPTH",iDEPTH)
        defDim(ds,"iINTERP",iINTERP)
        defDim(ds,"lTXT",lTXT)
        ds.attrib["title"] = "MITprof file created by ArgoData.jl (WIP)"
    end

    ##

    list_variables=(:lon,:lat,:date,:depth,:T,:Te,:Tw,:S,:Se,:Sw)
    #to be added : ID, ymd, hms, and maybe more
    [defVar_fromVar(fil,getfield(mps[1],var)) for var in list_variables]

    list_variables=(:lon,:lat,:date,:T,:Te,:Tw,:S,:Se,:Sw)
    ds=NCDataset(fil,"a")
    for var in list_variables
        for ii in 1:length(mps)
            tmp=getfield(mps[ii],var)
            ii==1 ? jj=collect(1:nps[1]) : jj=collect(nps[ii-1]+1:nps[ii])
            if ndims(tmp)==1
                ds[name(tmp)][jj]=tmp[:]
            else
                ds[name(tmp)][jj,:]=tmp[:,:]
            end
        end
    end
    close(ds)

end

##

function ncread(f::String,v::String)
    Dataset(f,"r") do ds
        ds[v][:]
    end
end

function defVar_fromVar(fil,var)
    T=eltype(skipmissing(var))
    NCDataset(fil,"a") do ds
        defVar(ds,name(var),T,dimnames(var),
            attrib = OrderedDict(
            "units" => var.attrib["units"],
            "_FillValue" => var.attrib["_FillValue"],
            "long_name" => var.attrib["long_name"]
        ))
    end
end

function ncwrite_2d(data,fil,name,long_name,units)
    NCDataset(fil,"a") do ds
      defVar(ds,name,data,("iPROF","iDEPTH"),
            attrib = OrderedDict(
         "units" => units,
         "_FillValue" => -9999.,
         "long_name" => long_name
      ))
    end
end

function ncwrite_1d(data,fil,name,long_name,units)
    NCDataset(fil,"a") do ds
        defVar(ds,name,data,("iPROF",),
            attrib = OrderedDict(
        "units" => units,
        "_FillValue" => -9999.,
        "long_name" => long_name
        ))
    end
end

##

"""
    format(gridded_fields,input_file)

From Argo file name as input : read input file content, process into the MITprof format, and write to MITprof file.

```
MITprof.format(gridded_fields,input_file)
```
"""
function format(gridded_fields,input_file)
    output_file=input_file[1:end-8]*"_MITprof.nc"
    meta=ArgoTools.meta(input_file,output_file)
    format(meta,gridded_fields,input_file,output_file)    
end

"""
    format(meta,gridded_fields,input_file,output_file="")

From Argo file name as input : read input file content, process into the MITprof format, and write to MITprof file.

```
MITprof.format(meta,gridded_fields,input_file)
```
"""
function format(meta,gridded_fields,input_file,output_file="")
    @unpack Γ,msk,T,S,σT,σS = gridded_fields
    z_std = meta["z_std"]

    isempty(output_file) ? output_file=joinpath(tempdir(),"MITprof_"*input_file) : nothing

    argo_data=Dataset(input_file)
    haskey(argo_data.dim,"N_PROF") ? np=argo_data.dim["N_PROF"] : np=NaN

    nz=length(z_std)

    profiles=Array{ProfileNative,1}(undef,np)
    profiles_std=Array{ProfileStandard,1}(undef,np)
    
    prof_σT=Array{Float64,1}(undef,50)
    prof_σS=Array{Float64,1}(undef,50)
    tmp1=Array{Float64,1}(undef,50)
    tmp2=Array{Float64,1}(undef,50)

    for m in 1:np
        #println(m)
    
        prof=ArgoTools.GetOneProfile(argo_data,m)
        prof_std=ProfileStandard(nz)
    
        ArgoTools.prof_convert!(prof,meta)
        ArgoTools.prof_interp!(prof,prof_std,meta)
    
        ArgoTools.prof_test_set1!(prof,prof_std,meta)

        ##
    
        if prof.lat[1]>-89.99

        (f,i,j,w)=InterpolationFactors(Γ,prof.lon[1],prof.lat[1])
        📚=(f=f,i=i,j=j,w=w)
    
        GriddedFields.interp_h(σT,📚.f,📚.i,📚.j,📚.w,prof_σT)
        GriddedFields.interp_h(σS,📚.f,📚.i,📚.j,📚.w,prof_σS)
    
        if sum( (!isnan).(prof_σT) )>0
            tmp_σT=ArgoTools.interp_z(-Γ.RC,prof_σT,z_std)
            tmp_σS=ArgoTools.interp_z(-Γ.RC,prof_σS,z_std)
        
            #3. combine instrumental and representation error
            prof_std.Tweight.=1 ./(tmp_σT.^2 .+ prof_std.T_ERR.^2)
            prof_std.Sweight.=1 ./(tmp_σS.^2 .+ prof_std.S_ERR.^2)
        else
            prof_std.Tweight.=0.0
            prof_std.Sweight.=0.0
        end
    
        ##
        
        if sum( (!isnan).(prof_σT) )>0
            fac,rec=ArgoTools.monthly_climatology_factors(prof.date[1])

            GriddedFields.interp_h(T[rec[1]],📚.f,📚.i,📚.j,📚.w,tmp1)
            GriddedFields.interp_h(T[rec[2]],📚.f,📚.i,📚.j,📚.w,tmp2)
            prof_std.Testim.=ArgoTools.interp_z(-Γ.RC,fac[1]*tmp1+fac[2]*tmp2,z_std)
    
            GriddedFields.interp_h(S[rec[1]],📚.f,📚.i,📚.j,📚.w,tmp1)
            GriddedFields.interp_h(S[rec[2]],📚.f,📚.i,📚.j,📚.w,tmp2)
            prof_std.Sestim.=ArgoTools.interp_z(-Γ.RC,fac[1]*tmp1+fac[2]*tmp2,z_std)
        end

        end #if prof.lat[1]>-89.99
    
        #

        ArgoTools.prof_test_set2!(prof_std,meta)

        #
    
        profiles[m]=prof
        profiles_std[m]=prof_std
    end

    MITprof.write(meta,profiles,profiles_std)
end

"""
    format_loop(II)

Loop over files and call `format`.

```
gridded_fields=GriddedFields.load()
files_list=GDAC.files_list()
MITprof.format_loop(gridded_fields,files_list,1:10)
```   
"""
function format_loop(gridded_fields,files_list,II)

    pth0=joinpath(tempdir(),"Argo_MITprof_files")
    pth1=joinpath(pth0,"input")
    pth2=joinpath(pth0,"MITprof")

    fil=joinpath(pth1,"ar_greylist.txt")
    isfile(fil) ? greylist=GDAC.grey_list(fil) : greylist=""

    for i in II
        println(i)

        wmo=string(files_list[i,:wmo])
        input_file=joinpath(pth1,files_list[i,:folder],wmo,wmo*"_prof.nc")
        output_file=joinpath(pth2,wmo*"_MITprof.nc")

        meta=ArgoTools.meta(input_file,output_file)
        meta["greylist"]=greylist

        if isfile(input_file)
            ds=Dataset(input_file)
            if haskey(ds,"PSAL")*haskey(ds,"TEMP")
                output_file=MITprof.format(meta,gridded_fields,input_file,output_file)
                println("✔ $(wmo)")
            else
                io = open(output_file[1:end-3]*".txt", "w")
                write(io, "Skipped file $(wmo) <- missing PSAL or TEMP\n")
                close(io)

                println("... skipping $(wmo)!")
            end

        else
            io = open(output_file[1:end-3]*".txt", "w")
            write(io, "Skipped file $(wmo) <- no input file\n")
            close(io)

            println("... skipping $(wmo)!")
        end
    end
end

"""
    cost_functions(vv="prof_T",JJ=[])

Loop through files and compute nb profiles, nb non-blank profiles, nb levels mean, cost mean.

```
pth="nc/"
nt,np,nz,cost=cost_functions(pth,"prof_S")

using JLD2
jldsave(joinpath(pth,"prof_S_stats.jld2"); nt,np,nz,cost)
```
"""
function cost_functions(pth,vv="prof_T",JJ=[])
    list_nc=glob("*.nc",pth)
    list_txt=glob("*.txt",pth)

    nt=[]
    np=[]
    nz=[]
    cost=[]

    isempty(JJ) ? II=(1:length(list_nc)) : II=JJ
    time0=time()
    for ii in II
        mod(ii,100)==0 ? println(time()-time0) : nothing
        mod(ii,100)==0 ? println(ii) : nothing
        ds=Dataset(list_nc[ii])
        push!(nt,size(ds[vv],1))
        tmp1=sum((!ismissing).(ds[vv]),dims=2)
        tmp2=sum(tmp1.>0)
        if tmp2>0
            push!(np,tmp2)
            push!(nz,sum(tmp1)/tmp2)
            tmp1=(ds[vv]-ds[vv*"estim"]).^2 .*ds[vv*"weight"]
            if ~isa(tmp1,Matrix{Missing})
                tmp1[findall(ismissing.(tmp1))].=0.0
                push!(cost,sum(tmp1[:])/sum((tmp1[:].>0.0)))
            else
                push!(cost,missing)
            end
        else
            push!(np,0)
            push!(nz,0)
            push!(cost,0)
        end
        close(ds)
    end

    return nt,np,nz,cost
end


"""
    profile_positions(path)

Create table (`DataFrame`) of the positions and dates obtained by looping through files in `path`. 
Additional information such as float `ID`, position on the ECCO grid `pos`, number of 
valid data points for T and S (`nbT` ,`nbS`).

```
path="nc/"
csv_file="profile_positions.csv"

using MeshArrays
γ=GridSpec("LatLonCap",MeshArrays.GRID_LLC90)
Γ=GridLoad(γ)

df=profile_positions(path,Γ)
CSV.write(csv_file, df)
```
"""
function profile_positions(path,Γ)
    list=glob("*.nc",path)
    nfiles=length(list)

    y=fill(0.0,nfiles,2)
    d=fill(DataFrame(),nfiles)

    #println("starting step 1")

    for ff in 1:nfiles
        output_file=joinpath(path,list[ff])
        mp=MITprofStandard(output_file)

        da=Dates.julian2datetime.(Dates.datetime2julian(DateTime(0,1,1)) .+mp.date)
        y[ff,1]=year(minimum(da))
        y[ff,2]=year(maximum(da))

        (f,i,j,c)=MeshArrays.knn(Γ.XC,Γ.YC,mp.lon[:],mp.lat[:])
        pos=[[f[ii],i[ii],j[ii]] for ii in 1:length(c)]

        nbT=sum((!ismissing).(mp.T[:,:]),dims=2)
        nbS=sum((!ismissing).(mp.S[:,:]),dims=2)

        d[ff]=DataFrame(ID=parse.(Int,mp.ID),lon=mp.lon,lat=mp.lat,
            date=da,pos=c[:],nbT=nbT[:],nbS=nbS[:])
    end

    #println("starting step 2")

    nd=length(findall((!isempty).(d)))
    df=d[1]
    [append!(df,d[ff]) for ff in 2:nd]

    df
end


end
