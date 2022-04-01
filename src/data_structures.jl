
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
