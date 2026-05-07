---
title: Hand v0.1 — Parametric CAD (OpenSCAD)
layout: default
nav_order: 13
permalink: /chassis/cad/
---

# Hand v0.1 — Parametric CAD (OpenSCAD)
{: .no_toc }

> **REFERENCE CAD — NOT VALIDATED BY PHYSICAL BUILD.** OpenSCAD parametric source for the v0.1 underactuated 5-finger hand. Text-based, version-controllable, deterministic. Any builder with the free OpenSCAD application can render to STL or DXF without proprietary tooling.

<details open markdown="block">
  <summary>Contents</summary>
  {: .text-delta }
- TOC
{:toc}
</details>

---

## 1. Why OpenSCAD for v0.1

The OpenLoco family pattern calls for FreeCAD `.FCStd` as the canonical lossless source. FreeCAD source is the next deliverable. For v0.1 we ship parametric OpenSCAD because:

- **Text-source.** Diff-able, mergeable, code-reviewable. `.FCStd` is a zip — useful, but opaque to `git diff`.
- **Agent-writable.** A future code-generation pass can mutate parameters or topology without a GUI.
- **Deterministic.** Same `.scad` + same OpenSCAD version → byte-identical mesh. Hashable into the OpenLoco UDD content-addressable cache.
- **Free tool.** OpenSCAD is BSD-licensed and runs on Linux/macOS/Windows.

A FreeCAD source pass is planned for v0.1.1 once the physical build feeds back dimension corrections.

---

## 2. Parametric hierarchy

```
hand_params.scad      ← single source of truth for all dimensions, fits, materials
        │
        ├── phalanx.scad      (single phalanx primitive)
        │       └── finger.scad      (3-phalanx or 2-phalanx thumb composition)
        │
        ├── pulley.scad       (generic flanged pulley primitive)
        ├── spool.scad        (single-tendon synergy spool + multi-tendon variant)
        │
        ├── palm.scad         (palm chassis: finger mounts, pulley mounts,
        │                      load-cell cavity, wrist iface, motor mount iface)
        │
        ├── motor_bracket.scad (Maxon GP 32 HP face → palm aluminum bracket)
        │
        ├── skin_mold.scad    (two-part silicone mold for hand-skin cast)
        │
        └── hand_assembly.scad (top-level: assembled, exploded, skeleton, mold views)
```

All non-`hand_params.scad` files `include <hand_params.scad>;` so dimensions live in exactly one place. To resize a phalanx, edit `hand_params.scad`; do not edit individual modules.

---

## 3. How to render

Install OpenSCAD 2024.05 or later (older versions miss `rotate_extrude` features used in pulley/spool).

### 3.1 Assembled-view STL

```sh
openscad -o hand_assembled.stl \
         -D 'view_mode=0' \
         hand_assembly.scad
```

### 3.2 Exploded-view PNG (for documentation)

```sh
openscad -o hand_exploded.png \
         -D 'view_mode=1' \
         --imgsize=1600,1200 \
         --camera=0,0,0,55,0,25,400 \
         hand_assembly.scad
```

### 3.3 Individual-part STLs (for printing)

```sh
# Each phalanx — set parameters via -D
openscad -o phalanx_proximal.stl \
         -D 'length=50' -D 'width=18' -D 'height=18' \
         phalanx.scad

# Palm chassis (the SLS-printed part)
openscad -o palm.stl palm.scad

# Motor bracket (mill from 6061 stock)
openscad -o motor_bracket.stl motor_bracket.scad

# Spool variants
openscad -o spool_single.stl -D '$fn=128' spool.scad
```

### 3.4 DXF for laser-cut / water-jet (motor bracket flat profile)

```sh
# 2D projection of the motor bracket bottom plate for water-jet cutting
openscad -o motor_bracket.dxf \
         -D 'projection_mode=true' \
         motor_bracket.scad
```

