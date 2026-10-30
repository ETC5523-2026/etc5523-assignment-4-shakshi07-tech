
# ============================================================
# FIREPRINT
# Reproducible preparation of NASA FIRMS MODIS fire detections
# ============================================================
#
# Research question:
# How did the concentration of satellite-detected fire activity
# shift between selected periods of Australia's 2019-2020
# fire season?
#
# Data source:
# NASA FIRMS MODIS active fire detections, Australia,
# calendar years 2019 and 2020.
#
# Study period:
# 1 September 2019 to 29 February 2020 (inclusive).
#
# Important:
# A satellite detection is not necessarily a separate fire.
# Detection counts do not directly measure burned area,
# fire severity or the number of individual bushfires.
#
# Geographic approach:
# Observations are aggregated into 1-degree latitude-longitude
# cells. These cells are not equal in physical area, so spatial
# concentration is interpreted across the coordinate grid,
# not as the proportion of Australian land area affected.
#
# Run this script from the root of the fireprint package.
#
# Inputs:
#   data-raw/modis_2019_Australia.csv
#   data-raw/modis_2020_Australia.csv
#
# Output:
#   data/fire_cells.rda
#
# ============================================================


# 1. Check that the source files exist -----------------------

input_files <- c(
  "data-raw/modis_2019_Australia.csv",
  "data-raw/modis_2020_Australia.csv"
)

if (!all(file.exists(input_files))) {
  stop(
    "One or both MODIS source CSV files are missing ",
    "from the data-raw folder."
  )
}

cat("Both source files were found.\n")


# 2. Read and validate the original data --------------------

required_columns <- c(
  "latitude",
  "longitude",
  "acq_date"
)

read_modis <- function(path) {

  data <- read.csv(
    path,
    stringsAsFactors = FALSE
  )

  missing_columns <- setdiff(
    required_columns,
    names(data)
  )

  if (length(missing_columns) > 0) {
    stop(
      "Missing required columns in ",
      path,
      ": ",
      paste(missing_columns, collapse = ", ")
    )
  }

  data$acq_date <- as.Date(
    data$acq_date,
    format = "%Y-%m-%d"
  )

  if (anyNA(data$acq_date)) {
    stop(
      "Invalid or missing acquisition dates in ",
      path
    )
  }

  data
}

modis_2019 <- read_modis(input_files[1])
modis_2020 <- read_modis(input_files[2])

cat("\nOriginal source records:\n")
cat("2019:", nrow(modis_2019), "\n")
cat("2020:", nrow(modis_2020), "\n")

if (!identical(names(modis_2019), names(modis_2020))) {
  stop(
    "The two MODIS files do not have matching column names."
  )
}


# 3. Combine the two calendar-year datasets -----------------

fire_raw <- rbind(
  modis_2019,
  modis_2020
)

cat(
  "\nCombined source records:",
  nrow(fire_raw),
  "\n"
)


# 4. Validate geographical coordinates ---------------------

valid_coordinates <- (
  is.finite(fire_raw$latitude) &
    is.finite(fire_raw$longitude) &
    fire_raw$latitude >= -90 &
    fire_raw$latitude <= 90 &
    fire_raw$longitude >= -180 &
    fire_raw$longitude <= 180
)

invalid_count <- sum(!valid_coordinates)

cat(
  "Records with invalid coordinates:",
  invalid_count,
  "\n"
)

fire_raw <- fire_raw[
  valid_coordinates,
  ,
  drop = FALSE
]


# 5. Define the Australian fire-season study period ---------

study_start <- as.Date("2019-09-01")
study_end <- as.Date("2020-02-29")

in_study_period <- (
  fire_raw$acq_date >= study_start &
    fire_raw$acq_date <= study_end
)

fire_season <- fire_raw[
  in_study_period,
  ,
  drop = FALSE
]

cat(
  "\nDetections within study period:",
  nrow(fire_season),
  "\n"
)

if (nrow(fire_season) == 0) {
  stop("No observations remain in the study period.")
}


# 6. Create monthly and geographic identifiers --------------

# Each detection is assigned to its calendar month.

fire_season$month <- format(
  fire_season$acq_date,
  "%Y-%m"
)

# The lower-left coordinate of each 1-degree grid cell.
# For example, longitude 150.7 and latitude -33.8
# become cell_lon = 150 and cell_lat = -34.

fire_season$cell_lon <- floor(
  fire_season$longitude
)

fire_season$cell_lat <- floor(
  fire_season$latitude
)


# 7. Aggregate monthly detections by grid cell --------------

fire_cells <- aggregate(
  x = list(
    detections = rep(
      1L,
      nrow(fire_season)
    )
  ),
  by = list(
    month = fire_season$month,
    cell_lon = fire_season$cell_lon,
    cell_lat = fire_season$cell_lat
  ),
  FUN = sum
)

fire_cells <- fire_cells[
  order(
    fire_cells$month,
    fire_cells$cell_lat,
    fire_cells$cell_lon
  ),
  ,
  drop = FALSE
]

rownames(fire_cells) <- NULL


# 8. Validate the prepared dataset --------------------------

expected_months <- format(
  seq(
    from = as.Date("2019-09-01"),
    to = as.Date("2020-02-01"),
    by = "month"
  ),
  "%Y-%m"
)

observed_months <- sort(
  unique(fire_cells$month)
)

if (!identical(observed_months, expected_months)) {
  stop(
    "The prepared data do not contain all six ",
    "expected study months."
  )
}

if (sum(fire_cells$detections) != nrow(fire_season)) {
  stop(
    "The total detection count changed during aggregation."
  )
}

if (anyNA(fire_cells)) {
  stop(
    "Missing values were found in the prepared dataset."
  )
}

if (any(fire_cells$detections <= 0)) {
  stop(
    "Invalid detection counts were found."
  )
}

cat("\nAll preparation checks passed.\n")


# 9. Calculate monthly validation summaries ----------------

monthly_totals <- aggregate(
  detections ~ month,
  data = fire_cells,
  FUN = sum
)

monthly_cells <- aggregate(
  detections ~ month,
  data = fire_cells,
  FUN = length
)

names(monthly_cells)[2] <- "occupied_cells"

monthly_summary <- merge(
  monthly_totals,
  monthly_cells,
  by = "month"
)

cat("\nMonthly detection summary:\n")
print(monthly_summary, row.names = FALSE)

cat(
  "\nNumber of monthly grid-cell records:",
  nrow(fire_cells),
  "\n"
)

cat(
  "Total detections retained:",
  sum(fire_cells$detections),
  "\n"
)


# 10. Save the prepared dataset inside the R package --------

# The data/ directory will be created automatically.
# The resulting .rda file can be accessed by package users
# without needing the original CSV files at runtime.

usethis::use_data(
  fire_cells,
  overwrite = TRUE,
  compress = "xz"
)

if (!file.exists("data/fire_cells.rda")) {
  stop("The package dataset was not saved successfully.")
}

cat(
  "\nSUCCESS: data/fire_cells.rda has been created.\n"
)

cat(
  "Fireprint data preparation is complete.\n"
)
