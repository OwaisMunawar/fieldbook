import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../domain/ports.dart';
import '../domain/workflow.dart';

class NotebookController extends ChangeNotifier {
  NotebookController({
    required this.repository,
    required this.recognizer,
    required this.generator,
    required this.capture,
    required this.newId,
    required this.clock,
    this.demo = false,
  });
  final NotebookRepository repository;
  final TextRecognizer recognizer;
  final ActionGenerator generator;
  final CaptureSource capture;
  final String Function() newId;
  final DateTime Function() clock;
  final bool demo;
  NotebookSnapshot _snapshot = NotebookSnapshot(
    evidence: [],
    issues: [],
    events: [],
  );
  NotebookFailure? _error;
  bool _busy = false;
  NotebookSnapshot get snapshot => _snapshot;
  NotebookFailure? get error => _error;
  bool get busy => _busy;

  Future<void> load() async {
    _snapshot = await repository.read();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<T?> _run<T>(Future<T> Function() operation) async {
    if (busy) return null;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      return await operation();
    } on NotebookFailure catch (failure) {
      _error = failure;
      return null;
    } catch (_) {
      _error = const NotebookFailure(
        FailureCode.storage,
        'The operation could not finish. Reload the notebook before trying again.',
      );
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<Evidence?> importSample() => _run(
    () async => _capture(await capture.sampleImage(), 'Inspection card 014'),
  );
  Future<Evidence?> importPhoto({
    required bool camera,
  }) => _run<Evidence?>(() async {
    if (demo) {
      throw const NotebookFailure(
        FailureCode.unsupported,
        'Demo mode uses the sample card. Run standard mode to import your own photos.',
      );
    }
    final path = await capture.chooseImage(camera: camera);
    if (path == null) return null;
    return _capture(path, 'Field observation ${snapshot.evidence.length + 1}');
  });

  Future<Evidence> _capture(String path, String title) async {
    final fingerprint = await capture.digest(path);
    final existing = snapshot.evidence.where(
      (e) => e.fingerprint == fingerprint,
    );
    if (existing.isNotEmpty) return existing.first;
    final lines = await recognizer.recognize(path);
    final id = newId();
    final stored = await capture.persist(path, id);
    try {
      final evidence = Evidence(
        id: id,
        title: title,
        imagePath: stored,
        fingerprint: fingerprint,
        capturedAt: clock(),
        lines: lines,
        source: demo ? 'Scripted demo OCR' : 'Apple Vision OCR',
      );
      final saved = await repository.addEvidence(evidence);
      if (saved.id != id) await capture.discard(stored);
      await load();
      return saved;
    } catch (_) {
      // Compensate only before the reference is committed; a later read failure must not remove evidence.
      final saved = (await repository.read()).evidence.any(
        (e) => e.imagePath == stored,
      );
      if (!saved) await capture.discard(stored);
      rethrow;
    }
  }

  Future<bool?> reload() => _run(() async {
    await load();
    return true;
  });

  Future<ActionDraft?> draft(Evidence evidence) => _run(() async {
    final candidate = await generator.generate(evidence);
    validateDraft(candidate, evidence);
    return candidate;
  });

  Future<bool?> accept(Evidence evidence, ActionDraft draft) => _run(() async {
    final issue = acceptDraft(
      draft: draft,
      evidence: evidence,
      id: newId(),
      at: clock(),
    );
    await repository.accept(issue);
    await load();
    return true;
  });

  Future<bool?> changeStatus(Issue issue, IssueStatus next, String note) =>
      _run(() async {
        await repository.changeStatus(issue, next, note, clock());
        await load();
        return true;
      });
}
