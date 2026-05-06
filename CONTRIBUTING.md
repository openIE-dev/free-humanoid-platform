# Contributing to Free Humanoid Platform

Thank you for considering a contribution. The platform is open hardware, open firmware, open data, and is governed by an unusually strict defensive-publication discipline that all contributors are asked to honor. This document is the contract.

---

## Quality bar

A contribution is acceptable for merge when:

1. **Every load-bearing design choice cites a [Free Humanoid Corpus](https://github.com/openIE-dev/free-humanoid-corpus) entry by id.** "Load-bearing" means: any choice that changes the descriptor, the BOM, the firmware HAL, the safety supervisor's invariants, the policy architecture, or the comms protocol. Cosmetic changes (typo fixes, README copy edits, formatting) do not require corpus citation.

2. **The cited entry actually anticipates the choice.** The contributor reads the corpus entry and confirms that its `prior_art_notes` field, taken on its own, reads as element-by-element 102/103 anticipation of the design choice as introduced. If the existing entries don't anticipate the choice, the contributor either (a) proposes a new corpus entry to the corpus repo, (b) chooses a different design that is anticipated, or (c) marks the choice `draft` in the descriptor and documents the invalidation gap explicitly.

3. **The commit message names the corpus entry id.** A commit that adds, say, a new actuator type to the descriptor reads `[descriptor] add cycloidal at hip; cite sumitomo-cyclo` rather than `[descriptor] update actuator block`. The audit trail is part of the defensive publication.

4. **Documentation updates are part of the same commit.** If a design choice changes, [ARCHITECTURE.md](ARCHITECTURE.md), [prior-art/INDEX.md](prior-art/INDEX.md), and any subdirectory README that depends on the choice are updated in the same commit. The corpus citation goes in the documentation, not just the commit message.

5. **Hardware contributions include an open-tooling buildability check.** Mechanical CAD must be readable in FreeCAD or OpenSCAD, not only in proprietary tools. PCB layouts must be readable in KiCad. Firmware must build with open toolchains (GCC / Clang / cargo / etc.). Closed-tool-only contributions do not meet the open-everything principle and are not acceptable.

6. **Safety-relevant contributions go through review by the safety supervisor maintainer (currently MathGround integration team).** Any change to the safety supervisor invariants, fail-safe pose, or fault-handling logic requires sign-off. This is non-negotiable per ARCHITECTURE §2.7 and the fail-safe-to-inert design principle.

---

## Defensive publication norms

The platform inherits the corpus's posture: every commit is a public disclosure that, taken with its commit timestamp and the cryptographic timestamping ceremony, becomes citeable as 102/103 prior art on the date of disclosure.

This means:

- **Don't strip rationale.** Comments in source code, design notes in CAD files, and prose explanation in documentation are part of the disclosure. A commit that explains *why* a design choice was made is more useful as prior art than a commit that just changes a number.

- **Cite primary sources.** When the corpus entry you cite refers to an academic paper, link the paper. When it refers to a patent, give the patent number. The chain corpus → primary source must be traversable.

- **Mark drafts as drafts.** A design choice that is not yet anticipated by any corpus entry and that the contributor wants merged anyway must be marked `draft: true` in the descriptor or `[DRAFT]` prefixed in the architecture. Drafts are merged only with explicit maintainer approval and a documented gap.

---

## No-patent-aggression contributor norm

By contributing, you agree that you will not assert any patent (held by you, your employer, or any party you control or are controlled by) against the platform, its derivatives, its users, its forks, or any other contributor, in connection with any matter covered by the platform's design, BOM, firmware, descriptors, or documentation.

This is a contributor norm, not a license grant — the actual license terms (CERN-OHL-S 2.0, Apache 2.0, CC-BY-SA 4.0, CC0 1.0) already cover patent grants where they apply. The norm exists to make the social contract explicit.

This norm aligns with the Open Invention Network and the corpus's defensive posture. Contributors who cannot agree to it should not contribute, but are still free to use the platform under its license terms.

---

## Reference-design-not-product

The platform is a reference design. There is no warranty, no support contract, no service tier, no SLA, no certified configuration. Forks are encouraged. Forks that productize without contributing improvements back are tolerated but not supported — the strongly-reciprocal CERN-OHL-S license does most of the work here.

If you are deploying the platform in a safety-critical environment, you are responsible for the safety case. The contributor base provides the safety supervisor architecture (see ARCHITECTURE §2.7) but cannot certify that any specific deployment satisfies any specific regulatory regime. Coordinate with your local regulatory authority and your safety engineering team.

---

## Pull request checklist

Before opening a PR:

- [ ] Every load-bearing design choice cites at least one corpus entry id.
- [ ] The cited entry actually anticipates the choice.
- [ ] Commit messages name the corpus entry id where applicable.
- [ ] Documentation (README, ARCHITECTURE, prior-art/INDEX, subdirectory READMEs) updated.
- [ ] Open-tooling buildability check passes for any hardware artifact.
- [ ] Safety-relevant changes flagged for safety-maintainer review.
- [ ] Drafts marked as drafts.
- [ ] Contributor agrees to the no-patent-aggression norm above.

---

## Reporting security or safety issues

For safety-critical issues — supervisor bypass, fail-safe failure modes, undocumented deadlocks — please email the safety maintainer directly rather than opening a public issue, until the fix is in. Coordinated disclosure on the public side following remediation.

For non-safety security issues, open a regular issue. The platform is open; threat models that depend on the closed-source posture do not apply here.

---

## Style guide for documentation

- Prose, not bullets, where the content is argued. Bullets where it is enumerated.
- Cite corpus entries inline as `` `entry-id` `` (backticks).
- Use markdown link syntax for cross-references between platform docs.
- Architecture decisions: argued prose, with options, recommendation, and TBD callout where the user (David) needs to make the call.
- Subsystem READMEs: scoped to the concern, no architectural argument. Architectural argument lives in [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Maintainer approval

Maintainership of the platform is currently held by the OpenIE / Free Humanoid project lead (David Charlot). Component-area maintainers (chassis, actuators, electronics, firmware, control, sim, safety supervisor) are appointed as the project grows. Until appointments are formalized, all PRs route to the project lead.
