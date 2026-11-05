# Progress

## Paper workflow

The paper goals are (1) verify EIDORS voltage-driven/current-sense operation,
(2) compare lumped contact impedance A3 with explicit-layer B6, and (3) study
frequency/layer/medium sensitivity in Model A. Goal 2 is partially supported:
the tested `delta_layer` values are about 7.9–8.5%, above the former 5% target.
Do not tune A3 to B6 and claim independent equivalence.

The active forward workflow is manual and goal-by-goal. `run_all.m` is archived;
the optional reconstruction demo is separate and does not change the paper workflow.

## Active structure

- `core/`: parameters, A3/B6 meshes and solvers, pair scans, metadata.
- `scripts/`: verification, A3/B6 comparison and ring-resolution study, and
  Model A parameter sweeps.
- `plots/`: saved-result plots, pair-series plots, mesh display, sweep summary.
- `demo_reconstruction/`: helper functions for the optional 6-case demo.
- `results/`: clean output folder for the manual runs; an old locked report may
  remain until its viewer releases it.
- `arsip/manual_run_reset_20261104/`: prior results and archived `run_all.m`.
- `arsip/superseded_B4_workflow/`: scripts/functions tied to the superseded B4
  comparison workflow.

## Current numerical evidence

- Latest A3/B6 verification: A3 has 5,182 elements, `dcc=1.27e-12`, floating
  current ratio `5.75e-16`, zero voltage deviation, and reciprocity error
  `5.72e-13` on 30 pairs.
- Latest B6 verification uses 11,872 elements, including 5,421 ring elements;
  `dcc=8.45e-12`, floating current ratio `2.16e-12`, zero voltage deviation,
  and reciprocity error `6.48e-12` on 30 pairs.
- Latest A3/B6 `delta_layer` is 8.45% at `h_ring=0.35 mm`; finer checks report
  8.24%, 8.00%, and 7.90% at 0.25, 0.20, and 0.15 mm.

## Recent cleanup and demo status

- `run_all.m` is archived. Run the scripts one goal at a time, beginning with
  `run_verify_models`; inspect its MAT and console log before moving to Goal 2.
- Previous results were moved to `arsip/manual_run_reset_20261104/`; the old
  report remained locked by another process.
- `demo_reconstruction.m` is intended to execute three example inclusion
  layouts for A3 and coarse B6 through forward current, ideal TIA, complex transfer-impedance
  difference, and regularized complex-Jacobian reconstruction of real and
  imaginary admittivity changes. Its helper functions are in
  `demo_reconstruction/`. It has not been run in Octave; outputs are a workflow
  demonstration, not validated tissue reconstructions.
- No Octave code was run during this cleanup/demo implementation.

## 2026-11-04 sweep workflow fixes

- Fixed the frequency list construction in `run_sweepA.m` to append 500 kHz
  horizontally, preserving a row vector and preventing the 1x13 vs 1x1 mismatch.
- Aligned `run_sweepA3.m` result struct fields with the fields it actually
  writes. Old MAT files with a different field schema are ignored and rebuilt
  instead of being concatenated into an incompatible struct array.
- Updated `summary_sweeps.m` to compute frequency `Delta_p` relative to the
  configured baseline frequency and to read the current A3 field names.
- Updated `plot_results.m` to use the active `cceit_runA3_mesh` solver.
- `run_all.m` has been archived; run each goal manually. These edits were
  inspected statically; Octave was not run.

## Manual Goal 1/2 checkpoint

- Goal 1 verification completed on 2026-11-04: A3 has 5,182 elements and B6
  has 11,872 elements at `h_ring=0.35 mm`; current/voltage checks and 30-pair
  reciprocity errors are within the observed numerical tolerances. Its console
  log is `run_verify_models_console_20261104_141851.txt`.
- Goal 2 coarse A3/B6 comparison completed at 500 kHz, `h_medium=2 mm`, and
  `h_ring=0.35 mm`: `delta_layer=0.0844945`, median magnitude ratio 0.916203.
  The B6 resolution study is the next step. Removed automatic `best` legend
  placement from this comparison plot; regenerate after the resolution run if
  a refreshed coarse figure is needed.
- B6 resolution study completed at `h_ring=0.35/0.25/0.20/0.15 mm`, giving
  `delta_layer=8.449/8.242/8.000/7.896%`; differences remain above 5% and have
  not fully plateaued. `plot_B6_resolution_study.m` refreshes its figure from
  the MAT without rebuilding meshes.
- Updated the coarse A3/B6 runner to time mesh generation and the 120-pair
  scan separately for both models, saving the measurements to
  `AB_A3_B6_timing.csv`. The timing values require rerunning that coarse stage;
  the existing 0.35 mm result predates these timing fields.

## Goal 3 metric standardization

- `Delta_p` is now the primary measure in all sensitivity plots. Median
  magnitude and phase remain descriptive; ratio-`r` sensitivity plots and
  sweep outputs were removed. The A3 medium summary plot shows mean `Delta_p`
  over tested factors for each thickness/frequency condition.
- A2 perturbs one parameter at a time around the configured 500 kHz baseline;
  its layer-conductivity sweep is absolute because baseline conductivity is
  zero. A3 uses the same medium baseline, with separate fixed-thickness and
  frequency scenarios. With a lossless layer, thickness and layer permittivity
  are coupled in the lumped contact admittance and should not be described as
  independently identifiable.
