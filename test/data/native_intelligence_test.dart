import 'dart:async';

import 'package:fieldbook/features/notebook/data/codec.dart';
import 'package:fieldbook/features/notebook/data/native_intelligence.dart';
import 'package:fieldbook/features/notebook/domain/models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/workflow_test.dart' show fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test.fieldbook/intelligence');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  test('Vision bridge decodes text, confidence and top-left regions', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => fixture().lines.map(lineToMap).toList(),
    );
    final lines = await const VisionTextRecognizer(
      channel,
    ).recognize('image.png');
    expect(lines.single.region.y, 0.2);
    expect(lines.single.text, contains('Handrail'));
  });
  test(
    'Vision rejects empty, malformed, absent and timed-out native responses',
    () async {
      for (final response in [
        <Object?>[],
        [
          {'id': 3},
        ],
      ]) {
        messenger.setMockMethodCallHandler(channel, (call) async => response);
        await expectLater(
          const VisionTextRecognizer(channel).recognize('image'),
          throwsA(isA<NotebookFailure>()),
        );
      }
      messenger.setMockMethodCallHandler(channel, null);
      await expectLater(
        const VisionTextRecognizer(channel).recognize('image'),
        throwsA(
          isA<NotebookFailure>().having(
            (e) => e.code,
            'code',
            FailureCode.unsupported,
          ),
        ),
      );
      messenger.setMockMethodCallHandler(
        channel,
        (call) => Completer<Object?>().future,
      );
      await expectLater(
        const VisionTextRecognizer(
          channel,
          timeout: Duration(milliseconds: 10),
        ).recognize('image'),
        throwsA(
          isA<NotebookFailure>().having(
            (e) => e.code,
            'code',
            FailureCode.unavailable,
          ),
        ),
      );
    },
  );
  test('generated quotes are checked against the stated evidence', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'modelStatus'
          ? 'available'
          : {
              'title': 'Inspect handrail',
              'quote': 'Handrail loose',
              'lineId': 'L1',
            },
    );
    final result = await const NativeActionGenerator(
      channel,
    ).generate(fixture());
    expect(result.origin, DraftOrigin.foundationModels);
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'modelStatus'
          ? 'available'
          : {'title': 'Wrong', 'quote': 'Invented quote', 'lineId': 'L1'},
    );
    await expectLater(
      const NativeActionGenerator(channel).generate(fixture()),
      throwsA(isA<NotebookFailure>()),
    );
  });
  test('unavailable model yields a visibly extractive draft', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => 'unavailable');
    final result = await const NativeActionGenerator(
      channel,
    ).generate(fixture());
    expect(result.origin, DraftOrigin.extractive);
  });
  test(
    'model errors, malformed output and timeouts remain explicit failures',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'unavailable');
      });
      await expectLater(
        const NativeActionGenerator(channel).generate(fixture()),
        throwsA(isA<NotebookFailure>()),
      );
      messenger.setMockMethodCallHandler(
        channel,
        (call) async =>
            call.method == 'modelStatus' ? 'available' : {'title': 3},
      );
      await expectLater(
        const NativeActionGenerator(channel).generate(fixture()),
        throwsA(
          isA<NotebookFailure>().having(
            (e) => e.code,
            'code',
            FailureCode.invalidInput,
          ),
        ),
      );
      messenger.setMockMethodCallHandler(
        channel,
        (call) => Completer<Object?>().future,
      );
      await expectLater(
        const NativeActionGenerator(
          channel,
          timeout: Duration(milliseconds: 10),
        ).generate(fixture()),
        throwsA(
          isA<NotebookFailure>().having(
            (e) => e.code,
            'code',
            FailureCode.unavailable,
          ),
        ),
      );
    },
  );
  test(
    'demo recognition and generation are deterministic and labelled',
    () async {
      final lines = await const DemoTextRecognizer().recognize('sample');
      expect(lines.length, 3);
      expect(
        (await const DemoActionGenerator().generate(fixture())).origin,
        DraftOrigin.demo,
      );
    },
  );
}
