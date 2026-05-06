# actuators/

Actuator family specifications: cycloidal reducers, harmonic drives, QDD, tendon-driven.

## Status (v0.0)

Stub. The actuator distribution is encoded in [`../descriptor/free-humanoid.udd.json`](../descriptor/free-humanoid.udd.json) `actuator_slots` block. The recommended distribution is **Option C — hybrid**:

| Joint group | Type | Corpus citation |
|---|---|---|
| Hip yaw / roll / pitch | cycloidal | `sumitomo-cyclo` (1937) |
| Knee pitch | cycloidal | `sumitomo-cyclo` |
| Ankle pitch / roll | QDD (BLDC + 9:1 planetary) | `mini-cheetah` (2019) |
| Shoulder pitch / roll / yaw | harmonic-drive | `honda-e0` (1986) |
| Elbow pitch | harmonic-drive | `honda-e0` |
| Wrist (3-DoF) | tendon-driven | `shadow-dexterous-hand` (2002) |
| Hand (synergy-reduced) | tendon-driven | `pisa-iit-softhand` (2012), `shadow-dexterous-hand` |
| Waist yaw, neck (2-DoF) | QDD | `mini-cheetah` |

This distribution is the **recommendation**. The architectural call (Option A pure cycloidal vs. Option B pure QDD vs. Option C hybrid) is in [../ARCHITECTURE.md §1.2 / §9](../ARCHITECTURE.md).

## Prior-art shielding

See [../prior-art/INDEX.md §2](../prior-art/INDEX.md). The corpus carries 89 years of prior art on cycloidal (`sumitomo-cyclo` 1937), 40 years on harmonic-drive in humanoids (`honda-e0` 1986), 11+ years on QDD (`mit-cheetah` 2009 → `mini-cheetah` 2019), and 24 years on tendon-driven hand (`shadow-dexterous-hand` 2002).

## Planned content

- `cycloidal/` — cycloidal reducer specs, sourcing notes, mounting CAD pointers
- `harmonic-drive/` — harmonic-drive specs, sourcing
- `qdd/` — QDD module specs, BLDC selection (T-Motor R60 / R80 family or commodity), planetary reducer
- `tendon/` — tendon routing, cable, anchor design
- `controllers/` — open BLDC controller integration: `mjbots-moteus` (recommended), `odrive`, `simplefoc`

## License

CERN-OHL-S 2.0 (CAD, mounting designs). Apache-2.0 (controller firmware integrations). CC0-1.0 (specs and sourcing data).
