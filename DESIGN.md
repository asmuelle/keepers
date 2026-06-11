# Keepers — Design Doc

## Thesis

A 3,000-shot wedding session is 60–150GB of RAW; it physically cannot round-trip through the cloud from a phone, so on-device batch scoring is the only architecture that can exist on mobile — and Aftershoot proved photographers pay $120–540/yr for exactly this workflow on desktop. Keepers culls **in place** off the USB-C card using embedded JPEG previews and Apple's Vision framework on the Neural Engine, so the phone never needs the storage, the bandwidth, or a server. The defensible layer is not the commodity blur/blink scoring — it's the per-photographer taste model trained on the user's own pick history, plus a lossless XMP round-trip into Lightroom Classic.

## Architecture

**Pipeline shape (mobile): capture → on-device inference → store → surface.**

```
USB-C card/SSD ──security-scoped bookmark──▶ IngestKit
   │  enumerate RAWs, extract embedded JPEG previews (no import)
   ▼
ScoringKit (thermal-aware batch scheduler)
   │  Vision: face landmarks (blink/EAR) · face capture quality
   │  Vision: aesthetics score + isUtility · feature prints
   ▼
RankerKit (Core ML aesthetic ranker + personalization head, ANE/FP16)
   │  composite score, burst best-of, near-dupe clusters
   ▼
PersistenceKit (GRDB/SQLite: sessions, score cards, decisions)
   ▼
KeepersUI (shortlist grid, burst stacks, loupe w/ on-demand full RAW decode)
   ▼
ExportKit ──XMP sidecars (stars/labels) back onto the card──▶ Lightroom Classic
```

**Cost discipline — who does what:**

| Layer | Used for | Cost |
|---|---|---|
| Deterministic code | File enumeration, EXIF parse, preview extraction, EAR blink math, cosine clustering, XMP serialization, scheduling | Free, testable, exact |
| OS models (Vision) | `DetectFaceLandmarksRequest`, `DetectFaceCaptureQualityRequest`, `CalculateImageAestheticsScoresRequest`, `GenerateImageFeaturePrintRequest` | Free, on-device, the entire batch workload |
| Custom Core ML | Aesthetic/expression ranker (EfficientNet/MobileViT-class, FP16, ANE) + per-photographer personalization head | Free at runtime; training is offline dev-time |
| On-device LLM (AFM) | Optional content tags / searchable captions only — **never in the scoring path** | Free, deferred to post-M2 |
| Frontier LLM | Nothing at runtime. Dev-time tooling only (e.g. label triage during model training) | $0 in product |

There is **no cloud inference anywhere**. Photo bytes never leave the device. This is the product's core promise (client contracts forbid third-party upload of wedding images) and a hard invariant in AGENTS.md.

### Module map

```
keepers/
├── project.yml              # XcodeGen spec → Keepers.xcodeproj (app shell, scheme "Keepers")
├── App/                     # SwiftUI app target: composition root only, no logic
└── Packages/
    ├── KeepersCore/         # Domain types + pure logic: scores, composite ranking, clustering math
    ├── IngestKit/           # Security-scoped bookmarks, RAW enumeration, ImageIO preview extraction
    ├── ScoringKit/          # Vision request pipeline + ProcessInfo.thermalState-aware batch scheduler
    ├── RankerKit/           # Core ML ranker loading/inference + personalization head training
    ├── ExportKit/           # XMP sidecar writer, star/label mapping, Lightroom handoff
    ├── PersistenceKit/      # GRDB/SQLite store: sessions, frames, score cards, decisions
    ├── TaggingKit/          # AFM content tags (optional; MUST NOT be imported by Scoring/RankerKit)
    └── KeepersUI/           # SwiftUI features: session browser, cull grid, loupe, burst stacks, export
```

Dependency rule: `KeepersCore` depends on nothing. Kits depend on `KeepersCore` only. `KeepersUI` and `App` compose kits. `ScoringKit`/`RankerKit`/`IngestKit`/`ExportKit` must not import any networking module — enforced by a CI grep test (M2).

## Data model sketch

