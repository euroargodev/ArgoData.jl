module ArgoData

include("data_structures.jl")

include("tools.jl")
include("GDAC.jl")
include("MITprof.jl")

export MITprof, GDAC, ArgoTools, GriddedFields
export ProfileNative, ProfileStandard, MITprofStandard

end # module
