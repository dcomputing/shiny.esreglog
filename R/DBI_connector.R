#' @docType class
#' 
#' @title Connector to DBI-valid databases
#' @description Object of this class handles all connections for the RegLogServer
#' object to the database. It is created to handle `DBI` compatible drivers.
#' Provides methods than will be used by RegLogServer to get and send data.
#' 
#' @family dbConnectors
#' @import R6
#' @export

RegLogDBIConnector = R6::R6Class(
  "RegLogDBIConnector",
  inherit = RegLogConnector,
  # private elements ####
  private = list(
    # storage of connection args
    db_args = NULL,
    # storage of connection driver
    db_drv = NULL,
    # storage of connection 
    db_conn = NULL,
    # table names
    db_tables = NULL,
    # connect to the database
    db_connect = function(
    ) {
      
      private$db_conn <- do.call(
        what = DBI::dbConnect,
        args = c(
          list(drv = private$db_drv),
          private$db_args
        )
        )
    },
    # disconnect from the database
    db_disconnect = function() {
      DBI::dbDisconnect(private$db_conn)
    },
    # check the connection, and reconnect
    db_check_n_refresh = function() {
    #   tryCatch({
    #     res <- DBI::dbSendQuery(private$db_conn, "SELECT TRUE;")
    #     DBI::dbClearResult(res)
    #     },
    #     error = function(e) {
    #       private$db_connect()
    #     }
    #   )
      if (!isTRUE(DBI::dbIsValid(private$db_conn)))
        private$db_connect()
    },
    # method to input log into database
    input_log = function(message, direction, session) {

      on.exit(private$db_disconnect())
      
      private$db_check_n_refresh()
      
      sql <- paste0("INSERT INTO ", private$db_tables[3], 
                   " (time, session, direction, type", 
                   if (!is.null(message$logcontent)) ", note", 
                   ") VALUES (?time, ?session, ?direction, ?type",
                   if (!is.null(message$logcontent)) ", ?note",
                   ");")
      
      log_data <- list(time = message$time,
                       session = session$token,
                       direction = direction,
                       type = message$type)
      
      if (!is.null(message$logcontent)) {
        log_data[["note"]] <- message$logcontent
      }
      
      query <- DBI::sqlInterpolate(private$db_conn,
                                   sql,
                                   .dots = log_data)
      
      DBI::dbExecute(private$db_conn, query)
      
    }
  ),
  # public elements ####
  public = list(

    #' @description Initialization of the object. Creates initial connection
    #' to the database.
    #' 
    #' Requires `DBI` package to be installed.
    #' 
    #' @param driver Call that specifies the driver to be used during all queries
    #' @param ... other arguments used in `DBI::dbConnect()` call
    #' @param table_names character vector. Contains names of the tables in the
    #' database: first containing user data, second - reset codes information,
    #' third (optional) - logs from the object. For more info check documentation
    #' of `DBI_database_create`.
    #' @param custom_handlers named list of custom handler functions. Every 
    #' custom handler should take arguments: `self` and `private` - relating to 
    #' the R6 object and `message` of class `RegLogConnectorMessage`. It should 
    #' return `RegLogConnectorMessage` object.
    #' @return object of `RegLogDBIConnector` class
    #' 
    
    initialize = function(
      driver,
      ...,
      table_names = c("users", "reset_codes", "logs"),
      custom_handlers = NULL
    ) {
      
      check_namespace("DBI")
      
      # append default handlers
      self$handlers[["login"]] <- DBI_login_handler
      self$handlers[["register"]] <- DBI_register_handler
      self$handlers[["credsEdit"]] <- DBI_credsEdit_handler
      self$handlers[["resetPass_generate"]] <- DBI_resetPass_generation_handler
      self$handlers[["resetPass_codevalidation"]] <- DBI_resetPass_codevalidation_handler
      self$handlers[["resetPass_confirm"]] <- DBI_resetPass_confirmation_handler
      self$handlers[["loginWithMicrosoft"]] <- DBI_login_with_microsoft_handler
      self$handlers[["getAllPermissions"]] <- DBI_get_all_permissions_handler
      self$handlers[["adjustPermissions"]] <- DBI_adjust_permissions_handler
      self$handlers[["adjustUserAsAdmin"]] <- DBI_adjust_user_admin_handler
      self$handlers[["addCompany"]] <- DBI_add_company_handler
      self$handlers[["editCompany"]] <- DBI_edit_company_handler
      self$handlers[["delCompany"]] <- DBI_del_company_handler
      self$handlers[["addStudy"]] <- DBI_add_study_handler
      self$handlers[["editStudy"]] <- DBI_edit_study_handler
      self$handlers[["delStudy"]] <- DBI_del_study_handler
      self$handlers[["adjustDisabledDashboards"]] <- DBI_adjust_disableddashboards_handler
      
      super$initialize(custom_handlers = custom_handlers)
      # store the arguments internally
      private$db_drv <- driver
      private$db_args <- list(...)
      private$db_tables <- table_names
      # initial connection to the database, checking if everything is all right
      private$db_connect()
      # disconnect fron the database when not used
      private$db_disconnect()
    }
  )
)