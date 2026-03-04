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
/// Supports optional [maxDuration] to auto-stop recording at a time limit.
class AudioRecordingService {
  AudioRecordingService({
    this.maxDuration,
    this.onMaxDurationReached,
  });

  /// Optional maximum recording duration. When reached, recording auto-stops.
  /// The recording is always saved — only further recording is prevented.
  final Duration? maxDuration;

  /// Called when recording is auto-stopped due to [maxDuration].
  /// Receives the saved file path (null if save failed) and elapsed duration.
  final void Function(String? filePath, Duration elapsed)?
      onMaxDurationReached;

  final AudioRecorder _recorder = AudioRecorder();

  final _stateController =
      StreamController<AudioRecordingState>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isPaused = false;
  bool _autoStopped = false;

  /// Stream of recording state changes.
  Stream<AudioRecordingState> get stateStream => _stateController.stream;

  /// Stream of elapsed recording duration (ticks every second).
  Stream<Duration> get durationStream => _durationController.stream;

  /// Current elapsed duration.
  Duration get elapsed => _elapsed;

  /// Whether the last recording was auto-stopped due to max duration.
  bool get wasAutoStopped => _autoStopped;

  /// Remaining duration before hitting the limit, or `null` if unlimited.
  Duration? get remaining {
    if (maxDuration == null) return null;
    final diff = maxDuration! - _elapsed;
    return diff.isNegative ? Duration.zero : diff;
  }

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
      _autoStopped = false;
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

        // Auto-stop when max duration is reached.
        if (maxDuration != null && _elapsed >= maxDuration!) {
          _autoStopped = true;
          final duration = _elapsed;
          stopRecording().then((filePath) {
            onMaxDurationReached?.call(filePath, duration);
          });
        }
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
