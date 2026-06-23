// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------
// tq_threads_selftest.scad  --  STANDARD-TABLE self-test (parse/render time).
//
// Pure assertions (no heavy geometry): verifies the preset table integrity,
// preset-count floor, spot-check nominal values, and the ISO 965 fundamental-
// deviation formulae.  Renders only a trivial cube so `openscad -o out.stl`
// exits 0 on success and NONZERO on any failed assertion.
//
//   openscad -o selftest.stl tq_threads_selftest.scad
// ----------------------------------------------------------------------------

include <tq_threads.scad>

// -- preset table integrity --------------------------------------------------
assert(tq_presets_selfcheck(),
       "SELFTEST: preset table self-check failed (a row is malformed or unresolvable)");
assert(tq_preset_count() >= 101,
       str("SELFTEST: preset count regressed below 101 (v0.4 baseline): ", tq_preset_count()));

// -- spot-check nominal preset values (exact) --------------------------------
assert(tq_preset("M3")  == [3.0, 0.50],  "SELFTEST: M3 nominal");
assert(tq_preset("M8")  == [8.0, 1.25],  "SELFTEST: M8 nominal");
assert(tq_preset("M12") == [12.0, 1.75], "SELFTEST: M12 nominal");
assert(tq_preset("M10x1.25") == [10.0, 1.25], "SELFTEST: M10x1.25 fine");
assert(abs(tq_preset("1/4-20")[0] - 6.35) < 1e-9,       "SELFTEST: 1/4-20 major");
assert(abs(tq_preset("1/4-20")[1] - 25.4/20) < 1e-12,   "SELFTEST: 1/4-20 pitch");
assert(abs(tq_preset("#6-32")[0]  - 0.138*25.4) < 1e-9, "SELFTEST: #6-32 major");
assert(abs(tq_preset("#10-32")[1] - 25.4/32) < 1e-12,   "SELFTEST: #10-32 pitch");
assert(is_undef(tq_preset("NoSuchPreset")),             "SELFTEST: unknown -> undef");

// -- ISO 965-1 fundamental deviation formulae (exact, micrometres) -----------
assert(abs(_tq_fit_dev_mm("g", 1.25)*1000 - (-(15 + 11*1.25))) < 1e-9, "SELFTEST: es(g)");
assert(abs(_tq_fit_dev_mm("f", 1.0 )*1000 - (-(30 + 11*1.0 ))) < 1e-9, "SELFTEST: es(f)");
assert(abs(_tq_fit_dev_mm("e", 1.0 )*1000 - (-(50 + 11*1.0 ))) < 1e-9, "SELFTEST: es(e)");
assert(_tq_fit_dev_mm("h", 1.0) == 0,                                  "SELFTEST: es(h)=0");
assert(abs(_tq_fit_dev_mm("G", 1.5)*1000 - ( 15 + 11*1.5)) < 1e-9,     "SELFTEST: EI(G)");
assert(_tq_fit_dev_mm("H", 1.0) == 0,                                  "SELFTEST: EI(H)=0");

// -- v0.6 profile-control geometry -----------------------------------------
P2 = 2;
S1 = 1;
assert(abs(_tq_profile_height(P2, P2, 0, 0, "sharp", false, 1, 30) - _TQ_H * P2) < 1e-6,
       "SELFTEST: sharp profile is a full 60-degree V by default");
assert(abs(_tq_profile_height(4, S1, 0, 0, "sharp", false, 1, 30) - (_TQ_H * S1)) < 1e-6,
       "SELFTEST: side_angle=30 maps thread_size to a 60-degree V");
assert(abs(_tq_profile_height(4, 3, 0, 0, "rectangle", true, 1/3, 30) - 1) < 1e-9,
       "SELFTEST: rectangle rect_ratio controls depth");
assert(abs(tq_npt_taper_rate() - 1/16) < 1e-12,
       "SELFTEST: NPT reference taper rate");
rect_tbl = _tq_table_rect(4, 2, 4, 5);
groove_tbl = _tq_table_groove(rect_tbl, 4, 5);
assert(abs(lookup(2, rect_tbl) - 5) < 1e-9 && abs(lookup(2, groove_tbl) - 4) < 1e-9,
       "SELFTEST: groove profile inverts the tooth into the base cylinder");
assert(_tq_lead_start("start", false) && !_tq_lead_end("start", true),
       "SELFTEST: lead_ends=start selects only the start");
assert(!_tq_lead_start("end", true) && _tq_lead_end("end", false),
       "SELFTEST: lead_ends=end selects only the end");
assert(_tq_lead_start("both", false) && _tq_lead_end("both", false),
       "SELFTEST: lead_ends=both selects both ends");
assert(!_tq_lead_start("none", true) && !_tq_lead_end("none", true),
       "SELFTEST: lead_ends=none disables both ends");

echo(str("SELFTEST PASS: ", tq_preset_count(), " presets, table + ISO 965 + profile-control formulae OK"));
cube(0.1);   // trivial geometry so STL export succeeds
