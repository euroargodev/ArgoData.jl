
module GDAC

using NCDatasets, CSV, DataFrames, FTPClient, Downloads, Printf

"""
    grey_list(fil::String)

Read "ar_greylist.txt" file into a DataFrame.
"""
grey_list(fil::String) = DataFrame(CSV.File(fil))

"""
    grey_list()

Download "ar_greylist.txt" from GDAC and read file into a DataFrame.
"""
function grey_list()
    Downloads.download("https://data-argo.ifremer.fr/ar_greylist.txt",joinpath(tempdir(),"ar_greylist.txt"))
    grey_list(joinpath(tempdir(),"ar_greylist.txt"))
end

"""
    files_list()

Get list of Argo float files from Ifremer GDAC server     
<ftp://ftp.ifremer.fr/ifremer/argo/dac/>

```
using ArgoData
files_list=GDAC.files_list()
```
"""
function files_list()
    ftp=FTP("ftp://ftp.ifremer.fr/ifremer/argo/dac/")

    files_list=DataFrame("folder" => [],"wmo" => [])
    list_folders=readdir(ftp)

    for pth in list_folders
        cd(ftp,pth)
        tmp=readdir(ftp)
        [append!(files_list,DataFrame("folder" => pth,"wmo" => parse(Int,x))) for x in tmp]
        cd(ftp,"..")
    end
    files_list
end

"""
    files_list(fil::String)

Get list of Argo float files from csv file with columns two columns -- `folder` and `wmo`.

```
using ArgoData
fil="https://raw.githubusercontent.com/euroargodev/ArgoData.jl/gh-pages/dev/Argo_float_files.csv"
files_list=GDAC.files_list(fil)
```
"""
function files_list(fil::String)
    if isfile(fil)
        DataFrame(CSV.File(fil))
    else
        DataFrame(CSV.File(Downloads.download(fil)))
    end
end

"""
    download_file(file::DataFrameRow,suff="prof",ftp=missing)

Get `folder` and `wmo` from data frame row and them call `download_file`.

```
using ArgoData
files_list=GDAC.files_list()
file=GDAC.download_file(files_list[10000,:])
```    
"""
download_file(file::DataFrameRow,suff="prof",ftp=missing) = download_file(file.folder,file.wmo,suff,ftp)

"""
    download_file(folder::String,wmo::Int,suff="prof",ftp=missing)

Download Argo file from the GDAC server (`<ftp://ftp.ifremer.fr/ifremer/argo/dac/>` by default)
to a temporary folder (`joinpath(tempdir(),"Argo_DAC_files")`)

The file name is given by `folder` and `wmo`.
For example, `13857_prof.nc` for `wmo=13857` is from the `aoml` folder. 

The default for `suff` is `"prof"` which means we'll download the file that contains the profile data. 
Other possible choices are `"meta"`, `"Rtraj"`, `"tech"`. 

If the `ftp` argument is omitted or `isa(ftp,String)` then `Downloads.download` is used. 
If, alternatively, `isa(ftp,FTP)` then `FTPClient.download` is used.

Example :

```
using ArgoData
GDAC.download_file("aoml",13857)

#or:
ftp="ftp://usgodae.org/pub/outgoing/argo/dac/"
GDAC.download_file("aoml",13857,"meta",ftp)
```
"""
function download_file(folder::String,wmo::Int,suff="prof",ftp=missing)
    path=joinpath(tempdir(),"Argo_DAC_files")
    !isdir(path) ? mkdir(path) : nothing
    path=joinpath(path,folder)
    !isdir(path) ? mkdir(path) : nothing
    path=joinpath(path,string(wmo))
    !isdir(path) ? mkdir(path) : nothing

    if ismissing(ftp)||isa(ftp,String)
        fil_out=joinpath(path,string(wmo)*"_"*suff*".nc")
        ismissing(ftp) ? path_ftp="ftp://ftp.ifremer.fr/ifremer/argo/dac/" : path_ftp=ftp
        fil_in=path_ftp*folder*"/"*string(wmo)*"/"*string(wmo)*"_"*suff*".nc"
        try
            Downloads.download(fil_in, fil_out)
        catch
            fil_err=fil_out*"_failed"
            run(`touch $(fil_err)`)
        end
    else
        fil_out=path*"/"*string(wmo)*"_"*suff*".nc"
        fil_in=folder*"/"*string(wmo)*"/"*string(wmo)*"_"*suff*".nc"
        FTPClient.download(ftp,fil_in, fil_out)
    end
    
    return fil_out
end

"""
    wget_geo(b::String,y::Int,m::Int)

Download, using wget, Argo data files for one regional domain (b), year (y), and
month (m) from the `GDAC` FTP server (<ftp://ftp.ifremer.fr/ifremer/argo>
or, equivalently, <ftp://usgodae.org/pub/outgoing/argo>).

```
b="atlantic"; yy=2009:2009; mm=8:12;
for y=yy, m=mm;
    println("\$b/\$y/\$m"); GDAC.wget_geo(b,y,m)
end
```
"""
function wget_geo(b::String,y::Int,m::Int)
    yy = @sprintf "%04d" y
    mm = @sprintf "%02d" m
    c=`wget --quiet -r ftp://ftp.ifremer.fr/ifremer/argo/geo/"$b"_ocean/$yy/$mm`
    run(c)
end

end
