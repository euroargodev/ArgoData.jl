module MITprofAnalysis

using Dates, MeshArrays, NCDatasets, Glob, DataFrames, CSV, Statistics, JLD2, Glob

import ArgoData.MITprofStandard
import ArgoData.ArgoTools: monthly_climatology_factors
import ArgoData.MITprof: default_path

## 1. Tasks that operate on MITprof files, directly, in a loop.
#
# - cost_functions : compute cost functions for each file
# - csv_of_positions : assemble table with all data point positions (-> csv/profile_positions.csv)
# - csv_of_variables : assemble table with all data for one variable (-> csv/prof_T.csv , etc)
# - csv_of_levels : date + slice of all variables (prof_T.csv, etc) at one level (-> csv_levels/k1.csv , etc)

"""
    cost_functions(vv="prof_T",JJ=[])

Loop through files and compute nb profiles, nb non-blank profiles, nb levels mean, cost mean.

```
pth="MITprof/"
nt,np,nz,cost=MITprofAnalysis.cost_functions(pth,"prof_S")

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
    isa(II,String) ? II=findall(basename.(list_nc).==JJ)[1] : nothing 

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
    csv_of_positions(path)

Create table (`DataFrame`) of the positions and dates obtained by looping through files in `path`. 
Additional information such as float `ID`, position on the ECCO grid `pos`, number of 
valid data points for T and S (`nbT` ,`nbS`).

```
using ArgoData
using MeshArrays
Γ=GridLoad(ID=:LLC90)
path=MITprof.default_path
df=MITprofAnalysis.csv_of_positions(path,Γ)
csv_file=joinpath(default_path,"profile_positions.csv")
CSV.write(csv_file, df)
```
"""
function csv_of_positions(path,Γ,file="")
    if isempty(file)
        list=glob("*.nc",path)
        nfiles=length(list)
    else
        list=[joinpath(path,file)]
        nfiles=1
    end

    y=fill(0.0,nfiles,2)
    d=fill(DataFrame(),nfiles)

    #println("starting step 1")

    for ff in 1:nfiles
        output_file=list[ff]
        true ? println("output_file $(ff) is "*output_file) : nothing

        mp=MITprofStandard(output_file)

        da=Dates.julian2datetime.(Dates.datetime2julian(DateTime(0,1,1)) .+mp.date)
        y[ff,1]=year(minimum(da))
        y[ff,2]=year(maximum(da))

        #fix to avoid issue in prepare_interpolation
        (lon,lat)=(mp.lon[:],mp.lat[:])
        ii=findall( isnan.(lon.*lat) )
        lon[ii].=0.0
        lat[ii].=-89.99
        
        (f,i,j,c)=MeshArrays.knn(Γ.XC,Γ.YC,lon,lat)
        pos=[[f[ii],i[ii],j[ii]] for ii in 1:length(c)]

        nbT=sum((!ismissing).(mp.T[:,:]),dims=2)
        nbS=sum((!ismissing).(mp.S[:,:]),dims=2)

        d[ff]=DataFrame(ID=parse.(Int,mp.ID),lon=lon,lat=lat,
            date=da,pos=c[:],nbT=nbT[:],nbS=nbS[:])
    end

    #println("starting step 2")

    nd=length(findall((!isempty).(d)))
    df=d[1]
    [append!(df,d[ff]) for ff in 2:nd]

    df
end

"""
    csv_of_variables(name::String)

Create Array of all values for one variable, obtained by looping through files in `path`. 

```
@everywhere using ArgoData, CSV, DataFrames
@everywhere list_v=("prof_T","prof_Testim","prof_Tweight","prof_S","prof_Sestim","prof_Sweight")
@distributed for v in list_v
    tmp=MITprofAnalysis.csv_of_variables(v)
    CSV.write(output_file,DataFrame(tmp,:auto))
end
```
"""
function csv_of_variables(name::String; path=default_path, csv=joinpath(default_path,"profile_positions.csv"))
    df=CSV.read(csv,DataFrame)
    
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
    prepare_interpolation(Γ,lon,lat) 
    
