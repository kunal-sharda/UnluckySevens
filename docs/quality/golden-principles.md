# Golden Principles

These principles are the highest-signal engineering rules for the repo. If a change would violate one of them, stop and make the decision explicit.

## Engine and UI

- The UI must not become a second rules engine.
- Anything that determines legality or mutates canonical state belongs in `ULS_CoreGame`.
- Viewer-safe summaries and legal/default action queries should come from the engine, not be reconstructed ad hoc in `MessagesExtension`.

## Determinism and Authority

- Determinism is sacred: gameplay outcomes must come from persisted deterministic state, never device-local randomness.
- Lobby progression and current-player gameplay actions should publish canonical `STATE` directly whenever the acting device can do so safely.
- Responder-side trade/discard messages are the only remaining non-canonical transport path, but they should still stay on the same per-game session so the transcript behaves like one game thread.
- Responder or legacy `INTENT` messages are inert until incorporated into a later canonical state, and the shell should prefer recovered `STATE` over showing a raw response bubble whenever recoverable context exists.

## Transport and Secrecy

- `ULS_Transport` owns the message/protocol boundary.
- The canonical state may contain hidden information, but the UI may expose only viewer-safe projections.
- Payload-size regressions are product regressions.

## Repo Hygiene

- Generated Xcode files are not source of truth and must not be committed.
- Tests and evals are the real safety rail; keep them green.
- Historical docs and ExecPlans should point to owner docs rather than becoming second sources of truth.
