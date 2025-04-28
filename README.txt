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

gretzky-goat/ ├── R-scripts/ # R code: scraping, cleaning, metrics │ ├── scrape_and_clean.R │ ├── compute_metrics.R │ └── run_all_metrics.R # calls other R scripts in sequence ├── MATLAB-scripts/ # MATLAB code: GEV fitting, simulation │ └── runAllEVTAndSimulations.m ├── data/ # cleaned data (no raw dumps) │ └── all_seasons_combined.csv ├── results/ # generated tables & figures ├── Dockerfile # builds R 4.4.3 + tidyverse container ├── Dockerfile.matlab # (optional) MATLAB R2024b container spec ├── .gitignore # keep unwanted files out of Git └── README.md # this file


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
After both pipelines complete, open the results/ folder to find:

dominance_scores.csv

gev_parameters.csv

exceedance_probabilities.csv

Return-level and histogram PNGs

These match exactly the tables and figures in the dissertation.

Citation
If you use or build on this work, please cite:

Keith, B. (2025) gretzky-goat-pipeline [code repository]. GitHub. Available at: https://github.com/ben1023446/gretzky-goat (Accessed: 28 April 2025).

License
MIT © 2025 Ben Keith
(Feel free to choose a license that fits your university’s policy.)

       
