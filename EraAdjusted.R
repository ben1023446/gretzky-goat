library(dplyr)
library(readr)


league_gpg <- master %>% 
  group_by(season) %>%
  summarise(GPG = sum(G)*2/sum(GP), .groups="drop")

baseline <- mean(league_gpg$GPG)

# era adjust
master_ea <- master %>%
  left_join(league_gpg, by="season") %>%
  mutate(AdjPPG = PPG / GPG * baseline)

# extract peaks
peaks_ea <- master_ea %>%
  group_by(Player) %>%
  summarise(PeakAdj = max(AdjPPG), .groups="drop") %>%
  arrange(desc(PeakAdj))%>%
  mutate(Rank = row_number()) %>%   
  select(Rank, Player, PeakAdj) 

write_csv(peaks_ea, "rankings_era_adjusted.csv")

