# Keepers

> AI photo culling that scores, blink-checks, groups, and shortlists a 3,000-shot session on the phone itself — Aftershoot power without the desktop or the $30/month.

**Category:** Edge AI / on-device inference (iOS + Android) · **Status:** ✅ Recommended (Top 5 of the edge-AI run)

## Scorecard

| Metric | Score |
|---|---|
| Rank (of 9 finalists) | #4 |
| Combined score | 5.6 |
| Monetization potential (1-10) | 7 |
| Feasibility (1-10) | 6 |
| Edge AI structurally essential | Yes |
| Skeptic verdict | weakened |

## Concept

AI photo culling that scores, blink-checks, groups, and shortlists a 3,000-shot session on the phone itself — Aftershoot power without the desktop or the $30/month.

## Target User & Payer

Wedding, event, and portrait photographers shooting 1,000-5,000 frames per session — 22% already cull on phones/tablets with zero AI help — plus serious hobbyists wanting their best 50 shots surfaced from a bloated camera roll as the volume tier.

## Why Edge AI Is Structural (not decoration)

Apple Vision for face landmarks, blink detection, and blur/sharpness scoring; a custom aesthetic-scoring and duplicate-grouping model AOT-compiled to the Neural Engine via Core AI for batch-scoring thousands of RAW previews; AFM 3 Core Advanced image input for content tagging and best-of-burst reasoning; Android via LiteRT with official NPU acceleration (Dimensity 9500 partnership). Essential, not merely cheaper: a 3,000-shot RAW session is 60-150GB — cloud scoring fails on upload time, bandwidth, and GPU cost simultaneously, and client contracts routinely forbid uploading wedding images to third-party servers. Batch on-device vision is the only architecture that can exist on mobile.

## Why Now (2026 timing)

A19 Pro's GPU Neural Accelerators (~4x peak GPU compute vs A18 Pro) make scoring thousands of frames in minutes feasible for the first time; Core AI AOT compilation for custom vision models shipped at WWDC26; Aftershoot proved local-processing demand at higher desktop prices, yet no mobile-native on-device player exists.

## Proposed Monetization

$6.99/mo or $49.99/yr pro tier, $89.99 lifetime — versus Aftershoot's $10-45/mo desktop pricing, paid readily by working photographers for hours saved per shoot. 30K paying pros ≈ $1.5M ARR at ~100% margin, with the consumer 'clean my camera roll' tier as volume upside beyond the pro beachhead.

## Competition & Gap

Aftershoot ($10-45/mo, desktop-only — validates both workflow and local processing), Narrative Select (desktop), Lightroom Mobile (no culling AI). The gap is the entire mobile platform: nobody serves the phone-culling photographer, and desktop incumbents can't follow without rebuilding for mobile NPUs.

---

# Evaluation (multi-agent adversarial review)

## Monetization Analysis — score 7/10

The payer is proven, the wedge is real but not as empty as claimed, and the ceiling is moderate. Aftershoot's ~$7.5M revenue (FY Mar 2025), $16.1M raised, and 8.8B images processed in 2025 prove working photographers pay $120-540/yr for culling automation, so willingness to pay is not speculative. The mobile-native, on-device angle is a genuine architectural wedge: 60-150GB RAW sessions genuinely cannot round-trip through the cloud on mobile, and desktop incumbents would need a real rebuild to follow. However, two claims in the pitch needed correction. First, the mobile gap is not vacant: PhotoPicker (iOS AI culling with offline RAW direct from memory cards, blink/sharpness/duplicate detection) and Photo Triager already ship exactly this on iPhone/iPad — they are small indie apps, so Keepers would be out-executing, not category-creating, which weakens the moat story. Second, the pro TAM is bounded: Aftershoot, the category leader with 100+ staff and desktop-grade models, is at ~$7.5M ARR; a mobile-only challenger realistically caps near $1-3M ARR on the pro tier, which is a good indie/small-team business but not a 9-10 outcome. The consumer 'clean my camera roll' tier has real money (Swipewipe alone at ~$1M/month per Sensor Tower) but is a race-to-the-bottom, paid-UA-driven category where Apple's built-in duplicate cleanup and dozens of paywall apps compete — it is upside, not a reliable second leg. Platform risk (Apple sherlocking best-shot selection into Photos; Aftershoot shipping a mobile companion off its existing models and brand) is material but not immediate. Net: solid niche with a proven payer and a credible technical moat on-device — high end of the 6-8 band.

