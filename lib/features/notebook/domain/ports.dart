import 'models.dart';

abstract interface class NotebookRepository {
  Future<NotebookSnapshot> read();
  Future<Evidence> addEvidence(Evidence evidence);
  Future<void> accept(Issue issue);
  Future<void> changeStatus(
    Issue current,
    IssueStatus next,
    String note,
    DateTime at,
  );
  Future<void> close();
}

abstract interface class TextRecognizer {
  Future<List<EvidenceLine>> recognize(String imagePath);
}

abstract interface class ActionGenerator {
  Future<ActionDraft> generate(Evidence evidence);
}

abstract interface class CaptureSource {
  Future<String?> chooseImage({required bool camera});
  Future<String> sampleImage();
  Future<String> digest(String path);
  Future<void> discard(String path);
  Future<String> persist(String path, String id);
}
