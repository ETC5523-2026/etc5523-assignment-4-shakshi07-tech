
library(shiny)
library(bslib)
library(leaflet)
library(htmltools)

fire_data <- get(
  "fire_cells",
  envir = asNamespace("fireprint")
)

available_months <- sort(unique(fire_data$month))

month_labels <- setNames(
  available_months,
  format(
    as.Date(paste0(available_months, "-01")),
    "%B %Y"
  )
)

format_month <- function(month) {
  format(
    as.Date(paste0(month, "-01")),
    "%B %Y"
  )
}

format_number <- function(x) {
  format(
    x,
    big.mark = ",",
    scientific = FALSE,
    trim = TRUE
  )
}

# The same detection ranges are used on both maps.
# Smaller ranges help reveal differences in less active areas.

fire_breaks <- c(
  0, 10, 50, 200, 500, 1000, 3000, Inf
)

fire_colors <- c(
  "#FFF1C9",
  "#FFD38B",
  "#FFAA58",
  "#F47738",
  "#D8492E",
  "#A52A30",
  "#651B24"
)

fire_labels <- c(
  "1–9",
  "10–49",
  "50–199",
  "200–499",
  "500–999",
  "1,000–2,999",
  "3,000+"
)

fire_category <- function(x) {
  cut(
    x,
    breaks = fire_breaks,
    labels = fire_labels,
    right = FALSE,
    include.lowest = TRUE
  )
}

fire_palette <- colorFactor(
  palette = fire_colors,
  domain = fire_labels,
  ordered = TRUE,
  na.color = "transparent"
)

# Both maps start with the same view of Australia.

create_fire_map <- function(month_data, month, map_id) {

  month_data <- month_data[
    month_data$detections > 0,
    ,
    drop = FALSE
  ]

  month_data <- month_data[
    order(
      month_data$detections,
      decreasing = TRUE
    ),
    ,
    drop = FALSE
  ]

  month_data$rank <- seq_len(nrow(month_data))

  month_data$is_top_ten <- month_data$rank <= 10

  month_data$fire_band <- as.character(
    fire_category(month_data$detections)
  )

  hover_text <- sprintf(
    paste0(
      "<strong>Fire detection grid cell</strong>",
      "<br>Month: %s",
      "<br>Detections: %s",
      "<br>Activity range: %s",
      "<br>Longitude: %.0f° to %.0f°",
      "<br>Latitude: %.0f° to %.0f°",
      "<br>%s"
    ),
    format_month(month),
    format_number(month_data$detections),
    month_data$fire_band,
    month_data$cell_lon,
    month_data$cell_lon + 1,
    month_data$cell_lat,
    month_data$cell_lat + 1,
    ifelse(
      month_data$is_top_ten,
      paste0(
        "Top 10 cell — rank ",
        month_data$rank
      ),
      "Other recorded cell"
    )
  )

  map <- leaflet(
    data = month_data,
    options = leafletOptions(
      minZoom = 3,
      maxZoom = 12
    )
  ) |>
    addProviderTiles(
      providers$OpenStreetMap,
      group = "Geographic background"
    ) |>
    setView(
      lng = 134,
      lat = -25,
      zoom = 4
    ) |>
    addRectangles(
      lng1 = ~cell_lon,
      lat1 = ~cell_lat,
      lng2 = ~cell_lon + 1,
      lat2 = ~cell_lat + 1,
      fillColor = ~fire_palette(fire_band),
      fillOpacity = 0.82,
      color = "#F8E4CB",
      weight = 0.3,
      opacity = 0.5,
      label = lapply(hover_text, HTML),
      labelOptions = labelOptions(
        direction = "auto",
        opacity = 0.97,
        textsize = "12px"
      ),
      group = "Fire detections"
    )

  top_cells <- month_data[
    month_data$is_top_ten,
    ,
    drop = FALSE
  ]

  if (nrow(top_cells) > 0) {

    top_labels <- sprintf(
      paste0(
        "<strong>Top 10 active grid cell</strong>",
        "<br>Rank: %s",
        "<br>Month: %s",
        "<br>Detections: %s",
        "<br>Grid: %.0f°E, %.0f°"
      ),
      top_cells$rank,
      format_month(month),
      format_number(top_cells$detections),
      top_cells$cell_lon,
      top_cells$cell_lat
    )

    map <- map |>
      addRectangles(
        data = top_cells,
        lng1 = ~cell_lon,
        lat1 = ~cell_lat,
        lng2 = ~cell_lon + 1,
        lat2 = ~cell_lat + 1,
        fill = FALSE,
        color = "#00E5CF",
        weight = 2.5,
        opacity = 1,
        label = lapply(top_labels, HTML),
        group = "Top 10 cells"
      )
  }

  map <- map |>
    addLegend(
      position = "bottomright",
      colors = fire_colors,
      labels = fire_labels,
      title = HTML(
        "<strong>Fire detections</strong><br>per grid cell"
      ),
      opacity = 0.95
    )

  # Moving one map updates the other map's view.
  # The guard prevents the maps from repeatedly updating each other.

  sync_js <- sprintf(
    "
    function(el, x) {
      var map = this;
      var sourceId = '%s';
      var otherId = '%s';

      map.on('moveend', function() {
        if (window.fireprintSyncing) return;

        var otherElement = document.getElementById(otherId);
        if (!otherElement) return;

        var otherMap = HTMLWidgets.find('#' + otherId);
        if (!otherMap || !otherMap.getMap) return;

        var targetMap = otherMap.getMap();
        if (!targetMap) return;

        var centre = map.getCenter();
        var zoom = map.getZoom();

        var targetCentre = targetMap.getCenter();

        if (
          targetMap.getZoom() === zoom &&
          Math.abs(targetCentre.lat - centre.lat) < 0.00001 &&
          Math.abs(targetCentre.lng - centre.lng) < 0.00001
        ) return;

        window.fireprintSyncing = true;

        targetMap.setView(centre, zoom, {
          animate: false
        });

        setTimeout(function() {
          window.fireprintSyncing = false;
        }, 150);
      });
    }
    ",
    map_id,
    if (map_id == "map_a") "map_b" else "map_a"
  )

  htmlwidgets::onRender(map, sync_js)
}

