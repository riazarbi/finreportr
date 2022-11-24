#' @import dplyr rvest
#' @importFrom XBRL xbrlDoAll
#' @importFrom xml2 read_html
#' @importFrom rvest html_elements html_table
#' @importFrom tools file_ext
#' @importFrom lubridate as_date
#' @importFrom tidyr separate replace_na


extract_facts <- function(CIK, accession.no, statement.types, xbrl_cache = "cache/XBRLcache", verbose  = FALSE) {
     
     # START Procedure 1: Obtain name of xbrl instance file from accession web page #
     accession.num <- gsub("-", "" , accession.no)
     
     CIK.numeric <- as.numeric(CIK)
     
     accession.num.root.url <- paste0("https://www.sec.gov/Archives/edgar/data/", 
                                      CIK.numeric, "/", 
                                      accession.num, "/")
     
     accession.header.url <- paste0(accession.num.root.url, 
                                    accession.no, "-index.html")
     header.html <- xml2::read_html(accession.header.url)
     
     accession.documents <- header.html |> 
          rvest::html_elements(".tableFile") |> 
          rvest::html_table() |> 
          bind_rows()
     
     xbrl.instance.filename <- accession.documents |> 
          filter(grepl("XBRL INSTANCE DOCUMENT", Description)) |> 
          pull(Document)
     
     if(length(xbrl.instance.filename) != 1){
          if(verbose){message("No remote file called XBRL INSTANCE DOCUMENT found. Attempting to select by type.")}
          xbrl.instance.filename <- accession.documents |>
               filter(grepl("EX-101.INS", Type)) |> pull(Document)
     }
     
     if(length(xbrl.instance.filename) != 1){
          if(verbose){message("No remote file of type EX-101.INS found. Simply selecting the largest xml file in the accession repository for processing.")}
          xbrl.instance.filename <- accession.documents |>
               filter(tools::file_ext(Document) == "xml") |> 
               filter(Size == max(Size)) |> pull(Document)
     }
     if(length(xbrl.instance.filename) != 1){
          stop("Cannot find an xml document in the accession repository. Perhaps there are no xbrl documents there?")
     }
     inst.url <- paste0(accession.num.root.url, xbrl.instance.filename)
          
     # END Procedure 1 #########################################################
     
     
     
     # START Procedure 2: Download and parse xbrl files and supporting schemas from SEC #
     ##   Download Instance Document
     dir.create(xbrl_cache, recursive = TRUE, showWarnings = FALSE)
     instFile <- XBRL::xbrlDoAll(inst.url, cache.dir=xbrl_cache, prefix.out = NULL, verbose=verbose)
     
     ##   Clear Cache Dir but keep xsd templates
     # This speeds up processing because it allows template reuse
     xml_files <- list.files("XBRLcache", pattern = "\\.xml$", full.names = TRUE)
     unlink(xml_files)
     
     instFile <- purrr::map(instFile, as_tibble)
     # END Procedure 2 #########################################################
     
     # START Procedure 3: Tidy up loaded XBRL data into data frame #############
     # link facts to context for dates and dimensions
     facts_wide <- left_join(instFile$fact, instFile$context, by = "contextId") 
     if(nrow(instFile$fact) != nrow(facts_wide)) {
          stop("joining fact table to context table is adding rows")
     }
     
     # link facts to units for ISO standards
     facts_wide_u <- left_join(facts_wide, instFile$unit, by = "unitId")
     if(nrow(facts_wide) != nrow(facts_wide_u)) {
          stop("joining fact table to context table is adding rows")
     }
     
     # separate elementId into taxonomy and concept
     facts_wide_c <- facts_wide_u |>  
          tidyr::separate(elementId, into = c("taxonomy", "concept"), sep = "_") |> 
          # make decimals numeric
          mutate(decimals = tidyr::replace_na(decimals, "0")) |>
          mutate(decimals = as.numeric(decimals),
                 startDate = lubridate::as_date(startDate),
                 endDate = lubridate::as_date(endDate)) 
     
     # this drops entries that are part of segments or consolidation axes
     # TODO think about this. mostly we don't want dimensioal stuff. 
     # but the shares classes are along these dimensions. 
     facts_wide_t <- facts_wide_c #|> filter(is.na(dimension1))
     
     # Narrow the columns down and drop duplicates
     facts_narrow_c <- facts_wide_t |> 
          select(taxonomy, 
                 concept, 
                 unitId, 
                 fact, 
                 decimals, 
                 startDate, 
                 endDate, 
                 measure,
                 dimension1,
                 value1) |> 
          distinct()
     
     facts_narrow_n <- facts_narrow_c |> 
          rename(unit = unitId, 
                 unit_iso = 
                      `measure`, 
                 start_date = startDate, 
                 end_date = endDate) 
     
     facts_narrow <- facts_narrow_n |> 
          group_by(taxonomy, 
                   concept, 
                   unit, 
                   start_date, 
                   end_date) |> 
          filter(decimals == max(decimals)) |>
          ungroup()
     
     facts <- facts_narrow |> 
          mutate(cik = CIK,
                     accession.no = accession.no) |>
          select(cik, accession.no, everything()) |> as_tibble()
     # END Procedure 3 #########################################################
     
     return(facts)
}
