#' Create a DuckLake table
#'
#' @param table_name Name of the new table
#' @param data_source Raw data source
#'
#' @returns NULL
#' @export
#'
create_table <- function(table_name, data_source) {
  # If data_source is a URL, ensure httpfs extension is installed and loaded
  if (grepl("^https?://", data_source)) {
    tryCatch({
      duckplyr::db_exec("LOAD httpfs;")
    }, error = function(e) {
      duckplyr::db_exec("INSTALL httpfs;")
      duckplyr::db_exec("LOAD httpfs;")
    })
  }
  
  #TODO: this needs to handle R data.frames
  duckplyr::db_exec(sprintf("CREATE TABLE %s AS FROM '%s';", table_name, data_source))
}
