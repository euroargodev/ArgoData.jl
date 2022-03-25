# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext:
#     formats: ipynb,jl:light
#     text_representation:
#       extension: .jl
#       format_name: light
#       format_version: '1.5'
#       jupytext_version: 1.11.3
#   kernelspec:
#     display_name: Julia 1.7.2
#     language: julia
#     name: julia-1.7
# ---

include("ArgoToMITprof_step2.jl")

prof

# ## File Creation

using NCDatasets
using OrderedCollections

# +
fil2=joinpath(tempdir(),"test.nc")

iPROF = 10
iDEPTH = 55
iINTERP = 4
lTXT = 30

##

NCDataset(fil2,"c") do ds
    defDim(ds,"iINTERP",iINTERP)
    defDim(ds,"lTXT",lTXT)
    ds.attrib["title"] = "MITprof file created by ArgoData.jl (WIP)"
end

##

data = Array{Union{Missing, Float64}, 2}(undef, iPROF, iDEPTH)

#data = randn(iPROF,iDEPTH)
#data = reshape(prof["T"][1:iDEPTH],(1,iDEPTH))
#data = reshape(nomissing(prof["T"][1:iDEPTH],-9999.),(iPROF,iDEPTH))

##

[data[i,:].=prof["T"][1:iDEPTH] for i in 1:iPROF]

NCDataset(fil2,"a") do ds
  defVar(ds,"prof_T",data,("iPROF","iDEPTH"), 
        attrib = OrderedDict(
     "units" => "degree_Celsius",
     "_FillValue" => -9999.,
     "long_name" => "Temperature"
  ))
end

##

data1=Float64.(meta["depthLevels"])[1:iDEPTH]

NCDataset(fil2,"a") do ds
  defVar(ds,"prof_depth",data1,("iDEPTH",), 
        attrib = OrderedDict(
     "units" => "m",
     "_FillValue" => -9999.,
     "long_name" => "Depth"
  ))
end

##

data1=fill(prof["lon"],iPROF)

NCDataset(fil2,"a") do ds
  defVar(ds,"prof_lon",data1,("iPROF",), 
        attrib = OrderedDict(
     "units" => "degrees_east",
     "_FillValue" => -9999.,
     "long_name" => "Longitude (degree East)"
  ))
end


#[data[i,:].=prof["T"][1:iDEPTH] for i in 1:iPROF]

# -

# ## Example from file created in 2018

#
# ```
# netcdf argo_indian_2016_done_in_2018 {
# dimensions:
# 	iPROF = 35690 ;
# 	iDEPTH = 55 ;
# 	iINTERP = 4 ;
# 	lTXT = 30 ;
# variables:
# 	double prof_depth(iDEPTH) ;
# 		prof_depth:long_name = "depth" ;
# 		prof_depth:units = "me" ;
# 		prof_depth:missing_value = -9999. ;
# 		prof_depth:_FillValue = -9999. ;
# 	double prof_date(iPROF) ;
# 		prof_date:long_name = "Julian day since Jan-1-0000" ;
# 		prof_date:units = " " ;
# 		prof_date:missing_value = -9999. ;
# 		prof_date:_FillValue = -9999. ;
#
# ...
# ...
#
#     double prof_interp_weights(iPROF, iINTERP) ;
# 		prof_interp_weights:long_name = "interpolation variable" ;
# 		prof_interp_weights:units = "unknown" ;
# 		prof_interp_weights:missing_value = -9999. ;
# 		prof_interp_weights:_FillValue = -9999. ;
#
# // global attributes:
# 		:Format = "The contents of this MITprof file were processed \n",
# 			"using the MITprof matlab toolbox which can be obtained from \n",
# 			"http://mitgcm.org/viewvc/MITgcm/MITgcm_contrib/gael/profilesMatlabProcessing/" ;
# 		:date = "24-Feb-2018" ;        
# ```
#

# ## Documentation example

# +
# This creates a new NetCDF file /tmp/test.nc.
# The mode "c" stands for creating a new file (clobber)
ds = Dataset(joinpath(tempdir(),"test.nc"),"c")

# Define the dimension "lon" and "lat" with the size 100 and 110 resp.
defDim(ds,"lon",100)
defDim(ds,"lat",110)

# Define a global attribute
ds.attrib["title"] = "this is a test file"

# Define the variables temperature with the attribute units
v = defVar(ds,"temperature",Float32,("lon","lat"), attrib = OrderedDict(
    "units" => "degree Celsius"))

# add additional attributes
v.attrib["comments"] = "this is a string attribute with Unicode Ω ∈ ∑ ∫ f(x) dx"

# Generate some example data
data = [Float32(i+j) for i = 1:100, j = 1:110]

# write a single column
v[:,1] = data[:,1]

# write a the complete data set
v[:,:] = data

close(ds)
# -


