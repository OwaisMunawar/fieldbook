# Verification record

Verified on 18 October 2026. These results describe a local reference app, not a deployed inspection system.

## Toolchain and checks

| Check | Result |
| --- | --- |
| `flutter analyze --fatal-infos` | Passed, no issues; strict casts, inference and raw types enabled |
| `dart format --output=none --set-exit-if-changed lib test integration_test tool` | Passed |
| `dart run tool/check_architecture.dart` | Passed; domain, application and presentation boundaries checked |
| `flutter test --coverage --exclude-tags golden` | 25 tests passed |
| `dart run tool/coverage_gate.dart` | 228/229 lines, 99.6% across domain and application; each covered file also exceeds 90% |
| `flutter test --tags golden` | 3 macOS baselines passed, 0.5% pixel tolerance |
| `actionlint .github/workflows/ci.yml` | Passed |
| SwiftLint 0.65.1 on native adapters | Passed, zero violations in strict mode |
| `flutter build ios --simulator --no-codesign --debug` | Passed with Flutter 3.44.2, Dart 3.12.2 and Xcode 26.6 |
| Native integration workflow | Passed on a dedicated iPhone 17 Pro simulator, iOS 26.5 |

Native Runner code uses Swift 6, complete concurrency checking and warnings as errors. Simulator builds use no signing team or physical device.

## Real native workflow

`python3 tool/capture_simulator.py <simulator-id>` ran the integration test and invoked `xcrun simctl io <simulator-id> screenshot` at its checkpoints. The test:

1. Opened the standard notebook and imported the bundled synthetic inspection card through **real Apple Vision**. It returned 13 text lines with normalized regions.
2. Observed Foundation Models availability as **available**, ran guided action/source-index generation, bound the original quote and ID outside the model, and validated that quote again in Dart.
3. Added two inspector-reviewed source-quote actions, preserving their extractive origin.
4. Opened source review, generated another **real Foundation Models** draft through the screen control, checked its origin label and captured the review state. The capture shows the exact selected source quote and the real-model origin label. The proposed action is still pending inspector acceptance.
5. Resolved the handrail action through the review-note dialog and checked its status and history.
6. Retrieved the handrail OCR snippet through local search.
7. Built a versioned JSON report and verified saved history through a separate SQLite connection. A separate storage test closes and reopens a real on-disk database.

The sample's repair notes are test inputs. No real repair occurred. Exact quotes validate citations, not the semantic correctness of a model's proposal.

## Screenshot provenance

All PNGs below are unedited simulator captures. Each was opened and visually checked against its filename.

| Capture | What it proves / shows |
| --- | --- |
| `screenshots/notebook.png` | Local notebook, source image thumbnail and current action counts |
| `screenshots/vision-evidence.png` | Real OCR boxes over the synthetic inspection card |
| `screenshots/on-device-draft.png` | Real local model output, checked quote, origin label and pending acceptance control |
| `screenshots/open-actions.png` | Inspector-reviewed actions and their exact source quotes; extractive origins remain visible |
| `screenshots/review-history.png` | Acceptance and resolution events, revision numbers and a synthetic inspector note |
| `screenshots/source-search.png` | Local retrieval of the original handrail text and its source-line ID |
| `screenshots/handover-report.png` | Report contents and export control |

The app does not claim to prove the authenticity of documents. The image fixture explicitly says it is synthetic.

## Explicitly not verified

- Physical iPhone behavior, camera capture, real-world documents, iOS 18 behavior, native share-sheet completion, iPad hardware, VoiceOver interaction or adverse lighting.
- Android: this release has an iOS runner only.
- Maestro: the flow is written but unrun because Maestro is not installed.
- Production deployment, OCR accuracy, model action correctness, latency, battery consumption or large-corpus performance.

Widget tests verify an export receives the current snapshot and a nonzero popover anchor; they do not replace a native sharing test. CI runs quality checks, goldens and simulator compilation. It does not run the native integration workflow.
