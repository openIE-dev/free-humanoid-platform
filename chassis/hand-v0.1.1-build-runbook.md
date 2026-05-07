---
title: Hand v0.1.1 — Build Runbook
layout: default
nav_order: 13
permalink: /chassis/hand-v0.1.1-build-runbook.html
---

# Hand v0.1.1 — Build Runbook
{: .no_toc }

> **Status (2026-05-07):** v0.1.1 CAD + descriptor + BOM applied 9 critical and 6 significant fixes from the [v0.1 audit](hand-v0.1-cad-audit.html). The runbook below is what a builder should execute to fabricate and bench-test the first physical hand. **Nothing here is validated by build yet** — the entire purpose of running the runbook is to convert v0.1.1's paper claims into empirical data for v0.1.2.

<details open markdown="block">
  <summary>Contents</summary>
  {: .text-delta }
- TOC
{:toc}
</details>

---

## 0. Scope

This runbook turns the v0.1.1 source artifacts into a single working hand subassembly:

- [`hand-v0.1-BOM.csv`](hand-v0.1-BOM.csv) — 31-line BOM (~$2,288 unit-qty-1)
- [`hand-v0.1-assembly.md`](hand-v0.1-assembly.html) — assembly walkthrough
- [`hand-v0.1.1-fixes.md`](hand-v0.1.1-fixes.html) — what changed since v0.1
- [`cad/`](cad/) — 10 OpenSCAD source files
- [`../descriptor/free-humanoid.udd.json`](../descriptor/free-humanoid.udd.json) — `L_HAND_synergy` / `R_HAND_synergy` blocks

The build is one prototype hand. Mirror later for the second hand.

---

## 1. Pre-order verification (do these BEFORE clicking buy)

The audit flagged six items as "verify against vendor drawing before ordering." v0.1.1 set these to the audit's best-guess values; before placing the orders, confirm each against the live vendor surface. **Two of these (Maxon face, Misumi pulley flange) can break the assembly geometry if wrong.**

