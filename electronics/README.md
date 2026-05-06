# electronics/

PCBs, power tree, on-robot compute integration.

## Status (v0.0)

Stub. Planned compute spine: **Joule SOM** (OpenIE property; recommended default) or off-the-shelf alternative (Jetson Orin Nano/NX, Intel NUC, Raspberry Pi 5 + Coral).

## Architectural posture

The on-robot electronics architecture has three compute domains, separated for safety and latency:

1. **Safety supervisor domain.** Runs MathGround with formal-method-checked invariants. Non-bypassable. Sherman Simplex pattern (corpus: `sherman-simplex-architecture`).
2. **Real-time control domain.** Runs whole-body MPC at 200–500 Hz. Drives the actuator CAN-FD bus.
3. **Perception / policy domain.** Runs stereo depth, VLM queries, RL policy inference, manipulation policy. Latency-decoupled from control.

Power tree:

- 48 V hot-swap Li-ion pack (~1 kWh)
- 24 V rail for actuators
- 12 V rail for compute and sensors
- 5 V / 3.3 V regulated rails for MCU-tier logic

## Prior-art shielding

See [../prior-art/INDEX.md §7](../prior-art/INDEX.md). Hot-swap pack architecture cited to `hyundai-boston-dynamics-spot` (2015) and `spot-fuel-cell` (2020). Modern humanoid power architectures cited via `unitree-h1`, `apptronik-apollo`, etc.

## Planned content

- `mainboard/` — main compute integration board (KiCad source)
- `power-tree/` — schematics for the power distribution
- `som/` — Joule SOM integration breakout; alternative-SoM adapters
- `bus/` — CAN-FD topology, Ethernet topology
- `bom-electronics.csv` — electronics BOM (CC0)

## License

CERN-OHL-S 2.0 (schematics, layouts). Apache-2.0 (firmware on the boards). CC0-1.0 (BOM, schematic-derived data).