- No Octave run was performed; regenerate sweep results and Goal 3 plots
  manually before using these updated outputs.

## Frequency and mesh sweep correction

- The first rerun of `run_sweepA` exposed a real mesh-study defect: it varied
  `P.h_int`/`P.h_el`, while `cceit_mesh_A3` built every mesh from fixed
  `P.h_int_A3`. All three reported 5,182 elements and zero change, so those
  mesh-convergence values are invalid. The frequency sweep from that run is
  independent of this defect.
- Added opt-in `mesh_h_int_A3` and `mesh_h_el_A3` overrides to
  `cceit_mesh_A3`; calls without overrides retain the prior production mesh
  settings. `run_sweepA` now passes its per-level mesh sizes explicitly and
  errors if fewer than two distinct mesh sizes are produced.
- Octave was not run. Rerun `run_sweepA` and confirm element counts differ and
  the coarse-to-fine `delta_mesh_A` values are nonzero before using them.

## 2026-11-04 plot layout cleanup

- Moved figure legends out of data regions in `plot_results.m`,
  `plot_sweepA2.m`, `plot_sweepA3_medium.m`, and `plot_mesh_AB.m`.
- Removed a free-floating mesh annotation that could overlay the convergence
  curve. No plot uses automatic `best` legend placement now.
- Static source inspection only; regenerate figures by running the plot scripts.

## Goal 3 layer sensitivity figure update

- Restored the direct `Delta_p` plots for thickness, permittivity, and
  conductivity. The three parameter curves now have connecting lines and the
  configured baseline is marked with a filled diamond.
- Static inspection only; regenerate the figure from the saved A2 MAT.

## Goal 3 figure selection and layout

- `plot_results.m` now generates only the retained Goal 3 figures from saved
  sweep results; it no longer computes the pair map, separation plot, or
  current-density field, and no longer rebuilds a mesh or repeats scans.
- Frequency response is one standalone plot. Layer response is one three-panel
  plot using direct `Delta_p` axes and connecting lines. Medium sensitivity is
  one 4-by-2 figure: four frequencies by conductivity and permittivity. It omits
  the baseline points (`Delta_p=0`) and uses one shared legend so perturbed
  responses are easier to compare.
- `summary_sweeps.m` now writes its table CSV/MAT only; frequency visualization
  comes from `plot_results.m`. Goal 2 plots remain available from their
  dedicated scripts.
- Removed the duplicate two-panel frequency PNG from `run_sweepA.m`; it now
  saves sweep data only, and `plot_results.m` creates the single retained
  frequency figure after the sweeps.
- Added `export_sweep_csv.m` to convert existing frequency, mesh, layer, and
  medium MAT results into tidy CSV tables without rerunning any simulations.
- Figure exporters use `PaperPositionMode='auto'` and larger canvas sizes to
  reduce cropped labels. The medium plot reserves space for a shared legend
  and panel spacing. Octave rendering was not run; inspect regenerated PNGs.
- Static source review only; regenerate PNGs from the existing sweep MAT files.

## Medium-sensitivity plot Octave legend fix

- Octave 11 raised an error while deleting a manually positioned legend during
  figure close, even though it had written the PNG. Replaced that shared legend
  with figure annotations in a reserved top strip to avoid the failing legend
  callback. Rerun `plot_results` to refresh the medium PNG; Octave was not run
  here.

## 2026-11-04 report schema fix

- Updated `generate_report.m` for the current sweep MAT schemas: frequency
  `Delta_p` is derived from `Yf` against the baseline frequency, A2 median
  fields use `median_abs`/`median_phase`, and A3 sensitivity uses
  `Delta_p_sig`/`Delta_p_eps`.
- Static inspection only; run `generate_report.m` manually to produce a fresh
  report.

## Reconstruction demo review and model update

- Added step-by-step comments to the demo driver and case helper, including
  phantom/model choices, the forward → ideal TIA → differential impedance →
  reconstruction flow, saved outputs, and illustrative-only limitations.
- Clarified that `plot_current_diff.m` redraws current plots from saved data and that generated
  files go under `results/reconstruction_demo/`; old archived outputs are not
  fresh-run inputs.
- Updated the demo from legacy A2/B5 builders to the active `cceit_mesh_A3` and
  `cceit_mesh_B6` functions; B6 uses `P.h_ring_B6_coarse`. Updated the model
  names in the optional current plots and README accordingly.
- Connected `plot_current_diff.m` to the end of the demo after it saves the
  status MAT. Each completed phantom/model case now gets a current plot with
  homogeneous and inclusion responses across the 120 pairs in acquisition
  order; the script can also redraw these plots from saved data alone.
- The prior undefined-function risk from legacy filenames is removed by these
  call-site changes. Octave was not run, so a fresh demo run is still needed to
  confirm the end-to-end reconstruction pipeline on A3/B6.

## Legacy current-solver NETGEN path fix

- `cceit_sim_v2_sebelumnya_masih_I_solver.m` now calls `setup_paths()` and reads
  the validated NETGEN folder through `cceit_params()` before adding it to
  `PATH`. It no longer depends on `CCEIT_NETGEN_BIN` already being set in the
  Octave process. The script was not run; verify it manually in a fresh session.