- **Session** — id, name, source bookmark (security-scoped, stale-handling flag), createdAt, frameCount, status (ingesting / scoring / reviewed / exported), modelVersion used.
- **Frame** — id, sessionId, relative path on source volume, fileType (CR3/NEF/ARW/RAF/DNG/JPEG), captureDate, camera/lens/EXIF summary, burstGroupId?, previewState (none / embedded / full-decoded), previewCachePath.
- **ScoreCard** — frameId, sharpness, faceCount, per-face blink (eye-aspect-ratio), per-face captureQuality, aestheticsScore, isUtility, featurePrint (blob ref), rankerScore, compositeScore, modelVersion, scoredAt. One per frame per model version — re-scores append, never overwrite.
- **BurstGroup** — id, sessionId, member frameIds (capture-time + feature-print adjacency), suggestedBestFrameId, userBestFrameId?.
- **DupeCluster** — id, sessionId, member frameIds, cosine threshold used, representative frameId.
- **CullDecision** — frameId, verdict (pick / reject / maybe), starRating (0–5), decidedBy (auto / user), decidedAt. User decisions are immutable training signal; new decisions supersede, never mutate.
- **PersonalizationProfile** — local photographer profile: trainingExampleCount, head weights (file ref), version, lastTrainedAt, sourceOfTruth (in-app picks / imported Lightroom history).
- **ExportJob** — sessionId, mapping config (picks→stars, rejects→label), destination (sidecar-in-place / folder), status, frameCount, exportedAt, warnings.
- **BatchRun** — sessionId, framesScored, duration, thermalEvents (state transitions), interrupted/resumed flags. Local-only diagnostics; powers the trust UI.

## Key flows

### 1. Card to shortlist (hero flow)
1. Photographer plugs USB-C card reader/SSD into iPhone; opens Keepers; taps "New Session".
2. Document picker → folder on external volume → store security-scoped bookmark; start access.
3. IngestKit enumerates RAW files, parses EXIF, extracts the **embedded JPEG preview** via `CGImageSource` — no RAW is ever copied into the sandbox (sandbox growth budget: < 1MB/frame).
4. ScoringKit batches frames through the four Vision requests, watching `ProcessInfo.thermalState`; RankerKit adds the learned aesthetic score; KeepersCore computes composite scores and clusters near-dupes by feature-print cosine distance.
5. UI surfaces a ranked shortlist grid with live progress and an honest ETA; the photographer can start reviewing the top of the stack while the tail is still scoring.

