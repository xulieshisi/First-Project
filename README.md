# MATLAB code for Figures 2–6

This package contains the MATLAB entry points, helper functions, optional Figure 2/3 caches, and the data needed to reproduce Figures 2–6. It runs from the package folder; the original working directory is not required.

## Requirements and first run

MATLAB R2022b or newer is recommended. Standard MATLAB graphics, MAT-file, and HDF5 support are required. Run from this directory:

```matlab
run_all_figures
```

The default command reuses the Figure 2/3 caches and skips Figures 4–6. To recompute a figure instead of reading its cache, use `f2('Recompute',true)` or `f3('Recompute',true)`; full recomputation is memory-intensive. The caches are convenience files and may be deleted before a fresh run.

The required model and RTM files are grouped directly in `data/`. The current Figure 6 scripts are `f6_1.m` and `f6_2.m`; they use the included Herten RTM volumes and select the requested horizontal traces. The combined command may use substantial memory because Figure 5 loads nine 3-D volumes:

```matlab
run_all_figures('RunLargeFigures',true)
```

Each figure can also be run directly from the package root:

```matlab
addpath('code')
f2
f3
f4
f5
f6
```

The Figure 2/3 entries use their verified caches by default. Use `f2('Recompute',true)` or `f3('Recompute',true)` only when a fresh numerical calculation is required.

## File roles

| File | Role |
|---|---|
| `run_all_figures.m` | Low-memory master entry point; optionally enables Figures 4–6. |
| `code/f2.m` | Main entry point for Figure 2. |
| `code/f3.m` | Main entry point for Figure 3. |
| `code/f4.m` | Main entry point for Figure 4. |
| `code/f5.m` | Main entry point for the compact Figure 5; displays the final 3-by-3 layout and saves `outputs/f5/f5.*`. |
| `code/f6.m` | Main entry point for the current Figure 6 panels. |
| `code/figure2_200MHz.m` | Figure 2, 200 MHz wavefield comparison; cache reuse or explicit recomputation. |
| `code/figure3_300MHz.m` | Figure 3, 300 MHz wavefield comparison; cache reuse or explicit recomputation. |
| `code/plot_2d_wavefield_fdtd_vs_adaptive.m` | Core 2-D FDTD, fixed LSDTD, adaptive LSDTD, reference, NRMSE, and export workflow. |
| `code/gpr_adaptive_lsdtd_coefficients.m` | Frequency- and permittivity-dependent least-squares stencil coefficients. |
| `code/gpr_uniform_permittivity_model_epsr20.m` | Uniform relative-permittivity model used by Figures 2/3. |
| `code/figure4_saved.m` | Figure 4 entry point. |
| `code/plot_figure5_matlab_white.m` | 3-D permittivity model and forward-field surfaces used for Figure 4. |
| `code/figure5_saved.m` | Backward-compatible Figure 5 alias. |
| `code/plot_figure5_compact_rtm_3x3.m` | Figure 5 export wrapper for the 3-by-3 RTM comparison. |
| `code/reproduce_clipboard_figure_matlab.m` | Final compact Figure 5 layout, lighting adjustment, display, and native MATLAB export stage. |
| `code/reproduce_attached_figure_matlab.m` | Figure 5 reconstruction setup and compact layout adjustment. |
| `code/attached_figure_original_source.m` | Loads the nine RTM volumes and constructs the 3-D panels. |
| `code/rtm_section_3d_6polar_no.m` | 3-D section/surface renderer used by Figure 5. |
| `code/figure6_latest.m` | Checks the grouped data directory and calls the two current trace scripts. |
| `code/f6_1.m` | Current Figure 6 panel at X=14 m, Y=7.5 m. |
| `code/f6_2.m` | Current Figure 6 panel at X=14 m, Y=5 m. |

The unrelated coefficient demonstration files and project simulation scripts are omitted because they are not called by Figures 2–6.

## Outputs and memory

The package has four working directories: `code/`, `data/`, `cache/`, and `outputs/`. Figure outputs are written under `outputs/f2/` through `outputs/f6_2/`; each folder keeps only PDF, EMF, and editable MATLAB FIG files. `data/` contains the model, GPR acquisition, RTM volumes, and `manifest.csv`; no data subfolders are required. `cache/` contains optional reusable Figure 2/3 numerical results. Figure 6 computes only its requested Y trace to keep memory use low. Run Figures 4–6 one at a time on a memory-limited machine.

## Reproducibility and availability

`data/manifest.csv` records required filenames and SHA-256 checksums. Before public release, archive the large data at a DOI-bearing repository, replace the repository DOI in the manuscript, and record the MATLAB release and operating system. Cite the software and data records separately, and include licenses for third-party data or routines.

Suggested statement:

> MATLAB code for Figures 2–6 and execution instructions are available at [software repository DOI]. The large model and RTM volumes required by Figures 4–6 are archived at [data repository DOI]. The software is released under the accompanying MIT License; data use is subject to the license stated in the data record.

The journal's current author guide and Elsevier research-data policy should be checked immediately before submission because requirements and links can change.

## GitHub and large files

Several included data files are larger than GitHub's 100 MB per-file limit. Use Git LFS for `data/*.mat` and `data/*.h5`, or place the same `data/` directory in a DOI-bearing data repository and keep only the code and `data/manifest.csv` in the GitHub repository. Do not change filenames after publishing: the manifest records the SHA-256 values used by the scripts.
