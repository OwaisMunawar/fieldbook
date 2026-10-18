import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import '../domain/ports.dart';
import '../domain/workflow.dart';
import 'codec.dart';

class SqliteNotebook implements NotebookRepository {
  SqliteNotebook._(this._database);
  final Database _database;

  static Future<SqliteNotebook> open(
    String path, {
    DatabaseFactory? factory,
    bool singleInstance = true,
  }) async {
    final db = await (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        singleInstance: singleInstance,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE evidence (id TEXT PRIMARY KEY, title TEXT NOT NULL, image_path TEXT NOT NULL, fingerprint TEXT NOT NULL UNIQUE, captured_at TEXT NOT NULL, source TEXT NOT NULL, lines TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE issues (id TEXT PRIMARY KEY, evidence_id TEXT NOT NULL REFERENCES evidence(id), line_id TEXT NOT NULL, title TEXT NOT NULL, quote TEXT NOT NULL, origin TEXT NOT NULL, status TEXT NOT NULL CHECK(status IN (\'open\',\'resolved\')), revision INTEGER NOT NULL CHECK(revision > 0), created_at TEXT NOT NULL, updated_at TEXT NOT NULL, UNIQUE(evidence_id,line_id,quote))',
          );
          await db.execute(
            'CREATE TABLE events (issue_id TEXT NOT NULL REFERENCES issues(id), revision INTEGER NOT NULL, action TEXT NOT NULL, note TEXT NOT NULL, at TEXT NOT NULL, PRIMARY KEY(issue_id,revision))',
          );
          await db.execute('CREATE INDEX issues_status ON issues(status)');
          for (final verb in ['UPDATE', 'DELETE']) {
            await db.execute(
              'CREATE TRIGGER events_no_${verb.toLowerCase()} BEFORE $verb ON events BEGIN SELECT RAISE(ABORT, \'Review history is append-only\'); END',
            );
          }
        },
      ),
    );
    return SqliteNotebook._(db);
  }

  Evidence _evidence(Map<String, Object?> row) => Evidence(
    id: row['id']! as String,
    title: row['title']! as String,
    imagePath: row['image_path']! as String,
    fingerprint: row['fingerprint']! as String,
    capturedAt: DateTime.parse(row['captured_at']! as String),
    source: row['source']! as String,
    lines: (jsonDecode(row['lines']! as String) as List<Object?>)
        .map((line) => lineFromMap((line! as Map<String, Object?>)))
        .toList(),
  );

  @override
  Future<NotebookSnapshot> read() => _database.transaction(
    (txn) async => NotebookSnapshot(
      evidence: (await txn.query(
        'evidence',
        orderBy: 'captured_at DESC, id',
      )).map(_evidence).toList(),
      issues: (await txn.query(
        'issues',
        orderBy: 'created_at DESC, id',
      )).map(issueFromMap).toList(),
      events: (await txn.query('events', orderBy: 'at, issue_id, revision'))
          .map(
            (row) => IssueEvent(
              issueId: row['issue_id']! as String,
              revision: row['revision']! as int,
              action: row['action']! as String,
              note: row['note']! as String,
              at: DateTime.parse(row['at']! as String),
            ),
          )
          .toList(),
    ),
  );

  @override
  Future<Evidence> addEvidence(Evidence evidence) =>
      _database.transaction((txn) async {
        final existing = await txn.query(
          'evidence',
          where: 'fingerprint = ?',
          whereArgs: [evidence.fingerprint],
        );
        if (existing.isNotEmpty) return _evidence(existing.first);
        await txn.insert('evidence', {
          'id': evidence.id,
          'title': evidence.title,
          'image_path': evidence.imagePath,
          'fingerprint': evidence.fingerprint,
          'captured_at': evidence.capturedAt.toUtc().toIso8601String(),
          'source': evidence.source,
          'lines': jsonEncode(evidence.lines.map(lineToMap).toList()),
        });
        return evidence;
      });

  @override
  Future<void> accept(Issue issue) => _database.transaction((txn) async {
    final rows = await txn.query(
      'evidence',
      where: 'id = ?',
      whereArgs: [issue.evidenceId],
    );
    if (rows.isEmpty ||
        issue.revision != 1 ||
        issue.status != IssueStatus.open) {
      throw const NotebookFailure(
        FailureCode.invalidInput,
        'The source or initial review is invalid.',
      );
    }
    validateDraft(
      ActionDraft(
        title: issue.title,
        quote: issue.quote,
        lineId: issue.lineId,
        origin: issue.origin,
      ),
      _evidence(rows.first),
    );
    final duplicates = await txn.query(
      'issues',
      where: 'evidence_id = ? AND line_id = ? AND quote = ?',
      whereArgs: [issue.evidenceId, issue.lineId, issue.quote],
    );
    if (duplicates.isNotEmpty) {
      throw const NotebookFailure(
        FailureCode.duplicate,
        'This source quote already has an action.',
      );
    }
    await txn.insert('issues', issueToMap(issue));
    await txn.insert('events', {
      'issue_id': issue.id,
      'revision': 1,
      'action': 'accepted',
      'note': 'Source quote reviewed by the inspector.',
      'at': issue.createdAt.toUtc().toIso8601String(),
    });
  });

  @override
  Future<void> changeStatus(
    Issue current,
    IssueStatus next,
    String note,
    DateTime at,
  ) => _database.transaction((txn) async {
    final rows = await txn.query(
      'issues',
      where: 'id = ?',
      whereArgs: [current.id],
    );
    if (rows.isEmpty || (rows.first['revision']! as int) != current.revision) {
      throw const NotebookFailure(
        FailureCode.staleRevision,
        'This issue changed. Reload before reviewing it.',
      );
    }
    final updated = transitionIssue(issueFromMap(rows.first), next, note, at);
    final count = await txn.update(
      'issues',
      issueToMap(updated),
      where: 'id = ? AND revision = ?',
      whereArgs: [current.id, current.revision],
    );
    if (count != 1) {
      throw const NotebookFailure(
        FailureCode.staleRevision,
        'The review was not saved. Reload and retry.',
      );
    }
    await txn.insert('events', {
      'issue_id': current.id,
      'revision': updated.revision,
      'action': next.name,
      'note': note.trim(),
      'at': at.toUtc().toIso8601String(),
    });
  });

  @override
  Future<void> close() => _database.close();
}