Alias for `InterpolationFactors(Γ,lon,lat)`. 

The loop below creates interpolation coefficients for all data points. 

The results are stored in a file called `csv/profile_coeffs.jld2` at the end.

```
using SharedArrays, Distributed

@everywhere begin
    using ArgoData
    G=GriddedFields.load()
    df=MITprofAnalysis.read_pos_level(5)

    np=size(df,1)
    n0=10000
    nq=Int(ceil(np/n0))
end

(f,i,j,w)=( SharedArray{Int64}(np,4), SharedArray{Int64}(np,4),
            SharedArray{Int64}(np,4), SharedArray{Float64}(np,4) )

@sync @distributed for m in 1:nq
    ii=n0*(m-1) .+collect(1:n0)
    ii[end]>np ? ii=n0*(m-1) .+collect(1:n0+np-ii[end]) : nothing
    tmp=MITprofAnalysis.prepare_interpolation(G.Γ,df.lon[ii],df.lat[ii])
    f[ii,:].=tmp[1]
    i[ii,:].=tmp[2]
    j[ii,:].=tmp[3]
    w[ii,:].=tmp[4]
end

fil=joinpath("csv","profile_coeffs.jld2")
co=[(f=f[ii,:],i=i[ii,:],j=j[ii,:],w=w[ii,:]) for ii in 1:np]
save_object(fil,co)
```
"""
prepare_interpolation(Γ,lon,lat) = InterpolationFactors(Γ,lon,lat)

"""
    csv_of_levels()

Create Array of all values for one level, obtained by looping through files in `csv/`. 
"""
function csv_of_levels(k=0; path=default_path, csv=joinpath(default_path,"profile_positions.csv"))
    df0=CSV.read(csv,DataFrame)
    path_input=path
    path_output=path

    k==0 ? kk=collect(1:55) : kk=[k]
    list_v=("prof_T","prof_Testim","prof_Tweight","prof_S","prof_Sestim","prof_Sweight")
    list_n=("T","Te","Tw","S","Se","Sw")
    vv=findall([isfile(joinpath(path_input,v*".csv")) for v in list_v])

    for ff in vv
        println("starting variable $(list_v[ff])")
        df=CSV.read(joinpath(path_input,list_v[ff]*".csv"),DataFrame)
        name=list_n[ff]
        for k in kk
            fil=joinpath(path_output,"k$(k).csv")
            if ff==vv[1]
                println("creating file $(fil)")
                df1=DataFrame(date=df0.date)
            else
                df1=CSV.read(fil,DataFrame)
            end
            df1[:,name]=df[:,Symbol("x$(k)")]
            CSV.write(fil,df1)
        end
    end
end

## 2. Functions that take csv as input
#
# - read_pos_level : read "csv_of_positions.csv" and e.g. "k1.csv" into DataFrame
# - add_level! : add e.g. "k1.csv" to DataFrame of "csv_of_positions.csv"
# - subset : Subset of df that's within specified date and position ranges.    
# - trim : Filter out data points that lack T, Te, etc.

"""
    read_pos_level(k=1; input_path="")

Read in from `csv/profile_positions.csv` and e.g. `csv_levels/k1.csv`,
parse `pos`, then `add_level!(df,k)`, and return a DataFrame.

```
df=MITprofAnalysis.read_pos_level(5)
```    
"""
function read_pos_level(k=1; input_path=default_path)
    df=CSV.read(joinpath(input_path,"profile_positions.csv"),DataFrame)
    df.pos=MITprofAnalysis.parse_pos.(df.pos)
    MITprofAnalysis.add_level!(df,k,input_path=input_path)
    df
end

"""
    add_coeffs!(df)

Read `profile_coeffs.jld2` and add to `df`.    

```
df=MITprofAnalysis.read_pos_level(5)
MITprofAnalysis.add_coeffs!(df)
```
"""
function add_coeffs!(df; input_path=default_path)
    df.📚=load_object(joinpath(input_path,"profile_coeffs.jld2"))
end

"""
    add_level!(df,k)

