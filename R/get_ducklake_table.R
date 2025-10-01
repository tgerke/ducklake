#' Get a DuckLake table
#'
#' @param tbl_name Character string, name of the table to retrieve
#'
#' @returns A DuckLake table of class `tbl_duckdb_connection`
#' @export
#'
get_ducklake_table <- function(tbl_name) {
  return(dplyr::tbl(duckplyr:::get_default_duckdb_connection(), tbl_name))
}

#' Get a DuckLake metadata table
#'
#' @param tbl_name Character string, name of the table to retrieve
#' @param ducklake_name Character string, name of the ducklake database
#'
#' @returns A DuckLake table of class `tbl_duckdb_connection`
#' @export
#'
get_metadata_table <- function(tbl_name, ducklake_name) {
  metadata_tbl_name <- paste0("__ducklake_metadata_", ducklake_name, ".", tbl_name)
  return(get_ducklake_table(metadata_tbl_name))
}
