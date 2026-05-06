# datasets/

Pointers to training data sources used by the platform's RL and IL policies.

## Status (v0.0)

Stub. Datasets are *pointers*, not stored data — the platform repo references upstream open datasets by URL and hash.

## Planned dataset pointers

| Dataset | Use | Corpus citation | License |
|---|---|---|---|
| Open X-Embodiment | Manipulation pretraining | `open-x-embodiment` | CC-BY |
| ALOHA / Mobile-ALOHA datasets | IL manipulation baselines | `act-aloha`, `mobile-aloha` | CC0 / CC-BY |
| RT-2 datasets (where open) | VLA reference | `openai-rt-2` | mixed |
| Cassie / Berkeley Humanoid sim-data | RL locomotion | `cassie-osu`, `berkeley-humanoid` | varies |
| RoboNet | Cross-platform manipulation | (corpus entry TBD) | CC-BY |

## Local datasets (none yet)

Once the platform reaches Phase 2 (first physical subassembly), local teleop datasets will be collected and published here as pointers to a separate dataset hosting (likely Hugging Face Datasets, S3, or Zenodo).

## Schema for dataset pointers

Each dataset is a small JSON/YAML stub:

```yaml
name: open-x-embodiment
url: https://robotics-transformer-x.github.io/
sha256: TBD
license: CC-BY-4.0
corpus_citation: open-x-embodiment
purpose: VLA pretraining
```

## License

CC0-1.0 (per [../LICENSE-DATA](../LICENSE-DATA)) for the dataset pointers themselves. Upstream datasets retain their original licenses.
