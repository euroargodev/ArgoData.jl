module ArgoData

function conda end
function pyimport end
function CondaPkgDev end
function get_climatology end

##

import Pkg
thistoml=joinpath(dirname(pathof(ArgoData)), "..", "Project.toml")
thisversion=Pkg.TOML.parsefile(thistoml)["version"]

##

include("data_structures.jl")
include("tools.jl")
include("GDAC.jl")
include("MITprof.jl")
include("MITprofAnalysis.jl")
include("ArgoFiles.jl")
import NetworkOptions

##

export GDAC, ArgoTools, GriddedFields
export MITprof, MITprofAnalysis, MITprofStat
export ProfileNative, ProfileStandard, MITprofStandard
export ArgoFiles, OneArgoFloat

## initialize data deps

#__init__() = begin
#    downloads.__init__standard_diags()
#end

end # module
