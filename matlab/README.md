# MATLAB scripts

Run each phase with its own folder as MATLAB's current folder.

## phase1_simulation
Simulated vibration, sensor model and features.
Functions: `gen_window`, `sensor_model`, `extract_features`.
Run in this order: `demo_signals`, `make_dataset` (writes `features_sim.csv`), `check_dataset`.

## phase2_cwru
Real bearing data from the Case Western Reserve University Bearing Data Center.
Put the CWRU .mat files in a subfolder named `cwru` (file list in `../../data/README.md`).
Run in this order: `explore_cwru`, `explore_cwru2` (needs variables from `explore_cwru`),
`make_dataset_cwru` (writes `features_cwru.csv`), `check_cwru`, `check_cwru_robust`, `check_cwru_robust2`.
`extract_features_cwru` is a helper called by `make_dataset_cwru`.
`verify_cwru_files` checks file numbers, RPM and sample counts.
