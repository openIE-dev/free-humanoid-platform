---
title: Architecture
layout: default
nav_order: 2
permalink: /ARCHITECTURE.html
---

# Architecture
{: .no_toc }

**Free Humanoid Platform — an open hardware, open firmware, open data humanoid robot reference design. The seventeenth morphology in the OpenLoco ecosystem. Shielded by the Free Humanoid Corpus.**

<details open markdown="block">
  <summary>Contents</summary>
  {: .text-delta }
- TOC
{:toc}
</details>

A 1.6 m, ~50 kg humanoid expressed as a single OpenLoco UDD descriptor. The descriptor compiles to URDF, MJCF, STL meshes, BOM, and assembly instructions through the existing OpenLoco toolchain. Every non-trivial design choice cites a specific entry in the Free Humanoid Corpus by id, so that the choice is defensible against patent assertion as anticipated by prior art.

This document is the canonical full-system spec. Where the platform must choose between alternatives, this document maps the option space supported by the corpus rather than committing the architecture. Load-bearing engineering decisions that require user input are explicitly flagged as **TBD (architectural call)**.

---

## 0. Design principles

1. **Open everything.** Hardware, firmware, descriptors, BOM, control software, simulation models, training data, documentation. CERN-OHL-S 2.0 for hardware, Apache 2.0 for software, CC-BY-SA 4.0 for documentation, CC0 1.0 for descriptors and datasets.

2. **The descriptor is the artifact, not the robot.** A UDD JSON file is the source of truth. URDF, MJCF, STL, BOM, and assembly instructions all fall out of the descriptor through the OpenLoco compiler. Any platform that wants to fork ours starts by forking the descriptor.

3. **Modularity at the interface, not at the implementation.** Actuator, sensor, compute, and safety blocks are interface-defined. The reference implementations are the recommended path; alternatives are first-class. The HAL is the contract.

4. **Prior-art-shielded design choices.** Every non-trivial choice cites a corpus entry. If the corpus does not anticipate a choice, the choice is not made — either an entry is added to the corpus, or a different choice is made.

5. **Reference design, not product.** The deliverable is a buildable design that anyone can fork. Not a robot we sell. Not a service we provide. Not a brand we defend.

6. **Fail safe to inert.** Every subsystem has a defined fail-safe state. The default answer to a fault is "drop to a stable pose, latch brakes, kill high-voltage rails." Safety supervisor (MathGround default) is non-bypassable from the policy layer.

7. **Deterministic where it matters, probabilistic where it must.** Low-level control, kinematics, balance, and safety are deterministic. Perception and policy are probabilistic. The boundary between them is sharp, not blended.

8. **Human-scale, but not human-replacing.** The platform is sized for human environments and tooling, not for humanoid uncanny-valley applications. The morphology is a means (compatibility with the built environment), not an end.

---

## 1. Fork map: what we take from where

This is what already exists in open-source or public-domain prior art and what we build on. Each row cites the corpus entry id that establishes the prior art.

### 1.1 Mechanical chassis and kinematics

| Source (corpus id) | What it gives us |
|---|---|
| `wabot-1` (Waseda 1973) | The original full-scale anthropomorphic biped. Full mechanism disclosure. 53-year prior art on humanoid bipedal kinematic topology. |
| `honda-e0` through `honda-e6` (1986–1993) | The Honda E-series chain. Static-walking-then-dynamic-walking biped lineage. 40-year prior art on the canonical humanoid leg kinematics (hip 3-DoF + knee + ankle 2-DoF). |
| `honda-p1`, `honda-p2`, `honda-p3` (1993–1997) | First self-balancing autonomous full humanoids. ZMP-based dynamic balance disclosed publicly Dec 1996 (`honda-p2`). 28-year prior art that nukes most modern bipedal-locomotion claims. |
| `asimo` (2000), `hubo` (2002) | Mass-produced humanoid lineage with full kinematic disclosures. Publicly demoed; KAIST HUBO has academic publication chain. |
| `hrp-2` through `hrp-5p` (2002–2018) | AIST/Kawada HRP series. Open academic disclosure of an industrial-scale humanoid through 2018. |
| `pal-talos` (2017), `nasa-valkyrie` (2013), `robonaut-2` (2011) | Industrial / NASA full humanoids with substantial published technical disclosure. Robonaut 2 is on the ISS — disclosed in space. |
| `cassie-osu` (2017), `atrias` (2013), `digit-meta` (2020) | OSU-lineage spring-mass dynamic bipeds. Foundational for the modern walking-controller subspace. |
| `berkeley-humanoid` (2024), `k-scale-os` (2024), `unitree-h1` (2023) | Recent academic / commodity humanoid disclosures. Berkeley Humanoid is open-source academic; Unitree H1 has full published spec. |
| `darwin-op` (2010), `poppy-humanoid` (2012), `inmoov` (2012), `reachy` (2020) | Open-source small/desk humanoid lineage. Permissive licenses, published BOMs, full CAD. |

