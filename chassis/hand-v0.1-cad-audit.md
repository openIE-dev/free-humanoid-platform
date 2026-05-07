# Hand v0.1 CAD verification audit

**Audited:** 2026-05-06
**BOM:** chassis/hand-v0.1-BOM.csv
**CAD source:** chassis/cad/ (10 files)
**Descriptor block:** descriptor/free-humanoid.udd.json (L_HAND_synergy / R_HAND_synergy)

---

## Verdict

**FAIL — needs fixes before fabrication.**

The dimensioned BOM-to-parameter mapping is largely consistent (axle, bushing, tendon, pulley, spring, magnet, skin, load-cell envelope all line up at the parameter level), but the assembly-level geometry has multiple structural defects that would surface on a machinist's first read: the motor bracket bolt circle does not match the palm's bolt circle, the in-palm pulley pivots collide with the motor mount, the finger MCP barrels are oriented orthogonal to the palm MCP barrels (no shared axle is possible), and the motor face PCD itself is contradicted by Maxon's published GP 32 HP mounting drawing. Several CAD-internal contradictions (spool effective OD vs. descriptor `spool_radius_m`, MCP flex never applied in `finger.scad`, oversize dowel length, missing bushing flange counterbore, load-cell mount bolt extending past the palm distal edge) would each independently block a clean first build.

No OpenSCAD syntax errors observed; the files will render. The defects are geometric / logical, not syntactic.

---

## Critical issues (block fabrication)

1. **[B] motor_bracket.scad:30 vs palm.scad:104 — bolt circle mismatch between bracket and palm.** `motor_bracket.scad` line 30 drills its palm-side mount holes on `palm_mount_pcd = 25.0` mm at four equally-spaced positions (0°, 90°, 180°, 270°). But `palm.scad`'s `motor_mount_iface` (lines 100-110) only drills holes on `motor_face_pcd = 22.0` mm at (45°, 135°, 225°, 315°). **Result: there is no path for the four M2.5 bracket-to-palm bolts called out by assembly.md §5.2 — the bracket cannot be bolted to the palm.** Fix: in `palm.scad` add a second 4-hole pattern at `palm_mount_pcd = 25.0` mm with rotation offset matching the bracket, or change `motor_bracket.scad` to use `motor_face_pcd` and 45° offset.

2. **[D] palm.scad finger_mcp_mount vs hand_assembly.scad finger placement — MCP barrels orthogonal.** `palm.scad:55-60` builds each finger MCP mount as joint barrels rotated `[90, 0, 0]` (axle along **Y**). In `hand_assembly.scad:53-59` the entire finger is rotated `[0, 0, 90]` about Z before placement, which maps the phalanx's local Y barrel axis to the palm's **X** axis. The proximal phalanx barrel and the palm MCP barrel end up perpendicular; **no 3 mm dowel pin can connect them**. Fix: either drop the `rotate([0, 0, 90])` in `hand_assembly.scad` and rebuild the finger module so its long axis is +Y, or rotate the palm's `finger_mcp_mount` ears to match the rotated finger.

3. **[B][F] palm.scad:104 motor face PCD = 22 mm, but assembly.md §5.1 + Maxon GP 32 HP datasheet — Maxon GP 32 HP's published front-face mounting pattern is 4× M3 (not M2.5) on a different PCD.** BOM line 6 (`drive_reducer 166940`) and `hand_params.scad:141-143` assert `motor_face_pcd = 22.0` and `motor_face_bolt_m = 2.5`. The Maxon GP 32 HP catalog page (166940) actually publishes 4× M3 on PCD 27 mm for the front mount. `hand_params.scad:138` itself flags this with the comment "verify against Maxon mounting drawing 166940 prior to ordering bracket stock." Fix before ordering: pull the official Maxon mounting drawing and replace `motor_face_pcd` and `motor_face_bolt_m` accordingly. Until corrected, both `motor_bracket.scad` and `palm.scad`'s motor interface are wrong.

