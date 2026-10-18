import 'dart:io';

void main() {
  final violations = <String>[];
  for (final entity
      in Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))) {
    final path = entity.path;
    final source = entity.readAsStringSync();
    for (final match in RegExp(
      r"(?:import|export)\s+'([^']+)'",
    ).allMatches(source)) {
      final dependency = match.group(1)!;
      final pureDart = {
        'dart:async',
        'dart:collection',
        'dart:convert',
        'dart:math',
      };
      final forbidden = path.contains('/domain/')
          ? (!pureDart.contains(dependency) &&
                (dependency.startsWith('dart:') ||
                    dependency.startsWith('package:') ||
                    !entity.uri.resolve(dependency).path.contains('/domain/')))
          : path.contains('/application/')
          ? dependency.contains('/data/') ||
                dependency.contains('/presentation/')
          : path.contains('/presentation/')
          ? dependency.contains('/data/')
          : dependency.contains('/presentation/');
      if (forbidden) violations.add('$path imports $dependency');
    }
  }
  if (violations.isNotEmpty) {
    stderr.writeln(violations.join('\n'));
    exitCode = 1;
    return;
  }
  stdout.writeln('Architecture boundaries passed.');
}
