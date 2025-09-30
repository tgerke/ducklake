#' Get a DuckLake table
#'
#' @param tbl_name Character string, name of the table to retrieve
#'
#' @returns A DuckLake table of class `tbl_duckdb_connection`
#' @export
#'
get_ducklake_table <- function(tbl_name) {
  tbl(duckplyr:::get_default_duckdb_connection(), tbl_name)
}
