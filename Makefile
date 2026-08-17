.PHONY: gen clean doc-freshness build test-quick test-full test-features practical-gate completion-contract plan-profile completion-gate completion-profile-lightweight completion-profile-standard completion-profile-release-critical release-contract release-gate harness-audit harness-check-tests

DOC_FRESHNESS_BASE ?= HEAD
DOC_FRESHNESS_FLAGS ?=
TEST_SIMULATOR_DESTINATION ?= platform=iOS Simulator,name=iPhone 17,OS=latest
FEATURE ?= smoke

gen:
	./scripts/gen.sh

clean:
	./scripts/clean.sh

doc-freshness:
	./scripts/check-doc-freshness.sh --base $(DOC_FRESHNESS_BASE) $(DOC_FRESHNESS_FLAGS)

build: doc-freshness gen
	xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build

test-quick:
	bash ./scripts/run-ui-test-lane.sh quick "$(FEATURE)"

test-full:
	bash ./scripts/run-ui-test-lane.sh full

test-features:
	bash ./scripts/run-ui-test-lane.sh list

practical-gate: doc-freshness gen
	swift test --package-path Packages/ULS_CoreGame --skip ULS_CoreGameEvals
	swift test --package-path Packages/ULS_CoreGame --filter ULS_CoreGameEvals
	swift test --package-path Packages/ULS_Transport
	xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath DerivedData/MessagesOnlyValidation CODE_SIGNING_ALLOWED=NO build
	xcodebuild -workspace UnluckySevens.xcworkspace -scheme MessagesExtension -destination 'generic/platform=iOS Simulator' build
	xcodebuild -workspace UnluckySevens.xcworkspace -scheme UnluckySevens-Workspace -destination '$(TEST_SIMULATOR_DESTINATION)' -skip-testing:UnluckySevensUITests test

completion-contract:
	@test -n "$(PLAN)" || (echo "error: PLAN=<active ExecPlan path> is required" >&2; exit 2)
	python3 ./scripts/check-verification-contract.py --plan "$(PLAN)" --mode complete

plan-profile:
	@test -n "$(PLAN)" || (echo "error: PLAN=<active ExecPlan path> is required" >&2; exit 2)
	@python3 ./scripts/check-verification-contract.py --plan "$(PLAN)" --print-profile

completion-gate: completion-contract
	$(MAKE) harness-audit
	git diff --check
	@profile="$$(python3 ./scripts/check-verification-contract.py --plan "$(PLAN)" --print-profile)"; \
		echo "Completion validation profile: $$profile"; \
		$(MAKE) "completion-profile-$$profile"

completion-profile-lightweight: doc-freshness

completion-profile-standard: build

completion-profile-release-critical: practical-gate

release-contract: completion-contract
	@profile="$$(python3 ./scripts/check-verification-contract.py --plan "$(PLAN)" --print-profile)"; \
		test "$$profile" = "release-critical" || \
		(echo "error: release-gate requires a release-critical plan (found $$profile)" >&2; exit 2)

release-gate: release-contract
	$(MAKE) harness-audit
	git diff --check
	$(MAKE) practical-gate

harness-audit:
	python3 ./scripts/check-harness.py

harness-check-tests:
	python3 -m unittest discover -s scripts/tests -p 'test_*.py'
