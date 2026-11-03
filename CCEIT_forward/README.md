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
2. Compare a lumped contact-impedance representation of a dielectric layer
   (Model A2) with an explicit conformal dielectric ring (Model B5). Current
   results support a partial conclusion: at the tested baseline and mesh,
   `delta_layer` is about 8.5–10%. Do not claim the original 5% criterion is
   met. State the mesh resolution and the limit in the paper.
3. Sweep frequency, layer properties, and homogeneous-medium properties with
   Model A. These are sensitivity studies for the chosen phantom scenario,
   not an anomaly reconstruction or biological-tissue validation.

The red conductivity regions seen in a reconstruction are outside this
forward-only study and are not evidence by themselves that the forward mesh is
too dense. They can arise from the inverse solver, sensitivity, or
regularization.

## Models

**Model A2** uses `core/cceit_mesh_A.m`, whose circular geometry is generated
at unit radius and scaled to SI units. This avoids millimetre-scale rounding
when EIDORS writes the NETGEN geometry. `core/cceit_runA_mesh.m` applies the
effective contact impedance and computes the 120 pair responses.

**Model B5** uses `core/cceit_mesh_B5.m` and `core/cceit_runB5.m`. The tissue
core uses `P.h_int` and the explicit ring uses a separate `h_ring` target. In
the recorded coarse comparison, B5 had 5,082 total elements (3,844 medium,
1,238 ring) at `h_ring=1 mm`; Model A2 had 3,178 elements. At 0.5 mm, B5 had
7,274 elements (4,234 medium, 3,040 ring). These counts show that refining the
ring does not cause the whole medium to become as dense as the former B4
workflow. B5 is an experimental mesh generator; the user runs the scripts in
Octave and checks the output before using new results.

The current measured comparison is not a proof of equivalence: at 500 kHz,
`delta_layer` was 10.06%, 9.83%, and 8.99% for B5 ring targets 1.0, 0.7, and
0.5 mm. A separate 0.35 mm run gave 8.46%. Report these as the observed
comparison and do not tune Model A to B merely to cross a threshold.

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

## Run the workflow

Run the main workflow from the project directory:

```octave
run_all
```

`run_all` runs, in order: verification, the coarse A2/B5 comparison, B5 ring
resolution (reusing the 1 mm scan created by the comparison), Model A sweeps,
sweep summaries, Model A plots, separate A/B pair plots, and the mesh figure.
Each stage is logged in `results/run_all_log.txt` and
`results/run_all_console.csv`. A failed stage is recorded and later stages
continue; check both logs before using the outputs. The initial full run needs
all sweeps and several forward scans, so it can take a few minutes or longer.

## Run one step at a time

Each command below assumes `setup_paths` has already run. `run_logged` saves
terminal output to a timestamped text file under `results/`.

```octave
run_logged('run_verify_models')
run_logged('run_AB_A2_B5_coarse')
run_logged('run_B5_resolution_study')
run_logged('run_sweepA')
run_logged('run_sweepA2')
run_logged('run_sweepA3')
run_logged('summary_sweeps')
```

The B5 resolution script requires a successful coarse A2/B5 run first. It
reuses the 1 mm point and solves 0.7 and 0.5 mm ring points while retaining
`P.h_int` for the medium. For mesh tinkering, change `P.h_int`, `P.h_el`, or
the supplied B5 `h_ring` in a copied run script; avoid changing shared
baseline parameters without regenerating dependent results.

## Plot saved results without rerunning the solver

Plots read MAT files; they do not run pair scans (the mesh figure is the
exception because it rebuilds the meshes to display them).

```octave
run('plots/plot_AB_pair_admittance_current.m')
run('plots/summary_sweeps.m')
run('plots/plot_results.m')
```

The A/B pair plot script writes six **separate** figures in acquisition order:
Model A and B magnitude, phase, and transmitter-current magnitude. It also
writes `AB_pair_admittance_current_acquisition_order.csv`. With `Vtx=1 V`,
`|Itx| = |Ypair|` numerically; units differ (A versus S per unit depth).
It prefers the latest complete `B5_resolution_study.mat`; if that file is
missing or stale, it falls back to the 1 mm `AB_A2_B5_coarse_results.mat`.
To plot newly computed 0.7/0.5 mm data, rerun `run_B5_resolution_study` first.

To regenerate the mesh image (this rebuilds A2 and B5 meshes):

```octave
run('plots/plot_mesh_AB.m')
```

## File guide

### Root

- `setup_paths.m`: EIDORS/NETGEN setup and project paths.
- `run_all.m`: ordered workflow and stage logs.
- `README.md`, `PROGRESS.md`: project context, status, and known limitations.

### `core/`

- `cceit_params.m`: baseline parameters and output directory.
- `cceit_mesh_A.m`, `cceit_runA_mesh.m`: Model A2 mesh and scan.
- `cceit_mesh_B5.m`, `cceit_runB5.m`: locally refined explicit-ring model.
- `cceit_pairscan.m`, `cceit_pair_list.m`, `cceit_solve_pair.m`: voltage-driven
  pair acquisition and single reverse solve for reciprocity.
- `cceit_electrode_boundary_lengths.m`: realized electrode boundary lengths.
- `cceit_same_baseline.m`: decides whether saved data match the parameters.
- `cceit_make_metadata.m`: software/version metadata for saved MAT files.
- `local_runA.m`: shared Model A helper used by sweeps.

### `scripts/`

- `run_verify_models.m`: current/voltage and reciprocity checks for A2/B5.
- `run_AB_A2_B5_coarse.m`: first explicit-layer comparison at 1 mm ring size.
- `run_B5_resolution_study.m`: ring convergence with fixed medium mesh.
- `run_sweepA.m`, `run_sweepA2.m`, `run_sweepA3.m`: frequency, layer, and
  medium sensitivity runs.
- `run_logged.m`, `cceit_run_stage.m`: console logging and isolated stage runs.

### `plots/`

- `plot_AB_pair_admittance_current.m`: separate pair-wise A/B figures and CSV.
- `cceit_plot_pair_series.m`: helper that exports one pair-series figure.
- `plot_results.m`: Model A field and sensitivity figures from saved sweeps.
- `plot_mesh_AB.m`: A2/B5 mesh close-up.
- `summary_sweeps.m`: sweep summary CSV and figure.
- `summary_section_tables.m` and the former B4 comparison scripts are archived
  because they expect B4 outputs rather than the active B5 result structure.

### `results/` and `arsip/`

`results/` is intentionally clean for the next run. New MAT, CSV, PNG, and
console logs belong here. Previous run outputs are preserved in
`arsip/results_pre_cleanup/`. Superseded B4 and exploratory source files are
preserved in `arsip/`; they are not part of the default A2/B5 workflow.

## If improving the workflow later

1. Read this README and `PROGRESS.md` first; confirm whether the change affects
   Model A2, B5, a sweep, or only plotting.
2. Keep each model's physical parameters explicit and shared through `P`.
   Do not fit contact impedance to B5 and then describe that fit as independent
   validation.
3. Change one modeling assumption at a time, save a new result file, and
   compare the 120 pairs in acquisition order. Preserve the previous run under
   `arsip/` before replacing results.
4. Record mesh sizes, element counts split into ring/medium, `delta_layer`,
   current checks, and software versions. A smaller `delta_layer` alone is
   insufficient if geometry or physics changed without documentation.
5. Use Octave for the project runs and update this file and `PROGRESS.md` when
   adding or retiring scripts.
