import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/models.dart';
import '../domain/ports.dart';

class LocalCapture implements CaptureSource {
  LocalCapture(this.picker);
  final ImagePicker picker;
  @override
  Future<String?> chooseImage({required bool camera}) async {
    try {
      return (await picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 90,
      ))?.path;
    } on PlatformException {
      throw const NotebookFailure(
        FailureCode.unavailable,
        'Photo access is unavailable. Check permission or try the sample card.',
      );
    }
  }

  @override
  Future<String> sampleImage() async {
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, 'fieldbook-inspection-card.png'));
    final data = await rootBundle.load('assets/inspection-card.png');
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return file.path;
  }

  @override
  Future<String> digest(String path) async =>
      (await sha256.bind(File(path).openRead()).first).toString();
  @override
  Future<void> discard(String path) async {
    final directory = p.join(
      (await getApplicationSupportDirectory()).path,
      'evidence',
    );
    if (p.isWithin(directory, path) && await File(path).exists()) {
      await File(path).delete();
    }
  }

  @override
  Future<String> persist(String path, String id) async {
    final source = File(path);
    if (await source.length() > 20 * 1024 * 1024) {
      throw const NotebookFailure(
        FailureCode.invalidInput,
        'Choose an image smaller than 20 MB.',
      );
    }
    final directory = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'evidence'),
    );
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, '$id${p.extension(path)}'));
    await source.copy(file.path);
    return file.path;
  }
}
