# firmware/

HAL, behaviors, safety supervisor, comms.

## Status (v0.0)

Stub. Planned structure mirrors OpenLoco's Rust+Cargo posture and integrates with the existing OpenLoco actuator traits (`Actuator`, `ImpedanceCommand`, `SafetyWrapper`, `FaultFlags`).

## Modules

```
firmware/
  hal/             actuator HAL, sensor HAL, compute-domain bridge
  safety/          MathGround integration, Simplex supervisor, CBF invariants
  behaviors/       walking, standing, manipulation, safe-pose-recovery
  comms/           CAN-FD low-level, ROS 2 bridge, gRPC telemetry
  policies/        RL policy runtime, IL policy runtime, VLA policy stub
```

## Architectural posture

- **HAL** — the contract. Interface-defined, swappable per-tier (Tier 0 Dynamixel / Tier 1 SimpleFOC / Tier 2 Moteus per OpenLoco convention). Tier 2 is the recommended default; Tier 1 / Tier 0 are valid for low-cost forks.

- **Safety** — MathGround default. Sherman Simplex pattern with CBF (`control-barrier-functions`) for the verified fallback controller. Runs on a **separate compute domain** from the control domain (see [../electronics/README.md](../electronics/README.md)) and is non-bypassable from the policy or behaviors layer.

- **Behaviors** — finite-state behaviors corresponding to descriptor modes (`safe_pose`, `standing`, `walking`, `manipulation`). Behavior transitions go through the safety supervisor. The behavior layer cannot directly command actuators bypassing the safety wrapper.

- **Comms** — CAN-FD for actuator/sensor bus (Moteus-compatible). ROS 2 bridge for development. gRPC for production telemetry. WebRTC for teleop video.

- **Policies** — RL for locomotion (textbook formulation, MuJoCo-trained, see [../sim/README.md](../sim/README.md)). IL for manipulation (ACT or diffusion-policy baseline). VLA optional.

## Prior-art shielding

- HAL: `mjbots-moteus`, `odrive`, `simplefoc` (open BLDC stacks).
- Safety: full chain at [../prior-art/INDEX.md §5](../prior-art/INDEX.md). Anchored at `asimov-positronic-robots` (1940), `sherman-simplex-architecture` (1995), `control-barrier-functions` (2007).
- Comms: ROS 2 corpus tag `software-ros2`; CAN-FD ISO standard.
- Policies: `mit-cheetah` family for RL locomotion; `act-aloha`, `diffusion-policy`, `mobile-aloha` for IL; `openai-rt-2`, `physical-intelligence-pi-zero` for VLA.

## Planned content

- HAL trait definitions (Rust) compatible with OpenLoco's actuator traits.
- MathGround integration shim — interface contract defined here, implementation via the MathGround project.
- Behavior implementations per mode.
- Policy runtime hooks.

## License

Apache-2.0 (per [../LICENSE-SOFTWARE](../LICENSE-SOFTWARE)).
