# Remove or add the "sidebar-collapse" class to the html body based on the parameter
util.filter.showSidebar <- function(shouldShow) {
  if (shouldShow) shinyjs::removeClass(selector = "body", class = "sidebar-collapse")
  else shinyjs::addClass(selector = "body", class = "sidebar-collapse")
}
