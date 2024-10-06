module ArgoDataClimatologyExt

using ArgoData, Climatology
import Climatology: MeshArrays
import ArgoData: get_climatology

function get_climatology(msk)
    pth=Climatology.MITPROFclim_download()
    T=MonthlyClimatology(joinpath(pth,"T_OWPv1_M_eccollc_90x50.bin"),msk)
    S=MonthlyClimatology(joinpath(pth,"S_OWPv1_M_eccollc_90x50.bin"),msk)
    σT=AnnualClimatology(joinpath(pth,"sigma_T_nov2015.bin"),msk)
    σS=AnnualClimatology(joinpath(pth,"sigma_S_nov2015.bin"),msk)
    (T,S,σT,σS)
end

function MonthlyClimatology(fil,msk)
    fid = open(fil)
    tmp = Array{Float32,4}(undef,(90,1170,50,12))
    read!(fid,tmp)
    tmp = hton.(tmp)
    close(fid)

    T=Array{MeshArrays.MeshArray,1}(undef,12)
    for tt=1:12
        T[tt]=msk*MeshArrays.read(tmp[:,:,:,tt],msk.grid)
    end
    return T
end

function AnnualClimatology(fil,msk)
    fid = open(fil)
    tmp=Array{Float32,3}(undef,(90,1170,50))
    read!(fid,tmp)
    tmp = hton.(tmp)
    close(fid)

    T=MeshArrays.MeshArray(msk.grid,Float64,50)
    T=msk*MeshArrays.read(convert(Array{Float64},tmp),T)
    return T
end

end



