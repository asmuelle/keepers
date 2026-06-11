# AGENTS.md — Operating Manual for Keepers

## Project snapshot

**Keepers** is on-device AI photo culling for iOS: it scores, blink-checks, groups, and shortlists a 3,000-shot RAW session directly off a USB-C card or SSD — no import, no cloud, no desktop. Payer: wedding/event/portrait photographers shooting 1,000–5,000 frames per session, at $7.99/mo or $69.99/yr Pro (free 300-frame tier as funnel). Pipeline status: **recommended** (#4 of 9 finalists, edge-AI run). The phone never uploads a photo: that is the product, not a feature.

## Read first

1. `README.md` — research dossier: concept, market evidence, adversarial review. The skeptic's findings are binding context.
2. `DESIGN.md` — architecture, data model, flows, milestones (M0–M3), risks. Build in milestone order.
3. `TOOLS.md` — commands, frameworks/API surface, env vars, CI behavior, harness notes.

## Commands

`just` is the single source of truth. Never invoke raw `xcodebuild`/`swiftlint` directly.

| Recipe | What it does |
|---|---|
| `just` | List all recipes |
| `just bootstrap` | Generate `Keepers.xcodeproj` from `project.yml` via XcodeGen + resolve SPM |
| `just build` | Build scheme `Keepers` for iOS Simulator |
| `just test` | Run tests on the iPhone 16 simulator |
| `just lint` | SwiftLint over the codebase |
| `just format` | swiftformat the whole repo |
| `just ci` | lint + build + test (what GitHub Actions runs) |

All recipes fail with guidance if the project is not yet bootstrapped (no `project.yml` / `.xcodeproj`). Until M0 lands, that failure is expected.

## Architecture summary

A thin SwiftUI app shell composes eight SPM packages around one pipeline: **IngestKit** opens a security-scoped bookmark to the card and extracts embedded JPEG previews from RAWs (never importing them); **ScoringKit** batch-runs four Vision framework requests under a thermal-aware scheduler; **RankerKit** adds a custom Core ML aesthetic score with a per-photographer personalization head; **PersistenceKit** (GRDB/SQLite) stores score cards and decisions durably; **KeepersUI** surfaces the shortlist/burst/loupe review; **ExportKit** writes XMP star/label sidecars back onto the card for Lightroom Classic. **KeepersCore** holds pure domain logic; **TaggingKit** isolates optional AFM tags away from scoring.

```
App/  → composition root only
Packages/ KeepersCore · IngestKit · ScoringKit · RankerKit
          ExportKit · PersistenceKit · TaggingKit · KeepersUI
```

Dependency rule: KeepersCore depends on nothing; kits depend only on KeepersCore; UI/App compose kits. See DESIGN.md for the full map.

## Coding standards

- Swift 6, strict concurrency everywhere; zero warnings is the bar. `Sendable` correctness is not optional in a batch-pipeline app.
- Files < 800 lines, functions < 50 lines. Many small files over few large ones; one type per file as the default.
- Immutability by default: `let`, value types, `struct` domain models. ScoreCards and CullDecisions are append-only — supersede, never mutate.
- Explicit error handling at every boundary: typed `throws` at file-system, Vision, Core ML, and StoreKit edges. No `try!`/`try?` swallowing in production code paths; surface user-readable messages in UI, keep diagnostic detail in `BatchRun`.
- No hardcoded secrets — env vars only (today there are none; see TOOLS.md before adding any).
- Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`.
- Naming: PascalCase types, camelCase members, `is/has/should/can` boolean prefixes, UPPER_SNAKE_CASE constants.

## Testing policy

- TDD: write the failing test first (Swift Testing preferred; XCTest where UI/integration requires it). 80%+ coverage target, AAA pattern, descriptive behavior names.
- What matters most for THIS product, in order:
  1. **Pure-math correctness**: eye-aspect-ratio blink math, composite score weighting, feature-print cosine clustering, burst grouping — deterministic golden-value tests in KeepersCore.
  2. **XMP golden files**: serialization must byte-match fixtures known to import cleanly into Lightroom Classic; ratings/labels round-trip is the product promise.
  3. **Bookmark lifecycle**: security-scoped start/stop pairing, stale bookmark resolution, yanked-card behavior — simulated via protocol-injected file access.
  4. **Scheduler behavior**: thermal-state transitions (injected, not real heat), checkpoint/resume mid-batch, durable progress.
  5. **Metering/entitlements** (M3): free-tier frame counting, offline purchase-state caching.
- Vision/Core ML outputs are non-portable across OS versions: test the pipeline *around* them with stubbed scores; reserve real-model assertions for device smoke tests, not CI.

## PRODUCT INVARIANTS (non-negotiable)

1. **No image egress, ever.** No photo bytes, previews, thumbnails, or feature prints leave the device. `IngestKit`, `ScoringKit`, `RankerKit`, `ExportKit` must not import networking modules — CI greps for `URLSession`/`Network` imports in those packages and fails the build (M2 gate).
2. **No LLM in the batch scoring loop.** Composite scores are a pure function of Vision outputs + the Core ML ranker. `TaggingKit` (AFM tags) must never be imported by ScoringKit or RankerKit, and tag data must never feed a ScoreCard. Testable: ScoreCard schema has no tag-derived fields.
3. **Cull in place — never import.** Full RAW files are never copied into the sandbox. Batch work reads embedded JPEG previews only; full Core Image RAW decode happens solely on-demand for the frame under the loupe. Testable: sandbox growth < 1MB per ingested frame in the M1 integration test.
4. **Non-destructive, always.** Originals on the card are never modified, moved, or deleted. The only writes to the source volume are explicit, user-confirmed `.xmp` sidecar files. There is no delete feature for originals — rejects are ratings; deletion belongs to Lightroom.
5. **Security-scoped access is paired and audited.** Every `startAccessingSecurityScopedResource` has a guaranteed matching stop (defer/scoped helper); stale bookmarks re-resolve or fail with a user-actionable error, never a crash.
6. **Deterministic scoring.** Same frames + same `modelVersion` ⇒ identical scores and ordering. Every ScoreCard is stamped with `modelVersion`; re-scores append new cards rather than overwriting (asserted in tests, M2).
7. **Thermal safety gates.** The batch scheduler must reduce concurrency at `.serious` and checkpoint+pause at `.critical` thermal state — verified with injected thermal states. Never ship a code path that ignores `ProcessInfo.thermalState`.
8. **Honest XMP semantics.** Export writes star ratings and color labels only; Lightroom pick/reject *flags* are catalog-only and must not be claimed or faked in UI copy or docs.
9. **Telemetry is opt-in, anonymized, decisions-only.** The sole permissible network feature is explicit opt-in upload of anonymized pick/reject decisions (no pixels, no EXIF identifiers). Default is off; scoring works fully in airplane mode.

## Working discipline

- **Build in milestone order** (DESIGN.md M0 → M3). Do not start M1 feature code before `just ci` is green in GitHub Actions; do not add paywall code before M2 trust gates exist.
- **Doc precedence on conflict:** the tailoring decisions in DESIGN.md and the invariants here override raw README ideas. Example: README floats "AFM best-of-burst reasoning"; the adversarial review killed it; invariant 2 is the law. If you find a real contradiction, flag it in the PR rather than silently picking one.
- **Plan before milestone-sized work:** use the planner subagent for anything touching ≥ 2 packages; single-package fixes can go straight to TDD.
- **New dependencies are exceptional.** GRDB is pre-approved (PersistenceKit). Anything else needs a justification in the PR body and must not enter the four no-network packages (invariant 1).
- **Fixtures over downloads:** RAW test files live in `Packages/*/Tests/Fixtures/` (small, redistributable samples per format). Never have a test fetch sample images from the network — that would itself violate the spirit of invariant 1.
- **Branch + PR per milestone slice**, conventional-commit titles; keep PRs reviewable (< ~600 changed lines where feasible).

## Platform gotchas (learned the hard way — don't relearn)

- **`DetectFaceCaptureQualityRequest` scores are only comparable for the *same subject*** across a burst — never rank different people's faces against each other with it. Apple documents this; violating it produces nonsense best-of picks.
- **`CalculateImageAestheticsScoresRequest` requires iOS 18+**; gate with `#available` and keep the composite-score function total when it's absent (weight redistribution, not crash).
- **The simulator has no Neural Engine.** RankerKit falls back to CPU/GPU there — tests must assert outputs and ordering, never inference latency. Real performance numbers come from device runs only.
- **Embedded preview size varies by manufacturer.** Canon CR3 embeds full-size JPEGs; some Sony ARW bodies embed small previews. IngestKit needs a per-format fallback chain (largest embedded → half-size decode) and tests with fixture files per format.
- **Strict concurrency + Vision:** `VNRequest`/`CIContext` are not `Sendable`. Keep them confined inside the ScoringKit actor; pass value-type results out. Don't sprinkle `@unchecked Sendable` to silence the compiler — that's a review blocker.
- **Security-scoped bookmark access is per-URL and reference-counted**; nested starts on the same URL must be balanced. Use the single scoped-access helper in IngestKit, never call the raw API at call sites.
- **`BGProcessingTask` is opportunistic, not guaranteed.** Never write UI copy or tests that assume background completion; the durable-checkpoint design exists precisely because iOS may not grant time.

## Definition of done

- [ ] Failing test written first; now green; coverage ≥ 80% on touched modules
- [ ] `just ci` passes locally (lint + build + test), zero strict-concurrency warnings
- [ ] No invariant above violated; anything touching invariants 1–4 has an explicit test
- [ ] Errors handled at every new boundary; no `try!` in production paths
- [ ] Files < 800 lines, functions < 50; no new dependency without justification in the PR body
- [ ] Conventional commit message; docs (DESIGN.md/TOOLS.md) updated if behavior or commands changed
- [ ] code-reviewer subagent run on the diff; CRITICAL/HIGH findings resolved
