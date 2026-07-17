# Harness Gate Profiles and Active-Plan Semantics

Completed 2026-07-11.

This slice separated `lightweight`, `standard`, and `release-critical` validation profiles. Selected-plan completion became independent from unfinished sibling plans, while sibling constraints remained visible as audit notices. The release gate retained exhaustive practical validation.

Durable semantics now live in [ExecPlan rules](../PLANS.md), [constraint verification](../../quality/constraint-verification.md), [QA](../../quality/qa.md), and the root `Makefile`.

Recorded validation included 29 focused checker tests, live active-plan schema checks, negative release-contract coverage, fresh constraint and architecture review, and a passing standard completion lane.
