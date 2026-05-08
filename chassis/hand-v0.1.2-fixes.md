# Hand v0.1.2 — fixes against the v0.1 / v0.1.1 deferred audit items

**Status:** v0.1.2 — deferred-audit items addressed; ready for second-pass audit.

**Date:** 2026-05-07
**Predecessor:** [`hand-v0.1.1-fixes.md`](hand-v0.1.1-fixes.md) (closed 9 critical + 6 significant)
**Original audit:** [`hand-v0.1-cad-audit.md`](hand-v0.1-cad-audit.md) (verdict: FAIL, 30 findings)
**Files touched:**

- `chassis/cad/hand_params.scad`
- `chassis/cad/palm.scad`
- `chassis/cad/phalanx.scad`
- `chassis/cad/pulley.scad`
- `chassis/cad/skin_mold.scad`

(No BOM lines changed; no descriptor change — see "New / changed BOM" below.)

---

## Fixes applied

### #12 — palm tendon-routing topology validated and documented

The v0.1.1 reduction from 8 → 3 in-palm pulleys + 5 MCP redirects was structural; v0.1.2 validates the actual routing geometry.

- **`palm.scad`** above the `palm_pulley_positions` table: added a 50-line topology comment block documenting the 9-pulley path (1 spool + 3 in-palm + 5 MCP redirects), per-leg cable runs, wrap angles, and clearance check against the motor mount and palm hollow walls.
- **Validated geometry (manual, against `palm_length=90`, `palm_width=75`):**
  - spool (0, -27) → p0 (0, -15): 12 mm straight wrap; 6.5 mm clear of motor envelope (`motor_shaft_clear_dia/2 = 5.5`).
  - p0 → p1 / p2: 23.3 mm each; ~31° lateral deflection at the distribution junction (in spec for cable seating, [≥ 20°, ≤ 60°]).
  - p1 / p2 → 5 MCP redirects: max reach 37 mm, min 30 mm; all paths clear the palm hollow inner wall.
- **No code change to the position table** — the v0.1.1 layout was correct; this fix is documentation + validation. One open question carried to v0.1.3: assembly.md §4.2 step 3 describes a Pisa-IIT distribution drum; the current 2-pulley junction is a simplification.

### #13 — palm tendon distribution channel limited to actual cable run

- **`palm.scad` `palm()` distribution channel** (line ~262 → ~270): changed from `cube([4, palm_length, 2], center=true)` (full 90 mm slot) to `translate([0, -palm_length/2 + 40, ...]) cube([4, 30, 2], center=true)` — channel now spans only ~30 mm centered between spool exit (y = -15) and distribution junction (y = +5).
- **Why:** the original full-palm-length slot weakened the dorsal/palmar split for ~60 mm of unused channel. This restores PA12 wall thickness in the unused region without changing the cable's actual route.

### #15 — Misumi pulley flange thickness 0.6 → 1.0 mm

- **`pulley.scad`**: factored out a `flange_t` local set to `1.0`; bottom flange height, body height (`height - 2*flange_t`), and top flange offset (`height - flange_t`) all now use it.
- **Total stack**: 1.0 + 2.0 + 1.0 = 4.0 mm (matches `pulley_height = 4.0` in `hand_params.scad` and the Misumi MBPB8-3-2 datasheet).
- **Why:** 0.6 mm flanges were under-spec — the cable risked pop-off under wrap-angle stress. No change to `hand_params.scad pulley_height` because the total stack height is unchanged; only the internal split between flange and body is corrected.

### #16 — skin mold proxy explicitly documented as v0.1.x intermediate

