using ArgoData
using Test

@testset "ArgoData.jl" begin

    files_list=GDAC.files_list()
    GDAC.download_file(files_list[10000,:])

    ftp="ftp://usgodae.org/pub/outgoing/argo/dac/"
    fil=GDAC.download_file(files_list[10000,:],"meta",ftp)

    @test isfile(fil)

    tmp=GDAC.grey_list()
    @test isa(tmp,GDAC.DataFrame)

    fil=joinpath(dirname(pathof(ArgoData)),"..","examples","ArgoToMITprof.jl")
    include(fil)

    @test isa(output_file,String)

    mp=MITprofStandard(output_file)

    MITprof.write(output_file*".tmp1",mp);
    MITprof.write(output_file*".tmp2",[mp,mp]);

    @test isa(mp,MITprofStandard)
end
