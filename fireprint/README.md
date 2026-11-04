# Fireprint: Beyond the Flames

**Exploring how the geographic distribution and concentration of satellite-detected fire activity changed during Australia's 2019–2020 bushfire season.**

## About Fireprint

Australia's 2019–2020 bushfire season, widely known as *Black Summer*, brought unprecedented attention to the scale and consequences of bushfires across the country. Maps and satellite imagery helped communicate the extent of the crisis, but understanding the patterns behind those images requires looking more closely at when and where fire activity was recorded.

A month with more satellite fire detections does not necessarily have a wider geographic distribution of detections. Activity may be concentrated in a relatively small number of locations, while another month may show fewer detections spread across a larger number of locations.

**Fireprint: Beyond the Flames** was developed to explore this distinction.

Fireprint is an R package that combines a prepared satellite fire-detection dataset, a reusable comparison function and an interactive Shiny dashboard. It allows users to compare selected months of the 2019–2020 bushfire season and investigate differences in detection counts, geographic grid coverage and concentration.

The project is guided by one research question:

**How did the concentration of satellite-detected fire activity shift between selected periods of Australia's 2019–2020 fire season?**

Fireprint is intended for students, environmental monitoring analysts and others interested in exploring geographic patterns in satellite observations. The dashboard provides an accessible starting point for visual exploration, while the package's R functions allow the same comparisons to be reproduced programmatically.

## What can you explore?

The interactive dashboard allows users to compare any two different months between September 2019 and February 2020.

Rather than relying on a single measure of fire activity, Fireprint brings together several complementary views of the satellite detection records.

- **Monthly detection counts:** Compare the total number of recorded fire detections in each selected month.
- **Geographic grid coverage:** Examine how many 1-degree latitude–longitude grid cells contained at least one detection.
- **Interactive geographic comparisons:** Explore two maps with synchronised views, allowing the same parts of Australia to be examined across both months.
- **Individual grid-cell details:** Hover over coloured cells to inspect their detection counts and geographic coordinates.
- **Most active grid cells:** Identify the ten grid cells with the highest detection counts in each selected month.
- **Detection concentration:** Compare the proportion of monthly detections recorded within each month's ten most active grid cells.
- **Supporting interpretation:** Examine the differences alongside explanations of what the measures represent and the limitations that affect their interpretation.

Both maps use consistent detection-count categories so that the same colours represent the same count ranges across the selected months.

This matters because differences in map colours should reflect differences in the underlying records, rather than changes in the visual scale.

Taken together, these features help users investigate not only how many fire detections were recorded, but also how their geographic distribution differed throughout the season.

## Data source and preparation

Fireprint uses active-fire detection records obtained from NASA's **Fire Information for Resource Management System (FIRMS)**. The records used in this project come from the Moderate Resolution Imaging Spectroradiometer (MODIS), carried aboard NASA's Terra and Aqua satellites.

The analysis focuses on Australia from **September 2019 to February 2020**, covering six consecutive months of the 2019–2020 bushfire season.

The original detection records contain geographic coordinates and observation information. To make geographic comparisons more manageable, detections were grouped into 1-degree latitude–longitude grid cells. The number of detections was then calculated for each grid cell and month.

This approach provides a consistent geographic framework for comparing the distribution of recorded detections without plotting every individual observation.

The resulting dataset, `fire_cells`, is included directly in the package.

The original source files and the R script used to prepare the dataset are retained in the `data-raw/` directory. This makes the preparation process inspectable and reproducible from the supplied source records.

Because the processed dataset is packaged with Fireprint, users do not need to download the original MODIS files or run the preparation script simply to use the dashboard.