## Recommended Revenue Model

Keep the proposed pro subscription but price slightly higher and gate by workflow value, not features: $7.99/mo or $59.99-79.99/yr pro tier (still 33-50% under Aftershoot's $9.99/mo culling-only floor of ~$120/yr, and pros anchor to hours saved per shoot, not app-store norms — undercutting too far just leaves money on the table and signals toy). Pro tier includes RAW ingest from card/SSD, batch scoring of 3,000+ frames, XMP/star export to Lightroom/Capture One, and burst best-of reasoning. Drop or time-limit the $89.99 lifetime to launch-only — lifetime deals cannibalize the exact high-LTV pro cohort this depends on. Add a free tier (e.g., 300 scored shots/month, JPEG only) as the funnel, and a $24.99-29.99/yr consumer tier for camera-roll cleanup, priced well below pro to avoid anchoring pros down. Math: 20-30K pro subs at ~$60-75 blended ARPU = $1.2-2.2M ARR at near-100% margin since inference is on-device; consumer tier is optionality on top, with Swipewipe's ~$12M/yr run rate proving the category but requiring paid UA to capture. Trial: 7-day full-feature trial on annual, since the first real wedding cull is the conversion moment.

## Market Evidence (live web research, June 2026)

Aftershoot revenue ~₹63.1 Crores (~$7.5M USD) for FY ending March 2025 per Tracxn, with $16.1M raised (Techstars, Headline, Info Edge Ventures), 102 employees (+79% YoY), and 8.8B images processed / 6.8B culled in 2025 per its Snapshot report — direct proof that high-volume photographers pay recurring fees for AI culling. Category pricing band confirmed: Aftershoot Selects (culling-only) $9.99/mo annual, up to $45-60/mo bundles; Narrative Select $10/mo entry, $60/mo Ultra. Consumer volume-tier comp: Swipewipe at ~400K downloads and ~$1M revenue in a single month per Sensor Tower, demonstrating large consumer spend on camera-roll cleanup but in a crowded paywall-app category. Counter-evidence to the 'empty mobile gap' claim: PhotoPicker (iOS) already does on-device AI culling (sharpness, closed eyes, duplicates) on RAW directly from memory cards offline, and Photo Triager does offline mobile RAW culling — both small indie apps, so the gap is underserved rather than unoccupied.

## Comparables

- Aftershoot — ~$7.5M revenue FY ending Mar 2025 (Tracxn), $16.1M raised, pricing $9.99/mo (culling-only) to $45-60/mo bundles; category leader, desktop-only
- Narrative Select — $10/mo entry, $60/mo Ultra (4 users); desktop (macOS-first), revenue undisclosed
- Swipewipe (consumer camera-roll cleaner) — ~$1M revenue and ~400K downloads in one month per Sensor Tower, ~$12M/yr run rate; consumer-tier comp
- PhotoPicker (iOS AI culling, offline RAW from memory cards) — direct mobile incumbent, indie-scale, revenue unknown but proves the mobile workflow exists
- Photo Triager — offline mobile RAW culling app, indie-scale, revenue unknown
- FilterPixel / Fovea — smaller desktop culling entrants; Fovea validates the on-device privacy-first positioning

## Adversarial Review — strongest case AGAINST (verdict: weakened)

The pitch's central premise is factually false: the mobile whitespace is already occupied. PhotoPicker (iOS) ships today and does exactly this — AI culling on iPhone/iPad directly off memory cards and external SSDs via Files, Lightroom Classic catalog round-trip with flags/ratings/labels, AF-point overlays. 'Nobody serves the phone-culling photographer' is the load-bearing claim and it doesn't survive a single App Store search. Second, the only model that matters is the one the team can't build: blur, blink, face landmarks, near-dupe grouping, and even baseline aesthetic scoring are commodity OS APIs (Vision's CalculateImageAestheticsScoresRequest, DetectFaceCaptureQualityRequest, feature prints) available to every competitor — differentiation lives entirely in a taste model that ranks 12 near-identical processional frames the way a wedding photographer would, and Aftershoot's moat is millions of culled sessions plus per-photographer personalization data that a new entrant has zero of (cold start on the differentiator). Third, the pitch over-credits the LLM: AFM-class ~3B models with image input cannot do reliable 'best-of-burst reasoning' — at ~1-3s per image of LLM inference, 3,000 frames is 1-2.5 hours of LLM time alone, with hallucinated tags and no fine-grained focus/expression judgment; the honest architecture barely uses an LLM, so the headline 'AI' is mostly 2019-era CNNs. Fourth, the marketing physics are optimistic: 60-150GB doesn't fit on most phones, so it must cull in place off the card (as PhotoPicker does) using embedded JPEG previews, and sustained ANE+RAW-decode batch work thermally throttles an iPhone chassis within minutes while iOS background-execution limits forbid long screen-off processing — 'minutes not hours' needs caveats. Fifth, both flanks are closing: the consumer 'clean my camera roll' tier is already sherlocked (iOS Photos duplicate merging, utility/aesthetics ranking; Google Photos free server-side; saturated cleanup-app category), and the pro tier faces an Aftershoot iPad app as a when-not-if (June 2026: 'the workflow is now complete' platform push) plus Adobe adding culling AI to Lightroom Mobile. Sixth, the price umbrella is thinner than claimed — Narrative has a free version and $10/mo entry, FilterPixel and Optyx have free tiers — and distribution is brutal: ~zero App Store search volume for 'photo culling,' a $50/yr ARPU against YouTube-influencer CAC in a niche where Aftershoot already owns the ambassador channel, and 30K paying pros implies winning ~10% of the realistic worldwide SAM as an unknown brand. The one claim that survives intact is the architecture: cloud culling genuinely cannot work here.

