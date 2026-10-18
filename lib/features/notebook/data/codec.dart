import '../domain/models.dart';

Map<String, Object?> lineToMap(EvidenceLine line) => {
  'id': line.id,
  'text': line.text,
  'confidence': line.confidence,
  'x': line.region.x,
  'y': line.region.y,
  'width': line.region.width,
  'height': line.region.height,
};
EvidenceLine lineFromMap(Map<String, Object?> map) => EvidenceLine(
  id: map['id']! as String,
  text: map['text']! as String,
  confidence: (map['confidence']! as num).toDouble(),
  region: Region(
    (map['x']! as num).toDouble(),
    (map['y']! as num).toDouble(),
    (map['width']! as num).toDouble(),
    (map['height']! as num).toDouble(),
  ),
);
Map<String, Object?> issueToMap(Issue issue) => {
  'id': issue.id,
  'evidence_id': issue.evidenceId,
  'line_id': issue.lineId,
  'title': issue.title,
  'quote': issue.quote,
  'origin': issue.origin.name,
  'status': issue.status.name,
  'revision': issue.revision,
  'created_at': issue.createdAt.toUtc().toIso8601String(),
  'updated_at': issue.updatedAt.toUtc().toIso8601String(),
};
Issue issueFromMap(Map<String, Object?> map) => Issue(
  id: map['id']! as String,
  evidenceId: map['evidence_id']! as String,
  lineId: map['line_id']! as String,
  title: map['title']! as String,
  quote: map['quote']! as String,
  origin: DraftOrigin.values.byName(map['origin']! as String),
  status: IssueStatus.values.byName(map['status']! as String),
  revision: map['revision']! as int,
  createdAt: DateTime.parse(map['created_at']! as String),
  updatedAt: DateTime.parse(map['updated_at']! as String),
);
