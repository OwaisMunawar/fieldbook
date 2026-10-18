import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/ports.dart';
import '../domain/workflow.dart';
import 'codec.dart';

class VisionTextRecognizer implements TextRecognizer {
  const VisionTextRecognizer(
    this.channel, {
    this.timeout = const Duration(seconds: 30),
  });
  final Duration timeout;
  final MethodChannel channel;
  @override
  Future<List<EvidenceLine>> recognize(String imagePath) async {
    try {
      final value = await channel
          .invokeMethod<Object?>('recognize', {'path': imagePath})
          .timeout(timeout);
      final lines = (value! as List<Object?>)
          .map(
            (row) => lineFromMap(
              (row! as Map<Object?, Object?>).map(
                (key, value) => MapEntry(key! as String, value),
              ),
            ),
          )
          .toList();
      if (lines.isEmpty) {
        throw const NotebookFailure(
          FailureCode.recognition,
          'No text found. Try a clearer, upright image.',
        );
      }
      return lines;
    } on NotebookFailure {
      rethrow;
    } on MissingPluginException {
      throw const NotebookFailure(
        FailureCode.unsupported,
        'Text recognition requires the iOS app.',
      );
    } on TimeoutException {
      throw const NotebookFailure(
        FailureCode.unavailable,
        'Text recognition timed out. Try again.',
      );
    } catch (_) {
      throw const NotebookFailure(
        FailureCode.recognition,
        'Could not read this image. Try a clear JPEG or PNG.',
      );
    }
  }
}

class NativeActionGenerator implements ActionGenerator {
  const NativeActionGenerator(
    this.channel, {
    this.timeout = const Duration(seconds: 45),
  });
  final Duration timeout;
  final MethodChannel channel;
  @override
  Future<ActionDraft> generate(Evidence evidence) async {
    try {
      final status = await channel
          .invokeMethod<String>('modelStatus')
          .timeout(timeout);
      if (status != 'available') return extractiveDraft(evidence);
      final value = await channel
          .invokeMethod<Object?>('draft', {
            'lines': evidence.lines
                .take(40)
                .map((line) => {'id': line.id, 'text': line.text})
                .toList(),
          })
          .timeout(timeout);
      final map = value! as Map<Object?, Object?>;
      final draft = ActionDraft(
        title: map['title']! as String,
        quote: map['quote']! as String,
        lineId: map['lineId']! as String,
        origin: DraftOrigin.foundationModels,
      );
      validateDraft(draft, evidence);
      return draft;
    } on NotebookFailure {
      rethrow;
    } on TimeoutException {
      throw const NotebookFailure(
        FailureCode.unavailable,
        'The model timed out. Use a source quote instead.',
      );
    } on PlatformException {
      throw const NotebookFailure(
        FailureCode.unavailable,
        'The on-device model could not finish. Use a source quote instead.',
      );
    } catch (_) {
      throw const NotebookFailure(
        FailureCode.invalidInput,
        'The draft did not match its evidence. Use a source quote instead.',
      );
    }
  }
}

class DemoTextRecognizer implements TextRecognizer {
  const DemoTextRecognizer();
  @override
  Future<List<EvidenceLine>> recognize(String imagePath) async => [
    EvidenceLine(
      id: 'L1',
      text: 'Handrail loose at north stair.',
      confidence: 0.98,
      region: Region(0.07, 0.38, 0.83, 0.04),
    ),
    EvidenceLine(
      id: 'L2',
      text: 'Ceiling panel stained near door E2.',
      confidence: 0.96,
      region: Region(0.07, 0.57, 0.86, 0.04),
    ),
    EvidenceLine(
      id: 'L3',
      text: 'Access label is missing.',
      confidence: 0.97,
      region: Region(0.07, 0.76, 0.64, 0.04),
    ),
  ];
}

class DemoActionGenerator implements ActionGenerator {
  const DemoActionGenerator();
  @override
  Future<ActionDraft> generate(Evidence evidence) async {
    final line = evidence.lines.firstWhere(
      (line) => line.text.contains('Handrail loose'),
      orElse: () => evidence.lines.first,
    );
    return ActionDraft(
      title: 'Inspect the north stair handrail',
      quote: line.text,
      lineId: line.id,
      origin: DraftOrigin.demo,
    );
  }
}
