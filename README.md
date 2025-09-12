
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ducklake

ducklake is an R package which complements the existing toolkits in the
[duckdb](https://r.duckdb.org/index.html) and
[duckplyr](https://duckplyr.tidyverse.org/index.html) packages, in order
to support the new
[DuckLake](https://ducklake.select/docs/stable/duckdb/introduction.html)
ecosystem.

## Installation

Install the development version of ducklake with

``` r
pak::pak("tgerke/ducklake")
```

## Create a local duckdb lakehouse

``` r
library(ducklake)

# install the ducklake extension to duckdb 
# requires that you already have DuckDB v1.3.0 or higher
install_ducklake()

# set up a temporary directory to demonstrate use
temp_dir <- tempdir()
# haha Jenny Bryan is going to set my computer on fire
setwd(temp_dir)

# create the ducklake
attach_ducklake("my_ducklake")
# show that we have ducklake files
list.files()
#> [1] "duckplyr"                 "my_ducklake.ducklake"    
#> [3] "my_ducklake.ducklake.wal"

# create a table using the Netherlands train traffic dataset 
create_table("nl_train_stations", "https://blobs.duckdb.org/nl_stations.csv")
# show that we now have a .files directory
list.files()
#> [1] "duckplyr"                   "my_ducklake.ducklake"      
#> [3] "my_ducklake.ducklake.files" "my_ducklake.ducklake.wal"
# main/ is where the parquet files go
list.files("my_ducklake.ducklake.files/main/")
#> [1] "nl_train_stations"

# connect to the ducklake
con <- duckdb::dbConnect(
  duckdb::duckdb(
    dbdir = paste0(temp_dir, "/my_ducklake.ducklake"),
    read_only = FALSE
  )
)

# list tables in the metadata store
duckdb::dbListTables(con)
#>  [1] "ducklake_column"                      
#>  [2] "ducklake_column_mapping"              
#>  [3] "ducklake_column_tag"                  
#>  [4] "ducklake_data_file"                   
#>  [5] "ducklake_delete_file"                 
#>  [6] "ducklake_file_column_statistics"      
#>  [7] "ducklake_file_partition_value"        
#>  [8] "ducklake_files_scheduled_for_deletion"
#>  [9] "ducklake_inlined_data_tables"         
#> [10] "ducklake_metadata"                    
#> [11] "ducklake_name_mapping"                
#> [12] "ducklake_partition_column"            
#> [13] "ducklake_partition_info"              
#> [14] "ducklake_schema"                      
#> [15] "ducklake_snapshot"                    
#> [16] "ducklake_snapshot_changes"            
#> [17] "ducklake_table"                       
#> [18] "ducklake_table_column_stats"          
#> [19] "ducklake_table_stats"                 
#> [20] "ducklake_tag"                         
#> [21] "ducklake_view"
```

This next section is dev/WIP!

``` r
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

# Find the Parquet file path for our table
train_stations_path <- get_table_path("nl_train_stations", con)
train_stations_path
#> [1] "my_ducklake.ducklake.files/main/nl_train_stations/ducklake-01993f31-b51a-73e8-8375-f6cffbda67f3.parquet"

# avoid duckplyr, and instead get the SQL which can be ported into UPDATE stmts
train_file <- duckdb::tbl_file(con, train_stations_path)
# Create and execute the update
train_query <- train_file |> 
  mutate(
    name_long = case_when(
      code == "ASB" ~ "Johan Cruijff ArenA",
      .default = name_long
    )
  ) 

# here's the query we're going to send to ducklake
train_query |>
  update_table("nl_train_stations")
#> [1] "UPDATE my_ducklake.nl_train_stations SET id = id, code = code, uic = uic, name_short = name_short, name_medium = name_medium, name_long = CASE WHEN (code = 'ASB') THEN 'Johan Cruijff ArenA' ELSE name_long END, slug = slug, country = country, \"type\" = \"type\", geo_lat = geo_lat, geo_lng = geo_lng"

train_query |>
  update_table("nl_train_stations") |>
  duckplyr::db_exec()

# metadata
DBI::dbGetQuery(con, "SELECT * FROM ducklake_table WHERE table_name = 'nl_train_stations';")
#>   table_id                           table_uuid begin_snapshot end_snapshot
#> 1        1 01993f31-b519-772a-8c5d-b2c9066b77c1              1           NA
#>   schema_id        table_name               path path_is_relative
#> 1         0 nl_train_stations nl_train_stations/             TRUE

# schema info
DBI::dbGetQuery(con, "SELECT * FROM ducklake_schema WHERE schema_id = 0;")
#>   schema_id                          schema_uuid begin_snapshot end_snapshot
#> 1         0 9eb734f5-8767-490b-ab32-46b13bf26626              0           NA
#>   schema_name  path path_is_relative
#> 1        main main/             TRUE

# snapshots
DBI::dbGetQuery(con, "SELECT * FROM ducklake_snapshot ORDER BY snapshot_id;")
#>   snapshot_id       snapshot_time schema_version next_catalog_id next_file_id
#> 1           0 2025-09-12 18:30:45              0               1            0
#> 2           1 2025-09-12 18:30:46              1               2            1

# data files with snapshots
DBI::dbGetQuery(con, "
  SELECT 
    d.*,
    s.snapshot_time,
    t.table_name,
    t.path as table_path
  FROM ducklake_data_file d
  JOIN ducklake_snapshot s ON d.begin_snapshot = s.snapshot_id
  JOIN ducklake_table t ON d.table_id = t.table_id
  WHERE t.table_name = 'nl_train_stations'
  ORDER BY d.begin_snapshot DESC;
")
#>   data_file_id table_id begin_snapshot end_snapshot file_order
#> 1            0        1              1           NA         NA
#>                                                    path path_is_relative
#> 1 ducklake-01993f31-b51a-73e8-8375-f6cffbda67f3.parquet             TRUE
#>   file_format record_count file_size_bytes footer_size row_id_start
#> 1     parquet          578           59856        1340            0
#>   partition_id encryption_key partial_file_info mapping_id       snapshot_time
#> 1           NA           <NA>              <NA>         NA 2025-09-12 18:30:46
#>          table_name         table_path
#> 1 nl_train_stations nl_train_stations/

# delete files with snapshots
DBI::dbGetQuery(con, "
  SELECT 
    d.*,
    s.snapshot_time,
    t.table_name
  FROM ducklake_delete_file d
  JOIN ducklake_snapshot s ON d.begin_snapshot = s.snapshot_id
  JOIN ducklake_table t ON d.table_id = t.table_id
  WHERE t.table_name = 'nl_train_stations'
  ORDER BY d.begin_snapshot DESC;
")
#>  [1] delete_file_id   table_id         begin_snapshot   end_snapshot    
#>  [5] data_file_id     path             path_is_relative format          
#>  [9] delete_count     file_size_bytes  footer_size      encryption_key  
#> [13] snapshot_time    table_name      
#> <0 rows> (or 0-length row.names)

# snapshot changes
DBI::dbGetQuery(con, "
  SELECT 
    c.*,
    s.snapshot_time
  FROM ducklake_snapshot_changes c
  JOIN ducklake_snapshot s USING (snapshot_id)
  ORDER BY snapshot_id DESC;
")
#>   snapshot_id                                                   changes_made
#> 1           1 created_table:"main"."nl_train_stations",inserted_into_table:1
#> 2           0                                          created_schema:"main"
#>         snapshot_time
#> 1 2025-09-12 18:30:46
#> 2 2025-09-12 18:30:45

# metadata path
DBI::dbGetQuery(con, "SELECT * FROM ducklake_metadata WHERE key = 'data_path';")
#>         key                       value scope scope_id
#> 1 data_path my_ducklake.ducklake.files/  <NA>       NA

# data files
list.files("my_ducklake.ducklake.files/main/nl_train_stations/", full.names = TRUE)
#> [1] "my_ducklake.ducklake.files/main/nl_train_stations//ducklake-01993f31-b51a-73e8-8375-f6cffbda67f3.parquet"
#> [2] "my_ducklake.ducklake.files/main/nl_train_stations//ducklake-01993f31-b5d5-744c-a4ab-74cd33de6195.parquet"
```
