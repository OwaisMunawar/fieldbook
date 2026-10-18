import 'package:flutter/material.dart';

import '../../../core/design.dart';
import '../application/notebook_controller.dart';
import '../domain/models.dart';
import '../domain/workflow.dart';
import 'evidence_preview.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.controller,
    required this.evidence,
  });
  final NotebookController controller;
  final Evidence evidence;
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  ActionDraft? draft;
  String? selected;
  final title = TextEditingController();
  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  void setDraft(ActionDraft value) {
    setState(() {
      draft = value;
      selected = value.lineId;
      title.text = value.title;
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      return Scaffold(
        appBar: AppBar(title: const Text('Review evidence')),
        body: Column(
          children: [
            if (controller.error != null)
              FailureBanner(
                message: controller.error!.message,
                dismiss: controller.clearError,
              ),
            if (controller.busy)
              const LinearProgressIndicator(
                semanticsLabel: 'Processing on device',
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Tag(widget.evidence.source, active: true),
                            const Tag('Original retained'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.evidence.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'A proposed action is only a draft. Compare the quote with the original before accepting.',
                        ),
                        const SizedBox(height: 20),
                        EvidencePreview(
                          evidence: widget.evidence,
                          selectedLineId: selected,
                        ),
                        const SectionHeading(
                          'Recognized lines',
                          trailing: 'Tap to quote',
                        ),
                        ...widget.evidence.lines.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: selected == line.id
                                  ? Palette.mint
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                selected: selected == line.id,
                                leading: Text(
                                  line.id,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                title: Text(line.text),
                                subtitle: Text(
                                  'OCR confidence ${(line.confidence * 100).round()}% · verify visually',
                                ),
                                trailing: const Icon(
                                  Icons.format_quote,
                                  size: 20,
                                ),
                                onTap: controller.busy
                                    ? null
                                    : () => setDraft(
                                        ActionDraft(
                                          title:
                                              'Review: ${line.text.length > 150 ? line.text.substring(0, 150) : line.text}',
                                          quote: line.text,
                                          lineId: line.id,
                                          origin: DraftOrigin.extractive,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: controller.busy
                                ? null
                                : () async {
                                    final candidate = await controller.draft(
                                      widget.evidence,
                                    );
                                    if (candidate != null && mounted) {
                                      setDraft(candidate);
                                    }
                                  },
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('Draft action on device'),
                          ),
                        ),
                        if (draft != null) ...[
                          const SectionHeading('Inspector review'),
                          SurfaceCard(
                            color: Palette.mint,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Tag(draft!.origin.label, active: true),
                                const SizedBox(height: 12),
                                Text(
                                  '“${draft!.quote}”',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Source ${draft!.lineId} · ${draft!.origin == DraftOrigin.foundationModels
                                      ? 'The quote is checked; the proposed action still needs your judgment.'
                                      : draft!.origin == DraftOrigin.demo
                                      ? 'Scripted output for demonstration. No language model ran.'
                                      : 'A source line reused as a draft. No language model ran.'}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: title,
                            maxLength: 180,
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Action to record',
                              helperText:
                                  'Edit the action; the source quote stays unchanged.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              key: const ValueKey('accept-action'),
                              onPressed: controller.busy
                                  ? null
                                  : () async {
                                      try {
                                        final reviewed = ActionDraft(
                                          title: title.text,
                                          quote: draft!.quote,
                                          lineId: draft!.lineId,
                                          origin: draft!.origin,
                                        );
                                        validateDraft(
                                          reviewed,
                                          widget.evidence,
                                        );
                                        final accepted = await controller
                                            .accept(widget.evidence, reviewed);
                                        if (accepted == true &&
                                            context.mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      } on NotebookFailure catch (error) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(error.message),
                                          ),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.check),
                              label: const Text('Accept reviewed action'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
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