## Recommended Tech Stack

iOS (ship first): Swift/SwiftUI; cull-in-place ingest off USB-C cards/SSDs via Files security-scoped bookmarks (no full import; PhotoKit only for the consumer tier); ImageIO/CGImageSource extraction of embedded JPEG previews from RAW (full Core Image RAW decode only on-demand for zoom); Vision framework — DetectFaceLandmarksRequest (blink via eye-aspect-ratio on landmarks), DetectFaceCaptureQualityRequest (per-face best-of-burst ranking — this, not an LLM, is the correct API), CalculateImageAestheticsScoresRequest (baseline score + isUtility), GenerateImageFeaturePrintRequest (near-duplicate clustering by cosine distance); custom Core ML aesthetic/expression ranker (EfficientNet/MobileViT-class, PyTorch → coremltools, ANE-targeted, FP16) with a lightweight on-device personalization head fine-tuned on the photographer's historical picks; Foundation Models framework (AFM) strictly for optional content tags/searchable captions, never in the scoring path; XMP sidecar writer + Lightroom Classic catalog sync for desktop handoff; ProcessInfo.thermalState-aware batch scheduler + BGProcessingTask for opportunistic continuation. Android (second, iPhone-skewed market): Kotlin/Compose; SAF/USB mass-storage ingest; LibRaw NDK for preview extraction; ML Kit Face Detection/Face Mesh for landmarks and blink; the same ranker converted via ai-edge-torch to LiteRT with QNN (Qualcomm) and NeuroPilot (MediaTek) NPU delegates and CPU/GPU fallback; ML Kit GenAI APIs / Gemini Nano for tags only. No cloud inference anywhere in the scoring path; optional anonymized opt-in telemetry of pick/reject decisions to train the taste model — which is the actual moat-building asset.

---

*Generated 2026-06-10 from a multi-agent research pipeline: 5 live-web research agents (Apple/Android platform state, market data, consumer trends, competitive landscape), 3-lens ideation, ruthless shortlist, then per-candidate monetization analyst + adversarial skeptic. Market figures are agent-researched estimates — verify before committing capital.*