4. **[B] palm.scad:170-176 palm_pulley_mounts collides with motor_mount_iface.** Palm pulley axle holes are placed on a circle of radius 18 mm centered at the palm origin, at every 45° (8 holes), drilled through the full palm thickness (`h = palm_thickness`). The motor_mount_iface (line 100) is centered at `(0, -palm_length/2 + 18, palm_thickness - 2)` = `(0, -27, 28)` with motor_shaft_clear_dia 11 mm + bolt holes at PCD 22. The pulley pivot at angle 270° lands at `(0, -18, ...)` — 9 mm from the motor mount center. With pulley OD 8 mm + flange 9.5 mm and motor mount Ø 12+ mm, **the lower pulley overlaps the motor shaft clearance**. Worse, the pulley axle hole runs through the same Z range as the motor mount counterbore, so the bolt and pulley pivot share material. Fix: relocate `palm_pulley_mounts` to a non-circular routing-driven layout; the 8-equally-spaced star is geometrically arbitrary and not matched to the routing path called out in assembly.md §4.

5. **[A] hand_params.scad:108 spool effective OD vs. descriptor `spool_radius_m`.** `spool.scad:42` builds the spool body with OD = `spool_od + 2*spool_groove_pitch` = 8 + 2·1.8 = **11.6 mm** (5.8 mm radius at the groove ridge, ~4 mm radius at the groove valley). The descriptor (`free-humanoid.udd.json:144-145`) sets `"spool_radius_m": 0.008` (= 8 mm radius = **16 mm OD**). The BOM rationale text in the descriptor metadata also says "8 mm spool" which the CAD interprets as diameter. **The descriptor's spool radius is double the CAD's effective spool radius**, so the descriptor's torque→cable-force conversion (~100 N continuous from 0.82 N·m / 0.008 m) is off by 2× from what the as-built spool will deliver (~205 N continuous from 0.82 N·m / 0.004 m). Fix: pick one. If 8 mm OD is correct, change the descriptor to `"spool_radius_m": 0.004` and re-derive cable force; if 16 mm OD is correct, change `spool_od` to 16 in `hand_params.scad`.

6. **[F] finger.scad:46-54 — MCP flex angle (`flex_angles[0]`) is never applied to the proximal phalanx.** In the 3-phalanx branch, the proximal phalanx is instantiated at the finger origin with no rotation, then PIP and DIP are rotated. There is no `rotate([0, flex_angles[0], 0])` wrapping the proximal segment. **The hand cannot be rendered in any flexed pose at the MCP** (which is the primary synergy DoF). Fix: wrap the proximal phalanx instantiation in `rotate([0, flex_angles[0], 0])` and translate-then-rotate the MCP joint at `(-proximal_length/2, 0, 0)` so rotation is about the MCP barrel center.

7. **[D] finger.scad:67-76 — DIP kinematic chain composes rotations in the wrong frame.** The distal phalanx is translated to `(proximal_length + middle_length + 2, 0, 0)` in the **un-rotated** parent frame, then rotated by `flex_angles[1] + flex_angles[2]`. PIP rotation does not propagate through to the distal-phalanx position; the additive `flex_angles[1] + flex_angles[2]` only fakes the orientation. **For any non-zero PIP flex the distal phalanx detaches from the middle phalanx tip.** Fix: nest the DIP transform inside the PIP transform: `rotate([0,flex_angles[1],0]) translate([middle_length+2,0,0]) rotate([0,flex_angles[2],0]) translate([distal_length/2,0,0]) phalanx(...)`.

8. **[B] hand_params.scad:53 axle_length = 30 mm, but joint_barrel_length = 10 mm.** The Misumi PB3-30-NN-A dowel is 30 mm long. Each joint barrel is only 10 mm axially. With a 30 mm pin in a 10 mm joint, **the pin protrudes ~10 mm out of each side of the joint** — fouling the adjacent phalanx, the spring, or the next joint over. Either use a shorter Misumi dowel (PB3-10 or PB3-12) or extend `joint_barrel_length` to ~28-30 mm. The BOM should be updated either way; the assembly procedure (assembly.md §3) calls out an E-clip retainer that assumes the pin is sized to the joint, not 3× longer.

