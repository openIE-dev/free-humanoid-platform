# sim/

Simulation models and pipelines.

## Status (v0.0)

Stub.

## Reference simulators

- **MuJoCo / MJX** — primary simulator. The descriptor's MJCF output (from OpenLoco's compiler) is the source. MuJoCo is the OpenLoco recommended default and is what OpenLoco's `gait_harness` runs against.
- **[Genesis](https://github.com/Genesis-Embodied-AI/Genesis)** — secondary; the GPU-parallelized open-source unified-multi-physics engine (rigid + soft + MPM + FEM + fluid) released December 2024 by a CMU/Stanford/MIT/Tsinghua/Peking/ETH/UMD academic collaboration. Apache-2.0. 43M FPS rigid-body simulation on a single RTX 4090; differentiable simulation for gradient-based policy optimization. URDF/MJCF interoperable, so the OpenLoco descriptor compiles to it without modification. Use for sim-to-real-at-scale RL training. Corpus citation: [`genesis-embodied-ai-simulator`](https://github.com/openIE-dev/free-humanoid-corpus/blob/main/contention_packets/control-sim-to-real.html).
- **Drake** — tertiary; used for whole-body MPC validation where deterministic semantics matter.
- **Gazebo / RViz** — tertiary; used for ROS 2 development.
- **Isaac Sim / Isaac Lab** — tertiary; NVIDIA's GPU-parallelized RL environment.

## Pipelines

- **Walking gait training:** RL policy for locomotion mode and gait. Trained against the MuJoCo model. OpenLoco's `gait_harness` is the runtime.
- **Manipulation policy training:** IL via ACT or diffusion-policy baseline. Trained on teleop data; tested in MuJoCo before deployment.
- **Sim-to-real:** domain randomization per `openai-dactyl` posture.

## Prior-art shielding

OpenLoco's existing simulation toolchain: `gait_harness`, `XfrcBackend`, `PhysicsBackend` trait, `CannedPhysics`, MuJoCo FFI integration. All open-source under OpenLoco's CC0/Apache-2.0 hybrid license.

Training pipelines cite the corpus chains at [../prior-art/INDEX.md §4](../prior-art/INDEX.md).

## Planned content

- `mujoco/` — MuJoCo model files (generated from descriptor)
- `drake/` — Drake URDF + cost / constraint files
- `training/` — RL and IL training pipelines
- `assets/` — meshes, textures (generated from descriptor's `bake` output)

## License

Apache-2.0 for code. CC0-1.0 for descriptor-derived models.
