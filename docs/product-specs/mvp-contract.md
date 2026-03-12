# MVP Contract

This document describes the current MVP product contract in plain language. It is derived from the PRD and current repo decisions, but it is not the lockfile for architecture or protocol changes. Those remain in [`../decisions.md`](../decisions.md).

## Player Promise

Unlucky Sevens should let a group of 3-4 players play a full asynchronous game of standard Catan inside an iMessage thread, from invite through setup to a deterministic win at 10 VP.

## MVP Scope

The current MVP includes:

- iMessage-first async play inside a group conversation
- full standard Catan rules for setup, turns, building, trading, dev cards, awards, and victory
- deterministic board generation and gameplay randomness
- a bubble-first experience where the game remains legible from transcript bubbles and the expanded view
- secrecy-safe UI that shows opponents by hand size, not hand composition

## Explicit Non-Goals

The current MVP does not include:

- GameKit or a backend service
- house rules or gameplay twists as part of the shipped contract
- AI opponents or 2-player variants
- monetization, cosmetics, analytics, or crash reporting as ship criteria

## MVP Experience Pillars

The UI and engine should preserve these product qualities:

- turns feel clear and low-friction in Messages
- the async authority model avoids desync and partial updates
- the board and audit surfaces explain the current state without leaking hidden information
- common actions stay compact enough for an iMessage context

## Relationship to Other Docs

- Use [`../decisions.md`](../decisions.md) for locked decisions.
- Use [`../../ARCHITECTURE.md`](../../ARCHITECTURE.md) for system and protocol boundaries.
- Use [`prd-verbatim.md`](prd-verbatim.md) for the original wording from the PRD.
