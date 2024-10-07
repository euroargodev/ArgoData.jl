
module ArgoFiles

using NCDatasets, Downloads, CSV, DataFrames, Interpolations, Statistics, Dates

"""
    ArgoFiles.list_floats(;list=DataFrame())

Get list of Argo profilers from file `ArgoFiles.list_floats()`.

Or write provided `list` to file as a DataFrame.

```
using OceanRobots, ArgoData
ArgoFiles.list_floats(list=GDAC.files_list())
```
"""
function list_floats(;list=DataFrame())
    td=string(Dates.today())
    fil=joinpath(tempdir(),"Argo_list_$(td).csv")
    if isempty(list)
        files_list=CSV.read(fil,DataFrame)
    else
        files_list=list
        CSV.write(fil,files_list)
        files_list
    end
end

"""
    ArgoFiles.download(files_list,wmo)

Download an Argo profiler file.    
"""
function download(files_list,wmo)
    ii=findall(files_list.wmo.==wmo)[1]
    folder=files_list.folder[ii]

    url0="https://data-argo.ifremer.fr/dac/$(folder)/"
    fil=joinpath(tempdir(),"$(wmo)_prof.nc")

    !isfile(fil) ? Downloads.download(url0*"/$(wmo)/$(wmo)_prof.nc",fil) : nothing

    return fil
end

"""
    ArgoFiles.readfile(fil)

Read an Argo profiler file.    
"""
function readfile(fil)
    ds=Dataset(fil)

	lon=ds["LONGITUDE"][:]
	lat=ds["LATITUDE"][:]

	lon360=lon; lon[findall(lon.<0)].+=360
	maximum(lon)-minimum(lon)>maximum(lon360)-minimum(lon360) ? lon=lon360 : nothing

	PRES=ds["PRES_ADJUSTED"][:,:]
	TEMP=ds["TEMP_ADJUSTED"][:,:]
	PSAL=ds["PSAL_ADJUSTED"][:,:]
	TIME=10*ones(size(PRES,1)).* (1:length(lon))' .-10.0
    DATE=[DateTime(ds["JULD"][i]) for j in 1:size(PRES,1), i in 1:length(lon)]

    close(ds)

    return (lon=lon,lat=lat,PRES=PRES,TEMP=TEMP,PSAL=PSAL,TIME=TIME,DATE=DATE)
end

skmi(x) = ( sum((!ismissing).(x))>0 ? minimum(skipmissing(x)) : missing )
skma(x) = ( sum((!ismissing).(x))>0 ? maximum(skipmissing(x)) : missing )

"""
    ArgoFiles.scan_txt(fil="ar_index_global_prof.txt"; do_write=false)

Scan the Argo file lists and return summary tables in DataFrame format. 
Write to csv file if `istrue(do_write)`.

```
ArgoFiles.scan_txt("ar_index_global_prof.txt",do_write=true)
ArgoFiles.scan_txt("argo_synthetic-profile_index.txt",do_write=true)
```
"""
function scan_txt(fil="ar_index_global_prof.txt"; do_write=false)
    if fil=="ar_index_global_prof.txt"
        filename=joinpath(tempdir(),"ar_index_global_prof.txt")
        url="https://data-argo.ifremer.fr/ar_index_global_prof.txt"
        outputfile=joinpath(tempdir(),"ar_index_global_prof.csv")
    elseif fil=="argo_synthetic-profile_index.txt"
        filename=joinpath(tempdir(),"argo_synthetic-profile_index.txt")
        url="https://data-argo.ifremer.fr/argo_synthetic-profile_index.txt"
        outputfile=joinpath(tempdir(),"argo_synthetic-profile_index.csv")
    else
        error("unknown file")
    end

    !isfile(filename) ? Downloads.download(url,filename) : nothing

    df=DataFrame(CSV.File(filename; header=9))
    n=length(df.file)
    df.wmo=[parse(Int,split(df.file[i],"/")[2]) for i in 1:n]
    sum(occursin.(names(df),"parameters"))==0 ? df.parameters=fill("CTD",n) : nothing

    gdf=groupby(df,:wmo)

    prof=combine(gdf) do df
        (minlon=skmi(df.longitude) , maxlon=skma(df.longitude) ,
        minlat=skmi(df.latitude) , maxlat=skma(df.latitude) ,
        mintim=skmi(df.date) , maxtim=skma(df.date), 
        nprof=length(df.date) , parameters=df.parameters[1])
    end

    do_write ? CSV.write(outputfile, prof) : nothing

    return prof
end

function speed(arr)
    (lon,lat)=(arr.lon,arr.lat)
    EarthRadius=6378e3 #in meters
    gcdist(lo1,lo2,la1,la2) = acos(sind(la1)*sind(la2)+cosd(la1)*cosd(la2)*cosd(lo1-lo2)) #in radians

    dx_net=EarthRadius*gcdist(lon[1],lon[end],lat[1],lat[end])
    dx=[EarthRadius*gcdist(lon[i],lon[i+1],lat[i],lat[i+1]) for i in 1:length(lon)-1]
    dt=10.0*86400

    dist_tot=sum(dx)/1000 #in km
    dist_net=dx_net/1000 #in km
    
	speed=[dx[1] ; (dx[2:end]+dx[1:end-1])/2 ; dx[end]]/dt
    speed_mean=mean(speed)

    return (dist_tot=dist_tot,dist_net=dist_net,
    speed_mean=speed_mean, speed=speed)
end

z_std=collect(0.0:5:500.0)
nz=length(z_std)

function interp_z(P,T)
    k=findall((!ismissing).(P.*T))
    interp_linear_extrap = LinearInterpolation(Float64.(P[k]), Float64.(T[k]), extrapolation_bc=Line()) 
    interp_linear_extrap(z_std)
end

function interp_z_all(arr)
    np=size(arr.PRES,2)
    T_std=zeros(length(z_std),np)
    S_std=zeros(length(z_std),np)
    [T_std[:,i].=interp_z(arr.PRES[:,i],arr.TEMP[:,i]) for i in 1:np]
    [S_std[:,i].=interp_z(arr.PRES[:,i],arr.PSAL[:,i]) for i in 1:np]
    T_std,S_std
end

end
