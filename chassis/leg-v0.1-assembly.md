---
title: Leg v0.1 — Assembly Reference
layout: default
nav_order: 12
permalink: /chassis/leg-v0.1-assembly.html
---

# Leg v0.1 — Assembly Reference
{: .no_toc }

> **REFERENCE document. Not yet validated by physical build.** This is the paired assembly walkthrough for [`leg-v0.1-BOM.csv`](leg-v0.1-BOM.csv). It exists to make the v0.1 leg subassembly tractable to a real builder. Every dimension, torque value, and procedure described here is a starting point for empirical iteration, not a tested specification. See [`../ARCHITECTURE.md` §2.4](../ARCHITECTURE.md#24-actuators) and [§9 commitment #1](../ARCHITECTURE.md#9-architectural-commitments) for the architectural framing. Corpus citations: [`sumitomo-cyclo`](../prior-art/INDEX.md), [`mit-cheetah-2`](../prior-art/INDEX.md), [`mini-cheetah`](../prior-art/INDEX.md), [`cassie-osu`](../prior-art/INDEX.md), [`mjbots-moteus`](../prior-art/INDEX.md), [`dlr-toro`](../prior-art/INDEX.md), [`sensing-proprioceptive-actuator`](../prior-art/INDEX.md), [`sensing-force-torque`](../prior-art/INDEX.md).

<details open markdown="block">
  <summary>Contents</summary>
  {: .text-delta }
- TOC
{:toc}
</details>

---

## 0. Scope and design intent

This subassembly is the v0.1 free-humanoid leg: a **6-DoF bipedal leg** with cycloidal reducers at hip and knee and quasi-direct-drive (QDD) actuators at the ankle. It implements architectural commitment #1 (hybrid actuator distribution).

Per-joint stack:

| Joint | DoF | Actuator | Reducer | Peak torque target | Corpus shield |
|---|---|---|---|---|---|
| Hip yaw | 1 | Maxon EC-i 50 (200 W, 48 V) | Onvio cycloidal 30:1 | ~80 N·m | `sumitomo-cyclo` |
| Hip abduction | 1 | Maxon EC-i 50 (200 W, 48 V) | Onvio cycloidal 50:1 | ~120 N·m | `sumitomo-cyclo` |
| Hip flexion | 1 | Maxon EC-i 52 (320 W, 48 V) | Onvio cycloidal 50:1 (HT) | ~150 N·m | `sumitomo-cyclo` |
| Knee flexion | 1 | Maxon EC-i 50 (200 W, 48 V) | Onvio cycloidal 30:1 (HT) | ~150 N·m | `sumitomo-cyclo` |
| Ankle pitch | 1 | T-Motor U8 Lite KV150 + Maxon GP 32 HP 6.6:1 | single-stage planetary | ~40 N·m | `mini-cheetah` |
| Ankle roll | 1 | T-Motor U8 Lite KV150 + Maxon GP 32 HP 6.6:1 | single-stage planetary | ~40 N·m | `mini-cheetah` |

The hip + knee cycloidals are non-backdrivable (or weakly backdrivable) but high torque density; the ankle QDDs are backdrivable for ground-impact compliance, matching the Mini Cheetah lineage. Force-torque at the foot (ATI Mini40 or in-house substitute) closes the high-bandwidth ground-reaction-force loop. CAN-FD bus over Moteus controllers; 48 V power bus from a torso BMS.

**Total v0.1 build cost:** ~$15,400 with ATI Mini40 foot FT; ~$9,800 with in-house strain-gauge foot substitute. The cycloidal reducers (~$1,900) and BLDC motors (~$2,740) dominate the budget. **The leg pair doubles all of this.**

---

## 1. Tools required

**Mechanical:**
- Hex/Torx driver set, metric (1.5–8 mm), torque-limited (Wera 7400 or equivalent), with calibrated torque values up to 25 N·m for the M8 hip-to-torso bolts
- Bench vise with soft jaws, ≥ 200 mm jaw opening (the femur tube is 450 mm)
- Pin punch set, 3–8 mm
- Snap-ring pliers, internal and external
- Calipers, 0.01 mm resolution (Mitutoyo or equivalent)
- Bearing puller (10–60 mm range) for cycloidal output bearings
- Dial indicator + magnetic base for cycloidal output runout verification
- Heat gun (300 °C class) for heat-shrink and bearing shrink-fit
- Soldering iron (350 °C, fine + medium tips) for power and signal harness work
- Crimp tool for XT60 / Molex PicoClasp / LEMO solder-cup terminations

**Cycloidal-specific:**
- Bearing press (arbor press, ≥ 1 ton) for cycloidal output bearings
- Reducer-cavity grease gun preloaded with Krytox GPL 226
- Torque wrench, 1–25 N·m range, for cycloidal flange bolts (M5 = 5 N·m, M6 = 10 N·m typical)

**Foot pad:**
- Two-part silicone scale (0.1 g resolution)
- Mixing cups, stirring sticks
- Vacuum degas chamber (5–10 cfm pump, ~–29 inHg) — strongly recommended; Dragon Skin 50 traps more bubbles than Dragon Skin 30
- Mold-release spray
- Foot-plate-sized casting dam (3D-printed PA12 or laser-cut acrylic)

**Electronics:**
- Bench supply, 48 V at ≥ 30 A, current-limited (Mean Well RSP-1500-48 or equivalent)
- Multimeter
- Oscilloscope for FOC commissioning
- USB-CAN-FD adapter (mjbots fdcanusb or equivalent)
- Computer running `moteus_tool` (Python, mjbots' open-source toolchain)

**Documentation:**
- Print-out of [`leg-v0.1-BOM.csv`](leg-v0.1-BOM.csv) and the cycloidal vendor mounting drawings
- The corpus entries above for reference geometry guidance
- [`../descriptor/free-humanoid.udd.json`](../descriptor/free-humanoid.udd.json) actuator-slot block for tier and CAN-ID assignments

---

## 2. Phase 1 — Foot subassembly

### 2.1 Foot plate inspection

Receive the milled aluminum foot plate (BOM `foot_plate`, 150 × 100 × 8 mm). Inspect for:
- Flatness ≤ 0.10 mm across the contact face (the silicone bond face)
- M4 thread quality on the FT-sensor mount pattern (if using ATI Mini40, 4× M4 on 30 mm bolt circle per ATI mounting drawing)
- No burrs on the silicone bond face — bead-blast or scotch-brite to ~Ra 1.6 µm to give Sil-Poxy mechanical bond surface

### 2.2 Force-torque sensor mount

If using **ATI Mini40** (BOM `foot_force_torque`):
1. Bolt the Mini40 lower flange to the foot plate using 4× M4 SHCS, 6 mm length, with Loctite 243. Torque to 2.5 N·m (M4 stainless into aluminum tapped hole).
2. The Mini40 upper flange becomes the ankle-roll yoke mount; do not bolt yet — that happens in Phase 2.
3. Route the FT signal cable up the tibia tube cavity (see Phase 7).

If using **in-house strain-gauge foot** (BOM substitution):
1. Adhere four 350 Ω foil strain gauges (one per quadrant of the foot plate underside) using cyanoacrylate.
2. Wire as a Wheatstone bridge per BOM `hip_yaw_torque_sensor` HX711 schematic.
3. This gives 1-axis vertical force only; lateral and torque axes are inferred by IMU + ankle motor current. Acceptable for v0.1 stand-and-balance but degrades walking gait quality.

### 2.3 Silicone foot pad casting

1. Build a casting dam around the foot plate underside (3 mm tall containment wall).
2. Apply Sil-Poxy primer to the bond face per the manufacturer's instructions; cure 30 min.
3. Mix 1:1 Dragon Skin 50 parts A + B by weight, ~80 g batch.
4. Vacuum degas at 28 inHg for 3 min until bubbling stops.
5. Pour into the dam, manipulate to fill all bond patterning. Final pad thickness ~5 mm.
6. Cure 16 h at room temperature (or 1 h at 65 °C).
7. After cure, trim the dam-line flash with a fresh razor.

---

## 3. Phase 2 — Ankle (2-DoF QDD stack)

The ankle is a serial 2-DoF wrist-style cluster: pitch axis (sagittal-plane up/down) followed by roll axis (frontal-plane in/out), with the foot plate distal to the roll axis.

### 3.1 Ankle-pitch QDD assembly

1. Mate the **Maxon GP 32 HP 6.6:1 planetary head** (BOM `ankle_pitch_qdd_planetary`) to the **T-Motor U8 Lite** (BOM `ankle_pitch_qdd_motor`) via the planetary's input flange. The U8 has a 12 mm output shaft; the GP 32 HP input is 4 mm — a custom bushing-type shaft adapter is required (machine from 4140 stock, 12 mm OD × 4 mm ID). This is **the single most fragile coupling in the leg** — confirm concentricity within 0.05 mm at the dial indicator before proceeding.
2. Bolt the planetary output flange to the ankle-pitch housing (BOM `ankle_pitch_housing`) using 4× M3 SHCS, 8 mm, Loctite 243, torque 1.5 N·m.
3. Press the AS5048A magnet (6 mm dia × 2.5 mm) into the planetary output shaft. Apply Loctite 638 retaining compound to the press fit.
4. Mount the AS5048A PCB to the ankle-pitch housing with a 1.0 ± 0.2 mm air gap to the magnet. Verify with a feeler gauge.
5. Install the Moteus c1 controller on the ankle-pitch housing — the c1 form factor lets it sit between the motor body and the housing wall, reducing harness routing complexity.

### 3.2 Ankle-roll QDD assembly

Repeat §3.1 with the ankle-roll components (BOM `ankle_roll_qdd_*`). The ankle-roll yoke is **machined as a U-shape** (BOM `ankle_roll_housing`) so its two arms straddle the foot plate above the FT sensor flange.

### 3.3 Pitch + roll cluster integration

1. Bolt the ankle-roll yoke to the FT sensor upper flange (or to the foot plate if no FT) using 4× M4 SHCS.
2. Mate the ankle-pitch output flange to the proximal end of the ankle-roll yoke. The kinematic axes intersect at a single point ~30 mm above the FT sensor — this is the **ankle center**.
3. Verify free rotation of both axes through their full ±0.5 rad (roll) / ±1.0 rad (pitch) range without binding.

---

## 4. Phase 3 — Tibia tube + ankle integration

1. Receive the **tibia tube** (BOM `tibia_tube`, 32 mm OD × 3 mm wall × 420 mm) and **tibia end-caps** (BOM `tibia_endcap`).
2. Bond the lower end-cap into the tibia tube using Loctite 638 retaining compound; press fit, cure 24 h. Verify concentricity ≤ 0.05 mm TIR.
3. The lower end-cap mates to the ankle-pitch housing input side. Bolt with 4× M5 SHCS, 12 mm, Loctite 243, torque 5 N·m.
4. Bond the upper end-cap into the tibia tube — this is the knee output mate. Same procedure as the lower cap.

The shank now exists as a self-contained subassembly: tibia tube + ankle 2-DoF + foot plate + FT sensor + foot pad. **Bench-test each ankle joint** by power-cycling the Moteus c1 with the bench supply; commutation calibration follows in Phase 8 once the full leg harness is in place, but a basic free-rotation test now catches mechanical binding.

---

## 5. Phase 4 — Knee joint (cycloidal + motor + sensor stack)

The knee uses an **Onvio RV-E-30E-HT cycloidal reducer** (BOM `knee_reducer`) with a Maxon EC-i 50 motor input. The cycloidal gives ~150 N·m peak with backlash ≤ 1 arc-min, suitable for stair-climb torque transients without backlash chatter on direction reversal.

1. Inspect the cycloidal: check the input shaft (typically 14 mm ID with keyway) and output flange bolt pattern (typically 4× M5 on a 50 mm PCD — verify against vendor drawing).
2. Mate the **EC-i 50 motor** (BOM `knee_motor`) to the cycloidal input. Use a flexible jaw coupling (Lovejoy L-070 class) to absorb shaft misalignment — the EC-i 50 output is 8 mm; the cycloidal input is 14 mm.
3. Bolt the cycloidal body to the knee housing (BOM `knee_housing`) using 4× M5 SHCS with Loctite 243, torque 8 N·m.
4. Press the **6907-2RS bearings** (BOM `knee_bearings`) into the housing, preloaded against the cycloidal output flange. **Cycloidal preload is the critical assembly parameter** — too loose causes output runout under torque (cycle-to-cycle position error); too tight overheats and shortens reducer life. Aim for 30–50 N axial preload via a wave washer behind the outer race.
5. Press the AS5048A magnet into the cycloidal output flange center. Verify the magnet is diametrically magnetised; the AS5048A is sensitive to vertical-magnetisation inserts being installed off-axis.
6. Mount the AS5048A PCB on the knee housing distal face with 1.0 ± 0.2 mm air gap.
7. Optional: install the strain-gauge bridge (BOM `knee_torque_sensor`) on the cycloidal output flange spokes. Bond gauges with cyanoacrylate; route signal wires through a strain-relief loop to the Moteus n1 — the n1 has a spare ADC input that the firmware exposes to the host over CAN-FD.
8. Mount the **Moteus n1 controller** (BOM `knee_controller`) on the knee housing using 2× M3 SHCS into tapped standoffs. Plug in the motor 3-phase + the AS5048A SPI + the strain-gauge ADC.

---

## 6. Phase 5 — Femur tube + knee integration

1. Receive the **femur tube** (BOM `femur_tube`, 38 mm OD × 3.2 mm wall × 450 mm) and **femur end-caps** (BOM `femur_endcap`).
2. Bond the lower end-cap (knee-side) into the femur tube. Verify concentricity ≤ 0.05 mm TIR.
3. Bolt the lower femur end-cap to the knee housing input side (the side opposite the cycloidal output) using 4× M5 SHCS, 12 mm, Loctite 243, torque 5 N·m.
4. Mate the knee output flange to the upper tibia end-cap (already installed in Phase 3). The femur + knee + tibia + ankle + foot now exists as a single chained subassembly.
5. The femur upper end-cap mates to the hip-flexion output, in Phase 6.

---

## 7. Phase 6 — Hip joints (3-DoF) and torso interface plate

The hip is the most kinematically intricate part of the leg: three serial revolute joints (yaw, abduction, flexion) cluster within a ~150 mm cube, oriented so their axes intersect at the **hip center**. Mini Cheetah and Cassie use a similar architecture; the axis-intersection geometry simplifies inverse kinematics and reduces parasitic moments.

### 7.1 Hip-flexion (innermost) assembly

1. Stack the hip-flexion cycloidal (BOM `hip_flex_reducer`, 50:1 HT) + motor (BOM `hip_flex_motor`, EC-i 52 320 W) + Moteus n1 (BOM `hip_flex_controller`) into the hip-flex housing (BOM `hip_flex_housing`).
2. Procedure mirrors Phase 4 (knee), with the larger 6908-2RS bearings on the hip-flex output side.
3. The hip-flex output flange mates to the femur upper end-cap. Bolt with 4× M6 SHCS, 16 mm, Loctite 243, torque 10 N·m.

### 7.2 Hip-abduction assembly

1. Stack the hip-abduction cycloidal (BOM `hip_abd_reducer`, 50:1) + motor (EC-i 50) + Moteus n1 into the hip-abd housing.
2. The hip-abd output mates to the hip-flex housing input side.
3. The hip-abd input side is the proximal mating face — exposed to the hip-yaw output.

### 7.3 Hip-yaw assembly

1. Stack the hip-yaw cycloidal (BOM `hip_yaw_reducer`, 30:1) + motor (EC-i 50) + Moteus n1 into the hip-yaw housing.
2. The hip-yaw output mates to the hip-abd housing.
3. The hip-yaw input side bolts to the **hip-torso mount plate** (BOM `hip_torso_mount_plate`).

### 7.4 Torso interface

1. Bolt the hip-torso mount plate to the pelvis flange (in the torso subassembly, scaffold v0.3) using 4× M8 SHCS, 30 mm (BOM `torso_iface_bolts`), with M8 nylon-insert flange lock-nuts (BOM `torso_iface_nuts`). Torque to 25 N·m.
2. The hip-yaw axis is vertical (parallel to gravity); the hip-abd axis is horizontal in the frontal plane; the hip-flex axis is horizontal in the sagittal plane. Verify via the dial indicator — single-leg-stance moment is dominated by hip-flex, and any deviation from sagittal-plane alignment translates to lateral hip-yaw cross-coupling under load.

---

## 8. Phase 7 — Harness routing (CAN-FD + 48 V power bus)

The leg has 6 controllers (4× Moteus n1 + 2× Moteus c1). Each needs CAN-FD signal + 48 V power. Plus 6 AS5048A SPI links (the encoders run over the same harness as the Moteus controllers via the n1/c1 onboard SPI input). Plus 1 FT sensor (ATI ethernet/CAN if Mini40, or HX711 I²C if in-house).

**Power bus (48 V):**
1. Run the 12 AWG silicone-jacket pair (BOM `power_bus_48v`) from the LEMO 2B torso receptacle (BOM `torso_connector_recept`, panel-mounted in the pelvis) down through the femur tube cavity to the **power-distribution PCB** (BOM `power_bus_distribution`) zip-tied to the femur interior wall.
2. From the distribution PCB, six XT30 pigtails fan out to the six Moteus controllers. Keep pigtails ≤ 200 mm to limit voltage transient ringing on motor commutation.
3. Place a 1000 µF / 100 V bulk electrolytic on the distribution PCB input.

**CAN-FD bus:**
1. Daisy-chain the six controllers via the BOM `canfd_bus_harness` (Molex PicoClasp 4-pin, 6-drop). Order: torso → hip-yaw n1 → hip-abd n1 → hip-flex n1 → knee n1 → ankle-pitch c1 → ankle-roll c1 → 120 Ω termination.
2. Set the CAN-IDs in `moteus_tool` per the descriptor's actuator-slot block. Suggested IDs: hip-yaw=11, hip-abd=12, hip-flex=13, knee=14, ankle-pitch=15, ankle-roll=16 (left leg); +10 offset for the right leg.

**Strain gauges and FT sensor:**
1. Strain-gauge wires (4 conductors per joint × 4 instrumented joints) run along the CAN-FD harness, separated by ~10 mm to limit inductive coupling.
2. ATI Mini40 cable runs in the tibia tube cavity, exits at the ankle-pitch housing, climbs the femur cavity along with the power and CAN harnesses, and exits at the LEMO 2B torso connector.

**Strain relief and grommets:**
- Every harness pass-through (femur end-caps, knee housing, tibia end-caps, ankle-pitch housing) gets a rubber grommet to prevent chafing under cyclic motion.

---

## 9. Phase 8 — Bring-up sequence

### 9.1 First power-on

1. With the leg suspended in a test fixture (no ground load), connect the 48 V bench supply to the LEMO 2B receptacle. Set current limit to 5 A initially.
2. Power on. Verify each Moteus controller's heartbeat LED.
3. Connect the fdcanusb adapter; run `moteus_tool --target N --info` for each N in {11..16}. Confirm all six respond.

### 9.2 Encoder commutation calibration

For each Moteus controller in turn (start with the ankle, work proximally — small motors first):
1. Run `moteus_tool --target N --calibrate`. The calibration injects current into stator coils and reads back AS5048A position to learn the rotor-to-encoder offset (commutation phase).
2. Verify the calibrated offset is stable across reboots. **Commutation drift is the single most common bring-up failure.** Symptoms: motor produces ~30% expected torque, gets hot rapidly, runs rough at low speed. Cause: AS5048A magnet seated off-axis, or magnet axially too far from PCB. Re-seat the magnet and repeat.

### 9.3 Torque-sensor zeroing

For each strain-gauge-equipped joint (hip-yaw, hip-abd, hip-flex, knee — and ankles if instrumented):
1. With the leg fully unloaded and the joint stationary at its mechanical zero, sample 1000 ADC counts.
2. Compute the bridge offset and store as the joint zero.
3. Apply a known calibration moment (a hanging mass at a known lever arm) and compute scale factor to convert ADC counts to N·m.

### 9.4 Range-of-motion sweep

For each joint, slowly command position from soft limit to soft limit at 0.1 rad/s while logging motor current and torque-sensor output. Look for:
- **Cycloidal preload misalignment:** uneven current draw across the rotation cycle (e.g. 2x current over a 30° arc). Symptom of bearing preload too tight or output flange not concentric with cycloidal output. **Disassemble and re-shim.**
- **Encoder commutation drift:** gradually rising current draw with no torque feedback change. Commutation phase has slipped — recalibrate.
- **Hip-yaw instability under torso load:** when the torso is bolted on and leg is loaded, hip-yaw may oscillate at ~3–5 Hz. Cause: low cycloidal stiffness × high reflected torso inertia. Mitigation: reduce hip-yaw position-loop gain, or add a torsional damper bushing at the hip-torso mount plate.

### 9.5 First standing test

With both legs assembled and bolted to the pelvis, place the robot in a Hoist (overhead-supported) jig. Command `safe_pose` (descriptor mode). Verify:
- All 12 leg joints reach their commanded targets within ±0.02 rad
- No joint draws > 30% rated continuous current at hold
- No audible cycloidal whine or grinding
- Foot FT readings (if instrumented) consistent with the gravitational distribution implied by the COM model

Only after these checks: lower the hoist to ground contact and re-verify.

---

## 10. Common failure modes

| Symptom | Likely cause | Fix |
|---|---|---|
| Cycloidal output runout > 0.1 mm TIR | Bearing preload uneven | Disassemble; re-shim with wave washer (target 30–50 N axial) |
| Joint stalls at 60% rated torque | Cycloidal preload too tight | Reduce wave-washer compression by 0.2 mm |
| Motor commutation phase drifts after thermal cycle | AS5048A magnet axially loose | Re-seat with Loctite 638 retaining compound; verify air gap 1.0 ± 0.2 mm |
| Hip-yaw oscillates 3–5 Hz under torso load | Torsional resonance hip-cycloidal × torso inertia | Reduce hip-yaw position-loop P gain by 50%; consider damper bushing |
| Ankle pitch loses zero across power cycles | AS5048A absolute position off (multi-turn ambiguity) | Single-turn AS5048A is correct only within ±π; add a homing limit switch or move to AS5048B (multi-turn) |
| Ankle planetary backlash audible at direction reversal | Maxon GP 32 HP backlash spec ~0.5° at no-load | Acceptable for v0.1; for v0.2 consider a low-backlash planetary or spring-preloaded backlash takeup |
| Foot FT signal noisy when motors spin up | Inductive coupling power → FT cable | Increase separation, add ferrite bead on FT cable, or move FT cable to opposite side of femur cavity |
| Strain-gauge zero drifts > 5% over 1 h | Bridge thermal coefficient | Add temperature compensation gauge; or accept and re-zero before each session |
| Knee cycloidal whines under load | Insufficient grease | Repack with Krytox GPL 226 per cycloidal vendor instructions |
| Hip-flex motor overheats during stair-climb gait | Continuous torque spec exceeded | Confirm gait planner stays within continuous-torque envelope; thermal-limit firmware in Moteus n1 |

---

## 11. Cross-references

- [`../ARCHITECTURE.md` §2.4](../ARCHITECTURE.md#24-actuators) — actuator architecture rationale
- [`../ARCHITECTURE.md` §9 commitment #1](../ARCHITECTURE.md#9-architectural-commitments) — hybrid actuator distribution commitment
- [`../descriptor/free-humanoid.udd.json`](../descriptor/free-humanoid.udd.json) — actuator-slot block (`L_HIP_yaw`, `L_HIP_roll`, `L_HIP_pitch`, `L_KNEE_pitch`, `L_ANKLE_pitch`, `L_ANKLE_roll` and right-side equivalents) is vendor-pinned to this BOM
- [`leg-v0.1-BOM.csv`](leg-v0.1-BOM.csv) — line-item bill of materials
- `cad/leg_assembly.scad` — top-level OpenSCAD model (assembled / exploded / kinematic-only)
- [`hand-v0.1-assembly.md`](hand-v0.1-assembly.md) — companion hand subassembly (reference pattern)

Corpus chain: `sumitomo-cyclo` (1937, 89 yr) gives cycloidal reducer prior-art shielding for hip + knee; `mit-cheetah-2` (2014), `mini-cheetah` (2019), `cassie-osu` give QDD ankle prior-art shielding; `mjbots-moteus` for the controller stack; `dlr-toro` for proprioceptive joint torque sensing.
