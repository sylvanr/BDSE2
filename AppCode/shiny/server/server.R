server <- function(input, output, session) {
  source(paste0(localSetting,"shiny/server/serverScriptLoader.R"),local=TRUE)
  source(paste0(localSetting,"shiny/server/InitDataLoad.R"),local=TRUE)
  source(paste0(localSetting,"shiny/server/serverPageLoader.R"),local=TRUE)
  source(paste0(localSetting,"shiny/server/componentLoader.R"),local=TRUE)

  output$mainPage <- renderUI(pages.visual.getPage())

  observe({
    init.sideBarFilters()
  })

  # Hide filter hamburger
  shinyjs::addClass(selector = "body > div > div > header > nav > a", class = "hidden")
}
