observeEvent(input[[id.visual.button.menu]], {
  util.filter.showSidebar(TRUE)
  observers.main.updateActiveTab(id.button.menuItem.visual)
  output$mainPage <- renderUI(pages.visual.getPage())
})

observeEvent(input$map_marker_click, {
  p <- input$map_marker_click
  hotelReviews <- db.findRandomForLatLng(p$lat, p$lng)

  removeUI(selector = "#defaultCard")
  removeUI(selector = "#detailedCard")
  insertUI(
    selector = "#map",
    where = "afterEnd",
    ui = tags$div(
      id = "detailedCard",
      class = "card",
      h2(paste0(hotelReviews[1], ", ", hotelReviews[2])),
      hr(),
      p(paste0("This hotel can be found at: ", hotelReviews[3], ".")),
      p(paste0("This hotel has been reviewed ", hotelReviews[4], " times.")),
      hr(),
      h3("Random Review", id = "reviewsHeader"),
      p(paste("Review:", hotelReviews[5])),
      p(paste("Review Score:", hotelReviews[6])),
      p(paste("Reviewer Nationality:", hotelReviews[7])),
      p(paste("Reviewer Date:", hotelReviews[8]))
    )
  )
})
