module ArgoDataCondaExt

using Conda, ArgoData

function ArgoData.conda(flag=:argopy)
    if flag==:argopy
        Conda.add("argopy")
#        Conda.pip_interop(true)
#        Conda.pip("install", "argopy")
    end
end

end
