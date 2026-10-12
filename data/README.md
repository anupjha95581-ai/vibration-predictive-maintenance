# Data

- `features_sim.csv`: simulated feature table (Phase 1).
- `features_cwru.csv`: features extracted from the Case Western Reserve University bearing data, 4 motor loads.
- `firmware_features.csv`: labeled feature windows published by the simulated ESP32 node.

## CWRU files used (not included, download from the CWRU Bearing Data Center)

Drive-end data, 0.007 inch faults, outer race at 6 o'clock. Normal baselines are 48 kHz, fault files 12 kHz.

| Load | Normal | Inner race | Ball | Outer race |
|---|---|---|---|---|
| 0 hp | 97 | 105 | 118 | 130 |
| 1 hp | 98 | 106 | 119 | 131 |
| 2 hp | 99 | 107 | 120 | 132 |
| 3 hp | 100 | 108 | 121 | 133 |

Check these numbers against the tables on the CWRU website before relying on them.
Note: the stored RPM for normal files 98 and 99 read 1797, not the lower speeds expected at 1 and 2 hp.
