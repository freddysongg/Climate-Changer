# Load required libraries
library(tidyverse) # For data manipulation and processing

# Set the path for the log file
log_dir <- "logs" # Directory for logs
log_file <- file.path(log_dir, "warnings_log.txt") # Full path to the log file

# Ensure the log directory exists; create if missing
if (!dir.exists(log_dir)) {
  dir.create(log_dir, recursive = TRUE) # Create the directory with all necessary parent directories
}

# Redirect warnings and messages to the log file
tryCatch({
  sink(log_file, type = "message") # Redirect messages to the log file
}, error = function(e) {
  cat("Error in opening log file:", e$message, "\n") # Print error message if redirection fails
})

# Load the dataset
file_path <- "data/climate_data.xls" # Path to the input Excel file
data <- tryCatch(
  {
    readxl::read_excel(file_path, sheet = "Data") # Load the data from the "Data" sheet
  },
  error = function(e) {
    cat("Error loading dataset:", e$message, "\n") # Print error if the dataset cannot be loaded
    NULL # Return NULL if loading fails
  }
)

# Proceed only if the dataset is successfully loaded
if (!is.null(data)) {
  # Preview the first few rows of the dataset
  print(head(data)) # Print a preview of the dataset for verification
  
  # Identify numeric columns starting from the 6th column onward
  numeric_cols <- names(data)[6:ncol(data)]
  
  # Convert numeric columns to numeric data type with error and warning handling
  data[numeric_cols] <- lapply(data[numeric_cols], function(col) {
    tryCatch(
      {
        as.numeric(as.character(col)) # Convert column to numeric
      },
      warning = function(w) {
        cat("Warning converting column:", w$message, "\n") # Log warnings
        as.numeric(as.character(col)) # Attempt conversion again
      },
      error = function(e) {
        cat("Error converting column:", e$message, "\n") # Log errors
        rep(NA, length(col)) # Replace the column with NAs if conversion fails
      }
    )
  })
  
  # Replace missing values (NA) with 0 for consistency
  data[is.na(data)] <- 0
  
  # Function to sanitize filenames by removing invalid characters
  sanitize_filename <- function(name) {
    name %>%
      gsub("[/\\:*?\"<>|]", "_", .) %>%  # Replace invalid characters with underscores
      gsub(" ", "_", .)                 # Replace spaces with underscores
  }
  
  # List of `Series Name` values to skip during processing
  skip_series <- c(
    "Annex-I emissions reduction target",
    "Average daily min/max temperature (1961-1990, Celsius)",
    "Hosted Clean Development Mechanism (CDM) projects",
    "Hosted Joint Implementation (JI) projects",
    "Issued Certified Emission Reductions (CERs) from CDM (thousands)",
    "Issued Emission Reduction Units (ERUs) from JI (thousands)",
    "Latest UNFCCC national communication",
    "NAMA submission",
    "NAPA submission",
    "Projected annual precipitation change (2045-2065, mm)",
    "Projected annual temperature change (2045-2065, Celsius)",
    "Projected change in annual cool days/cold nights",
    "Projected change in annual hot days/warm nights",
    "Renewable energy target"
  )
  
  # Split the dataset into subsets based on the `Series Name` column
  split_data <- split(data, data$`Series name`)
  
  # Loop through each subset to process and save it
  for (series in names(split_data)) {
    # Skip processing for series names in the skip list
    if (series %in% skip_series) {
      cat("Skipping:", series, "\n") # Log skipped series
      next
    }
    
    # Get the subset of data for the current `Series Name`
    series_data <- split_data[[series]]
    
    # Sanitize the series name for use as a file name
    sanitized_series <- sanitize_filename(series)
    file_name <- paste0("data/cleaned_", sanitized_series, ".csv") # Define the output file name
    
    # Save the subset to a CSV file
    tryCatch(
      {
        write_csv(series_data, file_name) # Write the data to a CSV file
        cat("Saved:", file_name, "\n") # Log successful file saves
      },
      error = function(e) {
        cat("Error saving file for series:", series, "-", e$message, "\n") # Log errors during file save
      }
    )
  }
  
  # Compute summary statistics for each subset
  stats_list <- lapply(split_data, function(df) {
    tryCatch(
      {
        df %>%
          summarise(across(where(is.numeric), 
                           list(mean = ~mean(.x, na.rm = TRUE), 
                                median = ~median(.x, na.rm = TRUE), 
                                sd = ~sd(.x, na.rm = TRUE)))) # Compute mean, median, and SD for numeric columns
      },
      error = function(e) {
        cat("Error computing statistics for dataset:", e$message, "\n") # Log errors during statistics computation
        NULL # Return NULL if computation fails
      }
    )
  })
  
  # Example: Print statistics for a specific series if available
  if ("Land area below 5m (% of land area)" %in% names(stats_list)) {
    print(stats_list[["Land area below 5m (% of land area)"]])
  }
}

# Close the sink connection safely
tryCatch({
  sink(NULL) # Close the sink for messages
}, error = function(e) {
  cat("Error in closing log file:", e$message, "\n") # Log errors during sink closure
})

# Notify the user that processing is complete
cat("Processing complete. Check", log_file, "for warnings and errors.\n")
