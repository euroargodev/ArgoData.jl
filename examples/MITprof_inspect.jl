
module MITprof_inspect

using JLD2, Statistics

import GLMakie as Mkie

#trim_cost is used in plot_cost
function trim_cost(cost)
    ii=findall((!ismissing).(cost) .&& (isfinite).(cost) .&& (cost.>0.0))
    med=round(median(cost[ii]), digits=3)
    nb=length(ii)

    (ncost,nii)=(length(cost),length(ii))
    println("keeping $(ncost), leaving $(ncost-nii)")
    println("median $(median(cost[ii]))")
    
    cost[ii],med,nb
end

"""
    plot_cost()

```
f=MITprof_inspect.plot_cost()
save("cost_pdf.png", f)
```
"""
function plot_cost()
    #
    costT=load("prof_T_stats.jld2","cost")
    costT,medT,nbT=trim_cost(costT)
    #
    costS=load("prof_S_stats.jld2","cost")
    costS,medS,nbS=trim_cost(costS)

    f = Mkie.Figure()
    Mkie.hist(f[1, 1], costT, bins = collect(0:0.1:8.0), 
        axis = (title = "cost for T (median=$(medT), from $(nbT))",), 
        color = :values, strokewidth = 1, strokecolor = :black)

    Mkie.hist(f[2, 1], costS, bins = collect(0:0.1:8.0), 
        axis = (title = "cost for S (median=$(medS), from $(nbS))",),
        color = :values, strokewidth = 1, strokecolor = :black)

    f
end

end
