module ArgoData

import Pkg
thistoml=joinpath(dirname(pathof(ArgoData)), "..", "Project.toml")
thisversion=Pkg.TOML.parsefile(thistoml)["version"]

include("data_structures.jl")
include("tools.jl")
include("GDAC.jl")
include("MITprof.jl")
include("MITprofAnalysis.jl")

export GDAC, ArgoTools, GriddedFields
export MITprof, MITprofAnalysis, MITprofStat, AnalysisMethods
export ProfileNative, ProfileStandard, MITprofStandard

end # module
