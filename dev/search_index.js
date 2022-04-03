var documenterSearchIndex = {"docs":
[{"location":"#ArgoData.jl","page":"Home","title":"ArgoData.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Argo data processing and analysis. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"The GDAC module functions access and retrieve files from the Argo data servers. \nMITprof supports the format of Forget, et al 2015 for standard depth data sets like this one.","category":"page"},{"location":"","page":"Home","title":"Home","text":"This package is in early developement stage when breaking changes can be expected.","category":"page"},{"location":"#Workflows","page":"Home","title":"Workflows","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Downloading and accessing an Argo file can simply be done like this.","category":"page"},{"location":"","page":"Home","title":"Home","text":"using ArgoData, NCDatasets\nfiles_list=GDAC.Argo_files_list()\nfile=GDAC.Argo_float_download(files_list[10000,:])\nDataset(file)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Or alternatively, like this.","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Downloads, NCDatasets\n\nwmo=6900900\nurl0=\"https://data-argo.ifremer.fr/dac/coriolis/\"\ninput_url=url0*\"/$(wmo)/$(wmo)_prof.nc\"\ninput_file=joinpath(tempdir(),\"$(wmo)_prof.nc\")\nfile=Downloads.download(input_url,input_file)\n\nDataset(file)","category":"page"},{"location":"","page":"Home","title":"Home","text":"A method to download files in bulk & parallel is presented in examples/Argodistributeddownload.jl.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Formatting of an Argo file (input_file) into an MITprof file (output_file) proceeds as follows.","category":"page"},{"location":"","page":"Home","title":"Home","text":"using ArgoData\n\nmeta=ArgoTools.meta(input_file,output_file)\ngridded_fields=GriddedFields.load()\nMITprof.format(meta,gridded_fields,input_file,output_file)","category":"page"},{"location":"","page":"Home","title":"Home","text":"The file generated by the previous command can be accessed normally as a NetCDF file or using the convenient MITprofStandard data structure from within Julia.","category":"page"},{"location":"","page":"Home","title":"Home","text":"using ArgoData\nmp=MITprofStandard(output_file)","category":"page"},{"location":"","page":"Home","title":"Home","text":"or ","category":"page"},{"location":"","page":"Home","title":"Home","text":"using NCDatasets\nds=Dataset(output_file)","category":"page"},{"location":"","page":"Home","title":"Home","text":"For additional detail, please refer to the examples/ArgoToMITprof.jl example.","category":"page"},{"location":"#Functions","page":"Home","title":"Functions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"ProfileNative\nProfileStandard\nMITprofStandard","category":"page"},{"location":"#ArgoData.ProfileNative","page":"Home","title":"ArgoData.ProfileNative","text":"ProfileNative\n\nContainer for a multivariate profile read from a GDAC Argo file.\n\n1D arrays: lon,lat,date,ymd,hms,pnumtxt,direc,DATAMODE,isBAD\n2D arrays: T,S,pressure,depth,T_ERR,SERR\n\n\n\n\n\n","category":"type"},{"location":"#ArgoData.ProfileStandard","page":"Home","title":"ArgoData.ProfileStandard","text":"ProfileNative\n\nContainer for a multivariate profile in MITprof format.\n\n2D arrays: T,S,Testim,Sestim,Tweight,Sweight,Ttest,Stest,T_ERR,SERR\n\n\n\n\n\n","category":"type"},{"location":"#ArgoData.MITprofStandard","page":"Home","title":"ArgoData.MITprofStandard","text":"MITprofStandard\n\nContainer for a MITprof format file data.\n\nfilename : file name\n1D arrays: lon,lat,date,depth,ID\n2D arrays: T,S,Te,Se,Tw,Sw\n\n\n\n\n\n","category":"type"},{"location":"","page":"Home","title":"Home","text":"Modules = [GDAC,MITprof]\nOrder   = [:type,:function]","category":"page"},{"location":"#ArgoData.GDAC.download_file","page":"Home","title":"ArgoData.GDAC.download_file","text":"download_file(file::DataFrameRow,suff=\"prof\",ftp=missing)\n\nDownload Argo file from the GDAC server (<ftp://ftp.ifremer.fr/ifremer/argo/dac/> by default) to a temporary folder (joinpath(tempdir(),\"Argo_DAC_files\"))\n\nThe file name is given by file.folder and file.wmo. For example, 13857_prof.nc for wmo=13857 is from the aoml folder. \n\nThe default for suff is \"prof\" which means we'll download the file that contains the profile data.  Other possible choices are \"meta\", \"Rtraj\", \"tech\". \n\nIf the ftp argument is omitted or isa(ftp,String) then Downloads.download is used.  If, alternatively, isa(ftp,FTP) then FTPClient.download is used.\n\nExample :\n\nusing ArgoData\nfiles_list=GDAC.files_list()\nGDAC.download_file(files_list[10000,:])\n\n#or:\n\nftp=\"ftp://usgodae.org/pub/outgoing/argo/dac/\"\nGDAC.download_file(files_list[10000,:],\"meta\",ftp)\n\n\n\n\n\n","category":"function"},{"location":"#ArgoData.GDAC.files_list-Tuple{String}","page":"Home","title":"ArgoData.GDAC.files_list","text":"files_list(fil::String)\n\nGet list of Argo float files from csv file with columns two columns – folder and wmo.\n\nusing ArgoData\nfil=\"https://raw.githubusercontent.com/JuliaOcean/ArgoData.jl/gh-pages/dev/Argo_float_files.csv\"\nfiles_list=GDAC.files_list(fil)\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.GDAC.files_list-Tuple{}","page":"Home","title":"ArgoData.GDAC.files_list","text":"files_list()\n\nGet list of Argo float files from Ifremer GDAC server      ftp://ftp.ifremer.fr/ifremer/argo/dac/\n\nusing ArgoData\nfiles_list=GDAC.files_list()\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.GDAC.grey_list-Tuple{String}","page":"Home","title":"ArgoData.GDAC.grey_list","text":"grey_list(fil::String)\n\nRead \"ar_greylist.txt\" file into a DataFrame.\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.GDAC.grey_list-Tuple{}","page":"Home","title":"ArgoData.GDAC.grey_list","text":"grey_list()\n\nDownload \"ar_greylist.txt\" from GDAC and read file into a DataFrame.\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.GDAC.wget_geo-Tuple{String, Int64, Int64}","page":"Home","title":"ArgoData.GDAC.wget_geo","text":"wget_geo(b::String,y::Int,m::Int)\n\nDownload, using wget, Argo data files for one regional domain (b), year (y), and month (m) from the GDAC FTP server (ftp://ftp.ifremer.fr/ifremer/argo or, equivalently, ftp://usgodae.org/pub/outgoing/argo).\n\nb=\"atlantic\"; yy=2009:2009; mm=8:12;\nfor y=yy, m=mm;\n    println(\"$b/$y/$m\"); GDAC.wget_geo(b,y,m)\nend\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.MITprof.format","page":"Home","title":"ArgoData.MITprof.format","text":"format(meta,gridded_fields,input_file,output_file=\"\")\n\nFrom Argo file name as input : read input file content, process into the MITprof format, and write to MITprof file.\n\nMITprof.format(meta,gridded_fields,input_file)\n\n\n\n\n\n","category":"function"},{"location":"#ArgoData.MITprof.format_loop-Tuple{Any, Any, Any}","page":"Home","title":"ArgoData.MITprof.format_loop","text":"format_loop(II)\n\nLoop over files and call format.\n\ngridded_fields=GriddedFields.load()\nfiles_list=GDAC.files_list()\nMITprof.format_loop(gridded_fields,files_list,1:10)\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.MITprof.read_positions","page":"Home","title":"ArgoData.MITprof.read_positions","text":"read_positions(f::String=\"MITprof/MITprof_mar2016_argo9506.nc\")\n\nStandard Depth Argo Data Example.\n\nHere we read the MITprof standard depth data set from <https://doi.org/10.7910/DVN/EE3C40> For more information, please refer to Forget, et al 2015 (<http://dx.doi.org/10.5194/gmd-8-3071-2015>) The produced figure shows the number of profiles as function of time for a chosen file     and maps out the locations of Argo profiles collected for a chosen year.\n\nusing ArgoData, Plots\n\nfi=\"MITprof/MITprof_mar2016_argo9506.nc\"\n(lo,la,ye)=MITprof.read_positions(fi)\n\nh = histogram(ye,bins=20,label=fi[end-10:end],title=\"Argo profiles\")\n\nye0=2004; ye1=ye0.+1\nkk=findall((ye.>ye0) .* (ye.<ye1))\nscatter(lo[kk],la[kk],label=fi[end-10:end],title=\"Argo profiles count\")\n\n\n\n\n\n","category":"function"},{"location":"#ArgoData.MITprof.read_positions_loop","page":"Home","title":"ArgoData.MITprof.read_positions_loop","text":"read_positions_loop(pth::String=\"profiles/\")\n\nStandard Depth Argo Data Collection – see ?MITprof.read for detail.\n\n\n\n\n\n","category":"function"},{"location":"#ArgoData.MITprof.write-Tuple{Dict, Array, Array}","page":"Home","title":"ArgoData.MITprof.write","text":"MITprof.write(meta,profiles,profiles_std;path=\"\")\n\nCreate an MITprof file from meta data + profiles during MITprof.format.\n\nMITprof.write(meta,profiles,profiles_std)\n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.MITprof.write-Tuple{String, MITprofStandard}","page":"Home","title":"ArgoData.MITprof.write","text":"write(fil::String,mp::MITprofStandard)\n\nCreate an MITprof file from an MITprofStandard input.  \n\n\n\n\n\n","category":"method"},{"location":"#ArgoData.MITprof.write-Tuple{String, Vector{MITprofStandard}}","page":"Home","title":"ArgoData.MITprof.write","text":"write(fil::String,mps::Vector{MITprofStandard})\n\nCreate an MITprof file from a vector of MITprofStandard inputs.  \n\n\n\n\n\n","category":"method"}]
}
