
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
#> [1] 0

# set up a temporary directory to demonstrate use
temp_dir <- tempdir()
# haha Jenny Bryan is going to set my computer on fire
setwd(temp_dir)

# create the ducklake
attach_ducklake("my_ducklake")
#> [1] 0
# show that we have ducklake files
list.files()
#> [1] "duckplyr"                 "my_ducklake.ducklake"    
#> [3] "my_ducklake.ducklake.wal"

# create a table using the Netherlands train traffic dataset 
create_table("nl_train_stations", "https://blobs.duckdb.org/nl_stations.csv")
#> [1] 578
# show that we now have a .files directory
list.files()
#> [1] "duckplyr"                   "my_ducklake.ducklake"      
#> [3] "my_ducklake.ducklake.files" "my_ducklake.ducklake.wal"
# main/ is where the parquet files go
list.files("my_ducklake.ducklake.files/main/nl_train_stations")
#> [1] "ducklake-01998226-1d56-7e16-8eb9-b8c3888f6917.parquet"

# update the first row
dplyr::rows_update(
  dplyr::tbl(duckplyr:::get_default_duckdb_connection(), "nl_train_stations"),
  data.frame(
    uic = 8400319,
    name_short = "NEW"
  ),
  by = "uic",
  copy = TRUE,
  in_place = TRUE,
  unmatched = "ignore"
)

# view snapshots
dplyr::tbl(
  duckplyr:::get_default_duckdb_connection(), 
  "__ducklake_metadata_my_ducklake.ducklake_snapshot_changes"
)
#> # Source:   SQL [?? x 2]
#> # Database: DuckDB v1.3.2 [tgerke@Darwin 23.6.0:R 4.5.1//private/var/folders/b7/664jmq55319dcb7y4jdb39zr0000gq/T/Rtmpb0xqV7/duckplyr/duckplyr13a422e8b707.duckdb]
#>   snapshot_id changes_made                                                      
#>         <dbl> <chr>                                                             
#> 1           0 "created_schema:\"main\""                                         
#> 2           1 "created_table:\"main\".\"nl_train_stations\",inserted_into_table…
#> 3           2 "inserted_into_table:1,deleted_from_table:1"
dplyr::tbl(
  duckplyr:::get_default_duckdb_connection(), 
  "__ducklake_metadata_my_ducklake.ducklake_snapshot"
)
#> # Source:   SQL [?? x 5]
#> # Database: DuckDB v1.3.2 [tgerke@Darwin 23.6.0:R 4.5.1//private/var/folders/b7/664jmq55319dcb7y4jdb39zr0000gq/T/Rtmpb0xqV7/duckplyr/duckplyr13a422e8b707.duckdb]
#>   snapshot_id snapshot_time       schema_version next_catalog_id next_file_id
#>         <dbl> <dttm>                       <dbl>           <dbl>        <dbl>
#> 1           0 2025-09-25 18:32:39              0               1            0
#> 2           1 2025-09-25 18:32:39              1               2            1
#> 3           2 2025-09-25 18:32:40              1               2            3

# check that the change is persisted
suppressMessages(library(duckplyr))

read_sql_duckdb("FROM nl_train_stations") |> 
  filter(uic == 8400319)
#> # A duckplyr data frame: 11 variables
#>      id code      uic name_short name_medium      name_long  slug  country type 
#>   <dbl> <chr>   <dbl> <chr>      <chr>            <chr>      <chr> <chr>   <chr>
#> 1   266 HT    8400319 NEW        's-Hertogenbosch 's-Hertog… s-he… NL      knoo…
#> # ℹ 2 more variables: geo_lat <dbl>, geo_lng <dbl>
```
