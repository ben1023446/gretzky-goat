library(httr)
library(rvest)
library(stringr)
library(readr)
library(dplyr)

dir.create("skater_stats", showWarnings = FALSE)

# to avoid bot detection
base_delay   <- 3     # seconds to wait between requests
jitter_max   <- 1     # randomly add up to one second

for (year in 1967:2024) {
  out_file <- sprintf("skater_stats/skaters_%d.csv", year) # make csv file for each year
  if (file.exists(out_file)) next 
  url  <- sprintf("https://www.hockey-reference.com/leagues/NHL_%d_skaters.html", year)
  resp <- GET(url, user_agent("you@domain.com"))
  if (status_code(resp) != 200) {
    message("Skipping ", year, ": HTTP ", status_code(resp))
    next
  }
  
  # get html
  txt <- content(resp, as = "text", encoding = "UTF-8")
  clean_html <- str_replace_all(txt, "<!--|-->", "") # remove comment markers
  page <- read_html(clean_html)
  node <- page %>% html_node("#player_stats") # get player stats
  if (inherits(node, "xml_missing") || xml2::xml_length(node) == 0) {
    message("No stats table for ", year, ", skipping.")
    next
  }
  
  tbl_raw <- html_table(node, fill = TRUE)
  
  #remove top row of headers
  if (nrow(tbl_raw) >= 2 && any(is.na(names(tbl_raw)))) {
    headers <- tbl_raw[2, ] %>% unlist() %>% as.character()
    tbl <- tbl_raw[-c(1,2), ]
    names(tbl) <- headers
  } 
  else {
    tbl <- tbl_raw
  }
  tbl <- type_convert(tbl,locale=locale(),trim_ws=TRUE)
  
  # force TOI and ATOI columns to be text to stop incorrect time formatting
  if ("time_on_ice" %in% names(tbl)) {
    tbl$time_on_ice <- paste0("'", tbl$time_on_ice)
  }
  if ("time_on_ice_avg" %in% names(tbl)) {
    tbl$time_on_ice_avg <- paste0("'", tbl$time_on_ice_avg)
  }
  
  tbl_clean <- tbl %>%
  filter(as.numeric(GP)>0)  # remove rows with 0 games played
  
  write_csv(tbl_clean, out_file)
  message("Wrote ", year)
  Sys.sleep(base_delay + runif(1, 0, jitter_max))
}
