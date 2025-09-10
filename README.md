
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

# try to get to the nl_train_stations table
duckplyr::db_exec("USE my_ducklake;")
query_result <- DBI::dbGetQuery(con, "SELECT * FROM ducklake_table WHERE table_name = 'nl_train_stations';")
query_result
#>   table_id                           table_uuid begin_snapshot end_snapshot
#> 1        1 01993566-502e-7827-acf0-eabea9d404b3              1           NA
#>   schema_id        table_name               path path_is_relative
#> 1         0 nl_train_stations nl_train_stations/             TRUE
duckplyr::as_duckdb_tibble(query_result)
#> # A duckplyr data frame: 8 variables
#>   table_id table_uuid     begin_snapshot end_snapshot schema_id table_name path 
#>      <dbl> <chr>                   <dbl>        <dbl>     <dbl> <chr>      <chr>
#> 1        1 01993566-502e…              1           NA         0 nl_train_… nl_t…
#> # ℹ 1 more variable: path_is_relative <lgl>

DBI::dbGetQuery(con, "SELECT * FROM ducklake_schema WHERE schema_id = 0;")
#>   schema_id                          schema_uuid begin_snapshot end_snapshot
#> 1         0 51ec5008-e367-4ef0-9050-37b3985f5db6              0           NA
#>   schema_name  path path_is_relative
#> 1        main main/             TRUE
# this is still just metadata
DBI::dbGetQuery(con, "SELECT * FROM ducklake_column WHERE table_id = 1;")
#>    column_id begin_snapshot end_snapshot table_id column_order column_name
#> 1          1              1           NA        1            1          id
#> 2          2              1           NA        1            2        code
#> 3          3              1           NA        1            3         uic
#> 4          4              1           NA        1            4  name_short
#> 5          5              1           NA        1            5 name_medium
#> 6          6              1           NA        1            6   name_long
#> 7          7              1           NA        1            7        slug
#> 8          8              1           NA        1            8     country
#> 9          9              1           NA        1            9        type
#> 10        10              1           NA        1           10     geo_lat
#> 11        11              1           NA        1           11     geo_lng
#>    column_type initial_default default_value nulls_allowed parent_column
#> 1        int64            <NA>          <NA>          TRUE            NA
#> 2      varchar            <NA>          <NA>          TRUE            NA
#> 3        int64            <NA>          <NA>          TRUE            NA
#> 4      varchar            <NA>          <NA>          TRUE            NA
#> 5      varchar            <NA>          <NA>          TRUE            NA
#> 6      varchar            <NA>          <NA>          TRUE            NA
#> 7      varchar            <NA>          <NA>          TRUE            NA
#> 8      varchar            <NA>          <NA>          TRUE            NA
#> 9      varchar            <NA>          <NA>          TRUE            NA
#> 10     float64            <NA>          <NA>          TRUE            NA
#> 11     float64            <NA>          <NA>          TRUE            NA

# there doesn't seem to be a direct way to reference the nl_train_stations table with existing duckplyr resources
# I believe this is because of the nested/heirarchical nature of ducklake
# So, get the data path and file name
data_path <- DBI::dbGetQuery(con, "SELECT value FROM ducklake_metadata WHERE key = 'data_path'")$value
train_data <- DBI::dbGetQuery(con, "SELECT * FROM ducklake_data_file WHERE table_id = 1;")
file_name <- train_data$path
full_path <- paste0(data_path, "main/nl_train_stations/", file_name)

# Now try to read with the full path
train_stations <- DBI::dbGetQuery(con, sprintf("SELECT * FROM parquet_scan('%s')", full_path))

# Convert to duckplyr tibble
nl_train_stations <- duckplyr::as_duckdb_tibble(train_stations)
nl_train_stations
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

# make an update with duckplyr that mirrors this ducklake command
# UPDATE nl_train_stations SET name_long='Johan Cruijff ArenA' WHERE code = 'ASB';
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
# check that it worked
nl_train_stations_new |> filter(code == "ASB")
#> # A duckplyr data frame: 11 variables
#>      id code      uic name_short name_medium   name_long     slug  country type 
#>   <dbl> <chr>   <dbl> <chr>      <chr>         <chr>         <chr> <chr>   <chr>
#> 1    41 ASB   8400074 Bijlmer A  Bijlmer ArenA Johan Cruijf… amst… NL      knoo…
#> # ℹ 2 more variables: geo_lat <dbl>, geo_lng <dbl>

duckdb::duckdb_register(con, "nl_train_stations_new", nl_train_stations_new)
DBI::dbGetQuery(con, sprintf("COPY nl_train_stations_new TO '%s' (FORMAT 'parquet', OVERWRITE 1);", full_path))
#> Warning in dbFetch(rs, n = n, ...): Should not call dbFetch() on results that
#> do not come from SELECT, got COPY
#> data frame with 0 columns and 0 rows

# Read the updated data
updated_train_stations <- DBI::dbGetQuery(con, sprintf("SELECT * FROM parquet_scan('%s')", full_path))

# Convert to duckplyr tibble and check the ASB station
nl_train_stations <- duckplyr::as_duckdb_tibble(updated_train_stations)
nl_train_stations %>% filter(code == "ASB")
#> # A duckplyr data frame: 11 variables
#>      id code      uic name_short name_medium   name_long     slug  country type 
#>   <dbl> <chr>   <dbl> <chr>      <chr>         <chr>         <chr> <chr>   <chr>
#> 1    41 ASB   8400074 Bijlmer A  Bijlmer ArenA Johan Cruijf… amst… NL      knoo…
#> # ℹ 2 more variables: geo_lat <dbl>, geo_lng <dbl>
```
