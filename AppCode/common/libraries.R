Packages <- c(
    "mongolite",
    "dplyr",
    "shiny",
    "shinydashboard",
    "shinyjs",
    "ff",
    "ffbase",
    "lubridate",
    "doBy",
    "tm",
    "sparklyr",
    "DBI",
    "leaflet"
  )

lapply(Packages, library, character.only = TRUE)

#installPackages <- function() {
#  lapply(Packages, install.packages, character.only = TRUE)
#}
#installPackages()
