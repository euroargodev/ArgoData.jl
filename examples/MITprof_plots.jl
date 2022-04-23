
module MITprofPlots

using ArgoData, DataFrames, Dates, Statistics
using CairoMakie
import CSV, JLD2

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

Read file `csv/profile_positions.csv`, pre-process, and then compute 
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
    stat_map(df::DataFrame,G::NamedTuple,var::Symbol,sta::Symbol; func=(x->x), rng=(), n0=0)

Compute and display map of statistic `sta` of variable `var` from DataFrame `df` on the 
grid provided by `G`. Options : `func` = function to apply on the gridded statistic;
`rng` = color range for plotting; `n0` = mask out statistic if observations are fewer than `n0`.

```
using ArgoData
#include("examples/MITprof_plots.jl")

df=MITprofAnalysis.read_pos_level(10)
df=MITprofAnalysis.trim(df)
G=GriddedFields.load()

MITprofPlots.stat_map(df,G,:Td,:median; rng=(-1.0,1.0),n0=3)

#MITprofPlots.stat_map(df,G,:Td,:n)
#MITprofPlots.stat_map(df,G,:Td,:var; rng=(0.0,3.0),func=sqrt)
#MITprofPlots.stat_map(df,G,:Td,:var; rng=(0.0,3.0),func=sqrt,n0=3)
```
"""
function stat_map(df::DataFrame,G::NamedTuple,va::Symbol,sta::Symbol; func=(x->x), rng=(), n0=0)

    ar=G.array()
    MITprofAnalysis.stat_grid!(ar,df,va,sta,func=func)
    ar[ismissing.(ar)].=NaN

    n=G.array()
    MITprofAnalysis.stat_grid!(n,df,va,:n)
    n[ismissing.(n)].=0.0

    ar[n .<=n0].=NaN
    ttl="variable, statistic = "*string(va)*","*string(sta)

    stat_map(ar,G; rng=rng,ttl=ttl)    
end

function stat_map(ar::Array,G::NamedTuple; rng=(),ttl="")
    ar[ismissing.(ar)].=NaN
    ar1=Float64.(ar)

    ii=findall( (!isnan).(ar1) )
    isempty(rng) ? colorrange=extrema(ar1[ii]) : colorrange=rng
    XC=GriddedFields.MeshArrays.write(G.Γ.XC)
    YC=GriddedFields.MeshArrays.write(G.Γ.YC)

    f = Figure()
    ax1 = Axis(f[1,1], title=ttl)
    sc1 = scatter!(ax1,XC[ii],YC[ii],color=ar1[ii],colorrange=colorrange,markersize=3)
    xlims!(ax1, -180, 180)
    ylims!(ax1, -90, 90)

    Colorbar(f[1,2],sc1)

    f
end


using NCDatasets

function stat_map_combine(G,level=5)
    ar2=G.array(); ar2.=NaN
    level<10 ? lev="0"*string(level) : lev=string(level)

    list=(  "np30nw5","np18nw5","np10nw5","np5nw5","np3nw5",
            "np3nw3","np3nw1","np1nw3","np1nw1")
    for i in list
        ds = NCDataset("stat_output/δT_$(lev)_$(i).nc")
        ar3=ds["δT"][:,:,120]; ii=findall((!isnan).(ar3))
        ar2[ii].=ar3[ii]
        close(ds)
    end

    γ=G.Γ.XC.grid
    ar1=ar2.*γ.write(G.msk[:,1])
    MITprofPlots.stat_map(ar1,G,rng=(-1.0,1.0))
end

end
