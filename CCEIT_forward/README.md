# CC-EIT forward workflow

## Purpose and paper goals

This project builds and checks a two-dimensional, 16-electrode capacitively
coupled EIT forward model in GNU Octave, EIDORS 3.12, and NETGEN. It computes
voltage-driven pair responses: one electrode is driven to `Vtx`, a receiver is
held at 0 V, and the remaining electrodes float. Every unordered pair is
measured, giving 120 pair admittances per scan. Values are per metre of model
depth.

The paper has three goals:

1. Verify the EIDORS voltage-driven/current-sense implementation through
   prescribed terminal voltages, current conservation, floating-electrode
   current, and reciprocity checks.
2. Compare a lumped contact-impedance representation (Model A3) with an
   explicit conformal dielectric ring (Model B6). Current results support a
   partial conclusion: `delta_layer` is about 7.9–8.5% for the tested meshes.
   Do not claim the 5% criterion is met.
3. Sweep frequency, layer properties, and homogeneous-medium properties with
   Model A. These are sensitivity studies for the chosen phantom scenario,
   not an anomaly reconstruction or biological-tissue validation.

The red conductivity regions seen in a reconstruction are outside this
forward-only study and are not evidence by themselves that the forward mesh is
too dense. They can arise from the inverse solver, sensitivity, or
regularization.

## Models

The active comparison is **Model A3/B6**. Model A3 uses the lumped contact
impedance; Model B6 meshes the explicit dielectric ring with a separate
`h_ring` target while retaining the chosen medium mesh size. The latest
recorded baseline is `h_medium=2 mm`, `h_ring=0.35 mm`, 5,182 A3 elements and
11,872 B6 elements. Its `delta_layer` is about 8.45%; the finer B6 checks
reported about 8.24%, 8.00%, and 7.90% at ring targets 0.25, 0.20, and
0.15 mm. This is partial agreement, not proof that the models are equivalent.

## Requirements and setup

- GNU Octave 7 or later (the current workstation uses Octave 11)
- EIDORS 3.12
- NETGEN with `netgen.exe`

Edit the two installation paths in `setup_paths.m` if EIDORS or NETGEN moves.
Then open Octave, set the current directory to `CCEIT_forward`, and run:

```octave
setup_paths
```

This adds `core/`, `scripts/`, and `plots/`, starts EIDORS when needed, and
checks NETGEN. `core/cceit_params.m` contains the shared physical and mesh
parameters; outputs go to `results/`.

## Manual workflow: run one paper goal at a time

`run_all.m` is archived. Start with Goal 1 only, inspect the saved numbers, and
then move to the next goal. Run `setup_paths` once in a fresh Octave session.
Use `run_logged` for each stage so its terminal output is saved in `results/`.

### Goal 1: voltage-driven/current-sense verification

```octave
run_logged('run_verify_models')
```

This saves `cceit_verification_results.mat` and a timestamped console log.
Check prescribed terminal voltages, floating current, current conservation,
and reciprocity before proceeding. This goal is reported as a verification
table; it does not need a field plot.

### Goal 2: contact impedance versus explicit layer

Run only after Goal 1 is reviewed:

```octave
run_logged('run_AB_A3_B6_coarse')
run_logged('run_B6_resolution_study')
run_logged('plot_B6_resolution_study')
run_logged('plot_AB_pair_admittance_current')
run_logged('plot_mesh_AB')
```

The coarse comparison creates the reference used by the B6 resolution study.
It records mesh-build and 120-pair scan times separately in
`AB_A3_B6_timing.csv`. Review `delta_layer`, ring/medium element counts, and
the pair-wise A/B plots.

### Goal 3: parameter sweeps

Run after the model comparison is reviewed:

```octave
run_logged('run_sweepA')
run_logged('run_sweepA2')
run_logged('run_sweepA3')
run_logged('summary_sweeps')
run_logged('export_sweep_csv')
```

Then generate and inspect the figures separately:

```octave
run_logged('plot_results')
```

`plot_results` reads the saved sweep MAT files; it does not rebuild meshes or
repeat scans. It generates the retained Goal 3 plots only: frequency response,
one three-panel layer plot, and one medium figure with eight panels (four
frequencies by conductivity and permittivity). The medium figure omits baseline
points, whose Delta_p is identically zero, so perturbed responses are easier to
compare. The old pair map, separation plot,
and current-field plot are not generated. `plot_sweepA2` and
`plot_sweepA3_medium` regenerate the layer and medium figures individually.
`summary_sweeps` writes the summary CSV/MAT without a duplicate plot.
`export_sweep_csv` converts existing MAT sweep results to tidy CSV files for
Python; it does not rerun simulations. `Delta_p` is the primary sensitivity
metric; median admittance magnitude and phase remain descriptive outputs.
The exporter creates `sweepA_frequency_data.csv`,
`sweepA_mesh_convergence.csv`, `sweepA2_long.csv`, and `sweepA3_long.csv` in
`results/`. In Python, load them with `pandas.read_csv('sweepA3_long.csv')`.

For interpretation, `run_sweepA2` changes one parameter at a time around the
configured baseline at 500 kHz; its zero-baseline layer conductivity sweep is
an absolute-value sweep. `run_sweepA3` changes medium conductivity or
permittivity around the same medium baseline separately for each tested layer
thickness and frequency. In the lossless-layer case, thickness and layer
permittivity enter the lumped contact admittance as a product, so those two
parameters are not independently identifiable from that sweep alone. Treat
the plotted `Delta_p` as the relative change across all 120 complex pair
admittances; the median magnitude and phase are descriptive summaries, not
alternative sensitivity scores.

## Reconstruction demonstration (separate from the paper workflow)

