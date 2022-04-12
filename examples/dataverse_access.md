
### 1) on a linux computer, create `names` and `ids` lists

```
#!/bin/sh

FILES=$(curl -s https://dataverse.harvard.edu/api/datasets/:persistentId?persistentId=doi:10.7910/DVN/EE3C40 | ./jq '.data.latestVersion.files[].dataFile.id')
FILENAMES=$(curl -s https://dataverse.harvard.edu/api/datasets/:persistentId?persistentId=doi:10.7910/DVN/EE3C40 | ./jq '.data.latestVersion.files[].dataFile.filename')

echo $FILES > file_ids.csv
echo $FILENAMES > file_names.csv

#for i in $FILES; do
# echo "wget --content-disposition https://dataverse.harvard.edu/api/access/datafile/$i"
#done
```

### 2) in julia, combine the lists in a `csv` file

```
using CSV, DataFrames
df1 = CSV.File("file_ids.csv",transpose=true,header=0) |> DataFrame
df2 = CSV.File("file_names.csv",transpose=true,header=0) |> DataFrame
df = DataFrame(ID=df1[!,:Column1],name=df2[!,:Column1])
CSV.write("files.csv", df)
```

### 3) access file in julia

```
fil="MITprof_mar2016_argo9506.nc"
tmp = CSV.File("dataverse_files.csv") |> DataFrame
ii=findall(tmp[:,:name].==fil)

run(`wget --content-disposition https://dataverse.harvard.edu/api/access/datafile/$(tmp[ii,:ID])`)

run(`ls $(tmp[ii,:name])`)
```
