using ArgoData
using Test

@testset "ArgoData.jl" begin

    list_files=GDAC.Argo_float_files()
    GDAC.Argo_float_download(list_files,10000)

    ftp="ftp://usgodae.org/pub/outgoing/argo/dac/"
    fil=GDAC.Argo_float_download(list_files,10000,"meta",ftp)

    @test isfile(fil)

    include("../examples/ArgoToMITprof_full.jl")

    @test isa(profiles,Vector{ProfileNative})
end
