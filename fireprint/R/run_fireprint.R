#' Launch the Fireprint dashboard
#'
#' Opens the interactive Fireprint dashboard to compare satellite-detected
#' fire activity across Australia's 2019–2020 fire season.
#'#' @import shiny
#' @import bslib
#' @import htmltools
#' @import htmlwidgets
#' @import leaflet
#'
#' @return Launches a Shiny application.
#' @export
#'
#' @examples
#' \dontrun{
#'   run_fireprint()
#' }
run_fireprint <- function() {
  app_dir <- system.file("shiny", package = "fireprint")

  if (app_dir == "") {
    stop("The Fireprint Shiny application could not be found.")
  }

  shiny::runApp(app_dir, launch.browser = TRUE)
}
