enum FailureCode {
  invalidInput,
  unsupported,
  unavailable,
  recognition,
  storage,
  staleRevision,
  duplicate,
}

class NotebookFailure implements Exception {
  const NotebookFailure(this.code, this.message);
  final FailureCode code;
  final String message;
  @override
  String toString() => message;
}

String requireText(String value, String label, {int max = 4000}) {
  final text = value.trim();
  if (text.isEmpty || text.length > max) {
    throw NotebookFailure(
      FailureCode.invalidInput,
      '$label must contain 1–$max characters.',
    );
  }
  return text;
}

class Region {
  Region(this.x, this.y, this.width, this.height) {
    if ([x, y, width, height].any((v) => !v.isFinite || v < 0 || v > 1) ||
        width == 0 ||
        height == 0 ||
        x + width > 1.001 ||
        y + height > 1.001) {
      throw const NotebookFailure(
        FailureCode.invalidInput,
        'Invalid text region.',
      );
    }
  }
  final double x;
  final double y;
  final double width;
  final double height;
}

class EvidenceLine {
  EvidenceLine({
    required String id,
    required String text,
    required this.confidence,
    required this.region,
  }) : id = requireText(id, 'Line ID', max: 100),
       text = requireText(text, 'Recognized text') {
    if (!confidence.isFinite || confidence < 0 || confidence > 1) {
      throw const NotebookFailure(
        FailureCode.invalidInput,
        'Invalid recognition confidence.',
      );
    }
  }
  final String id;
  final String text;
  final double confidence;
  final Region region;
}

class Evidence {
  Evidence({
    required String id,
    required String title,
    required this.imagePath,
    required this.fingerprint,
    required this.capturedAt,
    required List<EvidenceLine> lines,
    required this.source,
  }) : id = requireText(id, 'Evidence ID', max: 100),
       title = requireText(title, 'Title', max: 120),
       lines = List.unmodifiable(lines) {
    if (lines.isEmpty ||
        lines.length > 200 ||
        lines.map((e) => e.id).toSet().length != lines.length) {
      throw const NotebookFailure(
        FailureCode.invalidInput,
        'Evidence needs 1–200 uniquely identified lines.',
      );
    }
  }
  final String id;
  final String title;
  final String imagePath;
  final String fingerprint;
  final DateTime capturedAt;
  final List<EvidenceLine> lines;
  final String source;
}

enum DraftOrigin { foundationModels, demo, extractive }

extension DraftOriginLabel on DraftOrigin {
  String get label => switch (this) {
    DraftOrigin.foundationModels => 'On-device AI',
    DraftOrigin.demo => 'Scripted demo',
    DraftOrigin.extractive => 'Extractive fallback',
  };
}

class ActionDraft {
  ActionDraft({
    required String title,
    required this.quote,
    required this.lineId,
    required this.origin,
  }) : title = requireText(title, 'Action', max: 180);
  final String title;
  final String quote;
  final String lineId;
  final DraftOrigin origin;
}

enum IssueStatus { open, resolved }

class Issue {
  const Issue({
    required this.id,
    required this.evidenceId,
    required this.lineId,
    required this.title,
    required this.quote,
    required this.origin,
    required this.status,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final String evidenceId;
  final String lineId;
  final String title;
  final String quote;
  final DraftOrigin origin;
  final IssueStatus status;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class IssueEvent {
  const IssueEvent({
    required this.issueId,
    required this.revision,
    required this.action,
    required this.note,
    required this.at,
  });
  final String issueId;
  final int revision;
  final String action;
  final String note;
  final DateTime at;
}

class NotebookSnapshot {
  NotebookSnapshot({
    required List<Evidence> evidence,
    required List<Issue> issues,
    required List<IssueEvent> events,
  }) : evidence = List.unmodifiable(evidence),
       issues = List.unmodifiable(issues),
       events = List.unmodifiable(events);
  final List<Evidence> evidence;
  final List<Issue> issues;
  final List<IssueEvent> events;
}
