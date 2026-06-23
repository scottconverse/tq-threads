<!-- category: General -->
# Integrating with BOSL2 & migrating from threads.scad

A place to share integration recipes and migration tips. Starter notes below —
please add yours.

## Coexisting with other libraries
Every public symbol is namespaced `tq_*`, so tq-threads coexists with BOSL2,
NopSCADlib, and friends without clashes. Use the other library for shapes,
attachments, and rounding; use tq-threads for the actual printable threads.

```openscad
include <BOSL2/std.scad>
include <tq_threads.scad>
difference() {
    cuboid([20,20,12], rounding=2);   // BOSL2 shape
    tq_threaded_hole(6, 1.0, 12);     // tq-threads tapped hole
}
```

## Migrating from Dan Kirshner / rcolyer `threads.scad`
tq-threads is a clean-room **feature** equivalent (different code + API):

| threads.scad-style | tq-threads |
|---|---|
| `metric_thread(d,p,l)` | `tq_thread(d=d, pitch=p, length=l)` |
| `english_thread(in,tpi,l)` | `tq_thread_tpi(d=tq_in(in), tpi=tpi, length=tq_in(l))` |
| `...internal=true` | `tq_thread(...,internal=true)` / `tq_thread_cutter(...)` |
| `ScrewHole(...)` | `difference(){ part(); tq_threaded_hole(d,pitch,len); }` |
| `RodStart/RodEnd` | `tq_rod_start / tq_rod_end` |
| `n_starts` | `starts=` · left-hand → `hand="left"` |

Full table + parameters in the [MANUAL](../../MANUAL.md#migration).

## v0.6 profile-control notes
The compatibility default is still `profile="flat"` with the ISO/UN basic
truncations. New controls are optional and forward through `tq_thread_preset()`
and `tq_thread_tpi()`:

```openscad
tq_thread_preset("M8", 20, profile="square", thread_size=1);
tq_thread_tpi(d=0.5*25.4, tpi=8, length=20, profile="rectangle", rect_ratio=1/3);
tq_thread(14, 4, 20, profile="square", groove=true, lead_ends="both");
```

`side_angle=30` is a 60-degree included V using the half-angle-from-perpendicular
convention. Square, rectangular, and groove profiles are generic printable
forms, not standards-certified ACME/trapezoidal/buttress replacements.

## TinkerQuarry
MIT → GPL-2.0 compatible; vendor `tq_threads.scad` into the engine's `library/`
and call presets by name from generated `.scad`.

**Share your setup:** which libraries do you pair tq-threads with, and what
migration gotchas did you hit?
