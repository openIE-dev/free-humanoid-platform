---
title: Hand v0.1 — CAD Reference Stub
layout: default
nav_order: 12
permalink: /chassis/hand-v0.1-cad-references.html
---

# Hand v0.1 — CAD Reference Stub
{: .no_toc }

> **REFERENCE document. Stub describing the CAD files to produce, not the CAD itself.** This file enumerates the mechanical CAD deliverables for the v0.1 hand subassembly: what they are, key dimensions, file format, and where they will live in the repo. The actual `.FCStd` / `.step` / `.dxf` files are the next deliverable in Phase 2 of the roadmap. See [`../ARCHITECTURE.md` §2.9](../ARCHITECTURE.md#29-manipulation), [`hand-v0.1-BOM.csv`](hand-v0.1-BOM.csv), and [`hand-v0.1-assembly.md`](hand-v0.1-assembly.md).

<details open markdown="block">
  <summary>Contents</summary>
  {: .text-delta }
- TOC
{:toc}
</details>

---

## 0. CAD-tool posture

Per [`../CONTRIBUTING.md`](../CONTRIBUTING.md) and the OpenLoco family pattern, all CAD source files **must be open-tool-readable**. The reference toolchain is:

- **Source format:** FreeCAD 1.0+ `.FCStd`. Any contributor can install FreeCAD for free; commercial CAD imports lossily, FreeCAD is the lossless form.
- **Exchange formats:** `.step` (AP242) for solid bodies, `.dxf` for 2D profiles, `.stl` for mesh-baked output (auto-generated from the descriptor + CAD by the OpenLoco bake pipeline; not source-of-truth).
- **2D drawings:** PDF + the FreeCAD TechDraw source page that generated it.
- **Drawing standards:** ANSI Y14.5-2018 GD&T for geometric tolerances. ISO 286-1 / 286-2 for shaft/hole fits and tolerance grades. Material call-outs per ASTM (aluminum, steel) or vendor-spec (PA12, silicone).

Proprietary CAD source (SolidWorks `.SLDPRT`, Inventor `.IPT`, Fusion `.f3d`) is not accepted as primary; conversions are accepted only as a courtesy export alongside the `.FCStd` source.

---

## 1. Files to produce

### 1.1 Skeleton main body — `cad/hand/skeleton-palm.FCStd`

**Description.** The palm-housing structural shell. PA12 (SLS or HP MJF). Encloses the synergy distribution drum, the motor mount face, and the tendon-routing channels from spool to MCP redirect pulleys. Mates dorsally to the wrist coupler, ventrally to the silicone palm pad cast.

**Key dimensions (target).**
- Overall envelope: ~110 mm length × ~85 mm width × ~30 mm thickness at the synergy junction
- Motor mount face: 4× M3 × 0.5 PCD 22 mm matching the Maxon GP 32 HP face plate, 3.5 mm clearance bores
- Spool axis: nominally aligned with palm long axis; spool spindle bore Ø6 H7 (3 mm radius)
- Synergy distribution drum bore: Ø10 H7 with two 3 mm dowel-pin pivots
- 5 tendon-routing channel exits at the MCP plane, each 4 mm × 2 mm slot, spaced per anthropometric MCP geometry (thumb opposable position offset ~30 mm radially)
- Wrist coupler interface: 3× M2.5 × 0.45 SHCS at PCD 18 mm

**Notes.** The PA12 channel walls in the synergy-junction region are the highest-stress feature; design with replaceable milled-aluminum inserts (see §1.2) press-fit into recesses with 0.05 mm interference. Match the link mass `0.45 kg` and inertia placeholder in [`../descriptor/free-humanoid.udd.json`](../descriptor/free-humanoid.udd.json) link `L_hand` / `R_hand`; iterate the descriptor against the as-built CAD mass once finalised.

### 1.2 Tendon-routing channel inserts — `cad/hand/tendon-channel-insert.FCStd` + `.dxf`

**Description.** Two milled aluminum 6061-T6 inserts that line the synergy junction and the spool entry channel. Bear the highest cyclic contact stress in the assembly. The DXF file is the 2D profile for water-jet or laser-cut option; the FCStd is the 3D solid for milled-from-stock production.

**Key dimensions.**
- Footprint: ~30 mm × 20 mm × 3 mm thick per insert
- Channel groove: 1.8 mm width × 1.0 mm depth, 6 mm minimum bend radius (UHMWPE retains tensile strength above 5× cable diameter bend radius; design margin to 8×)
- Surface finish on channel groove: Ra ≤ 0.4 μm (lapped or burnished); rough surface destroys UHMWPE in <1000 cycles

**Notes.** The DXF can also be supplied to a service like Xometry for water-jet from sheet stock; FCStd 3D solid is for shops that mill from bar.

### 1.3 Skin mold — `cad/hand/skin-mold.FCStd`

**Description.** Two-part PA12-printed silicone mold for the Dragon Skin 30 hand-skin shell. Outer clamshell + inner positive core that matches the assembled skeleton outer profile.

**Key dimensions.**
- Inner core: skeleton outer profile + 0 mm offset (interference fit to the dorsal bondline)
- Outer clamshell internal cavity: skeleton outer profile + 1.5 mm uniform offset (palm/dorsal/finger sides), 3.0 mm offset at fingertip cavities
- Parting line: dorsal centerline of the hand
- Registration: 4× Ø6 mm hardened pin → bore features at the corners
- Vent ports: 4× Ø2 mm at distal fingertip vent pockets
- Clamp screws: 6× M3 × 25 mm SHCS for clamshell halves
- Wrist pour port: Ø12 mm at the proximal end

**Notes.** Print mold halves with 25% gyroid infill (rigidity vs. mass); coat the cavity with mold release before each cast.

### 1.4 Pulley spool and tendon terminator — `cad/hand/spool-and-terminator.FCStd`

**Description.** The motor-output cable spool plus the synergy-junction terminator at the cable load-cell interface. The spool is 3D-printable PA12 for v0.1; aluminum is the v0.1.1 upgrade for cycle life.

**Key dimensions.**
- Spool: Ø16 mm OD × 12 mm L body; flange Ø22 mm × 1.5 mm thick on each end; central bore Ø6 H7 for shaft + 1× M3 set screw for hub clamp
- Spool channel: 1.8 mm wide spiral groove for ~5 wraps of the synergy cable
- Terminator: M4 stud + Ø12 mm load-cell flange + figure-8 cable knot pocket (3 mm dia × 6 mm L pocket)

**Notes.** AS5048A magnet is bonded to the rear face of the spool with a Ø6 × 2.5 mm pocket sized for diametric magnet. Verify the magnet's field axis is in the rotation plane before bonding.

### 1.5 Motor mount bracket — `cad/hand/motor-mount.FCStd` + drawing

**Description.** Aluminum 6061-T6 milled bracket, ~80 g. Rigid coupling between the Maxon GP 32 HP front face and the palm housing. Carries thermal load from the motor (~70 W × inefficiency loss ~10–15 W into the bracket).

**Key dimensions.**
- Outer envelope: ~45 mm × 35 mm × 8 mm
- Maxon GP 32 face mating: 4× Ø3.5 mm clearance bores at PCD 22 mm; counterbore for M3 SHCS heads
- Palm housing mating: 4× M2.5 × 0.45 tapped through-holes at PCD 25 mm
- Center bore: Ø11 mm clearance for planetary output shaft
- Surface treatment: anodised type II, black, for corrosion resistance + emissivity (improves passive thermal radiation)

**Notes.** GD&T per ANSI Y14.5: parallelism between the Maxon mating face and the palm-housing mating face called out at 0.05 mm; concentricity of the central bore to the bolt-circle center at Ø0.10 mm. ISO 286 fits: H7 on the central bore.

---

## 2. Drawing standards summary

All 2D drawings follow:

- **GD&T:** ANSI Y14.5-2018. Default datum scheme: A (largest plane), B (longest cylindrical feature), C (third orthogonal feature). Tolerance frames complete; basic dimensions in rectangles.
- **Fits and tolerances:** ISO 286-1 / 286-2. Default fit classes: H7/g6 for rotating shaft-in-bore, H7/h6 for slip fits, H7/p6 for press fits. Tighter than that by exception only, called out in the drawing.
- **Surface finish:** Ra in μm with the standard ISO 1302 indication.
- **Materials:**
  - Aluminum 6061-T6 (per ASTM B221) for milled structural members
  - PA12 / Nylon 12 (per HP MJF or 3D Systems SLS material spec) for printed structural shells
  - SAE 841 oil-impregnated bronze (per ASTM B438) for bushings
  - 1095 spring steel (per ASTM A684) or music wire (per ASTM A228) for torsion springs
  - UHMWPE / Spectra (per Honeywell / Samson product spec) for tendon cable
  - Platinum-cure silicone, 30A durometer (Smooth-On Dragon Skin 30) for skin shell
- **Threads:** ISO metric coarse default. Imperial threads called out explicitly.
- **Title block:** name, drawing number, revision, scale, material, finish, tolerances default, designer, date, approval.

---

## 3. Distribution and repo layout

```
free-humanoid-platform/
  chassis/
    hand-v0.1-BOM.csv
    hand-v0.1-assembly.md
    hand-v0.1-cad-references.md           (this file)
    cad/
      hand/
        skeleton-palm.FCStd
        skeleton-finger-proximal.FCStd
        skeleton-finger-middle.FCStd
        skeleton-finger-distal.FCStd
        skeleton-thumb-cmc.FCStd
        skeleton-thumb-proximal.FCStd
        skeleton-thumb-distal.FCStd
        wrist-coupler.FCStd
        tendon-channel-insert.FCStd
        tendon-channel-insert.dxf
        skin-mold.FCStd
        spool-and-terminator.FCStd
        motor-mount.FCStd
        motor-mount.pdf                   (TechDraw output)
        ASSEMBLY.FCStd                    (top-level assembly)
        export/
          *.step                          (auto-export from FCStd)
          *.stl                           (auto-bake from descriptor + CAD)
```

**`.gitignore` additions** (already partially in `../.gitignore`; verify):

```
chassis/cad/**/*.FCStd1            # FreeCAD backup files
chassis/cad/**/*.FCBak             # FreeCAD backup files
chassis/cad/**/.~lock.*            # FreeCAD lock files
chassis/cad/**/__pycache__/        # Python macro caches
chassis/cad/**/export/             # auto-generated, regenerable
```

**License:** CERN-OHL-S 2.0 (per [`../LICENSE-HARDWARE`](../LICENSE-HARDWARE)) for `.FCStd`, `.step`, `.dxf`, `.pdf` source. CC0-1.0 (per [`../LICENSE-DATA`](../LICENSE-DATA)) for `.csv` BOM data and the descriptor JSON.

---

## 4. Reference back to OpenLoco's UDD-to-mesh-bake pipeline

OpenLoco's existing pipeline lets a UDD descriptor + CAD source bake to a mesh and a hashed mesh-id, where the descriptor refers to the mesh-id rather than the file path. For the hand:

1. Author the FreeCAD source (`skeleton-palm.FCStd` etc.) under `chassis/cad/hand/`.
2. Export each part to `.step` via the FreeCAD batch export macro.
3. Run OpenLoco's bake step:
   ```sh
   cargo run -- bake /path/to/free-humanoid.udd.json --cad-dir chassis/cad/hand/ --output-dir out/meshes/
   ```
4. The bake step:
   - Decimates each `.step` to `.stl` at the descriptor-specified LOD (visual + collision, separate)
   - Hashes the `.stl` content; the descriptor's `geometry_ref.hash` (e.g. `free_humanoid_hand_underactuated_v0`) is updated to point at the new content-hash
   - The OpenLoco compiler then emits URDF/MJCF/Gazebo/etc. with the correct mesh path

This means the **descriptor stays the source of truth**; the CAD files supply geometry but are themselves regenerable inputs to a content-addressable cache. The hash-naming convention in the descriptor's link entries already follows this pattern (`catalog_joints_*`, `free_humanoid_hand_underactuated_v0`, etc.).

For v0.1 of the hand specifically:
- The descriptor link `L_hand` / `R_hand` references mesh hash `free_humanoid_hand_underactuated_v0`. Once the CAD is authored and baked, this hash will be replaced with the content-hash of the assembled hand mesh (e.g., `sha256:...`). The placeholder identifier remains stable until that bake.
- The `actuator_slots` block is updated in [`../descriptor/free-humanoid.udd.json`](../descriptor/free-humanoid.udd.json) per the BOM-derived motor parameters; see commit pairing this CAD-stub file.

---

## 5. References

- [`../ARCHITECTURE.md` §2.9](../ARCHITECTURE.md#29-manipulation), [§9 commitment #4](../ARCHITECTURE.md#9-architectural-commitments)
- [`../prior-art/INDEX.md`](../prior-art/INDEX.md): `pisa-iit-softhand`, `shadow-dexterous-hand`, `dlr-hand-ii`, `da-vinci-knight`, `mjbots-moteus`
- [`hand-v0.1-BOM.csv`](hand-v0.1-BOM.csv)
- [`hand-v0.1-assembly.md`](hand-v0.1-assembly.md)
- OpenLoco UDD-to-mesh bake: see `openloco/crates/openloco/src/bake.rs` (upstream)

---

*Free Humanoid Platform — Hand v0.1 CAD reference stub — 2026-05-06.*