(For DXF export, wrap the body in `projection(cut=true) translate([0,0,-0.1])` — supplied as an example commit-time edit if 2D output is needed.)

### 3.5 Skin mold halves

```sh
openscad -o skin_mold_top.stl    -D 'view_mode=2' skin_mold.scad
openscad -o skin_mold_bottom.stl -D 'view_mode=3' skin_mold.scad
```

---

## 4. Verifying dimensions match the BOM

Every dimension in `hand_params.scad` includes a comment cross-referencing its BOM line. Cross-check by running:

```sh
# Print all parameter assignments with their inline BOM annotations
grep -nE '^[a-z_]+ *=' hand_params.scad
```

Then visually confirm each line against `../hand-v0.1-BOM.csv`. Notable matchings:

| `hand_params.scad` constant | BOM line |
|---|---|
| `axle_dia = 3.0`              | `joint_axle` PB3-30-NN-A |
| `bushing_od = 5.0`            | `bushing` 8458K71 |
| `tendon_dia = 1.5`            | `tendon_line` 8829T31 |
| `pulley_od = 8.0`             | `pulley` MBPB8-3-2 |
| `spring_wire_dia = 1.02`      | `return_spring` LTR-040A-04S |
| `motor_face_pcd = 22.0`       | `drive_reducer` GP 32 HP face |
| `magnet_pocket_dia = 6.1`     | `position_sensor_magnet` N35H-DIA6X2.5 |
| `skin_thickness = 1.5`        | `fingertip_pad` Dragon Skin 30 + cad-references §1.3 |

---

## 5. Dependencies

| Tool | Version | Purpose |
|---|---|---|
| OpenSCAD | 2024.05 or later | render `.scad` → `.stl` / `.dxf` / `.png` |
| GNU Make | optional | `make all` to render every part (Makefile not yet committed) |

OpenSCAD download: https://openscad.org/downloads.html

---

## 6. License

- **Source `.scad` files:** CC0-1.0 (per `../../LICENSE-DATA`). The CAD source travels with the descriptor and the descriptor is CC0; the CAD inherits.
- **Rendered hardware artifacts** (`.stl`, `.dxf`, `.step`, plus the physical hand built from them): CERN-OHL-S 2.0 (per `../../LICENSE-HARDWARE`).

Choosing CC0 for the `.scad` source is deliberate — agents and scripts must be able to mutate, fork, and republish parametric source without licensing friction. The strong-copyleft hardware license attaches at the rendered-artifact boundary.

---

## 7. Known best-guess dimensions (need physical-build feedback)

These are flagged inline in `hand_params.scad §12` and copied here for visibility:

- **Phalanx envelope** (length × width × height for proximal/middle/distal). Anatomical proxies; tune to a real hand cast.
- **Bushing flange OD/thickness.** Estimated; verify against Bunting/McMaster 8458K71 vendor drawing.
- **Maxon EC-i 30 + GP 32 HP combined stack length.** Pull from Maxon spec sheet.
- **Finger MCP lateral spacing.** Currently equally spaced; real hands converge ~5°/finger.
- **Lee Spring LTR-040A-04S free-state geometry.** Confirm pocket sizing vs. actual spring.
- **Phidgets CZL635 cavity sizing.** Placeholder; verify datasheet.

---

## 8. Roadmap

- v0.1.0 (this commit): OpenSCAD parametric source, exploded + assembled views, mold halves.
- v0.1.1 (after first physical build): tune dimensions to as-built feedback; add FreeCAD `.FCStd` source per `../hand-v0.1-cad-references.md` §1.
- v0.1.2: STEP exports per part; descriptor mesh-hash bake into `../../descriptor/free-humanoid.udd.json`.
- v0.2: differential synergy (vs. fixed-ratio), tactile fingertip integration, proper `.FCStd` master.

---

*Free Humanoid Platform — Hand v0.1 OpenSCAD CAD — 2026-05-06.*
