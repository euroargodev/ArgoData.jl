
module GDAC

using NCDatasets, CSV, DataFrames, FTPClient, Downloads, Printf

"""
    Argo_float_files()

Get list of Argo float files from Ifremer GDAC server     
<ftp://ftp.ifremer.fr/ifremer/argo/dac/>

```
using ArgoData
GDAC.Argo_float_files()
```
"""
function Argo_float_files()
    ftp=FTP("ftp://ftp.ifremer.fr/ifremer/argo/dac/")

    list_files=DataFrame("folder" => [],"wmo" => [])
    list_folders=readdir(ftp)

    for pth in list_folders
        cd(ftp,pth)
        tmp=readdir(ftp)
        [append!(list_files,DataFrame("folder" => pth,"wmo" => parse(Int,x))) for x in tmp]
        cd(ftp,"..")
    end
    list_files
end

"""
    Argo_float_files(fil::String)

Get list of Argo float files from csv file with columns two columns -- `folder` and `wmo`.

```
using ArgoData
fil="https://gaelforget.github.io/OceanRobots.jl/dev/examples/Argo_float_files.csv"
GDAC.Argo_float_files(fil)
```
"""
function Argo_float_files(fil::String)
    if isfile(fil)
        DataFrame(CSV.File(fil))
    else
        DataFrame(CSV.File(Downloads.download(fil)))
    end
end

"""
    Argo_float_download(list_files,ii=1,suff="prof",ftp=missing)

Download one Argo file for float ranked `ii` in `list_files` 
from GDAC server (`ftp://ftp.ifremer.fr/ifremer/argo/dac/` by default)
to a temporary folder (`joinpath(tempdir(),"Argo_DAC_files")`).
By default `suff="prof"` means we'll download the file that contains 
the profile data (e.g. `13857_prof.nc` for `ii=1` with `wmo=13857`). 
Other possible choices for `suff`: "meta", "Rtraj", "tech".
If the `ftp` argument is omitted or `isa(ftp,String)` then `Downloads.download` is used. 
If, alternatively, `isa(ftp,FTP)` then `FTPClient.download` is used.

Example :

```
using ArgoData
list_files=GDAC.Argo_float_files()
GDAC.Argo_float_download(list_files,10000)

ftp="ftp://usgodae.org/pub/outgoing/argo/dac/"
GDAC.Argo_float_download(list_files,10000,"meta",ftp)
```
"""
function Argo_float_download(list_files,ii,suff="prof",ftp=missing)
    path=joinpath(tempdir(),"Argo_DAC_files")
    !isdir(path) ? mkdir(path) : nothing
    folder=list_files[ii,:folder]
    wmo=list_files[ii,:wmo]
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
month (m) from the `GDAC` FTP server (`ftp://ftp.ifremer.fr/ifremer/argo`
or, equivalently, `ftp://usgodae.org/pub/outgoing/argo`).

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
