import 'package:flutter/material.dart';

import '../../../core/design.dart';
import '../application/notebook_controller.dart';
import '../domain/models.dart';
import 'evidence_preview.dart';

class NotebookPage extends StatelessWidget {
  const NotebookPage({
    super.key,
    required this.controller,
    required this.open,
    required this.capture,
  });
  final NotebookController controller;
  final void Function(Evidence) open;
  final VoidCallback capture;
  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot;
    final openCount = snapshot.issues
        .where((i) => i.status == IssueStatus.open)
        .length;
    final resolved = snapshot.issues.length - openCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NORTH WING  /  FIELD NOTES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Palette.muted,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Good records.\nClear handovers.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'Capture the source. Review the action.\nKeep the whole story on your device.',
        ),
        const SizedBox(height: 24),
        SurfaceCard(
          color: Palette.ink,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.radio_button_checked,
                    color: Color(0xFFB6D1AD),
                    size: 14,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'LOCAL NOTEBOOK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _Metric('${snapshot.evidence.length}', 'Sources'),
                  _Metric('$openCount', 'Open actions'),
                  _Metric('$resolved', 'Resolved'),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF3B5E58)),
              const SizedBox(height: 8),
              const Text(
                'Originals + quotes + review history',
                style: TextStyle(color: Color(0xFFCBDBD0), fontSize: 12),
              ),
            ],
          ),
        ),
        const SectionHeading('Evidence library', trailing: 'Stored on device'),
        if (snapshot.evidence.isEmpty)
          const EmptyCard(
            icon: Icons.document_scanner_outlined,
            title: 'Start with the source',
            message:
                'Scan the sample inspection card, or bring a photo of your own. The sample is synthetic; recognition is real in standard mode.',
          ),
        ...snapshot.evidence.map(
          (source) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              key: ValueKey('evidence-${source.id}'),
              borderRadius: BorderRadius.circular(20),
              onTap: () => open(source),
              child: SurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 74,
                      child: EvidencePreview(evidence: source),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Tag(source.source, active: true),
                          const SizedBox(height: 8),
                          Text(
                            source.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${source.lines.length} recognized lines · ${snapshot.issues.where((i) => i.evidenceId == source.id).length} actions',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Open source & review',
                            style: TextStyle(
                              fontSize: 12,
                              color: Palette.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.busy ? null : capture,
            icon: const Icon(Icons.add),
            label: const Text('Add evidence'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('scan-sample'),
            onPressed: controller.busy
                ? null
                : () async {
                    final evidence = await controller.importSample();
                    if (evidence != null) open(evidence);
                  },
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Scan sample card'),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'No account. No API key. No document upload.',
          style: TextStyle(fontSize: 12, color: Palette.muted),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFCBDBD0)),
        ),
      ],
    ),
  );
}
