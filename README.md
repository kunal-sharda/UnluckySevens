# Unlucky Sevens

Unlucky Sevens is an iMessage-first, GamePigeon-style implementation of standard Catan for 3-4 players.

## Generate the Xcode Workspace

```bash
./scripts/gen.sh
```

If scripts are not executable locally yet:

```bash
chmod +x scripts/*.sh
```

## Open the Workspace

```bash
open UnluckySevens.xcworkspace
```

## Run in iOS Simulator (Messages Extension)

1. Run the Messages extension scheme (or host app scheme if configured that way).
2. Open iOS Simulator.
3. Launch Messages and open any conversation.
4. Open the app drawer and select Unlucky Sevens.

## Hello Bubble test

1. Run the host app scheme on iPhone Simulator.
2. Open Messages and any thread.
3. Tap `+` and launch Unlucky Sevens.
4. Tap `Send Debug Bubble`.
5. Confirm the transcript bubble shows metadata:
   - Caption: `Unlucky Sevens Debug v1`
   - Subcaption: `debugId: <first 8 chars>`
   - Trailing subcaption: `ts: <unix seconds>`
6. Tap the bubble you just sent.
7. Confirm the extension status text updates:
   - `Send: sent`
   - `Selection: message selected` (or briefly pending)
   - `selectedMessage.url: provided` on ideal path, or `missing` on Simulator fallback path
   - `Payload source: url` or `summaryText`
   - `Decode: Decoded: type=debug, v=1, ...`
8. Repeat twice and confirm debugId/timestamp change each send.
9. Simulator caveat: message selection can lag; the extension now retries for about 1.2 seconds before settling.

## Documentation

- [Product Requirements Document](docs/UnluckySevensPRD.pdf)
- [Architecture / Decisions](docs/decisions.md)
