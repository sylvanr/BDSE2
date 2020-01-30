# load required libraries
source(paste0(localSetting,"common/libraries.R"))
source(paste0(localSetting,"database/database.R"),local=TRUE)
source(paste0(localSetting,"common/util.R"),local=TRUE)

# Shiny onstart
source(paste0(localSetting,"shiny/onStart.R"),local=TRUE)
# Shiny server
source(paste0(localSetting,"shiny/server/server.R"),local=TRUE)
# Shiny ui
source(paste0(localSetting,"shiny/ui/ui.R"),local=TRUE)