Read from e.g. `csv_levels/k1.csv` and add variables to `df`.    

```
df=CSV.read("csv/profile_positions.csv",DataFrame)
MITprofAnalysis.add_level!(df,5)
```
"""
function add_level!(df,k; input_path=default_path)
    df1=CSV.read(joinpath(input_path,"k$(k).csv"),DataFrame)
    #
    list_n=("T","Te","Tw","S","Se","Sw") 
    for i in list_n
        if i in names(df1)
            df[:,Symbol(i)]=df1[:,Symbol(i)]
        end
    end
    #
    (("T" in names(df))&&("Te" in names(df))) ? df.Td=df.T-df.Te : nothing
    (("S" in names(df))&&("Se" in names(df))) ? df.Sd=df.S-df.Se : nothing
    (("Tw" in names(df))&&("Td" in names(df))) ? df.Tnd=df.Td.*sqrt.(df.Tw) : nothing
    (("Sw" in names(df))&&("Sd" in names(df))) ? df.Snd=df.Sd.*sqrt.(df.Sw) : nothing
end

function read_pos_level_for_stat(level; reference=:OCCA1, path=default_path)
  df=CSV.read(joinpath(path,"profile_positions.csv"),DataFrame)
  add_k!(df,level,reference)
  df=trim(df)
  df.pos=MITprofAnalysis.parse_pos.(df.pos)
  df.Td=df.T-df.Te
  df.Sd=df.S-df.Se
  df
end

function read_k(fil,k)
  jldopen(fil,"r") do file
    file["single_stored_object"][:,k]
  end
end

function add_k!(df,k,reference)
  df.T=read_k("jld/T.jld2",k); GC.gc()
  df.Tw=read_k("jld/Tw.jld2",k); GC.gc()
  df.S=read_k("jld/S.jld2",k); GC.gc()
  df.Sw=read_k("jld/Sw.jld2",k); GC.gc()
  if reference!==:OCCA1
    println("jld/THETA_$(reference).jld2")
    df.Te=read_k("jld/THETA_$(reference).jld2",k); GC.gc()
    df.Se=read_k("jld/SALT_$(reference).jld2",k); GC.gc()
  else
    df.Te=read_k("jld/Te.jld2",k); GC.gc()
    df.Se=read_k("jld/Se.jld2",k); GC.gc()
  end
end

"""
    add_climatology_factors!(df)

Add temporal interpolation factors (`rec0,rec1,fac0,fac1`) to DataFrame. 

```
df=CSV.read("csv/profile_positions.csv",DataFrame)
MITprofAnalysis.add_climatology_factors!(df)
```
"""
function add_climatology_factors!(df)
    (df.fac0,df.fac1,df.rec0,df.rec1)=monthly_climatology_factors(df.date)
end

"""
    add_tile!(df,Γ,n)

Add tile index (see `MeshArrays.Tiles`) to `df` that can then be used with e.g. `groupby`.

```
input_file=joinpath("MITprof_input","profile_positions.csv")
df=CSV.read(input_file,DataFrame)
G=GriddedFields.load()
MITprofAnalysis.add_tile!(df,G.Γ,30)
```
"""
function add_tile!(df,Γ,n)
    γ=Γ.XC.grid
    τ=Tiles(γ,n,n)
    𝑻=MeshArray(γ)
    [𝑻[t.face][t.i,t.j].=t.tile for t in τ]
    isa(df.pos,Vector{CartesianIndex{2}}) ? pos=df.pos : pos=parse_pos.(df.pos)
    df[:,Symbol("id$n")]=γ.write(𝑻)[pos];
end

"""
    parse_pos(p)

Parse `String` vector `p` into a vector of `CartesianIndex`.
"""
parse_pos(p) = begin
    ii=parse.(Int,split(split(split(p,"(")[2],")")[1],","))
    CartesianIndex(ii...)
end

"""
    subset(df;lons=(-180.0,180.0),lats=(-90.0,90.0),dates=())

