import 'package:fieldbook/features/notebook/domain/models.dart';
import 'package:fieldbook/features/notebook/domain/ports.dart';
import 'package:fieldbook/features/notebook/domain/workflow.dart';

// Widget tests keep platform I/O out of Flutter's fake clock. SQLite has separate integration tests.
class WidgetNotebook implements NotebookRepository {
  final List<Evidence> _evidence = [];
  final List<Issue> _issues = [];
  final List<IssueEvent> _events = [];
  @override
  Future<NotebookSnapshot> read() async =>
      NotebookSnapshot(evidence: _evidence, issues: _issues, events: _events);
  @override
  Future<Evidence> addEvidence(Evidence evidence) async {
    _evidence.add(evidence);
    return evidence;
  }

  @override
  Future<void> accept(Issue issue) async {
    if (_issues.any(
      (i) =>
          i.evidenceId == issue.evidenceId &&
          i.lineId == issue.lineId &&
          i.quote == issue.quote,
    )) {
      throw const NotebookFailure(FailureCode.duplicate, 'Already reviewed');
    }
    _issues.add(issue);
    _events.add(
      IssueEvent(
        issueId: issue.id,
        revision: 1,
        action: 'accepted',
        note: 'Source quote reviewed by the inspector.',
        at: issue.createdAt,
      ),
    );
  }

  @override
  Future<void> changeStatus(
    Issue current,
    IssueStatus next,
    String note,
    DateTime at,
  ) async {
    final index = _issues.indexWhere((issue) => issue.id == current.id);
    final updated = transitionIssue(_issues[index], next, note, at);
    _issues[index] = updated;
    _events.add(
      IssueEvent(
        issueId: current.id,
        revision: updated.revision,
        action: next.name,
        note: note,
        at: at,
      ),
    );
  }

  @override
  Future<void> close() async {}
}
