using ArgoData, MeshArrays, Test

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

    pth=dirname(output_file)
    nt,np,nz,cost=MITprof.cost_functions(pth,"prof_S")
    @test isapprox(cost[1],1.365848840650727)

    γ=GridSpec("LatLonCap",MeshArrays.GRID_LLC90)
    Γ=GridLoad(γ)
    df=MITprof.profile_positions(pth,Γ)
    @test isapprox(maximum(df.lat),-39.894)

end
