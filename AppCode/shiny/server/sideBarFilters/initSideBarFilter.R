init.sideBarFilters <- function(initial = FALSE) {
  #On first load, get data to put in filters and put it in (only books probably)
  # Only allow hotels that are part of the hotels selected by the number of reviews, within the score range
  score <- input[[id.filter.score]]
  minReviews <- input[[id.filter.minReviews]]
  hotelName <- input[[id.filter.hotelName]]
  if (initial) {
    filterData <- datasetDB
    # Reset the min/max reviews
    updateSliderInput(session, id.filter.score, value = c(1,10))
    selectedHotels <- NULL
  }
  else {
    filterData <- db.getMarkersAggregated(score[1], score[2], minReviews, hotelName)
    selectedHotels <- hotelName
  }

  hotelNames <- sort(filterData$Hotel_Name)
  updateSelectInput(session,
    id.filter.hotelName,
    choices = hotelNames,
    selected = selectedHotels
  )

  highestNoReviews <- max(filterData$Total_Number_of_Reviews)
  updateSliderInput(session,
    id.filter.minReviews,
    max = highestNoReviews)
}

source(paste0(localSetting,"shiny/server/sideBarFilters/observers/reset.R"),local=TRUE)
