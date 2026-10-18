import 'dart:io';

import 'package:fieldbook/features/notebook/data/sqlite_notebook.dart';
import 'package:fieldbook/features/notebook/domain/models.dart';
import 'package:fieldbook/features/notebook/domain/workflow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../domain/workflow_test.dart' show fixture, draft;

void main() {
  sqfliteFfiInit();
  late SqliteNotebook repository;
  setUp(() async {
    repository = await SqliteNotebook.open(
      inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() async {
    await repository.close();
  });
  test(
    'idempotent source import and immutable quote review survive a snapshot',
    () async {
      final source = fixture();
      await repository.addEvidence(source);
      final duplicate = await repository.addEvidence(source);
      expect(duplicate.id, source.id);
      expect((await repository.read()).evidence.length, 1);
      final issue = acceptDraft(
        draft: draft(),
        evidence: source,
        id: 'i1',
        at: DateTime.utc(2026),
      );
      await repository.accept(issue);
      await expectLater(
        repository.accept(issue),
        throwsA(isA<NotebookFailure>()),
      );
      var snapshot = await repository.read();
      expect(snapshot.issues.single.quote, issue.quote);
      expect(snapshot.evidence.single.lines.single.region.y, 0.2);
      expect(snapshot.events.single.action, 'accepted');
      await repository.changeStatus(
        issue,
        IssueStatus.resolved,
        'Fixings checked',
        DateTime.utc(2026, 2),
      );
      await expectLater(
        repository.changeStatus(
          issue,
          IssueStatus.resolved,
          'Stale edit',
          DateTime.utc(2026, 3),
        ),
        throwsA(
          isA<NotebookFailure>().having(
            (e) => e.code,
            'code',
            FailureCode.staleRevision,
          ),
        ),
      );
      snapshot = await repository.read();
      expect(snapshot.issues.single.revision, 2);
      expect(snapshot.events.length, 2);
      await repository.changeStatus(
        snapshot.issues.single,
        IssueStatus.open,
        'Recheck',
        DateTime.utc(2026, 3),
      );
      expect((await repository.read()).events.length, 3);
    },
  );
  test(
    'missing sources and invalid quotes cannot create orphan issues',
    () async {
      final issue = acceptDraft(
        draft: draft(),
        evidence: fixture(),
        id: 'i1',
        at: DateTime.utc(2026),
      );
      await expectLater(
        repository.accept(issue),
        throwsA(isA<NotebookFailure>()),
      );
      await expectLater(
        repository.changeStatus(
          issue,
          IssueStatus.resolved,
          'Missing',
          DateTime.utc(2026, 2),
        ),
        throwsA(isA<NotebookFailure>()),
      );
      expect((await repository.read()).events, isEmpty);
    },
  );
  test('two concurrent reviews produce exactly one new revision', () async {
    await repository.addEvidence(fixture());
    final issue = acceptDraft(
      draft: draft(),
      evidence: fixture(),
      id: 'i1',
      at: DateTime.utc(2026),
    );
    await repository.accept(issue);
    final outcomes = await Future.wait(
      [1, 2].map((n) async {
        try {
          await repository.changeStatus(
            issue,
            IssueStatus.resolved,
            'Review $n',
            DateTime.utc(2026, 2),
          );
          return true;
        } on NotebookFailure {
          return false;
        }
      }),
    );
    expect(outcomes.where((ok) => ok).length, 1);
    expect((await repository.read()).events.length, 2);
  });
  test(
    'disk reopen restores history and database rejects history edits',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'fieldbook-test-',
      );
      final path = '${directory.path}/notebook.db';
      final disk = await SqliteNotebook.open(path, factory: databaseFactoryFfi);
      await disk.addEvidence(fixture());
      await disk.accept(
        acceptDraft(
          draft: draft(),
          evidence: fixture(),
          id: 'i1',
          at: DateTime.utc(2026),
        ),
      );
      await disk.close();
      final reopened = await SqliteNotebook.open(
        path,
        factory: databaseFactoryFfi,
      );
      expect(
        (await reopened.read()).issues.single.title,
        'Inspect handrail fixings',
      );
      await reopened.close();
      final raw = await databaseFactoryFfi.openDatabase(path);
      await expectLater(
        raw.rawUpdate("UPDATE events SET note = 'changed'"),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        raw.delete('events'),
        throwsA(isA<DatabaseException>()),
      );
      await raw.close();
      await directory.delete(recursive: true);
    },
  );
}
