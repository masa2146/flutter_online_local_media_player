import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/player_state.dart';
import '../../../../core/errors/failures.dart';
import 'media_player_datasource.dart';

class VideoPlayerDataSource implements MediaPlayerDataSource {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;

  final StreamController<PlaybackState> _stateController =
  StreamController<PlaybackState>.broadcast();

  PlaybackState _currentState = const PlaybackState();

  // Synchronization
  Timer? _positionTimer;
  Timer? _syncTimer;
  bool _isSyncedPlayback = false;
  bool _isDisposed = false;
  bool _isSeeking = false;

  // Subscriptions
  StreamSubscription? _videoPositionSubscription;
  StreamSubscription? _audioPositionSubscription;
  StreamSubscription? _audioStateSubscription;

  @override
  Stream<PlaybackState> get stateStream => _stateController.stream;

  @override
  Future<void> initialize(MediaItem mediaItem) async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');

    try {
      _updateState(_currentState.copyWith(status: PlaybackStatus.loading));

      await _initializeControllers(mediaItem);
      _setupListeners(mediaItem);

      final duration = _getDuration();
      _updateState(_currentState.copyWith(
        status: PlaybackStatus.paused,
        duration: duration,
        position: Duration.zero,
        error: null,
      ));

      debugPrint('VideoPlayerDataSource: Initialized successfully');

    } catch (e) {
      _updateState(_currentState.copyWith(
        status: PlaybackStatus.error,
        error: 'Failed to initialize: $e',
      ));
      rethrow;
    }
  }

  Future<void> _initializeControllers(MediaItem mediaItem) async {
    switch (mediaItem.type) {
      case MediaType.video:
        await _initializeVideoOnly(mediaItem);
        break;
      case MediaType.videoWithSeparateAudio:
        await _initializeSeparateStreams(mediaItem);
        break;
      case MediaType.audio:
        await _initializeAudioOnly(mediaItem);
        break;
    }
  }

  Future<void> _initializeVideoOnly(MediaItem mediaItem) async {
    final videoUrl = mediaItem.playableVideoUrl;
    if (videoUrl == null) throw PlayerFailure('No video URL provided');

    if (mediaItem.source == MediaSource.local) {
      _videoController = VideoPlayerController.file(
        File(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
    } else {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
    }

    await _videoController!.initialize();
    debugPrint('Video controller initialized');
  }

  Future<void> _initializeAudioOnly(MediaItem mediaItem) async {
    final audioUrl = mediaItem.playableAudioUrl;
    if (audioUrl == null) throw PlayerFailure('No audio URL provided');

    _audioPlayer = AudioPlayer();

    if (mediaItem.source == MediaSource.local) {
      await _audioPlayer!.setFilePath(audioUrl);
    } else {
      await _audioPlayer!.setUrl(audioUrl);
    }

    debugPrint('Audio player initialized');
  }

  Future<void> _initializeSeparateStreams(MediaItem mediaItem) async {
    final videoUrl = mediaItem.playableVideoUrl;
    final audioUrl = mediaItem.playableAudioUrl;

    if (videoUrl == null || audioUrl == null) {
      throw PlayerFailure('Both video and audio URLs required for separate streams');
    }

    // Initialize video controller
    if (mediaItem.source == MediaSource.local) {
      _videoController = VideoPlayerController.file(
        File(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true), // Allow audio mixing
      );
    } else {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    }

    // Initialize audio player
    _audioPlayer = AudioPlayer();

    // Initialize both
    await Future.wait([
      _videoController!.initialize(),
      mediaItem.source == MediaSource.local
          ? _audioPlayer!.setFilePath(audioUrl)
          : _audioPlayer!.setUrl(audioUrl),
    ]);

    // Mute video since we have separate audio
    await _videoController!.setVolume(0.0);

    _isSyncedPlayback = true;
    debugPrint('Separate streams initialized - Video: $videoUrl, Audio: $audioUrl');
  }

  void _setupListeners(MediaItem mediaItem) {
    if (_videoController != null) {
      // Video controller listener
      _videoController!.addListener(_onVideoControllerUpdate);
    }

    if (_audioPlayer != null) {
      // Audio state listener - FİX: Daha detaylı state handling
      _audioStateSubscription = _audioPlayer!.playerStateStream.listen(
            (state) {
          if (!_isDisposed) {
            _onAudioStateUpdate(state);
          }
        },
        onError: (error) => debugPrint('Audio state error: $error'),
      );

      // Audio position listener - throttled
      _audioPositionSubscription = _audioPlayer!.positionStream
          .where((_) => !_isDisposed && !_isSeeking)
          .listen(
            (position) {
          if (!_isDisposed) {
            _onAudioPositionUpdate(position);
          }
        },
        onError: (error) => debugPrint('Audio position error: $error'),
      );
    }

    // Start position tracking
    _startPositionTimer();

    // Start sync timer for separate streams
    if (_isSyncedPlayback) {
      _startSyncTimer();
    }
  }

  void _onVideoControllerUpdate() {
    if (_isDisposed || _videoController == null) return;

    final value = _videoController!.value;

    // FİX: Video durumu değişikliklerini yakalayalım
    PlaybackStatus newStatus = _currentState.status;

    if (value.isPlaying != _currentState.isPlaying) {
      newStatus = value.isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused;
      debugPrint('Video playback state changed: ${value.isPlaying ? "playing" : "paused"}');
    }

    // Update buffering state
    bool newBuffering = value.isBuffering;
    if (newBuffering != _currentState.isBuffering) {
      debugPrint('Video buffering state changed: $newBuffering');
    }

    // Update position for video-only playback
    Duration newPosition = _currentState.position;
    if (!_isSyncedPlayback && !_isSeeking) {
      newPosition = value.position;
    }

    // Handle video errors
    String? newError = _currentState.error;
    if (value.hasError) {
      newError = 'Video error: ${value.errorDescription}';
      newStatus = PlaybackStatus.error;
    }

    // Update state if anything changed
    if (newStatus != _currentState.status ||
        newBuffering != _currentState.isBuffering ||
        newPosition != _currentState.position ||
        newError != _currentState.error) {

      _updateState(_currentState.copyWith(
        status: newStatus,
        isBuffering: newBuffering,
        position: newPosition,
        error: newError,
      ));
    }
  }

  void _onAudioStateUpdate(PlayerState state) {
    if (_isDisposed) return;

    // FİX: Audio durumu güncellemelerini düzeltelim
    PlaybackStatus status;
    bool isPlaying = false;

    switch (state.processingState) {
      case ProcessingState.loading:
      case ProcessingState.buffering:
        status = PlaybackStatus.loading;
        break;
      case ProcessingState.ready:
        isPlaying = state.playing;
        status = state.playing ? PlaybackStatus.playing : PlaybackStatus.paused;
        break;
      case ProcessingState.completed:
        status = PlaybackStatus.stopped;
        break;
      default:
        status = PlaybackStatus.idle;
    }

    debugPrint('Audio state update: ${state.processingState} - playing: ${state.playing} -> status: $status');

    _updateState(_currentState.copyWith(
      status: status,
      isBuffering: state.processingState == ProcessingState.buffering,
    ));
  }

  void _onAudioPositionUpdate(Duration position) {
    if (_isDisposed || _isSeeking) return;

    _updateState(_currentState.copyWith(position: position));
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (_currentState.status == PlaybackStatus.playing && !_isSeeking) {
        final position = _getCurrentPosition();
        if (position != _currentState.position) {
          _updateState(_currentState.copyWith(position: position));
        }
      }
    });
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isDisposed || !_isSyncedPlayback) {
        timer.cancel();
        return;
      }

      if (_currentState.status == PlaybackStatus.playing) {
        _checkAndFixSync();
      }
    });
  }

  void _checkAndFixSync() async {
    if (_videoController == null || _audioPlayer == null || _isSeeking) return;

    final videoPosition = _videoController!.value.position;
    final audioPosition = _audioPlayer!.position;

    final difference = (videoPosition - audioPosition).abs();

    // If difference is more than 100ms, resync
    if (difference > const Duration(milliseconds: 100)) {
      debugPrint('Sync drift detected: ${difference.inMilliseconds}ms - resyncing...');

      _isSeeking = true;

      try {
        // Sync audio to video position
        await _audioPlayer!.seek(videoPosition);

        // Small delay to ensure seek completion
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        debugPrint('Sync error: $e');
      } finally {
        _isSeeking = false;
      }
    }
  }

  Duration _getCurrentPosition() {
    if (_audioPlayer != null) {
      return _audioPlayer!.position;
    } else if (_videoController != null) {
      return _videoController!.value.position;
    }
    return Duration.zero;
  }

  Duration _getDuration() {
    if (_audioPlayer != null) {
      return _audioPlayer!.duration ?? Duration.zero;
    } else if (_videoController != null) {
      return _videoController!.value.duration;
    }
    return Duration.zero;
  }

  @override
  Future<void> play() async {
    if (_isDisposed) throw PlayerFailure('Player disposed');

    try {
      debugPrint('Play command received');

      if (_isSyncedPlayback) {
        await _playSynced();
      } else if (_videoController != null) {
        await _videoController!.play();
        debugPrint('Video play started');
      } else if (_audioPlayer != null) {
        await _audioPlayer!.play();
        debugPrint('Audio play started');
      }

      // FİX: Hemen playing state'ini güncelleyelim
      _updateState(_currentState.copyWith(status: PlaybackStatus.playing));

    } catch (e) {
      debugPrint('Play error: $e');
      throw PlayerFailure('Failed to play: $e');
    }
  }

  Future<void> _playSynced() async {
    if (_videoController == null || _audioPlayer == null) return;

    try {
      // Get current video position for initial sync
      final videoPosition = _videoController!.value.position;

      // Seek audio to video position
      await _audioPlayer!.seek(videoPosition);

      // Start both simultaneously
      await Future.wait([
        _videoController!.play(),
        _audioPlayer!.play(),
      ]);

      debugPrint('Synced playback started at position: ${videoPosition.inMilliseconds}ms');

    } catch (e) {
      debugPrint('Synced play error: $e');
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    if (_isDisposed) throw PlayerFailure('Player disposed');

    try {
      debugPrint('Pause command received');

      await Future.wait([
        if (_videoController != null) _videoController!.pause(),
        if (_audioPlayer != null) _audioPlayer!.pause(),
      ]);

      // FİX: Hemen paused state'ini güncelleyelim
      _updateState(_currentState.copyWith(status: PlaybackStatus.paused));
      debugPrint('Paused successfully');

    } catch (e) {
      debugPrint('Pause error: $e');
      throw PlayerFailure('Failed to pause: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (_isDisposed) throw PlayerFailure('Player disposed');

    try {
      await Future.wait([
        if (_videoController != null) _videoController!.pause(),
        if (_audioPlayer != null) _audioPlayer!.stop(),
      ]);

      _updateState(_currentState.copyWith(
        status: PlaybackStatus.stopped,
        position: Duration.zero,
      ));
    } catch (e) {
      throw PlayerFailure('Failed to stop: $e');
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (_isDisposed) throw PlayerFailure('Player disposed');

    _isSeeking = true;

    try {
      final clampedPosition = _clampPosition(position);
      debugPrint('Seeking to: ${clampedPosition.inMilliseconds}ms');

      if (_isSyncedPlayback) {
        await _seekSynced(clampedPosition);
      } else {
        await Future.wait([
          if (_videoController != null) _videoController!.seekTo(clampedPosition),
          if (_audioPlayer != null) _audioPlayer!.seek(clampedPosition),
        ]);
      }

      _updateState(_currentState.copyWith(position: clampedPosition));

    } catch (e) {
      throw PlayerFailure('Failed to seek: $e');
    } finally {
      // Delay to ensure seek completion before resuming sync
      await Future.delayed(const Duration(milliseconds: 100));
      _isSeeking = false;
    }
  }

  Future<void> _seekSynced(Duration position) async {
    if (_videoController == null || _audioPlayer == null) return;

    try {
      // Seek both to the same position
      await Future.wait([
        _videoController!.seekTo(position),
        _audioPlayer!.seek(position),
      ]);

      debugPrint('Synced seek to: ${position.inMilliseconds}ms');

    } catch (e) {
      debugPrint('Synced seek error: $e');
      rethrow;
    }
  }

  Duration _clampPosition(Duration position) {
    final duration = _getDuration();
    if (duration == Duration.zero) return Duration.zero;

    return Duration(
      milliseconds: position.inMilliseconds.clamp(0, duration.inMilliseconds),
    );
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_isDisposed) throw PlayerFailure('Player disposed');

    final clampedVolume = volume.clamp(0.0, 1.0);

    try {
      if (_audioPlayer != null) {
        // Audio player handles volume
        await _audioPlayer!.setVolume(clampedVolume);
      } else if (_videoController != null) {
        // Video-only playback
        await _videoController!.setVolume(clampedVolume);
      }

      _updateState(_currentState.copyWith(volume: clampedVolume));
    } catch (e) {
      throw PlayerFailure('Failed to set volume: $e');
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (_isDisposed) throw PlayerFailure('Player disposed');

    final clampedSpeed = speed.clamp(0.25, 3.0);

    try {
      await Future.wait([
        if (_videoController != null) _videoController!.setPlaybackSpeed(clampedSpeed),
        if (_audioPlayer != null) _audioPlayer!.setSpeed(clampedSpeed),
      ]);

      _updateState(_currentState.copyWith(playbackSpeed: clampedSpeed));
    } catch (e) {
      throw PlayerFailure('Failed to set speed: $e');
    }
  }

  void _updateState(PlaybackState newState) {
    if (_isDisposed || _stateController.isClosed) return;

    _currentState = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    debugPrint('VideoPlayerDataSource: Disposing...');

    _positionTimer?.cancel();
    _syncTimer?.cancel();

    await _videoPositionSubscription?.cancel();
    await _audioPositionSubscription?.cancel();
    await _audioStateSubscription?.cancel();

    try {
      await Future.wait([
        if (_videoController != null) _videoController!.dispose(),
        if (_audioPlayer != null) _audioPlayer!.dispose(),
      ]);
    } catch (e) {
      debugPrint('Dispose error: $e');
    }

    await _stateController.close();

    debugPrint('VideoPlayerDataSource: Disposed successfully');
  }

  // Getters for video controller access (needed for UI)
  VideoPlayerController? get videoController => _videoController;
  bool get hasVideoController => _videoController != null;
  bool get isVideoInitialized => _videoController?.value.isInitialized == true;
  AudioPlayer? get audioPlayer => _audioPlayer;
}
