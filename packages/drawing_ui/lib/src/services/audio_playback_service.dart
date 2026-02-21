import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// State of audio playback.
enum AudioPlaybackState {
  idle,
  playing,
  paused,
}

/// Service for managing audio playback using the `just_audio` package.
class AudioPlaybackService {
  AudioPlaybackService();

  final AudioPlayer _player = AudioPlayer();

  final _stateController =
      StreamController<AudioPlaybackState>.broadcast();

  /// ID of the recording currently loaded/playing.
  String? _currentRecordingId;

  StreamSubscription<PlayerState>? _completionSub;

  /// Stream of playback state changes.
  Stream<AudioPlaybackState> get stateStream => _stateController.stream;

  /// Stream of current playback position (from AudioPlayer).
  Stream<Duration> get positionStream => _player.positionStream;

  /// Total duration of the loaded audio.
  Duration? get totalDuration => _player.duration;

  /// Currently loaded recording ID.
  String? get currentRecordingId => _currentRecordingId;

  /// Plays an audio file. Stops any currently playing audio first.
  Future<void> play(String recordingId, String filePath) async {
    try {
      // If same recording is paused, just resume
      if (_currentRecordingId == recordingId &&
          _player.processingState != ProcessingState.idle) {
        await _player.play();
        _stateController.add(AudioPlaybackState.playing);
        return;
      }

      // Stop current playback if different recording
      if (_currentRecordingId != null) {
        await _player.stop();
      }

      _currentRecordingId = recordingId;
      // Emit playing state immediately for instant UI update
      _stateController.add(AudioPlaybackState.playing);

      await _player.setFilePath(filePath);
      _completionSub?.cancel();
      _completionSub = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _currentRecordingId = null;
          _stateController.add(AudioPlaybackState.idle);
        }
      });
      await _player.play();
    } catch (e) {
      debugPrint('AudioPlaybackService: play failed: $e');
      _currentRecordingId = null;
      _stateController.add(AudioPlaybackState.idle);
    }
  }

  /// Pauses playback.
  Future<void> pause() async {
    await _player.pause();
    _stateController.add(AudioPlaybackState.paused);
  }

  /// Resumes playback.
  Future<void> resume() async {
    await _player.play();
    _stateController.add(AudioPlaybackState.playing);
  }

  /// Stops playback and resets.
  Future<void> stop() async {
    await _player.stop();
    _currentRecordingId = null;
    _stateController.add(AudioPlaybackState.idle);
  }

  /// Disposes all resources.
  void dispose() {
    _completionSub?.cancel();
    _player.dispose();
    _stateController.close();
  }
}
