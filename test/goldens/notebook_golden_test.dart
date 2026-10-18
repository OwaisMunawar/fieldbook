@Tags(['golden'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:fieldbook/app.dart';
import 'package:fieldbook/core/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/notebook_fixture.dart';

class TolerantComparator extends LocalFileComparator {
  TolerantComparator(super.testFile);
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final expected = await getGoldenBytes(golden);
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      expected,
    );
    final passes = result.passed || result.diffPercent <= 0.005;
    if (!passes) {
      final output = await generateFailureOutput(result, golden, basedir);
      result.dispose();
      throw FlutterError(output);
    }
    result.dispose();
    return true;
  }
}

void main() {
  setUpAll(
    () => goldenFileComparator = TolerantComparator(
      Uri.file(
        '${Directory.current.path}/test/goldens/notebook_golden_test.dart',
      ),
    ),
  );
  for (final name in ['notebook', 'actions', 'report']) {
    testWidgets('$name layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = await testController(seeded: true, memory: true);
      await tester.pumpWidget(
        MaterialApp(
          theme: notebookTheme(),
          home: NotebookShell(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      if (name != 'notebook') {
        await tester.tap(find.text(name == 'actions' ? 'Actions' : 'Report'));
        await tester.pumpAndSettle();
      }
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('$name.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await controller.repository.close();
    });
  }
}
