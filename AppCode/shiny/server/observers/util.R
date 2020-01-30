# Event for the logo in the top left of the application, this leads back to the visual page
observeEvent(input[[id.main.main]], {
  util.filter.showSidebar(TRUE)
  observers.main.updateActiveTab("MAIN")
  output$mainPage <- renderUI(pages.visual.getPage())
})

# Global variables that track which page is currently loaded, starting with visual
activeTab <<- id.button.menuItem.visual
previousTab <<- id.button.menuItem.visual
shinyjs::addClass(id = id.button.menuItem.visual, class = "active-tab")

observers.main.updateActiveTab <- function(selectedTab) {
  previousTab <<- activeTab
  activeTab <<- selectedTab
  shinyjs::removeClass(id = previousTab, class = "active-tab")
  shinyjs::addClass(id = selectedTab, class = "active-tab")
}


## HELPERS FOR THE ANALYSIS
analysis.observer.createDTM <- function() {
  datasetDB <- db.findReviewsWithSentiment()
  corpus <- Corpus(VectorSource(datasetDB$Review))
  dtm <- DocumentTermMatrix(corpus) %>% removeSparseTerms(0.99)
  dtmDF <- as.data.frame(as.matrix(dtm), stringsAsFactors = FALSE)
  return(cbind(dtmDF, Sentiment = datasetDB$Sentiment))
}

analysis.observer.createPartition <- function(scdata) {
  seed <- input[[id.analysis.input.seed]]
  split <- input[[id.analysis.input.split]]

  return(partitions <- sdf_random_split(scdata, training = split, test = (1-split), seed = seed))
}

analysis.observer.trainModels <- function(partitions) {
  incProgress(1/steps, detail = "Creating a model with Random Forest")
  rfTime <- system.time(rfModel <- ml_random_forest(partitions$training, Sentiment ~ ., type = "classification"))
  incProgress(1/steps, detail = "Creating a model with Decision Tree")
  dtTime <- system.time(dtModel <- ml_decision_tree(partitions$training, Sentiment ~ ., type = "classification"))
  incProgress(1/steps, detail = "Creating a model with Gradient Boosted Trees")
  gbTime <- system.time(gbModel <- ml_gradient_boosted_trees(partitions$training, Sentiment ~ ., type = "classification"))
  incProgress(1/steps, detail = "Creating a model with Logistic Regression")
  lrTime <- system.time(lrModel <- ml_logistic_regression(partitions$training, Sentiment ~ .))
  incProgress(1/steps, detail = "Creating a model with Support Vector Machine")
  svmTime <- system.time(svmModel <- ml_linear_svc(partitions$training, Sentiment ~ .))
  incProgress(1/steps, detail = "Creating a model with Naive Bayes")
  nbTime <- system.time(nbModel <- ml_naive_bayes(partitions$training, Sentiment ~ .))

  times <- list(rfTime, dtTime, gbTime, lrTime, svmTime, nbTime)
  models <- list(rfModel, dtModel, gbModel, lrModel, svmModel, nbModel)

  return(list(times, models))
}

analysis.observer.createPredictions <- function(trainResults, partitions) {
  # Get the model from the list of trainResults at the second location.
  rfPrediction <- ml_predict(trainResults[[2]][1][[1]], partitions$test)
  dtPrediction <- ml_predict(trainResults[[2]][2][[1]], partitions$test)
  gbPrediction <- ml_predict(trainResults[[2]][3][[1]], partitions$test)
  lrPrediction <- ml_predict(trainResults[[2]][4][[1]], partitions$test)
  svmPrediction <- ml_predict(trainResults[[2]][5][[1]], partitions$test)
  nbPrediction <- ml_predict(trainResults[[2]][6][[1]], partitions$test)

  return(list(rfPrediction, dtPrediction, gbPrediction, lrPrediction, svmPrediction, nbPrediction))
}

analysis.observer.evaluateAndPrint <- function(predictions, trainResults, withTime) {
  # Get RoC for all, then get accuracy for all.
  rfRoC <- ml_binary_classification_evaluator(predictions[[1]])
  dtRoC <- ml_binary_classification_evaluator(predictions[[2]])
  gbRoC <- ml_binary_classification_evaluator(predictions[[3]])
  lrRoC <- ml_binary_classification_evaluator(predictions[[4]])
  svmRoC <- ml_binary_classification_evaluator(predictions[[5]])
  nbRoC <- ml_binary_classification_evaluator(predictions[[6]])

  rfAccuracy <- ml_multiclass_classification_evaluator(predictions[[1]], metric_name = "accuracy")
  dtAccuracy <- ml_multiclass_classification_evaluator(predictions[[2]], metric_name = "accuracy")
  gbAccuracy <- ml_multiclass_classification_evaluator(predictions[[3]], metric_name = "accuracy")
  lrAccuracy <- ml_multiclass_classification_evaluator(predictions[[4]], metric_name = "accuracy")
  svmAccuracy <- ml_multiclass_classification_evaluator(predictions[[5]], metric_name = "accuracy")
  nbAccuracy <- ml_multiclass_classification_evaluator(predictions[[6]], metric_name = "accuracy")

  if (withTime) {
    dataset.observer.createUIFor("Random Forest", rfRoC, rfAccuracy, as.character(trainResults[[1]][1][[1]][3]))
    dataset.observer.createUIFor("Decision Tree", dtRoC, dtAccuracy, as.character(trainResults[[1]][2][[1]][3]))
    dataset.observer.createUIFor("Gradient Boosted Trees", gbRoC, gbAccuracy, as.character(trainResults[[1]][3][[1]][3]))
    dataset.observer.createUIFor("Linear Regression", lrRoC, lrAccuracy, as.character(trainResults[[1]][4][[1]][3]))
    dataset.observer.createUIFor("Support Vector Machine", svmRoC, svmAccuracy, as.character(trainResults[[1]][5][[1]][3]))
    dataset.observer.createUIFor("Naive Bayes", nbRoC, nbAccuracy, as.character(trainResults[[1]][6][[1]][3]))
  } else {
    dataset.observer.createUIForLoaded("Random Forest", rfRoC, rfAccuracy)
    dataset.observer.createUIForLoaded("Decision Tree", dtRoC, dtAccuracy)
    dataset.observer.createUIForLoaded("Gradient Boosted Trees", gbRoC, gbAccuracy)
    dataset.observer.createUIForLoaded("Linear Regression", lrRoC, lrAccuracy)
    dataset.observer.createUIForLoaded("Support Vector Machine", svmRoC, svmAccuracy)
    dataset.observer.createUIForLoaded("Naive Bayes", nbRoC, nbAccuracy)
  }
}

dataset.observer.createUIFor <- function(type, roc, acc, time) {
  insertUI(
    selector = "#analysisHR",
    where = "afterEnd",
    ui = p(paste0(type, " had an RoC of ", roc, " and an accuracy of ", acc, ". It took ", time, " seconds to train."))
  )
}

dataset.observer.createUIForLoaded <- function(type, roc, acc) {
  insertUI(
    selector = "#analysisStoredHR",
    where = "afterEnd",
    ui = p(paste0("Stored model ", type, " had an RoC of ", roc, " and an accuracy of ", acc, "."))
  )
}
