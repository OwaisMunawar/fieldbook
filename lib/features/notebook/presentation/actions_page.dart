import 'package:flutter/material.dart';

import '../../../core/design.dart';
import '../application/notebook_controller.dart';
import '../domain/models.dart';
import 'review_screen.dart';

class ActionsPage extends StatefulWidget {
  const ActionsPage({super.key, required this.controller});
  final NotebookController controller;
  @override
  State<ActionsPage> createState() => _ActionsPageState();
}

class _ActionsPageState extends State<ActionsPage> {
  IssueStatus filter = IssueStatus.open;
  @override
  Widget build(BuildContext context) {
    final issues = widget.controller.snapshot.issues
        .where((i) => i.status == filter)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Follow through.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'Every action leads back to its source. Every status change carries a review note.',
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          children: IssueStatus.values
              .map(
                (status) => ChoiceChip(
                  label: Text(status == IssueStatus.open ? 'Open' : 'Resolved'),
                  selected: filter == status,
                  onSelected: (_) => setState(() => filter = status),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        if (issues.isEmpty)
          EmptyCard(
            icon: Icons.task_alt,
            title: filter == IssueStatus.open
                ? 'No open actions'
                : 'No resolved actions',
            message: filter == IssueStatus.open
                ? 'Review a source and accept an action to start the log.'
                : 'Resolve an action with a review note to record it here.',
          ),
        ...issues.map(
          (issue) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              key: ValueKey('issue-${issue.id}'),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => IssueScreen(
                    controller: widget.controller,
                    issueId: issue.id,
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(20),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Tag(
                          issue.status == IssueStatus.open
                              ? 'TO REVIEW'
                              : 'RESOLVED',
                          active: true,
                        ),
                        Text(
                          'REV ${issue.revision}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      issue.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '“${issue.quote}”',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.link, size: 16, color: Palette.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Source ${issue.lineId} · ${issue.origin.label}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class IssueScreen extends StatelessWidget {
  const IssueScreen({
    super.key,
    required this.controller,
    required this.issueId,
  });
  final NotebookController controller;
  final String issueId;
  Future<void> _review(BuildContext context, Issue issue) async {
    final next = issue.status == IssueStatus.open
        ? IssueStatus.resolved
        : IssueStatus.open;
    final note = await showDialog<String>(
      context: context,
      builder: (_) =>
          _ReviewNoteDialog(resolving: next == IssueStatus.resolved),
    );
    if (note != null) await controller.changeStatus(issue, next, note);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final issue = controller.snapshot.issues.firstWhere(
        (i) => i.id == issueId,
      );
      final source = controller.snapshot.evidence.firstWhere(
        (e) => e.id == issue.evidenceId,
      );
      final history = controller.snapshot.events
          .where((event) => event.issueId == issueId)
          .toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Action record')),
        body: Column(
          children: [
            if (controller.error != null)
              FailureBanner(
                message: controller.error!.message,
                dismiss: controller.clearError,
              ),
            if (controller.busy) const LinearProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tag(
                          issue.status == IssueStatus.open
                              ? 'OPEN ACTION'
                              : 'RESOLVED BY INSPECTOR',
                          active: true,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          issue.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 24),
                        SurfaceCard(
                          color: Palette.mint,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '“${issue.quote}”',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${source.title} / ${issue.lineId}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute(
                                        builder: (_) => ReviewScreen(
                                          controller: controller,
                                          evidence: source,
                                        ),
                                      ),
                                    ),
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: const Text('Inspect original source'),
                              ),
                            ],
                          ),
                        ),
                        const SectionHeading('Review history'),
                        ...history.map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Tag(
                                        event.action.toUpperCase(),
                                        active: true,
                                      ),
                                      Text(
                                        'REV ${event.revision}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(event.note),
                                  const SizedBox(height: 8),
                                  Text(
                                    event.at.toLocal().toString().substring(
                                      0,
                                      16,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const ValueKey('change-status'),
                            onPressed: controller.busy
                                ? null
                                : () => _review(context, issue),
                            icon: Icon(
                              issue.status == IssueStatus.open
                                  ? Icons.task_alt
                                  : Icons.refresh,
                            ),
                            label: Text(
                              issue.status == IssueStatus.open
                                  ? 'Resolve with a review note'
                                  : 'Reopen with a review note',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'A recorded resolution reflects the inspector’s review. Fieldbook does not certify repairs or compliance.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ReviewNoteDialog extends StatefulWidget {
  const _ReviewNoteDialog({required this.resolving});
  final bool resolving;
  @override
  State<_ReviewNoteDialog> createState() => _ReviewNoteDialogState();
}

class _ReviewNoteDialogState extends State<_ReviewNoteDialog> {
  final input = TextEditingController();
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.resolving ? 'Record resolution' : 'Reopen action'),
    content: TextField(
      key: const ValueKey('review-note'),
      controller: input,
      autofocus: true,
      maxLength: 1000,
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Review note',
        hintText: 'What did you check or change?',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('save-review'),
        onPressed: () => Navigator.pop(context, input.text),
        child: const Text('Save review'),
      ),
    ],
  );
}
