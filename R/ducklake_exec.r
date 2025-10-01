#' Execute DuckLake operations from dplyr queries
#'
#' @param .data A dplyr query object (tbl_lazy) with accumulated operations
#' @param table_name The target table name for the operation
#' @param .quiet Logical, whether to suppress debug output (default TRUE)
#'
#' @return The result from duckplyr::db_exec()
#' @export
#'
#' @details
#' This function automatically detects the type of operation based on dplyr verbs:
#' - Filter-only queries generate DELETE operations (removes rows that DON'T match filter)
#' - Queries with mutate() generate UPDATE operations
#' - Other queries generate INSERT operations
#'
#' @examples
#' \dontrun{
#' # Delete rows that don't match filter
#' tbl(con, "my_table") |>
#'   filter(status == "inactive") |>
#'   ducklake_exec("my_table")
#'
#' # Update specific rows
#' tbl(con, "my_table") |>
#'   filter(id == 123) |>
#'   mutate(status = "updated") |>
#'   ducklake_exec("my_table")
#'
#' # Insert new computed data
#' tbl(con, "my_table") |>
#'   select(id, name) |>
#'   mutate(computed_field = name * 2) |>
#'   ducklake_exec("my_table")
#' }
ducklake_exec <- function(.data, table_name, .quiet = TRUE) {

  if (!.quiet) {
    # Show the original dplyr SQL
    cat("\n=== Original dplyr SQL ===\n")
    print(dplyr::show_query(.data))
  }

  # Generate the DuckLake SQL using update_table
  sql_string <- update_table(.data, table_name, .quiet = TRUE)

  if (!.quiet) {
    cat("\n=== Translated DuckLake SQL ===\n")
    cat(sql_string, "\n")
  }

  # Execute and return result
  result <- duckplyr::db_exec(sql_string)

  if (!.quiet) {
    cat("\nRows affected:", result, "\n")
  }

  return(result)
}
