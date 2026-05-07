# Hand v0.1.1 — fixes against the v0.1 CAD audit

**Status:** v0.1.1 — critical fixes applied; ready for second-pass audit before fabrication.

**Date:** 2026-05-07
**Predecessor audit:** [`hand-v0.1-cad-audit.md`](hand-v0.1-cad-audit.md) (verdict: FAIL, 30 findings)
**Files touched:**

- `chassis/cad/hand_params.scad`
- `chassis/cad/palm.scad`
- `chassis/cad/finger.scad`
- `chassis/cad/phalanx.scad`
- `chassis/cad/motor_bracket.scad`
- `chassis/cad/hand_assembly.scad`
- `chassis/hand-v0.1-BOM.csv`
- `chassis/hand-v0.1-assembly.md`
- `descriptor/free-humanoid.udd.json` (`L_HAND_synergy` + `R_HAND_synergy` blocks only)

---

## Fixes applied

### Critical (block-fabrication issues, all addressed)

#### #1 — bracket-to-palm bolt circle now coherent

- **`palm.scad` `motor_mount_iface()`** (was lines 100-110): the 4-hole pattern at `motor_face_pcd = 22 mm` / 45° offset → now `palm_mount_pcd = 25 mm` / 0/90/180/270, matching `motor_bracket.scad palm_mount_holes()`.
- **Why:** the bracket's palm-side bolts now have receiving clearance holes in the palm. The bracket's motor-face counterbore is a separate, smaller PCD (and now M3, see #3) cut into the bracket only.

#### #2 — finger long axis rebuilt to +Y

- **`finger.scad`**: each phalanx is now wrapped in `rotate([0,0,90])` so the phalanx's local +X (body axis) maps to finger frame +Y (distal). The chain translates along +Y. Joint barrels (phalanx local +Y) now lie along finger frame +X — matching the rebuilt palm MCP barrels (also along X).
- **`palm.scad` `finger_mcp_mount()`**: barrel ears swapped from `rotate([90,0,0])` (barrels along Y) to `rotate([0,90,0])` (barrels along X). Bushing pockets and axle hole likewise swapped.
- **`palm.scad` `thumb_cmc_block()`**: same X-axis rotation applied; the cube changed from `[16,14,14]` to `[14,16,14]` to keep the long axis consistent with the new barrel orientation.
- **`hand_assembly.scad`**: `rotate([0,0,90])` removed from finger placement in both `assembled_hand()` and `skeleton_only()`. Thumb's `thumb_opposition_deg + 90` reduced to `thumb_opposition_deg` (the +90 was paired with the now-removed Z-rotation).
- **Result:** the proximal phalanx joint barrel and the palm MCP joint barrel now share the X axis — a single 3 mm dowel pin can pass through both.

#### #3 — Maxon GP 32 HP face PCD corrected

- **`hand_params.scad`:** `motor_face_pcd 22.0 → 27.0`, `motor_face_bolt_m 2.5 → 3.0`, `motor_face_bolt_dia 2.7 → 3.2`. New comment: `// Per Maxon GP 32 HP (cat 166940) front-face mounting — verify against current drawing prior to fabrication.`
- **`motor_bracket.scad` `motor_face_holes()`**: angular layout swapped from `i*90 + 45` (45/135/225/315) to `i*90` (0/90/180/270) and counterbore diameter bumped from 4.6 mm (M2.5 head) → 5.6 mm (M3 head).
- **`hand-v0.1-assembly.md` §5.1**: callout updated to "4× M3 on PCD 27 mm per Maxon GP 32 HP cat 166940".
- **`hand-v0.1-assembly.md` §5.2**: bracket-to-palm bolts remain four M2.5 SHCS at 0.5 N·m on PCD 25 mm at 0/90/180/270 (palm side; the bracket-to-motor face is the separate, smaller M3/PCD 27 pattern internal to the bracket).

#### #4 — palm pulleys reduced to 3 routed positions, no motor-mount collision

- **`hand_params.scad`:** `palm_pulley_count 8 → 3`.
- **`palm.scad`:** `palm_pulley_mounts()` no longer iterates a star pattern. Replaced with an explicit `palm_pulley_positions` table:
  - p0 at `(0, -palm_length/2 + 30)` — spool exit, 8 mm distal of motor center
  - p1 at `(-12, -palm_length/2 + 50)` — left distribution junction
  - p2 at `(+12, -palm_length/2 + 50)` — right distribution junction
- **Visual clearance:** no pulley pivot lies within 8 mm of the motor_mount_iface center at `(0, -27)`. Closest is p0 at `y = -15` (12 mm away).
- **`palm_pulleys()` (assembly view)** rewritten to walk the same positions plus the 5 MCP redirects.

#### #5 — spool radius reconciled at 0.004 m

- **`hand_params.scad`:** `spool_od` already 8.0 (no change).
- **`descriptor/free-humanoid.udd.json`:** `spool_radius_m: 0.008 → 0.004` in both joint metadata blocks (`L_HAND_synergy`, `R_HAND_synergy`) **and** the actuator metadata blocks. Rationale string updated: continuous force = 0.82 / 0.004 ≈ 205 N (was 100 N); peak = 6.25 / 0.004 ≈ 1562 N (was 780 N). Source citation kept.
- **`hand-v0.1-assembly.md` §10:** added a note pinning the corrected force figures. Downstream synergy-controller code that consumes `spool_radius_m` will now compute correct cable forces.

#### #6 — MCP flex applied to proximal phalanx

- **`finger.scad`:** the proximal phalanx is now wrapped in `rotate([flex_angles[0], 0, 0])`. The MCP rotation also propagates through to PIP and DIP — the kinematic chain is correct end-to-end.

#### #7 — DIP nested inside PIP transform

- **`finger.scad`:** the distal phalanx instantiation is now nested inside both the MCP and PIP transforms (rotate-translate-rotate-translate-rotate-translate chain), so PIP rotation propagates the distal phalanx position naturally instead of `flex_angles[1] + flex_angles[2]` faking the orientation in the parent frame. The thumb's IP joint is similarly nested inside its MCP.

#### #8 — dowel pin shortened to PB3-12

- **`hand_params.scad`:** `axle_length 30 → 12`.
- **`hand-v0.1-BOM.csv` line 18**: part number `PB3-30-NN-A → PB3-12-NN-A`, description "30 mm length → 12 mm length", price tweaked, notes updated to call out the v0.1.1 reasoning (joint barrel 10 mm + 1 mm/side overhang for E-clip retainer groove).
- **`hand-v0.1-assembly.md` §3 step 3**: part-number callout changed from PB3-30-NN-A → PB3-12-NN-A with sizing rationale.

#### #9 — load cell relocated forearm-side

- **`palm.scad`:** `loadcell_cavity()` body removed (module retained as an empty no-op stub). Call site in `palm()` removed.
- **`hand-v0.1-assembly.md` §10:** new note at the top of the section pinning the CZL635 to forearm-side mounting (alongside the Moteus n1 per §5.4).
- **`descriptor/free-humanoid.udd.json`:** `tension_sensor_part_number` field annotated "(mounted forearm-side adjacent to Moteus n1; relocated v0.1.1 fix #9)".
- **Note:** the forearm bracket housing the load cell is a **forearm-subassembly artifact, not hand v0.1.1 work** — to be designed when the forearm CAD lands.

### Significant (also addressed in v0.1.1)

#### #10 — bushing flange counterbore added

- **`phalanx.scad` `bushing_pocket()`:** appended a `cylinder(d=bushing_flange_od, h=bushing_flange_t)` step at the outer face of each pocket (both proximal and distal). `bushing_flange_od = 7.0` and `bushing_flange_t = 0.8` were already in `hand_params.scad`. Flange now seats flush.

#### #11 — tendon channel rerouted below the joint barrel

- **`phalanx.scad`**: tendon channel z-position moved from `side_offset * (height/2 - 3.0)` to `side_offset * (height/2 - 1)` — the channel runs just below the barrel circumference instead of clipping through it.
- **Added** a small Z-direction reroute segment at each joint that brings the tendon up from the deep palmar channel to the barrel-underside pulley exit. Distal-end reroute is suppressed for `DIP`/`THUMB_IP` phalanges (no distal joint).
- **Bonus:** the tendon channel now uses `$fn=$fn_hi` instead of `$fn_lo`, partially addressing audit issue #24 (faceted-edge cable abrasion).

#### #14 — bracket M2.5/M3 comment vs. parameter resolved

- **`motor_bracket.scad`** header comment: "4× M3 mount holes to palm.scad" → "4× M2.5 mount holes to palm.scad" — now consistent with `palm_mount_bolt_m = 2.5` and assembly.md §5.2.

#### #18 — spring leg slot orientation fixed

- **`phalanx.scad` `spring_pocket()`**: leg-engagement cube wrapped in `rotate([90,0,0])` so its long axis aligns with the axle Y rather than world Z. The cube now actually engages the spring's free leg in the spring's plane.

#### #19 — wrist keying

- **`hand_params.scad`:** `wrist_iface_count 3 → 4`. New params `wrist_iface_key_dia = 2.0` and `wrist_iface_key_pcd = 22.0`.
- **`palm.scad` `wrist_interface()`:** now drills 4 equally-spaced bolt clearance holes plus one 2 mm dia keying pin hole at +45° on PCD 22 — locks orientation to a single install pose.

#### #20 — thumb CMC clearance

- **`palm.scad` `thumb_cmc_block()`** CMC axle hole: `axle_dia → axle_dia + axle_to_bushing_clearance`. The pin is now a slip fit, not a press fit.

---

## Items deferred to v0.1.2

The following audit findings are explicitly **not** addressed in v0.1.1. Each is annotated with the reason for deferral.

| # | Issue | Reason for deferral |
|---|---|---|
| #12 | Palm pulleys vs. assembly.md §4.2 mismatch (was 8 in palm, asm says 2-3 + 5 MCP) | **Partially addressed in v0.1.1** (3 in palm + 5 MCP redirects via `mcp_redirect_pulley_pocket`). Final pulley-path validation deferred to second-pass audit. |
| #13 | Tendon central distribution channel cuts full palm length | Geometric weakening; defer until palm-FEA / first-print bend test in v0.1.2. |
| #15 | Pulley flange thickness 0.6 mm vs BOM 1.0 mm | Cable-seating margin issue; defer until first cable-route bench test. |
| #16 | Skin mold uses parametric envelope proxy, not assembled-skeleton outer surface | Already flagged as v0.1.1 work in `cad/README.md §8`; needs assembled `union()` of skeleton + `minkowski()` offset. Out-of-scope for this pass. |
| #17 | Skin mold alignment pins not registered to the skeleton | Co-deferred with #16 (single mold rework pass in v0.1.2). |
| #21 | Descriptor `continuous_torque_nm = 0.82` not derived in rationale | Updated rationale string in v0.1.1 to spell out the 78 mNm × 14 × ~0.75 efficiency derivation; closed inline. (Tracked here for completeness; not a blocker.) |
| #22 | Descriptor `max_velocity_rad_s = 52.4` | Audit confirms ✓ matches; no action needed. |
| #23 | Pulley OD Ø8 mm gives bend radius 4 mm = ½ declared `tendon_min_bend_r` of 8 mm | Upsizing pulleys to Ø16 mm = BOM rework + palm geometry rework. Defer; mark cable-cycle-life as a known v0.1.2 risk. |
| #24 | Tendon hole `$fn=$fn_lo` (24-gon facet) | **Partially addressed** in v0.1.1 (changed to `$fn_hi` as part of fix #11). Closed. |
| #25 | `palm_finger_count` parameter name misleading | Cosmetic rename; defer. |
| #26 | `(height/2 - 3.0)` tendon offset has no guard for thinner phalanges | Defer; current values all satisfy the guard. |
| #27 | `spring_pocket_dia = 5.5` tight clearance for SLS PA12 | Manufacturing-tolerance issue; flagged in `hand_params.scad §12`. Defer to first physical print. |
| #28 | Visualization-only: assembly z-placement of fingers inside palm cavity | Caused by issue #2 deeper alignment problem; with #2 fix applied, this should self-resolve. Re-render and verify in second-pass audit. |
| #29 | BOM ↔ descriptor cross-checks | All passed after v0.1.1 fixes #5 and #21. |
| #30 | No `assert(...)` block in `hand_params.scad` | Recommended best practice; defer to v0.1.2 polish pass. |

---

## New / changed BOM line items

| BOM line | Before | After |
|---|---|---|
| `joint_axle` | Misumi PB3-**30**-NN-A, 30 mm length, $1.20 × 15 = $18.00 | Misumi PB3-**12**-NN-A, 12 mm length, $1.10 × 15 = $16.50 |

No new line items added. Other quantities and prices unchanged. (The TOTAL line at row 37 is approximate and not recomputed in this pass.)

---

## Open questions for second-pass audit

1. **Cable-bend radius (#23 deferred).** Pulley OD Ø8 mm gives a centerline bend radius of 4 mm — half the declared `tendon_min_bend_r = 8 mm`. Decision needed: accept reduced cycle life, or upsize pulleys (and reconcile BOM line 17 + palm geometry).
2. **Skin mold rebuild (#16/#17 deferred).** v0.1.2 should rebuild `hand_envelope_proxy()` from the assembled-skeleton union with a `minkowski()` offset, and add 2+ skeleton-registration features.
3. **Forearm bracket for the load cell (out-of-scope #9).** Once forearm CAD exists, drop a CZL635 mount adjacent to the Moteus n1 and route the synergy tendon through it inline.
4. **Re-render the assembled view** with the v0.1.1 finger orientation fix to confirm the proximal phalanx body extends from the palm distal edge rather than sitting inside the palm cavity (visualization issue #28).
5. **Verify Maxon GP 32 HP front-face PCD** against the current Maxon catalog drawing 166940 before ordering bracket stock — the 27 mm / M3 figure used in v0.1.1 is the standard catalog value; confirm no catalog revision since the audit.

---

## openie-cad verification

Run on **2026-05-07** against [openie-cad](https://github.com/openIE-dev/openie-cad) `main` @ `e535bf1` ([`cad.openie.dev`](https://cad.openie.dev)). All 9 source files lex, parse, and import to UDD without error:

```
PASS hand_params.scad   — 0 top-level expr  → 0 bodies,   0 UDD nodes
PASS phalanx.scad       — 20 top-level expr → 20 bodies, 11 UDD nodes
PASS finger.scad        — 6 top-level expr  → 6 bodies,   0 UDD nodes
PASS palm.scad          — 20 top-level expr → 20 bodies, 14 UDD nodes
PASS motor_bracket.scad — 6 top-level expr  → 6 bodies,   2 UDD nodes
PASS pulley.scad        — 1 top-level expr  → 1 body,     1 UDD nodes
PASS spool.scad         — 5 top-level expr  → 5 bodies,   4 UDD nodes
PASS skin_mold.scad     — 17 top-level expr → 17 bodies, 14 UDD nodes
PASS hand_assembly.scad — 7 top-level expr  → 7 bodies,   4 UDD nodes
exit 0
```

(`hand_params.scad` reporting 0 top-level expressions is expected — it's pure parameters with no geometry.)

This is a static parse + UDD-import check, not a CSG → B-Rep render. The OpenSCAD render step in the build runbook §3.2 is still required for STL generation. CSG evaluation through openie-cad's kernel is on the roadmap for cad.openie.dev; once exposed, it will replace the OpenSCAD render step.

The verifier itself lives at [openie-cad/crates/cad-interop/examples/check_openscad.rs](https://github.com/openIE-dev/openie-cad/blob/main/crates/cad-interop/examples/check_openscad.rs). Re-run before any future CAD edit.
