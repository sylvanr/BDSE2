pages.analysis.getPage <- function() {
  tagList(
    div(
      id = "reviewCard",
      class = "card",
      h2("Analyse Reviews"),
      hr(),
      p("Enter a review below, and hit the 'Predict Sentiment' button, this will start a prediction for the given review, using a pre-built Naive Bayes model."),
      textInput(id.analysis.input.review, label = "Write a review", placeholder = "e.g.: 'This hotel was amazing.'"),
      actionButton(id.analysis.button.check, label = "Predict Sentiment"),
      hr(),
      h3(id = "analysisPredict", "Predictions")
    ),
    div(
      id = "resultsCard",
      class = "card",
      h2("Results from stored trained models"),
      p("These models are trained on an 80/20 split. The models are: Random Forest, Decision Tree, Gradient Boosted Tree, Logistic Regression, Support Vector Machine and Naive Bayes"),
      actionButton(id.analysis.button.storedCheck, label = "Show stored models' results"),
      hr(id = "analysisStoredHR"),
    ),
    div(
      id = "trainCard",
      class = "card",
      h2("Re-Train models"),
      hr(),
      p("With this button below, it is possible to start the training process of the models. This training process will consist of: Getting the data, turning it into a usable DTM, creating a spark connection and using spark to train the models, simulating Parallel Computing. You are able to pass the seed and the split for the dataset, by selecting the values below. The value of the slider represents the size of the training partition."),
      sliderInput(id.analysis.input.split, "Select a split:", 0.05, 0.95, 0.80, step = 0.05),
      selectInput(id.analysis.input.seed, "Select a seed", 1:100),
      actionButton(id.analysis.button.train, label = "Train Models"),
      hr(id = "analysisHR")
    )
  )
}
