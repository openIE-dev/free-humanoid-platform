# Free Humanoid Platform

**An open hardware, open firmware, open data humanoid robot reference design — the seventeenth morphology in the [OpenLoco](https://openie-dev.github.io/openloco/) ecosystem and the first humanoid expressed in the OpenLoco Unified Descriptor Document (UDD) format. Shielded by the [Free Humanoid Corpus](https://github.com/openIE-dev/free-humanoid-corpus), a 181-entry public-domain prior art commons.**

> Status: scaffold (v0.0). This repository establishes the project's positioning, governance, and architectural option space. It is not yet a buildable robot. Load-bearing engineering decisions are explicitly flagged as TBD throughout, with the prior-art-supported option space documented for each.

---

## What this is

Free Humanoid Platform is a humanoid robot reference design where every part of the stack — chassis, actuators, electronics, firmware, control, perception, learning policy, and documentation — is open and unencumbered. Each non-trivial design choice cites a specific entry in the Free Humanoid Corpus that anticipates the choice as 102/103 prior art, so that the platform can be built and replicated without negotiating a patent thicket.

The platform sits at the intersection of three projects, each of which serves a distinct function and is structurally separate:

1. **[OpenLoco](https://openie-dev.github.io/openloco/)** — the substrate. OpenLoco is an open-source descriptor compiler that turns one UDD JSON file into a full toolchain output: URDF for ROS 2, MJCF for MuJoCo, STL meshes, BOM, and assembly instructions. It already covers sixteen morphologies (quadrupeds, wheel-leg hybrids, air-ground hybrids, whegs, wheeled bipeds, manipulators, aerial). Free Humanoid Platform is the seventeenth: a `humanoid_bipedal` morphology family that compiles through the same toolchain.

2. **[Free Humanoid Corpus](https://github.com/openIE-dev/free-humanoid-corpus)** — the prior-art commons. 181 timestamped, examiner-citeable defensive publications spanning private companies, open-source projects, science fiction, and academia, going back to R.U.R. (1920) and forward through 2025. The corpus exists to invalidate, by anticipation, the patent thicket that has accumulated around modern humanoids. Every design choice in this platform cites a corpus entry.

3. **Free Humanoid Platform** (this repository) — the reference design. The actual robot. Consumes UDD descriptors. References corpus entries. Integrates other OpenIE properties as the recommended (but swappable) compute, safety, and perception stack.

These three projects are tenants of one another. OpenLoco does not depend on the platform. The corpus does not depend on the platform. The platform depends on both, but is one of many possible tenants of each.

---

## Why a *seventeenth* morphology

The first sixteen OpenLoco morphologies are non-humanoid: quadrupeds, wheel-legs, air-ground hybrids, whegs, wheeled bipeds, manipulators, and aerial vehicles. None of them are humanoid bipedal. That gap is deliberate — humanoids are the most patent-thicketed morphology in robotics, and the first sixteen morphologies were chosen to validate the UDD compiler on simpler kinematic graphs first.

The platform brings the humanoid family into UDD because:

- The **descriptor-as-source-of-truth** discipline is most valuable on the most complex morphology. A humanoid descriptor that compiles to URDF + MJCF + STL + BOM + assembly is an artifact that previously did not exist in the open. Every existing open humanoid (Poppy, InMoov, K-Scale OS, Berkeley Humanoid, Reachy, Darwin-OP) is point-design. Whichever wins, the descriptor remains.

- The **prior-art commons is most valuable on the most patent-thicketed morphology**. The corpus's 181 entries disproportionately serve humanoid claims: bipedal locomotion, anthropomorphic hands, ZMP balancing, cycloidal/harmonic-drive joint actuation, whole-body MPC, RL policies for walking, VLA models. A platform that cites these entries by id makes the citations operational, not theoretical.

- **CC0 descriptors are the strongest possible defensive publication signal.** Once a UDD descriptor for a humanoid is published under CC0 with a defensible timestamp, the design choices it encodes are public domain by dedication. They cannot be re-enclosed.

The platform is not a product. It is a reference design that anyone can fork, build, modify, and ship without asking permission.

---

## Relationships to other OpenIE properties

Free Humanoid Platform recommends specific OpenIE properties as the default integration points, while keeping the integration boundary clean enough that any of them can be swapped out:

| OpenIE property | Role in Free Humanoid Platform | Swappability |
|---|---|---|
| **OpenLoco** | UDD descriptor format, URDF/MJCF/BOM/assembly compiler | hard dependency on the descriptor format; alternatives can re-compile from UDD |
| **Free Humanoid Corpus** | Prior-art commons; every design choice cites a corpus entry | required for governance posture; alternatives can use it independently |
| **Joule SOM** (recommended) | On-robot compute reference. Heterogeneous SoM with deterministic inference path. The default `compute` block in the descriptor. | swappable for any SoM exposing the same HAL |
| **MathGround** (recommended) | Safety supervisor running formal-method-checked invariants on top of the low-level controller. The default `safety` block in the firmware. | swappable for any Simplex-style supervisor; corpus entries `sherman-simplex-architecture`, `runtime-assurance-rta`, `control-barrier-functions`, `reachability-analysis-safe-control` shield the architecture |
| **Other OpenIE compute / fab properties** | Long-tail integration: `ofpga-fab` for SoC fabrication, `joulesperbit` for energy/efficiency framing, `silicon.openie.dev` as a successor compute substrate | optional, future-direction |

The platform does not require any of these — a builder can pick an off-the-shelf SoM, write their own Simplex supervisor, and still produce a fully open humanoid. The recommendations are the tested integration path, not a lock-in.

---

## License posture

Free Humanoid Platform is open at every layer, with the strongest available license for each artifact type:

| Artifact class | License | Files |
|---|---|---|
| Hardware (CAD, schematics, PCB layouts, mechanical designs) | **CERN-OHL-S 2.0** (strongly reciprocal open hardware) | [LICENSE-HARDWARE](LICENSE-HARDWARE) |
| Firmware, control software, simulation, tools | **Apache 2.0** | [LICENSE-SOFTWARE](LICENSE-SOFTWARE) |
| Documentation (README, ARCHITECTURE, design notes, manuals) | **CC-BY-SA 4.0** | [LICENSE-DOCS](LICENSE-DOCS) |
| Descriptors (UDD JSON), datasets, BOM data | **CC0 1.0** (public-domain dedication) | [LICENSE-DATA](LICENSE-DATA) |

CC0 on the descriptor and BOM is the load-bearing license choice. It matches OpenLoco's CC0 stance on its own descriptors and ensures that whatever this platform becomes, the *description* of it cannot be re-enclosed.

CERN-OHL-S 2.0 (rather than CERN-OHL-P) is chosen because the platform is meant to be a forking baseline, not raw material for proprietary forks. Anyone who modifies the hardware must release their modifications under the same license. This is the same posture as the `clean_fish`/shoal sibling project.

The license files in this repo currently contain SPDX-tagged headers and pointers to the canonical text. Inlining the full canonical text is a release-blocker before any public push (it is required by the licenses themselves and by SPDX best practice).

---

## Governance posture

This platform inherits the governance discipline of the Free Humanoid Corpus:

1. **Defensive publication norms.** Every non-trivial design choice in the architecture document, descriptor, and BOM cites a specific corpus entry that anticipates it as 102/103 prior art. Contributions that introduce a new design choice without a corpus citation are not accepted into the main branch; the contributor either cites an existing entry, adds a new entry to the corpus, or marks the choice as `draft` with an explicit invalidation gap noted.

2. **Examiner-citeable design rationale.** The style of the architecture document and design notes is element-by-element prior-art analysis, not narrative. Anyone — including a USPTO examiner reading this repo as non-patent literature — should be able to lift a design choice, follow the corpus citation, read the prior-art reference, and confirm the choice is anticipated.

3. **No-patent-aggression.** Contributors agree, by submitting, that they will not assert patents against the platform or its derivatives. This is not a license grant — the license already covers that — it is a social-contract posture aligned with the OIN model. The full text is in [CONTRIBUTING.md](CONTRIBUTING.md).

4. **Reference-design-not-product.** The platform is a reference design with explicit roadmap milestones, not a productized robot. There is no support contract, no warranty, no service tier. Forks are encouraged. Forks that productize without contributing improvements back are tolerated but not supported — the strongly-reciprocal license does most of the work here.

5. **Fail-safe-to-inert.** Every subsystem that can fail must have a defined fail-safe state. The robot must always have a defensible answer to "what does it do when something breaks?" The default answer is "drop to a stable pose, latch brakes, kill high-voltage rails." MathGround provides the supervisor implementation; the corpus chain `asimov-positronic-robots` → `williamson-folded-hands` → `sherman-simplex-architecture` → `control-barrier-functions` → `reachability-analysis-safe-control` → `iso-10218-collaborative-robots` → `runtime-assurance-rta` → `shielding-rl` shields the safety architecture across 80 years of fictional and 30 years of formal academic prior art.

---

## Eventual hosting

Per OpenIE convention, OSS projects in the OpenIE family are hosted at `openie-dev.github.io/<project>/`, separate from the commercial `openie.dev` namespace. The platform's eventual home is:

- **Repository:** `github.com/openIE-dev/free-humanoid-platform`
- **Site:** `openie-dev.github.io/free-humanoid-platform/`

This split matches `openie-dev.github.io/openloco/` (substrate), `github.com/openIE-dev/free-humanoid-corpus` (commons), and the precedent set by other OSS-side OpenIE projects.

---

## Repository layout

```
free-humanoid-platform/
  README.md                  this file — positioning, governance, license posture
  ARCHITECTURE.md            the canonical full-system spec, prior-art-cited
  CONTRIBUTING.md            quality bar, defensive-publication norms
  LICENSE-HARDWARE           CERN-OHL-S 2.0 header (canonical text TBD)
  LICENSE-SOFTWARE           Apache-2.0 header (canonical text TBD)
  LICENSE-DOCS               CC-BY-SA-4.0 header (canonical text TBD)
  LICENSE-DATA               CC0-1.0 header (canonical text TBD)

  descriptor/                UDD descriptor — the source of truth
    free-humanoid.udd.json   OpenLoco-compliant humanoid_bipedal descriptor
    README.md                how to compile the descriptor through OpenLoco

  chassis/                   mechanical CAD pointers, hull, kinematics
  actuators/                 actuator family options (cycloidal, harmonic-drive, QDD, tendon)
  electronics/               PCB pointers, power tree, Joule SOM integration
  firmware/                  HAL, behaviors, MathGround safety supervisor, comms
  control/                   whole-body MPC reference, RL policy weights
  sim/                       MuJoCo / Stonefish / Drake model pointers
  docs/                      design notes beyond root README/ARCHITECTURE
  datasets/                  pointers to training data sources

  prior-art/
    INDEX.md                 corpus entries this platform depends on, by subsystem
```

Each subdirectory has its own README.md scoped to its concern.

---

## Reading order

1. [ARCHITECTURE.md](ARCHITECTURE.md) — the canonical full-system spec. Start here if you want to understand the platform.
2. [descriptor/free-humanoid.udd.json](descriptor/free-humanoid.udd.json) — the OpenLoco UDD source of truth.
3. [prior-art/INDEX.md](prior-art/INDEX.md) — the corpus citation map.
4. [CONTRIBUTING.md](CONTRIBUTING.md) — how to add to the platform without breaking the governance posture.

---

## Status and roadmap

See [ARCHITECTURE.md §10](ARCHITECTURE.md) for the roadmap. Current state is **scaffold (v0.0)**: the project's shape is defined, the option space is mapped, and load-bearing engineering decisions are flagged for the user (David) to make as architectural calls.