**Original data source:** [NASA FIRMS](https://firms.modaps.eosdis.nasa.gov/)

## Installation

Fireprint can be installed directly from its GitHub Classroom repository.

First, install the `remotes` package if it is not already available:

```r
install.packages("remotes")
```

Then install Fireprint:

```r
remotes::install_github(
  "ETC5523-2026/etc5523-assignment-4-shakshi07-tech",
  subdir = "fireprint",
  dependencies = NA,
  upgrade = "never"
)
```

The `subdir = "fireprint"` argument is necessary because the R package is located inside the `fireprint` folder of the assignment repository.

Required dependencies, including shiny, leaflet, bslib, htmltools and htmlwidgets, are automatically installed if they are not already available.

The package has been successfully checked using devtools::check(), with 0 errors, 0 warnings and 0 notes. Installation on another computer should be verified separately.

## Launching the interactive dashboard

After installation, load the package and launch the dashboard:

```r
library(fireprint)

run_fireprint()
```

The Shiny application opens in a browser, where users can select two months and explore the corresponding geographic patterns.

All dashboard comparisons use the processed dataset supplied with the package. No additional CSV files need to be loaded at runtime.

To begin, select two different months, examine the summary measures and compare the maps. Hovering over grid cells reveals the detection counts associated with individual locations.

The accompanying interpretation helps connect the numerical differences with the geographic patterns shown on the maps.

## Using the comparison function

Fireprint also provides an exported function, `compare_fire_periods()`, for users who want to reproduce the analysis directly in R.

For example, the following code compares November 2019 with January 2020:

```r
library(fireprint)

result <- compare_fire_periods(
  month_a = "2019-11",
  month_b = "2020-01"
)

result$summary
result$comparison
```

The function returns three components:

| Component | What it contains |
|---|---|
| `summary` | Detection totals, occupied grid cells and concentration measures for each selected month |
| `comparison` | Differences between the selected months in detection counts, occupied cells and concentration |
| `grid_data` | Grid-level detection records for the two selected months |

Separating the comparison function from the dashboard makes the analytical method reusable. Users can inspect the results in R, incorporate them into other analyses or reproduce the comparisons without relying on the interactive interface.

Further information about the function's arguments and returned values is available through its reference documentation:

```r
?fireprint::compare_fire_periods
```

## Understanding the measures

Fireprint uses three related measures to describe different aspects of satellite-detected fire activity.

### Detection volume

Detection volume is the total number of satellite fire detections recorded during a selected month.

It describes the amount of recorded detection activity, but it does not represent the number of separate bushfires.

A higher total means that more detections were recorded. It does not necessarily mean that more individual fires occurred or that a larger area burned.

### Geographic grid coverage

Geographic grid coverage is measured by counting the number of 1-degree latitude–longitude grid cells containing at least one detection during a selected month.

This provides a descriptive indication of how widely the detections were distributed across the geographic grid.

Two months may have similar detection totals but different numbers of occupied cells, suggesting that their recorded activity was distributed differently.

However, an occupied grid cell is not equivalent to a measured burned area, and the physical area represented by a 1-degree cell varies with latitude.

### Detection concentration

Detection concentration measures the percentage of a month's detections recorded within its ten most active grid cells.

It is calculated as:

**Concentration (%) = (Detections in the ten most active grid cells ÷ Total monthly detections) × 100**

A higher percentage means that a greater share of that month's recorded detections occurred within its ten most active cells.

A lower percentage means that those cells accounted for a smaller share of the month's total detections.

The ten most active cells are identified separately for each month. They are therefore not necessarily the same geographic locations in both periods.

This measure provides a useful summary of relative concentration, although it does not capture every aspect of the geographic distribution.

### Why consider these measures together?

Each measure addresses a different part of the research question.

Detection volume describes **how many detections were recorded**. Grid coverage describes **how many geographic cells contained detections**. Concentration describes **how much of the recorded activity occurred within the most active cells**.

A month may have fewer detections overall but a higher concentration percentage. Conversely, a month with more detections may have activity distributed across a greater number of grid cells.

Examining these measures together helps avoid treating the total number of detections as a complete description of geographic fire activity.

## Important limitations

Satellite fire-detection records offer valuable opportunities to examine patterns over time and across locations. However, several limitations are important when interpreting Fireprint's results.

**Satellite detections are not individual fire events.** A single fire may generate multiple detections, while some fires may not be recorded. Detection counts should therefore not be interpreted as counts of unique bushfires.

**Detection counts do not directly measure burned area or severity.** The number of recorded detections cannot establish how much land burned, how intense the fires were or the extent of environmental and community impacts.

**Observation conditions influence detection records.** Cloud cover, smoke, satellite observation timing and sensor characteristics can affect whether active fires are detected. Differences between months may reflect both changes in fire activity and variation in observation conditions.

**The geographic grid is not equal-area.** Although the analysis uses consistent 1-degree latitude–longitude cells, their physical area varies with latitude. The number of occupied cells is therefore a measure of grid coverage, not a direct estimate of affected land area.

**Concentration is a descriptive measure rather than an explanation.** The percentage of detections in the ten most active cells helps describe differences between months, but it does not identify the causes of those differences.

For these reasons, Fireprint should be understood as a tool for exploring patterns in recorded satellite detections, rather than estimating the full physical, ecological or social consequences of the bushfire season.

## Package structure and reproducibility

Fireprint is organised as an R package so that its data, functions, documentation and interactive application can be accessed through a consistent workflow.

| Component | Purpose |
|---|---|
| `data/fire_cells.rda` | Prepared monthly grid-cell detection dataset |
| `data-raw/` | Original source files and the script used to prepare the packaged dataset |
| `R/compare_fire_periods.R` | Reusable function for comparing selected months |
| `R/run_fireprint.R` | Exported function for launching the Shiny application |
| `inst/shiny/` | Interactive Shiny dashboard |
| `man/` | Documentation for the exported functions and dataset |
| `vignettes/exploring-fire-patterns.Rmd` | Worked example explaining the comparison and interpretation |
| `README.md` | Project overview, installation instructions and usage guidance |

The package separates data preparation, analytical calculations and interactive presentation. This allows the underlying method to be inspected independently of the dashboard and makes it easier for other users to understand how the results were produced.

## Package website

Fireprint has a publicly accessible pkgdown website containing the package overview, installation instructions, function reference pages, dataset documentation and a worked example.

**Website:** https://etc5523-2026.github.io/etc5523-assignment-4-shakshi07-tech/

The website includes reference pages for `compare_fire_periods()`, `run_fireprint()` and `fire_cells`.

It also includes the article **Exploring Fire Detection Patterns with Fireprint**, which demonstrates how to reproduce a comparison in R, interpret the resulting measures and consider the limitations of satellite fire-detection data.

## Licence and data attribution

The Fireprint package code is released under the MIT licence.

The underlying MODIS active-fire detection records were obtained from NASA FIRMS. These source data remain subject to the original provider's applicable terms and attribution requirements.

The project acknowledges the use of data from NASA's Land, Atmosphere Near real-time Capability for Earth observations (LANCE), part of NASA's Earth Science Data and Information System (ESDIS).

**Data provider:** NASA Fire Information for Resource Management System (FIRMS).

**Source information:** [NASA FIRMS](https://firms.modaps.eosdis.nasa.gov/) and [NASA LANCE](https://www.earthdata.nasa.gov/data/projects/lance).

## Generative AI declaration

I used **ChatGPT (OpenAI)** as a supporting tool during the planning, development, debugging and documentation of Fireprint. Its use primarily involved clarifying unfamiliar technical concepts, exploring possible implementation approaches, troubleshooting errors and improving the communication of analytical results.

AI assistance was used in the following areas:

- **R package development:** Understanding the structure of an R package, the roles of `DESCRIPTION`, `NAMESPACE`, `R/`, `data/`, `data-raw/` and `inst/`, and how to document exported functions and datasets using `roxygen2`.
- **Data preparation and analytical methods:** Discussing how satellite fire detections could be aggregated into geographic grid cells, how to compare detection counts across months, and how to distinguish geographic concentration from detection volume.
- **Shiny application development:** Understanding reactive programming, connecting month-selection inputs to analytical functions, displaying interactive maps and summary measures, and considering how the application should respond to invalid or uninformative comparisons.
- **Debugging and reproducibility:** Investigating R errors, checking package dependencies, troubleshooting GitHub installation, understanding `devtools::check()` results and resolving package-documentation or deployment issues.
- **Documentation and communication:** Improving the clarity and organisation of the README, function documentation and analytical vignette, particularly when explaining results, assumptions and limitations.

### Examples of AI-assisted questions

The following are representative examples of the types of questions and prompts used during development, rather than verbatim transcripts of every interaction:

1. *"What is the difference between an ordinary R project and an R package, and why are folders such as `R/`, `data/`, `data-raw/` and `inst/` needed?"*

2. *"How can satellite fire-detection records be grouped into geographic grid cells so that their distribution can be compared across different months?"*

3. *"How should I interpret a situation where one month has fewer fire detections but a higher proportion of detections in its ten most active grid cells?"*

4. *"How does Shiny's reactive programming work, and how can changes in two month-selection inputs update summary statistics and interactive maps?"*

5. *"What is the purpose of `roxygen2`, and how can I document an exported comparison function and a packaged dataset?"*

6. *"How can I troubleshoot errors when installing an R package from a GitHub repository, particularly when the package is stored in a subdirectory?"*

7. *"What should I check when `devtools::check()` reports an error, warning or note, and how can I verify that my package is ready for installation?"*

8. *"How can I explain the limitations of MODIS active-fire detections without incorrectly treating them as measurements of burned area, fire severity or the number of individual fires?"*

9. *"How can I organise my README and pkgdown documentation so that users can understand the package's purpose, installation process, functions and analytical limitations?"*

### Review and responsibility

AI-generated explanations, code suggestions and documentation drafts were reviewed and adapted throughout development. I tested the package functions, examined the dashboard's behaviour, checked installation and package diagnostics, and revised the written explanations to reflect the actual implementation.

ChatGPT was used as a learning and development aid rather than as an independent source of scientific evidence. The final code, analytical choices, interpretation of results and submitted work remain my responsibility.

## Author

**Shakshi Shah**

Master of Business Analytics  
Monash University

ETC5523 — Communicating with Data  
Assignment 4
