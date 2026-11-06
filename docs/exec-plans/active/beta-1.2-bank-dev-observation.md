# #55 Bank and Dev first-use observation — proposed checkpoint

Base c51a207. Validation profile: standard. Delivery posture: direct. Planning record under beta-1.2-flight-delivery.md. Leave the Build Costs workstream alone. The owner delegated production design on 2026-11-05 and deferred human feedback. Build and simulator permission is requested separately. See issues #55, #25 and #26 and the contextual tutorial section of ui-flows.md.

## Baseline and open question

GamePhysicalPublicRackView implements manual Bank supply and Dev inspection, with accessible labels, values and hints. GameShellView routes legal purchases through confirmation. AppPreferences claims automatic teaching once per eligible local post-roll turn, deferred when busy. Trade also reveals supply. The table-learning catalog exercises testAutomaticDevBankTeaching with end-turn-action. Prior model and UI proof establishes behavior; #55 still needs first-use observation.

## Assumptions to test first

First recruit someone who has played tabletop Catan, knows what the Bank and development deck are for, and has never used this app. With tips off, predict they will look to the shared piles, intentionally reveal Bank supply, and open the Dev deck expecting a chance to inspect before committing. Looking only in Trade or Hand, or avoiding the Dev deck for fear of spending, challenges the corresponding prediction. The optional #25 tour is the fallback for learning these controls. A person new to both Catan and the app has a different hypothesis: when buying first becomes legal, the contextual tip helps them find the pile and understand inspection versus purchase. Observe that separately; use #24 for practice and #26 for later lookup. Keep experience constant when comparing tips on and off.

Treat bar comprehension as independent of finding the Bank. Predict a player can compare two nonzero resource levels and recognize an empty resource, and understands that three segments describe rough stock. After both discovery tasks, use a visible-supply fixture with contrasting levels including zero. Ask which resource looks most plentiful, which has run out, and what they can tell about the number left. Record their words. Reading two segments as two cards challenges the encoding even if discovery succeeded. If the Bank was missed, this follow-up only measures interpretation. Preserve Trade's temporary reveal of public Bank and Dev bars and the approximation caption during this study.

## Locked observation proposal

Use independent first-time players for tips off and default tips on (aim for two per condition, reverse task order within each pair). If only one is available, start tips off and report a single case. A later enabled trial with that person measures learning only. Record prior Catan and accessibility experience; use each person's normal input method. Prepare a synthetic eligible post-roll turn, Trade closed, manually hidden supply, differentiated stock, clean per-game teaching marker. Verify actual fixture stock before the session. Reset to identical conditions between participants. Never send a real move.

Read one goal at a time: “You may need more brick. How plentiful is it in the shared supply?” and “You’re considering getting a development card. Find out what it would cost, then return to your turn with your resources intact.” Do not point, name controls, demonstrate gestures or rescue. Allow up to 90 seconds per goal; stop earlier on abandonment. Afterward ask what they expected to happen and what the supply display told them.

Record first action, path, elapsed time, prompt exposure, wrong turns, interpretation, explicit confirmation reached, spend/publication and any moderator help. Score direct Bank discovery only for an intentional Bank reveal plus a correct qualitative reading. Record incidental Trade reveal separately. Score Dev discovery only for opening the public deck confirmation and backing out without buying. Record alternative routes as task success if appropriate, separately from direct discovery. Enabled teaching is assisted by product copy. Report each participant and condition, including failures. No general usability claim from a small sample.

## Learning ownership

#55 tips explain a live opportunity and permit the real interaction or dismissal. Keep suppression separate from explicit Buy. #25 offers experienced Catan players an optional 60–90 second synthetic production-controls tour, from Messages resume/turn ownership through Hand, public piles, Build/Trade, owned Dev, board selection/confirm, Game Information and End Turn. Demonstrate unavailable/playable controls, link reference for costs/timing, support accessible equivalents, back/skip/replay, exact return and no publication. #26 owns safe lobby/table entry and a read-only reference: costs, turn order, Dev timing and scoring up front; setup, seven/discard/robber, trades, awards, victory target and visible strategy, with links to learning. #24 owns beginner action practice, corrective feedback and unprompted transfer.

## Verification contract and next gate

Human observation is deferred by the owner. The assumptions above guide design now. The delegated delivery plan owns implementation and automated proof. Preserve this protocol for later feedback and do not report the hypotheses as observed behavior. Build and simulator authorization remains separately pending.

<!-- verification-contract:start -->
| ID | Class | Source | Acceptance | Verification | Evidence | Status | Rationale |
| --- | --- | --- | --- | --- | --- | --- | --- |
| OBS-01 | mechanical | user | Document existing Bank/Dev behavior and explicit persona hypotheses | Source inspection | file:MessagesExtension/Sources/Components/GamePhysicalPublicRackView.swift | pass | Planning record only |
| OBS-02 | observable | issue 55 | Record unaided discovery with tips on and off | Human first-use observation | report:deferred-by-owner | pending | Feedback follows delegated implementation |
<!-- verification-contract:end -->

<!-- fresh-review:start -->
| Reviewer | Required | Verdict | Evidence |
| --- | --- | --- | --- |
| constraint-auditor | yes | pending | report:pending-observation |
<!-- fresh-review:end -->
