module MITprof

using Dates, MeshArrays, NCDatasets, OrderedCollections, UnPack

import ArgoData.ProfileNative
import ArgoData.ProfileStandard
import ArgoData.ArgoTools

## reading MITprof files in bulk

function ncread(f::String,v::String)
    Dataset(f,"r") do ds
        ds[v][:]
    end
end

"""
    MITprof_read(f::String="MITprof/MITprof_mar2016_argo9506.nc")

Standard Depth Argo Data Example.

Here we read the `MITprof` standard depth data set from `https://doi.org/10.7910/DVN/EE3C40`
For more information, please refer to Forget, et al 2015 (`http://dx.doi.org/10.5194/gmd-8-3071-2015`)
The produced figure shows the number of profiles as function of time for a chosen file
    and maps out the locations of Argo profiles collected for a chosen year.

```
using ArgoData, Plots

fi="MITprof/MITprof_mar2016_argo9506.nc"
(lo,la,ye)=MITprof.MITprof_read(fi)

h = histogram(ye,bins=20,label=fi[end-10:end],title="Argo profiles")

ye0=2004; ye1=ye0.+1
kk=findall((ye.>ye0) .* (ye.<ye1))
scatter(lo[kk],la[kk],label=fi[end-10:end],title="Argo profiles count")
```
"""
function MITprof_read(f::String="MITprof/MITprof_mar2016_argo9506.nc")
    #i = ncinfo(f)
    lo = ncread(f, "prof_lon")
    la = ncread(f, "prof_lat")
    x = ncread(f, "prof_date")
    t = julian2datetime.( datetime2julian(DateTime(0)) .+ x )
    ye = year.(t) + dayofyear.(t) ./ 365.0 #neglecting leap years ...
    return Float64.(lo),Float64.(la),Float64.(ye)
end

"""
    loop(pth::String="profiles/")

Standard Depth Argo Data Collection -- see `?MITprof.read` for detail.
"""
function loop(pth::String="profiles/")
    λ=("MITprof_mar2016_argo9506.nc","MITprof_mar2016_argo0708.nc",
    "MITprof_mar2016_argo0910.nc","MITprof_mar2016_argo1112.nc",
    "MITprof_mar2016_argo1314.nc","MITprof_mar2016_argo1515.nc")

    lo=[]; la=[]; ye=[];
    for f=1:length(λ)
        (tmplo,tmpla,tmpye)=read(pth*λ[f])
        lo=cat(lo,tmplo,dims=1)
        la=cat(la,tmpla,dims=1)
        ye=cat(ye,tmpye,dims=1)
    end

    return Float64.(lo),Float64.(la),Float64.(ye)
end

## writing MITprof files

"""
    MITprof.MITprof_write(meta,profiles,profiles_std;path="")

Write to file.

```
MITprof.MITprof_write(meta,profiles,profiles_std)
```
"""
function MITprof_write(meta::Dict,profiles::Array,profiles_std::Array;path="")

    isempty(path) ? p=tempdir() : p=path
    fil=joinpath(p,meta["fileOut"])

    z=Float64.(meta["depthLevels"])
    k=findall((z.>=meta["depthRange"][1]) .& (z.<=meta["depthRange"][2]))

    iPROF = length(profiles[:])
    iDEPTH = length(k)
    iINTERP = 4
    lTXT = 30
    
    ##
    
    NCDataset(fil,"c") do ds
        defDim(ds,"iPROF",iPROF)
        defDim(ds,"iDEPTH",iDEPTH)
        defDim(ds,"iINTERP",iINTERP)
        defDim(ds,"lTXT",lTXT)
        ds.attrib["title"] = "MITprof file created by ArgoData.jl (WIP)"
    end

    ##

    NCDataset(fil,"a") do ds
      defVar(ds,"prof_depth",z[k],("iDEPTH",),
            attrib = OrderedDict(
         "units" => "m",
         "_FillValue" => -9999.,
         "long_name" => "Depth"
      ))
    end
    
    ##
    
    data1 = Array{Union{Missing, Float64}, 1}(undef, iPROF)
    
    ##
    
    [data1[i]=profiles[i].lon for i in 1:iPROF]
    ncwrite_1d(data1,fil,"prof_lon","Longitude (degree East)","degrees_east")
    
    [data1[i]=profiles[i].date for i in 1:iPROF]
    ncwrite_1d(data1,fil,"prof_date","Julian day since Jan-1-0000"," ") ##need units
    
    [data1[i]=profiles[i].ymd for i in 1:iPROF]
    ncwrite_1d(data1,fil,"prof_YYYYMMDD","year (4 digits), month (2 digits), day (2 digits)"," ") ##need units

    [data1[i]=profiles[i].hms for i in 1:iPROF]
    ncwrite_1d(data1,fil,"prof_HHMMSS","hour (2 digits), minute (2 digits), second (2 digits)"," ") ##need units

