using NCDatasets

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
    haskey(ds,"prof_descr") ? ID=ds["prof_descr"] : ID="0000"
    MITprofStandard(fil,
        ds["prof_lon"],ds["prof_lat"],ds["prof_date"],ds["prof_depth"],
        fill(ID,size(ds["prof_lon"])),
        ds["prof_T"],ds["prof_Testim"],ds["prof_Tweight"],
        ds["prof_S"],ds["prof_Sestim"],ds["prof_Sweight"]
        )
end

function Base.show(io::IO, mp::MITprofStandard) where {T}
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

