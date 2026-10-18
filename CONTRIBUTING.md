# Contributing

Use Flutter 3.44.2 and Dart 3.12.2. Native builds need Xcode 26 or newer and CocoaPods. Keep Swift 6 strict concurrency enabled; simulator builds need no signing team.

1. Branch from `main` and make a focused change.
2. Keep business rules in the pure Dart domain. Inject platform, storage and capture dependencies through existing ports.
3. Add a regression test that fails before the fix. Use real SQLite for storage constraints and an immediate test repository for widget tests.
4. Run the quality commands below and describe which native paths you exercised.

```sh
dart format lib test integration_test tool
flutter analyze --fatal-infos
swiftlint lint --strict --no-cache ios/Runner/AppDelegate.swift ios/Runner/FieldbookIntelligence.swift
dart run tool/check_architecture.dart
flutter test --coverage --exclude-tags golden
dart run tool/coverage_gate.dart
flutter test --tags golden
flutter build ios --simulator --no-codesign --debug
```

Goldens are recorded on macOS with Flutter's deterministic test font. The comparator permits 0.5% pixel differences; inspect any changed baseline before updating it. Use `flutter test --tags golden --update-goldens` only for an intentional visual change.

For real native verification, create your own simulator and run `flutter test integration_test/notebook_test.dart -d <simulator-id>`. To capture unedited screenshots at the test checkpoints, use `python3 tool/capture_simulator.py <simulator-id>`. The ID is an argument, never a checked-in constant. Delete your simulator and only its project build products afterward.

Use synthetic documents in tests and screenshots. State whether a draft came from the real model, an extractive path or a scripted demo. Do not put personal documents, API keys, signing identities or device identifiers in commits. Report security issues privately as described in [SECURITY.md](SECURITY.md).
