library(tidyverse)

# Path to the file
file_path <- "data/cleaned_CO2_emissions,_total_(KtCO2).csv"

# Step 1: Load the data and inspect structure
raw_data <- read_csv(file_path)
print("Raw Data:")
print(head(raw_data))
print("Column Names in Raw Data:")
print(colnames(raw_data))

# Step 2: Reshape the data
reshaped_data <- raw_data %>%
  rename_with(~ gsub("\\s+", "_", .x)) %>%                # Replace spaces with underscores
  rename_with(~ gsub("[()%,]", "", .x)) %>%              # Remove special characters
  pivot_longer(
    cols = starts_with("19") | starts_with("20"),       # Select year columns dynamically
    names_to = "Year",                                  # New column for year
    values_to = "Value"                                 # New column for the data
  ) %>%
  mutate(Year = as.integer(Year))                       # Ensure Year is numeric

# Step 3: Rename the Value column to Total_CO2
reshaped_data <- reshaped_data %>%
  rename(Total_CO2 = Value)

# Step 4: Inspect reshaped data
print("Reshaped Data:")
print(head(reshaped_data))
print("Column Names in Reshaped Data:")
print(colnames(reshaped_data))
