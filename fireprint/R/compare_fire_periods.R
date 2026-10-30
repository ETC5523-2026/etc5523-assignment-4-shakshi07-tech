
#' Compare Fire Detection Patterns Between Two Months
#'
#' Compares the volume, geographic spread and concentration
#' of satellite-detected fire activity between two months
#' in Australia's 2019-2020 fire season.
#'
#' @param month_a Character string in YYYY-MM format.
#'   The first comparison month.
#' @param month_b Character string in YYYY-MM format.
#'   The second comparison month.
#' @param data A data frame containing the monthly grid-cell
#'   observations. Defaults to the packaged `fire_cells` data.
#' @param top_n Positive whole number of grid cells used to
#'   calculate the concentration measure. Default is 10.
#'
#' @return A list containing:
#' \describe{
#'   \item{summary}{A two-row data frame with detection totals,
#'   occupied grid cells, and top-cell concentration percentages.}
#'   \item{comparison}{A one-row data frame describing the
#'   difference between the two selected months.}
#'   \item{grid_data}{Grid-cell observations for both months,
#'   suitable for visualisation.}
#' }
#'
#' @details
#' The concentration measure is the percentage of detections
#' recorded in the `top_n` most active 1-degree grid cells
#' within each month.
#'
#' A higher percentage indicates that detections were more
#' concentrated in a small number of grid cells.
#'
#' Grid cells are not equal-area, and satellite detections
#' do not directly represent burned area or fire severity.
#'
#' @examples
#' compare_fire_periods("2019-11", "2020-01")
#'
#' @export
compare_fire_periods <- function(
    month_a,
    month_b,
    data = fire_cells,
    top_n = 10L
) {

  # 1. Validate the selected months

  if (
    !is.character(month_a) ||
    length(month_a) != 1L ||
    is.na(month_a) ||
    !is.character(month_b) ||
    length(month_b) != 1L ||
    is.na(month_b)
  ) {
    stop("Both months must be single character strings.")
  }

  if (identical(month_a, month_b)) {
    stop("Please select two different months.")
  }

  # 2. Validate the input dataset

  required_columns <- c(
    "month",
    "cell_lon",
    "cell_lat",
    "detections"
  )

  if (!is.data.frame(data) ||
      !all(required_columns %in% names(data))) {
    stop("The dataset is missing required columns.")
  }

  if (
    !is.numeric(data$detections) ||
    anyNA(data[required_columns]) ||
    any(!is.finite(data$detections)) ||
    any(data$detections <= 0)
  ) {
    stop("The dataset contains invalid detection values.")
  }

  available_months <- sort(unique(data$month))

  if (
    !(month_a %in% available_months) ||
    !(month_b %in% available_months)
  ) {
    stop(
      "One or both months are unavailable. Choose from: ",
      paste(available_months, collapse = ", ")
    )
  }

  # 3. Validate the concentration setting

  if (
    !is.numeric(top_n) ||
    length(top_n) != 1L ||
    is.na(top_n) ||
    !is.finite(top_n) ||
    top_n < 1 ||
    top_n != floor(top_n)
  ) {
    stop("top_n must be a positive whole number.")
  }

  # 4. Extract observations for each month

  data_a <- data[
    data$month == month_a,
    ,
    drop = FALSE
  ]

  data_b <- data[
    data$month == month_b,
    ,
    drop = FALSE
  ]

  # 5. Calculate monthly concentration statistics

  summarise_month <- function(month_data) {

    total <- sum(month_data$detections)

    # Aggregate again by location to ensure one count
    # per grid cell, even if input rows are duplicated.
    cells <- stats::aggregate(
      detections ~ cell_lon + cell_lat,
      data = month_data,
      FUN = sum
    )

    ranked_counts <- sort(
      cells$detections,
      decreasing = TRUE
    )

    n_selected <- min(top_n, length(ranked_counts))

    top_share <- (
      sum(ranked_counts[seq_len(n_selected)]) /
        total
    ) * 100

    data.frame(
      month = unique(month_data$month)[1],
      total_detections = total,
      occupied_cells = nrow(cells),
      top_n_cells = n_selected,
      top_cell_share_pct = round(top_share, 2)
    )
  }

  summary_a <- summarise_month(data_a)
  summary_b <- summarise_month(data_b)

  monthly_summary <- rbind(
    summary_a,
    summary_b
  )

  rownames(monthly_summary) <- NULL

  # 6. Calculate differences between selected months

  comparison <- data.frame(
    month_a = month_a,
    month_b = month_b,

    detection_change = (
      summary_b$total_detections -
        summary_a$total_detections
    ),

    detection_change_pct = round(
      (
        summary_b$total_detections -
          summary_a$total_detections
      ) /
        summary_a$total_detections * 100,
      2
    ),

    occupied_cell_change = (
      summary_b$occupied_cells -
        summary_a$occupied_cells
    ),

    concentration_change_pp = round(
      summary_b$top_cell_share_pct -
        summary_a$top_cell_share_pct,
      2
    )
  )

  # 7. Prepare grid observations for the Shiny app
  grid_data <- rbind(
    data_a,
    data_b
  )

  rownames(grid_data) <- NULL

  # 8. Return all outputs

  list(
    summary = monthly_summary,
    comparison = comparison,
    grid_data = grid_data
  )
}
