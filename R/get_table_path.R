#' Find the Parquet file path for a DuckLake table
#'
#' @param table_name Name of the table to find the file for
#' @param con DuckDB connection to a DuckLake database
#'
#' @return Character string containing the Parquet file path
#' @export
#'
get_table_path <- function(table_name, con) {
  # Get the table ID and path from ducklake_table
  table_info <- DBI::dbGetQuery(
    con,
    sprintf("SELECT * FROM ducklake_table WHERE table_name = '%s';", table_name)
  )

  if (nrow(table_info) == 0) {
    stop(sprintf("Table '%s' not found in DuckLake metadata", table_name))
  }

  # Get the data path from metadata
  data_path <- DBI::dbGetQuery(
    con,
    "SELECT value FROM ducklake_metadata WHERE key = 'data_path'"
  )$value

  # Get the most recent data file for this table
  data_file <- DBI::dbGetQuery(
    con,
    sprintf("
      SELECT
        CASE
          WHEN d.path_is_relative THEN '%s' || 'main/' || '%s' || d.path
          ELSE d.path
        END as file_path
      FROM ducklake_data_file d
      WHERE d.table_id = %d
      ORDER BY d.begin_snapshot DESC
      LIMIT 1;
    ", data_path, table_info$path, table_info$table_id)
  )

  if (nrow(data_file) == 0) {
    stop(sprintf("No data files found for table '%s'", table_name))
  }

  data_file$file_path
}
