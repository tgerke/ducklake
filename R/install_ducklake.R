#' Install the ducklake extension to duckdb
#'
#' This only needs to be run once on your system.
#'
#' @returns NULL
#' @export
#'
#' @examples
#' ducklake::install_ducklake()
install_ducklake <- function() {

  # check that duckdb version is at least 1.3.0
  drv <- duckdb::duckdb()
  con <- DBI::dbConnect(drv)
  duckdb_version <- DBI::dbGetQuery(con, "SELECT version()")[1,1]
  duckdb_version_numeric <- as.integer(gsub("\\.", "", sub("^v", "", duckdb_version)))
  if (duckdb_version_numeric < 130) {
    cli::cli_abort("duckdb must be version 1.3.0 or higher")
  }

  # the long messages thrown on load for duckplyr are suppressed here
  # TODO: find a better/more global place to do this, since duckplyr used elsewhere
  suppressMessages(duckplyr::db_exec("INSTALL ducklake;"))
}


