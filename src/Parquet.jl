
module Argo_parquet

using DataFrames, Dates, IntervalSets
import Dataverse, Downloads, Parquet2
import TableOperations as TO

import ArgoData: Argo_pq

## data structure

"""
    Dataset(folder_pq)

Open dataset as a `Argo_pq` data structure

```
folder_pq=Argo_parquet.sample_download("ARGO_PHY_SAMPLE_QC")
da=Argo_parquet.Dataset(folder_pq)
```

is equivalent to :

```
ds2 = Parquet2.Dataset(folder_pq)
### append all row groups (important step)
Parquet2.appendall!(ds2)
lst=Parquet2.filelist(ds2)
sch=Tables.schema(ds2)
Argo_pq(ds2,sch,lst,folder_pq)
```    
"""
function Dataset(folder_pq)
	ds2 = Parquet2.Dataset(folder_pq)
	### append all row groups (important step)
	Parquet2.appendall!(ds2)
	lst=Parquet2.filelist(ds2)
    sch=Tables.schema(ds2)
    Argo_pq(ds2,sch,lst,folder_pq)
end

## helper functions


"""
    sample_download(folder="ARGO_PHY_SAMPLE_QC")

Get sample data set from archive.
"""
function sample_download(folder="ARGO_PHY_SAMPLE_QC")
	folder_pq=joinpath(tempdir(),folder)
	if !isdir(folder_pq)
		url="https://zenodo.org/records/15198578/files/$(folder).zip?download=1"
		fil_zip=joinpath(tempdir(),"$(folder).zip")
		Downloads.download(url,fil_zip)
		Dataverse.unzip(fil_zip)
	end
    folder_pq
end

"""
    get_subset_region(ds2::Parquet2.Dataset; lons=-75 .. -50, lats=25 .. 40, 
    dates=DateTime("2001-01-01T00:00:00") .. DateTime("2024-12-31T23:59:59"),
    variables=(:JULD, :LATITUDE, :LONGITUDE, :PRES, :TEMP, :PLATFORM_NUMBER))
"""
    get_subset_float(ds2::Parquet2.Dataset ; ID=3901064,
    variables=(:JULD, :LATITUDE, :LONGITUDE, :PRES, :TEMP, :PLATFORM_NUMBER))
    rule_PLATFORM_NUMBER = x -> coalesce.(x, 0).==Ref(string(ID))
"""
function get_subset_region(ds2::Parquet2.Dataset; 
    lons=-75 .. -50, 
    lats=25 .. 40, 
    dates=DateTime("2001-01-01T00:00:00") .. DateTime("2024-12-31T23:59:59"),
    variables=(:JULD, :LATITUDE, :LONGITUDE, :PRES, :TEMP, :PLATFORM_NUMBER),
    verbose=true)

    # Define filtering rules
    rule_juld = x -> in.(coalesce.(x, DateTime("2100-01-01T00:00:00")), Ref(dates))
    rule_latitude = x -> in.(coalesce.(x, NaN), Ref(lats))
    rule_longitude = x -> in.(coalesce.(x, NaN), Ref(lons))
    
    # Check which row groups contain relevant data
    rule_row_group = x ->   any(rule_latitude(Parquet2.load(x["LATITUDE"]))) && 
                            any(rule_longitude(Parquet2.load(x["LONGITUDE"]))) && 
                            any(rule_juld(Parquet2.load(x["JULD"])))

    row_groups = filter(rule_row_group, ds2.row_groups)
    
    if verbose
        println("Found $(length(row_groups)) matching row groups out of $(length(ds2.row_groups))")
    end
    
    if isempty(row_groups)
        if verbose
            println("No data found in specified region/time range")
        end
        return DataFrame([col => [] for col in variables]...)
    end
    
    # Process row groups one at a time and filter immediately
    filtered_dfs = DataFrame[]
    
    for (i, rg) in enumerate(row_groups)
        if verbose && i % 10 == 0
            println("Processing row group $i/$(length(row_groups))...")
        end
        
        # Load only this row group
        df_temp = DataFrame(rg, copycols=false)
        df_temp = select(df_temp, variables...)
        
        # Filter immediately before accumulating
        subset!(df_temp, :LATITUDE => rule_latitude, skipmissing=false)
        subset!(df_temp, :LONGITUDE => rule_longitude, skipmissing=false)
        subset!(df_temp, :JULD => rule_juld, skipmissing=false)
        
        # Only keep if there's data left after filtering
        if nrow(df_temp) > 0
            push!(filtered_dfs, df_temp)
        end
    end
    
    if isempty(filtered_dfs)
        if verbose
            println("No data matched filters after detailed filtering")
                    end
        return DataFrame([col => [] for col in variables]...)
    end
    
    # Combine only the filtered results
    if verbose
        println("Combining $(length(filtered_dfs)) filtered row groups...")
    end
    
    df_result = vcat(filtered_dfs..., cols=:union)
    
    if verbose
        println("Final result: $(nrow(df_result)) rows")
    end
    
    return df_result
end
"""
    get_lon_lat_temp(df3)
"""
function get_lon_lat_temp(df3::DataFrame)
    gdf3=groupby(df3,:JULD)
    lo=[x[1,:LONGITUDE] for x in gdf3]
    la=[x[1,:LATITUDE] for x in gdf3];
    te=[x[1,:TEMP] for x in gdf3];
    ii=findall((!ismissing).(te))
    (lo[ii],la[ii],Float64.(te[ii]))
end

"""
    get_positions(df3)
"""
function get_positions(df3::DataFrame)
    lo = Tables.getcolumn(df3, :LONGITUDE)
    la = Tables.getcolumn(df3, :LATITUDE)
    juld = Tables.getcolumn(df3, :JULD)
    pos3=[(lo[i],la[i],juld[i]) for i in 1:length(lo)]
    pos3=unique(pos3)
    ([a[1] for a in pos3],
    [a[2] for a in pos3],
    [a[3] for a in pos3])
end

end
