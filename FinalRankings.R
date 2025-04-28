library(dplyr)
library(readr)
library(tidyr)
library(purrr)

mm <- read_csv("rankings_mixedmodel.csv") %>% select(Player, Effect)
zs <- read_csv("rankings_zscore.csv") %>% select(Player, PeakZ)
ea <- read_csv("rankings_era_adjusted.csv") %>% select(Player, PeakAdj)

# raw career stats
career <- read_csv("all_seasons_combined.csv") %>%
  group_by(Player) %>%
  summarise(CareerGP=sum(GP,na.rm=TRUE),CareerGoals=sum(G,na.rm=TRUE),CareerAssists=sum(A,na.rm=TRUE),CareerPPG=(CareerGoals+CareerAssists)/CareerGP,.groups="drop")

# one table
composite <- mm %>%
  inner_join(zs,by = "Player") %>%
  inner_join(ea,by = "Player") %>%
  inner_join(career %>% filter(CareerGP >= 200),by="Player") # only players with 200+ games played

# turn all metrics into z-scores
composite_std <- composite %>%
  mutate(z_Effect = (Effect-mean(Effect,na.rm=TRUE))/sd(Effect,na.rm=TRUE), z_PeakZ = (PeakZ-mean(PeakZ,na.rm=TRUE))/sd(PeakZ,na.rm=TRUE), z_PeakAdj = (PeakAdj-mean(PeakAdj,na.rm=TRUE))/sd(PeakAdj,na.rm=TRUE), z_CareerGoals = (CareerGoals-mean(CareerGoals,na.rm=TRUE))/sd(CareerGoals,na.rm=TRUE), z_CareerAst = (CareerAssists-mean(CareerAssists,na.rm=TRUE))/sd(CareerAssists,na.rm=TRUE), z_CareerPPG = (CareerPPG-mean(CareerPPG,na.rm=TRUE))/sd(CareerPPG,na.rm=TRUE))

# unweighted composite score
composite_std <- composite_std %>%
  mutate(Composite = rowMeans(select(., starts_with("z_")), na.rm=TRUE)) %>%
  arrange(desc(Composite)) %>%
  mutate(Rank = row_number()) %>%
  select(Rank, Player, Composite, everything())
write_csv(composite_std, "final_rankings.csv")

#weighted composite
composite_w <- composite_std %>%
  mutate(Composite_w = 0.40 * z_Effect + 0.30 * z_PeakAdj + 0.20 * z_PeakZ + 0.10 * z_CareerPPG) %>%
  arrange(desc(Composite_w)) %>%         
  mutate(Rank_w = row_number()) %>%      
  select(Rank_w, Player, Composite_w, everything())
write_csv(composite_w, "final_rankings_weighted.csv")