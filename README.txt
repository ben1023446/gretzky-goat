# NHL GOAT Pipeline

A reproducible, data-driven framework to quantify Wayne Gretzky’s all-time NHL dominance and estimate the probability that a future player will surpass him.  
This repository contains all R and MATLAB scripts, configuration files, and environment definitions needed to reproduce the results from “HOW GREAT WAS GRETZKY?”
and the likelihood of seeing the dominance of future GOATs (April 2025).

## Features

- **Era-adjusted PPG**, **mixed-effects** and **z-score** metrics  
- **Composite indices** and **ensemble forecasting**  
- **Extreme-value theory (GEV)** fitting and **return-level** curves  
- **Monte Carlo** simulation of career-peak events  
- Fully **Dockerized** R environment for one-click reproducibility  
- Clear separation of R scripts, MATLAB scripts, and data

## Repository Structure

gretzky-goat/ ├── R-scripts/ # R code: scraping, cleaning, metrics │ ├── scrape_and_clean.R │ ├── compute_metrics.R │ └── run_all_metrics.R # calls other R scripts in sequence ├── MATLAB-scripts/ # MATLAB code: GEV fitting, simulation │ └── runAllEVTAndSimulations.m ├── data/ # cleaned data (no raw dumps) │ └── all_seasons_combined.csv ├── results/ # generated tables & figures ├── Dockerfile # builds R 4.4.3 + tidyverse container ├──  .gitignore # keep unwanted files out of Git └── README.md # this file


## Prerequisites

- [Docker](https://www.docker.com/) (for R environment)  
- **OR** access to R 4.4.3 + tidyverse v1.4.0 manually  
- MATLAB R2024b (or a department Docker image)  
- Git (if you want to clone and track changes locally)

## Installation & Setup

# Clone this repo  
```bash
git clone https://github.com/ben1023446/gretzky-goat.git
cd gretzky-goat

# Build the Docker image
docker build -t goat-pipeline-r:latest .

# Run the full R pipeline (mounts data folder)
docker run --rm \
  -v "$(pwd)/data:/home/pipeline/data" \
  goat-pipeline-r:latest

# This will generate all metric CSVs in results/.

# Run the MATLAB EVT & simulation
# If you have a MATLAB Docker image available:
docker build -f Dockerfile.matlab -t goat-pipeline-matlab:latest .
docker run --rm goat-pipeline-matlab:latest

# otherwise, on your system or cluster:
module load matlab/R2024b
matlab -batch "runAllEVTAndSimulations"
#That script fits GEVs, runs 20 000-run Monte Carlo, and writes final tables/plots into results/.

Viewing Results
results/
├── dominance_scores.csv           # Gretzky’s D_goat and runner-up comparisons by metric
├── gev_parameters.csv             # Fitted GEV ξ, σ, μ for each metric
├── exceedance_probabilities.csv   # P(future > D_goat) and 95% CIs for each metric
├── return_level_curves/           
│   ├── composite_return_level.png # Return-level curve for the Composite metric
│   └── ...                        # Other metrics’ curves
├── histograms/                    
│   ├── composite_mc_histogram.png # Monte Carlo histogram for the Composite metric
│   └── ...                        # Other metrics’ histograms
└── ensemble_forecast.png          # Final bar chart with unweighted/weighted ensemble lines

.csv files give the raw numbers behind Tables 4–7 in the dissertation.

return_level_curves/ and histograms/ contain the PNGs used for Figures 2–3 and all Appendix plots.

ensemble_forecast.png is the combined forecast bar chart (Figure 4).

Citation
If you use or build on this work, please cite:

Keith, B. (2025) gretzky-goat-pipeline [code repository]. GitHub. Available at: https://github.com/ben1023446/gretzky-goat (Accessed: 28 April 2025).

License
MIT © 2025 Ben Keith
(Feel free to choose a license that fits your university’s policy.)

       