ui <- page_fluid(

  theme = bs_theme(
    version = 5,
    bg = "#101820",
    fg = "#F4F5F7",
    primary = "#F28C45",
    base_font = font_google("Inter")
  ),

  tags$head(
    tags$style(HTML("
      body {
        background: #101820;
      }

      .fire-header {
        padding: 28px 0 24px;
      }

      .fire-brand {
        color: #F28C45;
        font-size: 13px;
        font-weight: 800;
        letter-spacing: 3px;
        margin-bottom: 14px;
      }

      .fire-subtitle {
        color: #B8C4CE;
        font-size: 16px;
        line-height: 1.7;
      }

      .fire-panel {
        background: #1C2A34;
        border: 1px solid #34444E;
        border-radius: 17px;
        padding: 24px;
        margin-bottom: 20px;
      }

      .fire-section {
        color: #FF9C53;
        font-size: 12px;
        font-weight: 800;
        letter-spacing: 2px;
        margin-bottom: 12px;
      }

      .fire-card {
        background: #192A35;
        border: 1px solid #34444E;
        border-radius: 15px;
        padding: 22px;
        margin-bottom: 18px;
        height: 100%;
      }

      .fire-card-label {
        color: #B8C4CE;
        font-size: 14px;
      }

      .fire-card-value {
        color: white;
        font-size: 31px;
        font-weight: 750;
        margin: 12px 0;
      }

      .fire-card-note {
        color: #AFC5D4;
        font-size: 12px;
      }

      .form-select {
        background-color: #101820;
        color: white;
        border-color: #52616B;
      }

      .leaflet-container {
        border-radius: 12px;
      }

      .leaflet-tooltip {
        color: #17232B;
        font-size: 12px;
      }

      .leaflet-control-layers,
      .leaflet-control.leaflet-control-attribution,
      .leaflet-control .info {
        color: #222;
      }

      .info.legend {
        background: rgba(255,255,255,0.96);
        padding: 10px;
        border-radius: 8px;
        font-size: 12px;
        line-height: 1.5;
      }

      .fire-note {
        color: #B8C4CE;
        font-size: 13px;
        line-height: 1.7;
        margin-top: 12px;
      }

      .fire-insight {
        background: #233540;
        border-left: 4px solid #F28C45;
        border-radius: 0 10px 10px 0;
        padding: 18px;
        line-height: 1.8;
      }

      .fire-table {
        color: #F4F5F7;
        width: 100%;
        font-size: 13px;
      }

      .fire-table th,
      .fire-table td {
        padding: 9px;
        border-bottom: 1px solid #40505A;
      }

      .fire-table th {
        color: #FFB67C;
      }
    "))
  ),

  div(
    class = "fire-header",

    div(
      class = "fire-brand",
      "FIREPRINT / BEYOND THE FLAMES"
    ),

    h1(
      "Where did fire activity concentrate?"
    ),

    p(
      class = "fire-subtitle",
      paste(
        "Compare satellite-detected fire activity across",
        "Australia's 2019–2020 fire season.",
        "Explore changes in detection volumes,",
        "geographic spread and concentration."
      )
    )
  ),

  div(
    class = "fire-panel",

    div(
      class = "fire-section",
      "01 / CHOOSE YOUR COMPARISON"
    ),

    h3("Two periods. One geographic story."),

    p(
      class = "fire-subtitle",
      paste(
        "Select two different months.",
        "Both maps use the same detection-count ranges."
      )
    ),

    fluidRow(
      column(
        6,
        selectInput(
          "month_a",
          "Period A",
          choices = month_labels,
          selected = "2019-11",
          width = "100%"
        )
      ),

      column(
        6,
        selectInput(
          "month_b",
          "Period B",
          choices = month_labels,
          selected = "2020-01",
          width = "100%"
        )
      )
    )
  ),

  uiOutput("comparison_content"),

  div(
    class = "fire-panel",

    div(
      class = "fire-section",
      "READING THE EVIDENCE"
    ),

    h3("What these maps can — and cannot — tell us"),

    p(
      paste(
        "Each coloured square is a 1-degree",
        "latitude–longitude grid cell.",
        "Its colour represents the number of",
        "MODIS satellite fire detections",
        "recorded during the selected month."
      )
    ),

    p(
      paste(
        "The legend uses uneven detection-count ranges",
        "to make lower-activity areas easier to distinguish.",
        "The same ranges are applied to both maps."
      )
    ),

    p(
      paste(
        "A detection is not necessarily a separate bushfire.",
        "Detection totals are affected by satellite",
        "observation conditions and do not directly",
        "measure burned area, severity or damage."
      )
    ),

    p(
      paste(
        "Grid cells also vary in physical area",
        "with latitude. Occupied-cell counts describe",
        "geographic grid coverage rather than",
        "a precise estimate of land area."
      )
    )
  ),

  p(
    class = "fire-note",
    paste(
      "Data source: NASA FIRMS MODIS satellite",
      "fire-detection records for Australia.",
      "Study period: September 2019–February 2020.",
      "Map background: OpenStreetMap."
    )
  )
)

server <- function(input, output, session) {

  valid_comparison <- reactive({
    req(input$month_a, input$month_b)

    input$month_a != input$month_b
  })

  comparison <- reactive({
    req(valid_comparison())

    compare_fire_periods(
      input$month_a,
      input$month_b
    )
  })

  month_data_a <- reactive({
    req(valid_comparison())

    fire_data[
      fire_data$month == input$month_a,
      ,
      drop = FALSE
    ]
  })

  month_data_b <- reactive({
    req(valid_comparison())

    fire_data[
      fire_data$month == input$month_b,
      ,
      drop = FALSE
    ]
  })

  output$comparison_content <- renderUI({

    if (!valid_comparison()) {
      return(
        div(
          class = "fire-panel",

          h3("Choose two different months"),

          p(
            paste(
              "Period A and Period B are currently",
              "the same. Select another month to",
              "compare changes in fire activity."
            )
          )
        )
      )
    }

    tagList(

      div(
        class = "fire-section",
        "02 / THE NUMBERS BEHIND THE MAPS"
      ),

      fluidRow(
        column(
          3,
          div(
            class = "fire-card",
            div(
              class = "fire-card-label",
              "Detections / Period A"
            ),
            div(
              class = "fire-card-value",
              textOutput("detections_a")
            ),
            div(
              class = "fire-card-note",
              textOutput("month_label_a")
            )
          )
        ),

        column(
          3,
          div(
            class = "fire-card",
            div(
              class = "fire-card-label",
              "Detections / Period B"
            ),
            div(
              class = "fire-card-value",
              textOutput("detections_b")
            ),
            div(
              class = "fire-card-note",
              textOutput("month_label_b")
            )
          )
        ),

        column(
          3,
          div(
            class = "fire-card",
            div(
              class = "fire-card-label",
              "Change in detections"
            ),
            div(
              class = "fire-card-value",
              textOutput("detection_change")
            ),
            div(
              class = "fire-card-note",
              "Relative to Period A"
            )
          )
        ),

        column(
          3,
          div(
            class = "fire-card",
            div(
              class = "fire-card-label",
              "Top-10 share change"
            ),
            div(
              class = "fire-card-value",
              textOutput("concentration_change")
            ),
            div(
              class = "fire-card-note",
              "Percentage-point difference"
            )
          )
        )
      ),

      fluidRow(
        column(
          4,
          div(
            class = "fire-card",
            div(
              class = "fire-card-label",
              "Occupied grid cells / Period A"
            ),
            div(
              class = "fire-card-value",
              textOutput("cells_a")
            ),
            div(
              class = "fire-card-note",
              "Cells with recorded detections"
            )
          )
        ),

        column(
          4,
          div(
            class = "fire-card",
            div(
              class = "fire-card-label",
              "Occupied grid cells / Period B"
            ),
            div(
              class = "fire-card-value",
              textOutput("cells_b")
            ),
            div(
              class = "fire-card-note",
              "Cells with recorded detections"
            )
          )
        ),

        column(
          4,
          div(
            class = "fire-card",
            div(
              class = "fire-card-label",
              "Change in occupied cells"
            ),
            div(
              class = "fire-card-value",
              textOutput("cell_change")
            ),
            div(
              class = "fire-card-note",
              "Period B minus Period A"
            )
          )
        )
      ),

      div(
        class = "fire-section",
        "03 / EXPLORE THE GEOGRAPHIC SHIFT"
      ),

      fluidRow(
        column(
          6,
          div(
            class = "fire-panel",

            h4(
              paste(
                "Period A —",
                format_month(input$month_a)
              )
            ),

            leafletOutput(
              "map_a",
              height = "540px"
            ),

            p(
              class = "fire-note",
              paste(
                "Hover over a coloured cell for",
                "its detection count and location.",
                "Turquoise outlines mark the",
                "ten most active grid cells."
              )
            )
          )
        ),

        column(
          6,
          div(
            class = "fire-panel",

            h4(
              paste(
                "Period B —",
                format_month(input$month_b)
              )
            ),

            leafletOutput(
              "map_b",
              height = "540px"
            ),

            p(
              class = "fire-note",
              paste(
                "Both maps use the same colour",
                "categories. Zoom or pan either",
                "map to explore the same area."
              )
            )
          )
        )
      ),

      div(
        class = "fire-panel",

        div(
          class = "fire-section",
          "04 / THE MOST ACTIVE GRID CELLS"
        ),

        h3("Where were detections highest?"),

        p(
          class = "fire-subtitle",
          paste(
            "These are the ten grid cells with",
            "the most satellite detections in",
            "each selected month.",
            "Coordinates identify grid cells,",
            "not named suburbs or administrative regions."
          )
        ),

        fluidRow(
          column(
            6,
            h4(
              paste(
                "Period A —",
                format_month(input$month_a)
              )
            ),
            tableOutput("top_cells_a")
          ),

          column(
            6,
            h4(
              paste(
                "Period B —",
                format_month(input$month_b)
              )
            ),
            tableOutput("top_cells_b")
          )
        )
      ),

      div(
        class = "fire-panel",

        div(
          class = "fire-section",
          "INTERPRETATION / WHAT CHANGED?"
        ),

        h3("Reading the comparison"),

        div(
          class = "fire-insight",
          textOutput("interpretation")
        )
      )
    )
  })

  output$month_label_a <- renderText({
    format_month(input$month_a)
  })

  output$month_label_b <- renderText({
    format_month(input$month_b)
  })

  output$detections_a <- renderText({
    format_number(
      comparison()$summary$total_detections[1]
    )
  })

  output$detections_b <- renderText({
    format_number(
      comparison()$summary$total_detections[2]
    )
  })

  output$detection_change <- renderText({
    x <- comparison()$comparison$detection_change_pct

    sprintf("%+.2f%%", x)
  })

  output$concentration_change <- renderText({
    x <- comparison()$comparison$concentration_change_pp

    sprintf("%+.2f pp", x)
  })

  output$cells_a <- renderText({
    format_number(
      comparison()$summary$occupied_cells[1]
    )
  })

  output$cells_b <- renderText({
    format_number(
      comparison()$summary$occupied_cells[2]
    )
  })

  output$cell_change <- renderText({
    x <- comparison()$comparison$occupied_cell_change

    sprintf("%+d", as.integer(x))
  })

  output$map_a <- renderLeaflet({
    create_fire_map(
      month_data_a(),
      input$month_a,
      "map_a"
    )
  })

  output$map_b <- renderLeaflet({
    create_fire_map(
      month_data_b(),
      input$month_b,
      "map_b"
    )
  })

  make_top_table <- function(d) {

    d <- d[
      order(d$detections, decreasing = TRUE),
      ,
      drop = FALSE
    ]

    d <- head(d, 10)

    data.frame(
      Rank = seq_len(nrow(d)),
      `Grid location` = sprintf(
        "%.0f°E, %.0f°",
        d$cell_lon,
        d$cell_lat
      ),
      Detections = format_number(d$detections),
      check.names = FALSE
    )
  }

  output$top_cells_a <- renderTable({
    make_top_table(month_data_a())
  }, striped = TRUE, bordered = FALSE)

  output$top_cells_b <- renderTable({
    make_top_table(month_data_b())
  }, striped = TRUE, bordered = FALSE)

  output$interpretation <- renderText({

    result <- comparison()

    change <- result$comparison$detection_change_pct

    concentration <- result$comparison$concentration_change_pp

    spread <- result$comparison$occupied_cell_change

    detection_word <- if (change < 0) {
      "decreased"
    } else if (change > 0) {
      "increased"
    } else {
      "remained unchanged"
    }

    concentration_word <- if (concentration > 0) {
      "increased"
    } else if (concentration < 0) {
      "decreased"
    } else {
      "remained unchanged"
    }

    spread_word <- if (spread < 0) {
      "fewer"
    } else if (spread > 0) {
      "more"
    } else {
      "the same number of"
    }

    paste0(
      "Between ",
      format_month(input$month_a),
      " and ",
      format_month(input$month_b),
      ", recorded satellite fire detections ",
      detection_word,
      " by ",
      sprintf("%.2f", abs(change)),
      "%. The share of detections in the ten most active ",
      "grid cells ",
      concentration_word,
      " by ",
      sprintf("%.2f", abs(concentration)),
      " percentage points. Period B had ",
      spread_word,
      " occupied grid cells compared with Period A. ",
      "These results describe observed detection patterns, ",
      "not necessarily changes in burned area or the ",
      "number of individual fires."
    )
  })
}

shinyApp(ui, server)
