import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'document_provider.dart';

/// All audio recordings in the current document.
final audioRecordingsProvider = Provider<List<AudioRecording>>((ref) {
  return ref.watch(documentProvider).audioRecordings;
});

/// Count of audio recordings in the current document.
final audioRecordingCountProvider = Provider<int>((ref) {
  return ref.watch(audioRecordingsProvider).length;
});

/// Adds a new audio recording to the document.
void addRecording(DocumentNotifier notifier, AudioRecording recording) {
  notifier.updateDocument(
    notifier.currentDocument.addAudioRecording(recording),
  );
}

/// Removes an audio recording from the document by ID.
void removeRecording(DocumentNotifier notifier, String recordingId) {
  notifier.updateDocument(
    notifier.currentDocument.removeAudioRecording(recordingId),
  );
}

/// Renames an audio recording.
void renameRecording(
  DocumentNotifier notifier,
  String recordingId,
  String newTitle,
) {
  final doc = notifier.currentDocument;
  final recording = doc.audioRecordings.firstWhere(
    (r) => r.id == recordingId,
  );
  notifier.updateDocument(
    doc.updateAudioRecording(
      recordingId,
      recording.copyWith(title: newTitle),
    ),
  );
}