Subset of df that's within specified date and position ranges.    

```
df=CSV.read("csv/profile_positions.csv",DataFrame)
d0=DateTime("2012-06-11T18:50:04")
d1=DateTime("2012-07-11T18:50:04")
df1=MITprofAnalysis.subset(df,dates=(d0,d1))
df2=MITprofAnalysis.subset(df,lons=(0,10),lats=(-5,5),dates=(d0,d1))
```
"""
function subset(df::DataFrame;lons=(-180.0,180.0),lats=(-90.0,90.0),dates=())
    if !isempty(dates)
        df[ (df.lon .> lons[1]) .& (df.lon .<= lons[2]) .&
        (df.lat .> lats[1]) .& (df.lat .<= lats[2]) .&
        (df.date .> dates[1]) .& (df.date .<= dates[2]) ,:]
    else
        df[ (df.lon .> lons[1]) .& (df.lon .<= lons[2]) .&
        (df.lat .> lats[1]) .& (df.lat .<= lats[2]) ,:]
    end
end

#subset(df,lons,lats,dates) = 
#    subset(df, [:lon, :lat, :date] => (lon, lat, date) -> 
#    lon .> lons[1] .&& lon .<= lons[2] .&&
#    lat .> lats[1] .&& lat .<= lats[2] .&& 
#    date .> dates[1] .&& date .<= dates[2])

"""
    trim(df)

Filter out data points that lack T, Te, etc.

```
df=CSV.read("csv/profile_positions.csv",DataFrame)
MITprofAnalysis.add_level!(df,1)
df1=MITprofAnalysis.trim(df)
```
"""
trim(df) = df[
    (!ismissing).(df.T) .& (!ismissing).(df.Te) .& (df.Tw.>0) .&
    (!ismissing).(df.S) .& (!ismissing).(df.Se) .& (df.Sw.>0) .&
    (!isnan).(df.T) .& (!isnan).(df.Te) .&
    (!isnan).(df.S) .& (!isnan).(df.Se) .&
    (df.date .> date_min) .& (df.date .< date_max)
    ,:]

#to restrict analysis to arbitrary time period:
date_min=DateTime(1000,1,1)
date_max=DateTime(3000,1,1)

end #module MITprofAnalysis

module MITprofStat

using NCDatasets, DataFrames, CSV, Statistics, Dates, MeshArrays, Bootstrap
import ArgoData.GriddedFields
import ArgoData.MITprofAnalysis

bootbias(x)= length(x)>=5 ? bias(bootstrap(mean, x, BasicSampling(100)))[1] : NaN
bootstderr(x)= length(x)>=5 ? stderror(bootstrap(mean, x, BasicSampling(100)))[1] : NaN

"""
    stat_df(df::DataFrame,by::Symbol,va::Symbol)

Compute statistics (mean, median, variance) of variable `va` from DataFrame `df` grouped by `by`.
"""
function stat_df(df::DataFrame,by::Symbol,va::Symbol)
    gdf=groupby(df,by)
    sdf=combine(gdf) do df
       (n=size(df,1), mean=mean(df[:,va]) ,  
       bias=bootbias(df[:,va]), err=bootstderr(df[:,va]))
    end

    sdf
end

"""
    stat_grid!(ar::Array,df::DataFrame,va::Symbol,sta::Symbol; func=(x->x))

Compute map `ar` of statistic `sta` of variable `va` from DataFrame `df`. This 
assumes that `df.pos` are indices into Array `ar` and should be used to groupby `df`.
"""
function stat_grid!(ar::Array,df::DataFrame,va::Symbol,sta::Symbol; func=(x->x))
    sdf=stat_df(df,:pos,va)
    ar.=missing
    ar[sdf.pos].=func.(sdf[:,sta])
end

"""
    stat_monthly!(ar::Array,df::DataFrame,va::Symbol,sta::Symbol,y::Int,m::Int,G::NamedTuple;
                    func=(x->x), nmon=1, npoint=1, nobs=1)

