# Progress

## Paper scope

1. Verify voltage-driven, current-sense operation in EIDORS using voltage
   stimulation and floating electrodes.
2. Compare the lumped contact impedance in Model A with the conformal explicit
   layer in Model B, reporting `delta_layer` and the tested mesh resolution.
3. Sweep frequency, layer parameters, and medium parameters using Model A and
   `Delta_p` across the 120 electrode pairs.

Reconstruction, anomalies, and `Delta_shape` are outside the paper scope.

## Project layout

- `setup_paths.m` configures the project folders and loads EIDORS from
  `EIDORS_ROOT` when needed.
- `core/` contains model parameters, mesh builders, pair solvers, metadata, and
  baseline comparison helper.
- `scripts/` contains verification, A/B comparison, B mesh-resolution,
  thickness, and sweep studies.
- `plots/` contains publication figures, sweep summaries, and table-ready CSV
  exporters.
- `results/` contains saved MAT, CSV, PNG, and orchestration log files.
- `arsip/` preserves superseded, exploratory, and out-of-scope scripts.
- `run_all.m` runs the workflow, catches per-stage failures, and writes
  `results/run_all_log.txt`. It assembles the B resolution series from matching
  preserved scans when available; missing B scans are recomputed only with
  `run_all(true)`. The d=1,3,5 mm thickness scans are also skipped by default
  and enabled with `run_all(true)`.
- `scripts/cceit_run_stage.m` runs each legacy-style script in an isolated
  workspace so a script-level `clear` does not erase the orchestration state.
- `plots/summary_section_tables.m` writes CSVs for verification, both mesh
  studies, A/B layer resolution, layer sensitivity, medium sensitivity, and
  any completed d=1,3,5 mm study points. `Delta_shape` is excluded by design.

## Numerical reference values

- Before correcting Netgen coordinate quantization, Model A had 2870 elements,
  max `dcc=1.1e-12`, and `delta_layer` values 0.0465 (`h_ring=1.0 mm`) and
  0.0316 (`h_ring=0.5 mm`) at `d=2 mm`, `f=500 kHz`. These are historical
  references and must be regenerated because the corrected mesh geometry can
  change Model A results.
- Model A reciprocity was previously checked on 30 pairs; rerun verification
  after regenerating the normalized-geometry mesh.
- Model B mesh refinement also makes the medium denser; the B4 generator does
  not currently isolate ring and medium element sizes.
- `d=1, 3, 5 mm` A/B results depend on running `scripts/run_thickness_study.m`;
  those values are not inferred from the `d=2 mm` baseline.
- The old `tes_B4_results.mat` and `diag_mesh_B_d2mm.mat` are preserved under
  `results/` and are inputs for the default B-resolution table assembly. The
  new consolidated output is `results/B_resolution_study.mat/.csv`.

## Output metadata

Active result writers call `cceit_make_metadata` and save interpreter version,
date, EIDORS version, and NETGEN version (`unknown` when unavailable). Existing
legacy MAT files have been preserved as-is; they are not retroactively edited.

## Runtime evidence

Only timings present in the supplied mesh-study output are recorded here:

- Model A, 2870 elements: 7 seconds per scan.
- Model B scan: 44 seconds at `h_ring=1.0 mm`, 122 seconds at 0.7 mm,
  319 seconds at 0.5 mm, and 941 seconds at 0.35 mm.
- Total runtimes for the runner scripts, verification, parameter sweeps, and
  plots were not recorded. No totals are estimated here.

## Known setup constraints

- `setup_paths.m` currently configures the user's EIDORS and NETGEN locations;
  update those two values there if either installation moves.
- `scripts/run_logged.m` runs one selected script and saves its console output,
  including failures, to a timestamped text file in `results/`.
- `setup_paths.m` does not recursively add EIDORS paths again when EIDORS is
  already initialized; this avoids stale `.git` checkpoint paths in Octave.
- Baseline cache matching ignores `h_ring_B` and `h_ring_B_coarse`; each saved
  B scan is validated against its explicit `h_ring` value, while all physical
  and core mesh parameters must still match. This permits reuse of older B4
  sweep MAT files that predate those run-selection fields.
- `run_B_resolution_study` can reuse current-baseline 1.0 and 0.5 mm scans from
  `cceit_AB_final_results.mat`; only missing 0.7 and 0.35 mm scans need solving
  when legacy B4 MAT files belong to another physical baseline.
- Pair ordering is centralized in `cceit_pair_list.m` and follows acquisition
  order: tx ascending, then rx ascending with `tx < rx`. Pair plots and CSV
  exports use that same index; regenerating them does not require a new solve.
- `scripts/run_A_electrode_resolution_study.m` reports electrode-node counts,
  effective arc widths and per-electrode mean |Y| at the baseline, then sweeps
  Model A `h_el` at 1.0, 0.6, and 0.4 mm with per-level error capture.
- Model A Netgen geometry is now generated at unit radius and scaled to SI
  units afterward. EIDORS writes geometry coordinates to three decimal places;
  generating directly in metres had quantized the 53 mm tank geometry in 1 mm
  steps. The previous per-electrode width-calibration attempt did not work and
  was removed. The normalized-geometry change still needs an Octave rerun; the
  old calibration output (including its increased magnitude variation) is not
  a valid result for the current mesh builder.
- Added experimental B5 mesh functions with separate local maximum element
  sizes for the explicit dielectric ring and tissue core, plus a coarse A2/B5
  comparison script at `h_ring=1 mm`. The core target stays at `P.h_int` to
  avoid B4's tank-wide refinement. These files have not been run in Octave;
  their NETGEN geometry syntax and element counts remain unconfirmed.
- Changes in this cleanup have not been tested by executing Octave or MATLAB.

## Next numerical work

- Run the thickness study when ready; it may take several scans and no runtime
  estimate is available for its requested mesh points.
- Re-run the A/B and verification scripts after setting up the new paths to
  reconfirm the reference values. These runs have intentionally not been made
  during this cleanup.
- Re-run `run_A_electrode_resolution_study` in Octave to check whether unit-
  radius geometry reduces `std(|Y|)/mean(|Y|)` within each separation group;
  inspect the reported max electrode-arc mismatch at the same time.
