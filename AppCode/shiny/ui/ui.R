# Load the sidebar
source(paste0(localSetting,"shiny/ui/sideBar.R"),local=TRUE)

# Create UI
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$title("Sylvan's Hotel Reviews"),
    tags$link(rel = "shortcut icon", type="image/png", href="images/icon.png"),
    tags$link(rel = "stylesheet", type = "text/css", href = "css/variables.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "css/styles.css")
  ),
  dashboardPage(
    dashboardHeader(
      title = actionLink(id.main.main, class = "logo", img(src = "images/logo.png")),
      tags$li(
        id = id.button.menuItem.analysis,
        class = "dropdown menuItem",
        actionLink(id.analysis.button.menu, "Analysis")
      ),
      tags$li(
        id = id.button.menuItem.visual,
        class = "dropdown menuItem",
        actionLink(id.visual.button.menu, "Visual")
      ),
      tags$li(
        id = id.button.menuItem.dataset,
        class = "dropdown menuItem",
        actionLink(id.dataset.button.menu, "Dataset")
      )
    ),
    dashboardSidebar(sideBar, collapsed = FALSE),
    dashboardBody(
      uiOutput("mainPage")
    )
  )
)
