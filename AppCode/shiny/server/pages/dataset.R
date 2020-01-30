pages.dataset.getPage <- function() {
  div(
    id = "datsetCard",
    class = "card",
    h2("Update dataset"),
    hr(),
    p("By pressing the button below, the system will read in the supplied dataset (can be changed in folder '/Data/'). It will use FFBase to read the dataset and use the ffdf datastructure, to simulate a solution for huge file storage. If the csv were 200 gigabytes, it couldnt work in the RAM of a laptop, the ffdf structure which is used, stores itself on the harddisk, using a temporary folder."),
    p("After this dataset is loaded, it is then inserted into the mongoDB, which means the dataset is immediately accesible"),
    actionButton(id.dataset.button.update, label = "Update dataset"),
    hr(id = "datasetHR")
  )
}
