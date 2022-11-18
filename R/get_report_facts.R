
#' @import dplyr
#' @importFrom arrow write_parquet open_dataset

get_report_facts <- function(CIK, 
                           accession.no, 
                           cache_dir = "cache", 
                           facts_filter = NULL,
                           collect = TRUE,
                           verbose = FALSE) {
     
     
     cache <- cache_dir
     cache.facts <- file.path(cache, "facts")
     cache.xbrl <- file.path(cache, "XBRLcache")
     dir.create(cache.facts, recursive=T, showWarnings = F)
     
     facts_path <- file.path(cache.facts, paste0(CIK, "/", accession.no, ".parquet"))

     if(!(file.exists(facts_path))) {
          if(verbose){message("No facts found in cache. Downloading...")}
          facts <- extract_facts(CIK, accession.no, xbrl_cache = cache.xbrl, verbose = verbose)
          dir.create(dirname(facts_path), recursive=T, showWarnings = F)
          write_parquet(facts, facts_path)
     }
     
     if(is.null(facts_filter)) {
          facts_dataset <- open_dataset(facts_path)      
     } else {
          facts_dataset <- open_dataset(facts_path) |>
               filter(label %in% facts_filter)
     }
     
     if(collect) {
          facts <- collect(facts_dataset)
          return(facts)
     } else {
          return(facts_dataset)
     }
     
     
}