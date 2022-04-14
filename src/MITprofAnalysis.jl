module MITprofAnalysis

using Dates, MeshArrays, NCDatasets, Glob, DataFrames, CSV, Statistics

import ArgoData.MITprofStandard

## 1. Tasks that operate on MITprof files, directly, in a loop.
#
# - cost_functions : compute cost functions for each file
# - profile_positions : assemble table with all data point positions (-> csv/profile_positions.csv)
# - profile_variables : assemble table with all data for one variable (-> csv/prof_T.csv , etc)
# - profile_levels : date + slice of all variables (prof_T.csv, etc) at one level (-> csv_levels/k1.csv , etc)

"""
    cost_functions(vv="prof_T",JJ=[])

Loop through files and compute nb profiles, nb non-blank profiles, nb levels mean, cost mean.

```
pth="MITprof/"
nt,np,nz,cost=AnalysisMethods.cost_functions(pth,"prof_S")

using JLD2
jldsave(joinpath("csv","prof_S_stats.jld2"); nt,np,nz,cost)
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
using ArgoData
path="MITprof/"
csv_file="csv/profile_positions.csv"

using MeshArrays
γ=GridSpec("LatLonCap",MeshArrays.GRID_LLC90)
Γ=GridLoad(γ)

df=MITprofAnalysis.profile_positions(path,Γ)
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
        output_file=list[ff]
        mod(ff,100)==0 ? println("output_file $(ff) is "*output_file) : nothing

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

"""
    profile_variables(name::String)

Create Array of all values for one variable, obtained by looping through files in `path`. 

```
@everywhere using ArgoData, CSV, DataFrames
@everywhere list_v=("prof_T","prof_Testim","prof_Tweight","prof_S","prof_Sestim","prof_Sweight")
@distributed for v in list_v
    output_file="csv/"*v*".csv"
    tmp=MITprofAnalysis.profile_variables(v)
    CSV.write(output_file,DataFrame(tmp,:auto))
end
```
"""
function profile_variables(name::String)
    path="MITprof/"
    csv_file="csv/profile_positions.csv"
    df=CSV.read(csv_file,DataFrame)
    
    list=glob("*.nc",path)
    nfiles= length(list)
    x=Array{Union{Float64,Missing},2}(undef,size(df,1),55)
    n0=[0]
    for ff in 1:nfiles
        tmp=Dataset(list[ff],"r") do ds
            ds[name][:,:]
        end # ds is closed
        s=size(tmp)
        x[n0[1]+1:n0[1]+s[1],:].=tmp
        n0[1]+=s[1]
    end

    x
end

"""
    profile_levels()

Create Array of all values for one level, obtained by looping through files in `csv/`. 
"""
function profile_levels(k=0)
    k==0 ? kk=collect(1:55) : kk=[k]
    list_v=("prof_T","prof_Testim","prof_Tweight","prof_S","prof_Sestim","prof_Sweight")
    list_n=("T","Te","Tw","S","Se","Sw")

    csv_file="csv/profile_positions.csv"
    df0=CSV.read(csv_file,DataFrame)

    path="csv_levels/"
    
    nfiles= length(list_v)
    for ff in 1:nfiles
        println(list_v[ff])
        df=CSV.read(path*list_v[ff]*".csv",DataFrame)
        name=list_n[ff]
        for k in kk
            fil=path*"k$(k).csv"
            if ff==1
                df1=DataFrame(date=df0.date)
            else
                df1=CSV.read(fil,DataFrame)
            end
            println("x$(k)")
            df1[:,name]=df[:,Symbol("x$(k)")]
            CSV.write(fil,df1)
        end
    end

end

## 2. Functions that take csv as input
#
# - profile_add_level! : add e.g. "k1.csv" to DataFrame of "profile_positions.csv"
# - profile_subset : Subset of df that's within specified date and position ranges.    
# - profile_trim : Filter out data points that lack T, Te, etc.

"""
    profile_add_level!(df,k)

```
df=CSV.read("csv/profile_positions.csv",DataFrame)
MITprofAnalysis.profile_add_level!(df,5)
```
"""
function profile_add_level!(df,k)
    df1=CSV.read("csv_levels/k$(k).csv",DataFrame)
    list_n=("T","Te","Tw","S","Se","Sw")
    [df[:,Symbol(i)]=df1[:,Symbol(i)] for i in list_n]
end

"""
    profile_add_tile!(df,Γ,n)

```
df=CSV.read("csv/profile_positions.csv",DataFrame)
G=GriddedFields.load()
MITprofAnalysis.profile_add_tile!(df,G.Γ,30)
```
"""
function profile_add_tile!(df,Γ,n)
    γ=Γ.XC.grid
    τ=Tiles(γ,n,n)
    𝑻=MeshArray(γ)
    [𝑻[t.face][t.i,t.j].=t.tile for t in τ]
    df[:,Symbol("id$n")]=γ.write(𝑻)[parse_pos.(df.pos)];
end

parse_pos(p) = begin
    ii=parse.(Int,split(split(split(p,"(")[2],")")[1],","))
    CartesianIndex(ii...)
end

"""
    profile_subset(df,lons,lats,dates)

Subset of df that's within specified date and position ranges.    

```
df=CSV.read("csv/profile_positions.csv",DataFrame)
d0=DateTime("2012-06-11T18:50:04")
d1=DateTime("2012-07-11T18:50:04")
df1=MITprofAnalysis.profile_subset(df,(0,10),(-5,5),(d0,d1))
```
"""
profile_subset(df,lons,lats,dates) = 
    df[ (df.lon .> lons[1]) .& (df.lon .<= lons[2]) .&
    (df.lat .> lats[1]) .& (df.lat .<= lats[2]) .&
    (df.date .> dates[1]) .& (df.date .<= dates[2]) ,:]

#profile_subset(df,lons,lats,dates) = 
#    subset(df, [:lon, :lat, :date] => (lon, lat, date) -> 
#    lon .> lons[1] .&& lon .<= lons[2] .&&
#    lat .> lats[1] .&& lat .<= lats[2] .&& 
#    date .> dates[1] .&& date .<= dates[2])

"""
    profile_trim(df)

Filter out data points that lack T, Te, etc.

```
df=CSV.read("csv/profile_positions.csv",DataFrame)
MITprofAnalysis.profile_add_level!(df,1)
df1=MITprofAnalysis.profile_trim(df)
"""
profile_trim(df) = df[
    (!ismissing).(df.T) .& (!ismissing).(df.Te) .& (df.Tw.>0) .&
    (!ismissing).(df.S) .& (!ismissing).(df.Se) .& (df.Sw.>0) .&
    (df.date .> DateTime(1000,1,1)) .& (df.date .< DateTime(2022,4,1))
    ,:]


function profile_stat(df::DataFrame,by::Symbol,v::Symbol)
    gdf=groupby(df,by)
    df2=combine(gdf) do df
        (n = length(df.ID), mean=mean(df[:,v]) , median=mean(df[:,v]), var=var(df[:,v]))
    end

    df2
end

end #module MITprofAnalysis