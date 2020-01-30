db.connect <- function() {
  mcon <<- mongo(collection = "hotel_reviews", db = "hotel_reviews", url = "mongodb://localhost")
}

db.disconnect <- function() {
  mcon$disconnect()
}

db.findAll <- function() {
  mcon$find(
    query = '{}'
  )
}

db.drop <- function() {
  mcon$drop()
}

db.insert <- function(df) {
  mcon$insert(df)
}

db.findReviewsWithSentiment <- function() {
  mcon$find('{}', fields = '{"_id":0, "Review":1, "Sentiment":1}')
}

db.findRandomForLatLng <- function(lat, lng) {
  res <- mcon$find(
    '{}',
    fields = paste0(
      '{"_id":0, "Lat":1, "Lng":1,',
      '"Average_Score":1, "Hotel_Name":1, "Hotel_Address":1,',
      '"Total_Number_of_Reviews":1, "Reviewer_Nationality":1,',
      '"Review_Date":1, "Review":1, "Reviewer_Score":1, "Tags":1 }'
    )
  )

  # Filtering in the query is impossible due to float inaccuracy, therefore filter after the
  # Query with the values of the floats times 10 mil.
  res <- filter(
    res,
    floor((Lat*10000000 - lat*10000000)) == 0 & floor((Lng*10000000 - lng*10000000)) == 0
  )

  i <- sample(nrow(res):1, 1)
  ret <- c(
    res$Hotel_Name[i], res$Average_Score[i], res$Hotel_Address[i], res$Total_Number_of_Reviews[i],
    res[i, "Review"], res[i, "Reviewer_Score"], res[i, "Reviewer_Nationality"], res[i, "Review_Date"]
  )

  return(ret)
}

db.getMarkersAggregated <- function(min, max, minReviews, hotelNames) {
  df <- mcon$aggregate('[
    {
      "$sort":{ "Lat":1, "Lng":1,"Average_Score":1, "Hotel_Name":1, "Hotel_Address":1 }
    },
    {
      "$group":{
        "_id":"$Hotel_Name",
        "Lat": { "$first" : "$Lat" },
        "Lng": { "$first" : "$Lng" },
        "Average_Score": { "$first" : "$Average_Score" },
        "Hotel_Name": { "$first" : "$Hotel_Name" },
        "Hotel_Address": { "$first" : "$Hotel_Address" },
        "Total_Number_of_Reviews": { "$first" : "$Total_Number_of_Reviews" }
      }
    }
  ]') %>%
    filter(Average_Score >= min) %>%
    filter(Average_Score <= max) %>%
    filter(Total_Number_of_Reviews >= minReviews)

  df <- na.omit(df)
  return(df)
}
