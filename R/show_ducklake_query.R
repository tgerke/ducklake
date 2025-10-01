#' Show the SQL that would be executed by ducklake operations
#'
#' This function shows the SQL that would be generated and executed by ducklake.
#' This is useful for debugging and understanding what SQL is being sent to DuckDB.
#'
#' @param .data A dplyr query object (tbl_lazy)
#' @param table_name The target table name for the operation
#'
#' @return The first argument, invisibly (following show_query convention)
#' @export
#'
#' @examples
#' \dontrun{
#' # Show SQL for an update operation
#' get_ducklake_table("my_table") %>%
#'   mutate(status = "updated") %>%
#'   show_ducklake_query("my_table")
#' }
show_ducklake_query <- function(.data, table_name) {
  cat("\n=== DuckLake SQL Preview ===\n")
  
  # Show main operation SQL
  cat("\n-- Main operation\n")
  sql_string <- update_table(.data, table_name, .quiet = TRUE)
  cat(sql_string, ";\n")
  
  invisible(.data)
}

