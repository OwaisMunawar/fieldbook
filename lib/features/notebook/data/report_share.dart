import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/models.dart';
import '../domain/report.dart';

Future<void> shareNotebookReport(NotebookSnapshot snapshot, Rect origin) async {
  final directory = await getTemporaryDirectory();
  final file = File(p.join(directory.path, 'fieldbook-report.json'));
  await file.writeAsString(
    encodeReport(snapshot, DateTime.now().toUtc()),
    flush: true,
  );
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      subject: 'Fieldbook inspection record',
      sharePositionOrigin: origin,
    ),
  );
}
