using ArgoData
using Test

@testset "ArgoData.jl" begin

    list_files=GDAC.Argo_float_files()
    GDAC.Argo_float_download(list_files,10000)

    ftp="ftp://usgodae.org/pub/outgoing/argo/dac/"
    fil=GDAC.Argo_float_download(list_files,10000,"meta",ftp)

    @test isfile(fil)

    tmp=GDAC.greylist()
    @test isa(tmp,GDAC.DataFrame)

    fil=joinpath(dirname(pathof(ArgoData)),"..","examples","ArgoToMITprof_full.jl")
    include(fil)

    @test isa(output_file,String)
end
