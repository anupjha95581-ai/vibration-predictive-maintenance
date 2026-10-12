# MATLAB scripts

## Phase 1: simulation
Functions: `gen_window`, `sensor_model`, `extract_features`.
Run in this order: `demo_signals`, `make_dataset`, `check_dataset`.

## Phase 2: real CWRU data
Put the CWRU .mat files in a subfolder named `cwru` (see `data/README.md`).
Run in this order: `explore_cwru`, `explore_cwru2`, `make_dataset_cwru`, `check_cwru`, `check_cwru_robust`, `check_cwru_robust2`.
`extract_features_cwru` is called by `make_dataset_cwru`. `verify_cwru_files` checks file numbers, RPM and sample counts.
