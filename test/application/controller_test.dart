import 'package:fieldbook/features/notebook/application/notebook_controller.dart';
import 'package:fieldbook/features/notebook/data/native_intelligence.dart';
import 'package:fieldbook/features/notebook/domain/models.dart';

import 'package:flutter_test/flutter_test.dart';

import '../support/memory_notebook.dart';

import '../support/notebook_fixture.dart';

void main() {
  test(
    'imports, deduplicates, drafts, accepts and resolves through real storage',
    () async {
      final controller = await testController();
      final evidence = (await controller.importSample())!;
      expect((await controller.importSample())!.id, evidence.id);
      expect(controller.snapshot.evidence.length, 1);
      final draft = (await controller.draft(evidence))!;
      expect(await controller.accept(evidence, draft), true);
      expect(await controller.accept(evidence, draft), isNull);
      expect(controller.error!.code, FailureCode.duplicate);
      controller.clearError();
      expect(controller.error, isNull);
      final issue = controller.snapshot.issues.single;
      expect(
        await controller.changeStatus(
          issue,
          IssueStatus.resolved,
          'Inspected and refixed',
        ),
        true,
      );
      expect(controller.snapshot.events.length, 2);
      expect(
        await controller.changeStatus(issue, IssueStatus.resolved, 'stale'),
        isNull,
      );
      expect(controller.error!.code, FailureCode.staleRevision);
      await controller.repository.close();
      controller.dispose();
    },
  );
  test(
    'cancelled photo import creates nothing; simultaneous imports do not duplicate',
    () async {
      final controller = await testController(demo: false);
      (controller.capture as TestCapture).chosen = null;
      expect(await controller.importPhoto(camera: true), isNull);
      expect(controller.snapshot.evidence, isEmpty);
      final results = await Future.wait([
        controller.importSample(),
        controller.importSample(),
      ]);
      expect(results.whereType<Object>().length, 1);
      expect(controller.busy, false);
      expect(controller.snapshot.evidence.length, 1);
      await controller.repository.close();
      controller.dispose();
    },
  );
  test(
    'failed persistence discards an unreferenced capture and offers reload',
    () async {
      final capture = TestCapture();
      final controller = NotebookController(
        repository: RejectingNotebook(),
        recognizer: const DemoTextRecognizer(),
        generator: const DemoActionGenerator(),
        capture: capture,
        newId: () => 'id',
        clock: () => DateTime.utc(2026),
      );
      expect(await controller.importPhoto(camera: false), isNull);
      expect(capture.discarded, true);
      expect(controller.error!.code, FailureCode.storage);
      expect(await controller.reload(), true);
      expect(controller.error, isNull);
      controller.dispose();
    },
  );
  test(
    'demo mode refuses to apply scripted recognition to a personal photo',
    () async {
      final controller = await testController(memory: true);
      expect(await controller.importPhoto(camera: true), isNull);
      expect(controller.error!.code, FailureCode.unsupported);
      expect(controller.snapshot.evidence, isEmpty);
      controller.dispose();
      await controller.repository.close();
    },
  );
}

class RejectingNotebook extends WidgetNotebook {
  @override
  Future<Evidence> addEvidence(Evidence evidence) async =>
      throw StateError('disk failure');
}
