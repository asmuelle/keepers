# TOOLS.md — Keepers tool surface

## Repo layout (since M0)

Domain logic lives in ONE root SPM package, `KeepersKit` (`Package.swift`), with the eight
DESIGN.md modules as targets under `Sources/<Module>` and tests under `Tests/<Module>Tests`
(fixtures in `Tests/<Module>Tests/Fixtures/`). `swift test` runs the whole suite on plain
macOS — no simulator, no device, no network. The iOS app shell (`App/` + `project.yml`)
composes the package via XcodeGen.

## just recipes

| Recipe | What it does | When to run |
|---|---|---|
| `just` | Lists all recipes | Orientation |
| `just bootstrap` | `xcodegen generate` from `project.yml`, then resolves SPM packages for scheme `Keepers` | Once after creating/changing `project.yml`; after fresh clone |
| `just build` | `swift build`, then `xcodebuild build` for the iOS Simulator (scheme `Keepers`) when bootstrapped | Fast compile check during development |
| `just test` | `swift test` (the hard gate), plus `xcodebuild test` on the **iPhone 16** simulator when bootstrapped — falls back to the first available iPhone simulator, or skips simulator tests with a note when no runtime exists | Before every commit; after any logic change |
| `just lint` | `swiftlint` over the repo; skips with a note when swiftlint is not installed (CI always runs it) | Before commit; CI runs it too |
| `just format` | `swiftformat .` | Rarely needed manually — the Claude Code hook formats on edit |
| `just ci` | `lint` + `build` + `test` in sequence | The pre-push gate; identical to what GitHub Actions runs |

`just bootstrap` still fails with a pointer to DESIGN.md M0 if `project.yml` is missing;
since M0 landed, `project.yml` exists and all recipes run end to end.

Tooling prerequisites (macOS): `brew install just xcodegen swiftformat swiftlint`, Xcode 16+
(swiftlint is optional locally — `just lint` skips without it). Simulator tests prefer an
iPhone 16 runtime and fall back to any installed iPhone simulator.

## External data sources / APIs

Keepers is deliberately API-free at runtime — all inference is on-device. The "API surface" is Apple frameworks:

| Surface | Used for | Auth / cost | Reference |
|---|---|---|---|
| Vision — `DetectFaceLandmarksRequest` | Eye landmarks → blink via eye-aspect-ratio | None; on-device | developer.apple.com/documentation/vision |
| Vision — `DetectFaceCaptureQualityRequest` | Per-face best-of-burst ranking (same subject only) | None; on-device | ditto |
| Vision — `CalculateImageAestheticsScoresRequest` | Baseline aesthetics + `isUtility` screenshots/docs filter | None; on-device | ditto |
| Vision — `GenerateImageFeaturePrintRequest` | Near-duplicate clustering via cosine distance | None; on-device | ditto |
| ImageIO / `CGImageSource` | Embedded JPEG preview + EXIF extraction from RAW | None | developer.apple.com/documentation/imageio |
| Core Image RAW | Full-resolution on-demand decode (loupe only) | None | developer.apple.com/documentation/coreimage |
| Core ML / coremltools | Custom aesthetic ranker + personalization head (ANE, FP16) | None at runtime; training offline | developer.apple.com/documentation/coreml |
| Foundation Models (AFM) | Optional content tags — **never in scoring** (invariant 2) | None; on-device; post-M2 | developer.apple.com/documentation/foundationmodels |
| StoreKit 2 | Subscriptions/trial/lifetime (M3) | App Store Connect account | developer.apple.com/documentation/storekit |

No third-party SaaS, no API keys, no rate limits in the product runtime. Any PR adding a network dependency to Ingest/Scoring/Ranker/ExportKit violates invariant 1 in AGENTS.md.

## Required env vars

| Variable | Purpose | Status |
|---|---|---|
| *(none)* | Local dev and CI need no secrets today | Current |
| `APP_STORE_CONNECT_KEY_ID` | ASC API key id for release automation (fastlane/notarized uploads) | Planned, M3+ |
| `APP_STORE_CONNECT_ISSUER_ID` | ASC API issuer for release automation | Planned, M3+ |
| `APP_STORE_CONNECT_KEY_P8` | ASC private key contents (CI secret, never committed) | Planned, M3+ |

Never hardcode values; CI secrets go in GitHub Actions secrets, local values in an untracked `.env` (already gitignored).

## Local services

None. There is no docker compose, no database server, no backend. Persistence is on-device SQLite (GRDB) inside the app sandbox — until that lands (M2), `PersistenceKit` ships an in-memory `SessionStoring` actor behind the same protocol seam, so M0/M1 have zero dependencies. The only "external hardware" dependency is a physical iPhone + USB-C card reader for M1/M2 device acceptance tests — simulator covers everything else via fixture RAW folders.

## CI (.github/workflows/ci.yml)

- Triggers: every `push` and `pull_request`. Runner: `macos-15`.
- Steps: checkout → `extractions/setup-just@v3` → `brew install swiftformat swiftlint` → **bootstrap guard** → `just ci`.
- Bootstrap guard: if `project.yml` is absent, CI emits a notice and skips build/test so the docs-only scaffold stays green. Once M0 lands `project.yml`, the same workflow installs `xcodegen` and runs `just bootstrap && just ci` — no workflow edits needed.
- Keep CI fast: simulator-only, no device tests, no code signing (`CODE_SIGNING_ALLOWED=NO` in the build recipe).

## AI harness notes (.claude/settings.json)

- **Hooks (PostToolUse on Write|Edit):** `swiftformat` auto-runs on any edited `.swift` file, then `swiftlint` prints the first 10 findings. Expect your Swift edits to be reformatted on save — don't fight the formatter.
- **Permissions:** `just`, `xcodebuild`, `xcrun`, `swift`, `swiftformat`, `swiftlint`, `xcodegen`, and read-only git are pre-allowed; everything else prompts.
- **Useful subagents for this repo:**
  - `tdd-guide` — start every new feature here; this codebase is pure-logic-heavy (scoring math, XMP, clustering) and ideal for test-first.
  - `code-reviewer` — run on every diff before commit (Definition of done requires it).
  - `security-reviewer` — mandatory for anything touching security-scoped bookmarks, file writes to user volumes, telemetry, or StoreKit; the privacy invariants are the brand.
  - `planner` — for milestone-sized work (each of M1–M3 should start with a plan).
- Skills worth invoking: `swift-concurrency-6-2` (strict-concurrency patterns), `swiftui-patterns` (KeepersUI), `tdd-workflow`.
