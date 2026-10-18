import 'package:flutter/material.dart';

import '../../../core/design.dart';
import '../domain/models.dart';
import '../domain/report.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key, required this.snapshot, required this.share});
  final NotebookSnapshot snapshot;
  final Future<void> Function(NotebookSnapshot, Rect) share;
  @override
  Widget build(BuildContext context) {
    final resolved = snapshot.issues
        .where((issue) => issue.status == IssueStatus.resolved)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ready for handover.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'A portable record of the source, the action and the review. Export only when you choose.',
        ),
        const SizedBox(height: 24),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Tag('INSPECTION RECORD', active: true),
              const SizedBox(height: 16),
              Text(
                'North Wing',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '${snapshot.evidence.length} sources · ${snapshot.issues.length} reviewed actions · $resolved resolved',
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              ...[
                (
                  '01',
                  'Source records',
                  'OCR text, regions and image SHA-256 digests',
                ),
                (
                  '02',
                  'Reviewed actions',
                  'Exact quotes, draft origins and current status',
                ),
                (
                  '03',
                  'Revision history',
                  'Acceptance, resolution and reopening notes',
                ),
              ].map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: Palette.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              item.$3,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Builder(
                builder: (buttonContext) => SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const ValueKey('export-report'),
                    onPressed: snapshot.evidence.isEmpty
                        ? null
                        : () async {
                            final box =
                                buttonContext.findRenderObject()! as RenderBox;
                            try {
                              await share(
                                snapshot,
                                box.localToGlobal(Offset.zero) & box.size,
                              );
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not open the report share sheet. Try again.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Export JSON report'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Contains recognized text and review notes. Original images stay on device. A digest identifies an image; it does not prove authenticity.',
                style: TextStyle(fontSize: 12, color: Palette.muted),
              ),
            ],
          ),
        ),
        const SectionHeading('What this record means'),
        const SurfaceCard(
          color: Palette.mint,
          child: Text(
            'Actions and resolutions reflect human review. This notebook is not a compliance certificate, an engineering opinion or a safety assessment.',
          ),
        ),
        const SizedBox(height: 16),
        ExpansionTile(
          title: const Text('Preview report data'),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                encodeReport(snapshot, DateTime.now().toUtc()),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
