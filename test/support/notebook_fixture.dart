import 'package:fieldbook/features/notebook/application/notebook_controller.dart';
import 'package:fieldbook/features/notebook/data/native_intelligence.dart';
import 'package:fieldbook/features/notebook/data/sqlite_notebook.dart';
import 'package:fieldbook/features/notebook/domain/ports.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'memory_notebook.dart';

class TestCapture implements CaptureSource {
  String? chosen = 'test-image';
  bool discarded = false;
  @override
  Future<String?> chooseImage({required bool camera}) async => chosen;
  @override
  Future<String> sampleImage() async => 'test-image';
  @override
  Future<String> persist(String path, String id) async => '';
  @override
  Future<String> digest(String path) async => 'sample-digest';
  @override
  Future<void> discard(String path) async {
    discarded = true;
  }
}

Future<NotebookController> testController({
  bool seeded = false,
  bool memory = false,
  bool demo = true,
}) async {
  sqfliteFfiInit();
  final NotebookRepository repository = memory
      ? WidgetNotebook()
      : await SqliteNotebook.open(
          inMemoryDatabasePath,
          factory: databaseFactoryFfi,
        );
  var id = 0;
  final controller = NotebookController(
    repository: repository,
    recognizer: const DemoTextRecognizer(),
    generator: const DemoActionGenerator(),
    capture: TestCapture(),
    newId: () => 'id-${++id}',
    clock: () => DateTime.utc(2026, 10, 18, 9),
    demo: demo,
  );
  await controller.load();
  if (seeded) {
    final evidence = (await controller.importSample())!;
    await controller.accept(evidence, (await controller.draft(evidence))!);
  }
  return controller;
}
