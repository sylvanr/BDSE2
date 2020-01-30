# install.packages("mongolite", "here")

library(here)
library(mongolite)

# setwd("here::here()")
setwd("/Users/sylvanridderinkhof/Projects/Courses/Big Data/BDSE2")

## Set up ffbase
# install.packages("ff")
#install.packages("ffbase")
#install.packages("doBy")

library(ff)
library(ffbase)
library(doBy)

# Create ffbase local
system("mkdir ffdf")
ffbaseDir <- paste0(getwd(), "/ffdf")
options(fftempdir = ffbaseDir)

# Step 1: Get the data from the csv file into a ffdf and show the time it takes
raw <- read.csv.ffdf(x = NULL, "Data/Hotel_Reviews.csv", encoding="ASCII")
timer <- system.time(raw <- read.csv.ffdf(x = NULL, "Data/Hotel_Reviews.csv", encoding="ASCII"))

# Step 2: Create a balanced dataset: There should be a collection of balanced set of reviews, for instance a collection consisting of 10.000 positive and 10.000 negative reviews having a least the following structure
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

# Connect to db
mcon <- mongo(collection = "hotel_reviews", db = "hotel_reviews", url = "mongodb://localhost")
# Insert into db
mcon$drop()
mcon$insert(as.data.frame(dataset))
# Retrieve data from db
datasetDB <- mcon$find('{}', fields = '{"_id":0, "Review":1, "Sentiment":1}')


library(tm)
corpus <- Corpus(VectorSource(datasetDB$Review))
dtm <- DocumentTermMatrix(corpus) %>% removeSparseTerms(0.99)
dtmDF <- as.data.frame(as.matrix(dtm), stringsAsFactors = FALSE)
dtmDF <- cbind(dtmDF, Sentiment = datasetDB$Sentiment)

# Spark
# Setup spark
# install.packages("sparklyr")
library(sparklyr)
library(DBI)
# spark_install(version = "2.4.0")

# Connect to spark
sc <- spark_connect(master = "local")
scdata <- sparklyr::copy_to(sc, dtmDF, "Hotel_Reviews")
# Get data from spark
# dbGetQuery(sc, "SELECT * FROM hotel_reviews")

# Create a 80/20 split
partitions <- sdf_random_split(scdata, training = 0.8, test = 0.2, seed = 1)

# Predict with Random Forest
system.time(rfModel <- ml_random_forest(partitions$training, Sentiment ~ ., type = "classification"))
rfPrediction <- ml_predict(rfModel, partitions$test)
rfResult <- ml_binary_classification_evaluator(rfPrediction)

# Predict with Decision Tree
dtModel <- ml_decision_tree(partitions$training, Sentiment ~ ., type = "classification")
dtPrediction <- ml_predict(dtModel, partitions$test)
dtResult <- ml_binary_classification_evaluator(dtPrediction)

# Predict with Gradient Bossted Tree
gbModel <- ml_gradient_boosted_trees(partitions$training, Sentiment ~ ., type = "classification")
gbPrediction <- ml_predict(gbModel, partitions$test)
gbResult <- ml_binary_classification_evaluator(gbPrediction)

# Predict with Logisic Regression
lrModel <- ml_logistic_regression(partitions$training, Sentiment ~ .)
lrPrediction <- ml_predict(lrModel, partitions$test)
lrResult <- ml_binary_classification_evaluator(lrPrediction)

# Predict with Multilayer Perceptron (neural network)
#mpModel <- ml_multilayer_perceptron_classifier(partitions$training, Sentiment ~ ., layers = c(11,15,2))
#mpPrediction <- ml_predict(mpModel, partitions$test)
#mpResult <- ml_binary_classification_evaluator(mpPrediction)

# Predict with Support Vector Machine
svmModel <- ml_linear_svc(partitions$training, Sentiment ~ .)
svmPrediction <- ml_predict(svmModel, partitions$test)
svmResult <- ml_binary_classification_evaluator(svmPrediction)

# Predict with Naine Bayes
nbModel <- ml_naive_bayes(partitions$training, Sentiment ~ .)
nbPrediction <- ml_predict(nbModel, partitions$test)
nbResult <- ml_binary_classification_evaluator(nbPrediction)

ml_save(rfModel, paste0(getwd(), "/Models"), overwrite = TRUE)
ml_save(dtModel, paste0(getwd(), "/Models"), overwrite = TRUE)
ml_save(gbModel, paste0(getwd(), "/Models"), overwrite = TRUE)
ml_save(lrModel, paste0(getwd(), "/Models"), overwrite = TRUE)
ml_save(svmModel, paste0(getwd(), "/Models"), overwrite = TRUE)
ml_save(nbModel, paste0(getwd(), "/Models"), overwrite = TRUE)

results <- as.data.frame(cbind(c("Random Forest", "Decision Tree", "Gradient Boosted", "Logistic Regression", "Support Vector Machine", "Naive Bayes"), c(rfResult, dtResult, gbResult, lrResult, svmResult, nbResult)))
colnames(results) <- c("Type", "Accuracy")
results <- results[order(results$Accuracy, decreasing = TRUE),]

#### SHINY APP
# install.packages("leaflet")
library(shiny)
library(leaflet)
library(dplyr)

data <- mcon$find('{}', fields = '{"_id":0, "Lat":1, "Lng":1,"Average_Score":1, "Hotel_Name":1, "Hotel_Address":1}')

ui <- fluidPage(
  leafletOutput("mymap"),
  p(),
  sliderInput("sliderScore", "Average Review Score Between:", 1, 10, c(1,10)), # Slider with a min and a max.
  #selectInput("hotelInput", data$)
)

server <- function(input, output) {
  data <- mcon$find('{}', fields = '{"_id":0, "Lat":1, "Lng":1,"Average_Score":1, "Hotel_Name":1, "Hotel_Address":1}')
  points <- na.omit(distinct(data))

  map <- function(points) {
    # create map
    renderLeaflet({
      leaflet() %>%
        addProviderTiles(providers$Stamen.TonerLite,
                         options = providerTileOptions(noWrap = TRUE)
        ) %>%
        addMarkers(
          lat = points$Lat,
          lng = points$Lng,
          label = paste(points$Hotel_Name, ", ", points$Average_Score),
          popup = paste(points$Hotel_Name, ", ", points$Average_Score, "\n", points$Hotel_Address)
        )
    })
  }

  # Listen to the slider changing and filter the dataset
  observeEvent(input$sliderScore, {
    filteredPoints <- filter(points, Average_Score > input$sliderScore[1])
    filteredPoints <- filter(filteredPoints, Average_Score < input$sliderScore[2])

    output$mymap <- map(filteredPoints)
  })

  observeEvent(input$mymap_marker_click, {
    p <- input$map_marker_click
  })

  output$mymap <- map(points)
}

shinyApp(ui, server)
