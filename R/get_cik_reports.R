#' @import dplyr
#' @importFrom lubridate as_datetime is.POSIXct
#' @importFrom httr GET add_headers content
#' @importFrom purrr map_df
get_cik_reports <- function(CIK, after = "1998-01-01", user_agent = getOption("HTTPUserAgent"), verbose = FALSE) {
     
     if(nchar(CIK) != 10) {
          stop("Improper CIK supplied. CIK must be a character string 10 digits long")
     }
     
     # coerce as_of to datetime
     after <- lubridate::as_datetime(as_date(after))
     
     if(!lubridate::is.POSIXct(after)) {
          stop("after parameter must be coercable to a datetime type.")
     }
     
     request <- httr::GET(paste0("data.sec.gov/submissions/CIK",CIK,".json"), httr::add_headers(.headers = c(`User-Agent` = user_agent)))
     content <- httr::content(request)
     if(verbose) {
          message(paste0("CIK: ", CIK))
          message(paste0("Tickers: ", paste(content$tickers, collapse = ", ")))
          message(paste0("Company Name: ", content$name))
     }
     filings <- content$filings
     recent_filings <- filings$recent
     filings_df <- purrr::map_df(recent_filings, ~ unlist(.x))
     filings_df_min_date <- min(lubridate::as_datetime(filings_df$filingDate))
     enough_filings <- filings_df_min_date < after
     old_filings <- filings$files
     if(!is.null(old_filings) & !enough_filings) {
          old_filings_df <- purrr::map_df(old_filings, ~ as.data.frame(.x)) 
               for (name in old_filings_df$name) {
                    request <- httr::GET(paste0("data.sec.gov/submissions/",name), httr::add_headers(.headers = c(`User-Agent` = user_agent)))
                    content <- httr::content(request)       
                    old_filings_df <- purrr::map_df(content, ~ unlist(.x))
                    filings_df <- bind_rows(filings_df, old_filings_df)
               }
     }     
     filings_df <- filings_df |> 
          filter(filingDate > after) |>
          mutate(across(all_of(c("filingDate", "reportDate", "acceptanceDateTime")), as_datetime))|>
          rename(accession.no = accessionNumber,
                 filing.date = filingDate,
                 report.date = reportDate,
                 filing.name = form) |>
          mutate(cik = CIK) |>
          select(cik, accession.no, filing.name, filing.date, report.date) 
          
     return(filings_df)
}
