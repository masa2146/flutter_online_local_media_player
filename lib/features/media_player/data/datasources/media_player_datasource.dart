import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/player_state.dart';

abstract class MediaPlayerDataSource {
  Future<void> initialize(MediaItem mediaItem);

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  Future<void> seekTo(Duration position);

  Future<void> setVolume(double volume);

  Future<void> setSpeed(double speed);

  Stream<PlaybackState> get stateStream;

  Future<void> dispose();
}

class AudioPlayerDataSource implements MediaPlayerDataSource {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StreamController<PlaybackState> _stateController =
  StreamController<PlaybackState>.broadcast();

  PlaybackState _currentState = const PlaybackState();
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  bool _isDisposed = false;

  @override
  Stream<PlaybackState> get stateStream => _stateController.stream;

  @override
  Future<void> initialize(MediaItem mediaItem) async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');

    try {
      _updateState(_currentState.copyWith(status: PlaybackStatus.loading));

      if (mediaItem.source == MediaSource.network &&
          mediaItem.audioUrl != null) {
        await _audioPlayer.setUrl(mediaItem.audioUrl!);
      } else if (mediaItem.source == MediaSource.local &&
          mediaItem.localAudioPath != null) {
        await _audioPlayer.setFilePath(mediaItem.localAudioPath!);
      } else {
        throw PlayerFailure('Invalid media source');
      }

      _setupListeners();

      _updateState(
        _currentState.copyWith(
          status: PlaybackStatus.paused,
          duration: _audioPlayer.duration ?? Duration.zero,
          position: Duration.zero,
          error: null,
        ),
      );

      debugPrint('AudioPlayerDataSource: Initialized successfully');
    } catch (e) {
      _updateState(
        _currentState.copyWith(
          status: PlaybackStatus.error,
          error: 'Failed to initialize audio: $e',
        ),
      );
      rethrow;
    }
  }

  void _setupListeners() {
    _positionSubscription = _audioPlayer.positionStream
        .where((_) => !_isDisposed)
        .listen(
          (position) {
        if (!_isDisposed) {
          _updateState(_currentState.copyWith(position: position));
        }
      },
      onError: (error) {
        debugPrint('Position stream error: $error');
        if (!_isDisposed) {
          _updateState(
            _currentState.copyWith(
              status: PlaybackStatus.error,
              error: 'Position stream error: $error',
            ),
          );
        }
      },
    );

    _playerStateSubscription = _audioPlayer.playerStateStream
        .where((_) => !_isDisposed)
        .listen(
          (state) {
        if (!_isDisposed) {
          PlaybackStatus status;
          switch (state.processingState) {
            case ProcessingState.loading:
            case ProcessingState.buffering:
              status = PlaybackStatus.loading;
              break;
            case ProcessingState.ready:
              status = state.playing
                  ? PlaybackStatus.playing
                  : PlaybackStatus.paused;
              break;
            case ProcessingState.completed:
              status = PlaybackStatus.stopped;
              break;
            default:
              status = PlaybackStatus.idle;
          }

          debugPrint('Audio state update: ${state.processingState} - playing: ${state.playing} -> status: $status');

          _updateState(
            _currentState.copyWith(
              status: status,
              isBuffering: state.processingState == ProcessingState.buffering,
            ),
          );
        }
      },
      onError: (error) {
        debugPrint('Player state error: $error');
        if (!_isDisposed) {
          _updateState(
            _currentState.copyWith(
              status: PlaybackStatus.error,
              error: 'Player state error: $error',
            ),
          );
        }
      },
    );
  }

  void _updateState(PlaybackState newState) {
    if (_isDisposed || _stateController.isClosed) return;

    final oldState = _currentState;
    _currentState = newState;

    // Debug log for important changes
    if (oldState.status != newState.status) {
      debugPrint('AudioPlayer state change: ${oldState.status} -> ${newState.status}');
    }

    _stateController.add(newState);
  }

  @override
  Future<void> play() async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');

    debugPrint('AudioPlayer: Play command received');
    await _audioPlayer.play();

    _updateState(_currentState.copyWith(status: PlaybackStatus.playing));
    debugPrint('AudioPlayer: Play started');
  }

  @override
  Future<void> pause() async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');

    debugPrint('AudioPlayer: Pause command received');
    await _audioPlayer.pause();

    _updateState(_currentState.copyWith(status: PlaybackStatus.paused));
    debugPrint('AudioPlayer: Paused');
  }

  @override
  Future<void> stop() async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');
    await _audioPlayer.stop();

    _updateState(_currentState.copyWith(
      status: PlaybackStatus.stopped,
      position: Duration.zero,
    ));
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');

    await _audioPlayer.seek(position);
    _updateState(_currentState.copyWith(position: position));
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');

    final clampedVolume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(clampedVolume);
    _updateState(_currentState.copyWith(volume: clampedVolume));
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');

    final clampedSpeed = speed.clamp(0.25, 3.0);
    await _audioPlayer.setSpeed(clampedSpeed);
    _updateState(_currentState.copyWith(playbackSpeed: clampedSpeed));
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    debugPrint('AudioPlayerDataSource: Disposing...');

    await _positionSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _audioPlayer.dispose();
    await _stateController.close();

    debugPrint('AudioPlayerDataSource: Disposed successfully');
  }
}
