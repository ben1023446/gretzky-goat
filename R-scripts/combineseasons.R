# combine all seasons for individual players
library(readr)
library(dplyr)
library(purrr)
library(stringr)

input_dir <- "skater_stats" 
files <- list.files(input_dir,pattern="\\.csv$",full.names=TRUE)

all_seasons <- files %>%
  set_names() %>%
  map_dfr(read_csv,.id = "file") %>%
  mutate(season = str_extract(basename(file),"\\d{4}") %>% as.integer()) %>% #get season year
  select(-file) #remove the helpers

all_seasons_clean <- all_seasons %>%
  filter(GP > 0) #remove any players with 0 games played

write_csv(all_seasons_clean, "all_seasons_combined.csv")
