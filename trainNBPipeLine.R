datasetDB <- mcon$find('{}', fields = '{"_id":0, "Review":1, "Sentiment":1}')
train <- copy_to(sc, datasetDB, overwrite = TRUE)

pipeline <- ml_pipeline(
  ft_tokenizer(sc, input_col = "Review", output_col = "tokens"),
  ft_count_vectorizer(sc, input_col = 'tokens', output_col = 'vocab'),
  ml_naive_bayes(sc, Sentiment ~ ., label_col = "Sentiment")
)

model <- ml_fit(pipeline, train)
ml_save(model, "Models/nbModelPipeline/")
