
# ON ICE

This branch is _on ice_. I don't have any current plans to finish it or extend it.

I have made significant changes to the original finreportr package. This branch barely shares any code with the original repo. 

That said, the functions work - you might find them useful.

## Usage

```r
# if this doesn't work clone in the repo and use devtools load_all()
install_github("riazarbi/xbrl") # the cran version is broken
install_github("riazarbi/finreportr", ref = "riaz-mods")
library(secfacts)
options(stringsAsFactors = FALSE)
options(HTTPUserAgent = "NAME EMAIL@email.com")
```

```r
> company_info("AAPL")
     company        CIK  SIC state state.inc FY.end     street.address         city.state
1 Apple Inc. 0000320193 3571    CA        CA   0930 ONE APPLE PARK WAY CUPERTINO CA 95014
```

```r
> get_cik("AAPL")
[1] "0000320193"
```

```r
> get_cik("AAPL") |> get_cik_reports()
# A tibble: 1,860 × 5
   cik        accession.no         filing.name filing.date         report.date        
   <chr>      <chr>                <chr>       <dttm>              <dttm>             
 1 0000320193 0000320193-22-000113 4           2022-11-23 00:00:00 2022-11-22 00:00:00
 2 0000320193 0001354457-22-000638 25-NSE      2022-11-09 00:00:00 NA                 
 3 0000320193 0001193125-22-278435 8-K         2022-11-07 00:00:00 2022-11-06 00:00:00
 4 0000320193 0000320193-22-000111 4           2022-11-01 00:00:00 2022-10-28 00:00:00
 5 0000320193 0000320193-22-000108 10-K        2022-10-28 00:00:00 2022-09-24 00:00:00
 6 0000320193 0000320193-22-000107 8-K         2022-10-27 00:00:00 2022-10-27 00:00:00
 7 0000320193 0000320193-22-000102 4           2022-10-18 00:00:00 2022-10-15 00:00:00
 8 0000320193 0000320193-22-000101 4           2022-10-18 00:00:00 2022-10-15 00:00:00
 9 0000320193 0000320193-22-000097 4           2022-10-04 00:00:00 2022-10-01 00:00:00
10 0000320193 0000320193-22-000095 4           2022-10-04 00:00:00 2022-10-01 00:00:00
# … with 1,850 more rows
# ℹ Use `print(n = ...)` to see more rows
```

```r
> get_cik("AAPL") |> get_latest_report()
# A tibble: 1 × 5
  cik        accession.no         filing.name filing.date         report.date        
  <chr>      <chr>                <chr>       <dttm>              <dttm>             
1 0000320193 0000320193-22-000108 10-K        2022-10-28 00:00:00 2022-09-24 00:00:00
```

```r
> get_report_facts("0000320193","0000320193-22-000108")
# A tibble: 1,041 × 12
   cik       acces…¹ taxon…² concept unit  fact  decim…³ start_date end_date   unit_…⁴
   <chr>     <chr>   <chr>   <chr>   <chr> <chr>   <dbl> <date>     <date>     <chr>  
 1 00003201… 000032… dei     Amendm… NA    false       0 2021-09-26 2022-09-24 NA     
 2 00003201… 000032… dei     Docume… NA    2022        0 2021-09-26 2022-09-24 NA     
 3 00003201… 000032… dei     Docume… NA    FY          0 2021-09-26 2022-09-24 NA     
 4 00003201… 000032… dei     Entity… NA    0000…       0 2021-09-26 2022-09-24 NA     
 5 00003201… 000032… us-gaap Proper… NA    P1Y         0 2021-09-26 2022-09-24 NA     
 6 00003201… 000032… us-gaap Proper… NA    P5Y         0 2021-09-26 2022-09-24 NA     
 7 00003201… 000032… us-gaap Revenu… NA    P1Y         0 NA         2022-09-24 NA     
 8 00003201… 000032… us-gaap Revenu… numb… 0.64        2 NA         2022-09-24 pure   
 9 00003201… 000032… us-gaap Revenu… numb… 0.27        2 NA         2022-09-24 pure   
10 00003201… 000032… us-gaap Revenu… numb… 0.07        2 NA         2022-09-24 pure   
# … with 1,031 more rows, 2 more variables: dimension1 <chr>, value1 <chr>, and
#   abbreviated variable names ¹​accession.no, ²​taxonomy, ³​decimals, ⁴​unit_iso
# ℹ Use `print(n = ...)` to see more rows, and `colnames()` to see all variable names
```

One **very cool feature** of this package is that it makes use of a cache. So you can use it to incrementally update data without hitting the SEC each time.

## Why is it on ice?

The code here successfully and accurately extracts facts from the XBRL of filings. Unfortunately, compaies file so differently that comparison across companies is difficult to automate. 

One particular problem broke the camel's back. For dual-class shares, companies make use of a second reporting axis. This breaks the neat start schema of the rest of the facts, and there is no standard way that companies nbame these additional dimensions. Because shares is so fundamental to computing ratios it's a bit of a nail in the coffin, so I threw in the towel and decided to pay for clean data instead.

