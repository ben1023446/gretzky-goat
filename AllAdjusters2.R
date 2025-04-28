library(lme4)
library(dplyr)
library(readr)
library(openxlsx)
library(tibble)

master_raw <- read_csv("all_seasons_combined.csv")

master <- master_raw %>%
  group_by(Player,season) %>%  # combine transfer rows
  summarise(GP = sum (GP,na.rm=TRUE), G = sum(G,na.rm=TRUE),A = sum(A,na.rm=TRUE), .groups = "drop") %>%
  filter(GP >= 20) %>%  # remove players with less than 20 games in a season
  mutate(PPG = (G+A)/GP)  # points per game

# mixed model ranking
model <- lmer(PPG ~ 1+(1|season)+(1|Player), data=master, REML=TRUE),mm_eff <- ranef(model)$Player %>%
  rownames_to_column("Player") %>%
  rename(Effect=`(Intercept)`) %>%
  arrange(desc(Effect)) %>%
  mutate(Rank = row_number()) %>%
  select(Rank,Player,Effect)

# season z score ranking
z_scores <- master %>%
  group_by(season) %>%
  mutate(mu = mean(PPG), sigma = sd(PPG), Zppg = (PPG-mu)/sigma) %>%
  ungroup()
z_rank <- z_scores %>%
  group_by(Player) %>%
  summarise(PeakZ = max(Zppg), .groups = "drop") %>%
  arrange(desc(PeakZ)) %>%
  mutate(Rank = row_number()) %>%
  select(Rank,Player,PeakZ)

# era adjusted rank
league_gpg <- master %>%
  group_by(season) %>%
  summarise(GPG = sum(G) * 2 / sum(GP), .groups = "drop")
baseline_gpg <- mean(league_gpg$GPG)
ea_rank <- master %>%
  left_join(league_gpg, by = "season") %>%
  mutate(AdjPPG = PPG / GPG * baseline_gpg) %>%
  group_by(Player) %>%
  summarise(PeakAdj = max(AdjPPG), .groups = "drop") %>%
  arrange(desc(PeakAdj)) %>%
  mutate(Rank = row_number()) %>%
  select(Rank, Player, PeakAdj)

# combine into worksheet
wb <- createWorkbook("GOAT_Rankings")
addWorksheet(wb,"MixedModel")
addWorksheet(wb,"ZScore")
addWorksheet(wb,"EraAdjusted")
writeData(wb,"MixedModel",mm_eff)
writeData(wb,"ZScore",z_rank)
writeData(wb,"EraAdjusted",ea_rank)
saveWorkbook(wb,"GOAT_rankings.xlsx",overwrite = TRUE)

# separate csv files
write_csv(mm_eff,"rankings_mixedmodel.csv")
write_csv(z_rank,"rankings_zscore.csv")
write_csv(ea_rank,"rankings_era_adjusted.csv")
