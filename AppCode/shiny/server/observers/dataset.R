observeEvent(input[[id.dataset.button.menu]], {
  util.filter.showSidebar(FALSE)
  observers.main.updateActiveTab(id.button.menuItem.dataset)
  output$mainPage <- renderUI(pages.dataset.getPage())
})

observeEvent(input[[id.dataset.button.update]], {
  steps <<- 5
  withProgress(message = 'Updating dataset', value = 0, {
    # Remove a possible remaining ui element with results
    removeUI(selector = "#datasetResultDiv")
    # Do process
    times <- dataset.observer.updateDataset()
    # Add result
    incProgress(1/steps, detail = "Finishing Up")
    dataset.observer.showResult(times)
  })
})

dataset.observer.updateDataset <- function() {
  # Create ffbase local folder and use it as working directory
  incProgress(1/steps, detail = "Setting up FFBase")
  system("mkdir ffdf")
  ffbaseDir <- paste0(getwd(), "/ffdf")
  options(fftempdir = ffbaseDir)

  incProgress(1/steps, detail = "Getting raw data from CSV")
  # Step 1: Get the data from the csv file into a ffdf and store the time it takes
  timeRaw <- system.time(raw <- read.csv.ffdf(x = NULL, "Data/Hotel_Reviews.csv", encoding="ASCII"))

  # Step 2: Create a balanced dataset: There should be a collection of balanced set of reviews,
  # for instance a collection consisting of 10.000 positive and 10.000 negative reviews
  incProgress(1/steps, detail = "Create a useful subset (10000/10000 split of positive and negative)")
  timeSample <- system.time(dataset <- dataset.observer.sampleRawData(raw))

  # Step 3: Overwrite the database
  incProgress(1/steps, detail = "Update the database")
  db.drop()
  timeDB <- system.time(
    db.insert(as.data.frame(dataset))
  )

  return(c(timeRaw, timeSample, timeDB))
}

dataset.observer.sampleRawData <- function(raw) {
  set.seed(1); # using seed 1 to get the same random data set every time.

  # Get all the positive reviews, assuming positive reviews have a minimum rating of 5.5, drop others, also want at least 5 words.
  pos <- ffdf("Hotel_Address" = raw$Hotel_Address,
    "Hotel_Name" = raw$Hotel_Name,
    "Lat" = raw$lat,
    "Lng" = raw$lng,
    "Average_Score" = raw$Average_Score,
    "Total_Number_of_Reviews" = raw$Total_Number_of_Reviews,
    "Additional_Number_of_Scoring" = raw$Additional_Number_of_Scoring,
    "Reviewer_Nationality" = raw$Reviewer_Nationality,
    "Review_Date" = raw$Review_Date,
    "Review" = raw$Positive_Review,
    "Review_Word_Counts" = raw$Review_Total_Positive_Word_Counts,
    "Total_Number_of_Reviews_Reviewer_Has_Given" = raw$Total_Number_of_Reviews_Reviewer_Has_Given,
    "Reviewer_Score" = raw$Reviewer_Score,
    "Tags" = raw$Tags,
    "Sentiment"= as.ff(rep(1, times = nrow(raw)))
  ) %>% subset.ffdf(Reviewer_Score >= 5.5) %>% subset.ffdf(Review_Word_Counts > 4)

  # Get all the negative reviews, assuming negative reviews have a maximum rating of 5.5, drop others, also want at least 5 words.
  neg <- ffdf("Hotel_Address" = raw$Hotel_Address,
    "Hotel_Name" = raw$Hotel_Name,
    "Lat" = raw$lat,
    "Lng" = raw$lng,
    "Average_Score" = raw$Average_Score,
    "Total_Number_of_Reviews" = raw$Total_Number_of_Reviews,
    "Additional_Number_of_Scoring" = raw$Additional_Number_of_Scoring,
    "Reviewer_Nationality" = raw$Reviewer_Nationality,
    "Review_Date" = raw$Review_Date,
    "Review" = raw$Negative_Review,
    "Review_Word_Counts" = raw$Review_Total_Negative_Word_Counts,
    "Total_Number_of_Reviews_Reviewer_Has_Given" = raw$Total_Number_of_Reviews_Reviewer_Has_Given,
    "Reviewer_Score" = raw$Reviewer_Score,
    "Tags" = raw$Tags,
    "Sentiment"= as.ff(rep(0, times = nrow(raw)))
  ) %>% subset.ffdf(Reviewer_Score < 5.5) %>% subset.ffdf(Review_Word_Counts > 4)

  a <- pos[sample(1:nrow(pos), 10000),]
  b <- neg[sample(1:nrow(neg), 10000),]
  rownames(a) <- c(1:10000)
  rownames(b) <- c(10001:20000)
  # Select 10000 random rows from pos and neg, make them a single df.
  pos <- as.ffdf(a)
  neg <- as.ffdf(b)

  dataset <- ffdfappend(pos, neg)
}

dataset.observer.showResult <- function(times) {
  insertUI(
    selector = "#datasetHR",
    where = "afterEnd",
    ui = div(
      id = "datasetResultDiv",
      p(paste("Time it took to get the raw data into an FFDF with ffbase:", times[1])),
      p(paste("Time it took to turn the raw data into an evenly spread set of positive and negative reviews as FFDF with ffbase:", times[2])),
      p(paste("Time it took to store the dataset in the database:", times[3]))
    )
  )
}
