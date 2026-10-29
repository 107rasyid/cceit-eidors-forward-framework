# Progress

## Active workflow

- Model A uses a lumped dielectric contact impedance on a Netgen CEM mesh.
- Model B resolves the dielectric layer explicitly with `cceit_mesh_B4`, using
  `mode='tank'` so the ring resolution is independent of the core resolution.
- `cceit_pairscan` performs voltage-driven scans over all unique electrode pairs.
- `run_sweepA`, `run_sweepA2`, and `run_sweepA3` remain the Model A studies.
- `run_AB_final.m` compares A with B4 at the coarse diagnostic and working ring
  mesh sizes. Its output is saved under `hasil_cceit/`.
- `run_B_final.m` runs and saves the coarse 1 mm B4 scan; `run_AB_final.m`
  reuses that result when its parameters match.
- `run_verify_models.m` checks A and working-resolution B conservation,
  floating currents, prescribed voltages, and reciprocity on 30 pairs; it saves
  the checks to `hasil_cceit/cceit_verification_results.mat`.
- `plot_results.m` reads the saved A2/A3 sweep results, labels changes as
  `Delta_p` / `Delta_shape`, marks the A2 baseline explicitly, and avoids
  connecting discrete parameter-sweep points. It also exports B4 mesh
  convergence and per-separation A/B comparison figures when matching result
  files are present. The field plot shows elementwise current-density magnitude,
  subtle mesh edges, and sparse equal-length arrows for the real current direction.
- `cceit_recon.m` is deferred; its optional B data path now points to B4.

## Current Model B decisions

- Working ring mesh target: `P.h_ring_B = 0.5e-3` m.
- Coarse diagnostic ring mesh: `P.h_ring_B_coarse = 1e-3` m.
- Preserve `P.h_int` for the interior/core mesh when refining the ring.
- Keep the prior B4 result MAT files in the project root; archive superseded
  source scripts without deleting result data.

## What works / what remains

- The active source set is separated from earlier B1/B2/B3 and exploratory
  scripts, which are preserved in `arsip/`.
- The new B4 wrapper and A/B runner have been added but have not yet been run in
  Octave in this task.
- The revised plotting script has not yet been run in Octave; regenerate and
  inspect all PNGs once before using them in the manuscript. New figures are
  `fig4d_layer_mesh.png` and `fig4e_AB_by_separation.png`.
- Next: run the Model A sweep scripts, `run_B_final.m`, `run_AB_final.m`, and
  `run_verify_models.m`. Inspect the verification checks, `delta_layer`, and
  the median A/B magnitude ratio.
- Treat the 0.5 mm Model B mesh as a practical working resolution, not a claim
  of fully mesh-converged truth. Keep any reported mesh error tied to the exact
  pair of resolutions used to estimate it.

## Octave quirks

- Octave rejected the asymmetric `errorbar` argument layout in
  `plot_results.m`. The pair summary now draws min–max ranges and medians with
  separate `plot` calls instead.
- Octave's Magick++ PNG writer failed to open the relative Fig. 3 output path.
  Plot exports now use absolute paths rooted at `plot_results.m`; Fig. 3 falls
  back to `hasil_cceit/` if the project-root target cannot be opened.

## Proposed extensions

- None added in this milestone.