Compute map `ar` of statistic `sta` for variable `va` from DataFrame `df` for year `y` and month `m`.
This assumes that `df.pos` are indices into Array `ar` and should be used to groupby `df`.

```
using ArgoData
G=GriddedFields.load();

P=( variable=:Td, level=10, year=2002, month=1, input_path=MITprof.default_path,
    statistic=:median, npoint=9, nmon=3, rng=(-1.0,1.0))

df1=MITprofAnalysis.trim( MITprofAnalysis.read_pos_level(P.level,input_path=P.input_path) )

GriddedFields.update_tile!(G,P.npoint);
ar1=G.array();
MITprofStat.stat_monthly!(ar1,df1,
    P.variable,P.statistic,P.year,P.month,G,nmon=P.nmon,npoint=P.npoint);

MITprofPlots.stat_map(ar1,G,rng=P.rng)
```
"""
function stat_monthly!(ar::Array,df::DataFrame,va::Symbol,sta::Symbol,y::Int,m::Int,G::NamedTuple; 
    func=(x->x), nmon=1, npoint=1, nobs=1)
    if nmon==1
        d0=DateTime(y,m,1)
        m==12 ? d1=DateTime(y+1,mod1(m+1,12),1) : d1=DateTime(y,m+1,1)
    elseif nmon==3
        m==1 ? d0=DateTime(y-1,12,1) : d0=DateTime(y,m-1,1)
        m>=11 ? d1=DateTime(y+1,mod1(m+2,12),1) : d1=DateTime(y,m+2,1)
    elseif nmon==5
        m<=2 ? d0=DateTime(y-1,10+m,1) : d0=DateTime(y,m-2,1)
        m>=10 ? d1=DateTime(y+1,mod1(m+3,12),1) : d1=DateTime(y,m+3,1)
    else
        error("only options are nmon=1, 3, or 5")
    end

    df1=MITprofAnalysis.subset(df,dates=(d0,d1))

    if npoint==1
        sdf1=stat_df(df1,:pos,va)
        sdf1.npoint.=npoint
	if sta!==:none
          for i in 1:size(sdf1,1)
            sdf1[i,:n]>=nobs ? ar[sdf1[i,:pos]]=func(sdf1[i,sta]) : nothing
          end
        end
    else        
        df1[:,:tile]=G.tile[df1.pos]
        sdf1=stat_df(df1,:tile,va)
        sdf1.npoint.=npoint
        if sta!==:none
          for i in 1:size(sdf1,1)
            sdf1[i,:n]>=nobs ? ar[G.tile.==sdf1[i,:tile]].=func(sdf1[i,sta]) : nothing
          end
        end
    end

    return sdf1
end

"""
    stat_monthly!(arr:Array,df::DataFrame,va::Symbol,sta::Symbol,years,G::NamedTuple;
                    func=(x->x), nmon=1, npoint=1, nobs=1)

Compute maps of statistic `sta` for variable `va` from DataFrame `df` for years `years`. 
This assumes that `df.pos` are indices into Array `ar` and should be used to groupby `df`. 
For each year in `years`, twelve fields are computed -- one per month.

```
using ArgoData
G=GriddedFields.load()
df1=MITprofAnalysis.trim( MITprofAnalysis.read_pos_level(1, input_path="MITprof_input") )

years=2004:2007
arr=G.array(12,length(years))
MITprofStat.stat_monthly!(arr,df1,:Td,:median,years,G,nmon=3);
```
"""
function stat_monthly!(arr::Array,df::DataFrame,va::Symbol,sta::Symbol,years,G::NamedTuple; 
                        func=(x->x), nmon=1, npoint=1, nobs=1)
    ny=length(years)
    ar1=G.array()
    sdf1=fill(DataFrame(),12,ny)
    for y in 1:ny, m in 1:12
        m==1 ? println("starting year "*string(years[y])) : nothing
        ar1.=missing
        sdf1[m,y]=stat_monthly!(ar1,df,va,sta,years[y],m,G;
            func=func, nmon=nmon, npoint=npoint, nobs=nobs)
        arr[:,:,m,y].=ar1
    end

    arr[ismissing.(arr)].=NaN
    arr.=Float64.(arr)

    return sdf1
end

"""
    stat_write(file,arr,varia)
