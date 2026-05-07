---
title: Hand v0.1 — Assembly Reference
layout: default
nav_order: 11
permalink: /chassis/hand-v0.1-assembly.html
---

# Hand v0.1 — Assembly Reference
{: .no_toc }

> **REFERENCE document. Not yet validated by physical build.** This is the paired assembly walkthrough for [`hand-v0.1-BOM.csv`](hand-v0.1-BOM.csv). It exists to make the v0.1 hand subassembly tractable to a real builder. Every dimension, torque value, and procedure described here is a starting point for empirical iteration, not a tested specification. See [`../ARCHITECTURE.md` §2.9](../ARCHITECTURE.md#29-manipulation) and [§9 commitment #4](../ARCHITECTURE.md#9-architectural-commitments) for the architectural framing. Corpus citations: [`pisa-iit-softhand`](../prior-art/INDEX.md), [`shadow-dexterous-hand`](../prior-art/INDEX.md), [`da-vinci-knight`](../prior-art/INDEX.md), [`mjbots-moteus`](../prior-art/INDEX.md), [`act-aloha`](../prior-art/INDEX.md), [`gelsight`](../prior-art/INDEX.md).

<details open markdown="block">
  <summary>Contents</summary>
  {: .text-delta }
- TOC
{:toc}
</details>

---

## 0. Scope and design intent

This subassembly is the v0.1 free-humanoid hand: an underactuated, synergy-reduced, 5-finger anthropomorphic hand driven by a single brushless motor. It implements architectural commitment #4 (Pisa-IIT SoftHand class). One Maxon EC-i 30 with a GP 32 HP 14:1 planetary head spools a single Spectra synergy tendon that closes all five fingers in a coordinated power-grasp posture. Passive torsion springs at every phalanx joint return the hand to an open posture when the cable is slack. A magnetic encoder on the spool gives motor-side position; an inline load cell at the synergy terminator gives true cable tension. The Moteus n1 controller closes a position-and-current loop over CAN-FD; the synergy-grasp policy lives one layer above on the wrist controller (or in the case of bench bring-up, on a Joule SOM dev kit).

Total of 6 mechanical DoF in the hand (5 fingers MCP + 4 PIP/DIP coupling per finger via passive joint coupling) collapses to **1 motor DoF** through the synergy network. Adopting `pisa-iit-softhand`'s underactuation lineage means the BOM is a single drive subsystem instead of 6–20 servos as in `shadow-dexterous-hand`, with proportional reduction in cost, mass, and wiring.

---

## 1. Tools required

**Mechanical:**
- Hex driver set, metric (1.5–4 mm), torque-limited (preferred: Wera 7400 series or equivalent)
- Bench vise with soft jaws
- Pin punch set, 2–4 mm
- Snap-ring pliers, internal and external
- Calipers, 0.01 mm resolution (Mitutoyo or equivalent)
- Small jewelers' files
- Heat gun (300 °C class) for heat-shrink and Spectra terminal sealing
- Soldering iron (350 °C, 0.5 mm conical tip) for harness work

**Tendon-specific:**
- Fid (small, for splicing AmSteel-Blue if you choose to splice rather than terminate by knot+heat)
- Pre-stretch jig: any rigid frame with two anchor points 2 m apart, ideally with a calibrated tension gauge

**Skin-casting:**
- Two-part silicone scale (0.1 g resolution)
- Mixing cups, stirring sticks
- Vacuum degas chamber (5–10 cfm pump, ~–29 inHg) — *strongly recommended*; without it expect bubble defects in the skin
- Mold-release spray (Smooth-On Universal Mold Release or equivalent)

**Electronics:**
- Bench supply, 24 V at ≥10 A, current-limited
- Multimeter
- Oscilloscope (recommended for FOC commissioning, not strictly required)
- USB-CAN-FD adapter (mjbots fdcanusb or equivalent) for Moteus n1 commissioning
- Computer running `moteus_tool` (Python, mjbots' open-source toolchain)

**Documentation:**
- Print-out of [`hand-v0.1-cad-references.md`](hand-v0.1-cad-references.md) and the BOM
- The corpus entries above for reference geometry guidance

---

## 2. Pre-assembly: skeleton printing/milling, skin mold prep

### 2.1 Skeleton

The skeleton is split into:
- **5 finger sets** (proximal, middle, distal phalanx per finger; thumb has 2 phalanges + carpometacarpal block)
- **Palm housing** (encloses motor mount face, synergy junction, tendon-routing channels)
- **Wrist coupler** (mates to the wrist roll output of the forearm; carries the LEMO bulkhead)

Print the PA12 parts via HP MJF or SLS at a service bureau (Hubs, Shapeways, Materialise) with the following process notes:

- **Part orientation:** orient phalanges with their long axis vertical; this minimises stair-step on the joint axle bores
- **Tolerances:** call out **+0.10 mm / −0.05 mm on bearing bores**, post-process with a 3 mm reamer to final size
- **Finish:** standard bead-blast acceptable; vapor-smoothing optional for cosmetic outer surfaces
- Order at least **two complete sets** so a build mistake on one doesn't block bring-up

For the high-load tendon-routing channel inserts in the palm (where the synergy tendon makes its sharpest bend), use **6061-T6 aluminum stock**, milled per the DXF in [`hand-v0.1-cad-references.md`](hand-v0.1-cad-references.md). These bear the highest cycle-loaded contact stress and are the first thing to wear in a SLS-only build. As an interim measure, the v0.1 prototype can run with PA12 channels and accept reduced cycle life until the milled inserts arrive.

### 2.2 Skin mold

The skin is a one-piece silicone glove with reinforced fingertip pads. Two-part silicone mold:
- **Outer mold:** PA12-printed clamshell, two halves bolted with M3 SHCS through registered bosses, parting-line on the dorsal centerline
- **Inner core (positive):** matches the skeleton outer profile + 1.5 mm uniform offset everywhere except fingertips (3.0 mm)

Treat both halves of the mold and the core with mold release before each cast. The skin shell will be poured around the assembled (and tendon-routed) skeleton in Phase 4; Phase 0 is just preparing the molds and confirming they close cleanly.

---

## 3. Phase 1: skeleton joint assembly with axles + bushings + return springs

For each of the 15 phalanx joints (5 fingers × 3 joints, with the thumb's 2 joints counted plus a CMC block — total 14 to 16 depending on thumb topology; the BOM allots 15 dowels with 1 spare):

1. **Press-fit a flanged bronze bushing** (8458K71 equivalent, 3 mm ID) into each side of the proximal joint bore. Light film of Krytox GPL 205 on the bushing OD eases the press fit. Confirm the flange seats flush.
2. **Fit the torsion spring** (Lee Spring LTR-040A-04S equivalent) over the joint axis. The free leg of the spring engages a small slot on the proximal phalanx; the active leg bears against the distal phalanx face such that the spring biases the joint toward the **open / extended** posture. Pre-load of ~5–10° is acceptable; do not exceed the spring's rated angular deflection.
3. **Slide the 3 mm dowel pin** (Misumi PB3-12-NN-A — 12 mm length, sized to the 10 mm joint barrel + 1 mm/side E-clip overhang per v0.1.1 fix #8) through both bushings + the spring. Light Krytox on the pin.
4. **Retain the pin** with a small 3 mm E-clip or with a captive-screw retainer geometry built into the printed phalanx (preferred — eliminates a part). Confirm the joint moves freely with ~0.05–0.15 N·m breakaway friction.
5. **Smoke-test the joint** by manually closing it 50× and inspecting for binding, bushing migration, or spring chatter.

Repeat for all 15 joints. Total elapsed time on a first build: ~3 hours.

---

## 4. Phase 2: tendon routing through PEEK pulleys

The synergy tendon is a single continuous AmSteel-Blue cable that runs from the motor spool through the palm, branches at the synergy junction in the palm into 5 sub-paths, threads each finger from MCP to fingertip, and terminates at a thimble at each fingertip with a tied + heat-sealed knot.

> **Key design choice:** the v0.1 hand uses a **fixed-ratio mechanical synergy** rather than a **soft synergy** (in which the same cable spools at different rates by passing over differential pulleys). The fixed-ratio variant is simpler to build and debug; the differential variant is the upgrade path for v0.2.

### 4.1 Pre-stretch the cable

UHMWPE cable creeps under load. Pre-stretch the full ~3 m length on the bench under ~50% of the working load (~50 N) for at least 30 minutes before final routing. Mark a reference point at each end before pre-stretch; the line will lengthen ~0.5–1.5%.

### 4.2 Install pulleys

The 12 PEEK pulleys (Misumi MBPB8-3-2 equivalent) seat on 3 mm dowel-pin pivots in the palm and at each MCP joint:
- **Spool pulley** (1) on the motor output shaft, integrated into the spool spindle
- **Synergy junction pulleys** (2–3) at the palm centroid where the single cable branches into 5 sub-paths
- **MCP redirect pulleys** (5, one per finger) where the tendon transitions from palm channel to finger channel
- **Spare** (3) for in-build replacement

Lubricate each pulley axle with a single drop of Krytox before installation. Confirm each pulley spins freely under no load with ~5–15 g·cm bearing drag.

### 4.3 Route the cable

Working from the spool outward:

1. Anchor one end of the cable at the spool with a single full wrap + a heat-sealed bowline. Spool 5–10 cm of cable around the spool (this is the takeup reservoir).
2. Run the cable through the first synergy junction pulley.
3. At the synergy junction, the cable splits into 5 sub-paths. The split is mechanical: the cable wraps a **central distribution drum** in the synergy junction such that as the drum rotates, all five outgoing sub-cables pay out in lockstep. (This is the classic Pisa-IIT SoftHand mechanism — see `pisa-iit-softhand` corpus entry for the geometric detail.) For v0.1 the distribution drum is PA12-printed with PEEK pulleys at each output.
4. Each of the 5 sub-cables then passes through that finger's MCP redirect pulley and threads through the inner channel of the proximal, middle, and distal phalanges.
5. Terminate each sub-cable at the distal-phalanx fingertip with a thimble + figure-8 knot, then heat-seal the tail with the heat gun.

Each cable should sit slack at full hand-open posture (return springs holding the joints open) and pull taut to begin closing the finger when the spool rotates 1/4 turn.

---

## 5. Phase 3: motor + Moteus controller + harness wiring

### 5.1 Motor + reducer assembly

Mount the Maxon GP 32 HP 14:1 planetary head to the EC-i 30 motor face per Maxon's mounting note (no shims required for the GP-32-to-EC-i-30 paired flange). Torque the four M3 mounting screws (4× M3 on PCD 27 mm per Maxon GP 32 HP cat 166940 — v0.1.1 fix #3, corrected from prior M2.5/PCD 22 mm) to 1.0 N·m with Loctite 222.

### 5.2 Motor mount bracket

Bolt the milled aluminum motor mount bracket (Phase 0 prep) into the palm housing using four M2.5 SHCS at 0.5 N·m on PCD 25 mm at 0/90/180/270 (v0.1.1 fix #1: bracket-to-palm bolt circle aligned with palm; the bracket-to-motor face is a separate, smaller 4× M3 PCD 27 pattern internal to the bracket). Confirm the motor output shaft is concentric with the spool axis to within 0.1 mm; misalignment of >0.2 mm will cause cable mis-tracking on the spool.

### 5.3 Spool + AS5048A magnet

Install the spool on the planetary output shaft. Adhere the diametrically magnetised N35H magnet to the rear of the spool (or to the motor rear-shaft if the EC-i 30 variant has one) using two-part epoxy. The AS5048A magnetic encoder PCB sits 0.5–1.5 mm from the magnet face; confirm with calipers.

### 5.4 Moteus n1 wiring

The Moteus n1 lives in the palm housing or just upstream in the forearm — for v0.1 we recommend forearm-side mounting (more thermal headroom, shorter motor leads, the LEMO connector becomes a clean separation interface for hand-swap).

| Moteus n1 pin | Function | Wire to |
|---|---|---|
| Power+ | 24 V in | XT30 from arm rail |
| Power− | GND | XT30 from arm rail |
| Phase A/B/C | 3-phase to motor | EC-i 30 motor leads |
| CAN-FD H, L | bus | Forearm CAN-FD spine |
| AUX SPI | AS5048A | 4 wires: 3.3 V, GND, MOSI, MISO, SCK, CS |
| AUX I2C | HX711 → CZL635 | 4 wires: 3.3 V, GND, DT, SCK |

Twist all signal pairs and use shielded silicone wire across the LEMO bulkhead. Fit ferrites on the motor leads at the controller end.

### 5.5 Initial power-up smoke test

Bench-power the controller from a current-limited 24 V supply (~2 A limit). Run `moteus_tool --target=N --info`; confirm the controller boots and reports its serial number. Do not yet command motion.

---

## 6. Phase 4: skin casting and bonding to skeleton

After Phases 1–3 are complete and the bare skeleton + tendon assembly passes a manual cycle test (see §10):

1. **Mask** the AS5048A PCB, the load cell, the Moteus n1, and all electrical connectors with Kapton or PTFE tape. Silicone is hard to get back off.
2. **Apply Sil-Poxy** to the dorsal side of each phalanx and the dorsal palm surface. This is the bonded interface between PA12 and the silicone skin.
3. **Mix Dragon Skin 30** by weight per the Smooth-On data sheet (1A:1B). For one hand, ~150 g total mix is sufficient. Add ~1 wt% So-Strong pigment if desired.
4. **Vacuum-degas** the mixed silicone for 2–4 minutes at −29 inHg until the foam collapses.
5. **Pour into the closed mold** through the wrist port. The skeleton is already inside the closed mold. Air pockets vent through the fingertip vent holes (4 mm dia in the mold core).
6. **Cure** at room temperature for 16 hours, or 1 hour at 65 °C in an oven. Don't demold early; partial cure means the skin tears at the next bring-up.
7. **Demold** by separating the mold halves and gently peeling the core off the palm interior. The skin remains bonded to the dorsal phalanges and palm via the Sil-Poxy layer.

Inspect the cast skin for bubbles, tears, or unbonded sections. Small bubbles are cosmetic; tears at the fingertip are not — recast if any tear penetrates >50% of the wall.

---

## 7. Phase 5: position-sensor + tension-sensor calibration

### 7.1 AS5048A position sensor

Power up the controller. Run `moteus_tool --target=N --calibrate`. The Moteus firmware will spin the motor open-loop, sample the encoder, and fit the commutation offset. The fit's RMS residual should be <2 deg electrical; if not, the magnet is mis-positioned or the encoder mounting distance is off — re-seat the magnet.

### 7.2 CZL635 cable-tension sensor

The HX711 returns a raw 24-bit signed count. Calibrate by hanging known masses (100 g, 500 g, 1 kg) from the cable terminator with the hand fully extended:

1. Record raw count at zero load (tare offset)
2. Record raw count at each test mass
3. Linear-fit: `tension_N = (raw − tare) × scale_factor`
4. Store `tare` and `scale_factor` in the Moteus aux config or on the upstream Joule SOM

Repeat the calibration after the first 100 cycles — UHMWPE cable creep will shift the no-load tare.

---

## 8. Phase 6: bring-up — Moteus tuning, synergy-grasp baseline test

### 8.1 Moteus FOC tuning

Use `moteus_tool` to:
1. Set `servo.max_position_slip` to ~0.2 rev (allows the synergy mechanism to back-drive without faulting)
2. Set `servo.max_velocity` to 30 rad/s motor-side (~2 rad/s output-side at 14:1)
3. Set `servo.max_current_A` initially to 2 A; raise once thermal performance is characterised
4. Position-loop kp = 1.0, kd = 0.05; iterate empirically

### 8.2 First grasp

Command position 0.0 → 0.5 rev (motor-side) at 5 rad/s. The hand should close from open to soft-fist posture. Watch for:
- Cable tension monotonically rising with position command
- All 5 fingers closing roughly synchronously (within ~10° of each other at the MCP)
- No cable jumping off any pulley (audible clicking is a tell)

If a finger lags >20° behind the others, the synergy distribution drum tension is mis-balanced or that finger's path has unusually high friction — disassemble and re-route that path's pulleys.

### 8.3 Synergy-grasp characterisation

With a calibrated touch sensor or human finger as a reference, measure:
- Grip force vs. position-command curve (output of the load cell × kinematic gear ratio of the synergy distribution)
- Time-to-close from open to full fist (target: <500 ms for a useful manipulation policy)
- Hold-current at steady-state grasp (target: <0.5 A continuous to avoid motor thermal saturation)

Record these as the v0.1 baseline. Subsequent UDD descriptor iterations should match.

---

## 9. Common failure modes and how to debug

| Symptom | Likely cause | Fix |
|---|---|---|
| Encoder calibration RMS >5 deg | Magnet eccentric or air gap >2 mm | Re-seat magnet, use feeler gauge to set 0.5–1.5 mm air gap |
| Cable jumps off pulley during close | Pulley flange too shallow, or cable enters at >15° wrap angle | Substitute a deeper-flanged pulley, or add a guard plate |
| One finger lags >20° behind others | Friction asymmetry in routing path | Re-lubricate that finger's bushings, or check for printed-channel surface defects (file/sand the PA12 channel interior) |
| Tension reading drifts at constant cable load | UHMWPE cable creep | Re-pre-stretch and re-calibrate; expect 0.5–1.0% creep over first 1000 cycles |
| Skin tears at fingertip | Insufficient Sil-Poxy bond, or cure not complete | Recast; ensure 16 hr ambient cure, prime PA12 with mold-release-removed alcohol wipe |
| Moteus reports motor-fault, overtemp | Hold-current too high | Lower max_current; revisit synergy spring stiffness — too stiff a return spring forces continuous holding torque |
| Moteus CAN bus errors | Termination resistor missing | Add 120 Ω termination at the far end of the bus |
| Bushing wear after 1000 cycles | PA12 channels bearing the high-side load | Substitute milled aluminum inserts (planned for v0.1.1) |

---

## 10. Synergy controller calibration procedure

> **v0.1.1 fix #9 — load-cell location.** The Phidgets CZL635 cable-tension load cell lives **forearm-side** adjacent to the Moteus n1 (per §5.4 forearm-side controller mounting), not in the palm. The forearm bracket housing the load cell is a forearm-subassembly artifact — out of scope for the hand v0.1.1 work.
>
> **v0.1.1 fix #5 — cable-force figures, updated.** With `spool_radius_m = 0.004 m` (corrected from 0.008 m to match the BOM 8 mm spool OD), continuous cable force ≈ 0.82 N·m / 0.004 m ≈ **205 N**, peak ≈ 6.25 N·m / 0.004 m ≈ **1562 N**. Both figures are roughly 2× the v0.1 derivations, well within the Spectra cable's tensile envelope but flag larger loads on the in-palm pulley flanges and tendon-channel walls than v0.1 anticipated.

The synergy controller maps a single scalar **grasp-progress** input ∈ [0, 1] to a target spool position and a cable-tension feedforward. The mapping is calibrated in three steps.

1. **Geometric calibration.** With the hand mounted in a calibration jig, measure the spool position at three reference postures: hand-fully-open (`s_open`), hand-soft-fist (`s_soft`), hand-tight-fist (`s_tight`). Linear-interpolate: `position(g) = s_open + g × (s_tight − s_open)`. The mapping is monotonic but not linear in joint space; this is acceptable because the synergy controller treats fingers as a single coordinated DoF.

2. **Tension feedforward.** Hang increasing test masses from the synergy terminator, record `tension(g)` curve. Fit a cubic. Use this as a feedforward to the Moteus current command to reduce position-tracking error.

3. **Cycle-life adjustment.** Every ~500 cycles, re-run step 1's measurement. Adjust `s_open` (UHMWPE creep tends to shift this most) and re-publish the calibration.

The synergy controller as a behaviour lives one layer above the Moteus n1, in the firmware HAL of the upstream controller (Joule SOM dev kit for bench bring-up; main robot compute for integrated build). The behaviour signature matches OpenLoco's `behavior::SynergyGrasp` skill stub (added to OpenLoco as part of Phase 2 deliverables; see ARCHITECTURE.md §5 #2).

---

## 11. References

- [`../ARCHITECTURE.md` §2.9](../ARCHITECTURE.md#29-manipulation) — manipulation subsystem spec
- [`../ARCHITECTURE.md` §9 commitment #4](../ARCHITECTURE.md#9-architectural-commitments) — underactuated 5-finger hand commitment
- [`../prior-art/INDEX.md`](../prior-art/INDEX.md) — corpus shielding chain
- [`hand-v0.1-BOM.csv`](hand-v0.1-BOM.csv) — paired BOM
- [`hand-v0.1-cad-references.md`](hand-v0.1-cad-references.md) — paired CAD pointer

**Corpus citations:**
- `pisa-iit-softhand` (2012) — synergy-based underactuated hand reference. Drives the architectural commitment.
- `shadow-dexterous-hand` (2002) — full-DoF tendon-routed reference. Documents the cable routing topology this hand simplifies.
- `da-vinci-knight` (1495) — 528-year prior-art anchor on tendon-driven anthropomorphic mechanism. Useful as the deepest possible chain anchor against late-issuing tendon-mechanism patents.
- `mjbots-moteus` (2019) — open BLDC controller, defines the CAN-FD command surface.
- `act-aloha` (2023) — imitation-learning reference for manipulation policy training, downstream of this hand.
- `gelsight` (2009) — fingertip tactile reference; tactile integration is a v0.2 follow-up.

---

*Free Humanoid Platform — Hand v0.1 reference assembly — 2026-05-06.*
