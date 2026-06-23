<!-- SPDX-License-Identifier: MIT -->
# PROVENANCE — clean-room source ledger

This file records, per data source, exactly **what** tq-threads uses, **where**
it comes from, and **how faithful** it is. It complements the fidelity table in
[REFERENCES.md §0](REFERENCES.md) and the clean-room statement there.

**Clean-room rule (unchanged):** no third-party OpenSCAD thread library
(Dan Kirshner `threads.scad`, rcolyer `thread_profile`/`threadlib`, BOSL2,
MCAD, …) was opened, read, line-diffed, translated, or used as a template for
code, comments, lookup tables, tests, or API text. Only public standards and
first-principles math were used. License: **MIT** (GPL-2.0 compatible).

Fidelity classes: **EXACT** (nominal standard value used verbatim) ·
**DERIVED** (exact formula from the standard's definition) ·
**FDM** (printability default chosen here) · **APPROX** (approximation/fallback).

| Source / spec | Used for | Class | Faithfulness & notes |
|---|---|---|---|
| **ISO 68-1** (metric basic profile) | 60° form, `H=(√3/2)P`, crest `P/8`, root `P/4`, engaged `0.5413P` | EXACT/DERIVED | Geometry transcribed/derived from the basic-profile definition. |
| **First-principles thread geometry** | `side_angle`, `thread_size`, square/rectangular profiles, groove inversion | DERIVED/APPROX | Generic printable forms implemented from the behavioral spec and trig; no standards fit class claimed. |
| **ISO 261** (general plan) | metric coarse + fine major Ø & pitch (presets) | EXACT | Nominal diameter/pitch series. Verified by `tq_presets_selfcheck()` + cross-checked online. |
| **ISO 262** (selected sizes) | preferred metric subset | EXACT | Informs which presets are "common". |
| **ISO 965-1 §13.1** (tolerances) | `fit=` fundamental deviation (allowance) | DERIVED (exact formula) | external e/f/g/h, internal G/H. **Position only**, not the grade/band. Formula value (unrounded); ISO tables round to whole µm. NOT metrology-grade. |
| **ASME B1.1** (Unified) | UNC/UNF numbered+fractional major & TPI (presets) | EXACT | `major=0.060+0.013·N` in (numbered); `pitch=25.4/TPI`. Cross-checked online. |
| **ISO 273** (clearance holes) | `tq_clearance_dia` (close/medium/free) | EXACT (listed) / APPROX (fallback) | Listed sizes nominal; unlisted sizes use a documented ratio fallback. |
| **ISO 7089** (plain washer A) | `tq_washer_dims` | EXACT (listed) / APPROX (fallback) | |
| **ISO 4032** (hex nuts) | `tq_nut_thickness`, `tq_nut_across_flats` | EXACT (listed) / APPROX (fallback) | Also reused for hex bolt heads. |
| **ISO 4762** (socket head cap screws) | `tq_shcs_head` (dk,k), `tq_hex_key_af` | EXACT (listed) / APPROX (fallback) | |
| **ISO 10642** (csk socket head) | `tq_csk_head_dia` (90°) | EXACT (listed) / APPROX (fallback) | |
| **ISO 4757** (cross recesses) | Phillips recess *concept* | APPROX | Printable cruciform approximation; NOT gauge-accurate. |
| **ASME B1.20.1** (NPT) | taper-rate context only | DERIVED | `tq_npt_taper_rate()` returns the published 1:16 diameter taper reference. NPT's truncated profile is NOT implemented. |
| *(none — generic)* | `tq_auger`, `tq_bottle_thread`, `tq_wood_screw` | APPROX/GENERIC | Printable generic forms; **no** standard claimed (explicitly documented). |
| *(this library)* | `clearance` default 0.4 mm (½/½ split), `TQ_MIN_SEG`, lead-in chamfers, rounded fillets `H/6`,`H/12` | FDM/DERIVED | Printability choices / derived geometry, not standards. |

## v0.6 profile-control provenance

The v0.6 profile controls came from the local capability specification dated
2026-06-23 and first-principles geometry, not from any third-party OpenSCAD
library.

- `side_angle` uses the right-triangle relation `h = S/(2*tan(beta))`, where
  `S` is the axial tooth width and `beta` is the flank angle from the plane
  perpendicular to the axis. `beta=30` gives the familiar 60-degree included V.
- `thread_size` is a caller-selected axial tooth width and is validated before
  internal-thread relief or square/rectangular clamping. Values greater than
  pitch are rejected.
- `profile="sharp"` is a full-height V. The compatibility default remains the
  flat ISO/UN basic form with crest/root truncation.
- Square, rectangular, and groove profiles are generic printable height-field
  shapes. They do not claim ACME, trapezoidal, buttress, or pipe-thread gauge
  compatibility.
- `taper_rate` is just diameter change per unit length. The NPT helper returns
  the public 1:16 taper-rate reference only; it does not implement the NPT
  truncated profile or sealing/gauge requirements.

## What could only be validated with physical prints + calipers
- Real-world **fit** of a printed bolt/nut pair at a given `clearance`/`fit`.
- Whether a printed thread meets an actual **ISO/ASME tolerance class** (tq-threads
  models a single nominal surface, so it cannot certify a class).
- **SPI/GPI** closure interchange with a real cap/bottle.
- Pull-out / torque strength of `tq_wood_screw` / heat-set alternatives.

Validation path: print the calibration set in [README → FDM fit guide](README.md),
measure major/minor/pitch diameters with calipers/thread gauges, and adjust
`clearance` (and optionally `fit`) per material/printer. For certified parts, use
machined hardware or a metrology-grade CAM toolchain — not an FDM print.

Practical note: ISO 965 position allowance is tiny at FDM scale. M8 `6g` is about
0.029 mm diametral shift, below typical tuned clearance and layer-line effects,
so `fit=` records nominal intent; `clearance` is the real print-fit control.
