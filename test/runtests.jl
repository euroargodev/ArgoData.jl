using ArgoData
using Test

@testset "ArgoData.jl" begin

    files_list=GDAC.Argo_files_list()
    GDAC.Argo_float_download(files_list[10000,:])

    ftp="ftp://usgodae.org/pub/outgoing/argo/dac/"
    fil=GDAC.Argo_float_download(files_list[10000,:],"meta",ftp)

    @test isfile(fil)

    tmp=GDAC.grey_list()
    @test isa(tmp,GDAC.DataFrame)

    fil=joinpath(dirname(pathof(ArgoData)),"..","examples","ArgoToMITprof.jl")
    include(fil)

    @test isa(output_file,String)
end
