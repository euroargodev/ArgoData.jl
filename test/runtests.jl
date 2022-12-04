using ArgoData, MeshArrays, Test

@testset "ArgoData.jl" begin

    files_list=GDAC.files_list()
    GDAC.download_file(files_list[10000,:])

    ftp="ftp://usgodae.org/pub/outgoing/argo/dac/"
    fil=GDAC.download_file(files_list[10000,:],"meta",ftp)

    @test isfile(fil)

    tmp=GDAC.grey_list()
    @test isa(tmp,GDAC.DataFrame)

 ##
    wmo=6900900
    url0="https://data-argo.ifremer.fr/dac/coriolis/"
	input_url=url0*"/$(wmo)/$(wmo)_prof.nc"
	input_file=joinpath(tempdir(),"$(wmo)_prof.nc")
	output_file=joinpath(tempdir(),"ncdev","$(wmo)_MITprof.nc")
	
	!isfile(input_file) ? fil=Downloads.download(input_url,input_file) : nothing
	!isdir(dirname(output_file)) ? mkdir(dirname(output_file)) : nothing
	isfile(output_file) ? rm(output_file) : nothing
	
    mp=MITprofStandard(output_file)
    MITprof.write(output_file*".tmp1",mp);
    MITprof.write(output_file*".tmp2",[mp,mp]);

    @test isa(mp,MITprofStandard)

    pth=dirname(output_file)
    nt,np,nz,cost=AnalysisMethods.cost_functions(pth,"prof_S")
    @test isapprox(cost[1],1.365848840650727)

    γ=GridSpec("LatLonCap",MeshArrays.GRID_LLC90)
    Γ=GridLoad(γ)
    df=AnalysisMethods.profile_positions(pth,Γ)
    @test isapprox(maximum(df.lat),-39.894)

end
