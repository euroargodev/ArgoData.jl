var documenterSearchIndex = {"docs":
[{"location":"#ArgoData.jl","page":"Home","title":"ArgoData.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Argo data processing and analysis. Currently provides:","category":"page"},{"location":"","page":"Home","title":"Home","text":"The GDAC module functions access and retrieve files from the Argo data servers. \nMITprof supports the format of Forget, et al 2015 for standard depth data sets like this one.\nAnalysisMethods module provides methods for cost functions and geospatial statistics.\nThe MITprof_plots module in examples/.","category":"page"},{"location":"","page":"Home","title":"Home","text":"This package is in early developement stage when breaking changes can be expected.","category":"page"},{"location":"#Workflows","page":"Home","title":"Workflows","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Downloading and accessing an Argo file (wmo=13857 from folder=\"aoml\") is done like this.","category":"page"},{"location":"","page":"Home","title":"Home","text":"using ArgoData\ninput_file=GDAC.download_file(\"aoml\",13857)\n\nusing NCDatasets\nDataset(input_file)","category":"page"},{"location":"","page":"Home","title":"Home","text":"A list of all folder,wmo pairs can be obtained using files_list=GDAC.files_list(). And a method to download files in bulk & parallel is presented in examples/Argo_distributed_download.jl.","category":"page"},{"location":"#MITprof-Format","page":"Home","title":"MITprof Format","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Formatting an Argo file (input_file) into an MITprof file (output_file) proceeds as follows.","category":"page"},{"location":"","page":"Home","title":"Home","text":"gridded_fields=GriddedFields.load()\noutput_file=MITprof.format(gridded_fields,input_file)","category":"page"},{"location":"","page":"Home","title":"Home","text":"The file generated by the previous command can be accessed normally as a NetCDF file (e.g., Dataset(output_file)) or using the convenient MITprofStandard data structure.","category":"page"},{"location":"","page":"Home","title":"Home","text":"mp=MITprofStandard(output_file)","category":"page"},{"location":"","page":"Home","title":"Home","text":"For additional detail, please refer to the examples/ArgoToMITprof.jl example.","category":"page"},{"location":"#Download-MITprof-files","page":"Home","title":"Download MITprof files","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The original collection of MITprof files from Forget, et al 2015 is archived here. These files can be retrieved as follows.","category":"page"},{"location":"","page":"Home","title":"Home","text":"using CSV, DataFrames\ntmp = CSV.File(\"examples/dataverse_files.csv\") |> DataFrame\nurl0=\"https://dataverse.harvard.edu/api/access/datafile/\"\nrun(`wget --content-disposition $(url0)$(tmp[1,:ID])`)","category":"page"},{"location":"#Functions","page":"Home","title":"Functions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"ProfileNative\nProfileStandard\nMITprofStandard","category":"page"},{"location":"#ArgoData.ProfileNative","page":"Home","title":"ArgoData.ProfileNative","text":"ProfileNative\n\nContainer for a multivariate profile read from a GDAC Argo file.\n\n1D arrays: lon,lat,date,ymd,hms,pnumtxt,direc,DATAMODE,isBAD\n2D arrays: T,S,pressure,depth,T_ERR,SERR\n\n\n\n\n\n","category":"type"},{"location":"#ArgoData.ProfileStandard","page":"Home","title":"ArgoData.ProfileStandard","text":"ProfileNative\n\nContainer for a multivariate profile in MITprof format.\n\n2D arrays: T,S,Testim,Sestim,Tweight,Sweight,Ttest,Stest,T_ERR,SERR\n\n\n\n\n\n","category":"type"},{"location":"#ArgoData.MITprofStandard","page":"Home","title":"ArgoData.MITprofStandard","text":"MITprofStandard\n\nContainer for a MITprof format file data.\n\nfilename : file name\n1D arrays: lon,lat,date,depth,ID\n2D arrays: T,S,Te,Se,Tw,Sw\n\n\n\n\n\n","category":"type"},{"location":"","page":"Home","title":"Home","text":"Modules = [GDAC,MITprof,AnalysisMethods]\nOrder   = [:type,:function]","category":"page"},{"location":"#ArgoData.GDAC.download_file","page":"Home","title":"ArgoData.GDAC.download_file","text":"download_file(file::DataFrameRow,suff=\"prof\",ftp=missing)\n\nGet folder and wmo from data frame row and them call download_file.\n\nusing ArgoData\nfiles_list=GDAC.files_list()\nfile=GDAC.download_file(files_list[10000,:])\n\n\n\n\n\n","category":"function"},{"location":"#ArgoData.GDAC.download_file-2","page":"Home","title":"ArgoData.GDAC.download_file","text":"download_file(folder::String,wmo::Int,suff=\"prof\",ftp=missing)\n\nDownload Argo file from the GDAC server (<ftp://ftp.ifremer.fr/ifremer/argo/dac/> by default) to a temporary folder (joinpath(tempdir(),\"Argo_DAC_files\"))\n\nThe file name is given by folder and wmo. For example, 13857_prof.nc for wmo=13857 is from the aoml folder. \n\nThe default for suff is \"prof\" which means we'll download the file that contains the profile data.  Other possible choices are \"meta\", \"Rtraj\", \"tech\". \n\nIf the ftp argument is omitted or isa(ftp,String) then Downloads.download is used.  If, alternatively, isa(ftp,FTP) then FTPClient.download is used.\n\nExample :\n\nusing ArgoData\nGDAC.download_file(\"aoml\",13857)\n\n#or:\nftp=\"ftp://usgodae.org/pub/outgoing/argo/dac/\"\nGDAC.download_file(\"aoml\",13857,\"meta\",ftp)\n\n\n\n\n\n","category":"function"},{"location":"#ArgoData.GDAC.files_list-Tuple{String}","page":"Home","title":"ArgoData.GDAC.files_list","text":"files_list(fil::String)\n\nGet list of Argo float files from csv file with columns two columns – folder and wmo.\n\nusing ArgoData\nfil=\"https://raw.githubusercontent.com/JuliaOcean/ArgoData.jl/gh-pages/dev/Argo_float_files.csv\"\nfiles_list=GDAC.files_list(fil)\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.GDAC.files_list-Tuple{}","page":"Home","title":"ArgoData.GDAC.files_list","text":"files_list()\n\nGet list of Argo float files from Ifremer GDAC server      ftp://ftp.ifremer.fr/ifremer/argo/dac/\n\nusing ArgoData\nfiles_list=GDAC.files_list()\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.GDAC.grey_list-Tuple{String}","page":"Home","title":"ArgoData.GDAC.grey_list","text":"grey_list(fil::String)\n\nRead \"ar_greylist.txt\" file into a DataFrame.\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.GDAC.grey_list-Tuple{}","page":"Home","title":"ArgoData.GDAC.grey_list","text":"grey_list()\n\nDownload \"ar_greylist.txt\" from GDAC and read file into a DataFrame.\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.GDAC.wget_geo-Tuple{String, Int64, Int64}","page":"Home","title":"ArgoData.GDAC.wget_geo","text":"wget_geo(b::String,y::Int,m::Int)\n\nDownload, using wget, Argo data files for one regional domain (b), year (y), and month (m) from the GDAC FTP server (ftp://ftp.ifremer.fr/ifremer/argo or, equivalently, ftp://usgodae.org/pub/outgoing/argo).\n\nb=\"atlantic\"; yy=2009:2009; mm=8:12;\nfor y=yy, m=mm;\n    println(\"$b/$y/$m\"); GDAC.wget_geo(b,y,m)\nend\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.MITprof.format","page":"Home","title":"ArgoData.MITprof.format","text":"format(meta,gridded_fields,input_file,output_file=\"\")\n\nFrom Argo file name as input : read input file content, process into the MITprof format, and write to MITprof file.\n\nMITprof.format(meta,gridded_fields,input_file)\n\n\n\n\n\n","category":"function"},{"location":"#ArgoData.MITprof.format-Tuple{Any, Any}","page":"Home","title":"ArgoData.MITprof.format","text":"format(gridded_fields,input_file)\n\nFrom Argo file name as input : read input file content, process into the MITprof format, and write to MITprof file.\n\nMITprof.format(gridded_fields,input_file)\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.MITprof.format_loop-Tuple{Any, Any, Any}","page":"Home","title":"ArgoData.MITprof.format_loop","text":"format_loop(II)\n\nLoop over files and call format.\n\ngridded_fields=GriddedFields.load()\nfil=joinpath(tempdir(),\"Argo_MITprof_files\",\"input\",\"Argo_float_files.csv\")\nfiles_list=GDAC.files_list(fil)\nMITprof.format_loop(gridded_fields,files_list,1:10)\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.MITprof.write-Tuple{Dict, Array, Array}","page":"Home","title":"ArgoData.MITprof.write","text":"MITprof.write(meta,profiles,profiles_std;path=\"\")\n\nCreate an MITprof file from meta data + profiles during MITprof.format.\n\nMITprof.write(meta,profiles,profiles_std)\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.MITprof.write-Tuple{String, MITprofStandard}","page":"Home","title":"ArgoData.MITprof.write","text":"write(fil::String,mp::MITprofStandard)\n\nCreate an MITprof file from an MITprofStandard input.  \n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.MITprof.write-Tuple{String, Vector{MITprofStandard}}","page":"Home","title":"ArgoData.MITprof.write","text":"write(fil::String,mps::Vector{MITprofStandard})\n\nCreate an MITprof file from a vector of MITprofStandard inputs.  \n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.AnalysisMethods.cost_functions","page":"Home","title":"ArgoData.AnalysisMethods.cost_functions","text":"cost_functions(vv=\"prof_T\",JJ=[])\n\nLoop through files and compute nb profiles, nb non-blank profiles, nb levels mean, cost mean.\n\npth=\"MITprof/\"\nnt,np,nz,cost=MITprof.cost_functions(pth,\"prof_S\")\n\nusing JLD2\njldsave(joinpath(\"csv\",\"prof_S_stats.jld2\"); nt,np,nz,cost)\n\n\n\n\n\n","category":"function"},{"location":"#ArgoData.AnalysisMethods.profile_add_level!-Tuple{Any, Any}","page":"Home","title":"ArgoData.AnalysisMethods.profile_add_level!","text":"profile_add_level!(df,k)\n\ndf=CSV.read(\"csv/profile_positions.csv\",DataFrame)\nMITprof.profile_add_level!(df,5)\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.AnalysisMethods.profile_levels","page":"Home","title":"ArgoData.AnalysisMethods.profile_levels","text":"profile_levels()\n\nCreate Array of all values for one level, obtained by looping through files in csv/. \n\n\n\n\n\n","category":"function"},{"location":"#ArgoData.AnalysisMethods.profile_positions-Tuple{Any, Any}","page":"Home","title":"ArgoData.AnalysisMethods.profile_positions","text":"profile_positions(path)\n\nCreate table (DataFrame) of the positions and dates obtained by looping through files in path.  Additional information such as float ID, position on the ECCO grid pos, number of  valid data points for T and S (nbT ,nbS).\n\nusing ArgoData\npath=\"MITprof/\"\ncsv_file=\"csv/profile_positions.csv\"\n\nusing MeshArrays\nγ=GridSpec(\"LatLonCap\",MeshArrays.GRID_LLC90)\nΓ=GridLoad(γ)\n\ndf=MITprof.profile_positions(path,Γ)\nCSV.write(csv_file, df)\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.AnalysisMethods.profile_subset-NTuple{4, Any}","page":"Home","title":"ArgoData.AnalysisMethods.profile_subset","text":"profile_subset(df,lons,lats,dates)\n\ndf=CSV.read(\"csv/profile_positions.csv\",DataFrame)\nd0=DateTime(\"2012-06-11T18:50:04\")\nd1=DateTime(\"2012-07-11T18:50:04\")\ntmp=MITprof.profile_subset(df,(0,10),(-5,5),(d0,d1))\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.AnalysisMethods.profile_trim-Tuple{Any}","page":"Home","title":"ArgoData.AnalysisMethods.profile_trim","text":"profile_trim(df)\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.AnalysisMethods.profile_variables-Tuple{String}","page":"Home","title":"ArgoData.AnalysisMethods.profile_variables","text":"profile_variables(name::String)\n\nCreate Array of all values for one variable, obtained by looping through files in path. \n\n@everywhere using ArgoData, CSV, DataFrames\n@everywhere list_v=(\"prof_T\",\"prof_Testim\",\"prof_Tweight\",\"prof_S\",\"prof_Sestim\",\"prof_Sweight\")\n@distributed for v in list_v\n    output_file=\"csv/\"*v*\".csv\"\n    tmp=MITprof.profile_variables(v)\n    CSV.write(output_file,DataFrame(tmp,:auto))\nend\n\n\n\n\n\n","category":"method"}]
}
