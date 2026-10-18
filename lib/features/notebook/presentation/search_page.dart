import 'package:flutter/material.dart';

import '../../../core/design.dart';
import '../domain/models.dart';
import '../domain/search.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.evidence, required this.open});
  final List<Evidence> evidence;
  final void Function(Evidence) open;
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final results = searchEvidence(query, widget.evidence);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find the evidence.',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'Exact source snippets, ranked by word overlap. No generated answers or invented citations.',
        ),
        const SizedBox(height: 24),
        TextField(
          key: const ValueKey('evidence-search'),
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            labelText: 'Search recognized text',
            hintText: 'Try handrail, ceiling, label',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        SectionHeading(
          query.isEmpty
              ? 'Your source index'
              : '${results.length} matching ${results.length == 1 ? 'line' : 'lines'}',
        ),
        if (query.isEmpty)
          const EmptyCard(
            icon: Icons.manage_search,
            title: 'A direct line to the source',
            message:
                'Search the text saved with your evidence. Matching lines link back to their original image.',
          ),
        if (query.isNotEmpty && results.isEmpty)
          const EmptyCard(
            icon: Icons.search_off,
            title: 'No supporting source',
            message:
                'No recognized lines matched. Try a different word or add more evidence.',
          ),
        ...results.map(
          (match) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => widget.open(match.evidence),
              borderRadius: BorderRadius.circular(20),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tag(
                      '${match.evidence.title} / ${match.line.id}',
                      active: true,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '“${match.line.text}”',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.link, size: 16, color: Palette.accent),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Inspect original',
                            style: TextStyle(color: Palette.accent),
                          ),
                        ),
                        Text(
                          '${(match.line.confidence * 100).round()}% OCR',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
