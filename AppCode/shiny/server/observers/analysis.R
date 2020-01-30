observeEvent(input[[id.analysis.button.menu]], {
  util.filter.showSidebar(FALSE)
  observers.main.updateActiveTab(id.button.menuItem.analysis)
  output$mainPage <- renderUI(pages.analysis.getPage())
})

observeEvent(input[[id.analysis.button.train]], {
  # Determine the steps required for success
  steps <<- 12

  withProgress(message = 'Training Models', value = 0, {
    # Training the models
    # Create the DTM
    incProgress(1/steps, detail = "Creating DTM")
    dtmDF <- analysis.observer.createDTM()

    # Start a spark connection
    incProgress(1/steps, detail = "Connecting to Spark")
    sc <- spark_connect(master = "local")
    incProgress(1/steps, detail = "Copying the DTM to Spark")
    scdata <- sparklyr::copy_to(sc, dtmDF, "Hotel_Reviews")

    # Create the partition
    incProgress(1/steps, detail = "Creating partitions")
    partitions <- analysis.observer.createPartition(scdata)

    # Train Models
    trainResults <- analysis.observer.trainModels(partitions)

    incProgress(1/steps, detail = "Creating predictions with the models")
    predictions <- analysis.observer.createPredictions(trainResults, partitions)

    incProgress(1/steps, detail = "Evaluating predictions")
    analysis.observer.evaluateAndPrint(predictions, trainResults, TRUE)

    # Close the spark connection
    incProgress(1/steps, detail = "Disconnecting from Spark")
    spark_disconnect(sc)
  })
})

observeEvent(input[[id.analysis.button.storedCheck]], {
  steps <<- 5

  withProgress(message = 'Checking Models', value = 0, {
    incProgress(1/steps, detail = "Re-creating the DTM that was used for training old models")
    dtmDF <- analysis.observer.createDTM()
    incProgress(1/steps, detail = "Connecting to spark")
    sc <- spark_connect(master = "local")
    scdata <- sparklyr::copy_to(sc, dtmDF, "Hotel_Reviews")
    partitions <- analysis.observer.createPartition(scdata)

    incProgress(1/steps, detail = "Loading models")
    rfModel <- ml_load(sc, "Models/rfModel")
    dtModel <- ml_load(sc, "Models/dtModel")
    gbModel <- ml_load(sc, "Models/gbModel")
    lrModel <- ml_load(sc, "Models/lrModel")
    svmModel <- ml_load(sc, "Models/svmModel")
    nbModel <- ml_load(sc, "Models/nbModel")

    times <- list(1,2,3,4,5,6)
    models <- list(rfModel, dtModel, gbModel, lrModel, svmModel, nbModel)
    trainResults <- list(times, models)

    incProgress(1/steps, detail = "Predicting")
    predictions <- analysis.observer.createPredictions(trainResults, partitions)
    analysis.observer.evaluateAndPrint(predictions, trainResults, FALSE)
    incProgress(1/steps, detail = "Disconnecting from Spark")
    spark_disconnect(sc)
  })
})

observeEvent(input[[id.analysis.button.check]], {
  reviewInput <- input[[id.analysis.input.review]]

  steps <- 5
  # Connect to spark
  withProgress(message = 'Predicting Sentiment', value = 0, {
    incProgress(1/steps, detail = "Connecting to spark")
    sc <- spark_connect(master = "local")
    # Load the model
    incProgress(1/steps, detail = "Loading the model")
    model <- ml_load(sc, "Models/nbModelPipeline")
    # Insert the review text into spark as a dataframe.
    incProgress(1/steps, detail = "Adding the review to Spark session")
    reviewDF <- data_frame(Review = c(reviewInput))
    sReview <- copy_to(sc, reviewDF, overwrite = TRUE)

    incProgress(1/steps, detail = "Evaluating the review")
    res <- ml_transform(model, sReview) %>% collect
    resStringified <- ifelse(res$prediction == 1, "positive!", "negative!")

    result <- paste0(
      "The review: '",
      reviewInput,
      "' was deemed to be ",
      resStringified
    )

    insertUI(
      selector = "#analysisPredict",
      where = "afterEnd",
      ui = p(result)
    )

    incProgress(1/steps, detail = "Disconnecting from Spark")
    spark_disconnect(sc)
  })
})
