# Design Workspace

[DESIGN.md](../../DESIGN.md) owns current visual language. Production assets live under `MessagesExtension/Resources`; this directory does not duplicate them.

- `references/manifest.json` lists the small set of explicitly user-approved durable binary references. It is currently empty.
- [cleanup-receipt.md](cleanup-receipt.md) records the one-time numbered-pass cleanup, reduction, and production-asset hash proof.
- `workbench/` is ignored local scratch for candidates and comparison work. A checkpointed active ExecPlan must explicitly own it while a decision is pending; the harness reports owned files as an in-flight notice. Empty it when the decision closes so unowned residue fails the audit.

Keep outcomes and decisions, not numbered iteration history.

## Artwork Credits

- “Factory” by [Ardhian Rama](https://thenounproject.com/creator/ardhianrama777/), from the Noun Project.
- “Ship” by [Rémy Médard](https://thenounproject.com/creator/catalarem/), from the Noun Project.

All other artwork in Unlucky Sevens was created by Kunal Sharda.
