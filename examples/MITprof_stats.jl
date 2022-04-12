
module MITprof_stats

using ArgoData, DataFrames, CSV, Dates, GLMakie

"""
    plot_stats()

Read file `profile_positions.csv`, pre-process, and then compute 
and display basic statistics of the Argo float array.
"""
function plot_stats()
    csv_file="profile_positions.csv"
    df=CSV.read(csv_file,DataFrame)

    #time variable = year + (month-1/2)/12 :
    df.ym=year.(df.date)+(month.(df.date) .-0.5)/12

    #eliminate problematic data points:
    l0=size(df,1)
    df=df[df.lat .> -89.99,:]
    df=df[df.date .> DateTime(1000,1,1),:]
    l1=size(df,1)
    df=df[df.date .< DateTime(2022,4,1),:]
    l2=size(df,1)

    #display basic statistics of the Argo float array:
    plot_stats(df)
end

"""
    plot_stats(df::DataFrame; ym1=2004+(12-0.5)/12,ym2=2021+(12-0.5)/12)

Call `plot_stats` with `df` already in memory. Please refer to the `plot_stats()` 
source code for documentation on how to load `df`.
"""
function plot_stats(df::DataFrame; ym1=2004+(12-0.5)/12,ym2=2021+(12-0.5)/12)
    txt(ym) = string(Int(floor(ym)))*"/"*string(Int(round((ym-floor(ym))*12+0.5)))
    
    #ii=findall(peryear[:,:year].>1900)

    gdf=groupby(df,:ym)
    df2=combine(gdf) do df
        (m = length(df.ID), n = length(unique(df.ID)))
    end
    sort!(df2, [:ym])

    f = Figure()

    ax1 = Axis(f[1,1], title="number of profiles per day")
    lines!(ax1,df2[:,:ym],df2[:,:m]/365)
    lines!(ax1,[ym1,ym1],[0,50],color=:red,linestyle=:dash)
    lines!(ax1,[ym2,ym2],[0,50],color=:red,linestyle=:dash)
    ylims!(ax1, (0, 50))

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

end #module MITprof_stats