**Implication for the platform.** The kinematic topology of a 1.6 m bipedal humanoid — head + torso + 2× 7-DoF arms + 2× 6-DoF legs + 2× anthropomorphic hands — is *fully exhausted as patentable subspace*. Any patent claim on humanoid kinematic topology that issues post-2025 is anticipated by at least one entry in the chain above.

### 1.2 Actuators

This is the patent-thicket-densest subsystem and the single highest-leverage attack surface. The corpus carries the deepest chains here.

**Cycloidal reducers (corpus chain anchored at `sumitomo-cyclo` 1937)**

| Source (corpus id) | What it gives us |
|---|---|
| `sumitomo-cyclo` (1937) | The cycloidal reducer. **89-year prior art.** Sumitomo Heavy Industries CYCLO drive, all original patents long expired. The canonical anchor. |
| `apptronik-apollo`, `sanctuary-phoenix`, `sanctuary-phoenix-gen6`, `tesla-optimus` | Modern humanoids using cycloidal in production. The corpus entries enumerate the patents asserted around these implementations. None of those patents survive 102/103 against `sumitomo-cyclo`. |

**Recommendation.** Cycloidal as the default for high-torque hip and knee joints. Direct from `sumitomo-cyclo` lineage; trivially defensible. **TBD (architectural call):** specific reducer ratio, sourcing (commodity Chinese cycloidals are now $80–$200 retail), and whether to design our own (full corpus shielding) or buy commodity (assembly speed).

**Harmonic-drive (corpus chain anchored at `honda-e0` 1986)**

| Source (corpus id) | What it gives us |
|---|---|
| `honda-e0` (1986) | First disclosed harmonic-drive use in a humanoid. **40-year prior art.** |
| `asimo`, `hubo`, `hrp-2..5p`, `robonaut-2`, `pal-talos`, `nasa-valkyrie` | Full chain through 2018 of harmonic-drive humanoids with published specs. |

**Recommendation.** Harmonic-drive as a *secondary option* for the shoulder and elbow joints where backlash matters and torque is moderate. Strain-wave geometry is patent-encumbered by Harmonic Drive Systems but the *use of harmonic drives in humanoids* is fully prior-arted.

**Quasi-direct-drive (QDD) (corpus chain anchored at `mit-cheetah-2` 2014, `cassie-osu` 2017, `mini-cheetah` 2019)**

| Source (corpus id) | What it gives us |
|---|---|
| `mit-cheetah` (2009), `mit-cheetah-2` (2014), `mit-cheetah-3` (2017), `mini-cheetah` (2019) | Foundational QDD architecture. 11-year prior art lineage with complete academic disclosure. |
| `cassie-osu` (2017), `digit-meta` (2020), `atrias` (2013) | QDD adaptation to bipeds. |
| `berkeley-humanoid` (2024), `k-scale-os` (2024) | Open-source QDD humanoid lineage. |
| `mjbots-moteus` (2019), `odrive` (2017), `simplefoc` (2020) | Open BLDC controllers. **The unlock for cost.** |

**Recommendation.** QDD as the default for the ankle (low-impedance, high-bandwidth ground reaction) and as an *alternative* to cycloidal for hip/knee where lower cost beats higher torque. Open BLDC controller (`mjbots-moteus` recommended for production-quality CAN-FD; `odrive` or `simplefoc` for hobbyist-tier) running FOC.

**Tendon-driven / cable-driven (corpus chain anchored at `shadow-dexterous-hand` 2002, `dlr-hand-ii` 2001)**

| Source (corpus id) | What it gives us |
|---|---|
| `shadow-dexterous-hand` (2002), `shadow-hand` (2002) | 24-year prior art on tendon-routed anthropomorphic hand. Full mechanism disclosure. |
| `dlr-hand-ii` (2001), `dlr-justin` (2009) | DLR's dexterous-hand and tendon-arm chain. |
| `pisa-iit-softhand` (2012) | Underactuated soft hand — synergy-based control. |

