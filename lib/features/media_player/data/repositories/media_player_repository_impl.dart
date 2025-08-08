import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/player_state.dart';
import '../../domain/repositories/media_player_repository.dart';
import '../datasources/background_audio_datasource.dart';
import '../datasources/media_player_datasource.dart';
import '../datasources/video_player_datasource.dart';

class MediaPlayerRepositoryImpl implements MediaPlayerRepository {
  MediaPlayerDataSource? _currentDataSource;
  MediaItem? _currentMedia;
  List<MediaItem> _playlist = [];
  int _currentIndex = 0;
  bool _backgroundPlaybackEnabled = false;

  final StreamController<MediaItem?> _currentMediaController =
  StreamController<MediaItem?>.broadcast();

  StreamSubscription? _customEventSubscription;
  bool _isDisposed = false;

  @override
  Stream<MediaItem?> get currentMediaStream => _currentMediaController.stream;

  @override
  Stream<PlaybackState> get playbackStateStream =>
      _currentDataSource?.stateStream ?? const Stream.empty();

  /// Enable or disable background playback
  /// When enabled, audio-only media will use background playback with notifications
  void setBackgroundPlaybackEnabled(bool enabled) {
    _backgroundPlaybackEnabled = enabled;
  }

  bool get isBackgroundPlaybackEnabled => _backgroundPlaybackEnabled;

  @override
  Future<Result<void>> loadMedia(MediaItem mediaItem) async {
    if (_isDisposed) return const Error(PlayerFailure('Repository disposed'));

    try {
      // **DEĞİŞİKLİK:** Sadece farklı medya tipine geçiyorsak DataSource'u değiştir
      bool needsNewDataSource = false;

      if (_currentDataSource == null) {
        needsNewDataSource = true;
      } else if (_currentMedia?.type != mediaItem.type) {
        // Medya tipi değişti (audio <-> video), yeni datasource lazım
        needsNewDataSource = true;
      } else if (mediaItem.type == MediaType.video && _currentDataSource is! VideoPlayerDataSource) {
        needsNewDataSource = true;
      } else if (mediaItem.type == MediaType.audio && _currentDataSource is! BackgroundAudioDataSource) {
        needsNewDataSource = true;
      }

      if (needsNewDataSource) {
        debugPrint('Creating new DataSource for media type: ${mediaItem.type}');
        await _disposeCurrentDataSource();
        _currentDataSource = _createDataSource(mediaItem);
        _setupCustomEventListener();
      } else {
        debugPrint('Reusing existing DataSource for media type: ${mediaItem.type}');
      }

      _currentMedia = mediaItem;
      _currentMediaController.add(mediaItem);

      // Medyayı yükle (mevcut DataSource ile)
      await _currentDataSource!.initialize(mediaItem);

      return const Success(null);
    } catch (e) {
      debugPrint('Error loading media: $e');
      return Error(PlayerFailure('Failed to load media: $e'));
    }
  }

  MediaPlayerDataSource _createDataSource(MediaItem mediaItem) {
    switch (mediaItem.type) {
      case MediaType.audio:
      // Use background audio data source if background playback is enabled
        return BackgroundAudioDataSource();

      case MediaType.video:
      case MediaType.videoWithSeparateAudio:
      // Video always uses regular video player (no background support for video)
        return VideoPlayerDataSource();
    }
  }

  void _setupCustomEventListener() {
    _customEventSubscription?.cancel();

    if (_currentDataSource is BackgroundAudioDataSource) {
      final backgroundDataSource =
      _currentDataSource as BackgroundAudioDataSource;

      _customEventSubscription = backgroundDataSource.customEventStream.listen(
            (event) {
          _handleCustomEvent(event);
        },
        onError: (error) {
          debugPrint('Custom event stream error: $error');
        },
      );
    }
  }

  void _handleCustomEvent(String event) {
    switch (event) {
      case 'skipToPrevious':
        skipToPrevious();
        break;
      case 'skipToNext':
        skipToNext();
        break;
      default:
        debugPrint('Unknown custom event: $event');
    }
  }

  @override
  Future<Result<void>> setPlaylist(
      List<MediaItem> playlist, {
        int startIndex = 0,
      }) async {
    if (_isDisposed) return const Error(PlayerFailure('Repository disposed'));

    try {
      _playlist = List.from(playlist);
      _currentIndex = startIndex.clamp(0, playlist.length - 1);

      if (playlist.isNotEmpty && _currentIndex < playlist.length) {
        return await loadMedia(playlist[_currentIndex]);
      }

      return const Success(null);
    } catch (e) {
      return Error(PlayerFailure('Failed to set playlist: $e'));
    }
  }

  VideoPlayerController? getVideoController() {
    if (_currentDataSource is VideoPlayerDataSource) {
      return (_currentDataSource as VideoPlayerDataSource).videoController;
    }
    return null;
  }

  bool get hasVideoController {
    if (_currentDataSource is VideoPlayerDataSource) {
      return (_currentDataSource as VideoPlayerDataSource).hasVideoController;
    }
    return false;
  }

  bool get isVideoInitialized {
    if (_currentDataSource is VideoPlayerDataSource) {
      return (_currentDataSource as VideoPlayerDataSource).isVideoInitialized;
    }
    return false;
  }

  /// Check if current media is playing in background
  bool get isPlayingInBackground {
    return _currentDataSource is BackgroundAudioDataSource;
  }

