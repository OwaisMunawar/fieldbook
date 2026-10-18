import 'dart:convert';

import 'package:fieldbook/app.dart';
import 'package:fieldbook/bootstrap.dart';
import 'package:fieldbook/features/notebook/data/sqlite_notebook.dart';
import 'package:fieldbook/features/notebook/domain/models.dart';
import 'package:fieldbook/features/notebook/domain/report.dart';
import 'package:fieldbook/features/notebook/domain/workflow.dart';
import 'package:fieldbook/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> checkpoint(WidgetTester tester, String name) async {
  await Future<void>.delayed(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
  if (const bool.fromEnvironment('CAPTURE_SCREENSHOTS')) {
    debugPrint('FIELDBOOK_SCREENSHOT:$name');
    await Future<void>.delayed(const Duration(seconds: 3));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real OCR, reviewed actions, revision history, retrieval and disk restore',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(NotebookShell));
      final container = ProviderScope.containerOf(context);
      final controller = await container.read(notebookProvider.future);
      expect(controller.demo, false);
      final evidence = (await controller.importSample())!;
      expect(evidence.source, 'Apple Vision OCR');
      final handrail = evidence.lines.firstWhere(
        (line) => line.text.contains('Handrail loose'),
      );
      final ceiling = evidence.lines.firstWhere(
        (line) => line.text.contains('Ceiling panel'),
      );
      expect(handrail.confidence, greaterThan(0.45));
      expect(handrail.region.width, greaterThan(0));
      const channel = MethodChannel('com.owaismunawar.fieldbook/intelligence');
      final status = await channel.invokeMethod<String>('modelStatus');
      final generated = (await controller.draft(evidence))!;
      validateDraft(generated, evidence);
      expect(
        generated.origin,
        status == 'available'
            ? DraftOrigin.foundationModels
            : DraftOrigin.extractive,
      );
      debugPrint('FIELDBOOK_MODEL_STATUS:$status');
      final handrailDraft = ActionDraft(
        title: 'Inspect the north stair handrail',
        quote: handrail.text,
        lineId: handrail.id,
        origin: DraftOrigin.extractive,
      );
      final ceilingDraft = ActionDraft(
        title: 'Revisit the east corridor ceiling panel',
        quote: ceiling.text,
        lineId: ceiling.id,
        origin: DraftOrigin.extractive,
      );
      // The workflow is rerunnable: source import and quote acceptance are idempotent at the repository boundary.
      if (!controller.snapshot.issues.any((i) => i.lineId == handrail.id)) {
        await controller.accept(evidence, handrailDraft);
      }
      if (!controller.snapshot.issues.any((i) => i.lineId == ceiling.id)) {
        await controller.accept(evidence, ceilingDraft);
      }
      await tester.pumpAndSettle();
      await checkpoint(tester, 'notebook');
      await tester.ensureVisible(find.text('Scan sample card'));
      await tester.tap(find.text('Scan sample card'));
      await tester.pumpAndSettle();
      expect(find.text('Review evidence'), findsOneWidget);
      await checkpoint(tester, 'vision-evidence');
      await tester.ensureVisible(find.text('Draft action on device'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Draft action on device'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          status == 'available' ? 'On-device AI' : 'Extractive fallback',
        ),
        findsOneWidget,
        reason: controller.error?.message,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('accept-action')));
      await checkpoint(
        tester,
        status == 'available' ? 'on-device-draft' : 'extractive-draft',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      await checkpoint(tester, 'open-actions');
      if (controller.snapshot.issues
              .firstWhere((i) => i.lineId == handrail.id)
              .status ==
          IssueStatus.resolved) {
        await tester.tap(find.text('Resolved'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Inspect the north stair handrail'));
      await tester.pumpAndSettle();
      final issue = controller.snapshot.issues.firstWhere(
        (i) => i.lineId == handrail.id,
      );
      if (issue.status == IssueStatus.open) {
        await tester.ensureVisible(find.byKey(const ValueKey('change-status')));
        await tester.tap(find.byKey(const ValueKey('change-status')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('review-note')),
          'Fixings inspected and refastened. Recheck recorded for handover.',
        );
        await tester.tap(find.byKey(const ValueKey('save-review')));
        await tester.pumpAndSettle();
      }
      expect(
        controller.snapshot.issues.firstWhere((i) => i.id == issue.id).status,
        IssueStatus.resolved,
      );
      await checkpoint(tester, 'review-history');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Find'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('evidence-search')),
        'handrail',
      );
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('“${handrail.text}”'), findsOneWidget);
      await checkpoint(tester, 'source-search');
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      await checkpoint(tester, 'handover-report');
      final report =
          jsonDecode(encodeReport(controller.snapshot, DateTime.now().toUtc()))
              as Map<String, Object?>;
      expect(report['schema_version'], 1);
      expect(report['history'], isNotEmpty);
      final directory = await getApplicationSupportDirectory();
      final reopened = await SqliteNotebook.open(
        p.join(directory.path, 'notebook.db'),
        singleInstance: false,
      );
      expect(
        (await reopened.read()).events.length,
        controller.snapshot.events.length,
      );
      await reopened.close();
      expect(tester.takeException(), isNull);
    },
  );
}
