import 'dart:convert';

import 'package:fieldbook/features/notebook/domain/models.dart';
import 'package:fieldbook/features/notebook/domain/report.dart';
import 'package:fieldbook/features/notebook/domain/search.dart';
import 'package:fieldbook/features/notebook/domain/workflow.dart';
import 'package:flutter_test/flutter_test.dart';

import 'workflow_test.dart' show fixture, draft;

void main() {
  test(
    'search retrieves exact evidence, ranks overlap and abstains on no match',
    () {
      final evidence = fixture();
      expect(searchEvidence('HANDRAIL loose', [evidence]).single.line.id, 'L1');
      expect(searchEvidence('ceiling', [evidence]), isEmpty);
      expect(searchEvidence('the and is', [evidence]), isEmpty);
      expect(searchEvidence('handrail', [evidence], limit: 0), isEmpty);
      final others = Evidence(
        id: 'e0',
        title: 'Title',
        imagePath: 'path',
        fingerprint: 'hash',
        capturedAt: DateTime.utc(2026),
        source: 'test',
        lines: [
          EvidenceLine(
            id: 'L2',
            text: 'Handrail loose with some other observations today',
            confidence: 0.9,
            region: Region(0, 0, 1, 1),
          ),
          EvidenceLine(
            id: 'L1',
            text: 'Handrail',
            confidence: 0.9,
            region: Region(0, 0, 1, 1),
          ),
          EvidenceLine(
            id: 'L0',
            text: 'Handrail',
            confidence: 0.9,
            region: Region(0, 0, 1, 1),
          ),
        ],
      );
      expect(
        searchEvidence('handrail loose', [others, evidence]).first.evidence.id,
        'e1',
      );
      expect(searchEvidence('handrail', [others]).first.line.id, 'L0');
      expect(searchEvidence('handrail', [others], limit: 1).length, 1);
      final copy = Evidence(
        id: 'e2',
        title: 'Copy',
        imagePath: 'path',
        fingerprint: 'hash2',
        capturedAt: DateTime.utc(2026),
        source: 'test',
        lines: evidence.lines,
      );
      expect(
        searchEvidence('handrail', [copy, evidence]).first.evidence.id,
        'e1',
      );
    },
  );
  test(
    'report keeps quotes, origins and history, excludes private image paths',
    () {
      final issue = acceptDraft(
        draft: draft(),
        evidence: fixture(),
        id: 'i1',
        at: DateTime.utc(2026),
      );
      final resolved = transitionIssue(
        issue,
        IssueStatus.resolved,
        'Reviewed',
        DateTime.utc(2026, 2),
      );
      final snapshot = NotebookSnapshot(
        evidence: [fixture()],
        issues: [issue, resolved],
        events: [
          IssueEvent(
            issueId: 'i1',
            revision: 2,
            action: 'resolved',
            note: 'Reviewed',
            at: DateTime.utc(2026, 2),
          ),
        ],
      );
      final encoded = encodeReport(snapshot, DateTime.utc(2026, 3));
      final report = jsonDecode(encoded) as Map<String, Object?>;
      expect(report['schema_version'], 1);
      expect(report['counts'], {'evidence': 1, 'open': 1, 'resolved': 1});
      expect(encoded, contains('Handrail loose'));
      expect(encoded, contains('demo'));
      expect(encoded, isNot(contains('sample.png')));
      expect(encoded, contains('Reviewed'));
      expect(() => snapshot.issues.clear(), throwsUnsupportedError);
    },
  );
}
