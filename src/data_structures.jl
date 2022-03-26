
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

struct ProfileStandard
    T
    Testim
    Tweight
    T_ERR
    S
    Sestim
    Sweight
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
    Array{Union{Float64,Missing},1}(undef,nz)
)
