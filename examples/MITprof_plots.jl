
module MITprofPlots

using ArgoData, DataFrames, CSV, Dates, GLMakie, JLD2, Statistics

#trim_cost is used in MITprofPlots.cost
function trim_cost(cost)
    ii=findall((!ismissing).(cost) .&& (isfinite).(cost) .&& (cost.>0.0))
    med=round(median(cost[ii]), digits=3)
    nb=length(ii)

    (ncost,nii)=(length(cost),length(ii))
    println("keeping $(nii), leaving $(ncost-nii)")
    println("median $(median(cost[ii]))")
    println("mean $(mean(cost[ii]))")
    println("max $(maximum(cost[ii]))")
    
    cost[ii],med,nb
end

"""
    cost_functions()

```
f=MITprofPlots.cost_functions()
save("cost_pdf.png", f)
```
"""
function cost_functions()
    #
    costT=load("csv/prof_T_stats.jld2","cost")
    costT,medT,nbT=trim_cost(costT)
    #
    costS=load("csv/prof_S_stats.jld2","cost")
    costS,medS,nbS=trim_cost(costS)

    f = Figure()
    hist(f[1, 1], costT, bins = collect(0:0.1:8.0), 
        axis = (title = "cost for T (median=$(medT), from $(nbT))",), 
        color = :values, strokewidth = 1, strokecolor = :black)

    hist(f[2, 1], costS, bins = collect(0:0.1:8.0), 
        axis = (title = "cost for S (median=$(medS), from $(nbS))",),
        color = :values, strokewidth = 1, strokecolor = :black)

    f
end

"""
    array_status()

Read file `profile_positions.csv`, pre-process, and then compute 
and display basic statistics of the Argo float array.

```
f=MITprofPlots.array_status()
save("ArgoDistributions.png", f)
```
"""
function array_status(csv_file="csv/profile_positions.csv")
    #read csv file
    csv_file="csv/profile_positions.csv"
    df=CSV.read(csv_file,DataFrame)

    #add ym time variable = year + (month-1/2)/12 :
    df.ym=year.(df.date)+(month.(df.date) .-0.5)/12
    
    #eliminate problematic data points:
    df=df[df.lat .> -89.99,:]
    df=df[df.date .> DateTime(1000,1,1),:]
    df=df[df.date .< DateTime(2022,4,1),:]
        
    #display basic statistics of the Argo float array:
    array_status(df)
end

"""
    array_status(df::DataFrame; ym1=2004+(12-0.5)/12,ym2=2021+(12-0.5)/12)

Call `array_status` with `df` already in memory. Please refer to the `array_status()` 
source code for documentation on how to load `df`.
"""
function array_status(df::DataFrame; ym1=2004+(12-0.5)/12,ym2=2021+(12-0.5)/12)
    txt(ym) = string(Int(floor(ym)))*"/"*string(Int(round((ym-floor(ym))*12+0.5)))
    
    #ii=findall(peryear[:,:year].>1900)

    gdf=groupby(df,:ym)
    df2=combine(gdf) do df
        (m = length(df.ID), n = length(unique(df.ID)))
    end
    sort!(df2, [:ym])

    ##
    
    f = Figure()

    ax1 = Axis(f[1,1], title="number of profiles per day")
    lines!(ax1,df2[:,:ym],df2[:,:m]/30)
    lines!(ax1,[ym1,ym1],[0,600],color=:red,linestyle=:dash)
    lines!(ax1,[ym2,ym2],[0,600],color=:red,linestyle=:dash)
    ylims!(ax1, (0, 600))

    ax2 = Axis(f[1,2], title="number of profilers at sea")
    barplot!(ax2,df2.ym,df2.n)
    lines!(ax2,[ym1,ym1],[0,5000],color=:red,linestyle=:dash)
    lines!(ax2,[ym2,ym2],[0,5000],color=:red,linestyle=:dash)
    ylims!(ax2, (0, 5000))

    ax3 = Axis(f[2,1], title="profile positions for "*txt(ym1))
    tmp=df[df.ym.==ym1,:]
    scatter!(ax3,tmp.lon,tmp.lat,markersize=3)
    xlims!(ax3, (-180, 180)); ylims!(ax3, (-90, 90))

    ax4 = Axis(f[2,2], title="profile positions for "*txt(ym2))
    tmp=df[df.ym.==ym2,:]
    scatter!(ax4,tmp.lon,tmp.lat,markersize=3)
    xlims!(ax4, (-180, 180)); ylims!(ax4, (-90, 90))

	f
end

"""
    stat_map(df::DataFrame,G::NamedTuple)

```
G=GriddedFields.load()
df=CSV.read("csv/profile_positions.csv",DataFrame)
#MITprofAnalysis.profile_add_level!(df,5)
#df1=profile_trim(df)

MITprofPlots.stat_map(df,G)
```
"""
function stat_map(df::DataFrame,G::NamedTuple)
    gdf=groupby(df,:pos)
    df2=combine(gdf) do df
        (m = log10(length(df.ID)), lon=mean(df.lon), lat=mean(df.lat))
    end

    tmp1=fill(0.0,(90,1170))
    ii=fill(0,2)
    for i in 1:size(df2,1)
        ii.=parse.(Int,split(split(split(df2[i,:pos],"(")[2],")")[1],","))
        tmp1[ii[1],ii[2]]=df2[i,:m]
    end

    #GriddedFields.MeshArrays.read(tmp1,G.msk.grid)
    XC=GriddedFields.MeshArrays.write(G.Γ.XC)
    YC=GriddedFields.MeshArrays.write(G.Γ.YC)
    ii=findall((!).(tmp1.==0))

    f = Figure()

    ax1 = Axis(f[1,1], title="number of profiles per day")
    scatter!(ax1,XC[ii],YC[ii],color=tmp1[ii])
    xlims!(ax1, -180, 180)
    ylims!(ax1, -90, 90)

    #(XC,YC,tmp1,f)
    f
end

end
