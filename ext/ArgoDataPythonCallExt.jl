module ArgoDataPythonCallExt

using PythonCall, ArgoData
import ArgoData: NetworkOptions

function ArgoData.pyimport(flag=:argopy)
    if flag==:argopy
#        @py import ssl
#        p=ssl.get_default_verify_paths()
#        string(p.cafile)
#        println(cafile)
        cafile=NetworkOptions.ca_roots_path()
        ENV["SSL_CERT_FILE"] = cafile
        PythonCall.pyimport("argopy")
#        withenv("SSL_CERT_FILE"=>cafile) do
#            PythonCall.pyimport("argopy")
#        end
    else
        @warn "unknown flag value   "
    end
end

end
