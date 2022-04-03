

@everywhere using ArgoData
@everywhere path=joinpath(tempdir(),"Argo_DAC_files")
@everywhere fil=joinpath(path,"Argo_float_files.csv")
#@everywhere ftp="ftp://usgodae.org/pub/outgoing/argo/dac/"

!isdir(path) ? mkdir(path) : nothing

if !isfile(fil)
    files_list=GDAC.files_list()
    path=joinpath(tempdir(),"Argo_DAC_files")
    !isdir(path) ? mkdir(path) : nothing
    GDAC.CSV.write(joinpath(path,"Argo_float_files.csv"),files_list)
end

@everywhere files_list=GDAC.DataFrame(GDAC.CSV.File(fil))

for i in unique(files_list[:,:folder])
    !isdir(joinpath(path,i)) ? mkdir(joinpath(path,i)) : nothing
end

@everywhere n=10
@everywhere N=0
while N<1 #size(files_list,1)
    @sync @distributed for m in 1:nworkers()
        ii=collect(N + (m-1)*n .+ (1:n))
        println(ii[1])
        #[Argo_float_download(files_list[i,:],"prof",ftp) for i in ii];
        [GDAC.download_file(files_list[i,:],"prof") for i in ii];
    end
    @everywhere N=N+n*nworkers()
end
