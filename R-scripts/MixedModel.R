library(lme4)
library(dplyr)
library(readr)

# read combined table
master <- read_csv("all_seasons_combined.csv") %>%
  filter(GP > 0) %>%                         # remove players with 0 games
  mutate(PPG = (G + A) / GP)                # calculate ppg

#mixed model:
model <- lmer(PPG ~ 1 + (1 | season) + (1 | Player),
              data = master,
              REML = TRUE)

# extract the player random effects (BLUPs)
player_eff <- ranef(model)$Player %>%        # data frame of random intercepts
  tibble::rownames_to_column("Player") %>%   # bring rownames into a column
  rename(Effect = `(Intercept)`)             # name the column "Effect"

# rank players
ranked <- player_eff %>%
  arrange(desc(Effect))

# identify GOAT and compute dominance (σ)
sigma_u <- sd(player_eff$Effect)             # spread of player effects
top1    <- ranked$Effect[1]                  # best player’s effect
top2    <- ranked$Effect[2]                  # runner-up
D_goat  <- (top1 - top2) / sigma_u
GOAT    <- ranked$Player[1]

# number column
ranked <- player_eff %>%
  arrange(desc(Effect)) %>%
  mutate(Rank = row_number()) %>%      
  select(Rank, everything())           # move rank to be the first column


write_csv(ranked, "dominance_rankings.csv")

sink("goat_summary.txt")
cat("Mixed‐model GOAT:", GOAT, "\n")
cat("Dominance score (σ‐units):", round(D_goat, 2), "\n")
sink()