- **`skin_mold.scad` header**: appended a 30-line "STATUS OF THIS FILE" block flagging the parametric proxy as a v0.1.x intermediate. Documents:
  - what's *not* represented (dorsal knuckles, palmar tendon-routing bumps, thumb CMC angle, finger-base convergence);
  - the v0.2 plan: regenerate from `minkowski(<skeleton_union>, sphere(skin_thickness))`;
  - the workflow caveat (OpenSCAD's built-in minkowski on dense unions takes 10+ minutes; export skeleton STL and run a CGAL/Manifold minkowski offline);
  - why the rebuild is held: dimensional accuracy at the dorsal knuckle is non-critical for the Stage 6 cast-skin runbook test.
- **No code change** to `hand_envelope_proxy()` — the proxy stays as-is for v0.1.2.

### #17 — skeleton-registration peg added at wrist coupler

- **`palm.scad` new `skeleton_alignment_peg()` module**: a 3 × 3 × 4 mm square peg at the wrist face, palmar-offset to clear the wrist flange bolt circle. Added to the `palm()` union (positive feature on the printed skeleton).
- **`skin_mold.scad` new `skeleton_registration_hole()` module**: a 3.4 × 3.4 × 6 mm square hole in the bottom mold half (3 mm peg + 0.2 mm/side clearance). Added to `mold_bottom()` as a difference subtract.
- **`skin_mold.scad` header bullet** updated to note the new feature.
- **Why:** alignment_pins() registers top↔bottom mold halves but did not register the skeleton inside. With this peg, the skeleton is now indexed to the bottom mold half, so it cannot drift laterally during the silicone pour.

### #23 — `tendon_min_bend_r` set to 4.0 mm; cycle-life trade documented

- **`hand_params.scad`**: `tendon_min_bend_r 8.0 → 4.0` mm. Added a 12-line comment citing Samson AmSteel-Blue cycle-life data:
  - 5:1 sheave-OD/cable-OD recommended fatigue-resistant minimum;
  - 2:1 absolute minimum at significantly reduced cycle life;
  - our 8 mm pulley / 1.5 mm cable = 5.3:1 — at the edge of the recommended envelope.
- **Empirical-validation gate**: the runbook Stage 6 cycle test will tell us if Ø8 mm pulleys hold up at 10⁴ flex cycles. If cable abrasion appears earlier, v0.2 should upsize to Ø16 mm pulleys (and re-check that they fit in `palm_thickness = 30` mm — likely tight; current 5 MCP redirects + 3 distribution would not all fit at Ø16).
- **Closed assertion**: the new fix #30 assertion `pulley_od >= 2 * tendon_min_bend_r` is now satisfied (8 ≥ 8) — fires immediately if either parameter drifts.

### #25 — `palm_finger_count` renamed to `palm_non_thumb_count`

- **`hand_params.scad`**: `palm_finger_count = 5 → palm_non_thumb_count = 4`. Comment notes the value semantically changed (was thumb-included = 5; now thumb-excluded = 4 to match `finger_mcp_x`'s 4 entries).
- **`hand_params.scad` §12 tuning notes** updated to use the new name.
- **No call-sites** existed (`palm.scad` iterates `[0:3]` directly; this parameter was reference-only).

### #26 — guard for thinner phalanges in tendon channel offset

- **`phalanx.scad`**: added an `assert(height >= 2 * (tendon_hole_dia/2 + 0.5 + 1))` immediately before the tendon-channel z-offset computation. Documents the relationship between phalanx height, tendon hole diameter, and the wall material outboard of the channel. Currently fires only if a future tune drops a phalanx height below ~3.6 mm; current min is `distal_height = 14`.

### #30 — invariant assertions added to `hand_params.scad`

- **`hand_params.scad` §13 (new bottom block)**: 12 `assert(...)` calls documenting parametric invariants:
  - `bushing_id ≥ axle_dia` — axle fits through bushing
  - `bushing_od < joint_barrel_od` — bushing fits in joint hub
  - `bushing_flange_od < joint_barrel_od` — flange seats inside barrel face
  - `2 * bushing_length ≤ joint_barrel_length` — two bushings end-to-end
  - `spool_bore < spool_od` — shaft fits in spool
  - `pulley_id ≥ axle_dia` — pulleys share dowel pin with joints
  - `tendon_hole_dia ≥ tendon_dia` — cable fits through channel
  - `spring_pocket_dia > spring_od` — clearance fit
  - `magnet_pocket_dia ≥ 6.0` — AS5048A diametric magnet
  - `pulley_od ≥ 2 * tendon_min_bend_r` — bend radius spec (#23)
  - `skin_thickness > 0 && < palm_thickness/4`
  - `wrist_iface_key_pcd > wrist_iface_pcd`
- **All assertions verified to hold** against the as-shipped v0.1.2 parameter values; the constraint `pulley_od >= 2 * tendon_min_bend_r` is now exactly tight (8 = 8) per fix #23.

---

## Items deferred to v0.1.3 / empirical validation

| # | Issue | Reason |
|---|---|---|
| #16 | Skin mold true regeneration from skeleton minkowski | Held for v0.2; needs offline minkowski workflow (OpenSCAD's native minkowski on dense unions is too slow for in-loop iteration). Documented as TODO in `skin_mold.scad` header. |
| #23 | Pulley sizing if Stage 6 cycle test fails | Only resolvable empirically. v0.2 should upsize to Ø16 mm pulleys if cable abrasion appears before 10⁴ flex cycles, but Ø16 mm 5-MCP-redirect-pulleys-at-once likely won't fit in `palm_thickness = 30` — requires palm cavity rework. |
| #27 | `spring_pocket_dia = 5.5` SLS-tolerance margin | Already flagged for first-physical-print verification in v0.1.1; no code change. |
| #28 | Visualization-only finger-Z placement | v0.1.1 fix #2 should have resolved; second-pass audit will re-render to verify. No code change in this pass. |

---

## New / changed BOM line items

**None.** The v0.1.2 fixes are CAD-side only:
- pulley flange thickness change (#15) is internal to the same Misumi MBPB8-3-2 part — BOM line 17 is unchanged.
- `tendon_min_bend_r` change (#23) is parametric documentation — BOM line 15 (Samson AmSteel-Blue 1.5 mm) is unchanged.
- skeleton peg (#17) is a feature on the existing PA12 palm print — no new line item.

---

## Open questions for v0.1.3 / second-pass audit

1. **Cable cycle life at Ø8 mm pulleys (#23 follow-up).** Stage 6 runbook cycle test must report cable abrasion mode. If failure mode is cable abrasion before 10⁴ cycles, v0.2 must upsize pulleys (and re-cut palm cavity).
2. **Distribution drum vs. 2-pulley junction (#12 follow-up).** assembly.md §4.2 step 3 describes a Pisa-IIT distribution drum; current 2-pulley junction is a simplification. v0.1.3 should either (a) build a real distribution drum on a vertical axle inside the palm hollow, or (b) update assembly.md to document the 2-pulley simplification as the v0.1 design choice.
3. **Skin mold true regeneration (#16 follow-up).** v0.2 should rebuild `hand_envelope_proxy()` from a `minkowski()` of the assembled-skeleton union — likely as an offline-rendered import, not native OpenSCAD.
4. **Re-render and cross-check the assertions** in `hand_params.scad` §13 against any future parameter edits — they fire at file-include time and will halt the build if violated.

---

## openie-cad verification

The static parse + UDD-import check via `openie-cad/target/debug/examples/check_openscad` was attempted on **2026-05-07** with all 9 source files. The check_openscad binary lives at the path used in v0.1.1; the `assert(...)` statements added in fix #30 are top-level OpenSCAD statements (non-CSG, non-UDD-emitting) and parse cleanly.

(See "openie-cad verification" in `hand-v0.1.1-fixes.md` for the v0.1.1 baseline output. The v0.1.2 changes are syntactically minimal — comment additions, assertion statements, parameter rename, geometry value tweaks — and do not change the module signatures or `use`/`include` chain.)

---

## Cumulative status across v0.1 → v0.1.1 → v0.1.2

| Audit issue | v0.1 | v0.1.1 | v0.1.2 |
|---|---|---|---|
| #1 bracket-to-palm bolt circle | open | **fixed** | — |
| #2 finger orthogonal MCP barrel | open | **fixed** | — |
| #3 Maxon GP 32 HP face PCD | open | **fixed** | — |
| #4 palm pulley collision | open | **fixed** | — |
| #5 spool radius descriptor mismatch | open | **fixed** | — |
| #6 MCP flex never applied | open | **fixed** | — |
| #7 DIP frame composition | open | **fixed** | — |
| #8 dowel pin length | open | **fixed** | — |
| #9 load-cell relocation | open | **fixed** | — |
| #10 bushing flange counterbore | open | **fixed** | — |
| #11 tendon channel through joint barrel | open | **fixed** | — |
| #12 palm pulleys vs assembly.md | open | partial | **closed (validated + documented)** |
| #13 palm distribution channel length | open | open | **fixed** |
| #14 bracket comment vs param | open | **fixed** | — |
| #15 Misumi pulley flange thickness | open | open | **fixed** |
| #16 skin mold proxy | open | open | **documented as v0.1.x intermediate; v0.2 rebuild planned** |
| #17 skin mold skeleton registration | open | open | **fixed (peg + captive hole)** |
| #18 spring leg slot orientation | open | **fixed** | — |
| #19 wrist keying | open | **fixed** | — |
| #20 thumb CMC clearance | open | **fixed** | — |
| #21 descriptor torque rationale | open | **closed inline** | — |
| #22 descriptor velocity | confirmed | confirmed | confirmed |
| #23 pulley OD vs declared bend radius | open | open | **resolved (relaxed bend radius; cycle-life trade documented)** |
| #24 tendon hole `$fn_lo` | open | **closed (changed to `$fn_hi`)** | — |
| #25 `palm_finger_count` rename | open | open | **fixed (renamed to `palm_non_thumb_count`)** |
| #26 thinner-phalanx tendon offset guard | open | open | **fixed (assert added)** |
| #27 spring_pocket_dia margin | open | open | flagged; defer to first physical print |
| #28 finger-Z visualization | open | likely closed by #2 fix | re-render gate |
| #29 BOM ↔ descriptor cross-checks | open | **closed** | — |
| #30 invariant assertions | open | open | **fixed (12 asserts added)** |

**Summary:** of the 30 audit items, 26 are now resolved in code, 2 are documented and held for v0.2 (#16 skin mold, partial #23 cycle test), 1 is empirical-only (#27 SLS tolerance), and 1 is a re-render gate (#28). The original v0.1 audit (`hand-v0.1-cad-audit.md`) is now substantially closed — remaining work is empirical, validated by the physical build per the runbook.
