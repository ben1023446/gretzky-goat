# list all seasons in one table
library(dplyr)
library(purrr)
library(readr)
library(stringr)

files <- list.files("skater_stats", pattern = "\\.csv$", full.names = TRUE)
all_stats <- files %>%
  set_names() %>% 
  map_dfr(read_csv, .id = "season_file") %>%
  mutate(year = str_extract(season_file, "\\d{4}") %>% as.integer()) # get season year

career <- all_stats %>%
  group_by(Player) %>%
  summarise(seasons = n(), total_games = sum(GP,na.rm=TRUE), total_goals = sum(G,na.rm=TRUE), total_assists = sum(A,na.rm=TRUE), total_points = sum(PTS,na.rm=TRUE), avg_points_per_season = mean(PTS,na.rm=TRUE)) %>%
  arrange(desc(total_points))

write_csv(career, "career_stats_summary.csv")
