import 'package:fieldbook/features/notebook/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

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
      final controller = await testController();
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
}