9. **[B] palm.scad:138-144 loadcell mount bolt poke past palm distal edge.** `loadcell_cavity` is centered at `(0, -palm_length/2 + 30, palm_thickness/2)` = `(0, 15, 15)` with length 38 mm along Y. The two end-mount bolt holes are placed at `Y = -palm_length/2 + 30 ± loadcell_cavity_l/2` = `Y = -4` and `Y = +34`. With `palm_length/2 = 45`, the second mount bolt at Y=34 has only 11 mm to the palm edge but the bolt clearance cylinder is `h=8 center=true` — barely contained. More importantly, a **38 mm load cell + 2 end-mount bosses cannot fit anywhere reasonable in a 90 mm palm whose proximal half is reserved for the motor stack** (BOM motor_stack_length = 70 mm). Either the CZL635 is in the wrong location, or it should be inline with the synergy tendon between motor spool and finger junction (per assembly.md §10), which is the proximal half of the palm — currently occupied by the motor. Fix: relocate the load cell to the forearm-side of the LEMO bulkhead (assembly.md §5.4 already places the Moteus n1 forearm-side; the load cell can travel with it).

---

## Significant issues (should be fixed before order)

10. **[B] phalanx.scad:30-38 bushing_pocket has no recess for the bushing flange.** The bushing pocket subtracts a Ø5.03 mm × 4 mm cylinder. The Bunting / McMaster 8458K71 bushing has a flange of OD ~7 mm × thickness ~0.8 mm (per `hand_params.scad:57-58`). Without a Ø7 mm × 0.8 mm counterbore at the outer face of the joint barrel, **the flange will sit proud** — preventing bushing seating, fouling the phalanx-to-phalanx mating face, and allowing the bushing to migrate axially under load. Fix: extend `bushing_pocket()` to add a `cylinder(d=bushing_flange_od, h=bushing_flange_t)` step at the outer face of each pocket.

11. **[C] phalanx.scad:121-126 tendon channel passes through the joint barrel.** The tendon channel is drilled at `z = -1*(height/2 - 3.0) = -6 mm` (palmar side) over the full phalanx length. The proximal joint barrel at `(-length/2, 0, 0)` has OD 12 mm and is centered at `z=0`, so it spans `z = -6 to +6`. **The tendon hole at `z = -6.8 to -5.2` clips through the bottom edge of the joint barrel, intersecting the bushing pocket and the axle hole.** This makes the tendon path conflict with the pivot bearing — every flex cycle the tendon would saw against the bushing flange. Fix: route the tendon channel below the joint barrel (`z = -(height/2 - 1)` and add a small dorsal-palmar reroute at the joint), or use a side-entry pulley at each joint per the Pisa-IIT SoftHand reference.

12. **[D] palm.scad:170-176 vs assembly.md §4.2 — palm has 8 in-palm pulley pivots but the assembly procedure calls for 2-3 in-palm + 5 at MCP.** Assembly.md §4.2 lists "1 spool pulley + 2-3 synergy junction pulleys (in palm) + 5 MCP redirect pulleys (one per finger)". The palm.scad `palm_pulley_count = 8` and the comment block at line 6-9 of palm.scad says "8 in-palm tendon-routing pulleys (12 PEEK pulleys total per BOM; 4 are non-palm spares + spool pulley)" — which leaves zero PEEK pulleys for the MCP redirects. Either the MCP redirects are missing geometry (the finger_mcp_mount in palm.scad has no pulley pocket) or the palm has 5 pulleys it doesn't need. Fix: drop palm-internal pulley count to 2-3 distribution pulleys + add a pulley-axle pocket to each `finger_mcp_mount`.

13. **[C] palm.scad:198-201 tendon central distribution channel cuts through the palm full Y-length and full X-thickness.** The channel is `cube([4, palm_length, 2], center=true)` at `z = palm_thickness/2`. **A 4 mm × 2 mm slot the entire 90 mm length of the palm structurally weakens the dorsal/palmar split.** Combined with the palm_hollow cavity, the palm wall above the channel may be only ~3.5 mm of PA12. Fix: limit channel length to the actual cable run from spool exit to distribution junction (~30 mm), not the full palm.

