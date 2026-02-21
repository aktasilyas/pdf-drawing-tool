import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_playback_service.dart';
import '../services/audio_recording_service.dart';
import 'document_provider.dart';

// =============================================================================
// DOCUMENT-LEVEL RECORDING PROVIDERS (existing)
// =============================================================================

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

// =============================================================================
// SERVICE SINGLETONS
// =============================================================================

/// Audio recording service singleton with auto-cleanup.
final audioRecordingServiceProvider =
    Provider.autoDispose<AudioRecordingService>((ref) {
  final service = AudioRecordingService();
  ref.onDispose(service.dispose);
  return service;
});

/// Audio playback service singleton with auto-cleanup.
final audioPlaybackServiceProvider =
    Provider.autoDispose<AudioPlaybackService>((ref) {
  final service = AudioPlaybackService();
  ref.onDispose(service.dispose);
  return service;
});

// =============================================================================
// RECORDING STREAM PROVIDERS
// =============================================================================

/// Current audio recording state.
final audioRecordingStateProvider =
    StreamProvider.autoDispose<AudioRecordingState>((ref) {
  final service = ref.watch(audioRecordingServiceProvider);
  return service.stateStream;
});

/// Elapsed recording duration (ticks every second).
final recordingDurationProvider =
    StreamProvider.autoDispose<Duration>((ref) {
  final service = ref.watch(audioRecordingServiceProvider);
  return service.durationStream;
});

// =============================================================================
// PLAYBACK STREAM PROVIDERS
// =============================================================================

/// Current audio playback state.
final audioPlaybackStateProvider =
    StreamProvider.autoDispose<AudioPlaybackState>((ref) {
  final service = ref.watch(audioPlaybackServiceProvider);
  return service.stateStream;
});

/// Current playback position.
final audioPlaybackPositionProvider =
    StreamProvider.autoDispose<Duration>((ref) {
  final service = ref.watch(audioPlaybackServiceProvider);
  return service.positionStream;
});

/// ID of the recording currently being played.
///
/// Re-evaluates whenever playback state changes and reads the
/// service's [currentRecordingId] synchronously.
final playingRecordingIdProvider = Provider.autoDispose<String?>((ref) {
  ref.watch(audioPlaybackStateProvider);
  return ref.read(audioPlaybackServiceProvider).currentRecordingId;
});

// =============================================================================
// CONVENIENCE PROVIDERS
// =============================================================================

/// Whether an audio recording is currently active (recording or paused).
final isRecordingProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(audioRecordingStateProvider);
  return state.whenOrNull(
        data: (s) =>
            s == AudioRecordingState.recording ||
            s == AudioRecordingState.paused,
      ) ??
      false;
});