"""
function stat_write(file,arr,varia)
    ny=size(arr,4)
    nt=12*ny

    ds = NCDataset(file,"c")
    defDim(ds,"i",90)
    defDim(ds,"j",1170)
    defDim(ds,"t",nt)
    v = defVar(ds,"δ",Float32,("i","j","t"))
    v[:,:,:] = reshape(arr,90,1170,nt)
    if varia==:Td
        ds.attrib["title"] = "Temperature Anomaly"
        v.attrib["units"] = "degree Celsius"
    elseif varia==:Sd
        ds.attrib["title"] = "Salinity Anomaly"
        v.attrib["units"] = "psu"
    else
        error("unknown variable")
    end
    close(ds)
end

function stat_write(file,sdf::Matrix{DataFrame})
    ny=size(sdf,2)
    nt=12*ny
    df=DataFrame()
    for y in 1:ny
    for m in 1:12
       tmp=sdf[m,y]
       tmp.y.=y
       tmp.m.=m
       append!(df,tmp)
    end
    end
    CSV.write(file,df)
end

"""
    stat_driver(;varia=:Td,level=1,years=2004:2022,output_to_file=false,
    nmon=1, npoint=1, sta=:none, nobs=1, input_path="", output_path="")

```
P=( variable=:Td, level=10, years=2004:2007, 
    statistic=:median, npoint=3, nmon=3, 
    input_path="MITprof_input",
    output_path=joinpath(tempdir(),"stat_output"),
    output_to_file=false
    )

MITprofStat.stat_driver(input_path=P.input_path,varia=P.variable,
        level=P.level,years=P.years,
        nmon=P.nmon, npoint=P.npoint, sta=P.statistic, 
        output_path=P.output_path, output_to_file=P.output_to_file)
```    
"""
function stat_driver(;varia=:Td,level=1,years=2004:2022,output_to_file=false,
    nmon=1, npoint=1, sta=:none, nobs=1, reference=:OCCA1,output_path="stat_output")
   
    output_to_nc=false
    output_to_csv=true

    G=GriddedFields.load()
    df1=MITprofAnalysis.read_pos_level_for_stat(level,reference=reference)

    ny=length(years)
    arr=G.array(12,ny)

    npoint>1 ? GriddedFields.update_tile!(G,npoint) : nothing

    sdf=stat_monthly!(arr,df1,varia,sta,years,G,nmon=nmon,npoint=npoint,nobs=nobs)

    return if output_to_file
      if output_to_nc
        suf=string(varia)
        ext=string(level)*"_np$(npoint)nm$(nmon)no$(nobs).nc"
        level<10 ? output_file=suf*"_k0"*ext : output_file=suf*"_k"*ext

        output_file=joinpath(output_path,output_file)
        !isdir(dirname(output_file)) ? mkdir(dirname(output_file)) : nothing
        isfile(output_file) ? rm(output_file) : nothing

        stat_write(output_file,arr,varia)
      end
      if output_to_csv
        suf=string(varia)
        ext=string(level)*"_np$(npoint)nm$(nmon).csv"
        level<10 ? output_file=suf*"_k0"*ext : output_file=suf*"_k"*ext

        output_file=joinpath(output_path,output_file)
        !isdir(dirname(output_file)) ? mkdir(dirname(output_file)) : nothing
        isfile(output_file) ? rm(output_file) : nothing

        stat_write(output_file,sdf)
      end
    else
        arr
    end
end

function stat_combine(G,level=5,varia=:Td, rec=120;
    path_input="stat_output",stat_config="",
    func=(x->x))

    ar2=G.array(); ar2.=0.0
    ar2w=G.array(); ar2w.=0.0
    ar3=G.array(); ar3.=0.0
    ar3w=G.array(); ar3w.=0.0
    level<10 ? lev="0"*string(level) : lev=string(level)

    if isempty(stat_config)
      list=MITprofStat.list_stat_configurations()
    elseif isa(stat_config,String)
      list=CSV.read(stat_config,DataFrame)
    elseif isa(stat_config,DataFrame)
      list=stat_config
    end

    nsize=size(list,1)
    for i in 1:nsize
        npoint=list.npoint[i]
        nmon=list.nmon[i]
        nobs=list.nobs[i]

        fil=joinpath(path_input,"$(varia)_k"*lev*"_np$(npoint)nm$(nmon).csv")
        ##
        sdf1=CSV.read(fil,DataFrame)
        y=Int(ceil(rec/12))
        m=mod1(rec-12*Int(floor(rec/12)),12)
        sdf1=sdf1[(sdf1.m.==m).&&(sdf1.y.==y),:]
        ##
        sta=:mean
        ar3.=NaN
        ar3w.=NaN
        npoint>1 ? GriddedFields.update_tile!(G,npoint) : nothing
        npoint==1 ? sdf1.pos.=MITprofAnalysis.parse_pos.(sdf1.pos) : nothing
        if npoint==1
          for i in 1:size(sdf1,1)
            sdf1[i,:n]>=nobs ? ar3[sdf1[i,:pos]]=func(sdf1[i,sta]) : nothing
            sdf1[i,:n]>=nobs ? ar3w[sdf1[i,:pos]]=1 : nothing
            #sdf1[i,:n]>=nobs ? ar3w[sdf1[i,:pos]]=1/(sdf1[i,:err]^2) : nothing
            #sdf1[i,:n]>=nobs ? ar3w[sdf1[i,:pos]]=1/(sdf1[i,:err]^2)/npoint : nothing
	  end
        else
          for i in 1:size(sdf1,1)
            sdf1[i,:n]>=nobs ? ar3[G.tile.==sdf1[i,:tile]].=func(sdf1[i,sta]) : nothing
            sdf1[i,:n]>=nobs ? ar3w[G.tile.==sdf1[i,:tile]].=1 : nothing
            #sdf1[i,:n]>=nobs ? ar3w[G.tile.==sdf1[i,:tile]].=1/(sdf1[i,:err]^2) : nothing
            #sdf1[i,:n]>=nobs ? ar3w[G.tile.==sdf1[i,:tile]].=1/(sdf1[i,:err]^2)/npoint : nothing
          end
        end

        ii=findall((!isnan).(ar3))
        #w=list.nobs[i]/(list.npoint[i]^2)
        ar2[ii].+=ar3w[ii].*ar3[ii]
        ar2w[ii].+=ar3w[ii]
    end
    γ=G.Γ.XC.grid
    #ar2=ar2./ar2w
    #ar2=ar2./nsize
    ar2=ar2./max.(ar2w,nsize/2)
    ar2[findall(isnan.(ar2))].=0

    z_std=Float64.([[5:10:185]... ; [200:20:500]... ; [550:50:1000]...; [1100:100:6000]...])
    z_model=-G.Γ.RC
    kk= ( z_std[level]<=z_model[1] ? 1 : maximum(findall(z_model.<z_std[level])) )

    ar2.*γ.write(G.msk[:,kk])
end


"""
    list_stat_configurations()

List of confiburations (each one a choice of nmon,npoint,nobs) to be used in `stat_combine`.
"""
function list_stat_configurations()
    list=DataFrame(:nmon => [],:npoint => [],:nobs => [])
    #
    push!(list,[5 30 50])
    push!(list,[5 18 40])
    push!(list,[5 10 30])
    push!(list,[5 5 20])
    push!(list,[5 3 9])
    push!(list,[5 2 6])
    push!(list,[5 1 3])
    list
end

end #module MITprofStat
