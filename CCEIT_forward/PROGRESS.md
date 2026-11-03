# Progress

## Paper workflow

The paper goals are (1) verify EIDORS voltage-driven/current-sense operation,
(2) compare lumped contact impedance A2 with explicit-layer B5, and (3) study
frequency/layer/medium sensitivity in Model A. Goal 2 is partially supported:
the tested `delta_layer` values are about 8.5–10%, above the former 5% target.
Do not tune A2 to B5 and claim independent equivalence.

The active forward workflow is `run_all.m`; the optional reconstruction demo
is explicitly separate and does not change the paper workflow.

## Active structure

- `core/`: parameters, A2/B5 meshes and solvers, pair scans, metadata.
- `scripts/`: verification, A2/B5 comparison and ring-resolution study, and
  Model A parameter sweeps.
- `plots/`: saved-result plots, pair-series plots, mesh display, sweep summary.
- `demo_reconstruction/`: helper functions for the optional 6-case demo.
- `results/`: new run outputs; currently empty after archiving prior outputs.
- `arsip/results_pre_cleanup/`: all pre-cleanup generated outputs.
- `arsip/superseded_B4_workflow/`: scripts/functions tied to the superseded B4
  comparison workflow.

## Current numerical evidence

- Corrected A mesh has 3,178 elements and electrode arc mismatch 0.14%.
- B5 at `h_ring=1.0/0.7/0.5 mm` has respectively 5,082/5,838/7,274 total
  elements; medium counts 3,844/4,282/4,234; ring counts 1,238/1,556/3,040.
- `delta_layer` at those three ring sizes is 10.06%, 9.83%, 8.99%; a separate
  0.35 mm run reported 8.46%.
- B5 coarse checks: `dcc=7.41e-12`, floating/It `1.59e-12`, and voltage
  deviation 0 V. Reciprocity must be rechecked after any mesh/solver changes.

## Recent cleanup and demo status

- `run_all.m` now targets A2/B5 verification, coarse comparison, B5 resolution,
  sweeps, summaries, and current plots. It has not been run after cleanup.
- Previous results were moved to `arsip/results_pre_cleanup/` for a clean run.
- `demo_reconstruction.m` executes three example inclusion layouts for A2 and
  coarse B5 through forward current, ideal TIA, complex transfer-impedance
  difference, and regularized complex-Jacobian reconstruction of real and
  imaginary admittivity changes. Its helper functions are in
  `demo_reconstruction/`. It has not been run in Octave; outputs are a workflow
  demonstration, not validated tissue reconstructions.
- No Octave code was run during this cleanup/demo implementation.
