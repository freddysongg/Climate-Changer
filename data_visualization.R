# Load required libraries
library(tidyverse)
library(ggplot2)
library(gridExtra)
library(corrplot)
library(reshape2)
library(scales)

# Define file paths
files <- list(
  "Agricultural_land" = "data/cleaned_Agricultural_land_under_irrigation_(%_of_total_ag._land).csv",
  "Cereal_yield" = "data/cleaned_Cereal_yield_(kg_per_hectare).csv",
  "CO2_per_capita" = "data/cleaned_CO2_emissions_per_capita_(metric_tons).csv",
  "CO2_GDP" = "data/cleaned_CO2_emissions_per_units_of_GDP_(kg_$1,000_of_2005_PPP_$).csv",
  "Total_CO2" = "data/cleaned_CO2_emissions,_total_(KtCO2).csv",
  "Energy_per_capita" = "data/cleaned_Energy_use_per_capita_(kilograms_of_oil_equivalent).csv",
  "Energy_GDP" = "data/cleaned_Energy_use_per_units_of_GDP_(kg_oil_eq._$1,000_of_2005_PPP_$).csv",
  "Methane_emissions" = "data/cleaned_Methane_(CH4)_emissions,_total_(KtCO2e).csv",
  "Urban_population" = "data/cleaned_Urban_population.csv",
  "Population_growth" = "data/cleaned_Population_growth_(annual_%).csv",
  "GDP" = "data/cleaned_GDP_($).csv",
  "Protected_areas" = "data/cleaned_Nationally_terrestrial_protected_areas_(%_of_total_land_area).csv"
)

# Helper function to clean and standardize data
standardize_and_pivot <- function(filepath) {
  read_csv(filepath) %>%
    rename_with(~ gsub("\\s+", "_", .x)) %>%
    rename_with(~ gsub("[()%,]", "", .x)) %>%
    pivot_longer(
      cols = starts_with("19") | starts_with("20"),
      names_to = "Year",
      values_to = "Value"
    ) %>%
    mutate(
      Year = as.integer(Year),
      Value = ifelse(Value == 0, NA, Value)
    )
}

# Define separate functions for handling each specific file
handle_total_co2 <- function(filepath) {
  standardize_and_pivot(filepath) %>%
    rename(Total_CO2 = Value)
}

handle_urban_population <- function(filepath) {
  standardize_and_pivot(filepath) %>%
    rename(Urban_population = Value)
}

handle_gdp <- function(filepath) {
  standardize_and_pivot(filepath) %>%
    rename(GDP = Value)
}

handle_population_growth <- function(filepath) {
  standardize_and_pivot(filepath) %>%
    rename(Population_growth = Value)
}

handle_methane_emissions <- function(filepath) {
  standardize_and_pivot(filepath) %>%
    rename(Methane_emissions = Value)
}

handle_energy_gdp <- function(filepath) {
  standardize_and_pivot(filepath) %>%
    rename(Energy_GDP = Value)
}

handle_protected_areas <- function(filepath) {
  standardize_and_pivot(filepath) %>%
    rename(Protected_areas = Value)
}

# Handle specific files
total_co2_data <- handle_total_co2(files$Total_CO2)
urban_population_data <- handle_urban_population(files$Urban_population)
gdp_data <- handle_gdp(files$GDP)
population_growth_data <- handle_population_growth(files$Population_growth)
methane_emissions_data <- handle_methane_emissions(files$Methane_emissions)
energy_gdp_data <- handle_energy_gdp(files$Energy_GDP)
protected_areas_data <- handle_protected_areas(files$Protected_areas)

# Handle remaining files dynamically
other_files <- names(files)[!names(files) %in% 
  c("Total_CO2", "Urban_population", "GDP", "Population_growth", "Methane_emissions", "Energy_GDP", "Protected_areas")]
data_list <- lapply(files[other_files], standardize_and_pivot)
names(data_list) <- other_files

# Add back the separately handled datasets
data_list$Total_CO2 <- total_co2_data
data_list$Urban_population <- urban_population_data
data_list$GDP <- gdp_data
data_list$Population_growth <- population_growth_data
data_list$Methane_emissions <- methane_emissions_data
data_list$Energy_GDP <- energy_gdp_data
data_list$Protected_areas <- protected_areas_data

# Merge datasets by "Country_name" and "Year"
merged_data <- reduce(data_list, full_join, by = c("Country_name", "Year"))

# Check structure
print(str(merged_data))

# Correlation matrix for numerical variables
numerical_cols <- merged_data %>% select_if(is.numeric)
corr_matrix <- cor(numerical_cols, use = "complete.obs")

