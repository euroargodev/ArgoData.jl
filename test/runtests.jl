
using ArgoData, MeshArrays, Test, Suppressor
using Climatology, MITgcm, Dates, CairoMakie

ENV["DATADEPS_ALWAYS_ACCEPT"]=true
clim_path=Climatology.MITPROFclim_download()

run_argopy=true
#Sys.ARCH==:aarch64 ? run_argopy=false : nothing

if run_argopy
  using PythonCall, CondaPkg
  @testset "argopy" begin
    @suppress ArgoData.conda(:argopy)
    println(CondaPkg.status())
    argopy=ArgoData.pyimport(:argopy)
    println(argopy.status())

    ds_fetcher=argopy.DataFetcher().float(pylist([6902746, 6902747, 6902757, 6902766]))
    ds_points = ds_fetcher.to_xarray()
    ds_profiles = ds_points.argo.point2profile()

    @test true
  end
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

    output_file=joinpath(dirname(input_file),"13857_MITprof.nc")
    isfile(output_file) ? rm(output_file) : nothing
    output_file=MITprof.format(gridded_fields,input_file)

    @test isfile(output_file)
	
    mp=MITprofStandard(output_file)
    MITprof.write(output_file*".tmp1",mp)
    MITprof.write(output_file*".tmp2",[mp,mp])
    show(mp)

    @test isa(mp,MITprofStandard)

    pth=dirname(output_file)
    fil=basename(output_file)
    nt,np,nz,cost=MITprofAnalysis.cost_functions(pth,"prof_T",fil)
    @test isapprox(cost[1],1.495831407933)

    ##

    Γ=GridLoad(ID=:LLC90,option=:light)
    pth=MITprof.default_path
    files=MITprof.download(ids=5,path=pth) #ids=5 for 2002
    df=MITprofAnalysis.csv_of_positions(pth,Γ,files[1])
    csv_file=joinpath(pth,"profile_positions.csv")
    MITprof.CSV.write(csv_file, df)
    list_v=("prof_T","prof_Testim","prof_Tweight","prof_S","prof_Sestim","prof_Sweight")
    for v in list_v
      tmp=MITprofAnalysis.csv_of_variables(v,csv=csv_file,path=pth)
      temp_file=joinpath(pth,"$(v).csv")
      MITprofAnalysis.CSV.write(temp_file,MITprofAnalysis.DataFrame(tmp,:auto))      
    end
    MITprofAnalysis.csv_of_levels(10)
    @test isfile(joinpath(pth,"k10.csv"))

    df=MITprofAnalysis.read_pos_level(10)

    tmp=MITprofAnalysis.prepare_interpolation(Γ,df.lon,df.lat)
    np=size(tmp[1],1)
    co=[(f=tmp[1][ii,:],i=tmp[2][ii,:],j=tmp[3][ii,:],w=tmp[4][ii,:]) for ii in 1:np]
    fil=joinpath(pth,"profile_coeffs.jld2")
    MITprofAnalysis.save_object(fil,co)

    MITprofAnalysis.add_coeffs!(df)
    df=MITprofAnalysis.CSV.read(joinpath(pth,"profile_positions.csv"),MITprofAnalysis.DataFrame)
    MITprofAnalysis.add_level!(df,10)
    @test "T" in names(df)
    
    #more 

    df=MITprofAnalysis.trim(df)
    df.pos=MITprofAnalysis.parse_pos.(df.pos)
    df.Td=df.T-df.Te
    df.Sd=df.S-df.Se
    MITprofAnalysis.add_climatology_factors!(df)
    MITprofAnalysis.add_tile!(df,Γ,30)  
    d0=DateTime("2002-01-01T00:00:00")
    d1=DateTime("2002-02-01T00:00:00")
    df1=MITprofAnalysis.subset(df,dates=(d0,d1))
    df2=MITprofAnalysis.subset(df,lons=(-180,0),lats=(20,50),dates=(d0,d1))
    @test !isempty(df2)

    G=GriddedFields.load()
    P=( variable=:Td, level=10, year=2002, month=1, input_path=MITprof.default_path,
        statistic=:mean, npoint=9, nmon=3, rng=(-1.0,1.0))
    df1=MITprofAnalysis.trim( MITprofAnalysis.read_pos_level(P.level,path=P.input_path) )
    GriddedFields.update_tile!(G,P.npoint)
    ar1=G.array()
    sta1=MITprofStat.stat_monthly!(ar1,df1,P.variable,P.statistic,P.year,P.month,G,nmon=P.nmon)
    @test !isempty(sta1)

    ##

    file,list=MITprofStat.geostat_config(output_path=MITprof.default_path,years=2002:2002)

    for nmap in 1:size(list,1)
      MITprofStat.stat_driver(; varia=:Td, level=10,
      nmap=nmap, sta=:mean, output_path=MITprof.default_path, output_to_file=true)
    end

    G=GriddedFields.load()
    x=MITprofStat.stat_combine(G,10,:Td, 12,input_path=MITprof.default_path)
    @test !isempty(x)

    ##
    
    dates=[ArgoTools.DateTime(2011,1,10) ArgoTools.DateTime(2011,1,20)]
    (fac0,fac1,rec0,rec1)=GriddedFields.monthly_climatology_factors(dates)
    (fac0,fac1,rec0,rec1)=GriddedFields.monthly_climatology_factors(dates[1])
    @test isapprox(fac0,0.20967741935483875)
    @test rec0==12

    ##

    ArgoFiles.scan_txt("ar_index_global_prof.txt",do_write=true)
    @test isfile(joinpath(tempdir(),"ar_index_global_prof.csv"))

    ArgoFiles.scan_txt("argo_synthetic-profile_index.txt",do_write=true)
    @test isfile(joinpath(tempdir(),"argo_synthetic-profile_index.csv"))

    b=read(OneArgoFloat(),wmo=2900668)
    @test isa(b,OneArgoFloat)

    f1=plot(b,option=:samples)
    f2=plot(b,option=:TS)
    f3=plot(b,option=:standard)
    @test isa(f3,Figure)

end

