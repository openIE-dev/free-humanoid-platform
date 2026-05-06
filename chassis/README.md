# chassis/

Mechanical CAD, frame, hull, structural members.

## Status (v0.0)

Stub. The kinematic topology and link inertias are encoded in [`../descriptor/free-humanoid.udd.json`](../descriptor/free-humanoid.udd.json). Detailed CAD is **TBD**, gated on the architectural calls in [../ARCHITECTURE.md §9](../ARCHITECTURE.md):

- Mass budget (30 / 50 / 80 kg)
- Cycloidal sourcing (commodity vs. design our own)

## Prior-art shielding

Foundational topology is fully prior-arted. See [../prior-art/INDEX.md §1](../prior-art/INDEX.md) for the chain anchored at `wabot-1` (1973) → Honda E/P series (1986–1997) → ASIMO/HUBO/HRP/PAL/Valkyrie/Robonaut/Berkeley Humanoid.

## Planned content

- `cad/` — mechanical CAD source files (FreeCAD or step files; **must be open-tool-readable** per CONTRIBUTING.md)
- `kinematics/` — symbolic kinematic chain with reach analysis and CoM trajectory bounds
- `hull/` — outer composite shell designs
- `bom-mechanical.csv` — mechanical BOM (CC0 per LICENSE-DATA)

## License

CERN-OHL-S 2.0 (per [../LICENSE-HARDWARE](../LICENSE-HARDWARE)) for CAD source files. CC0-1.0 (per [../LICENSE-DATA](../LICENSE-DATA)) for BOM data.
