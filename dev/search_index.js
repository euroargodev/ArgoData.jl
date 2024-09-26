var documenterSearchIndex = {"docs":
[{"location":"examples/","page":"Examples","title":"Examples","text":"The One Argo Float notebook demonstrates various functionalities of the ArgoData.jl package, which are further documented below.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"👉 One Argo Float 👈 (code)","category":"page"},{"location":"examples/#Download-From-Argo-Data-Center","page":"Examples","title":"Download From Argo Data Center","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"Downloading and accessing an Argo file (wmo=13857 from folder=\"aoml\") is done like this.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using ArgoData\ninput_file=GDAC.download_file(\"aoml\",13857)","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"You can then simply access the file content using NCDatasets.jl.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using NCDatasets\nds=Dataset(input_file)\nkeys(ds)","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"A list of all folder,wmo pairs can be obtained using files_list=GDAC.files_list(). And a method to download files in bulk & parallel is presented in examples/Argo_distributed_download.jl.","category":"page"},{"location":"examples/#Argo-on-Standard-Depth-Levels","page":"Examples","title":"Argo on Standard Depth Levels","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"A more complete version of the workflow presented below is in this notebook:","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"👉 from Argo to MITprof 👈 (code)","category":"page"},{"location":"examples/#The-MITprof-Format","page":"Examples","title":"The MITprof Format","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"The MITprof format is a simple to use version of Argo where profiles have been converted to potential temperature and interpolated to standard depth levels.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"Turning an Argo file (input_file) into an MITprof file (output_file) proceeds as follows. ","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"gridded fields are retrieved. These climatologies enable quality control of the data and scientific applications in step 2.\nread the Argo file and process it. The observed profiles are interpolated to standard depth levels, converted to potential temperature, quality controled, and appended climatological profiles. ","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"note: Note\nFor more detail on the use of climatologies, representation error estimation, and model-data cost functions, see Forget et al 2015, Forget 2011, Forget and Wunsch 2007.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"output_file=input_file[1:end-7]*\"MITprof.nc\" # hide\nisfile(output_file) ? mv(output_file,tempname()) : nothing # hide\ngridded_fields=GriddedFields.load()\noutput_file=MITprof.format(gridded_fields,input_file)\nds2=Dataset(output_file)\nkeys(ds2)","category":"page"},{"location":"examples/#Associated-Data-Structure","page":"Examples","title":"Associated Data Structure","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"The generated file can be accessed normally as a NetCDF file (e.g., Dataset(output_file)) or using the convenient MITprofStandard data structure.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"mp=MITprofStandard(output_file)","category":"page"},{"location":"examples/#Sample-MITprof-Files","page":"Examples","title":"Sample MITprof Files","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"The full set of MITprof profiles processed in 2023 from the Argo data base is available in this Dataverse. This dataset can be explored and retrieved using Dataverse.jl.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using Dataverse\ndoi=\"https://doi.org/10.7910/DVN/7HLV09\"\nlst=Dataverse.file_list(doi)\nDataverse.file_download(lst,lst.filename[2],tempdir())","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"Another example is the original collection of MITprof files from Forget, et al 2015 is archived in this Dataverse. This contains an earlier versio of Argo along with complementary datasets.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using Dataverse\ndoi=\"https://doi.org/10.7910/DVN/EE3C40\"\nlst=Dataverse.file_list(doi)","category":"page"},{"location":"examples/#Argo-via-Python-API","page":"Examples","title":"Argo via Python API","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"The python library called argopy provides more ways to access, manipulate, and visualize Argo data. ","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using ArgoData, CondaPkg, PythonCall\nArgoData.conda(:argopy)\nargopy=ArgoData.pyimport(:argopy)\nprintln(argopy.status())","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"ds_fetcher=argopy.DataFetcher().float(pylist([6902746, 6902747, 6902757, 6902766]))\nds_points = ds_fetcher.to_xarray()","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"👉 Notebook 👈 (code)","category":"page"},{"location":"Functionalities/","page":"Reference","title":"Reference","text":"Content of this section:","category":"page"},{"location":"Functionalities/","page":"Reference","title":"Reference","text":"Data Structures\nModules (1): GDAC, MITprof, GriddedFields\nModules (2): MITprofAnalysis, MITprofStat","category":"page"},{"location":"Functionalities/#Data-Structures","page":"Reference","title":"Data Structures","text":"","category":"section"},{"location":"Functionalities/","page":"Reference","title":"Reference","text":"ProfileNative\nProfileStandard\nMITprofStandard","category":"page"},{"location":"Functionalities/#ArgoData.ProfileNative","page":"Reference","title":"ArgoData.ProfileNative","text":"ProfileNative\n\nContainer for a multivariate profile read from a GDAC Argo file.\n\n1D arrays: lon,lat,date,ymd,hms,pnumtxt,direc,DATAMODE,isBAD\n2D arrays: T,S,pressure,depth,T_ERR,SERR\n\n\n\n\n\n","category":"type"},{"location":"Functionalities/#ArgoData.ProfileStandard","page":"Reference","title":"ArgoData.ProfileStandard","text":"ProfileNative\n\nContainer for a multivariate profile in MITprof format.\n\n2D arrays: T,S,Testim,Sestim,Tweight,Sweight,Ttest,Stest,T_ERR,SERR\n\n\n\n\n\n","category":"type"},{"location":"Functionalities/#ArgoData.MITprofStandard","page":"Reference","title":"ArgoData.MITprofStandard","text":"MITprofStandard\n\nContainer for a MITprof format file data.\n\nfilename : file name\n1D arrays: lon,lat,date,depth,ID\n2D arrays: T,S,Te,Se,Tw,Sw\n\n\n\n\n\n","category":"type"},{"location":"Functionalities/#Module:-GDAC","page":"Reference","title":"Module: GDAC","text":"","category":"section"},{"location":"Functionalities/","page":"Reference","title":"Reference","text":"Modules = [GDAC]\nOrder   = [:type,:function]","category":"page"},{"location":"Functionalities/#ArgoData.GDAC.download_file","page":"Reference","title":"ArgoData.GDAC.download_file","text":"download_file(file::DataFrameRow,suff=\"prof\",ftp=missing)\n\nGet folder and wmo from data frame row and them call download_file.\n\nusing ArgoData\nfiles_list=GDAC.files_list()\nfile=GDAC.download_file(files_list[10000,:])\n\n\n\n\n\n","category":"function"},{"location":"Functionalities/#ArgoData.GDAC.download_file-2","page":"Reference","title":"ArgoData.GDAC.download_file","text":"download_file(folder::String,wmo::Int,suff=\"prof\",ftp=missing)\n\nDownload Argo file from the GDAC server (<ftp://ftp.ifremer.fr/ifremer/argo/dac/> by default) to a temporary folder (joinpath(tempdir(),\"Argo_DAC_files\"))\n\nThe file name is given by folder and wmo. For example, 13857_prof.nc for wmo=13857 is from the aoml folder. \n\nThe default for suff is \"prof\" which means we'll download the file that contains the profile data.  Other possible choices are \"meta\", \"Rtraj\", \"tech\". \n\nIf the ftp argument is omitted or isa(ftp,String) then Downloads.download is used.  If, alternatively, isa(ftp,FTP) then FTPClient.download is used.\n\nExample :\n\nusing ArgoData\nGDAC.download_file(\"aoml\",13857)\n\n#or:\nftp=\"ftp://usgodae.org/pub/outgoing/argo/dac/\"\nGDAC.download_file(\"aoml\",13857,\"meta\",ftp)\n\n\n\n\n\n","category":"function"},{"location":"Functionalities/#ArgoData.GDAC.files_list-Tuple{String}","page":"Reference","title":"ArgoData.GDAC.files_list","text":"files_list(fil::String)\n\nGet list of Argo float files from csv file with columns two columns – folder and wmo.\n\nusing ArgoData\nfil=\"https://raw.githubusercontent.com/euroargodev/ArgoData.jl/gh-pages/dev/Argo_float_files.csv\"\nfiles_list=GDAC.files_list(fil)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.GDAC.files_list-Tuple{}","page":"Reference","title":"ArgoData.GDAC.files_list","text":"files_list()\n\nGet list of Argo float files from Ifremer GDAC server      ftp://ftp.ifremer.fr/ifremer/argo/dac/\n\nusing ArgoData\nfiles_list=GDAC.files_list()\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.GDAC.grey_list-Tuple{String}","page":"Reference","title":"ArgoData.GDAC.grey_list","text":"grey_list(fil::String)\n\nRead \"ar_greylist.txt\" file into a DataFrame.\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.GDAC.grey_list-Tuple{}","page":"Reference","title":"ArgoData.GDAC.grey_list","text":"grey_list()\n\nDownload \"ar_greylist.txt\" from GDAC and read file into a DataFrame.\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#Module:-MITprof","page":"Reference","title":"Module: MITprof","text":"","category":"section"},{"location":"Functionalities/","page":"Reference","title":"Reference","text":"Modules = [MITprof]\nOrder   = [:type,:function]","category":"page"},{"location":"Functionalities/#ArgoData.MITprof.format","page":"Reference","title":"ArgoData.MITprof.format","text":"format(meta,gridded_fields,input_file,output_file=\"\")\n\nFrom Argo file name as input : read input file content, process into the MITprof format, and write to MITprof file.\n\nMITprof.format(meta,gridded_fields,input_file)\n\n\n\n\n\n","category":"function"},{"location":"Functionalities/#ArgoData.MITprof.format-Tuple{Any, Any}","page":"Reference","title":"ArgoData.MITprof.format","text":"format(gridded_fields,input_file)\n\nFrom Argo file name as input : read input file content, process into the MITprof format, and write to MITprof file.\n\nMITprof.format(gridded_fields,input_file)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprof.format_loop-Tuple{Any, Any, Any}","page":"Reference","title":"ArgoData.MITprof.format_loop","text":"format_loop(II)\n\nLoop over files and call format.\n\ngridded_fields=GriddedFields.load()\nfil=joinpath(tempdir(),\"Argo_MITprof_files\",\"input\",\"Argo_float_files.csv\")\nfiles_list=GDAC.files_list(fil)\nMITprof.format_loop(gridded_fields,files_list,1:10)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprof.write-Tuple{Dict, Array, Array}","page":"Reference","title":"ArgoData.MITprof.write","text":"MITprof.write(meta,profiles,profiles_std;path=\"\")\n\nCreate an MITprof file from meta data + profiles during MITprof.format.\n\nMITprof.write(meta,profiles,profiles_std)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprof.write-Tuple{String, MITprofStandard}","page":"Reference","title":"ArgoData.MITprof.write","text":"write(fil::String,mp::MITprofStandard)\n\nCreate an MITprof file from an MITprofStandard input.  \n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprof.write-Tuple{String, Vector{MITprofStandard}}","page":"Reference","title":"ArgoData.MITprof.write","text":"write(fil::String,mps::Vector{MITprofStandard})\n\nCreate an MITprof file from a vector of MITprofStandard inputs.  \n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#Module:-GriddedFields","page":"Reference","title":"Module: GriddedFields","text":"","category":"section"},{"location":"Functionalities/","page":"Reference","title":"Reference","text":"Modules = [GriddedFields]\nOrder   = [:type,:function]","category":"page"},{"location":"Functionalities/#ArgoData.GriddedFields.interp!-Tuple{MeshArrays.gcmarray, Any, MITprofStandard, NamedTuple, Any}","page":"Reference","title":"ArgoData.GriddedFields.interp!","text":"interp!(T_in::MeshArray,Γ,mp::MITprofStandard,📚,T_out)\ninterp!(T_in::MeshArray,Γ,mp::MITprofStandard,T_out)\n\nInterpolate T_in, defined on grid Γ, to locations speficied in mp and store the result in array T_out.\n\nProviding interpolation coefficients 📚 computed beforehand speeds up repeated calls.\n\nExample:\n\nfil=glob(\"*_MITprof.nc\",\"MITprof\")[1000]\nmp=MITprofStandard(fil)\n\n(f,i,j,w)=InterpolationFactors(G.Γ,mp.lon[:],mp.lat[:]);\n📚=(f=f,i=i,j=j,w=w)\n\nT=[similar(mp.T) for i in 1:12]\n[interp!(G.T[i],G.Γ,mp,📚,T[i]) for i in 1:12]\n\nIn the above example, [interp!(G.T[i],G.Γ,mp,T[i]) for i in 1:12] would be much slower.\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.GriddedFields.interp-Tuple{Any, Any, MITprofStandard}","page":"Reference","title":"ArgoData.GriddedFields.interp","text":"interp(T_in::MeshArray,Γ,mp::MITprofStandard)\n\nInterpolate T_in, defined on grid Γ, to locations speficied in mp. \n\nFor a more efficient, in place, option see interp!.\n\nfil=\"MITprof/1901238_MITprof.nc\"\nmp=MITprofStandard(fil)\n\ninterp(G.T[1],G.Γ,mp)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.GriddedFields.load-Tuple{}","page":"Reference","title":"ArgoData.GriddedFields.load","text":"load()\n\nLoad gridded fields from files (and download the files if needed). Originally this function returned Γ,msk,T,S,σT,σS,array. \n\nThe embeded array() function returns a 2D array initialized to missing.  And array(1), array(3,2), etc add dimensions to the resulting array.\n\nusing Climatology, MITgcm; Climatology.MITPROFclim_download()\nusing ArgoData; gridded_fields=GriddedFields.load()\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#Module:-MITprofAnalysis","page":"Reference","title":"Module: MITprofAnalysis","text":"","category":"section"},{"location":"Functionalities/","page":"Reference","title":"Reference","text":"Modules = [MITprofAnalysis]\nOrder   = [:type,:function]","category":"page"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.add_climatology_factors!-Tuple{Any}","page":"Reference","title":"ArgoData.MITprofAnalysis.add_climatology_factors!","text":"add_climatology_factors!(df)\n\nAdd temporal interpolation factors (rec0,rec1,fac0,fac1) to DataFrame. \n\ndf=CSV.read(\"csv/profile_positions.csv\",DataFrame)\nMITprofAnalysis.add_climatology_factors!(df)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.add_coeffs!-Tuple{Any}","page":"Reference","title":"ArgoData.MITprofAnalysis.add_coeffs!","text":"add_coeffs!(df)\n\nRead profile_coeffs.jld2 and add to df.    \n\ndf=MITprofAnalysis.read_pos_level(5)\nMITprofAnalysis.add_coeffs!(df)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.add_level!-Tuple{Any, Any}","page":"Reference","title":"ArgoData.MITprofAnalysis.add_level!","text":"add_level!(df,k)\n\nRead from e.g. csv_levels/k1.csv and add variables to df.    \n\ndf=CSV.read(\"csv/profile_positions.csv\",DataFrame)\nMITprofAnalysis.add_level!(df,5)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.add_tile!-Tuple{Any, Any, Any}","page":"Reference","title":"ArgoData.MITprofAnalysis.add_tile!","text":"add_tile!(df,Γ,n)\n\nAdd tile index (see MeshArrays.Tiles) to df that can then be used with e.g. groupby.\n\ninput_file=joinpath(\"MITprof_input\",\"profile_positions.csv\")\ndf=CSV.read(input_file,DataFrame)\nG=GriddedFields.load()\nMITprofAnalysis.add_tile!(df,G.Γ,30)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.cost_functions","page":"Reference","title":"ArgoData.MITprofAnalysis.cost_functions","text":"cost_functions(vv=\"prof_T\",JJ=[])\n\nLoop through files and compute nb profiles, nb non-blank profiles, nb levels mean, cost mean.\n\npth=\"MITprof/\"\nnt,np,nz,cost=MITprofAnalysis.cost_functions(pth,\"prof_S\")\n\nusing JLD2\njldsave(joinpath(\"csv\",\"prof_S_stats.jld2\"); nt,np,nz,cost)\n\n\n\n\n\n","category":"function"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.csv_of_levels","page":"Reference","title":"ArgoData.MITprofAnalysis.csv_of_levels","text":"csv_of_levels()\n\nCreate Array of all values for one level, obtained by looping through files in csv/. \n\n\n\n\n\n","category":"function"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.csv_of_positions","page":"Reference","title":"ArgoData.MITprofAnalysis.csv_of_positions","text":"csv_of_positions(path)\n\nCreate table (DataFrame) of the positions and dates obtained by looping through files in path.  Additional information such as float ID, position on the ECCO grid pos, number of  valid data points for T and S (nbT ,nbS).\n\nusing ArgoData\nusing MeshArrays\nΓ=GridLoad(ID=:LLC90)\npath=MITprof.default_path\ndf=MITprofAnalysis.csv_of_positions(path,Γ)\ncsv_file=joinpath(default_path,\"profile_positions.csv\")\nCSV.write(csv_file, df)\n\n\n\n\n\n","category":"function"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.csv_of_variables-Tuple{String}","page":"Reference","title":"ArgoData.MITprofAnalysis.csv_of_variables","text":"csv_of_variables(name::String)\n\nCreate Array of all values for one variable, obtained by looping through files in path. \n\n@everywhere using ArgoData, CSV, DataFrames\n@everywhere list_v=(\"prof_T\",\"prof_Testim\",\"prof_Tweight\",\"prof_S\",\"prof_Sestim\",\"prof_Sweight\")\n@distributed for v in list_v\n    tmp=MITprofAnalysis.csv_of_variables(v)\n    CSV.write(output_file,DataFrame(tmp,:auto))\nend\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.parse_pos-Tuple{Any}","page":"Reference","title":"ArgoData.MITprofAnalysis.parse_pos","text":"parse_pos(p)\n\nParse String vector p into a vector of CartesianIndex.\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.prepare_interpolation-Tuple{Any, Any, Any}","page":"Reference","title":"ArgoData.MITprofAnalysis.prepare_interpolation","text":"prepare_interpolation(Γ,lon,lat)\n\nAlias for InterpolationFactors(Γ,lon,lat). \n\nThe loop below creates interpolation coefficients for all data points. \n\nThe results are stored in a file called csv/profile_coeffs.jld2 at the end.\n\nusing SharedArrays, Distributed\n\n@everywhere begin\n    using ArgoData\n    G=GriddedFields.load()\n    df=MITprofAnalysis.read_pos_level(5)\n\n    np=size(df,1)\n    n0=10000\n    nq=Int(ceil(np/n0))\nend\n\n(f,i,j,w)=( SharedArray{Int64}(np,4), SharedArray{Int64}(np,4),\n            SharedArray{Int64}(np,4), SharedArray{Float64}(np,4) )\n\n@sync @distributed for m in 1:nq\n    ii=n0*(m-1) .+collect(1:n0)\n    ii[end]>np ? ii=n0*(m-1) .+collect(1:n0+np-ii[end]) : nothing\n    tmp=MITprofAnalysis.prepare_interpolation(G.Γ,df.lon[ii],df.lat[ii])\n    f[ii,:].=tmp[1]\n    i[ii,:].=tmp[2]\n    j[ii,:].=tmp[3]\n    w[ii,:].=tmp[4]\nend\n\nfil=joinpath(\"csv\",\"profile_coeffs.jld2\")\nco=[(f=f[ii,:],i=i[ii,:],j=j[ii,:],w=w[ii,:]) for ii in 1:np]\nsave_object(fil,co)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.read_pos_level","page":"Reference","title":"ArgoData.MITprofAnalysis.read_pos_level","text":"read_pos_level(k=1; input_path=\"\")\n\nRead in from csv/profile_positions.csv and e.g. csv_levels/k1.csv, parse pos, then add_level!(df,k), and return a DataFrame.\n\ndf=MITprofAnalysis.read_pos_level(5)\n\n\n\n\n\n","category":"function"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.subset-Tuple{DataFrames.DataFrame}","page":"Reference","title":"ArgoData.MITprofAnalysis.subset","text":"subset(df;lons=(-180.0,180.0),lats=(-90.0,90.0),dates=())\n\nSubset of df that's within specified date and position ranges.    \n\ndf=CSV.read(\"csv/profile_positions.csv\",DataFrame)\nd0=DateTime(\"2012-06-11T18:50:04\")\nd1=DateTime(\"2012-07-11T18:50:04\")\ndf1=MITprofAnalysis.subset(df,dates=(d0,d1))\ndf2=MITprofAnalysis.subset(df,lons=(0,10),lats=(-5,5),dates=(d0,d1))\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofAnalysis.trim-Tuple{Any}","page":"Reference","title":"ArgoData.MITprofAnalysis.trim","text":"trim(df)\n\nFilter out data points that lack T, Te, etc.\n\ndf=CSV.read(\"csv/profile_positions.csv\",DataFrame)\nMITprofAnalysis.add_level!(df,1)\ndf1=MITprofAnalysis.trim(df)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#Module:-MITprofStat","page":"Reference","title":"Module: MITprofStat","text":"","category":"section"},{"location":"Functionalities/","page":"Reference","title":"Reference","text":"Modules = [MITprofStat]\nOrder   = [:type,:function]","category":"page"},{"location":"Functionalities/#ArgoData.MITprofStat.list_stat_configurations-Tuple{}","page":"Reference","title":"ArgoData.MITprofStat.list_stat_configurations","text":"list_stat_configurations()\n\nList of confiburations (each one a choice of nmon,npoint,nobs) to be used in stat_combine.\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofStat.stat_df-Tuple{DataFrames.DataFrame, Symbol, Symbol}","page":"Reference","title":"ArgoData.MITprofStat.stat_df","text":"stat_df(df::DataFrame,by::Symbol,va::Symbol)\n\nCompute statistics (mean, median, variance) of variable va from DataFrame df grouped by by.\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofStat.stat_driver-Tuple{}","page":"Reference","title":"ArgoData.MITprofStat.stat_driver","text":"stat_driver(;varia=:Td,level=1,years=2004:2022,output_to_file=false,\nnmon=1, npoint=1, sta=:none, nobs=1, input_path=\"\", output_path=\"\")\n\nP=( variable=:Td, level=10, years=2002:2002, \n    statistic=:mean, npoint=3, nmon=3, \n    output_path=MITprof.default_path,\n    output_to_file=true\n    )\n\nMITprofStat.stat_driver(; varia=P.variable,\n        level=P.level,years=P.years,\n        nmon=P.nmon, npoint=P.npoint, sta=P.statistic, \n        output_path=P.output_path, output_to_file=P.output_to_file)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofStat.stat_grid!-Tuple{Array, DataFrames.DataFrame, Symbol, Symbol}","page":"Reference","title":"ArgoData.MITprofStat.stat_grid!","text":"stat_grid!(ar::Array,df::DataFrame,va::Symbol,sta::Symbol; func=(x->x))\n\nCompute map ar of statistic sta of variable va from DataFrame df. This  assumes that df.pos are indices into Array ar and should be used to groupby df.\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofStat.stat_monthly!-Tuple{Array, DataFrames.DataFrame, Symbol, Symbol, Any, NamedTuple}","page":"Reference","title":"ArgoData.MITprofStat.stat_monthly!","text":"stat_monthly!(arr:Array,df::DataFrame,va::Symbol,sta::Symbol,years,G::NamedTuple;\n                func=(x->x), nmon=1, npoint=1, nobs=1)\n\nCompute maps of statistic sta for variable va from DataFrame df for years years.  This assumes that df.pos are indices into Array ar and should be used to groupby df.  For each year in years, twelve fields are computed – one per month.\n\nusing ArgoData\nG=GriddedFields.load()\ndf1=MITprofAnalysis.trim( MITprofAnalysis.read_pos_level(1, input_path=\"MITprof_input\") )\n\nyears=2004:2007\narr=G.array(12,length(years))\nMITprofStat.stat_monthly!(arr,df1,:Td,:median,years,G,nmon=3);\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofStat.stat_monthly!-Tuple{Array, DataFrames.DataFrame, Symbol, Symbol, Int64, Int64, NamedTuple}","page":"Reference","title":"ArgoData.MITprofStat.stat_monthly!","text":"stat_monthly!(ar::Array,df::DataFrame,va::Symbol,sta::Symbol,y::Int,m::Int,G::NamedTuple;\n                func=(x->x), nmon=1, npoint=1, nobs=1)\n\nCompute map ar of statistic sta for variable va from DataFrame df for year y and month m. This assumes that df.pos are indices into Array ar and should be used to groupby df.\n\nusing ArgoData\nG=GriddedFields.load();\n\nP=( variable=:Td, level=10, year=2002, month=1, input_path=MITprof.default_path,\n    statistic=:median, npoint=9, nmon=3, rng=(-1.0,1.0))\n\ndf1=MITprofAnalysis.trim( MITprofAnalysis.read_pos_level(P.level,input_path=P.input_path) )\n\nGriddedFields.update_tile!(G,P.npoint);\nar1=G.array();\nMITprofStat.stat_monthly!(ar1,df1,\n    P.variable,P.statistic,P.year,P.month,G,nmon=P.nmon,npoint=P.npoint);\n\nMITprofPlots.stat_map(ar1,G,rng=P.rng)\n\n\n\n\n\n","category":"method"},{"location":"Functionalities/#ArgoData.MITprofStat.stat_write-Tuple{Any, Any, Any}","page":"Reference","title":"ArgoData.MITprofStat.stat_write","text":"stat_write(file,arr,varia)\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.jl","page":"Home","title":"ArgoData.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Tools to access, visualize, process, and analyze of  Argo ocean data sets.","category":"page"},{"location":"#Contents","page":"Home","title":"Contents","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"GDAC module to access and retrieve files from Argo server\nMITprof module for the format of Forget, et al 2015\nMITprofPlots module (in examples/) for MITprof\nMITprofAnalysis module for model-data comparison\nMITprofAnalysis module for tabular data access\nMITprofStat module geospatial statistics","category":"page"},{"location":"#Notebooks","page":"Home","title":"Notebooks","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"ArgoData 🚀 interactive vizualisation\nMITprof 🚀 simplified format\nargopy 🚀 python API via Julia","category":"page"},{"location":"","page":"Home","title":"Home","text":"This package is in early developement stage when breaking changes can be expected.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Argo Float Positions Argo Float Profiles (T, S, ...)\n(Image: float positions) (Image: salinity profiles)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Argo Profile Distributions Cost Funtions & Uncertainties\n(Image: distributions) (Image: cost pdf)","category":"page"}]
}
