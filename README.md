
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
con <- DBI::dbConnect(
  duckdb::duckdb(
    dbdir = paste0(temp_dir, "/my_ducklake.ducklake"),
    read_only = FALSE
  )
)

# list tables in the metadata store
DBI::dbListTables(con)
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
