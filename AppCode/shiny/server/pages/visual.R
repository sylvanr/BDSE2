pages.visual.getPage <- function() {
  tagList(
    div(
      id = "map",
      class = "card",
      leafletOutput("map")
    ),
    div(
      id = "defaultCard",
      class = "card",
      h2("Hotel Information"),
      hr(),
      p("Click on a hotel marker on the map, to display information here.")
    )
  )
}

map <- function() {
  # create map
  leaflet() %>%
    addProviderTiles(providers$Stamen.TonerLite,
      options = providerTileOptions(noWrap = TRUE)
    ) %>%
    addMarkers(
      data = mapPoints,
      label = paste(mapPoints$Hotel_Name, ", ", mapPoints$Average_Score),
      popup = paste(mapPoints$Hotel_Name, ", ", mapPoints$Average_Score, "\n", mapPoints$Hotel_Address)
    )
}
