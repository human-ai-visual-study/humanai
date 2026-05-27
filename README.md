# Human-AI Visual Study

This repository contains supplementary materials for a computational comparison of AI-generated images and human-produced photographs.

## Contents

- `index.html`: interactive visual interface
- `images/`: web-optimized image set used in the interface
- `measurements.txt`: ImageJ/imageMeasure HSB measurement output
- `data/final_dataset.csv`: combined analysis dataset
- `results/`: statistical output tables, including sensitivity analysis output
- `figures/`: generated figures used for visual inspection
- `scripts/analyze.R`: analysis script for reproducing the main statistical outputs
- `scripts/duyarlilik_analizi.R`: sensitivity analysis script for the per-cell sample size

## Notes

The web interface uses resized image files for browser performance. The statistical analyses are based on the HSB metric values provided in `data/final_dataset.csv` and `measurements.txt`.

The R scripts require the `car` and `pwr` packages.

The sensitivity analysis uses two-sided independent-group comparisons with n = 90 per group, power = .80, and alpha levels of .05 and .0042.
