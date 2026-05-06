# Prior Art Index

This document maps every load-bearing design choice in the Free Humanoid Platform to specific entries in the [Free Humanoid Corpus](https://github.com/openIE-dev/free-humanoid-corpus). Each entry is cited by its corpus `id`. Anyone reviewing this platform — including USPTO examiners and invalidity-contention attorneys — can use this index to find the specific defensive publications that anticipate any patent claim against the platform's architecture.

The corpus has 181 entries spanning 1818 (Frankenstein) to 2025. This index cites the ~70 entries that are most directly load-bearing for the platform.

---

## Subsystem 1 — Kinematic topology (33-DoF bipedal humanoid)

| Corpus id | Year | Shielding |
|---|---|---|
| `wabot-1` | 1973 | Foundational anchor: first full-scale anthropomorphic biped, 53 years of prior art on humanoid kinematic topology. |
| `honda-e0` | 1986 | First disclosed harmonic-drive use in a humanoid. Anchors the harmonic-drive option space. |
| `honda-e1`–`honda-e6` | 1987–1993 | Static-then-dynamic walking biped lineage. Anchors hip 3-DoF + knee + ankle 2-DoF leg topology. |
| `honda-p1` | 1993 | First full-body Honda humanoid. |
| `honda-p2` | 1996 | First self-balancing autonomous full humanoid. **December 1996 disclosure date — anchors ZMP balance for any post-1996 claim.** |
| `honda-p3` | 1997 | Smaller form-factor refinement. |
| `asimo` | 2000 | Industrial-scale humanoid with sustained public disclosure. |
| `hubo` | 2002 | KAIST academic chain; published full kinematic spec. |
| `hrp-2`–`hrp-5p` | 2002–2018 | AIST/Kawada chain through 2018; full academic disclosure. |
| `nasa-valkyrie` | 2013 | Open NASA disclosure; 28 DoF documented. |
| `robonaut-2` | 2011 | NASA / GM; on-orbit at ISS. Disclosed in space. |
| `pal-talos` | 2017 | European industrial humanoid with full spec. |
| `cassie-osu` | 2017 | OSU spring-mass biped. Anchors the dynamic-walking subspace. |
| `digit-meta` | 2020 | Cassie-derivative full humanoid, commercial. |
| `atrias` | 2013 | OSU's predecessor to Cassie. |
| `berkeley-humanoid` | 2024 | Open-source academic humanoid. Strongest recent open anchor. |
| `unitree-h1` | 2023 | Commodity humanoid with full published spec. |
| `unitree-g1` | 2024 | Smaller commodity variant. |
| `darwin-op`, `poppy-humanoid`, `inmoov`, `reachy` | 2010–2020 | Open-source small / desk humanoid lineage. |

**Implication:** humanoid kinematic topology is fully exhausted as patentable subspace.

---

## Subsystem 2 — Actuators

### 2.1 Cycloidal reducers (default for hip, knee)

| Corpus id | Year | Shielding |
|---|---|---|
| `sumitomo-cyclo` | 1937 | **The cycloidal reducer.** 89-year prior art. Sumitomo Heavy Industries CYCLO drive; original patents long expired. |
| `apptronik-apollo`, `sanctuary-phoenix`, `sanctuary-phoenix-gen6`, `tesla-optimus` | 2023–2024 | Modern cycloidal in production humanoids. Their patent assertions are anticipated by `sumitomo-cyclo`. |

### 2.2 Harmonic-drive (default for shoulder, elbow)

| Corpus id | Year | Shielding |
|---|---|---|
| `honda-e0` | 1986 | First disclosed use of harmonic-drive in a humanoid. 40-year prior art. |
| `asimo`, `hubo`, `hrp-2`–`hrp-5p`, `robonaut-2`, `pal-talos`, `nasa-valkyrie` | 2000–2018 | Full chain through 2018 of harmonic-drive humanoids with published specs. |

### 2.3 QDD (default for ankle, alternative for hip/knee)

| Corpus id | Year | Shielding |
|---|---|---|
| `mit-cheetah` | 2009 | The original Cheetah; foundational. |
| `mit-cheetah-2` | 2014 | Foundational QDD architecture. |
| `mit-cheetah-3` | 2017 | Refined QDD. |
| `mini-cheetah` | 2019 | Open MIT QDD reference. The most-cited modern QDD anchor. |
| `cassie-osu` | 2017 | QDD adapted to bipeds. |
| `digit-meta` | 2020 | Commercial QDD biped. |
| `atrias` | 2013 | OSU spring-mass bipedal QDD. |
| `berkeley-humanoid` | 2024 | Open-source QDD humanoid. |
| `k-scale-os` | 2024 | Open-source QDD humanoid. |
| `mjbots-moteus` | 2019 | Open BLDC controller (CAN-FD). |
| `odrive` | 2017 | Open BLDC controller (USB / CAN). |
| `simplefoc` | 2020 | Open BLDC controller (Arduino-tier). |

### 2.4 Tendon-driven (default for hand, wrist)

| Corpus id | Year | Shielding |
|---|---|---|
| `shadow-dexterous-hand` | 2002 | 24-year prior art on tendon-routed anthropomorphic hand. Full mechanism disclosure. |
| `shadow-hand` | 2002 | Co-anchor. |
| `dlr-hand-ii` | 2001 | DLR's dexterous hand. |
| `dlr-justin` | 2009 | DLR's tendon-arm chain. |
| `pisa-iit-softhand` | 2012 | Underactuated soft hand (synergy-based). The recommended-hand anchor. |

---

## Subsystem 3 — Sensing

| Corpus id | Year | Shielding |
|---|---|---|
| `pomerleau-alvinn` | 1989 | First end-to-end neural-net policy from camera to control. 35-year prior art on learned-from-pixels control. |
| `howe-cutkosky-tactile-1989` | 1989 | 36-year academic anchor on robotic tactile sensing. |
| `biotac-syntouch` | 2008 | Multimodal fingertip tactile. |
| `gelsight` | 2009 | High-resolution optical tactile sensor. The recommended-fingertip anchor. |
| `cornell-jamming-gripper` | 2010 | Granular jamming end-effector — alternative compliance mechanism. |

---

## Subsystem 4 — Compute and learning policy

| Corpus id | Year | Shielding |
|---|---|---|
| `openai-rt-2` | 2023 | Foundational VLA. arXiv preprint disclosure. |
| `open-x-embodiment` | 2023 | Foundational open-data VLA training corpus. |
| `act-aloha` | 2023 | Action Chunking Transformer (imitation learning). |
| `mobile-aloha` | 2024 | Mobile manipulation imitation learning. |
| `diffusion-policy` | 2023 | Diffusion-based imitation learning. |
| `physical-intelligence-pi-zero` | 2024 | VLA foundation model. |
| `skild-foundation-model` | 2024 | VLA foundation model. |
| `covariant-rfm` | 2024 | Robotic foundation model. |
| `openai-dactyl` | 2018 | Sim-to-real RL with domain randomization on dexterous hand. |
| `toyota-thr3` | 2017 | Whole-body teleoperation. |

---

## Subsystem 5 — Safety supervisor (the deepest chain in the corpus)

This subsystem has the deepest prior-art chain in the entire commons — 80 years of fictional anticipation plus 30 years of formal academic prior art.

| Corpus id | Year | Shielding |
|---|---|---|
| `frankenstein` | 1818 | Earliest known fictional anchor on autonomous-machine safety failure. |
| `rur-rossums-robots` | 1920 | Origin of the word "robot." Three-Laws-anticipating constraint failure. |
| `metropolis-maschinenmensch` | 1927 | Mid-chain fictional anchor. |
| `asimov-positronic-robots` | 1940 | **Three Laws as inviolable hard constraints.** 86-year fictional anchor. |
| `williamson-folded-hands` | 1947 | Classic safety-constraint failure mode (Humanoids over-protect). |
| `forbidden-planet-robby` | 1956 | Robby the Robot — Three-Laws-compliant fictional disclosure. |
| `hal-9000` | 1968 | Mid-chain fictional anchor on supervisor failure modes. |
| `silent-running-drones` | 1972 | Maintenance drones with task-bound autonomy. |
| `thx-1138-chrome-cops` | 1971 | Authority-bound autonomous machines. |
| `asimovs-zeroth-law` | 1985 | Extension of the Three Laws. |
| `data-tng` | 1987 | Self-aware constraint adherence as character. |
| `robocop-1987` | 1987 | **"Prime Directives" as explicit Simplex-architecture-anticipating disclosure.** Cited verbatim by name in multiple academic Simplex papers. |
| `t-800-terminator` | 1984 | Failure of safety-supervisor-bypass. |
| `bishop-aliens` | 1986 | Asimov-compliant industrial-grade supervisor. |
| `sherman-simplex-architecture` | 1995 | **Foundational academic.** Verified safety controller as fallback when high-performance controller violates invariants. |
| `iso-10218-collaborative-robots` | 2006 | Industrial standards anchor. |
| `reachability-analysis-safe-control` | 2005 | Formal-method safe set computation. |
| `control-barrier-functions` | 2007 | The modern formal safety-controller standard. |
| `runtime-assurance-rta` | 2010 | AFRL pattern bridging Simplex to flight-control. |
| `shielding-rl` | 2018 | Formal safety on learned policy. |

**Implication:** any patent on a "safety supervisor for physical AI" issued post-2010 is anticipated by an 80-year-deep chain.

---

## Subsystem 6 — Comms and middleware

| Corpus id / standard | Year | Shielding |
|---|---|---|
| `software-ros1` / `software-ros2` corpus tag | 2007 / 2017 | ROS / ROS 2: open-source middleware standard. Universal in modern academic robotics. |
| `mjbots-moteus` | 2019 | Open CAN-FD actuator stack. |
| `software-mjbots-stack` corpus tag | 2019 | Open low-level robotics stack. |

(Comms is not patent-thicket-dense; corpus shielding is light because the design choices are obvious-and-universal rather than novel-claimed.)

---

## Subsystem 7 — Power

| Corpus id | Year | Shielding |
|---|---|---|
| `hyundai-boston-dynamics-spot` | 2015 | Hot-swap legged-platform power architecture. |
| `spot-fuel-cell` | 2020 | Alternative-chemistry anchor. |
| `unitree-h1`, `unitree-g1`, `apptronik-apollo`, `tesla-optimus` | 2023–2024 | Modern humanoid power architectures. |

---

## Subsystem 8 — Manipulation policy and end-effector

| Corpus id | Year | Shielding |
|---|---|---|
| `act-aloha`, `mobile-aloha` | 2023–2024 | Imitation-learning-from-teleop. |
| `diffusion-policy` | 2023 | Diffusion imitation learning. |
| `pisa-iit-softhand` | 2012 | Underactuated synergy-based hand (the recommended platform default). |
| `shadow-dexterous-hand` | 2002 | Full-DoF tendon-routed reference. |
| `dlr-hand-ii` | 2001 | DLR dexterous-hand chain. |
| `cornell-jamming-gripper` | 2010 | Granular-jamming alternative. |

---

## How to use this index

When you make a design choice in the platform — adding a feature, picking a vendor, modifying the descriptor, or writing a new firmware module — locate the relevant subsystem in this index and cite the most specific corpus entry that anticipates the choice.

If the corpus does not yet anticipate your choice:
1. Check the [corpus](https://github.com/openIE-dev/free-humanoid-corpus) directly (`corpus.jsonl`) — the index here is a curated subset.
2. If still no anticipation, propose a new corpus entry (per the corpus's `CONTRIBUTING.md`).
3. If neither is possible, mark the design choice `draft` in the descriptor or architecture document and document the invalidation gap.

Every commit to this platform that introduces a load-bearing design choice should reference at least one corpus entry id by name in the commit message. This is the operational form of the governance posture in [README.md](../README.md) and [CONTRIBUTING.md](../CONTRIBUTING.md).
