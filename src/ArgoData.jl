module ArgoData

include("data_structures.jl")

include("tools.jl")
include("MITprof.jl")
include("GDAC.jl")

export MITprof, GDAC, ArgoTools, GriddedFields
export ProfileNative, ProfileStandard

end # module
