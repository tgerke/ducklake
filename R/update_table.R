#' Convert a dplyr SELECT query to a DuckLake UPDATE statement
#'
#' @param query A dplyr query object that can be passed to show_query()
#' @param table_name The name of the table to update
#' @param ducklake_name The name of the DuckLake database, defaults to "my_ducklake"
#'
#' @return A string containing the DuckLake UPDATE statement
#' @export
#'
#' @examples
#' \dontrun{
#' # Create a dplyr query
#' train_file |>
#'   mutate(
#'     name_long = case_when(
#'       code == "ASB" ~ "Johan Cruijff ArenA",
#'       .default = name_long
#'     )
#'   ) |>
#'   update_table("nl_train_stations", ducklake_name = "my_ducklake") |>
#'   duckplyr::db_exec()
#' }
update_table <- function(query, table_name, ducklake_name = "my_ducklake") {
  # Capture the SQL from show_query
  sql_query <- capture.output(dplyr::show_query(query))
  sql_query <- paste(sql_query, collapse = "\n")
  # Remove <SQL> tag if present
  sql_query <- gsub("<SQL>", "", sql_query)

  # Start building the UPDATE statement with schema
  update_sql <- paste("UPDATE", paste0(ducklake_name, ".", table_name), "SET")
  
  # Process the SELECT query:
  # 1. Remove SELECT keyword and newlines
  sql_query <- gsub("^\\s*SELECT\\s+", "", sql_query) |>
    gsub("\\s*\\n\\s*", " ", x = _)
    
  # 2. Handle CASE WHEN expressions first
  sql_query <- gsub("(CASE WHEN .+? END) AS ([[:alnum:]_]+)", "\\2 = \\1", sql_query)
  
  # 3. Handle regular columns
  sql_query <- gsub("([[:alnum:]_\"]+)(,|\\s+FROM|$)", "\\1 = \\1\\2", sql_query)
  
  # 4. Remove any duplicate END assignments
  sql_query <- gsub("END = END", "END", sql_query)
  
  # 5. Remove the FROM clause
  sql_query <- gsub("\\s+FROM.*$", "", sql_query)
  
  # Combine and clean up
  sql <- paste(update_sql, sql_query) |>
    gsub("\\s+", " ", x = _) |>     # normalize spaces
    gsub(",\\s*$", "", x = _) |>    # remove trailing comma
    trimws()
  
  sql
}
