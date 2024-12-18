using NCDatasets
using Dates

"""
   ProfileNative

Container for a multivariate profile read from a GDAC Argo file.

- 1D arrays: lon,lat,date,ymd,hms,pnum_txt,direc,DATA_MODE,isBAD
- 2D arrays: T,S,pressure,depth,T_ERR,SERR
"""
struct ProfileNative
    lon
    lat
    date
    ymd
    hms
    T
    S
    pressure
    depth
    T_ERR
    S_ERR
    pnum_txt
    direc
    DATA_MODE
    isBAD
end

"""
   ProfileNative

Container for a multivariate profile in MITprof format.

- 2D arrays: T,S,Testim,Sestim,Tweight,Sweight,Ttest,Stest,T_ERR,SERR
"""
struct ProfileStandard
    T
    Testim
    Tweight
    Ttest
    T_ERR
    S
    Sestim
    Sweight
    Stest
    S_ERR
end

ProfileStandard(nz::Int) = ProfileStandard(
    Array{Union{Float64,Missing},1}(undef,nz),
    Array{Union{Float64,Missing},1}(undef,nz),
    Array{Union{Float64,Missing},1}(undef,nz),
    Array{Union{Float64,Missing},1}(undef,nz),
    Array{Union{Float64,Missing},1}(undef,nz),
    Array{Union{Float64,Missing},1}(undef,nz),
    Array{Union{Float64,Missing},1}(undef,nz),
    Array{Union{Float64,Missing},1}(undef,nz),
    Array{Union{Float64,Missing},1}(undef,nz),
    Array{Union{Float64,Missing},1}(undef,nz)
)


"""
   MITprofStandard

Container for a MITprof format file data.

- filename : file name
- 1D arrays: lon,lat,date,depth,ID
- 2D arrays: T,S,Te,Se,Tw,Sw
"""
struct MITprofStandard
    filename
    lon
    lat
    date
    depth
    ID
    #
    T
    Te
    Tw
    S
    Se
    Sw
end

"""
   MITprofStandard

Create a `MITprofStandard` view of an MITprof file.

```
fil="nc/5903955_MITprof.nc"
mp=MITprof.MITprofStandard(fil)
```
"""
function MITprofStandard(fil::String)
    ds=Dataset(fil)
    np=size(ds["prof_lon"])
    da=ds["prof_date"]

    if haskey(ds,"prof_descr")
        ID=ds["prof_descr"][:,:]
        ID=[parse(Int,prod(ID[:,a])) for a in 1:size(ID,2)]
    else
        ID=zeros(np)
    end
    Te=(haskey(ds,"prof_Testim") ? "prof_Testim" : "prof_TeccoV4R2clim")
    Se=(haskey(ds,"prof_Sestim") ? "prof_Sestim" : "prof_SeccoV4R2clim")
    MITprofStandard(fil,
        ds["prof_lon"],ds["prof_lat"],da,ds["prof_depth"],ID,
        ds["prof_T"],ds[Te],ds["prof_Tweight"],
        ds["prof_S"],ds[Se],ds["prof_Sweight"]
        )
end

toDateTime(dt::NCDatasets.CFVariable)=Dates.julian2datetime.(dt.+Dates.datetime2julian(DateTime("000-01-01", "yyyy-mm-dd")))

function Base.show(io::IO, mp::MITprofStandard)
    printstyled(io, "File name is ",color=:normal)
    printstyled(io, "$(basename(mp.filename)) \n",color=:blue)
    printstyled(io, "List of variables : \n",color=:normal)
    #
    printstyled(io, "  lon   is ",color=:normal)
    printstyled(io, "$(size(mp.lon)) \n",color=:blue)
    printstyled(io, "  lat   is ",color=:normal)
    printstyled(io, "$(size(mp.lat)) \n",color=:blue)
    printstyled(io, "  date  is ",color=:normal)
    printstyled(io, "$(size(mp.date)) \n",color=:blue)
    printstyled(io, "  depth is ",color=:normal)
    printstyled(io, "$(size(mp.depth)) \n",color=:blue)
    printstyled(io, "  ID    is ",color=:normal)
    printstyled(io, "$(size(mp.ID)) \n",color=:blue)
    #
    printstyled(io, "  T     is ",color=:normal)
    printstyled(io, "$(size(mp.T)) \n",color=:blue)
    printstyled(io, "  Te    is ",color=:normal)
    printstyled(io, "$(size(mp.Te)) \n",color=:blue)
    printstyled(io, "  Tw    is ",color=:normal)
    printstyled(io, "$(size(mp.Tw)) \n",color=:blue)
    printstyled(io, "  S     is ",color=:normal)
    printstyled(io, "$(size(mp.S)) \n",color=:blue)
    printstyled(io, "  Se    is ",color=:normal)
    printstyled(io, "$(size(mp.Se)) \n",color=:blue)
    printstyled(io, "  Sw    is ",color=:normal)
    printstyled(io, "$(size(mp.Sw))",color=:blue)
    #
    return
end

##

struct OneArgoFloat
    ID::Int64
    data::NamedTuple
end

OneArgoFloat() = OneArgoFloat(0,NamedTuple())

import Base: read

"""
    read(x::OneArgoFloat;wmo=2900668)

Note: the first time this method is used, it calls `ArgoData.GDAC.files_list()` 
to get the list of Argo floats from server, and save it to a temporary file.

```
using OceanRobots, ArgoData
read(OneArgoFloat(),wmo=2900668)
```
"""
function read(x::OneArgoFloat;wmo=2900668,files_list="")
    isempty(files_list) ? nothing : @warn "specifycing files_list here is deprecated"
    lst=try
        ArgoFiles.list_floats()
    catch
        println("downloading floats list via ArgoData.jl")
        ArgoFiles.list_floats(list=GDAC.files_list())
    end
    fil=ArgoFiles.download(lst,wmo)
    arr=ArgoFiles.readfile(fil)
    OneArgoFloat(wmo,arr)
end