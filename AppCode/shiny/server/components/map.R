output$map <- renderLeaflet({
  score <- input[[id.filter.score]]
  minReviews <- input[[id.filter.minReviews]]
  hotelName <- input[[id.filter.hotelName]]

  mapPoints <<- db.getMarkersAggregated(score[1], score[2], minReviews, hotelName)
  if (!is.null(hotelName)) mapPoints <<- subset(mapPoints, Hotel_Name %in% hotelName)
  map() %>% addProviderTiles(providers$Esri.NatGeoWorldMap)
})