`demo_reconstruction.m` is an optional software-chain demonstration, not part
of the paper's forward-only results. It runs three synthetic inclusion layouts
(one circle, two circles left/right, three circles in a triangle) on active
Model A3 and coarse Model B6 meshes, for six cases total. B6 uses
`P.h_ring_B6_coarse`. Each case performs:

1. homogeneous and inclusion voltage-driven scans over the 120 electrode pairs;
2. conversion of transmitter current to ideal TIA voltage using
   `Vtia = -Rf * I`, then recovery of current from that voltage;
3. a homogeneous-to-inclusion transfer-impedance difference; and
4. separate real and imaginary reconstructions using a diagonally weighted,
   regularized Jacobian.

The demo uses 3 MHz, `d=1 mm`, `Rf=10 kOhm`, and deliberately large example
inclusion properties so the imaginary response is visible. These values and
the simple regularization are illustrative; they are not validated tissue
properties or a validated imaging method. Each case catches its own failure.
Successful cases save a result MAT and a pair-wise TIA CSV. The main script
also saves six three-panel reconstruction PNGs, six homogeneous-versus-inclusion
current PNGs (120 pairs in acquisition order), and `demo_run_status.mat` under
`results/reconstruction_demo/`. The current plots show real and imaginary
currents in separate panels. `demo_reconstruction/plot_current_diff.m` is
called automatically after the cases finish; run it alone to redraw those
plots from the saved status MAT without repeating forward solves.

The demo calls the active mesh builders `cceit_mesh_A3` and `cceit_mesh_B6` and
the shared voltage-driven pair solver. It has only been reviewed statically in
this cleanup, not executed in Octave.

After `setup_paths`, run in Octave with:

```octave
run('demo_reconstruction.m')
```

The source helpers live in `demo_reconstruction/`; generated files live in
`results/reconstruction_demo/`. The old example outputs under `arsip/` are
historical and are not inputs to a fresh demo run.

## Run one step at a time

For plot-only work, use the plotting commands under each goal. They read the
saved MAT data, except `plot_mesh_AB`, which rebuilds the meshes to display
them. If results are missing, run that goal's solver stage first.

## File guide

### Root

- `setup_paths.m`: EIDORS/NETGEN setup and project paths.
- `arsip/manual_run_reset_20261104/run_all.m`: archived orchestrator; do not use.
- `demo_reconstruction.m`: optional six-case A3/B6 reconstruction demo;
  helpers in `demo_reconstruction/`, generated outputs in
  `results/reconstruction_demo/`.
- `README.md`, `PROGRESS.md`: project context, status, and known limitations.

### `core/`

- `cceit_params.m`: baseline parameters and output directory.
- `cceit_mesh_A3.m`, `cceit_runA3_mesh.m`: active lumped-interface model.
- `cceit_mesh_B6.m`, `cceit_runB6.m`: explicit ring with medium/ring mesh controls.
- `cceit_pairscan.m`, `cceit_pair_list.m`, `cceit_solve_pair.m`: voltage-driven
  pair acquisition and single reverse solve for reciprocity.
- `cceit_electrode_boundary_lengths.m`: realized electrode boundary lengths.
- `cceit_same_baseline.m`: decides whether saved data match the parameters.
- `cceit_make_metadata.m`: software/version metadata for saved MAT files.
- `local_runA.m`: shared Model A helper used by sweeps.

### `scripts/`

- `run_verify_models.m`: current/voltage and reciprocity checks for A3/B6.
- `run_AB_A3_B6_coarse.m`: explicit-layer comparison at the configured coarse ring size.
- `run_B6_resolution_study.m`: ring convergence with the selected medium mesh.
- `run_sweepA.m`, `run_sweepA2.m`, `run_sweepA3.m`: frequency, layer, and
  medium sensitivity runs.
- `run_logged.m`, `cceit_run_stage.m`: console logging and isolated stage runs.

### `plots/`

- `plot_AB_pair_admittance_current.m`: separate pair-wise A/B figures and CSV.
- `cceit_plot_pair_series.m`: helper that exports one pair-series figure.
- `plot_results.m`: retained Goal 3 sensitivity figures from saved sweeps.
- `cceit_plot_layer_sensitivity.m`, `cceit_plot_medium_sensitivity.m`:
  figure builders used by the plot scripts.
- `plot_mesh_AB.m`: A3/B6 mesh close-up.
- `summary_sweeps.m`: sweep summary CSV and MAT.
- `export_sweep_csv.m` (in `scripts/`): tidy CSV export from existing sweeps.
- `summary_section_tables.m` and the former B4 comparison scripts are archived
  because they expect B4 outputs rather than the active B6 result structure.

### `results/` and `arsip/`

`results/` is the active output folder. Prior files are preserved under
`arsip/manual_run_reset_20261104/results_previous/`, and `run_all.m` is
archived in the same reset folder. One old `run_all_report.txt` stayed locked
by a text editor during cleanup. Superseded code remains under `arsip/`.

## If improving the workflow later

1. Read this README and `PROGRESS.md` first; confirm whether the change affects
   Model A3, B6, a sweep, or only plotting.
2. Keep each model's physical parameters explicit and shared through `P`.
   Do not fit contact impedance to B6 and then describe that fit as independent
   validation.
3. Change one modeling assumption at a time, save a new result file, and
   compare the 120 pairs in acquisition order. Preserve the previous run under
   `arsip/` before replacing results.
4. Record mesh sizes, element counts split into ring/medium, `delta_layer`,
   current checks, and software versions. A smaller `delta_layer` alone is
   insufficient if geometry or physics changed without documentation.
5. Use Octave for the project runs and update this file and `PROGRESS.md` when
   adding or retiring scripts.
