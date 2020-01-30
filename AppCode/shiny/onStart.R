onStart <- function() {
  db.connect()

  localSetting <- paste0(getwd(),"/AppCode/")
  source(paste0(localSetting, "common/scriptloader.R", sep=""), local=TRUE)

  onStop(function() {
    db.disconnect()
    rm(list = ls())
  })
}
