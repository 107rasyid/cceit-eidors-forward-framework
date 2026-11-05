# CC-EIT Sweep Notes

## Sweep Ranges

### run_sweepA (Frequency Sweep)
- **Mesh levels**: 3 levels (h_int: 4.0, 3.0, 2.5 mm; h_el: 2.0, 1.5, 1.0 mm)
- **Frequencies**: 13-14 points log-spaced from 10 kHz to 10 MHz, including 500 kHz
- **Outputs**: Delta_mesh (mesh convergence), median |I_t|, median phase
- **Note**: Mesh A3 built once, not dependent on frequency

### run_sweepA2 (Layer and Tissue Sweep)
- **Scaled parameters** (factor f_k = [0.25 0.5 1 2 4] × baseline):
  - d: [0.25, 0.5, 1, 2, 4] × 2 mm = [0.5, 1, 2, 4, 8] mm
  - epsr_d: [0.25, 0.5, 1, 2, 4] × 3 = [0.75, 1.5, 3, 6, 12]
  - sigma: [0.25, 0.5, 1, 2, 4] × 0.025 = [0.00625, 0.0125, 0.025, 0.05, 0.1] S/m
  - epsr: [0.25, 0.5, 1, 2, 4] × 80 = [20, 40, 80, 160, 320]
- **sigma_d** (absolute values): [0, 1e-8, 1e-7, 1e-6, 1e-5, 1e-4, 3e-4] S/m
- **Outputs per point**: parameter value, factor, Delta_p, ratio r, median |y|, median phase, phase diff, flag
- **Flag**: d values outside [1, 5] mm marked as "model A only (outside A-B validation range)"

### run_sweepA3 (Medium Sensitivity)
- **d grid**: [0.5, 1, 2, 4] mm
- **f grid**: [100 kHz, 500 kHz, 1 MHz, 3 MHz]
- **Factors for sigma and epsr**: [0.25, 0.5, 2, 4] (baseline on both sides)
- **sigma values**: [0.00625, 0.0125, 0.05, 0.1] S/m
- **epsr values**: [20, 40, 160, 320]
- **Outputs per (d,f) block**: Delta_p, ratio r, phase diff for sigma and epsr
- **Flag**: d values outside [1, 5] mm marked
- **Checkpoint**: Results saved after each (d,f) block, skips existing blocks on rerun

## Rationale for Same Factor Range

All scaled parameters (d, epsr_d, sigma, epsr) use the same factor range [0.25, 0.5, 1, 2, 4] to:
1. Enable direct comparison of sensitivity across different physical parameters
2. Provide consistent coverage from -75% to +300% variation
3. Maintain baseline at factor = 1 for reference
4. Facilitate unified plotting in log-log space

## Estimated Scan Counts

### run_sweepA
- Mesh builds: 3 (for delta_mesh study)
- Frequency solves: 13-14 (mesh reused)
- **Total solves: ~16-17**

### run_sweepA2
- Mesh build: 1 (A3 built once)
- Parameter solves: 5 (d) + 5 (epsr_d) + 5 (sigma) + 5 (epsr) + 7 (sigma_d) = 27
- Degeneracy check: 1
- **Total solves: ~28**

### run_sweepA3
- Mesh build: 1 (A3 built once)
- (d,f) combinations: 4 × 4 = 16
- For each (d,f): 4 (sigma) + 4 (epsr) = 8 solves
- **Total solves: 16 × 8 = 128**

## Data Outputs

All sweeps save:
- Delta_p = norm(y(p)-y(p0))/norm(y(p0))
- Ratio r = median(|I_t|(p)) / median(|I_t|(p0))
- Phase diff = median phase(p) - median phase(p0) (degrees)
- Raw values: median |y|, median phase
- Flags for parameters outside validation range

Plots:
- run_sweepA: Two panels (log-log magnitude, semilogx phase)
- run_sweepA2: Two plots (scaled parameters, tissue parameters with (r-1)%)
- run_sweepA3: Two panels (sigma vs f, epsr vs f, showing (r-1)%)
