# Product

This is concise design-facing context. Product behavior remains owned by [the MVP contract](docs/product-specs/mvp-contract.md) and [UI flows](docs/product-specs/ui-flows.md); current visual language lives in [DESIGN.md](DESIGN.md).

## Register

product

## Users

Unlucky Sevens is for 3-4 players who want an async Catan-style game inside an iMessage thread. Players use it in short sessions from Messages, often returning to a game bubble after time away, so the UI needs to reorient them quickly and keep the next legal action obvious.

## Product Purpose

The product brings a full standard-Catan loop to Messages while preserving deterministic rules, canonical state, and hidden-information boundaries. Success means players can invite, join, set up, play turns, trade, build, use development cards, recover interrupted games, leave play without stopping everyone else, and finish by victory, unanimous draw, or host end without leaving the Messages-first flow.

## Brand Personality

Compact, tactile, trustworthy. The interface should feel like a premium tabletop game compressed into Messages: physical enough to be legible and fun, restrained enough for repeated async play, and clear enough that state changes feel dependable.

## Anti-references

Avoid generic SaaS dashboards, debug/log surfaces, oversized marketing-style heroes, and decorative forms that compete with the board. Avoid UI that makes Messages feel like a cramped web app, hides the primary game state, or replaces core-rule clarity with ornamental chrome.

## Design Principles

- Board first: the live board is the primary object, with hand, dev-card, and utility surfaces supporting it.
- One obvious next action: setup, forced flows, and turns should always make the current legal action clear without teaching rules from scratch.
- Physical but efficient: use tabletop affordances where they improve scanability, but keep controls dense enough for the Messages host.
- Canonical state stays visible: presentation can be polished, but it must not obscure whose turn it is, what is pending, or what changed.
- Trust over spectacle: polish should reinforce reliability, secrecy, and deterministic game flow.

## Accessibility & Inclusion

The UI should preserve readable contrast, Dynamic Type behavior where feasible in the Messages host, VoiceOver labels for icon-first controls, and reduced-motion alternatives for animated surfaces. Color must not be the only indicator of player identity, legality, or resource state.
