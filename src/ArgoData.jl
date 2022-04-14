module ArgoData

import Pkg
thistoml=joinpath(dirname(pathof(ArgoData)), "..", "Project.toml")
thisversion=Pkg.TOML.parsefile(thistoml)["version"]

include("data_structures.jl")

include("tools.jl")
include("GDAC.jl")
include("MITprof.jl")

export MITprof, GDAC, ArgoTools, GriddedFields, AnalysisMethods
export ProfileNative, ProfileStandard, MITprofStandard

end # module
