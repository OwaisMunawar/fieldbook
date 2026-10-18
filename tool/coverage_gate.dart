import 'dart:io';

void main(List<String> args) {
  final file = File(args.isEmpty ? 'coverage/lcov.info' : args.first);
  if (!file.existsSync()) {
    stderr.writeln('Coverage data is missing.');
    exitCode = 1;
    return;
  }
  var selected = false;
  var total = 0;
  var hit = 0;
  final byFile = <String, List<int>>{};
  String current = '';
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3);
      selected =
          current.contains('/domain/') || current.contains('/application/');
    } else if (selected && line.startsWith('DA:')) {
      final values = line.substring(3).split(',');
      final count = int.parse(values[1]);
      final counts = byFile.putIfAbsent(current, () => [0, 0]);
      total++;
      counts[1]++;
      if (count > 0) {
        hit++;
        counts[0]++;
      }
    }
  }
  if (total == 0) {
    stderr.writeln('No domain or application coverage found.');
    exitCode = 1;
    return;
  }
  for (final entry in byFile.entries) {
    if (100 * entry.value[0] / entry.value[1] < 90) exitCode = 1;
    stdout.writeln(
      '${entry.key}: ${(100 * entry.value[0] / entry.value[1]).toStringAsFixed(1)}%',
    );
  }
  final percentage = 100 * hit / total;
  stdout.writeln(
    'Domain + application: $hit/$total lines (${percentage.toStringAsFixed(1)}%). Minimum 90%.',
  );
  if (percentage < 90) exitCode = 1;
}
