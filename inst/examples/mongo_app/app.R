library(shiny.esreglog)

mongo_default <- list(
  url = "mongodb://localhost",
  db = "reglog"
)

mongo_tables_create(
  mongo_url = mongo_default$url,
  mongo_db = mongo_default$db,
  verbose = F
)

shiny.esreglog:::RegLogTest(
  dbConnector = RegLogMongoConnector$new(
    mongo_url = mongo_default$url,
    mongo_db = mongo_default$db
  ),
  mailConnector = RegLogConnector$new(),
  use_modals = F,
  onStart = {
    options("RegLogServer.logs_to_database" = 1)
    options("RegLogServer.logs" = 1)
  }
)

