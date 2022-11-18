

get_cik <- function(symbol, verbose = FALSE) {
     info <- company_info(symbol)
     if(verbose) {
          message(paste0("CIK: ", info$CIK))
          message(paste0("Company Name: ", info$company))
          message(paste0("Address: ", info$street.address))
          message(paste0("City / State: ", info$city.state))
          
     }
     return(info$CIK)
}