import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'features/notebook/application/notebook_controller.dart';
import 'features/notebook/data/local_capture.dart';
import 'features/notebook/data/native_intelligence.dart';
import 'features/notebook/data/sqlite_notebook.dart';

final notebookProvider = FutureProvider<NotebookController>((ref) async {
  const demo = bool.fromEnvironment('FIELDBOOK_DEMO');
  const channel = MethodChannel('com.owaismunawar.fieldbook/intelligence');
  final directory = await getApplicationSupportDirectory();
  final repository = await SqliteNotebook.open(
    p.join(directory.path, demo ? 'demo.db' : 'notebook.db'),
  );
  final controller = NotebookController(
    repository: repository,
    recognizer: demo
        ? const DemoTextRecognizer()
        : const VisionTextRecognizer(channel),
    generator: demo
        ? const DemoActionGenerator()
        : const NativeActionGenerator(channel),
    capture: LocalCapture(ImagePicker()),
    newId: const Uuid().v4,
    clock: () => DateTime.now().toUtc(),
    demo: demo,
  );
  ref.onDispose(() {
    controller.dispose();
    unawaited(repository.close());
  });
  await controller.load();
  return controller;
});
