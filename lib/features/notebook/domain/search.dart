import 'dart:math' as math;

import 'models.dart';

Set<String> terms(String text) => RegExp(r'[a-z0-9]{2,}')
    .allMatches(text.toLowerCase())
    .map((m) => m.group(0)!)
    .where(
      (term) => !{
        'the',
        'and',
        'for',
        'with',
        'from',
        'this',
        'that',
        'what',
        'where',
        'was',
        'are',
        'at',
        'to',
        'of',
        'is',
        'in',
        'on',
      }.contains(term),
    )
    .toSet();

class EvidenceMatch {
  const EvidenceMatch(this.evidence, this.line, this.score);
  final Evidence evidence;
  final EvidenceLine line;
  final double score;
}

List<EvidenceMatch> searchEvidence(
  String query,
  List<Evidence> documents, {
  int limit = 8,
}) {
  final needles = terms(query);
  if (needles.isEmpty || limit <= 0) return [];
  final matches = <EvidenceMatch>[];
  for (final document in documents) {
    for (final line in document.lines) {
      final words = terms(line.text);
      final overlap = needles.intersection(words).length;
      if (overlap == 0) continue;
      // Short, direct evidence wins over long lines with an incidental match.
      final score =
          overlap / needles.length + overlap / math.max(words.length, 1) * 0.25;
      matches.add(EvidenceMatch(document, line, score));
    }
  }
  matches.sort((a, b) {
    final rank = b.score.compareTo(a.score);
    if (rank != 0) return rank;
    final source = a.evidence.id.compareTo(b.evidence.id);
    return source != 0 ? source : a.line.id.compareTo(b.line.id);
  });
  return matches.take(limit).toList(growable: false);
}
