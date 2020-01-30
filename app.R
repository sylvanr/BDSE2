# Before running the App, make sure all the libraries are installed, for which there is a handy function in the libraries folder.

localSetting <- paste0(here::here(),"/AppCode/")
source(paste0(localSetting, "common/scriptloader.R", sep=""), local=TRUE)

# Run the application 
shinyApp(ui = ui, server = server, onStart = onStart)
