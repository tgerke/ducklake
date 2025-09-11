
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
library(duckplyr)
#> Loading required package: dplyr
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
#> ✔ Overwriting dplyr methods with duckplyr methods.
#> ℹ Turn off with `duckplyr::methods_restore()`.

# Find the Parquet file path for our table
train_stations_path <- get_table_path("nl_train_stations", con)
train_stations_path
#> [1] "my_ducklake.ducklake.files/main/nl_train_stations/ducklake-01993ad2-c319-75a4-be9a-a943a0062267.parquet"

nl_train_stations <- read_parquet_duckdb(train_stations_path)

# row we want to edit
nl_train_stations |> filter(code == "ASB")
#> # A duckplyr data frame: 11 variables
#>      id code      uic name_short name_medium   name_long     slug  country type 
#>   <dbl> <chr>   <dbl> <chr>      <chr>         <chr>         <chr> <chr>   <chr>
#> 1    41 ASB   8400074 Bijlmer A  Bijlmer ArenA Amsterdam Bi… amst… NL      knoo…
#> # ℹ 2 more variables: geo_lat <dbl>, geo_lng <dbl>
nl_train_stations_new <- nl_train_stations |>
  mutate(
    name_long = case_when(
      code == "ASB" ~ "Johan Cruijff ArenA",
      .default = name_long
    )
  )
nl_train_stations_new |> filter(code == "ASB")
#> # A duckplyr data frame: 11 variables
#>      id code      uic name_short name_medium   name_long     slug  country type 
#>   <dbl> <chr>   <dbl> <chr>      <chr>         <chr>         <chr> <chr>   <chr>
#> 1    41 ASB   8400074 Bijlmer A  Bijlmer ArenA Johan Cruijf… amst… NL      knoo…
#> # ℹ 2 more variables: geo_lat <dbl>, geo_lng <dbl>

compute_parquet(nl_train_stations_new, train_stations_path)
#> # A duckplyr data frame: 11 variables
#>       id code      uic name_short name_medium      name_long slug  country type 
#>    <dbl> <chr>   <dbl> <chr>      <chr>            <chr>     <chr> <chr>   <chr>
#>  1   266 HT    8400319 Den Bosch  's-Hertogenbosch 's-Herto… s-he… NL      knoo…
#>  2   269 HTO   8400320 Dn Bosch O 's-Hertogenb. O. 's-Herto… s-he… NL      stop…
#>  3   227 HDE   8400388 't Harde   't Harde         't Harde  t-ha… NL      stop…
#>  4     8 AHBF  8015345 Aachen     Aachen Hbf       Aachen H… aach… D       knoo…
#>  5   818 AW    8015199 Aachen W   Aachen West      Aachen W… aach… D       stop…
#>  6    51 ATN   8400045 Aalten     Aalten           Aalten    aalt… NL      stop…
#>  7     5 AC    8400047 Abcoude    Abcoude          Abcoude   abco… NL      stop…
#>  8   550 EAHS  8021123 Ahaus      Ahaus            Ahaus     ahaus D       stop…
#>  9    12 AIME  8774176 Aime-la-Pl Aime-la-Plagne   Aime-la-… aime… F       inte…
#> 10   819 ACDG  8727149 Airport dG Airport deGaulle Airport … airp… F       knoo…
#> # ℹ more rows
#> # ℹ 2 more variables: geo_lat <dbl>, geo_lng <dbl>

# it worked, but i doubt the snapshots and other ducklake infra picked this up
nl_train_stations <- read_parquet_duckdb(train_stations_path)
nl_train_stations |> filter(code == "ASB")
#> # A duckplyr data frame: 11 variables
#>      id code      uic name_short name_medium   name_long     slug  country type 
#>   <dbl> <chr>   <dbl> <chr>      <chr>         <chr>         <chr> <chr>   <chr>
#> 1    41 ASB   8400074 Bijlmer A  Bijlmer ArenA Johan Cruijf… amst… NL      knoo…
#> # ℹ 2 more variables: geo_lat <dbl>, geo_lng <dbl>

# check if ducklake noticed the changes
snapshots <- DBI::dbGetQuery(con, "SELECT * FROM ducklake_snapshot ORDER BY snapshot_id DESC;")
snapshots
#>   snapshot_id       snapshot_time schema_version next_catalog_id next_file_id
#> 1           1 2025-09-11 22:08:34              1               2            1
#> 2           0 2025-09-11 22:08:34              0               1            0
```
