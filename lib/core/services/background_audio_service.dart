import 'dart:async';

import 'package:audio_service/audio_service.dart' hide MediaItem, PlaybackState;
import 'package:just_audio/just_audio.dart';

import '../../features/media_player/domain/entities/media_item.dart' as domain;
import '../../features/media_player/domain/entities/player_state.dart';

class BackgroundAudioHandler extends BaseAudioHandler with SeekHandler {
  AudioPlayer? _audioPlayer;
  final StreamController<PlaybackState> _playbackStateController =
  StreamController<PlaybackState>.broadcast();

  PlaybackState _currentState = const PlaybackState();
  bool _isDisposed = false;

  // Stream subscriptions
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  Stream<PlaybackState> get playbackStateStream =>
      _playbackStateController.stream;

  PlaybackState get currentState => _currentState;

  BackgroundAudioHandler();

  void _setupAudioPlayer() {
    if (_audioPlayer == null) return;

    // Cancel existing subscriptions
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();

    // Listen to player state changes
    _playerStateSubscription = _audioPlayer!.playerStateStream.listen((playerState) {
      if (!_isDisposed) {
        _updatePlaybackState(playerState);
      }
    });

    // Listen to position changes
    _positionSubscription = _audioPlayer!.positionStream.listen((position) {
      if (!_isDisposed) {
        _updateState(_currentState.copyWith(position: position));
      }
    });

    // Listen to duration changes
    _durationSubscription = _audioPlayer!.durationStream.listen((duration) {
      if (!_isDisposed && duration != null) {
        _updateState(_currentState.copyWith(duration: duration));
      }
    });
  }

  void _updatePlaybackState(PlayerState playerState) {
    PlaybackStatus status;
    bool isPlaying = false;

    switch (playerState.processingState) {
      case ProcessingState.loading:
      case ProcessingState.buffering:
        status = PlaybackStatus.loading;
        break;
      case ProcessingState.ready:
        isPlaying = playerState.playing;
        status = playerState.playing
            ? PlaybackStatus.playing
            : PlaybackStatus.paused;
        break;
      case ProcessingState.completed:
        status = PlaybackStatus.stopped;
        break;
      default:
        status = PlaybackStatus.idle;
    }

    // Update both internal state and audio_service state
    _updateState(
      _currentState.copyWith(
        status: status,
        isBuffering: playerState.processingState == ProcessingState.buffering,
      ),
    );

    // Update audio_service playback state
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.rewind,
          isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.fastForward,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [1, 2, 3],
        processingState: _mapToAudioServiceState(playerState.processingState),
        playing: isPlaying,
        updatePosition: _audioPlayer?.position ?? Duration.zero,
        bufferedPosition: _audioPlayer?.bufferedPosition ?? Duration.zero,
        speed: _audioPlayer?.speed ?? 1.0,
        queueIndex: 0,
      ),
    );
  }

  AudioProcessingState _mapToAudioServiceState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  void _updateState(PlaybackState newState) {
    if (_isDisposed) return;
    _currentState = newState;
    _playbackStateController.add(newState);
  }

  Future<void> _recreateAudioPlayer() async {
    // Dispose existing player and subscriptions
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();

    if (_audioPlayer != null) {
      await _audioPlayer!.dispose();
    }

    // Create new player
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  Future<void> initializeMedia(domain.MediaItem mediaItem) async {
    if (_isDisposed) return;

    try {
      _updateState(_currentState.copyWith(status: PlaybackStatus.loading));

      // **TEMEL ÇÖZÜM:** Her yeni medya için AudioPlayer'ı yeniden oluştur
      await _recreateAudioPlayer();

      // Set audio source
      if (mediaItem.source == domain.MediaSource.network &&
          mediaItem.audioUrl != null) {
        await _audioPlayer!.setUrl(
          mediaItem.audioUrl!,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
            'Accept': '*/*',
            'Accept-Encoding': 'identity',
            'Connection': 'keep-alive',
          },
        );
      } else if (mediaItem.source == domain.MediaSource.local &&
          mediaItem.localAudioPath != null) {
        await _audioPlayer!.setFilePath(mediaItem.localAudioPath!);
      } else {
        throw Exception('Invalid audio source for background playback');
      }

      _updateState(
        _currentState.copyWith(
          status: PlaybackStatus.paused,
          duration: _audioPlayer!.duration ?? Duration.zero,
          position: Duration.zero,
          error: null,
        ),
      );
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

  @override
  Future<void> play() async {
    if (_isDisposed || _audioPlayer == null) return;
    await _audioPlayer!.play();
  }

  @override
  Future<void> pause() async {
    if (_isDisposed || _audioPlayer == null) return;
    await _audioPlayer!.pause();
  }

  @override
  Future<void> stop() async {
    if (_isDisposed || _audioPlayer == null) return;
    await _audioPlayer!.stop();
    _updateState(
      _currentState.copyWith(
        status: PlaybackStatus.stopped,
        position: Duration.zero,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isDisposed || _audioPlayer == null) return;
    await _audioPlayer!.seek(position);
    _updateState(_currentState.copyWith(position: position));
  }

  @override
  Future<void> rewind() async {
    if (_audioPlayer == null) return;
    final currentPosition = _audioPlayer!.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    await seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  @override
  Future<void> fastForward() async {
    if (_audioPlayer == null) return;
    final currentPosition = _audioPlayer!.position;
    final duration = _audioPlayer!.duration ?? Duration.zero;
    final newPosition = currentPosition + const Duration(seconds: 10);
    await seek(newPosition > duration ? duration : newPosition);
  }

  @override
  Future<void> skipToPrevious() async {
    customEvent.add('skipToPrevious');
  }

  @override
  Future<void> skipToNext() async {
    customEvent.add('skipToNext');
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_isDisposed || _audioPlayer == null) return;
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _audioPlayer!.setVolume(clampedVolume);
    _updateState(_currentState.copyWith(volume: clampedVolume));
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (_isDisposed || _audioPlayer == null) return;
    final clampedSpeed = speed.clamp(0.25, 3.0);
    await _audioPlayer!.setSpeed(clampedSpeed);
    _updateState(_currentState.copyWith(playbackSpeed: clampedSpeed));
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    // Cancel subscriptions
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();

    // Dispose player and controller
    await _audioPlayer?.dispose();
    await _playbackStateController.close();
  }
}
