import 'package:fieldbook/app.dart';
import 'package:fieldbook/core/design.dart';
import 'package:fieldbook/features/notebook/application/notebook_controller.dart';
import 'package:fieldbook/features/notebook/domain/models.dart';
import 'package:fieldbook/features/notebook/presentation/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/notebook_fixture.dart';

void main() {
  late NotebookController controller;
  setUp(() async {
    controller = await testController(seeded: true, memory: true);
  });
  tearDown(() async {
    await controller.repository.close();
    controller.dispose();
  });
  Future<void> open(WidgetTester tester, {double scale = 1}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: notebookTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: NotebookShell(
          controller: controller,
          share: (snapshot, rect) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows source provenance, search results and no-evidence state', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Fieldbook'), findsOneWidget);
    expect(find.text('DEMO'), findsOneWidget);
    await tester.tap(find.text('Find'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('evidence-search')),
      'handrail',
    );
    await tester.pumpAndSettle();
    expect(find.text('“Handrail loose at north stair.”'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('evidence-search')),
      'unrelated',
    );
    await tester.pumpAndSettle();
    expect(find.text('No supporting source'), findsOneWidget);
  });
  testWidgets('resolution requires a note and appends history', (tester) async {
    await open(tester);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inspect the north stair handrail'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('change-status')));
    await tester.tap(find.byKey(const ValueKey('change-status')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('review-note')),
      'Refixed and inspected',
    );
    await tester.tap(find.byKey(const ValueKey('save-review')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 350)),
    );
    await tester.pumpAndSettle();
    expect(controller.snapshot.issues.single.status, IssueStatus.resolved);
    expect(find.text('Refixed and inspected'), findsOneWidget);
  });
  testWidgets('review retains exact quote while an inspector edits the title', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: notebookTheme(),
        home: ReviewScreen(
          controller: controller,
          evidence: controller.snapshot.evidence.single,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Access label is missing.'));
    await tester.tap(find.text('Access label is missing.'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(
      find.byType(TextField),
      'Replace the service-room label',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('accept-action')));
    await tester.tap(find.byKey(const ValueKey('accept-action')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();
    expect(controller.snapshot.issues.length, 2);
    expect(
      controller.snapshot.issues
          .where((issue) => issue.title == 'Replace the service-room label')
          .single
          .quote,
      'Access label is missing.',
    );
  });
  testWidgets(
    'report export receives current snapshot and a nonzero share anchor',
    (tester) async {
      var exports = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: notebookTheme(),
          home: NotebookShell(
            controller: controller,
            share: (snapshot, origin) async {
              exports++;
              expect(snapshot.issues.length, 1);
              expect(origin.width, greaterThan(0));
              expect(origin.height, greaterThan(0));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('export-report')));
      await tester.tap(find.byKey(const ValueKey('export-report')));
      await tester.pumpAndSettle();
      expect(exports, 1);
    },
  );
  testWidgets('notebook, actions, search and report fit at double text size', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await open(tester, scale: 2);
    for (final page in ['Actions', 'Find', 'Report', 'Notebook']) {
      await tester.tap(find.text(page));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
