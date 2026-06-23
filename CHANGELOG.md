<!-- SPDX-License-Identifier: MIT -->
# Changelog

All notable changes to tq-threads. Format loosely follows
[Keep a Changelog](https://keepachangelog.com); versions are git tags.

## [0.6.0] - 2026-06-23

Flexible non-60-degree profile-control release.

### Added
- `profile="square"` and `profile="rectangle"` thread forms.
- `thread_size=` to decouple one tooth's axial width from pitch, enabling
  wide-pitch/narrow-tooth threads and grooves.
- `rect_ratio=` for rectangular threads; `1` is square, `1/3` is shallow.
- `groove=true` to make a helical channel cut into the cylinder surface as a
  direct manifold height-field solid.
- `side_angle=` for the half-angle measured from the plane perpendicular to the
  axis. `side_angle=30` is the conventional 60-degree included V. Existing
  `angle=60` remains the backward-compatible included-angle parameter.
- `lead_ends="none"|"start"|"end"|"both"` as a clearer lead chamfer selector,
  while retaining `lead_in` / `lead_out`.
- `taper_rate=` plus `tq_npt_taper_rate()` (`1/16` diameter change per length)
  for rate-based taper input.

### Changed
- The render proof now covers the new square, rectangular, groove, narrow-tooth,
  six-start, lead-end, taper-rate, preset-wrapper, and TPI-wrapper cases.
- `profile="sharp"` is now the documented full-height pointed V form. The
  default flat ISO/UN profile remains unchanged for existing calls.
- `tq_thread_preset()` and `tq_thread_tpi()` now forward the full v0.6 profile
  controls (`thread_size`, `side_angle`, `rect_ratio`, `groove`, `taper_rate`,
  `lead_ends`, and related overrides).
- The official render proof now captures combined stdout/stderr from OpenSCAD,
  enforces strict explicit `-OpenSCAD` paths, runs independent STL mesh checks
  for every positive render, and is the CI proof used on push.

### Fixed
- `thread_size > pitch` is rejected consistently for square and rectangular
  profiles before internal-thread relief or clamping is applied.
- `tq_wood_screw()` now supplies an explicit printable tooth depth for its
  coarse sharp-profile default, so the stricter full-sharp-V semantics do not
  make the default/example non-renderable.

### Documentation
- Rebuilt the user manual as a full professional reference with architecture,
  mental model, API usage, profile controls, print tuning, integration patterns,
  proof workflow, and troubleshooting.
- Added a dedicated manual architecture SVG and fixed landing-page inline-code
  wrapping in feature cards.

## [0.5.0] - 2026-06-23

Printability proof release for TinkerQuarry, plus two targeted geometry fixes.

### Fixed
- `profile="rounded"` no longer overshoots the requested major diameter at the
  crest; the crest arc apex now lands at `Rmaj`.
- `tq_wood_screw` no longer clips the helical thread with a cone boolean. The
  threaded body now stops before the point and unions to a solid lead-point cone,
  which avoids the previous non-manifold edge cases.
- Negative/assert tests now write BOM-free temporary `.scad` files and require an
  actual OpenSCAD `assert` in stderr before counting a rejection as a pass.

### Added
- `scripts/check_stl_mesh.py`, an independent STL edge-pairing and bounds checker
  used for the v0.5 targeted proof.

### Documentation
- Clarified that `fit=` models nominal ISO 965 position allowance only. For M8
  `6g`, the diametral shift is about 0.029 mm, which is below typical FDM
  clearance and layer-height effects; use `clearance` as the real print-fit lever.

## [0.4.0] — 2026-06-22

Stronger standards fidelity + honesty, robust Windows workflow, expanded proof.

### Added
- **ISO 965-1 fit classes** — optional `fit=` on `tq_thread` applies the
  fundamental deviation (tolerance *position*/allowance) from the exact ISO 965-1
  §13.1 formulae (external e/f/g/h, internal G/H), separate from the FDM
  `clearance`. Verified: 6g M8 → Ø7.971, 6h → Ø8.000.
- **Precision overrides** — `minor_d` (set core diameter / thread depth), in
  addition to v0.3's `angle`, `tooth_height`, `crest_flat`, `root_flat`, `taper`.
- **Preset table expansion to 101** (from 43): full ISO 261 fine-pitch series and
  the complete Unified numbered (#0–#12) + fractional (¼–1″) UNC/UNF sets, plus
  `tq_preset_count()` and `tq_presets_selfcheck()` introspection/test functions.
- **Robust example/test selection** — zero-`-D` wrapper `.scad` files in
  `examples/`, plus a shell-safe numeric `-D PART=n` selector. The fragile
  `-D SHOW="..."` string is now a documented fallback only.
- **`tq_threads_selftest.scad`** — parse/render-time assertions (preset table,
  count floor, ISO 965 formulae).
- **`scripts/render_proof.ps1`** — PASS/FAIL summary, OpenSCAD version + timings,
  13 negative/assert tests, exits nonzero on failure (PS 5.1 + pwsh compatible).
- **`PROVENANCE.md`** and a fidelity-classification table in `REFERENCES.md`
  (EXACT / DERIVED / FDM / APPROX) for every table and formula.
- **`ACCEPTANCE-REPORT-v0.4.0.md`**.

### Changed
- **`tq_wood_screw`** gained `taper`, `core_d`, `thread_depth`, `point`
  (`gimlet`|`cone`|`flat`, accepts the old bool), and `shank`; still explicitly a
  generic printable wood-screw-LIKE form (no standard claimed).
- **`tq_bottle_thread`** gained `angle`, `tooth_height`, `profile`, and `lead_in`
  (with `starts`/`internal` from before); still explicitly generic (not SPI/GPI).
- `scripts/render-tests.ps1` is now a deprecation shim → `render_proof.ps1`.
- Docs distinguish **printable/FDM defaults** vs **nominal standards** vs
  **tolerance/fit** throughout; metrology limits stated plainly.

### Compatibility
- All v0.2/v0.3 public APIs and `include <tq_threads.scad>;` usage preserved;
  `tq_wood_screw(..., point=true/false)` still works; default `angle=60` keeps
  v0.2/v0.3 geometry bit-for-bit.

## [0.3.0] — 2026-06-22

Stronger-than-baseline release: adds the remaining helper categories users
expect from a general thread library, plus more profile control — all clean-room.

### Added
- **Custom flank angle** `angle=60` on `tq_thread` (e.g. 55° Whitworth-ish, 45°);
  thread height is derived from the angle (or set explicitly, below).
- **Explicit `tooth_height`** override on `tq_thread` (sets the radial flight
  depth directly instead of deriving it from the flats/angle).
- **Tapered threads** `taper=` on `tq_thread` (total diameter reduction over the
  length — NPT-ish tapers, auger tips, etc.).
- **`tq_auger` / `tq_auger_hole`** — deep coarse helical flight + matching
  negative (screw conveyor / drill / feed-screw style; generic, not a standard).
- **Phillips (cross) drive**: `tq_phillips_drive` (cruciform cutter/tip),
  `tq_phillips_tip` (driver bit), and `drive="phillips"` on `tq_bolt` /
  `tq_countersunk_bolt`; helpers `tq_ph_dims`, `tq_ph_size_for`.
- **Child-difference convenience wrappers** (ScrewHole/ClearanceHole in spirit,
  `tq_*` naming): `tq_tap`, `tq_drill`, `tq_counterbore`, `tq_countersink`.
- **`tq_relief_groove`** — thread-relief / runout groove cutter.

### Changed
- `tq_bolt` / `tq_countersunk_bolt` `drive` now selects `hex` | `phillips` |
  `none` via a shared `_tq_drive_recess` selector (was hex-only).
- The minor-radius safety assert now also accounts for `taper` (top of a tapered
  thread) in addition to the rounded-root depth.
- `_TQ_H` is no longer used for the flank-height calc (generalized to `angle`);
  default `angle=60` is bit-for-bit backward compatible with v0.2.
- Examples, fast/heavy test grids, README, MANUAL, and REFERENCES updated for
  every new helper.

## [0.2.0] — 2026-06-22

Feature-parity release: brings tq-threads to practical parity with common
OpenSCAD thread libraries while preserving clean-room provenance and MIT.

### Added
- **Presets M2–M64** metric coarse (ISO 261/262), common metric fine
  (`M8x1`, `M10x1.25`, `M12x1.5`, …), data-driven via `TQ_PRESETS` + `tq_preset`.
- **Hardware helpers**: `tq_countersunk_bolt`, `tq_wood_screw`, `tq_washer`,
  `tq_clearance_hole`, `tq_recessed_clearance_hole`,
  `tq_countersunk_clearance_hole`, `tq_rod_start`, `tq_rod_end`,
  `tq_rod_coupler`, `tq_hex`, `tq_hex_drive`.
- **Dimension-table functions**: `tq_clearance_dia` (ISO 273),
  `tq_washer_dims` (ISO 7089), `tq_nut_thickness` / `tq_nut_across_flats`
  (ISO 4032), `tq_shcs_head` / `tq_hex_key_af` (ISO 4762),
  `tq_csk_head_dia` (ISO 10642), `tq_hex_across_flats/corners`.
- **Real `$fs` support** in segment calculation (full `$fn`/`$fa`/`$fs` rule,
  with a `TQ_MIN_SEG` flank-quality floor).
- **Comprehensive input validation** (`assert`) across `tq_thread` and helpers:
  positive d/pitch/length/steps, valid arc/hand/profile/starts, sane
  clearance/chamfer, shank `< length`.
- Split test suites: `tq_threads_fast_tests.scad` (CI/headless, with preset
  assertions) and `tq_threads_heavy_tests.scad` (visual demo);
  `tq_threads_tests.scad` is now a compatibility wrapper → fast suite.
- `scripts/render-tests.ps1` headless render-proof; GitHub Actions CI.
- Full docs: landing-page `README.md`, `MANUAL.md`, architecture diagram,
  discussion seeds.

### Changed
- **Bolt solidity**: head/shank/thread now overlap by `TQ_EPS` and the thread's
  head-end is square, so bolts export as one coherent printable solid.
- `tq_bolt` socket drive recess is now in the bearing face; head/AF defaults come
  from the ISO tables.
- Examples are selectable without editing the file (`-D SHOW="bolt"` or a wrapper
  assignment); default is `"all"` only when `SHOW` is undefined.
- `tq_nut` defaults to ISO 4032 thickness/across-flats.

## [0.1.0] — 2026-06-22

Initial clean-room release.

### Added
- Core `tq_thread` (height-field polyhedron), `flat`/`sharp`/`rounded` profiles,
  multi-start, left/right hand, partial arc, lead-in/out chamfers, clearance.
- `tq_thread_preset` (M2–M12 + UNC/UNF), `tq_thread_tpi`, `tq_in`.
- `tq_threaded_rod`, `tq_thread_cutter`, `tq_threaded_hole`, `tq_nut`,
  `tq_standoff`, `tq_bolt`, `tq_bottle_thread`, `tq_thread_debug`.
- README, LICENSE (MIT), REFERENCES, examples, tests.
