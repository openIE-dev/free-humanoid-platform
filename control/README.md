# control/

Whole-body MPC reference, RL policy weights, manipulation policy.

## Status (v0.0)

Stub.

## Architectural posture

Layered control:

1. **Low-level (200–500 Hz):** whole-body MPC. Textbook formulation (no patentable claims). Implemented in Rust per OpenLoco's `gait_harness` posture or in C++ if leveraging an existing MPC library (Crocoddyl, Aligator). Outputs per-actuator impedance commands.

2. **Mid-level (50–100 Hz):** RL policy for locomotion mode and gait. Trained in MuJoCo via OpenLoco's `gait_harness` (the same harness that runs the existing ANYmal-WL and Mini-Whegs gaits). Outputs MPC reference trajectories.

3. **High-level (10 Hz):** manipulation policy. Imitation-learning baseline (ACT or diffusion-policy variant). Optional VLA upgrade. Outputs target end-effector trajectories.

## Prior-art shielding

See [../prior-art/INDEX.md §4](../prior-art/INDEX.md):
- MPC: textbook (no specific corpus citation needed; `mit-cheetah` family establishes the open-MPC tradition for legged platforms).
- RL: `mit-cheetah-2`, `cassie-osu`, `mini-cheetah`, `digit-meta`, `berkeley-humanoid`.
- IL: `act-aloha`, `mobile-aloha`, `diffusion-policy`.
- VLA: `openai-rt-2`, `open-x-embodiment`, `physical-intelligence-pi-zero`, `skild-foundation-model`, `covariant-rfm`.

## Planned content

- `mpc/` — whole-body MPC reference
- `rl/` — RL policy training scripts and weight checkpoints
- `il/` — IL policy training scripts and weight checkpoints
- `vla/` — optional VLA wrapper (subprocess to a foundation-model API or local model)
- `eval/` — evaluation harnesses

## License

Apache-2.0 (per [../LICENSE-SOFTWARE](../LICENSE-SOFTWARE)) for code. CC0-1.0 (per [../LICENSE-DATA](../LICENSE-DATA)) for trained policy weights treated as data.
