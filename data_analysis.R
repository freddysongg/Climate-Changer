# Load required libraries
library(tidyverse)

# Load the dataset
file_path <- "data/climate_data.xls"
data <- readxl::read_excel(file_path, sheet = "Data")

# Preview dataset
print(head(data))

# Ensure numeric columns are properly converted
numeric_cols <- names(data)[6:ncol(data)]
data[numeric_cols] <- lapply(data[numeric_cols], function(x) as.numeric(as.character(x)))

# Handle missing values
data[is.na(data)] <- 0

# Function to sanitize filenames
sanitize_filename <- function(name) {
  name %>%
    gsub("[/\\:*?\"<>|]", "_", .) %>%  
    gsub(" ", "_", .)                
}

# Split dataset by `Series Name`
split_data <- split(data, data$`Series name`)

# Loop through each unique `Series Name` to save separate cleaned files
for (series in names(split_data)) {
  series_data <- split_data[[series]]
  sanitized_series <- sanitize_filename(series)
  file_name <- paste0("data/cleaned_", sanitized_series, ".csv")
  write_csv(series_data, file_name)
  cat("Saved:", file_name, "\n")
}

# Example: Aggregated statistics for each dataset
stats_list <- lapply(split_data, function(df) {
  df %>%
    summarise(across(where(is.numeric), 
                     list(mean = ~mean(.x, na.rm = TRUE), 
                          median = ~median(.x, na.rm = TRUE), 
                          sd = ~sd(.x, na.rm = TRUE))))
})

# Print example statistics
if ("Land area below 5m (% of land area)" %in% names(stats_list)) {
  print(stats_list[["Land area below 5m (% of land area)"]])
}
