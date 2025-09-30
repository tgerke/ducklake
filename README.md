
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ducklake <a href="https://github.com/tgerke/ducklake-r"><img src="man/figures/ducklake-hex.jpg" align="right" height="138" /></a>

ducklake is an R package which complements the existing toolkits in the
[duckdb](https://r.duckdb.org/index.html) and
[duckplyr](https://duckplyr.tidyverse.org/index.html) packages, in order
to support the new
[DuckLake](https://ducklake.select/docs/stable/duckdb/introduction.html)
ecosystem.

## Installation

Install the development version of ducklake with

``` r
pak::pak("tgerke/ducklake-r")
```

## Create a local duckdb lakehouse

``` r
library(ducklake)
library(dplyr)

# install the ducklake extension to duckdb 
# requires that you already have DuckDB v1.3.0 or higher
install_ducklake()

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
list.files("my_ducklake.ducklake.files/main/nl_train_stations")
#> [1] "ducklake-01999c1b-cc3a-79b8-908a-e47e036a9b72.parquet"

# update the first row with dplyr::rows_update
rows_update(
  tbl(duckplyr:::get_default_duckdb_connection(), "nl_train_stations"),
  data.frame(
    uic = 8400319,
    name_short = "NEW"
  ),
  by = "uic",
  copy = TRUE,
  in_place = TRUE,
  unmatched = "ignore"
)

# update with mutate and ducklake::ducklake_exec
tbl(duckplyr:::get_default_duckdb_connection(), "nl_train_stations") |>
  mutate(
    name_long = dplyr::case_when(
      code == "ASB" ~ "Johan Cruijff ArenA",
      .default = name_long
    )
  ) |>
  ducklake_exec("nl_train_stations")
#> [1] 578

# filter using ducklake::ducklake_exec
tbl(duckplyr:::get_default_duckdb_connection(), "nl_train_stations") |>
  filter(uic == 8400319 | code == "ASB") |>
  ducklake_exec("nl_train_stations")
#> [1] 576

# view snapshots
tbl(
  duckplyr:::get_default_duckdb_connection(), 
  "__ducklake_metadata_my_ducklake.ducklake_snapshot_changes"
)
#> # Source:   SQL [?? x 5]
#> # Database: DuckDB 1.4.0 [tgerke@Darwin 23.6.0:R 4.5.1//private/var/folders/b7/664jmq55319dcb7y4jdb39zr0000gq/T/RtmpWGFFQ4/duckplyr/duckplyr16bb428bc63b9.duckdb]
#>   snapshot_id changes_made               author commit_message commit_extra_info
#>         <dbl> <chr>                      <chr>  <chr>          <chr>            
#> 1           0 "created_schema:\"main\""  <NA>   <NA>           <NA>             
#> 2           1 "created_table:\"main\".\… <NA>   <NA>           <NA>             
#> 3           2 "inserted_into_table:1,de… <NA>   <NA>           <NA>             
#> 4           3 "inserted_into_table:1,de… <NA>   <NA>           <NA>             
#> 5           4 "deleted_from_table:1"     <NA>   <NA>           <NA>
tbl(
  duckplyr:::get_default_duckdb_connection(), 
  "__ducklake_metadata_my_ducklake.ducklake_snapshot"
)
#> # Source:   SQL [?? x 5]
#> # Database: DuckDB 1.4.0 [tgerke@Darwin 23.6.0:R 4.5.1//private/var/folders/b7/664jmq55319dcb7y4jdb39zr0000gq/T/RtmpWGFFQ4/duckplyr/duckplyr16bb428bc63b9.duckdb]
#>   snapshot_id snapshot_time       schema_version next_catalog_id next_file_id
#>         <dbl> <dttm>                       <dbl>           <dbl>        <dbl>
#> 1           0 2025-09-30 19:31:30              0               1            0
#> 2           1 2025-09-30 19:31:31              1               2            1
#> 3           2 2025-09-30 19:31:31              1               2            3
#> 4           3 2025-09-30 19:31:31              1               2            4
#> 5           4 2025-09-30 19:31:31              1               2            5

duckplyr::read_sql_duckdb("FROM nl_train_stations") 
#> # A duckplyr data frame: 11 variables
#>      id code      uic name_short name_medium      name_long  slug  country type 
#>   <dbl> <chr>   <dbl> <chr>      <chr>            <chr>      <chr> <chr>   <chr>
#> 1   266 HT    8400319 NEW        's-Hertogenbosch 's-Hertog… s-he… NL      knoo…
#> 2    41 ASB   8400074 Bijlmer A  Bijlmer ArenA    Johan Cru… amst… NL      knoo…
#> # ℹ 2 more variables: geo_lat <dbl>, geo_lng <dbl>
```