**Recommendation.** Tendon-driven for the **hands** and the **wrist** specifically, where cycloidal/harmonic-drive packaging is too bulky and the joint count is high. Tendon-driven is *not* recommended for the major leg or arm joints — too much friction, backlash, and routing complexity for the platform's reliability target.

**Actuator architectural call.**
**TBD (architectural call):** the platform's default actuator distribution. The trade space:

- **Option A — pure cycloidal (Apollo / Phoenix posture):** all major joints cycloidal + BLDC. Simplest BOM, highest torque density, highest cost (~$300–$600/joint at production volume), patent-thicket-dense but corpus-shielded.
- **Option B — pure QDD (Berkeley Humanoid / Mini Cheetah posture):** all major joints QDD. Lowest cost (~$80–$150/joint with commodity BLDC + 9:1 planetary), best transparency for impedance control, lower peak torque, prior-art chain via Cheetah lineage.
- **Option C — hybrid (recommended default):** cycloidal at hip and knee (high torque, shielded by `sumitomo-cyclo`); QDD at ankle (low impedance, shielded by `mini-cheetah`); harmonic-drive at shoulder and elbow (moderate torque, low backlash, shielded by `honda-e0`); tendon-driven at hands and wrist (shielded by `shadow-dexterous-hand`).

The recommendation is Option C, but this is the call the user (David) should make. The descriptor is currently structured to support Option C and can be re-derived for A or B by editing the `actuator_slots` block.

### 1.3 Sensing and perception

| Source (corpus id) | What it gives us |
|---|---|
| `pomerleau-alvinn` (1989) | First end-to-end neural-network policy from camera to control. **35-year prior art** on learned-from-pixels control. |
| `gelsight` (2009), `biotac-syntouch` (2008), `howe-cutkosky-tactile-1989` (1989) | Full chain on tactile fingertip sensing. `howe-cutkosky-tactile-1989` is a 36-year academic anchor. |
| `openai-rt-2` (2023), `open-x-embodiment` (2023) | Foundational VLA (vision-language-action) prior art. Open arXiv / open dataset disclosure. |
| `act-aloha` (2023), `mobile-aloha` (2024), `diffusion-policy` (2023) | Imitation-learning-from-teleop foundational disclosures. |
| `openai-dactyl` (2018) | Sim-to-real RL with domain randomization on dexterous hand. |

**Recommendation.** Stereo cameras (commodity Luxonis/DepthAI or equivalent) + IMU at every link + force-torque at wrist + tactile (GelSight-style or capacitive) at fingertips. Perception runtime delegated to OpenLoco's existing skill-graph runtime (see `openloco`'s v0.7.8 perception stack: `SkillGraphRuntime`, `StubDetector`, `VilaQueryStub`).

**TBD (architectural call):** depth modality. Stereo (passive, low-power, range-limited) vs. structured-light (better short-range, room-light-dependent) vs. ToF (medium range, narrow FoV). Stereo is the recommended default for cost and corpus-shielding.

### 1.4 Compute

| Source (corpus id) / OpenIE property | Role |
|---|---|
| **Joule SOM** (OpenIE recommended) | Default on-robot compute. Heterogeneous SoM with deterministic-LUT inference path. The descriptor's `compute` block points at Joule SOM as the reference implementation. |
| Off-the-shelf alternatives (Jetson Orin, Intel NUC, Raspberry Pi 5 + Coral) | Swappable at the HAL boundary. |

The compute integration point is structurally clean: the firmware HAL exposes a small set of services (sensor reads, motor commands, safety hooks, perception result subscription) and the SoM choice is invisible above the HAL. Joule SOM is the recommended default; alternatives are first-class.

### 1.5 Safety supervisor

This is one of the highest-leverage subsystems and the corpus chain is the deepest single chain in the entire commons.

