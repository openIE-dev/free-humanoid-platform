# sim/

Simulation models and pipelines.

## Status (v0.0)

Stub.

## Reference simulators

- **MuJoCo / MJX** — primary simulator. The descriptor's MJCF output (from OpenLoco's compiler) is the source. MuJoCo is the OpenLoco recommended default and is what OpenLoco's `gait_harness` runs against.
- **Drake** — secondary; used for whole-body MPC validation where deterministic semantics matter.
- **Gazebo / RViz** — tertiary; used for ROS 2 development.
- **Isaac Sim** — tertiary; alternative for parallel RL training.

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