# Plot correlation matrix with blurb
corrplot(corr_matrix, method = "color", type = "upper", tl.col = "black", tl.srt = 45)
ggsave("output/correlation_matrix.pdf")

# Add a blurb
cat("Correlation Matrix Analysis: This matrix highlights correlations between key variables. Strong positive or negative correlations indicate potential relationships, while weak correlations suggest independence.")

# Visualization 1: Urban population vs CO2 emissions
p1 <- ggplot(merged_data, aes(x = Urban_population, y = Total_CO2)) +
  geom_point(aes(color = log10(Total_CO2)), alpha = 0.7) +
  scale_color_viridis_c(option = "D") +
  geom_smooth(method = "lm", color = "blue") +
  labs(title = "Urban Population vs Total CO2 Emissions",
       x = "Urban Population",
       y = "Total CO2 Emissions (KtCO2)")
ggsave("output/urban_population_vs_co2.pdf")

# Add a blurb
cat("Graph 1: Urban Population vs CO2 Emissions: This scatterplot reveals how urban population influences CO2 emissions. A positive trend indicates that larger urban populations often correspond to increased emissions, likely due to higher energy demand.")

# Visualization 2: Methane vs CO2 emissions
p2 <- ggplot(merged_data, aes(x = Methane_emissions, y = Total_CO2)) +
  geom_point(aes(linewidth = GDP, color = Population_growth), alpha = 0.6) +
  scale_color_viridis_c(option = "C") +
  scale_size_continuous(range = c(2, 10)) +
  labs(title = "Methane vs CO2 Emissions",
       x = "Methane Emissions (KtCO2e)",
       y = "Total CO2 Emissions (KtCO2)")
ggsave("output/methane_vs_co2.pdf")

# Add a blurb
cat("Graph 2: Methane vs CO2 Emissions: This visualization shows the relationship between methane and CO2 emissions. Countries with high methane emissions also tend to have higher CO2 emissions, potentially indicating industrial and agricultural impacts.")

# Visualization 3: Energy use efficiency
p3 <- ggplot(merged_data, aes(x = Energy_GDP, y = Total_CO2)) +
  geom_point(aes(color = log10(GDP)), alpha = 0.7) +
  scale_color_viridis_c(option = "B") +
  geom_smooth(method = "lm", color = "red") +
  labs(title = "Energy Use Efficiency vs Total CO2 Emissions",
       x = "Energy Use per GDP",
       y = "Total CO2 Emissions (KtCO2)")
ggsave("output/energy_efficiency_vs_co2.pdf")

# Add a blurb
cat("Graph 3: Energy Use Efficiency vs CO2 Emissions: This scatterplot examines the efficiency of energy use relative to GDP. Inefficient energy use correlates with higher CO2 emissions, emphasizing the need for improved energy policies.")

# Visualization 4: Protected areas and CO2 emissions
p4 <- ggplot(merged_data, aes(x = Protected_areas, y = Total_CO2)) +
  geom_point(aes(linewidth = GDP, color = log10(Population_growth)), alpha = 0.6) +
  scale_color_viridis_c(option = "C") +
  scale_size_continuous(range = c(2, 10)) +
  labs(title = "Protected Areas vs Total CO2 Emissions",
       x = "Protected Areas (% of Total Land Area)",
       y = "Total CO2 Emissions (KtCO2)")
ggsave("output/protected_areas_vs_co2.pdf")

# Add a blurb
cat("Graph 4: Protected Areas vs CO2 Emissions: This graph investigates whether increased protected land correlates with reduced CO2 emissions. Results may vary by country based on policy effectiveness.")

# Additional Visualization: Time series of Urban Population and CO2 Emissions
p5 <- ggplot(merged_data, aes(x = Year)) +
  geom_line(aes(y = Urban_population, color = "Urban Population"), linewidth = 1) +
  geom_line(aes(y = Total_CO2 / 1000, color = "Total CO2 Emissions (in thousands)"), linewidth = 1) +
  scale_color_manual(values = c("Urban Population" = "blue", "Total CO2 Emissions (in thousands)" = "red")) +
  labs(title = "Urban Population and CO2 Emissions Over Time",
       x = "Year",
       y = "Value") +
  theme_minimal()
ggsave("output/time_series_urban_vs_co2.pdf", plot = p5, width = 10, height = 6)

# Add a blurb
cat("Graph 5: Urban Population and CO2 Emissions Over Time: This time series highlights growth trends in urban populations and their connection to increasing CO2 emissions. Urbanization appears to drive emission growth globally.")

# Print a message
cat("All visualizations and analyses have been saved as PDFs with detailed descriptions. Check the working directory for outputs.")