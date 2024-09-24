module ArgoDataCondaPkgExt

using CondaPkg, ArgoData

function ArgoData.conda(flag=:argopy)
    if flag==:argopy
        CondaPkg.add("xarray",version=">=0.18,<2024.3")
        CondaPkg.add("argopy")
    else
        error("unknown option")
    end
end

end
