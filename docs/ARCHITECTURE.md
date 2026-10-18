# Architecture decisions

## ADR 1 — Preserve evidence before polishing language

**Decision:** OCR lines have stable IDs, confidence and image-relative regions. A draft quotes one line. The domain checks the quote belongs to that line; the inspector compares the OCR with the original image and accepts an edited action explicitly.

**Rejected:** storing only a generated summary. A fluent summary cannot reconstruct the evidence. Semantic entailment is not asserted by a substring check; fabricated actions with valid quotes remain a human-review concern.

Vision coordinates originate at the bottom left. The native adapter converts them to top-left normalized coordinates. The image preview and its overlay share the same image-sized stack, preserving alignment across layouts.

## ADR 2 — Local native intelligence behind ports

**Decision:** `TextRecognizer` and `ActionGenerator` are Dart interfaces. Vision and Foundation Models are platform-channel adapters; deterministic implementations exercise the same controller and validation rules. The composition root selects adapters. The domain imports no Flutter, storage or channel code.

**Rejected:** an API key compiled into the client, a mandatory cloud backend, or a first-launch model download. The native frameworks fit a bounded inspection follow-up without managing a downloaded runtime. The cost is an iOS-only first release and OS-dependent model availability.

Foundation Models receives a bounded JSON array of indexed source lines and produces a guided Swift action with a source index. The native adapter checks that index and binds the exact original quote and ID. Asking the model to reproduce citation metadata was rejected after real simulator runs returned mismatched quote/ID pairs; source metadata is now copied deterministically. Dart validates the bound quote again at the domain boundary. It has no tools, permissions or automatic write access. Source text is treated as untrusted; validation still cannot prove that a proposed action is sensible. Unavailable models yield explicitly extractive output. Generation failures and timeouts are reported rather than silently rebranded as model output.

## ADR 3 — Transactions and revisions, not optimistic checkmarks

**Decision:** SQLite owns sources, issues and events. Acceptance validates the stored source, inserts the issue and its initial event in one transaction. A status change reads the stored issue, checks the caller's revision, runs the pure transition rule, updates with the expected revision and appends an event atomically. A failed command rolls back both records.

Unique `(evidence_id, line_id, quote)` prevents duplicate actions. A unique fingerprint makes re-importing the same image bytes idempotent; semantically equivalent recompressed images are distinct. Triggers prohibit event updates and deletes through the normal database connection. This is local history integrity, not protection against a person who controls the database file.

**Rejected:** preferences containing a JSON document; they do not provide relational constraints or multi-record transactions. Also rejected: a sync engine before there is a second participant. Multi-device identity, merge policy and conflict review are separate work.

## ADR 4 — Compensate file writes across the database boundary

**Decision:** recognition completes before the durable image copy. A successful copy is referenced by an evidence row. If persistence fails and the reference is absent, the controller removes its own copied file. If the database commit succeeded but the next read fails, it retains the referenced image. It never removes the selected original.

**Rejected:** claiming a filesystem write and a SQLite commit are one atomic transaction. They are not. A process kill between the copy and database insert can leave an orphan file; startup orphan reconciliation is future work. This release does not expose deletion controls.

## ADR 5 — Search returns evidence, not answers

**Decision:** lowercase token sets and deterministic overlap scoring rank recognized source lines. Empty or unmatched queries return no evidence. Ties break on source and line IDs. No external index or embedding model is required.

**Rejected:** a language model paraphrasing search results without reliable evidence selection. Also rejected: a vector index before the notebook's scale requires it. The current linear scan is intentionally bounded by the small-notebook use case, not offered as a large-corpus search engine.

## ADR 6 — Portable records with explicit scope

**Decision:** the report is versioned JSON containing source IDs, OCR lines and regions, SHA-256 digests, reviewed actions and revision history. It omits local paths and images. The system share sheet is the only export action; the user chooses the destination. The popover anchor is nonzero on iPad.

**Rejected:** calling a text report a backup or a compliance certificate. Neither restoration nor authenticity is implemented. Rendered PDF and signed record formats need separate design.

## Ownership and boundaries

- `domain`: immutable snapshots, validated source values, review rules, search and report formatting.
- `application`: injected orchestration and observable UI state; no concrete data adapters.
- `data`: SQLite, platform channels, photo capture, private files and report sharing.
- `presentation`: screens and shared primitives; no direct data-layer imports.
- `bootstrap.dart` / `app.dart`: lifecycle and adapter composition.

`tool/check_architecture.dart` checks forbidden imports in CI. The domain has no singletons. Platform plugins are used only at the app boundary. No server exists in this release; there is no server/client secret crossing to configure.
