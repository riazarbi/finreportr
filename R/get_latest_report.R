#' @import dplyr
#' @importFrom lubridate as_datetime
#' @importFrom arrow write_parquet open_dataset

get_latest_report <- function(CIK, 
                            report = c("10-K", "10-Q", "20-F"), 
                            as_of = lubridate::now(), 
                            cache_dir = "cache", 
                            verbose = FALSE) {
     
as_of <- lubridate::as_datetime(as_of)
cache <- cache_dir
cache.filings <- file.path(cache, "filings")
dir.create(cache.filings, recursive=T, showWarnings = F)

filing_path <- file.path(cache.filings, paste0(CIK, ".parquet"))
if(!(file.exists(filing_path))) {
     filings <- get_cik_reports(CIK, verbose = verbose)
     arrow::write_parquet(filings, filing_path)
     
}

filing_range <- open_dataset(filing_path) |> 
     select(filing.date) |> 
     summarise(max_filing_date = max(filing.date),
               min_filing_date = min(filing.date)) |> 
     collect()

if(as_of > filing_range$max_filing_date | as_of < filing_range$min_filing_date) {
     filings <- get_cik_reports(CIK, verbose = verbose)
     arrow::write_parquet(filings, filing_path)
     filing_range <- arrow::open_dataset(filing_path) |> 
          select(filing.date) |> 
          summarise(max_filing_date = max(filing.date),
                    min_filing_date = min(filing.date)) |> 
          collect()
}

filing <- arrow::open_dataset(filing_path) |> 
     filter(filing.date < as_of,
            filing.name %in% report) |>
     collect() |>
     slice_max(filing.date)

return(filing)
}
