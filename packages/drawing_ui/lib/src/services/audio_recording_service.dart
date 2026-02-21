import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// State of the audio recording process.
enum AudioRecordingState {
  idle,
  recording,
  paused,
  saving,
  error,
}

/// Service for managing audio recording using the `record` package.
///
/// Follows the PDFImportService pattern with StreamController + state enum.
class AudioRecordingService {
  AudioRecordingService();

  final AudioRecorder _recorder = AudioRecorder();

  final _stateController =
      StreamController<AudioRecordingState>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isPaused = false;

  /// Stream of recording state changes.
  Stream<AudioRecordingState> get stateStream => _stateController.stream;

  /// Stream of elapsed recording duration (ticks every second).
  Stream<Duration> get durationStream => _durationController.stream;

  /// Current elapsed duration.
  Duration get elapsed => _elapsed;

  /// Whether the recorder has microphone permission.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts a new audio recording.
  ///
  /// Returns `false` if permission is denied or recording fails to start.
  Future<bool> startRecording() async {
    try {
      final hasPerms = await _recorder.hasPermission();
      if (!hasPerms) {
        _stateController.add(AudioRecordingState.error);
        return false;
      }

      final dir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${dir.path}/recordings');
      if (!recordingsDir.existsSync()) {
        recordingsDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${recordingsDir.path}/rec_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      _elapsed = Duration.zero;
      _isPaused = false;
      _durationController.add(_elapsed);
      _startTimer();
      _stateController.add(AudioRecordingState.recording);
      return true;
    } catch (e) {
      debugPrint('AudioRecordingService: start failed: $e');
      _stateController.add(AudioRecordingState.error);
      return false;
    }
  }

  /// Pauses the current recording.
  Future<void> pauseRecording() async {
    try {
      await _recorder.pause();
      _isPaused = true;
      _stopTimer();
      _stateController.add(AudioRecordingState.paused);
    } catch (e) {
      debugPrint('AudioRecordingService: pause failed: $e');
    }
  }

  /// Resumes a paused recording.
  Future<void> resumeRecording() async {
    try {
      await _recorder.resume();
      _isPaused = false;
      _startTimer();
      _stateController.add(AudioRecordingState.recording);
    } catch (e) {
      debugPrint('AudioRecordingService: resume failed: $e');
    }
  }

  /// Stops the recording and returns the file path, or `null` on failure.
  Future<String?> stopRecording() async {
    try {
      _stateController.add(AudioRecordingState.saving);
      _stopTimer();
      final path = await _recorder.stop();
      _stateController.add(AudioRecordingState.idle);
      return path;
    } catch (e) {
      debugPrint('AudioRecordingService: stop failed: $e');
      _stateController.add(AudioRecordingState.error);
      return null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        _elapsed += const Duration(seconds: 1);
        _durationController.add(_elapsed);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Disposes all resources.
  void dispose() {
    _stopTimer();
    _recorder.dispose();
    _stateController.close();
    _durationController.close();
  }
}
