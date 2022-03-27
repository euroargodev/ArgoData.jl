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
#

MITprof.MITprof_write(meta,[prof,prof,prof],[prof_std,prof_std,prof_std])

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

# ## Variables List
#
# ```
# 	double prof_depth(iDEPTH) ;
# 	double prof_date(iPROF) ;
# 	double prof_YYYYMMDD(iPROF) ;
# 	double prof_HHMMSS(iPROF) ;
#     
# 	double prof_lon(iPROF) ;
# 	double prof_lat(iPROF) ;
# 	double prof_basin(iPROF) ;
# 	double prof_point(iPROF) ;
#     
# 	double prof_T(iPROF, iDEPTH) ;
# 	double prof_Tweight(iPROF, iDEPTH) ;
# 	double prof_Testim(iPROF, iDEPTH) ;
# 	double prof_Terr(iPROF, iDEPTH) ;
# 	double prof_Tflag(iPROF, iDEPTH) ;
#     
# 	double prof_S(iPROF, iDEPTH) ;
# 	double prof_Sweight(iPROF, iDEPTH) ;
# 	double prof_Sestim(iPROF, iDEPTH) ;
# 	double prof_Serr(iPROF, iDEPTH) ;
# 	double prof_Sflag(iPROF, iDEPTH) ;
#     
# 	double prof_interp_XC11(iPROF) ;
# 	double prof_interp_YC11(iPROF) ;
# 	double prof_interp_XCNINJ(iPROF) ;
# 	double prof_interp_YCNINJ(iPROF) ;
# 	double prof_interp_i(iPROF, iINTERP) ;
# 	double prof_interp_j(iPROF, iINTERP) ;
# 	double prof_interp_lon(iPROF, iINTERP) ;
# 	double prof_interp_lat(iPROF, iINTERP) ;
# 	double prof_interp_weights(iPROF, iINTERP) ;
# ```


