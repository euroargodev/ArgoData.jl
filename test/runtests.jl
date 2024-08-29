using ArgoData, MeshArrays, Test
using Climatology, MITgcm

ENV["DATADEPS_ALWAYS_ACCEPT"]=true
Climatology.MITPROFclim_download()

@testset "argopy" begin

run_argopy=true
#Sys.ARCH==:aarch64 ? run_argopy=false : nothing

if run_argopy
  method="external"
  if method=="external"
    tmpfile=joinpath(tempdir(),"pythonpath.txt")
    run(pipeline(`which python`,tmpfile)) 
    ENV["PYTHON"]=readline(tmpfile)
  else #internal python path
    ENV["PYTHON"]=""
  end
  using Pkg; Pkg.build("PyCall")

  using PyCall, Conda
  ArgoData.conda(:argopy)
  argopy=ArgoData.pyimport(:argopy)
end

ds_fetcher=argopy.DataFetcher().float([6902746, 6902747, 6902757, 6902766])
ds_points = ds_fetcher.to_xarray()
ds_profiles = ds_points.argo.point2profile()

@test true

end

@testset "ArgoData.jl" begin

    files_list=GDAC.files_list()
    GDAC.download_file(files_list[10000,:])

    ftp="ftp://ftp.ifremer.fr/ifremer/argo/dac/"
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
    show(mp)

    @test isa(mp,MITprofStandard)

    pth=dirname(output_file)
    fil=basename(output_file)
    nt,np,nz,cost=MITprofAnalysis.cost_functions(pth,"prof_T",fil)
    @test isapprox(cost[1],1.495831407933)

    γ=GridSpec("LatLonCap",MeshArrays.GRID_LLC90)
    Γ=GridLoad(γ)
    df=MITprofAnalysis.csv_of_positions(pth,Γ,fil)
    @test isapprox(maximum(df.lat),6.859)

    dates=[ArgoTools.DateTime(2011,1,10) ArgoTools.DateTime(2011,1,20)]
    (fac0,fac1,rec0,rec1)=ArgoTools.monthly_climatology_factors(dates)
    (fac0,fac1,rec0,rec1)=ArgoTools.monthly_climatology_factors(dates[1])
    @test isapprox(fac0,0.20967741935483875)
    @test rec0==12

end
