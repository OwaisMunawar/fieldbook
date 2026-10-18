import 'package:fieldbook/features/notebook/domain/models.dart';
import 'package:fieldbook/features/notebook/domain/workflow.dart';
import 'package:flutter_test/flutter_test.dart';

Evidence fixture({double confidence = 0.98}) => Evidence(
  id: 'e1',
  title: 'North stair',
  imagePath: 'sample.png',
  fingerprint: 'digest',
  capturedAt: DateTime.utc(2026),
  source: 'Vision OCR',
  lines: [
    EvidenceLine(
      id: 'L1',
      text: 'Handrail loose at north stair.',
      confidence: confidence,
      region: Region(0.1, 0.2, 0.8, 0.1),
    ),
  ],
);
ActionDraft draft({String quote = 'Handrail loose', String lineId = 'L1'}) =>
    ActionDraft(
      title: 'Inspect handrail fixings',
      quote: quote,
      lineId: lineId,
      origin: DraftOrigin.demo,
    );
void main() {
  test('accepts only a quote belonging to the stated source line', () {
    final issue = acceptDraft(
      draft: draft(),
      evidence: fixture(),
      id: 'i1',
      at: DateTime.utc(2026),
    );
    expect(issue.status, IssueStatus.open);
    expect(issue.revision, 1);
    expect(issue.quote, 'Handrail loose');
    expect(issue.origin.label, 'Scripted demo');
    for (final invalid in [
      draft(quote: 'Invented evidence'),
      draft(quote: 'a'),
      draft(lineId: 'L2'),
    ]) {
      expect(
        () => validateDraft(invalid, fixture()),
        throwsA(isA<NotebookFailure>()),
      );
    }
    expect(
      () => validateDraft(draft(), fixture(confidence: 0.2)),
      throwsA(isA<NotebookFailure>()),
    );
  });
  test(
    'review transitions require a note, a new status and monotonic time',
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
        'Fixings checked',
        DateTime.utc(2026, 2),
      );
      expect(resolved.revision, 2);
      expect(resolved.status, IssueStatus.resolved);
      expect(resolved.createdAt, issue.createdAt);
      final reopened = transitionIssue(
        resolved,
        IssueStatus.open,
        'Needs recheck',
        DateTime.utc(2026, 3),
      );
      expect(reopened.revision, 3);
      expect(
        () => transitionIssue(
          issue,
          IssueStatus.open,
          'same',
          DateTime.utc(2026),
        ),
        throwsA(isA<NotebookFailure>()),
      );
      expect(
        () => transitionIssue(
          issue,
          IssueStatus.resolved,
          '',
          DateTime.utc(2026),
        ),
        throwsA(isA<NotebookFailure>()),
      );
      expect(
        () => transitionIssue(
          resolved,
          IssueStatus.open,
          'old',
          DateTime.utc(2025),
        ),
        throwsA(isA<NotebookFailure>()),
      );
    },
  );
  test('extractive fallback stays visibly distinct from model output', () {
    final result = extractiveDraft(fixture());
    expect(result.origin.label, 'Extractive fallback');
    expect(validateDraft(result, fixture()).id, 'L1');
    final long = Evidence(
      id: 'e',
      title: 'Title',
      imagePath: 'p',
      fingerprint: 'd',
      capturedAt: DateTime.utc(2026),
      source: 'Test',
      lines: [
        EvidenceLine(
          id: 'l',
          text: 'x' * 200,
          confidence: 0.9,
          region: Region(0, 0, 1, 1),
        ),
      ],
    );
    expect(extractiveDraft(long).title.length, lessThanOrEqualTo(180));
    expect(extractiveDraft(fixture(confidence: 0.1)).quote, isNotEmpty);
  });
  test(
    'rejects malformed recognition values and duplicate line identities',
    () {
      for (final box in [
        [-0.1, 0.0, 0.2, 0.1],
        [0.9, 0.0, 0.2, 0.1],
        [0.0, 0.0, 0.0, 0.1],
        [double.nan, 0.0, 0.2, 0.1],
      ]) {
        expect(
          () => Region(box[0], box[1], box[2], box[3]),
          throwsA(isA<NotebookFailure>()),
        );
      }
      for (final confidence in [-0.1, 1.1, double.nan]) {
        expect(
          () => fixture(confidence: confidence),
          throwsA(isA<NotebookFailure>()),
        );
      }
      expect(() => requireText(' ', 'Title'), throwsA(isA<NotebookFailure>()));
      expect(
        () => requireText('long', 'Title', max: 2),
        throwsA(isA<NotebookFailure>()),
      );
      expect(
        () => Evidence(
          id: 'e',
          title: 't',
          imagePath: 'p',
          fingerprint: 'f',
          capturedAt: DateTime.utc(2026),
          source: 'test',
          lines: [],
        ),
        throwsA(isA<NotebookFailure>()),
      );
      expect(
        () => Evidence(
          id: 'e',
          title: 't',
          imagePath: 'p',
          fingerprint: 'f',
          capturedAt: DateTime.utc(2026),
          source: 'test',
          lines: [fixture().lines.first, fixture().lines.first],
        ),
        throwsA(isA<NotebookFailure>()),
      );
      expect(() => fixture().lines.clear(), throwsUnsupportedError);
      expect(
        NotebookFailure(FailureCode.storage, 'failed').toString(),
        'failed',
      );
      expect(DraftOrigin.foundationModels.label, 'On-device AI');
    },
  );
}