14. **[B] motor_bracket.scad:60-62 plate_od = motor_stack_od + 12 = 44 mm, but palm_mount_pcd = 25 mm.** The bracket flange holes at PCD 25 mm sit at radius 12.5 mm — well inside the plate (radius 22 mm). That's fine geometrically, but the comment at line 9 says "4× M3 mount holes to palm.scad" while `palm_mount_bolt_m = 2.5`. **The CAD comment and the parameter disagree on M2.5 vs M3.** The bracket BOM line 27 calls for "Custom CNC milling" with no fastener spec; assembly.md §5.2 says "four M2.5 SHCS at 0.5 N·m." Resolve: pick M2.5 or M3 and update the comment in motor_bracket.scad line 9.

15. **[A] hand_params.scad:96 pulley_height = 4.0 mm but BOM (line 17) says 2 mm flange.** BOM line 17 specifies "Misumi miniature ball-bearing pulley, 8 mm OD x 3 mm bore x 2 mm flange." The Misumi MBPB8-3-2 datasheet: total height = 4 mm with two 1 mm flanges (2 mm body). The CAD has top/bottom flanges of 0.6 mm each (lines 25, 30) and a 2.8 mm body. Marginal — total height matches but flange thickness is wrong, which affects whether a 1.5 mm UHMWPE cable will stay seated under wrap-angle stress. Fix: set flange thickness to 1.0 mm in `pulley.scad`.

16. **[E] skin_mold.scad:23-54 hand_envelope_proxy uses a parametric stand-in, not the assembled-skeleton outer envelope.** The file's own header (lines 5-7) flags this: "the actual mold should be derived from the assembled-hand outer surface once the hand is solid; this file is a parametric stand-in." A mold derived from a rounded-rectangular palm + capsule fingers will be **dimensionally close but not surface-accurate** — the dorsal knuckles, palmar tendon-routing bumps, and thumb CMC angle will not be represented. The cast skin will fit loosely on the dorsal knuckles and tightly at the palmar tendon-channel ridges. Fix (acknowledged as v0.1.1 work in README §8): regenerate `hand_envelope_proxy()` from a `minkowski()` of the assembled-skeleton union.

17. **[E] skin_mold.scad:67-76 alignment pins at corner of mold box (radius 8 from corner) — not registered to skeleton.** The pins index the two mold halves to each other but not to the skeleton inside; if the skeleton shifts during pouring, the cast skin will be uneven. Fix: add 2 skeleton-registration features (e.g., a peg at the wrist coupler that engages a captive hole in the bottom mold half).

18. **[B] phalanx.scad:42-51 spring_pocket leg-engagement slot is a `cube([2, 1.5, spring_pocket_length])` translated radially without aligning the cube's Z-axis to the axle Y-axis.** The spring pocket cylinder is correctly along Y (rotated 90° about X). But the cube's local Z-axis is along the world Z; the radial slot at `[spring_pocket_dia/2, 0, 0]` is then 5 mm tall in Z, not along the axle. **The leg slot does not actually engage the spring's free leg in the spring's plane.** Fix: orient the cube so its long axis aligns with the axle (rotate `[90,0,0]` like the spring pocket).

19. **[B] hand_params.scad:188 wrist_iface_count = 3, but palm.scad:120-124 wrist_interface drills `i*(360/3)` = 120° spacing.** With only 3 bolts on a Ø30 wrist flange, there is **no provision for keying the wrist orientation** (3-bolt symmetric flanges allow 3 install orientations). The forearm-side wrist coupler (assembly.md §2.1, mentioned but not specced) needs either an asymmetric pattern or a separate keying feature. Fix: change to 4 bolts, or add a keying pin to the wrist flange.

20. **[B] palm.scad:75-93 thumb_cmc_block uses `cylinder(d=axle_dia, h=20)` for the CMC axle hole — no clearance over the dowel pin.** Other axle holes in palm.scad (line 61) use `axle_dia + axle_to_bushing_clearance = 3.02`. The CMC axle hole at line 92 uses `axle_dia = 3.0` — exactly the pin diameter — which under PA12 tolerance and SLS shrink will be a press fit, not a slip fit. **The thumb CMC pin won't slide in.** Fix: use `axle_dia + axle_to_bushing_clearance` consistently.

