import 'models.dart';

EvidenceLine validateDraft(ActionDraft draft, Evidence evidence) {
  final matches = evidence.lines.where((line) => line.id == draft.lineId);
  if (matches.isEmpty ||
      draft.quote.trim().length < 4 ||
      !matches.first.text.contains(draft.quote.trim())) {
    throw const NotebookFailure(
      FailureCode.invalidInput,
      'The draft must quote its recognized source line exactly.',
    );
  }
  if (matches.first.confidence < 0.45) {
    throw const NotebookFailure(
      FailureCode.recognition,
      'Recognition is uncertain. Capture a clearer source before accepting.',
    );
  }
  return matches.first;
}

Issue acceptDraft({
  required ActionDraft draft,
  required Evidence evidence,
  required String id,
  required DateTime at,
}) {
  validateDraft(draft, evidence);
  return Issue(
    id: requireText(id, 'Issue ID', max: 100),
    evidenceId: evidence.id,
    lineId: draft.lineId,
    title: draft.title,
    quote: draft.quote.trim(),
    origin: draft.origin,
    status: IssueStatus.open,
    revision: 1,
    createdAt: at,
    updatedAt: at,
  );
}

Issue transitionIssue(Issue issue, IssueStatus next, String note, DateTime at) {
  requireText(note, 'Review note', max: 1000);
  if (issue.status == next || at.isBefore(issue.updatedAt)) {
    throw const NotebookFailure(
      FailureCode.invalidInput,
      'That change is not valid for the current issue.',
    );
  }
  return Issue(
    id: issue.id,
    evidenceId: issue.evidenceId,
    lineId: issue.lineId,
    title: issue.title,
    quote: issue.quote,
    origin: issue.origin,
    status: next,
    revision: issue.revision + 1,
    createdAt: issue.createdAt,
    updatedAt: at,
  );
}

ActionDraft extractiveDraft(Evidence evidence) {
  final line = evidence.lines.firstWhere(
    (line) => line.confidence >= 0.45,
    orElse: () => evidence.lines.first,
  );
  return ActionDraft(
    title:
        'Review: ${line.text.length > 150 ? line.text.substring(0, 150) : line.text}',
    quote: line.text,
    lineId: line.id,
    origin: DraftOrigin.extractive,
  );
}