| Source (corpus id) | What it gives us |
|---|---|
| `asimov-positronic-robots` (1940) | **86-year fictional anchor.** Three Laws as inviolable hard constraints. The `asimovs-zeroth-law` (1985) extends. |
| `williamson-folded-hands` (1947) | Classic "safety constraint failure mode" prior art (the Humanoids over-protect). |
| `frankenstein` (1818), `rur-rossums-robots` (1920) | Earlier fictional anchors on autonomous-machine safety failure. |
| `hal-9000` (1968), `data-tng` (1987), `robocop-1987` (1987) | Mid-chain fictional anchors. RoboCop's "Prime Directives" are an explicit Simplex-architecture-anticipating disclosure. |
| `sherman-simplex-architecture` (1995) | **Foundational academic.** The Simplex architecture: a verified safety controller as a fallback when the high-performance controller violates invariants. |
| `reachability-analysis-safe-control` (2005), `control-barrier-functions` (2007) | Formal-method safety controllers. CBFs are the modern standard. |
| `iso-10218-collaborative-robots` (2006) | Industrial standards anchor. |
| `runtime-assurance-rta` (2010) | AFRL runtime assurance pattern — bridges Simplex to flight-control. |
| `shielding-rl` (2018) | Shielded RL — formal safety on learned policy. |

**Implication for the platform.** Any patent on a "safety supervisor for physical AI" issued after 2010 faces an 80-year-deep chain of fictional anticipation plus a 30-year-deep chain of formal academic prior art. The architecture is fully shielded.

**Recommendation.** **MathGround** as the default safety supervisor implementation. It instantiates the `sherman-simplex-architecture` pattern with `control-barrier-functions` for the verified fallback controller, runs invariants on a separate compute domain from the high-performance controller, and is non-bypassable from the policy layer. Alternative: any open-source CBF implementation; the architectural pattern is what matters, not the implementation.

### 1.6 Whole-body control and learning policy

| Source (corpus id) | What it gives us |
|---|---|
| `mit-cheetah` series, `cassie-osu`, `digit-meta`, `atrias` | Open whole-body MPC for legged locomotion. |
| `act-aloha`, `mobile-aloha`, `diffusion-policy` | Imitation learning for manipulation. |
| `openai-rt-2`, `open-x-embodiment`, `physical-intelligence-pi-zero`, `skild-foundation-model`, `covariant-rfm` | VLA / foundation-model policies. |
| `openai-dactyl` | Sim-to-real RL on dexterous manipulation. |

**Recommendation.** Whole-body MPC (textbook formulation, no patentable claims) for low-level walking and balance, layered under an RL-trained policy for terrain-aware gait selection and locomotion mode switching. Manipulation policy: imitation-learning baseline (ACT or diffusion policy variant) with a VLA foundation-model option for higher-level task planning. The corpus shields all of this.

**TBD (architectural call):** policy architecture commitment. The trade space is between (a) classical MPC + scripted manipulation behaviors (interpretable, deterministic, low data requirement), (b) RL for locomotion + IL for manipulation (current academic best-practice), and (c) full VLA (highest ceiling, highest data and compute requirement). Recommendation is (b) with a path to (c).

### 1.7 Comms

