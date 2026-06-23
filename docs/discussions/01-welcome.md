<!-- category: Announcements -->
# 👋 Welcome to tq-threads

**tq-threads** is a clean-room, MIT-licensed OpenSCAD library for **printable
screw threads** — ISO metric and Unified (imperial) — plus the everyday hardware
built from them: bolts, nuts, washers, tapped/clearance/countersunk holes,
standoffs, couplers, countersunk and wood screws, and bottle/cap threads.
The v0.6.0 release also adds flexible printable profile controls: square,
rectangular, narrow-tooth, groove, `side_angle`, `thread_size`, `lead_ends`, and
rate-based taper input.

### What makes it different
- **Manifold by construction.** Each thread is a single watertight `polyhedron`
  (a helical height-field), so models stay 2-manifold and export straight to STL
  with no repair step.
- **Printable-first.** Fit `clearance`, internal-oversize/external-undersize
  compensation, lead-in chamfers, rounded roots, and real `$fn/$fa/$fs`
  resolution are all parameters.
- **Flexible profiles.** Keep the default ISO/UN basic profile, or choose
  full-sharp V, square, rectangular, narrow-tooth, or helical groove forms.
- **Clean-room + MIT.** Built only from public standards (ISO 68-1/261/262/273/
  4032/4762/7089/10642, ASME B1.1). MIT is GPL-2.0-compatible, so it drops into
  GPL projects unchanged.

### Get started
```openscad
include <tq_threads.scad>;
tq_thread_preset("M8", 20);                       // M8 rod
difference() { part(); tq_threaded_hole(6,1.0,12); } // tapped hole
tq_bolt(8,1.25,20, head="socket", shank=4);       // cap screw
tq_thread(12,4,20, profile="square", thread_size=1.5);
```
See the [README](../../README.md) for install options and the
[MANUAL](../../MANUAL.md) for the full reference.

### Tell us
- What are you building with it?
- Which presets/helpers would make your workflow easier?

Welcome aboard — and happy printing. 🧵🖨️
