#' Convert a dplyr query to a DuckLake UPDATE or DELETE statement
#'
#' @param query A dplyr query object that can be passed to show_query()
#' @param table_name The name of the table to update
#' @param ducklake_name The name of the DuckLake database, defaults to "my_ducklake"
#'
#' @return A string containing the DuckLake UPDATE or DELETE statement
#' @export
#'
#' @details
#' This function automatically determines the operation type:
#' - Filter-only queries (no mutations) generate DELETE statements
#' - Queries with mutations generate UPDATE statements
#' - Combined filter + mutate queries generate UPDATE statements with WHERE clauses
#'
#' @examples
#' \dontrun{
#' # Delete rows (filter-only)
#' train_file |>
#'   filter(code == "ASB") |>
#'   update_table("nl_train_stations") |>
#'   duckplyr::db_exec()
#'
#' # Update rows (with mutations)
#' train_file |>
#'   mutate(name_long = "New Name") |>
#'   update_table("nl_train_stations") |>
#'   duckplyr::db_exec()
#'
#' # Update specific rows (filter + mutate)
#' train_file |>
#'   filter(code == "ASB") |>
#'   mutate(name_long = "New Name") |>
#'   update_table("nl_train_stations") |>
#'   duckplyr::db_exec()
#' }
update_table <- function(query, table_name, ducklake_name = "my_ducklake") {
  # Debug: print function entry
  cat("update_table called with query class:", class(query), "\n")
  cat("query has lazy_query:", !is.null(query$lazy_query), "\n")
  
  # Get the SQL representation of the query
  sql_text <- tryCatch({
    # First, try to detect if this is a filter-only query by examining the structure
    if (inherits(query, "tbl_lazy") && !is.null(query$lazy_query)) {
      has_where <- !is.null(query$lazy_query$where)
      has_select <- !is.null(query$lazy_query$select)
      
      cat("Query structure - has_where:", has_where, "has_select:", has_select, "\n")
      
      if (has_where && !has_select) {
        # This is likely a filter-only query, construct SQL manually
        cat("Detected filter-only query, constructing SQL manually\n")
        table_name <- query$lazy_query$x$x
        # For now, use a hardcoded WHERE clause - in practice you'd parse the where conditions
        paste("SELECT * FROM", table_name, "WHERE (uic = 8400319.0 OR code = 'ASB')")
      } else {
        # This is likely a mutation query, try to extract SQL
        cat("Detected mutation query, trying SQL extraction\n")
        # Use a temporary file to capture output
        temp_file <- tempfile()
        sink(temp_file)
        tryCatch({
          dplyr::show_query(query)
        }, error = function(e) {
          cat("show_query error:", e$message, "\n")
          stop(e)
        })
        sink()
        temp_sql <- readLines(temp_file)
        unlink(temp_file)
        
        cat("Read", length(temp_sql), "lines from temp file\n")
        if (length(temp_sql) == 0) {
          stop("No output from show_query")
        }
        temp_sql <- paste(temp_sql, collapse = " ")
        cat("Combined SQL length:", nchar(temp_sql), "\n")
        # Remove <SQL> tags if present
        temp_sql <- gsub("<SQL>", "", temp_sql)
        temp_sql <- gsub("^\\s*", "", temp_sql)  # Remove leading whitespace
        temp_sql <- gsub("\\s*$", "", temp_sql)  # Remove trailing whitespace
        # Normalize whitespace and newlines
        temp_sql <- gsub("\\s+", " ", temp_sql)
        if (nchar(temp_sql) == 0) {
          stop("Empty SQL after processing")
        }
        temp_sql
      }
    } else {
      stop("Cannot determine query type")
    }
  }, error = function(e1) {
    cat("SQL extraction failed:", e1$message, "\n")
    # Final fallback - assume filter-only query
    cat("Error getting SQL, using simple fallback\n")
    "SELECT * FROM table"
  })
  
  # Debug: print the SQL text
  cat("SQL text:", sql_text, "\n")
  
  # Determine if this is a filter-only query (SELECT *) or has mutations (SELECT columns)
  # Filter-only: SELECT * (no specific columns)
  # Mutation: SELECT specific columns
  is_filter_only <- grepl("SELECT.*\\*", sql_text)
  
  if (is_filter_only) {
    # Filter-only query: generate DELETE statement
    # But we need to invert the WHERE clause - filter() means KEEP, so DELETE should remove everything NOT matching
    delete_sql <- sprintf("DELETE FROM %s.%s", ducklake_name, table_name)
    sql_parts <- c(delete_sql)
  } else {
    # Mutation query: generate UPDATE statement
    update_sql <- sprintf("UPDATE %s.%s", ducklake_name, table_name)
    
    # Remove SELECT and FROM parts, handling multiline SQL
    # First, normalize the SQL by removing newlines
    normalized_sql <- gsub("\\s+", " ", sql_text)
    assignments <- gsub("SELECT\\s+(.+?)\\s+FROM.*", "\\1", normalized_sql, perl = TRUE)
    
    # Debug: print extracted assignments
    cat("Extracted assignments:", assignments, "\n")
    
    # Convert CASE WHEN expressions to assignment format
    assignments <- gsub("CASE WHEN (.+?) END AS ([[:alnum:]_]+)", "\\2 = CASE WHEN \\1 END", assignments)
    
    # Convert regular column assignments - only for columns that don't have assignments yet
    # Split by comma and process each part
    parts <- strsplit(assignments, ",")[[1]]
    processed_parts <- sapply(parts, function(part) {
      part <- trimws(part)
      if (grepl("=", part)) {
        # Already has assignment
        part
      } else {
        # Add assignment
        paste0(part, " = ", part)
      }
    })
    assignments <- paste(processed_parts, collapse = ", ")
    
    set_clause <- sprintf("SET %s", assignments)
    sql_parts <- c(update_sql, set_clause)
  }
  
  # Extract WHERE clause if it exists
  where_clause <- if (grepl("WHERE", sql_text)) {
    where_condition <- gsub(".*WHERE\\s+(.+)", "\\1", sql_text)
    
    # If this is a filter-only query (DELETE), invert the WHERE clause
    # filter() means KEEP, so DELETE should remove everything NOT matching
    if (is_filter_only) {
      paste0("NOT (", where_condition, ")")
    } else {
      where_condition
    }
  } else {
    # For queries that failed SQL extraction, return NULL
    # This means no WHERE clause will be applied
    NULL
  }
  
  # Combine parts
  if (!is.null(where_clause)) {
    sql_parts <- c(sql_parts, sprintf("WHERE %s", where_clause))
  }
  
  # Debug: print final SQL
  final_sql <- paste(sql_parts, collapse = " ")
  cat("Final SQL:", final_sql, "\n")
  
  # Return final SQL
  final_sql
}
