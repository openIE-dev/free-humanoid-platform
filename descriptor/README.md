# descriptor/

The OpenLoco UDD descriptor. **This is the source of truth for the platform.**

## Files

- [`free-humanoid.udd.json`](free-humanoid.udd.json) — the canonical UDD-compliant humanoid descriptor.

## Schema

OpenLoco UDD `schema_version: 1`. The descriptor encodes:

- `meta` — name, units, author, description, generator, plus the `morphology_family: "humanoid_bipedal"` and `corpus_anchors` extension fields used by Free Humanoid Platform.
- `robot.links` — link list with mass, inertia (6-element diagonal-major), and `geometry_ref` (mesh hash).
- `robot.joints` — joint list with joint_type (`revolute` | `fixed` | `continuous`), parent_link, child_link, axis, origin_xyz, origin_rpy, and limits.
- `robot.actuator_slots` — actuator binding to joints, with OpenLoco tier (0 Dynamixel, 1 SimpleFOC, 2 Moteus) and Free Humanoid Platform extension fields `type` and `corpus_citation`.
- `robot.modes` — controller modes (`safe_pose`, `standing`, `walking`, `manipulation`).

## Compiling the descriptor

The OpenLoco compiler turns this descriptor into:

- `free-humanoid.urdf` — ROS 2 / RViz / Gazebo
- `free-humanoid.xml` — MJCF for MuJoCo / MJX
- `bom.csv` — bill of materials
- `assembly.md` — assembly instructions
- STL meshes (one per unique mesh hash)

From an OpenLoco checkout (e.g. `/path/to/openloco/`):

```sh
cd /path/to/openloco
cargo run -- validate /path/to/free-humanoid-platform/descriptor/free-humanoid.udd.json
cargo run -- generate /path/to/free-humanoid-platform/descriptor/free-humanoid.udd.json --all --output-dir out/
cargo run -- bake /path/to/free-humanoid-platform/descriptor/free-humanoid.udd.json --output-dir out/meshes/
```

## Status (v0.0)

The descriptor is a **scaffold**. Specifically:

- The kinematic topology is correct: 33 links, 39 joints, 29 revolute (2 head + 1 waist + 7×2 arms + 6×2 legs + 6 wrist channels expressed as 3-DoF wrist), 29 actuator slots in a 4-mode lattice.
- Mass and inertia values are placeholders chosen to be *plausible* for a 1.6 m / 50 kg humanoid but not derived from physical CAD. They are sufficient for OpenLoco compilation and MuJoCo simulation; they are **not** sufficient for physical-build engineering.
- Mesh hashes for joint housings and brackets reference OpenLoco's existing catalog families (`catalog_joints_*`, `catalog_brackets_*`). Mesh hashes for bespoke parts (`free_humanoid_pelvis_v0`, `free_humanoid_torso_v0`, `free_humanoid_head_v0`, `free_humanoid_hand_underactuated_v0`, `free_humanoid_foot_v0`) are placeholders — the corresponding mesh content will be authored as the chassis/CAD effort progresses.
- The hand is currently expressed as a single `_hand` link with 6 effective DoF folded into a synergy-based underactuated mechanism. Per OpenLoco UDD convention this is a single link with the inner hand mechanism as a separate descriptor extension (TBD; needs upstream PR to OpenLoco for the synergy-based-hand schema).
- The actuator distribution follows ARCHITECTURE Option C (hybrid): cycloidal at hip/knee, harmonic-drive at shoulder/elbow, QDD at ankle, tendon-driven at wrist/hand. This is the recommendation, not the architectural commitment. See [../ARCHITECTURE.md §1.2](../ARCHITECTURE.md) for the option space.

## Iterating the descriptor

When changing the descriptor, ensure:

1. The change is justified by a corpus citation (set in `corpus_citation` for actuator slots; cited in commit message and ARCHITECTURE.md for structural changes).
2. `cargo run -- validate` from OpenLoco passes.
3. `cargo run -- generate --all` produces a compilable URDF and MJCF.
4. The change is reflected in [../ARCHITECTURE.md](../ARCHITECTURE.md) and [../prior-art/INDEX.md](../prior-art/INDEX.md).

## License

CC0-1.0 (per [../LICENSE-DATA](../LICENSE-DATA)). Public-domain dedication.
