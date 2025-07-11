#' listener for RegLogServer
#' 
#' @details all reactivity of the server lies there
#' 
#' @param self object of R6
#' @param private object of R6
#' @noRd
#' @import shiny

RegLogServer_listener <- function(
  self,
  private
) {
  
  moduleServer(
    id = self$module_id, 
    function(input, output, session) {
      
      # observe changes in internal listener ####
      observe({
        
        req(!is.null(private$listener))
        # receive the message
        received_message <- private$listener()
        req(class(received_message) == "RegLogConnectorMessage") 
        req(received_message$type %in% c("logout"))
        # save the message to the logs
        save_to_logs(received_message, "received", self, session)        
        
        ## switches for different reactions ####
        isolate({
          switch(
            received_message$type,
            
            ## logout messages reactions ####
            logout = {
              
              if (received_message$data$success) {
                
                modals_check_n_show(private = private,
                                    modalname = "logout_success")
                # clear user data
                self$is_logged(FALSE)
                self$user_id(uuid::UUIDgenerate())
                self$user_mail(NULL)
                self$is_admin(NULL)
                self$account_id(NULL)
                self$permissions(NULL)
                self$is_logged_microsoft(FALSE)
                
              } else {
                
                modals_check_n_show(private = private,
                                    modalname = "logout_notLogIn")
                
              }
            }
          )
        })
        #expose the message to the outside
        self$message(received_message)
      })
      
      # observe changes in dbConnector ####
      observe({
        
        # safety check - for the dbConnector to not be NULL
        req(!is.null(self$dbConnector))
        
        # receive the message
        received_message <- self$dbConnector$message()
        req(class(received_message) == "RegLogConnectorMessage")
        req(!received_message$type %in% c("logout"))
        
        ## switches for different reactions ####
        isolate({
          # save the received message to logs
          save_to_logs(received_message, "received", self, session)
          switch(
            received_message$type,
            
            getAllPermissions = {
              self$all_permissions(received_message$data$all_permissions)
              self$all_companies(received_message$data$all_companies)
              self$all_studies(received_message$data$all_studies)
              self$all_users(received_message$data$all_users)
              self$companies_table(received_message$data$companies_table)
              self$studies_table(received_message$data$studies_table)
              self$disabled_dashboard_table(received_message$data$disabled_dashboard_table)
              self$message(received_message)
            },
            
            adjustPermissions = {
              if(received_message$data$action == "Grant"){
                if(received_message$data$success){
                  modals_check_n_show(private = private,
                                      modalname = "permission_grant_success")
                }
                else{
                  modals_check_n_show(private = private,
                                      modalname = "permission_grant_fail")
                }
              }
              else if(received_message$data$action == "Revoke"){
                if(received_message$data$success){
                  modals_check_n_show(private = private,
                                      modalname = "permission_revoke_success")
                }
                else{
                  modals_check_n_show(private = private,
                                      modalname = "permission_revoke_fail")
                }
              }
              
              self$all_permissions(received_message$data$all_permissions)
              self$message(received_message)
            },

            adjustUserAsAdmin = {
              if (received_message$data$action == "Enable") {
                if (received_message$data$success) {
                  modals_check_n_show(private = private,
                                      modalname = "setUserAsAdmin_success")
                } else {
                  modals_check_n_show(private = private,
                                      modalname = "setUserAsAdmin_fail")
                }
              } else if (received_message$data$action == "Disable") {
                if (received_message$data$success) {
                  modals_check_n_show(private = private,
                                      modalname = "removeUserAsAdmin_success")
                } else {
                  modals_check_n_show(private = private,
                                      modalname = "removeUserAsAdmin_fail")
                }
              }
              
              self$all_users(received_message$data$all_users)
              self$message(received_message)
            },

            addCompany = {
              self$companies_table(received_message$data$companies_table)
              self$all_companies(received_message$data$all_companies)
              self$message(received_message)
            },
            
            editCompany = {
              self$companies_table(received_message$data$companies_table)
              self$all_companies(received_message$data$all_companies)
              self$message(received_message)
            },
            
            delCompany = {
              self$companies_table(received_message$data$companies_table)
              self$all_companies(received_message$data$all_companies)
              self$message(received_message)
            },
            
            addStudy = {
              self$studies_table(received_message$data$studies_table)
              self$all_studies(received_message$data$all_studies)
              self$message(received_message)
            },
            
            editStudy = {
              self$studies_table(received_message$data$studies_table)
              self$all_studies(received_message$data$all_studies)
              self$message(received_message)
            },
            
            delStudy = {
              self$studies_table(received_message$data$studies_table)
              self$all_studies(received_message$data$all_studies)
              self$message(received_message)
            },
            
            adjustDisabledDashboards = {
              self$all_studies(received_message$data$all_studies)
              self$disabled_dashboard_table(received_message$data$disabled_dashboard_table)
              self$message(received_message)
            },
            
            ## login messages reactions ####
            login = {
              # if couldn't log in
              if (!received_message$data$success) {
                # check what was the reason: 
                # user doesn't exist:
                if (!received_message$data$username) {
                  # show the modal if configuration allows
                  modals_check_n_show(private = private,
                                      modalname = "login_badId")
                } else {
                  # if the password is wrong
                  modals_check_n_show(private = private,
                                      modalname = "login_badPass")
                }
              } else {
                # if login is successful
                # TODO: Maybe add a toast notification here
                # modals_check_n_show(private = private,
                #                     modalname = "login_success")
                
                # change the log-in state
                self$is_logged(TRUE)
                self$account_id(received_message$data$account_id)
                self$user_id(received_message$data$user_id)
                self$user_mail(received_message$data$user_mail)
                self$is_admin(received_message$data$is_admin)
                self$permissions(received_message$data$permissions)
                self$studies_table(received_message$data$studies_table)
                self$disabled_dashboard_table(received_message$data$disabled_dashboard_table)
                self$is_logged_microsoft(received_message$data$is_logged_microsoft)
              }
            },
            
            ## register messages reactions ####
            register = {
              
              # if registration is successful
              if (received_message$data$success) {
                
                # show modal if enabled
                modals_check_n_show(private, "register_success")
                
                # send message to the mailConnector
                if (isTRUE(getOption("RegLogServer.register_mail", TRUE))) {
                  message_to_send <- RegLogConnectorMessage(
                    "reglog_mail",
                    process = "register",
                    username = received_message$data$user_id,
                    email = received_message$data$user_mail,
                    app_name = private$app_name,
                    password = received_message$data$password
                  )
                  
                  # email them their password
                  self$mailConnector$listener(message_to_send)
                  save_to_logs(message_to_send, "sent", self, session)
                  
                }
                
              } else {
                # if registering failed
                
                modals_check_n_show(
                  private = private,
                  modalname = if (isFALSE(received_message$data$username)) "register_existingId"
                         else if (isFALSE(received_message$data$email)) "register_existingEmail"
                )
              }
            },
            
            ## data edit messages reactions ####
            credsEdit = {

              # if data change is successful
              if (received_message$data$success) {
                
                modals_check_n_show(private,
                                    "credsEdit_success")
                
                if (!is.null(received_message$data$new_user_id)) {
                  self$user_id(received_message$data$new_user_id)
                }
                if (!is.null(received_message$data$new_user_mail)) {
                  self$user_mail(received_message$data$new_user_mail)
                }
                
                # send message to the mailConnector
                if (isTRUE(getOption("RegLogServer.credsEdit_mail", TRUE))) {
                  message_to_send <- RegLogConnectorMessage(
                    "reglog_mail",
                    process = "credsEdit",
                    username = self$user_id(),
                    email = self$user_mail(),
                    app_name = private$app_name,
                    app_address = private$app_address
                  )
                  
                  self$mailConnector$listener(message_to_send)
                  save_to_logs(message_to_send, "sent", self, session)
                }
                # if there were any conflicts
              } else {
                modals_check_n_show(
                  private = private,
                  modalname = if (isFALSE(received_message$data$username)) "credsEdit_badId"
                         else if (isFALSE(received_message$data$password)) "credsEdit_badPass"
                         else if (isFALSE(received_message$data$new_username)) "credsEdit_existingId"
                         else if (isFALSE(received_message$data$new_email)) "credsEdit_existingEmail"
                  )
              }
            },
            
            # reset password generation messages reactions ####
            
            resetPass_generate = {
              
              # if generation were successful
              if (received_message$data$success) {
                
                modals_check_n_show(private, "resetPass_codeGenerated")

                # send message to the mailConnector
                message_to_send <- RegLogConnectorMessage(
                  "reglog_mail",
                  process = "resetPass",
                  username = received_message$data$user_id,
                  email = tolower(received_message$data$user_mail),
                  app_name = private$app_name,
                  app_address = private$app_address,
                  reset_code = received_message$data$reset_code
                )
                
                self$mailConnector$listener(message_to_send)
                save_to_logs(message_to_send, "sent", self, session)
                
              } else {
                #if not successful
                modals_check_n_show(private, "resetPass_badId")
              }
            },
            
            # reset password code validation reactions ####
            
            resetPass_codevalidation = {
              # if reset code was valid
              if (received_message$data$success) {
                modals_check_n_show(private, "resetPass_codeValidated")
                shinyjs::show(id="reset_pass1")
                shinyjs::show(id="reset_pass2")
                shinyjs::show(id="change_password_bttn")
                shinyjs::show(id="passwd_instructions")
                shinyjs::hide(id="reset_code")
                shinyjs::hide(id="reset_confirm_bttn")
                shinyjs::hide(id="reset_send")
                shinyjs::hide(id="reset_user_ID")
                shinyjs::hide(id="code_instructions")
                shinyjs::hide(id="reset_instructions")
              } else {
                modals_check_n_show(
                  private = private,
                  modalname = if (isFALSE(received_message$data$username)) "resetPass_badId"
                  else if (isFALSE(received_message$data$code_valid)) "resetPass_invalidCode"
                )
              }
            },
            
            # reset password confirmation messages reactions ####

            resetPass_confirm = {
              # if password change was successful
              if (received_message$data$success) {

                modals_check_n_show(private, "resetPass_success")
                blank_textInputs(c("reset_user_ID", "reset_code", 
                                                     "reset_pass1", "reset_pass2"), 
                                                    session = session)
                shinyjs::hide(id="reset_pass1")
                shinyjs::hide(id="reset_pass2")
                shinyjs::hide(id="change_password_bttn")
                shinyjs::hide(id="passwd_instructions")
                shinyjs::show(id="reset_user_ID")
                shinyjs::show(id="reset_instructions")
                shinyjs::show(id="reset_send")
                shinyjs::runjs("$('.reglog_bttn').attr('disabled', true)")

              } else {
                #if not successful
                modals_check_n_show(
                  private = private,
                  modalname = if (isFALSE(received_message$data$username)) "resetPass_badId"
                         else if (isFALSE(received_message$data$code_valid)) "resetPass_invalidCode"
                )
              }
            }
          )
          #expose the message to the outside
          self$message(received_message)
          
          shinyjs::runjs("$('.reglog_bttn').attr('disabled', false)")
          
        })
      })
      
      # observe changes in mailConnector ####
      
      observe({
        
        # safety check - for the dbConnector to not be NULL
        req(!is.null(self$mailConnector))
        
        # receive the message
        received_message <- self$mailConnector$message()
        req(class(received_message) == "RegLogConnectorMessage")
        
        isolate({
          # save message to logs
          save_to_logs(received_message, "received", self, session)
          
          #expose the message to the outside
          self$mail_message(received_message)
          
        })
      })
    })
}