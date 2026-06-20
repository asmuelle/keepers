# Keepers

[![CI](https://github.com/asmuelle/keepers/actions/workflows/ci.yml/badge.svg)](https://github.com/asmuelle/keepers/actions/workflows/ci.yml)

> AI photo culling that scores, blink-checks, groups, and shortlists a 3,000-shot session on the phone itself — Aftershoot power without the desktop or the $30/month.

**Category:** Edge AI / on-device inference (iOS + Android) 
## Concept

AI photo culling that scores, blink-checks, groups, and shortlists a 3,000-shot session on the phone itself — Aftershoot power without the desktop or the $30/month.

## Target User 


Wedding, event, and portrait photographers shooting 1,000-5,000 frames per session — 22% already cull on phones/tablets with zero AI help — plus serious hobbyists wanting their best 50 shots surfaced from a bloated camera roll as the volume tier.

## Why Edge AI Is Structural (not decoration)

Apple Vision for face landmarks, blink detection, and blur/sharpness scoring; a custom aesthetic-scoring and duplicate-grouping model AOT-compiled to the Neural Engine via Core AI for batch-scoring thousands of RAW previews; AFM 3 Core Advanced image input for content tagging and best-of-burst reasoning; Android via LiteRT with official NPU acceleration (Dimensity 9500 partnership). Essential, not merely cheaper: a 3,000-shot RAW session is 60-150GB — cloud scoring fails on upload time, bandwidth, and GPU cost simultaneously, and client contracts routinely forbid uploading wedding images to third-party servers. Batch on-device vision is the only architecture that can exist on mobile.

## Why Now (2026 timing)

A19 Pro's GPU Neural Accelerators (~4x peak GPU compute vs A18 Pro) make scoring thousands of frames in minutes feasible for the first time; Core AI AOT compilation for custom vision models shipped at WWDC26; Aftershoot proved local-processing demand at higher desktop prices, yet no mobile-native on-device player exists.



## Tech Stack

iOS (ship first): Swift/SwiftUI; cull-in-place ingest off USB-C cards/SSDs via Files security-scoped bookmarks (no full import; PhotoKit only for the consumer tier); ImageIO/CGImageSource extraction of embedded JPEG previews from RAW (full Core Image RAW decode only on-demand for zoom); Vision framework — DetectFaceLandmarksRequest (blink via eye-aspect-ratio on landmarks), DetectFaceCaptureQualityRequest (per-face best-of-burst ranking — this, not an LLM, is the correct API), CalculateImageAestheticsScoresRequest (baseline score + isUtility), GenerateImageFeaturePrintRequest (near-duplicate clustering by cosine distance); custom Core ML aesthetic/expression ranker (EfficientNet/MobileViT-class, PyTorch → coremltools, ANE-targeted, FP16) with a lightweight on-device personalization head fine-tuned on the photographer's historical picks; Foundation Models framework (AFM) strictly for optional content tags/searchable captions, never in the scoring path; XMP sidecar writer + Lightroom Classic catalog sync for desktop handoff; ProcessInfo.thermalState-aware batch scheduler + BGProcessingTask for opportunistic continuation. Android (second, iPhone-skewed market): Kotlin/Compose; SAF/USB mass-storage ingest; LibRaw NDK for preview extraction; ML Kit Face Detection/Face Mesh for landmarks and blink; the same ranker converted via ai-edge-torch to LiteRT with QNN (Qualcomm) and NeuroPilot (MediaTek) NPU delegates and CPU/GPU fallback; ML Kit GenAI APIs / Gemini Nano for tags only. No cloud inference anywhere in the scoring path; optional anonymized opt-in telemetry of pick/reject decisions to train the taste model — which is the actual moat-building asset.
