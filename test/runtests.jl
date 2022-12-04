using ArgoData, MeshArrays, Test

@testset "ArgoData.jl" begin

    files_list=GDAC.files_list()
    GDAC.download_file(files_list[10000,:])

    ftp="ftp://usgodae.org/pub/outgoing/argo/dac/"
    fil=GDAC.download_file(files_list[10000,:],"meta",ftp)

    @test isfile(fil)

    tmp=GDAC.grey_list()
    @test isa(tmp,GDAC.DataFrame)

    gridded_fields=GriddedFields.load()
    input_file=GDAC.download_file("aoml",13857)    
    output_file=MITprof.format(gridded_fields,input_file)

    @test isfile(output_file)
	
    mp=MITprofStandard(output_file)
    MITprof.write(output_file*".tmp1",mp);
    MITprof.write(output_file*".tmp2",[mp,mp]);

    @test isa(mp,MITprofStandard)

    pth=dirname(output_file)
    fil=basename(output_file)
    nt,np,nz,cost=AnalysisMethods.cost_functions(pth,"prof_T",fil)
    @test isapprox(cost[1],1.495831407933)

    γ=GridSpec("LatLonCap",MeshArrays.GRID_LLC90)
    Γ=GridLoad(γ)
    df=AnalysisMethods.profile_positions(pth,Γ,fil)
    @test isapprox(maximum(df.lat),6.859)

end
