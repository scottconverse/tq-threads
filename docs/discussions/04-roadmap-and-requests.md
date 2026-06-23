<!-- category: Ideas -->
# 🗺️ Roadmap & feature requests

What should tq-threads do next? Vote with 👍 and add your own.

## On the table
- **Standards-accurate ACME / trapezoidal / buttress** lead-screw profiles.
- **True ISO internal profile** option (vs. the current external-form cutter).
- **Full NPT / tapered pipe** threads (v0.6 only provides the 1:16 taper-rate
  reference, not the pipe-thread profile or sealing/gauge behavior).
- **More named hardware presets** (DIN/ISO bolt & nut length series, helicoil sizes).
- **Thread-relief groove** helper (undercut at the thread runout).
- **Knurling** helper for knobs/caps.
- A **parts catalog** example gallery rendered to PNG in CI.

## Out of scope (for now)
- Cosmetic/vitamin part libraries — pair with NopSCADlib instead.
- A GUI configurator.

## Already in v0.6.0
- Generic printable square and rectangular profiles.
- Narrow-tooth threads via `thread_size`.
- Helical grooves via `groove=true`.
- `side_angle`, `lead_ends`, and `taper_rate=tq_npt_taper_rate()`.

## Ground rules for contributions
tq-threads is **clean-room** and **MIT**. New geometry must come from public
standards + first-principles math, never from another thread library. See
[CONTRIBUTING.md](../../CONTRIBUTING.md).

**Drop your request below** — include the use case (what are you trying to print?)
so we can prioritize by real need.