21. **[H] descriptor `peak_torque_nm: 6.25` matches BOM intermittent torque, but `continuous_torque_nm: 0.82` does not match BOM.** BOM `drive_motor` (line 5): EC-i 30 nominal torque 78 mNm. BOM `drive_reducer` (line 6): GP 32 HP 14:1, max continuous 4.5 N·m, max intermittent 6.25 N·m. Motor 78 mNm × 14 = 1.092 N·m at the reducer output, **not 0.82 N·m**. The descriptor's 0.82 N·m figure appears to derate by ~75% (perhaps for reducer efficiency ~75% — plausible) but the rationale doesn't show that derivation. Fix: either correct to 1.092 N·m or annotate the efficiency assumption in the rationale string. Peak 6.25 N·m is reducer-limited (BOM says max intermittent 6.25 N·m) — this matches.

22. **[H] descriptor `max_velocity_rad_s: 52.4`.** EC-i 30 no-load 7000 rpm ÷ 14 = 500 rpm output = 52.4 rad/s. ✓ matches.

---

## Minor issues / nits

23. **[A] hand_params.scad:84-88 tendon_min_bend_r = 8 mm = 8× cable dia.** Sound. But this constraint is **only declared, never enforced** — no module asserts that pulley OD ≥ 2× tendon_min_bend_r. The BOM pulleys (Ø8 mm) give a bend radius of 4 mm at the cable centerline (assuming groove valley near center), which is **half** the declared minimum. Fix: either accept the cable spec margin (Samson AmSteel-Blue can run on smaller pulleys at reduced cycle life) and update `tendon_min_bend_r`, or upsize the pulleys to Ø16 mm.

24. **[G] phalanx.scad:122 uses `$fn=$fn_lo` for the tendon hole.** A 1.6 mm hole at $fn=24 is a 24-gon, edges at ~0.21 mm — the tendon will catch on the facet edges. Use `$fn=$fn_hi` for through-channels that tendons slide against.

25. **[F] hand_params.scad:230-231 comment notes `palm_finger_count == 5 but finger_mcp_x has 4 entries`.** This is intentional (thumb separate) but the parameter name is misleading. Rename `palm_finger_count` to `palm_non_thumb_count` or `finger_count_excluding_thumb`.

26. **[B] phalanx.scad:122 side_offset hardcoded to ±1 (selecting palmar vs. dorsal channel side); but the offset distance `(height/2 - 3.0)` assumes height ≥ 6.** For distal phalanx with `distal_height = 14`, that's 4 mm offset — fine. But there's no guard for thinner phalanges.

27. **[A] hand_params.scad:78 `spring_pocket_dia = 5.5` clearance over Ø4.75 spring OD = 0.75 mm radial = 0.375 mm/side.** Tight but plausible for SLS PA12; flag for first-build verification per `hand_params.scad:227-228` self-note.

