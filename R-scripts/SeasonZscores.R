library(dplyr)
library(readr)

master <- read_csv("all_seasons_combined.csv") %>%
  filter(GP > 0) %>%
  mutate(PPG = (G + A)/GP)

# mean & sd per season then z-score
master_z <- master %>%
  group_by(season) %>%
  mutate(
    mu   = mean(PPG),
    sigma = sd(PPG),
    Zppg = (PPG - mu)/sigma
  ) %>%
  ungroup()

# each player’s peak Zppg and rank
peaks_z <- master_z %>%
  group_by(Player) %>%
  summarise(PeakZ = max(Zppg), .groups="drop") %>%
  arrange(desc(PeakZ)) %>%
  mutate(Rank = row_number()) %>%
  select(Rank, Player, PeakZ)  

write_csv(peaks_z, "rankings_zscore.csv")
