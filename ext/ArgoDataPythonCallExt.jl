module ArgoDataPythonCallExt

using PythonCall, ArgoData

function ArgoData.pyimport(flag=:argopy)
    if flag==:argopy
        PythonCall.pyimport("argopy")
    else
        @warn "unknown flag value   "
    end
end

end