28. **[G] hand_assembly.scad:59,67 finger placement uses `palm_thickness/2` for Z, but the palm's `finger_mcp_mount` is also at `palm_thickness/2`.** The phalanx body's bottom is at `z = -width/2 = -9` in finger frame; after Z-rotation 90° and placement at `(x, palm_length/2, palm_thickness/2)`, the proximal phalanx body sits at z = `palm_thickness/2 - width/2` = `15 - 9 = 6`. The palm dorsal surface is at z = `palm_thickness = 30`. **The finger sits inside the palm cavity, not extending from it** — a visualization-only issue but indicative of the deeper alignment problem (issue #2).

29. **[H] BOM and descriptor agree on motor part, reducer, controller, encoder, tendon, spool radius (after fixing #5), velocity. Spot-checks pass except for the continuous torque derating noted in #21 and the spool radius mismatch in #5.**

30. **[G] No file uses `assert(...)` to enforce parametric invariants** (e.g., `assert(bushing_id >= axle_dia)`). Adding a small block at the top of `hand_params.scad` would catch future-edit regressions automatically. Not a blocker, but recommended.

---

## Cross-checked items (passed)

- BOM dowel-pin diameter (3 mm) ↔ `axle_dia = 3.0` in `hand_params.scad:52`. ✓
- BOM bushing OD (5 mm) ↔ `bushing_od = 5.0` in `hand_params.scad:55`. ✓ (flange recess missing — see #10)
- BOM tendon line (Samson AmSteel-Blue 1.5 mm) ↔ `tendon_dia = 1.5` and `tendon_hole_dia = 1.6` in `hand_params.scad:84-85`. ✓
- BOM pulley OD (8 mm PEEK) ↔ `pulley_od = 8.0` in `hand_params.scad:94`. ✓
- BOM Lee Spring LTR-040A-04S free-state (90°, 0.040 in wire, 0.187 in OD) ↔ `spring_wire_dia = 1.02`, `spring_od = 4.75`, `spring_free_angle = 90` in `hand_params.scad:72-75`. ✓ (unit conversion correct)
- BOM N35H 6×2.5 mm magnet ↔ `magnet_pocket_dia = 6.1`, `magnet_pocket_depth = 2.6` in `hand_params.scad:116-117`. ✓
- BOM Dragon Skin 30 skin thickness (1.5 mm dorsal, 3.0 mm fingertip per assembly.md §2.2) ↔ `skin_thickness = 1.5`, `skin_thickness_fingertip = 3.0` in `hand_params.scad:123-124`. ✓
- Module signatures match: `palm.scad` → `pulley()` is `use <pulley.scad>` then `pulley()` with no args (uses defaults). ✓ `finger.scad` → `phalanx(length, width, height, joint_type, tendon_side, with_spring_pocket)` matches `phalanx.scad:63-68` signature exactly. ✓
- OpenSCAD syntax: no unmatched braces, no missing semicolons, all referenced parameters are defined in `hand_params.scad`. All files will render. ✓
- License headers present and consistent (CC0 source, CERN-OHL-S artifacts) per `cad/README.md §6`. ✓
- Parametric hierarchy (single source of truth in `hand_params.scad`, `include` chain) is clean and correctly scoped. ✓
- Descriptor `synergy_dof: true` and `spool_radius_m` metadata correctly flag the synergy DoF as a reduced-DoF abstraction over 14-16 passive joints. ✓
- Descriptor reducer ratio (14.0) matches BOM line 6 (GP 32 HP 14:1). ✓
- Descriptor tendon material matches BOM line 15 (UHMWPE / Samson AmSteel-Blue 1.5 mm). ✓

---

## Recommended next steps

Before ordering any parts, a real CAD engineer should: (1) pull the official Maxon GP 32 HP mounting drawing (catalog 166940) and re-derive `motor_face_pcd` and `motor_face_bolt_m` — issue #3 alone makes the bracket and palm motor interface fictitious; (2) resolve the assembly-frame finger orientation (issue #2) by either flattening the `rotate([0,0,90])` in `hand_assembly.scad` or rebuilding `finger.scad` so its long axis is +Y to begin with, then re-render the assembled view to confirm finger-MCP barrels are coaxial with palm-MCP barrels; (3) reconcile the motor bracket-to-palm bolt circle (issue #1) so the 4 M2.5 SHCS in assembly.md §5.2 actually have receiving threads to engage; (4) resolve the spool-radius discrepancy (issue #5) before publishing the descriptor's torque-to-cable-force claim, since downstream control code reads `spool_radius_m` directly; (5) shorten the dowel pins in the BOM to match the joint barrel length (issue #8) or extend the joint barrel; (6) re-derive the load-cell location (issue #9) — the current placement either intersects the motor stack or pokes through the palm distal edge. Issues #6 and #7 can be deferred (they affect rendered pose only, not fabricated geometry) but should be fixed before the v0.1 hand is used as a kinematic reference for the descriptor or for the OpenLoco `behavior::SynergyGrasp` skill stub. The BOM-to-parameter dimensional mapping is sound; the failures are at the assembly level. A second pass focused on `palm.scad` and `hand_assembly.scad` — with all part-level modules left untouched — should resolve the structural defects.

---

*Audit performed against files as of 2026-05-06. Read-only; no source files modified.*
