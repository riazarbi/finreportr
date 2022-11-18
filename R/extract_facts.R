#' @import dplyr rvest
#' @importFrom XBRL xbrlDoAll
#' @importFrom xml2 read_html
#' @importFrom rvest html_elements html_table
#' @importFrom tools file_ext
#' @importFrom lubridate as_date


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
     
     # END Procedure 2 #########################################################
     
     # START Procedure 3: Tidy up loaded XBRL data into data frame #############      
     ##   Get Role ID from Instance Document
     role.df <- instFile$role 
     
     role.id <- as.character(role.df$roleId)
     
     ##   Create statement template from Presentation Linkbase
     statement.skeleton <-
          instFile$presentation %>%
          filter(roleId %in% role.id)
     
     rowid <- c(1:nrow(statement.skeleton))
     statement.skeleton <- mutate(statement.skeleton, rowid = rowid)
     
     # ##   Merge with Label Linkbase
     # statement <-
     #      merge(statement.skeleton, instFile$label, by.x = "toElementId", 
     #            by.y = "elementId") %>%
     #      filter(labelRole == preferredLabel)
     
     ##   Merge with Label Linkbase
     statement <-
          merge(statement.skeleton, instFile$label, by.x = "toElementId", 
                by.y = "elementId") %>%
          filter(labelRole == "http://www.xbrl.org/2003/role/label")
     
     ##   Merge with Fact Linkbase
     statement <- merge(statement, instFile$fact, by.x = "toElementId", 
                        by.y = "elementId")
     
     ##   Merge with Context Linkbase
     statement <- merge(statement, instFile$context, by.x = "contextId", 
                        by.y = "contextId") %>%
          arrange(rowid)
     
     ##   Merge with Presentation Linkbase
     role_descriptions <- instFile$role |> select(roleId, description)
     statement <- left_join(statement, role_descriptions, by = "roleId") 
     
     ## Add CIK and accession.no
     statement <- statement |> mutate(cik = CIK, accession.no = accession.no)
          
     ## Subset combined table
     statement <- subset(statement, is.na(statement$dimension1))
     # Clean up
     clean.statement <- statement |> select(labelString, unitId, fact,
                               startDate, endDate, rowid, description, cik, accession.no) |>
          mutate(startDate = lubridate::as_date(startDate),
                 endDate = lubridate::as_date(endDate))

     clean.statement <- clean.statement |> rename(label = labelString,
                                                  unit = unitId,
                                                  section = description) 
     
     clean.statement <- clean.statement |> 
          arrange(rowid) |> 
          select(-rowid) |>
          select(cik, accession.no, everything()) |> as_tibble()
     # END Procedure 3 #########################################################
     
     return(clean.statement)
}