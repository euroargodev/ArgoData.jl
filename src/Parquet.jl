
module Argo_parquet

using DataFrames, Dates, IntervalSets
import Dataverse, Downloads, Parquet2
import TableOperations as TO

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

function get_subset_region(ds2; lons=-75 .. -50, lats=25 .. 40, 
    dates=DateTime("2018-01-01T00:00:00") .. DateTime("2018-12-31T23:59:59"),
    variables=(:JULD, :LATITUDE, :LONGITUDE, :PRES, :TEMP, :PLATFORM_NUMBER))

    rule_juld = x -> in.(coalesce.(x, DateTime("2100-01-01T00:00:00")), Ref(dates))
    rule_latitude = x -> in.(coalesce.(x, NaN), Ref(lats))
    rule_longitude = x -> in.(coalesce.(x, NaN), Ref(lons))
    rule_row_group = x ->   any(rule_latitude(Parquet2.load(x["LATITUDE"]))) && 
                            any(rule_longitude(Parquet2.load(x["LONGITUDE"]))) && 
                            any(rule_juld(Parquet2.load(x["JULD"])))

    row_groups = filter(rule_row_group, ds2.row_groups)
    df_subset2 = reduce(vcat,DataFrame.(row_groups,copycols=false)) |> TO.select(variables...) |> DataFrame
    subset!(df_subset2, :LATITUDE => rule_latitude)
    subset!(df_subset2, :LONGITUDE => rule_longitude)
    subset!(df_subset2, :JULD => rule_juld)
    df_subset2
end

function get_subset_float(ds2 ; ID=3901064,
    variables=(:JULD, :LATITUDE, :LONGITUDE, :PRES, :TEMP, :PLATFORM_NUMBER))
    rule_PLATFORM_NUMBER = x -> coalesce.(x, 0).==Ref(string(ID))
#	rule_PLATFORM_NUMBER = x -> coalesce.(x, 0).==Ref(ID)
    row_groups = filter(x -> any(rule_PLATFORM_NUMBER(Parquet2.load(x["PLATFORM_NUMBER"]))), ds2.row_groups)
    df_subset3 = reduce(vcat,DataFrame.(row_groups,copycols=false)) |> TO.select(variables...) |> DataFrame
    subset!(df_subset3, :PLATFORM_NUMBER => rule_PLATFORM_NUMBER)
    df_subset3
end

function get_lon_lat_temp(df3)
    gdf3=groupby(df3,:JULD)
    lo=[x[1,:LONGITUDE] for x in gdf3]
    la=[x[1,:LATITUDE] for x in gdf3];
    te=[x[1,:TEMP] for x in gdf3];
    ii=findall((!ismissing).(te))
    (lo[ii],la[ii],Float64.(te[ii]))
end

end
