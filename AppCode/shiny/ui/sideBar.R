sideBar <- sidebarMenu(
  id = id.general.sidebar,

  #Empty selectInputs to be filled serverside
  sliderInput(id.filter.score, "Average review score between:", 1, 10, c(1,10)), # Slider with a min and a max.
  sliderInput(id.filter.minReviews, "Minumum number of reviews:", 1, 10, c(1)), # Slider with a min and a max.
  selectInput(id.filter.hotelName, label = "Hotel Name:", choices = c(""), multiple = TRUE),

  actionButton(id.filter.reset, label = "Reset Filters"),
  htmlOutput("urlText", inline = TRUE)
)