| Source / OpenIE property | Role |
|---|---|
| **ROS 2** (corpus tag `software-ros2`) | Onboard middleware, off-board orchestration. |
| **JANUS-equivalent local protocol** (the corpus's `software-mjbots-stack` analog) | Robot-internal CAN-FD bus protocol for actuator and sensor traffic. |
| **WebRTC / gRPC** | Off-robot teleop and telemetry. |

Nothing patent-thicketed here — ROS 2 is permissive open source, CAN-FD is an ISO standard, WebRTC and gRPC are open. No special prior-art shielding needed.

### 1.8 Power

| Source (corpus id) | What it gives us |
|---|---|
| `hyundai-boston-dynamics-spot`, `spot-fuel-cell` | Power architecture for legged platforms; Spot fuel-cell is an alternative-chemistry anchor. |
| `unitree-h1`, `unitree-g1`, `apptronik-apollo`, `tesla-optimus` | Modern humanoid power architectures (Li-ion, hot-swap battery packs). |

**Recommendation.** Hot-swap Li-ion pack (~1 kWh, 48 V nominal), commodity-grade. Hot-swap is the corpus-anchored design choice. Pack chemistry is commodity — no patent-thicket exposure.

**TBD (architectural call):** hot-swap mechanical interface. Every modern humanoid uses a different incompatible swap interface; standardizing one across the platform is a mild commons contribution.

### 1.9 End-of-life and materials

The platform should degrade to recoverable / recyclable materials. Battery contained in IP-rated module. Magnets in motors are recoverable. PCBs are standard recyclable. Composite shells should prefer recyclable thermoplastics (PETG, PA12) over thermosets where stiffness allows.

This is not a corpus-shielded posture — it is a values-aligned design constraint inherited from the OpenIE family's environmental posture (see `clean_fish` ARCHITECTURE §2.7).

---

## 2. Platform spec: subsystem-by-subsystem

### 2.1 Form factor

- **Height (standing):** 1.55–1.70 m (corpus-shielded humanoid form factor; matches `unitree-h1` ~1.80 m, `apptronik-apollo` ~1.73 m, `digit-meta` ~1.60 m, `pal-talos` ~1.75 m, `nasa-valkyrie` ~1.88 m, all anchored back to the Honda E/P series and ASIMO 1.20–1.30 m, and back to WABOT-1 1.93 m at 1973).
- **Mass (no payload):** ~50 kg target. **TBD (architectural call):** mass budget. Lighter (30–40 kg, Berkeley Humanoid posture) reduces actuator torque demand and battery; heavier (60–80 kg, Atlas posture) increases payload capacity. Recommendation: 50 kg as a reasonable median.
- **Payload:** ~10 kg per arm at full extension; ~25 kg distributed.
- **Reach:** ~0.85 m per arm.
- **Walking speed:** target 1.5 m/s steady-state, 3 m/s peak (well under `unitree-h1` 5.4 m/s announced peak).

### 2.2 Kinematic topology

Standard 33-DoF humanoid topology, decomposed as:

- **Head:** 2-DoF (neck pitch + yaw)
- **Torso:** 1-DoF (waist yaw); optional 2 additional DoF for waist pitch/roll (cited by `wabot-1`'s 26-DoF torso lineage)
- **Each arm (×2):** 7-DoF — shoulder (pitch + roll + yaw), elbow (pitch), wrist (pitch + roll + yaw)
- **Each hand (×2):** 6-DoF underactuated (5 fingers, opposable thumb, with synergy-based reduction; cited by `pisa-iit-softhand`, `shadow-dexterous-hand`, `dlr-hand-ii`)
- **Each leg (×2):** 6-DoF — hip (pitch + roll + yaw), knee (pitch), ankle (pitch + roll)

Total: 33 DoF in the recommended baseline. This is the standard humanoid topology, exhaustively prior-arted.

The full kinematic tree, with link masses, inertias, joint limits, and effort/velocity bounds, lives in `descriptor/free-humanoid.udd.json`. That descriptor is the source of truth; this section is summary.

### 2.3 Chassis and structural

Frame: aluminum 6061 / 7075 mix for high-load structural members; carbon fiber composite for shells. **Detailed CAD: TBD** — the descriptor encodes link inertias and origins; the detailed CAD is the next deliverable.

Corpus citations:
- `wabot-1`, `honda-p2`, `honda-p3` for foundational humanoid frame topology.
- `unitree-h1`, `apptronik-apollo`, `berkeley-humanoid` for modern lightweight frame implementations.

### 2.4 Actuators

See §1.2 for the option space and recommendation. The descriptor encodes a placeholder distribution consistent with Option C (hybrid). The actuator block is structured as `actuator_slots` per OpenLoco UDD convention, with each slot specifying:

```
{
  "name": "...",            // matches a joint name
  "joint": "...",
  "tier": 2,                // OpenLoco tier: 0 Dynamixel, 1 SimpleFOC, 2 Moteus
  "type": "cycloidal" | "harmonic_drive" | "qdd" | "tendon" | "linear",
  "reducer_ratio": ...,
  "peak_torque_nm": ...,
  "continuous_torque_nm": ...,
  "max_velocity_rad_s": ...,
  "corpus_citation": "sumitomo-cyclo" | "honda-e0" | "mit-cheetah-2" | ...
}
```

### 2.5 Sensing

- **Per-actuator:** position, velocity, current. Corpus tag `sensing-proprioceptive-actuator`.
- **IMU at every major link:** torso, head, each forearm, each tibia. Corpus tag `sensing-imu`. Anchored at `honda-p2` and the entire HRP/ASIMO chain.
- **Force-torque at each wrist and ankle.** Corpus tag `sensing-force-torque`.
- **Tactile at fingertips:** GelSight-style or capacitive. Corpus chain `howe-cutkosky-tactile-1989` → `biotac-syntouch` → `gelsight`.
- **Stereo camera at head:** Luxonis OAK or equivalent, providing depth and RGB. Corpus tag `sensing-stereo-camera`. Anchored at `pomerleau-alvinn` (1989) for camera-to-control.
- **Microphones:** stereo for sound localization; not corpus-load-bearing.

### 2.6 Compute

- **Default:** Joule SOM (OpenIE property). Provides deterministic-LUT inference path, RISC-V housekeeping core, and safety co-processor in one module.
- **Alternative:** Jetson Orin Nano / NX for high-throughput VLA inference; Raspberry Pi 5 + Coral for hobbyist-tier; Intel NUC for x86 development convenience.
- **Compute distribution:** safety supervisor on a separate compute domain from the high-performance controller (Simplex pattern, corpus `sherman-simplex-architecture`). Perception runtime on its own compute domain (latency-decoupled from control).

### 2.7 Safety supervisor

**Default implementation:** MathGround (OpenIE property) running the Simplex pattern.

The supervisor enforces a small set of formally specified invariants:
- COM stays within the support polygon under expected disturbance bounds
- Joint limits, velocity limits, torque limits not exceeded
- Self-collision avoidance
- Collision-stop on unexpected contact
- Battery undervoltage triggers safe-pose latch
- Heartbeat from the high-level controller; absence triggers safe-pose latch

When any invariant is violated, the supervisor takes over, drives the robot to a defined safe pose (sitting, kneeling, or supported standing depending on context), latches the brakes, and reports the violation upstream. The high-level controller cannot override the supervisor. This is the `sherman-simplex-architecture` pattern with `control-barrier-functions` for the formal invariants.

Corpus citation chain (full): `asimov-positronic-robots` (1940) → `williamson-folded-hands` (1947) → `hal-9000` (1968) → `asimovs-zeroth-law` (1985) → `data-tng` (1987) → `robocop-1987` (1987) → `sherman-simplex-architecture` (1995) → `reachability-analysis-safe-control` (2005) → `iso-10218-collaborative-robots` (2006) → `control-barrier-functions` (2007) → `runtime-assurance-rta` (2010) → `shielding-rl` (2018).

### 2.8 Perception

Onboard perception pipeline:

1. **Stereo depth + RGB** at ~30 Hz from head camera.
2. **Foothold map / ground-plane fit** running at ~30 Hz on perception domain. Corpus: classical SLAM / ground-fit prior art is universal; OpenLoco's `foothold_map`, `ground_plane_fit`, `obstacle_height` skills are the reference implementations.
3. **Object detection / VLM querying** event-driven, ~1 Hz when needed, pulled via `SkillGraphRuntime` (OpenLoco's skill graph). Corpus: `openai-rt-2`, `open-x-embodiment`, `physical-intelligence-pi-zero`.
4. **Tactile** at ~100 Hz during contact tasks. Corpus: `gelsight`.

### 2.9 Manipulation

- **Default end-effector:** 5-finger underactuated hand (synergy-reduced from full anatomical DoF count). Corpus: `pisa-iit-softhand` (synergy-based), `shadow-dexterous-hand` (full-DoF reference), `dlr-hand-ii`.
- **Alternative:** parallel-jaw gripper for industrial-task variants. Corpus: trivially universal prior art.
- **TBD (architectural call):** which hand variant is the *default* in the descriptor. Recommendation: underactuated soft hand for the reference, with a parallel-jaw alternative descriptor as a separate UDD.

### 2.10 Learning policy

See §1.6. Layered:
- **Low-level:** whole-body MPC (textbook). Cycle 200–500 Hz on the control compute domain.
- **Mid-level:** RL policy for locomotion mode and gait. Cycle 50–100 Hz. Trained in MuJoCo via OpenLoco's `gait_harness` (the same harness that runs the ANYmal-WL and Mini Whegs gaits). Corpus: `mit-cheetah-2`, `cassie-osu`, `mini-cheetah`, `digit-meta`.
- **High-level:** imitation-learning manipulation policy (ACT / diffusion-policy baseline). Corpus: `act-aloha`, `mobile-aloha`, `diffusion-policy`. Optional VLA upgrade: `openai-rt-2`, `physical-intelligence-pi-zero`, `skild-foundation-model`.

### 2.11 Comms

- **On-robot:** CAN-FD for actuator/sensor bus (Moteus-style). Ethernet between compute domains.
- **Off-robot:** ROS 2 for development; gRPC for production telemetry; WebRTC for teleop video.
- **Wireless:** WiFi 6 onboard; optional 5G modem.

### 2.12 Power

Hot-swap Li-ion pack, ~1 kWh nominal, 48 V. Onboard 24 V and 12 V DC-DC rails for compute and sensors. Estimated runtime 1.5–3 hours depending on workload.

**TBD (architectural call):** hot-swap interface mechanical standard.

### 2.13 End-of-life

Batteries IP-rated and removable for recycling. Magnets in motors recoverable. Composite shells preferring thermoplastics over thermosets. PCBs standard-recyclable. Documentation includes a takedown / disassembly manual matching the assembly manual.

---

## 3. The descriptor

The single source of truth is `descriptor/free-humanoid.udd.json`. It is OpenLoco UDD-compliant. The OpenLoco compiler can already turn it into:

- `free-humanoid.urdf` — ROS 2 / RViz / Gazebo
- `free-humanoid.xml` — MJCF for MuJoCo / MJX
- `bom.csv` — bill of materials
- `assembly.md` — assembly instructions
- STL meshes (one per unique mesh hash)

To compile:

```sh
# from an OpenLoco checkout
cargo run -- validate /path/to/free-humanoid.udd.json
cargo run -- generate /path/to/free-humanoid.udd.json --all --output-dir out/
cargo run -- bake /path/to/free-humanoid.udd.json --output-dir out/meshes/
```

The descriptor currently uses placeholder mass/inertia values structured to OpenLoco UDD conventions. **Iterating these to physical-build accuracy is a load-bearing follow-up task**, gated on the actuator-distribution and mass-budget architectural calls.

---

## 4. Repository structure

```
free-humanoid-platform/
  README.md
  ARCHITECTURE.md           (this document)
  CONTRIBUTING.md
  LICENSE-HARDWARE          CERN-OHL-S 2.0
  LICENSE-SOFTWARE          Apache 2.0
  LICENSE-DOCS              CC-BY-SA 4.0
  LICENSE-DATA              CC0 1.0

  descriptor/
    free-humanoid.udd.json  the source of truth
    README.md

  chassis/                  mechanical CAD pointers, hull, kinematics
  actuators/                actuator family options and specs
  electronics/              PCB pointers, power tree, Joule SOM integration
  firmware/                 HAL, behaviors, safety supervisor (MathGround), comms
  control/                  whole-body MPC, RL policy weights, manipulation policy
  sim/                      MuJoCo / Stonefish / Drake model pointers
  docs/                     additional design notes
  datasets/                 pointers to training data sources

  prior-art/
    INDEX.md                corpus entries this platform depends on, by subsystem
```

---

## 5. What needs original engineering

Not covered by existing prior art and requiring genuine new disclosure:

1. **The UDD schema extension for humanoid-specific actuator slots.** The existing UDD schema handles tier-2 Moteus QDD; humanoid-specific extensions for cycloidal and harmonic-drive actuator types need to be added (and contributed back upstream to OpenLoco).

2. **The hand descriptor.** No existing OpenLoco morphology has a 6-DoF underactuated 5-finger hand. The synergy-reduction representation in UDD is novel and needs to be designed in collaboration with OpenLoco maintainers.

3. **The MathGround integration shim.** MathGround as a Simplex supervisor for a UDD-described robot is a new integration. The interface contract is defined here; the implementation is downstream.

4. **The hot-swap battery interface mechanical standard.** Optional small commons contribution; the interface is novel only in that it is *standardized*.

Everything else is fork, port, or integration of existing open work, with corpus citations.

---

## 6. Roadmap

### Phase 0 — months 0–3: scaffold and corpus citation

- This document. ✓ (current pass)
- Descriptor in placeholder form with all subsystems represented. ✓ (current pass)
- Prior-art INDEX.md cross-referencing every architectural choice to corpus entries. ✓ (current pass)
- License headers in place; canonical license text inlined before any public push.
- User (David) makes the load-bearing architectural calls flagged as TBD.

### Phase 1 — months 3–9: simulation-buildable

- Iterate descriptor to a state where the OpenLoco compiler emits a MuJoCo model that walks under whole-body MPC.
- Write the UDD schema extensions for cycloidal / harmonic-drive / tendon-driven actuator types; PR upstream to OpenLoco.
- Integrate OpenLoco's `gait_harness` for closed-loop walking rollouts.
- First contribution to OpenLoco from a humanoid morphology.

### Phase 2 — months 9–18: hand + first physical subassembly

- Design the 6-DoF underactuated hand. Corpus-shielded by `pisa-iit-softhand`, `shadow-dexterous-hand`. Build the hand first — it is the highest-cost-per-DoF subsystem and the highest-leverage demonstration that the open posture can match commercial closed designs.
- First physical actuator characterization (commodity cycloidal + Moteus + Joule SOM HAL).
- Tactile fingertip integration (`gelsight` corpus citation).

### Phase 3 — months 18–30: arm + leg subassemblies, integrated control

- Single-arm physical build. ACT/diffusion-policy imitation-learning baseline trained on teleop data.
- Single-leg physical build. Whole-body MPC for single-leg balance.
- MathGround safety supervisor integrated and tested.

### Phase 4 — months 30–48: full platform

- Full kinematic build.
- First standing demonstration. Then walking. Then manipulation.
- Public open release. Defensive-publication ceremony parallel to corpus quarterly release.

### Phase 5 — months 48+: ecosystem

- Variants: industrial / domestic / outdoor.
- Forks encouraged.
- Continued contributions to OpenLoco and to the corpus.

---

## 7. Safety, ethics, and what we won't do

- **No surveillance integration.** The platform's perception stack does not ship with face recognition, speech-to-identity, or persistent identification primitives. Forks that add these violate the no-patent-aggression contributor norm and the OpenIE values posture.
- **No weaponization.** The platform license does not prohibit weaponization (CERN-OHL-S does not have a non-weapons clause), but the contributor norm explicitly does. Forks that weaponize are not in this project's contributor base.
- **No biological hazard payloads.** Self-evident.
- **Fail-safe-to-inert is a hard constraint.** See §2.7. The MathGround supervisor cannot be bypassed.
- **Indigenous and community consent for outdoor / public-space deployment.** Same posture as `clean_fish` ARCHITECTURE §9.

---

## 8. Why open

Three reasons, the same three the `clean_fish` architecture cites and which the OpenIE family applies to every substrate.

**Trust.** Embodied physical AI in human environments requires radical transparency. Anyone deploying a humanoid in a workspace must be able to inspect the safety supervisor, the control policy, the perception stack, and the actuator firmware. Closed-source physical AI is a trust failure waiting to happen.

**Distribution.** Humanoids will not be solved by a few well-capitalized incumbents. The space is too broad — industrial, domestic, hazardous-environment, eldercare, agricultural, construction. An open kit replicated by hundreds of universities, labs, and small companies covers the space; a half-dozen closed silos do not.

**Compounding.** Every fork makes the next fork easier. Every corpus citation makes the next platform's defense easier. Every UDD descriptor strengthens OpenLoco. The commons compounds; the silos do not.

This is the OpenIE thesis applied to humanoids. The descriptor compiler, the prior-art commons, the safety supervisor, the deterministic compute spine — they all converge on a humanoid that anyone can build, anyone can fork, and no one can enclose.

---

## 9. Open architectural decisions (summary)

The load-bearing decisions flagged for user input, in priority order:

1. **Actuator distribution** (§1.2 / §2.4). Pure cycloidal vs. pure QDD vs. hybrid (recommended). Determines BOM cost, control characteristics, and corpus-shielding emphasis.
2. **Mass budget** (§2.1). 30 kg (lightweight academic), 50 kg (recommended median), 80 kg (industrial). Determines battery, actuator torque, and use-case envelope.
3. **Default policy architecture** (§1.6 / §2.10). Classical MPC + scripted vs. RL-locomotion + IL-manipulation (recommended) vs. full VLA. Determines data and compute requirements.
4. **Default end-effector** (§2.9). Underactuated 5-finger hand (recommended) vs. parallel-jaw vs. both-as-variants. Determines manipulation policy training data needs.
5. **Depth modality** (§1.3). Stereo (recommended) vs. structured-light vs. ToF.
6. **Hot-swap battery interface mechanical standard** (§2.12 / §1.8). Recommendation: design one, contribute the spec. Or: pick an existing commercial standard.
7. **Cycloidal sourcing** (§1.2). Commodity buy vs. design our own. Trade is build-speed vs. corpus-shielding completeness.
8. **Hand variant for first physical build** (Phase 2 of §6). Underactuated soft (recommended) vs. full-DoF Shadow-style.
9. **Reference-design vs. specific-build distinction** (governance). Whether the platform repo should ship a specific build (with chosen vendor parts) or only the reference design (with vendor-agnostic specs).
10. **Joule SOM commitment** (§2.6). Whether the descriptor's `compute` block defaults to Joule SOM or to a vendor-agnostic abstract HAL with Joule SOM as one implementation among many.

These are the architectural calls. The scaffold is structured to support any answer to each; the recommendations are this document's defaults.

---

*Free Humanoid Platform — the seventeenth OpenLoco morphology — scaffold v0.0 — 2026-05-06.*
