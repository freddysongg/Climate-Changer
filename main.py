import pandas as pd

# Load the Excel file
file_path = "data/climate_data.xls"
data = pd.ExcelFile(file_path)

# Check sheet names
print(data.sheet_names)

# Load the first sheet to inspect the data
df = data.parse(sheet_name=data.sheet_names[0])
print(df.head())
