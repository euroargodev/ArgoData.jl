module ArgoDataMakieExt

using ArgoData, Makie
import Makie: plot

"""
    plot(x::OneArgoFloat; option=:standard, markersize=2,pol=Any[],size=(900,600)

Default plot for OneArgoFloat (see https://argopy.readthedocs.io/en/latest/what_is_argo.html#what-is-argo).

- option=:standard , :samples, or :ts
- size let's you set the figure dimensions
- pol is a set of polygons (e.g., continents) 

```
using ArgoData, CairoMakie
argo=read(OneArgoFloat,wmo=2900668)

f1=plot(argo,option=:samples)
f2=plot(argo,option=:TS)
f3=plot(argo,option=:standard)
```
"""
plot(x::OneArgoFloat; option=:standard, markersize=2,pol=Any[],size=(900,600)) = begin
	if option==:standard
		T_std,S_std=ArgoFiles.interp_z_all(x.data)
		spd=ArgoFiles.speed(x.data)
		plot_standard(x.ID,x.data,spd,T_std,S_std; markersize=markersize, pol=pol, size=size)
	elseif option==:samples
		plot_samples(x.data,x.ID)
	elseif option==:TS
		plot_TS(x.data,x.ID)
	end
end

function plot_TS(arr,wmo)
	fig1=Figure(size=(600,600))
	ax=Axis(fig1[1,1],title="Float wmo="*string(wmo),xlabel="Salinity",ylabel="Temperature")
	scatter!(ax,arr.PSAL[:],arr.TEMP[:],markersize=2.0)
	fig1
end

function plot_samples(arr,wmo;ylims=(-2000.0, 0.0))
	
	fig1=Figure(size = (1200, 900))
	lims=(nothing, nothing, ylims...)

	ttl="Float wmo="*string(wmo)
	ax=Axis(fig1[1,1],title=ttl*", temperature, degree C", limits=lims)
	hm1=plot_profiles!(ax,arr.TIME,arr.PRES,arr.TEMP,:thermal)
	Colorbar(fig1[1,2], hm1, height=Relative(0.65))

	ax=Axis(fig1[2,1],title=ttl*", salinity, psu", limits=lims)
	hm2=plot_profiles!(ax,arr.TIME,arr.PRES,arr.PSAL,:viridis)
	Colorbar(fig1[2,2], hm2, height=Relative(0.65))

	fig1
end

function heatmap_profiles!(ax,TIME,TEMP,cmap)
	x=TIME[1,:]; y=collect(0.0:5:500.0)
	co=Float64.(permutedims(TEMP))
	rng=extrema(TEMP[:])
	sca=heatmap!(ax, x , y , co, colorrange=rng,colormap=cmap)
	ax.ylabel="depth (m)"
	sca
end

function plot_profiles!(ax,TIME,PRES,TEMP,cmap)
	ii=findall(((!ismissing).(PRES)).*((!ismissing).(TEMP)))

	x=TIME[ii]
	y=-PRES[ii] #pressure in decibars ~ depth in meters
	co=Float64.(TEMP[ii])
	rng=extrema(co)

	sca=scatter!(ax, x , y ,color=co,colormap=cmap, markersize=5)

	ax.xlabel="time (day)"
	ax.ylabel="depth (m)"

	sca
end

function plot_trajectory!(ax,lon,lat,co;
		markersize=2,linewidth=3, pol=Any[],xlims=(-180,180),ylims=(-90,90),title="")
	li=lines!(ax,lon, lat, linewidth=linewidth, color=co, colormap=:turbo)
	scatter!(ax,lon, lat, marker=:circle, markersize=markersize, color=:black)
	!isempty(pol) ? [lines!(ax,l1,color = :black, linewidth = 0.5) for l1 in pol] : nothing
	ax.xlabel="longitude";  ax.ylabel="latitude"; ax.title=title
	xlims!(xlims...); ylims!(ylims...)
	li
end

xrng(lon)=begin
	a=[floor(minimum(skipmissing(lon))) ceil(maximum(skipmissing(lon)))]
	dx=max(diff(a[:])[1],10)
	b=(a[2]>180 ? +180 : 0)
	(max(a[1]-dx/2,-180+b),min(a[2]+dx/2,180+b))
end
yrng(lat)=begin
	a=[floor(minimum(skipmissing(lat))) ceil(maximum(skipmissing(lat)))]
	dx=max(diff(a[:])[1],10)
	b=(max(a[1]-dx/2,-90),min(a[2]+dx/2,90))
end

function plot_standard(wmo,arr,spd,T_std,S_std; markersize=2,pol=Any[],size=(900,600))

	xlims=xrng(arr.lon)
	ylims=yrng(arr.lat)
	
	fig1=Figure(size=size)

	ax=Axis(fig1[1,1])
	li1=plot_trajectory!(ax,arr.lon,arr.lat,arr.TIME[1,:];
		linewidth=5,pol=pol,xlims=xlims,ylims=ylims,
		title="time since launch, in days")
	Colorbar(fig1[1,2], li1, height=Relative(0.65))

	ax=Axis(fig1[1,3])
	li2=plot_trajectory!(ax,arr.lon,arr.lat,spd.speed;
		linewidth=5,pol=pol,xlims=xlims,ylims=ylims,
		title="estimated speed (m/s)")
	Colorbar(fig1[1,4], li2, height=Relative(0.65))

	ax=Axis(fig1[2,1:3],title="Temperature, °C")
	hm1=heatmap_profiles!(ax,arr.DATE,T_std,:thermal)
	Colorbar(fig1[2,4], hm1, height=Relative(0.65))
	ylims!(ax, 500, 0)

	ax=Axis(fig1[3,1:3],title="Salinity, [PSS-78]")
	hm2=heatmap_profiles!(ax,arr.DATE,S_std,:viridis)
	Colorbar(fig1[3,4], hm2, height=Relative(0.65))
	ylims!(ax, 500, 0)

	rowsize!(fig1.layout, 1, Relative(1/2))

	fig1
end

end