| # | Item | v0.1.1 value | Verify against |
|---|------|--------------|----------------|
| 1 | Maxon GP 32 HP front-face PCD | 4× M3 on Ø27 mm | [Maxon catalog 166940 mounting drawing](https://www.maxongroup.us/maxon/view/product/166940) — pull the PDF, confirm PCD and bolt size |
| 2 | Misumi MBPB8-3-2 pulley flange | 1.0 mm/side, 4 mm total | [Misumi MBPB8-3-2 datasheet](https://us.misumi-ec.com/vona2/detail/110302689730/) |
| 3 | Misumi PB3-12-NN-A dowel | Ø3 ×12 mm h7 | [Misumi PB3-12 datasheet](https://us.misumi-ec.com/vona2/detail/110300086170/) |
| 4 | McMaster 8458K71 bushing flange | OD 7 mm × 0.8 mm | [8458K71 spec page](https://www.mcmaster.com/8458K71/) — confirm flange OD; if it differs, regenerate `bushing_pocket()` counterbore in `phalanx.scad` |
| 5 | Lee Spring LTR-040A-04S | 0.040 in wire, 0.187 in OD, 90° free | [Lee Spring datasheet](https://www.leespring.com/torsion-springs/LTR-040A-04S) — confirm metric conversion in `hand_params.scad` |
| 6 | LEMO FGG-0B-308-CLAD | 8-pin push-pull plug | [LEMO datasheet](https://www.mouser.com/ProductDetail/LEMO/FGG-0B-308-CLAD52) — verify pin count + cable diameter range |

If any value differs, **stop and patch `cad/hand_params.scad` first**, then regenerate the print. The print is the long-pole; the screws can be swapped post-receive.

---

## 2. Vendor sequencing

Six vendors, three lead-time tiers. Order in this sequence so the slow tier arrives concurrent with the fast tier.

### Tier A — long lead, order day 0

| Vendor | Items | Typical lead time |
|--------|-------|-------------------|
| Maxon US | EC-i 30 motor, GP 32 HP reducer, ENX 16 EASY encoder | **4–6 weeks** (special-order from Switzerland is common; confirm stock at order time) |
| LEMO via Mouser | FGG-0B-308 + EGG-0B-308 connectors | 2–3 weeks |
| Service bureau (Hubs / Shapeways / Materialise) | SLS / MJF PA12 hand skeleton print | **5–10 business days** after STL upload |
| Local machine shop / Xometry | Aluminum motor mount bracket (custom mill) | **2–3 weeks** quote-to-ship |

### Tier B — mid lead, order day 0–3

| Vendor | Items | Typical lead time |
|--------|-------|-------------------|
| mjbots | Moteus n1 controller | 1–2 weeks |
| Misumi US | MBPB8-3-2 pulleys, PB3-12 dowels | 1 week |
| Mouser | AS5048A encoder + N35H magnet | 3–5 days |
| Smooth-On Direct | Dragon Skin 30, So-Strong, Sil-Poxy | 3–5 days |

### Tier C — short lead, order day 5–7 (so it doesn't sit)

| Vendor | Items |
|--------|-------|
| McMaster-Carr | 8458K71 bushings, 91290A115 SHCS kit, 91458A115 Loctite 222, 1245K73 Krytox, 7856K53 heatshrink, 9600K11 grommets, 8975K426 6061 stock |
| Sparkfun | HX711 breakout |
| Adafruit | Silicone wire bundle |
| Phidgets | CZL635 load cell — **note: load cell now lives forearm-side per audit fix #9.** Order with the forearm subassembly, not the hand. |

McMaster ships overnight; treat it as just-in-time inventory.

### Order grouping checklist

- Single ship-to address for all vendors. Maxon and LEMO sometimes use freight forwarders that won't ship to residential — confirm.
- Maxon needs an account (free). EC-i 30 is the only line item that may require a "what is this for" form; answer "academic robotics research."
- The PA12 print should go out **after** any pre-order CAD patch from §1. Don't print until you've sanity-checked dimensions.

---

## 3. Pre-fabrication CAD prep (day 0–2)

Before the print order:

```sh
cd chassis/cad/
openscad -o ../../out/hand_assembly.stl hand_assembly.scad
openscad -o ../../out/skin_mold.stl skin_mold.scad
# also generate per-finger STLs for orientation-friendly print packing:
openscad -D 'render_target="finger"'  -o ../../out/finger.stl  finger.scad
openscad -D 'render_target="palm"'    -o ../../out/palm.stl    palm.scad
openscad -D 'render_target="bracket"' -o ../../out/motor_bracket.stl motor_bracket.scad
```

(If your `.scad` files do not yet support `render_target` — they may not — render the assemblies as-is and let the service bureau orient.)

**Mass-produce sanity checks before upload:**

1. Open `hand_assembly.stl` in [Prusa Slicer](https://www.prusa3d.com/page/prusaslicer_424/) or [Meshmixer](https://meshmixer.com/) — eyeball for obvious geometry errors (floating phalanges, missing barrels, intersecting walls). The audit caught nine of these on paper; the human eye catches what the audit missed.
2. Print a single finger in PLA on whatever desktop printer you have first. **Cost: ~$2 in filament. Buys you a lot of confidence.** Confirm the joint barrel diameter accepts a 3 mm dowel by hand and the bushing pocket accepts the 8458K71 flange.
3. Only after the desktop test passes should the SLS PA12 production print go to the service bureau.

This gates the largest cost line in the BOM ($320 print) on a $2 desktop test.

---

## 4. Receive-and-inspect (as parts arrive)

Per-tier checklist. Do not start §5 build until every item below is checked.

### Maxon stack

- [ ] EC-i 30 spins by hand smoothly (no detent grit; flat-rotor = should feel almost free)
- [ ] GP 32 HP mates to EC-i 30 face — **measure the front-face PCD and bolt thread ones more time**; if PCD ≠ 27 mm or bolts ≠ M3, return to §1.1 and patch CAD before proceeding
- [ ] ENX 16 EASY encoder rear-mounts to EC-i 30 without obstruction
- [ ] Reducer output shaft turns smoothly when EC-i 30 input is rotated by hand (gear ratio feel: ~14 input turns for 1 output)

### Service-bureau print

- [ ] All 5 fingers + palm + bracket arrived in one piece (no support residue inside tendon channels)
- [ ] Joint barrels accept Misumi PB3-12 dowel pin with hand pressure (slip fit, not press fit)
- [ ] Bushing pockets accept 8458K71 with light tap (the flange counterbore added in v0.1.1 fix #10 should seat the flange flush)
- [ ] Tendon channel runs clear end-to-end on each phalanx — pass a stiff wire through to confirm no support material clogged the 1.6 mm channel
- [ ] Palm motor mount holes (4× on Ø25) match the bracket palm-side holes — bolt the bracket to the palm dry, no fasteners other than M2.5 SHCS

### Aluminum bracket

- [ ] Motor-side counterbores accept M3 SHCS heads flush
- [ ] Palm-side holes align with palm fix #1 pattern — dry-bolt to confirm
- [ ] Total mass ≤ 100 g (target ~80 g)

### Misumi pulleys + dowels

- [ ] PB3-12 length actually ≤ 12 mm (audit fix #8 assumed; verify with calipers)
- [ ] MBPB8-3-2 spins on a 3 mm shaft without binding

---

## 5. Build sequence

Follow [`hand-v0.1-assembly.md`](hand-v0.1-assembly.html) sections in order, with these v0.1.1-specific notes:

| Assembly section | v0.1.1 note |
|------------------|-------------|
| §2 Skeleton subassembly | Drop dowel pin to PB3-12 (shorter than the §3 callout — assembly.md was updated) |
| §3 Joint pinning | E-clip retainer groove zone is now ~1 mm/side (was ~10 mm/side overhang) — confirm E-clips seat in this narrower band |
| §4 Pulley routing | Palm has **3** in-palm pulleys (not 8 per v0.1) plus 5 MCP redirect pulleys (one in each `finger_mcp_mount` pocket added in fix #4 / #12). Total 8 pulleys + 1 spool = 9 routing positions; BOM is 12 (3 spares). |
| §5.1 Motor mount | Motor face is M3 on Ø27 mm (not M2.5 on Ø22) — fix #3 |
| §5.2 Bracket-to-palm | M2.5 on Ø25 mm at 0/90/180/270 — fix #1 |
| §6 Spool installation | Spool effective radius is **4 mm** (not 8). If you cite force budget anywhere downstream, the new figures are ~205 N continuous / ~1562 N peak — fix #5 |
| §7 Tendon routing | Channel runs below joint barrel with a short reroute segment at each joint — fix #11. The tendon should not contact the bushing flange anywhere along its run. |
| §10 Load cell | **The CZL635 does NOT live in the palm in v0.1.1.** It moves forearm-side adjacent to the Moteus n1 — fix #9. Skip this section for the hand build; treat it as forearm-subassembly work. |

For everything not in this table, follow assembly.md as-is.

---

## 6. Bench-test plan

Six-stage smoke test. Pass each before proceeding.

### Stage 1 — Motor + encoder spin-up (no load)

Goal: confirm the Moteus n1 talks to the EC-i 30 + ENX 16 EASY + AS5048A.

1. Mount the motor + reducer + spool on a bench fixture. Do **not** install in the palm yet.
2. Wire the Moteus n1 via XT30 (24 V supply) and Molex PicoClasp (CAN-FD).
3. Run `moteus_tool --calibrate` from the [moteus host tool](https://github.com/mjbots/moteus). This sweeps the motor for commutation phase and writes `motor_position.config` to the controller. **First failure mode:** wrong pole count for EC-i 30 (it's 8-pole, not the default 14). Set `motor_position.position_min / max` to wide bounds for first calibration.
4. Issue position commands of ±0.25 turns at the spool; confirm the AS5048A reports motion via `moteus_tool --read-data`. If the encoder reports backward, flip the diametric magnet.

Expected: smooth motion, ≤2 mNm cogging at zero current.

### Stage 2 — Single-finger pull (no synergy)

Goal: confirm one finger flexes through full range when its tendon is pulled directly by hand.

1. Install one finger (proximal + middle + distal phalanges, three dowels, three return springs, three bushings × 6) into one MCP slot on the palm.
2. Route a single Spectra line from a hand-held loop through the MCP redirect pulley → through the finger's tendon channel → terminate at the distal tip.
3. Pull by hand. The finger should curl from open (springs at 90°) to fully closed (~270° wrap). Pull force at full closure ~5–10 N if the audit's torsion-spring math is right.
4. Release. Springs should return the finger to open in <1 s, no stick-slip.

**v0.1.1 risk:** the tendon channel's joint reroute (fix #11) is geometric speculation. If the cable jams or grinds at a joint, the reroute geometry is wrong — capture exactly where, and feed back to v0.1.2.

### Stage 3 — All 5 fingers, manual synergy

Same as stage 2 but five fingers in parallel, all five cables joined at a single eye splice (the synergy junction).

Pull the synergy line by hand. All 5 fingers should close concurrently in roughly the Pisa-IIT SoftHand grasp synergy (thumb opposes; index/middle close first; ring/pinky trail).

If any finger lags or leads >100 ms behind the others, the routing pulley friction is unequal across fingers. Capture per-finger at-rest tendon path lengths.

### Stage 4 — Motor-driven synergy

Connect the motor's spool to the synergy junction. Issue a Moteus position command for spool rotation = +1 turn (~25 mm of cable take-up at 4 mm radius — closes from open to grasp).

Smoke test: one slow close-and-release cycle. Watch for cable wrap quality (no overlap on the spool), pulley alignment (no cable jumping out of grooves), and finger sequencing.

### Stage 5 — Tension control loop (forearm-side load cell)

This stage requires the forearm subassembly with the CZL635 + HX711 inline at the synergy junction. **If forearm subassembly is not built yet, skip and document that v0.1.1 hand bench test is open-loop only.**

With the load cell wired: command spool position closed enough to develop ~50 N cable tension, hold for 30 s. Tension reading should be stable to ±2 N. Spool position-current loop should not drift.

### Stage 6 — Cycle test (24-hour soak)

Run `close → 50 N hold 5 s → release → idle 5 s` in a loop for 24 hours. Pass conditions:
- No cable abrasion failure
- No bushing wear visible by eye
- No spring fatigue (return time stable)
- No phalanx PA12 fracture at high-stress points (audit flagged the palm tendon channel as a structural risk in v0.1)

This is the test that converts v0.1.1 from "paper" to "validated reference design."

---

## 7. First-build feedback to capture for v0.1.2

This is the part of the runbook that closes the descriptor → CAD → physical → descriptor loop. Capture these in a `chassis/hand-v0.1.1-build-log.md` as you go:

1. **Print fit-up exceptions:** any Misumi/McMaster/Maxon part that didn't fit the matching CAD pocket within 0.1 mm. These become parameter updates in `hand_params.scad`.
2. **Tendon path measurement:** rest length and at-grasp length per finger. The descriptor's `spool_radius_m` derives a take-up budget; physical reality is the truth.
3. **Cable tension at synergy junction vs. command:** linearity, hysteresis, friction loss across the 9-pulley network. Friction coefficient for the in-palm bushings is one of the largest unknowns in the descriptor's torque-to-force model.
4. **Spring fatigue cycles:** how many open/close cycles before any of the 15 torsion springs softens >10%. Lee Spring's spec doesn't give cycle life at this load profile — empirical measurement is the only path.
5. **PA12 wear surfaces:** photograph dorsal/palmar tendon channels and bushing pockets every 1000 cycles. v0.1 audit issue #11 (deferred portions) and the "PA12 cycle life under sliding contact" question are entirely empirical.
6. **Audit deferred-issue impacts:** the audit deferred items #12, #13, #15, #16, #17, #23, #25, #26, #27. For each, log whether it surfaced as a real defect during build.

Write the build log openly. The log itself is a defensive-publication artifact for the corpus.

---

## 8. Known risks (post-v0.1.1)

| Risk | Source | Mitigation in build |
|------|--------|---------------------|
| Maxon front-face PCD assumption is wrong | Audit #3 (v0.1.1 used best-guess; not pulled from current Maxon drawing) | §1.1 verification gate before order |
| PA12 tendon channel wear under cyclic load | Audit #11 partial (path rerouted but material is still PA12) | Stage 6 cycle test; expect to relocate channel inserts to milled aluminum if wear is excessive |
| Pulley bend radius < tendon spec minimum | Audit #23 (deferred to v0.1.2) | Accept Samson's reduced cycle life for v0.1.1; upsize to Ø16 mm pulleys in v0.1.2 if cycle test shows premature cable failure |
| Spring fatigue at synergy junction | Lee Spring spec gap | Stage 6 cycle test |
| LEMO 0B connector stripped under arm motion | Forearm subassembly has not been built yet | Force-test connector retention before integration |
| Skin mold dimensional accuracy | Audit #16, #17 (deferred — proxy mold geometry, no skeleton registration) | Pour skin only after mechanical bench tests pass; skin is cosmetic for v0.1.1 |

---

## 9. Cost summary

Net build cost — one prototype hand:

- BOM hard goods: **~$2,288** (excludes optional CNC mill — the $180 line item is optional if SLS PA12 channels are deemed sufficient)
- Plus shipping/handling: included in the $65 line at line 36
- Plus optional aluminum mill: **+$180** if pursued
- Plus desktop sanity-check filament: **~$2** (PLA, off the existing spool)
- **Total: ~$2,290–$2,470 for one prototype hand.**

If costs are a constraint, the Molex Mini-Fit Jr 8-circuit at ~$8/pair substitutes for the LEMO at $140/pair, dropping BOM to ~$2,150.

---

## 10. Cross-references

- [Hand v0.1 audit (historical)](hand-v0.1-cad-audit.html) — original 30-finding audit; v0.1.1 footer references this runbook
- [Hand v0.1.1 fixes](hand-v0.1.1-fixes.html) — diff log of what changed CAD-side
- [Hand v0.1 assembly walkthrough](hand-v0.1-assembly.html) — section-by-section build steps
- [BOM](hand-v0.1-BOM.csv) — 31-line bill of materials
- [Architecture §2.9 Manipulation](../ARCHITECTURE.md#29-manipulation) and [§9 commitments](../ARCHITECTURE.md#9-architectural-commitments)
- Corpus prior art chains: [`pisa-iit-softhand`](https://openie-dev.github.io/free-humanoid-corpus/), [`shadow-dexterous-hand`](https://openie-dev.github.io/free-humanoid-corpus/), [`dlr-hand-arm-system-2011`](https://openie-dev.github.io/free-humanoid-corpus/), [`yale-reflex-openhand-2014`](https://openie-dev.github.io/free-humanoid-corpus/), [`pisa-iit-softhand-2`](https://openie-dev.github.io/free-humanoid-corpus/), [`inmoov-hand-2012`](https://openie-dev.github.io/free-humanoid-corpus/)

---

## License

Apache-2.0 / CC-BY-SA 4.0 / CC0-1.0 / CERN-OHL-S 2.0 — per the family license overlay.
