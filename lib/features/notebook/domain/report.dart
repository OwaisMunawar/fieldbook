import 'dart:convert';

import 'models.dart';

Map<String, Object?> buildReport(NotebookSnapshot snapshot, DateTime at) => {
  'schema_version': 1,
  'generated_at': at.toUtc().toIso8601String(),
  'project': 'North Wing / Inspection notebook',
  'notice':
      'Inspector-reviewed observations. Not a compliance certificate or a safety assessment. Quotes are OCR output; verify against the original image.',
  'counts': {
    'evidence': snapshot.evidence.length,
    'open': snapshot.issues.where((i) => i.status == IssueStatus.open).length,
    'resolved': snapshot.issues
        .where((i) => i.status == IssueStatus.resolved)
        .length,
  },
  'evidence': snapshot.evidence
      .map(
        (e) => {
          'id': e.id,
          'title': e.title,
          'sha256': e.fingerprint,
          'source': e.source,
          'captured_at': e.capturedAt.toUtc().toIso8601String(),
          'lines': e.lines
              .map(
                (line) => {
                  'id': line.id,
                  'text': line.text,
                  'confidence': line.confidence,
                  'region': {
                    'x': line.region.x,
                    'y': line.region.y,
                    'width': line.region.width,
                    'height': line.region.height,
                  },
                },
              )
              .toList(),
        },
      )
      .toList(),
  'issues': snapshot.issues
      .map(
        (i) => {
          'id': i.id,
          'title': i.title,
          'status': i.status.name,
          'revision': i.revision,
          'evidence_id': i.evidenceId,
          'line_id': i.lineId,
          'quote': i.quote,
          'draft_origin': i.origin.name,
          'created_at': i.createdAt.toUtc().toIso8601String(),
          'updated_at': i.updatedAt.toUtc().toIso8601String(),
        },
      )
      .toList(),
  'history': snapshot.events
      .map(
        (event) => {
          'issue_id': event.issueId,
          'revision': event.revision,
          'action': event.action,
          'note': event.note,
          'at': event.at.toUtc().toIso8601String(),
        },
      )
      .toList(),
};
String encodeReport(NotebookSnapshot snapshot, DateTime at) =>
    const JsonEncoder.withIndent('  ').convert(buildReport(snapshot, at));
