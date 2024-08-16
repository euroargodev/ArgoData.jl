module ArgoDataPyCallExt

using PyCall, ArgoData

function ArgoData.pyimport(flag=:argopy)
    if flag==:argopy
        PyCall.pyimport("argopy")
    else
        @warn "unknown flag value   "
    end
end

end