# 	double prof_basin(iPROF) ;
# 	double prof_point(iPROF) ;

    ##

    data = Array{Union{Missing, Float64}, 2}(undef, iPROF, iDEPTH)
    
    ##
    
    [data[i,:].=profiles_std[i].T[k] for i in 1:iPROF]
    ncwrite_2d(data,fil,"prof_T","Temperature","degree_Celsius")

    [data[i,:].=profiles_std[i].Tweight[k] for i in 1:iPROF]
    ncwrite_2d(data,fil,"prof_Tweight","Temperature least-square weight","(degree C)^-2")

    [data[i,:].=profiles_std[i].Testim[k] for i in 1:iPROF]
    ncwrite_2d(data,fil,"prof_Testim","Temperature atlas (monthly clim.)","degree_Celsius")

# 	double prof_Terr(iPROF, iDEPTH) ;
# 	double prof_Tflag(iPROF, iDEPTH) ;

    ##

    [data[i,:].=profiles_std[i].S[k] for i in 1:iPROF]
    ncwrite_2d(data,fil,"prof_S","Salinity","psu")

    [data[i,:].=profiles_std[i].Sweight[k] for i in 1:iPROF]
    ncwrite_2d(data,fil,"prof_Sweight","Salinity least-square weight","(psu)^-2")

    [data[i,:].=profiles_std[i].Sestim[k] for i in 1:iPROF]
    ncwrite_2d(data,fil,"prof_Sestim","Salinity atlas (monthly clim.)","psu")

# 	double prof_Serr(iPROF, iDEPTH) ;
# 	double prof_Sflag(iPROF, iDEPTH) ;

end

##

function ncwrite_2d(data,fil,name,long_name,units)
    NCDataset(fil,"a") do ds
      defVar(ds,name,data,("iPROF","iDEPTH"),
            attrib = OrderedDict(
         "units" => units,
         "_FillValue" => -9999.,
         "long_name" => long_name
      ))
    end
end

function ncwrite_1d(data,fil,name,long_name,units)
    NCDataset(fil,"a") do ds
        defVar(ds,name,data,("iPROF",),
            attrib = OrderedDict(
        "units" => units,
        "_FillValue" => -9999.,
        "long_name" => long_name
        ))
    end
end

##

"""
    MITprof_format(meta,gridded_fields,input_file,output_file="")

From Argo file name as input : read input file content, process into the MITprof format, and write to MITprof file.

```
MITprof.MITprof_format(meta,gridded_fields,input_file)
```
"""
function MITprof_format(meta,gridded_fields,input_file,output_file="")
    @unpack Γ,msk,T,S,σT,σS = gridded_fields
    z_std = meta["z_std"]

    isempty(output_file) ? output_file=joinpath(tempdir(),"MITprof_"*input_file) : nothing

    argo_data=Dataset(input_file)
    haskey(argo_data.dim,"N_PROF") ? np=argo_data.dim["N_PROF"] : np=NaN

    nz=length(z_std)

    profiles=Array{ProfileNative,1}(undef,np)
    profiles_std=Array{ProfileStandard,1}(undef,np)
    
    for m in 1:np
        #println(m)
    
        prof=ArgoTools.GetOneProfile(argo_data,m)
        prof_std=ProfileStandard(nz)
    
        ArgoTools.prof_convert!(prof,meta)
        ArgoTools.prof_interp!(prof,prof_std,meta)
    
        ArgoTools.prof_test_set1!(prof,prof_std,meta)

        ##
    
        (f,i,j,w)=InterpolationFactors(Γ,prof.lon,prof.lat)
        📚=(f=f,i=i,j=j,w=w)
    
        prof_σT=[Interpolate(σT[:,k],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
        prof_σS=[Interpolate(σS[:,k],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
    
        prof_σT=ArgoTools.interp1(-Γ.RC,prof_σT,z_std)
        prof_σS=ArgoTools.interp1(-Γ.RC,prof_σS,z_std)
    
        #3. combine instrumental and representation error
        prof_std.Tweight.=1 ./(prof_σT.^2 .+ prof_std.T_ERR.^2)
        prof_std.Sweight.=1 ./(prof_σS.^2 .+ prof_std.S_ERR.^2)
    
        ##
    
        fac,rec=ArgoTools.monthly_climatology_factors(prof.date)
    
        tmp1=[Interpolate(T[:,k,rec[1]],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
        tmp2=[Interpolate(T[:,k,rec[2]],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
        prof_std.Testim.=ArgoTools.interp1(-Γ.RC,fac[1]*tmp1+fac[2]*tmp2,z_std)
    
        tmp1=[Interpolate(S[:,k,rec[1]],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
        tmp2=[Interpolate(S[:,k,rec[2]],📚.f,📚.i,📚.j,📚.w)[1] for k=1:50]
        prof_std.Sestim.=ArgoTools.interp1(-Γ.RC,fac[1]*tmp1+fac[2]*tmp2,z_std)
    
        #

        ArgoTools.prof_test_set2!(prof_std,meta)

        #
    
        profiles[m]=prof
        profiles_std[m]=prof_std
    end

    MITprof.MITprof_write(meta,profiles,profiles_std)

    output_file
end

end
