# Monthly Satellite Fire Detections in Australia

A prepared dataset of NASA FIRMS MODIS satellite-detected fire activity
across Australia from September 2019 to February 2020, inclusive.

## Usage

``` r
fire_cells
```

## Format

A data frame with 2,006 rows and 4 variables:

- month:

  Calendar month in YYYY-MM format.

- cell_lon:

  Western longitude boundary of the grid cell, in degrees.

- cell_lat:

  Southern latitude boundary of the grid cell, in degrees.

- detections:

  Number of satellite detections recorded in that month and grid cell.

## Source

NASA Fire Information for Resource Management System (FIRMS), MODIS
active fire detections. https://firms.modaps.eosdis.nasa.gov/

## Details

Individual observations are aggregated by calendar month and 1-degree
latitude-longitude grid cell.

Each row represents a month and an occupied grid cell. Grid cells have
equal angular dimensions but unequal physical areas, so the data should
not be interpreted as an equal-area measure of fire activity.

Satellite detections do not represent unique bushfires and do not
directly measure burned area or severity. Observations are subject to
satellite coverage and detection conditions.