### 2. Burst stack review
1. Frames within capture-time + feature-print adjacency collapse into one stack showing the suggested best (driven by `DetectFaceCaptureQualityRequest` per-face ranking — comparable **only within the same subject across a burst**, per Apple's API contract).
2. Photographer fans the stack open in the loupe; full Core Image RAW decode happens **on demand** for the frame under the loupe only, with 100% zoom and per-face blink badges ("face 2: eyes closed, EAR 0.11").
3. One swipe picks the keeper and rejects siblings; the override is recorded as a training example for the personalization head.

### 3. XMP round-trip to Lightroom Classic
1. Photographer taps Export; chooses mapping (default: picks → ★★★ , rejects → red label + 1★; pick/reject *flags* are Lightroom-catalog-only and do not survive XMP — this constraint is documented in-app).
2. ExportKit writes `.xmp` sidecars next to the RAWs on the source volume under the still-valid security-scoped bookmark; originals are never modified or deleted.
3. Back at the desktop, Lightroom Classic import reads ratings/labels from sidecars; photographer filters to ★≥3 and edits only keepers. Round-trip fidelity is an M1 acceptance test against a real LR Classic catalog.

### 4. Personalization (the moat loop)
1. Cold start: offer one-time import of the photographer's historical picks from existing XMP sidecars / exported catalogs — instant taste signal from years of their own culls.
2. Every in-app override of an auto-suggestion appends a training example (kept frame vs rejected siblings, same scene).
3. After N≥ threshold new examples, RankerKit fine-tunes the lightweight personalization head on-device (background, charger + thermal-nominal only); new modelVersion stamped, prior ScoreCards preserved for comparison.
4. Optional, explicit, off-by-default: anonymized pick/reject telemetry upload to grow the global taste corpus — the only network feature in the product, and never image bytes.

### 5. Thermal-aware batch lifecycle
1. Scheduler runs full-tilt at `.nominal`, halves batch concurrency at `.fair`, drops to single-stream at `.serious`, checkpoints and pauses at `.critical`.
2. Progress is durable: every ScoreCard is committed as produced; a yanked cable or force-quit resumes from the last frame.
3. On screen-off, a `BGProcessingTask` requests opportunistic continuation; the UI never promises background completion it can't guarantee.

## Performance budgets

The adversarial review's thermal critique is correct, so budgets are explicit and device-measured (iPhone 16-class baseline, real card reader, mixed CR3/NEF/ARW fixtures):

| Stage | Budget | Notes |
|---|---|---|
| Preview extraction | ≥ 8 frames/sec sustained | ImageIO embedded JPEG only; USB-C reader is often the bottleneck, not CPU |
| Vision batch scoring | ≥ 4 frames/sec at `.nominal`, graceful degradation per thermal state | All four requests per frame, previews ≤ 3MP working size |
| 3,000-frame session, card-to-shortlist | ≤ 25 min wall clock without hitting `.critical` | The honest marketing number; measured by BatchRun diagnostics |
| Loupe full RAW decode | ≤ 1.5s to first full-res tile | On-demand only; pre-decode the next frame in the stack |
| Peak memory during batch | ≤ 1.5GB | Stream previews; never hold decoded RAW buffers in the batch path |
| Sandbox growth | < 1MB per ingested frame | Invariant 3; thumbnails + DB rows only |
| Cold launch to session list | ≤ 600ms | PersistenceKit reads are indexed; no scoring work at launch |

Budgets are asserted in device smoke tests (not CI) and tracked per release in BatchRun telemetry locally.

## Deliberate scope cuts (v1 does NOT build)

- **No Android yet.** Kotlin/LiteRT port (per README stack) starts only after iOS pro-tier conversion is proven — the market is iPhone-skewed and the team is small.
- **No editing, no presets, no export of pixels.** Keepers selects; Lightroom edits. Scope creep here re-fights Adobe on Adobe's turf.
- **No consumer "clean my camera roll" tier in v1.** It's a sherlocked, paid-UA category (README review, flank 5); revisit only with pro revenue established. PhotoKit integration stays out of the codebase until then.
- **No cloud sync / multi-device.** Sessions live on the device + the card's XMP sidecars; the sidecars *are* the sync format.
- **No AFM tags until post-M2.** TaggingKit is scaffolded as a boundary, not built — keeping the LLM out of v1 entirely removes the hallucination and latency risks the skeptic flagged.

## Product & visual design direction: "Darkroom light-table"

The UI is the loupe-and-lightbox of a working pro, used at 11pm in a dim hotel room after a wedding. Direction: **true-black darkroom chrome with a safelight accent**. Surfaces are pure OLED black and color-neutral near-blacks (`oklch(0.16 0 0)` band) so embedded previews read color-true — never tinted grays that shift perception of skin tones. One accent: safelight amber (`oklch(0.78 0.16 75)`) for picks, progress, and focus states; desaturated brick red for rejects; white is reserved for image content and primary numerals. Typography: SF Pro Display (heavy weights, tight tracking) for headings and counts; SF Mono for EXIF, scores, and EAR readouts — data the photographer scans like a histogram. Hierarchy comes from scale and luminance, not boxes: hairline `oklch(0.3 0 0)` separators, no cards, no shadows. Motion is functional only: stack fan-out, score-sort reflow, progress shimmer — all under 300ms, all honoring Reduce Motion.

## Milestones

### M0 — Bootstrap (make `just ci` green)
- `project.yml` (XcodeGen) defining app target **Keepers** + the eight SPM packages, iOS 18 minimum, Swift 6 strict concurrency enabled everywhere.
- `.swiftlint.yml` + `.swiftformat` configs; one placeholder Swift Testing test per package.
- **Accept:** `just bootstrap && just ci` passes locally and in GitHub Actions on macos-15; zero warnings under strict concurrency.

### M1 — Thin vertical slice: card → ranked grid → XMP
- Scope: pick a folder of ≥100 mixed RAWs (CR3/NEF/ARW) on an external volume → extract previews without importing → run all four Vision requests → ranked grid → manual pick/reject → write XMP sidecars next to the RAWs. No custom ranker yet (composite = Vision-only), no bursts UI, no paywall.
- **Accept:** end-to-end on a physical iPhone with a real card reader; sandbox growth < 1MB/frame; Lightroom Classic import shows correct stars/labels for every decision; unit tests for EAR math, composite scoring, XMP serialization (golden files), bookmark stale-resolution; 80%+ coverage on KeepersCore/ExportKit.

### M2 — Trust layer
- Privacy proof: CI test greps Ingest/Scoring/Ranker/ExportKit for networking imports and fails on any hit; in-app "Airplane-mode culling" claim backed by a documented offline test script.
- Explainable rejects (per-face blink/quality reasons in the loupe), deterministic re-score (same frames + same modelVersion ⇒ identical ordering, asserted in tests), thermal scheduler states surfaced in UI with BatchRun diagnostics, dupe clusters with adjustable threshold, burst stacks + suggested best.
- **Accept:** a 3,000-frame session completes on an iPhone 16-class device without `.critical` shutdown; every auto-reject shows a concrete reason; privacy CI gate red/green demonstrated.

### M3 — Monetization wiring
- StoreKit 2: Free (300 scored frames/month, JPEG only), Pro $7.99/mo or $69.99/yr with 7-day full trial on annual (RAW ingest, unlimited batch, XMP export, bursts), launch-window-only $89.99 lifetime, consumer tier deferred until the pro beachhead converts.
- Paywall triggers at RAW ingest and at export — the first real wedding cull is the conversion moment. Entitlement-gated feature flags; purchase state cached for fully-offline use; conversion counters local-only.
- **Accept:** sandbox-tested purchase/restore/trial flows; free-tier metering enforced and unit-tested; export blocked-then-unlocked path E2E tested.

## Risks & mitigations (from adversarial review)

| # | Risk | Mitigation |
|---|---|---|
| 1 | **Mobile gap is occupied, not empty** — PhotoPicker and Photo Triager already ship offline RAW culling on iOS; we are out-executing, not category-creating. | Benchmark against PhotoPicker in M1 (frames/min, LR round-trip fidelity, dupe quality); win on the two things they lack: personalization head + polished burst best-of. Keep a living comparison matrix in the repo. |
| 2 | **Differentiator cold start** — blur/blink/aesthetics are commodity OS APIs; the taste model is the moat and we have zero training data. | Bootstrap from the photographer's *own* historical XMP/catalog picks at onboarding (flow 4.1); per-user head needs only their data, not millions of sessions. Opt-in anonymized decision telemetry is the long-term corpus — the only acceptable network feature. |
| 3 | **Thermal/battery physics** — sustained ANE + RAW decode throttles an iPhone in minutes; iOS forbids long screen-off processing. | Batch path touches embedded previews only (full RAW decode is loupe-on-demand); thermal-state scheduler with checkpointed resume (flow 5); honest ETAs; M2 acceptance is an instrumented 3,000-frame run. Never market "minutes" without the caveat. |
| 4 | **Flanks closing** — Aftershoot iPad app is when-not-if; Apple may sherlock best-shot into Photos; Lightroom Mobile may add culling. | Speed to the pro wedge they must rebuild for: card-native ingest + XMP round-trip + on-device personalization. Price at $69.99/yr under Aftershoot's ~$120/yr culling floor. Personalization history makes switching costly. |
| 5 | **Distribution is brutal** — near-zero search volume for "photo culling", influencer CAC high, Aftershoot owns ambassadors. | Free 300-frame tier as the funnel; target second shooters (they choose tools, can't expense $120/yr); ASO on adjacent terms photographers actually search ("RAW viewer", "card reader photos", "select photos Lightroom"); the XMP sidecar itself is a desktop-visible artifact every collaborator sees. |
