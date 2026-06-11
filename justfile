# Keepers — on-device AI photo culling (iOS)
# Single source of truth for dev commands. Agents: use these, never raw xcodebuild.

project   := "Keepers.xcodeproj"
scheme    := "Keepers"
simulator := "iPhone 16"

# List available recipes
default:
	@just --list

# Generate the Xcode project from project.yml via XcodeGen and resolve SPM packages
bootstrap:
	@command -v xcodegen >/dev/null 2>&1 || { echo "error: xcodegen not installed — run 'brew install xcodegen'"; exit 1; }
	@if [ ! -f project.yml ]; then \
		echo "error: project.yml not found — this repo is still a docs-only scaffold."; \
		echo "next:  create project.yml + SPM packages per DESIGN.md milestone M0, then re-run 'just bootstrap'."; \
		exit 1; \
	fi
	xcodegen generate
	xcodebuild -resolvePackageDependencies -project {{project}} -scheme {{scheme}}

# Build: SPM package for the host, then the app shell for the iOS Simulator (scheme Keepers)
build:
	swift build
	@if [ ! -d {{project}} ]; then \
		echo "note: {{project}} not generated — run 'just bootstrap' to also build the app shell."; \
	else \
		xcodebuild build -project {{project}} -scheme {{scheme}} \
			-destination 'generic/platform=iOS Simulator' \
			CODE_SIGNING_ALLOWED=NO; \
	fi

# Run the test suite: SPM tests on the host, plus simulator tests when bootstrapped and a simulator exists
test:
	swift test
	@if [ ! -d {{project}} ]; then \
		echo "note: {{project}} not generated — skipping simulator tests (run 'just bootstrap' first)."; \
	elif xcrun simctl list devices available | grep -q "{{simulator}} ("; then \
		xcodebuild test -project {{project}} -scheme {{scheme}} \
			-destination 'platform=iOS Simulator,name={{simulator}}' \
			CODE_SIGNING_ALLOWED=NO; \
	else \
		sim_name=$(xcrun simctl list devices available | sed -nE 's/^[[:space:]]+(iPhone [^(]+[^( ]) \(.*/\1/p' | head -1); \
		if [ -n "$sim_name" ]; then \
			echo "note: simulator '{{simulator}}' unavailable — using '$sim_name'."; \
			xcodebuild test -project {{project}} -scheme {{scheme}} \
				-destination "platform=iOS Simulator,name=$sim_name" \
				CODE_SIGNING_ALLOWED=NO; \
		else \
			echo "note: no iPhone simulator runtime available — skipping simulator tests (SPM tests already ran)."; \
		fi; \
	fi

# Lint all Swift sources with SwiftLint (skips gracefully when not installed)
lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint --quiet; \
	else \
		echo "note: swiftlint not installed — skipping lint ('brew install swiftlint'; CI runs it)."; \
	fi

# Format all Swift sources with swiftformat
format:
	@command -v swiftformat >/dev/null 2>&1 || { echo "error: swiftformat not installed — run 'brew install swiftformat'"; exit 1; }
	swiftformat .

# Full gate: lint + build + test (what GitHub Actions runs)
ci: lint build test