  @override
  Future<Result<void>> play() async {
    if (_isDisposed) return const Error(PlayerFailure('Repository disposed'));
    if (_currentDataSource == null)
      return const Error(PlayerFailure('No media loaded'));

    try {
      await _currentDataSource!.play();
      return const Success(null);
    } catch (e) {
      return Error(PlayerFailure('Failed to play: $e'));
    }
  }

  @override
  Future<Result<void>> pause() async {
    if (_isDisposed) return const Error(PlayerFailure('Repository disposed'));
    if (_currentDataSource == null)
      return const Error(PlayerFailure('No media loaded'));

    try {
      await _currentDataSource!.pause();
      return const Success(null);
    } catch (e) {
      return Error(PlayerFailure('Failed to pause: $e'));
    }
  }

  @override
  Future<Result<void>> stop() async {
    if (_isDisposed) return const Error(PlayerFailure('Repository disposed'));
    if (_currentDataSource == null)
      return const Error(PlayerFailure('No media loaded'));

    try {
      await _currentDataSource!.stop();
      return const Success(null);
    } catch (e) {
      return Error(PlayerFailure('Failed to stop: $e'));
    }
  }

  @override
  Future<Result<void>> seekTo(Duration position) async {
    if (_isDisposed) return const Error(PlayerFailure('Repository disposed'));
    if (_currentDataSource == null)
      return const Error(PlayerFailure('No media loaded'));

    try {
      await _currentDataSource!.seekTo(position);
      return const Success(null);
    } catch (e) {
      return Error(PlayerFailure('Failed to seek: $e'));
    }
  }

  @override
  Future<Result<void>> setVolume(double volume) async {
    if (_isDisposed) return const Error(PlayerFailure('Repository disposed'));
    if (_currentDataSource == null)
      return const Error(PlayerFailure('No media loaded'));

    try {
      await _currentDataSource!.setVolume(volume);
      return const Success(null);
    } catch (e) {
      return Error(PlayerFailure('Failed to set volume: $e'));
    }
  }

  @override
  Future<Result<void>> setPlaybackSpeed(double speed) async {
    if (_isDisposed) return const Error(PlayerFailure('Repository disposed'));
    if (_currentDataSource == null)
      return const Error(PlayerFailure('No media loaded'));

    try {
      await _currentDataSource!.setSpeed(speed);
      return const Success(null);
    } catch (e) {
      return Error(PlayerFailure('Failed to set speed: $e'));
    }
  }

  /// Additional controls for background playback
  Future<Result<void>> rewind() async {
    if (_isDisposed) return const Error(PlayerFailure('Repository disposed'));

    if (_currentDataSource is BackgroundAudioDataSource) {
      try {
        final backgroundDataSource =
        _currentDataSource as BackgroundAudioDataSource;
        await backgroundDataSource.rewind();
        return const Success(null);
      } catch (e) {
        return Error(PlayerFailure('Failed to rewind: $e'));
      }
    } else {
      // Fallback to seek backward 10 seconds
      final currentState = await playbackStateStream.first;
      final newPosition = currentState.position - const Duration(seconds: 10);
      return await seekTo(
        newPosition < Duration.zero ? Duration.zero : newPosition,
      );
    }
  }

  Future<Result<void>> fastForward() async {
    if (_isDisposed) return const Error(PlayerFailure('Repository disposed'));

    if (_currentDataSource is BackgroundAudioDataSource) {
      try {
        final backgroundDataSource =
        _currentDataSource as BackgroundAudioDataSource;
        await backgroundDataSource.fastForward();
        return const Success(null);
      } catch (e) {
        return Error(PlayerFailure('Failed to fast forward: $e'));
      }
    } else {
      // Fallback to seek forward 10 seconds
      final currentState = await playbackStateStream.first;
      final newPosition = currentState.position + const Duration(seconds: 10);
      final clampedPosition = newPosition > currentState.duration
          ? currentState.duration
          : newPosition;
      return await seekTo(clampedPosition);
    }
  }

  @override
  Future<Result<void>> skipToNext() async {
    if (_playlist.isEmpty || _currentIndex >= _playlist.length - 1) {
      return const Error(PlayerFailure('Cannot skip to next'));
    }

    _currentIndex++;
    return await loadMedia(_playlist[_currentIndex]);
  }

  @override
  Future<Result<void>> skipToPrevious() async {
    if (_playlist.isEmpty || _currentIndex <= 0) {
      return const Error(PlayerFailure('Cannot skip to previous'));
    }

    _currentIndex--;
    return await loadMedia(_playlist[_currentIndex]);
  }

  @override
  Future<Result<void>> skipToIndex(int index) async {
    if (_playlist.isEmpty || index < 0 || index >= _playlist.length) {
      return const Error(PlayerFailure('Invalid index'));
    }

    _currentIndex = index;
    return await loadMedia(_playlist[_currentIndex]);
  }

  Future<void> _disposeCurrentDataSource() async {
    await _customEventSubscription?.cancel();
    await _currentDataSource?.dispose();
    _currentDataSource = null;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    debugPrint('MediaPlayerRepositoryImpl: Disposing...');

    await _disposeCurrentDataSource();
    await _currentMediaController.close();

    // **YENİ:** Uygulama kapanırken shared resources'ı temizle
    // Sadece son repository instance'ı dispose edilirken çağrılmalı
    // await BackgroundAudioDataSource.disposeSharedResources();
  }
}
