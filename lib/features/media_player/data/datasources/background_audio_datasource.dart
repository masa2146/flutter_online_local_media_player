import 'dart:async';
import 'package:audio_service/audio_service.dart' hide PlaybackState, MediaItem;
import 'package:flutter/cupertino.dart';
import '../../../../core/services/background_audio_service.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/player_state.dart';
import '../../../../core/errors/failures.dart';
import 'media_player_datasource.dart';

/// Background audio data source that uses audio_service for background playback
/// and notification controls. Only supports audio media items.
class BackgroundAudioDataSource implements MediaPlayerDataSource {
  // **SINGLETON YAPI:** AudioService ve Handler'ı static olarak yönet
  static BackgroundAudioHandler? _sharedAudioHandler;
  static bool _isAudioServiceInitialized = false;

  StreamSubscription? _handlerSubscription;
  StreamSubscription? _customEventSubscription;

  final StreamController<PlaybackState> _stateController =
  StreamController<PlaybackState>.broadcast();

  PlaybackState _currentState = const PlaybackState();
  bool _isDisposed = false;

  @override
  Stream<PlaybackState> get stateStream => _stateController.stream;

  @override
  Future<void> initialize(MediaItem mediaItem) async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');

    try {
      // Only support audio media items for background playback
      if (mediaItem.type != MediaType.audio) {
        throw PlayerFailure('Background playbook only supports audio media');
      }

      _updateState(_currentState.copyWith(status: PlaybackStatus.loading));

      // **ÖNEMLİ:** AudioService'i sadece bir kez initialize et
      if (!_isAudioServiceInitialized || _sharedAudioHandler == null) {
        debugPrint('BackgroundAudioDataSource: Initializing AudioService for first time');

        final handler = await AudioService.init(
          builder: () => BackgroundAudioHandler(),
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.example.flutter_media_player.audio',
            androidNotificationChannelName: 'Media Player',
            androidNotificationChannelDescription: 'Media playback controls',
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: true,
            androidNotificationClickStartsActivity: true,
            androidNotificationIcon: 'mipmap/ic_launcher',
            androidShowNotificationBadge: true,
          ),
        );

        _sharedAudioHandler = handler as BackgroundAudioHandler?;
        _isAudioServiceInitialized = true;

        if (_sharedAudioHandler == null) {
          throw PlayerFailure('Failed to initialize audio service');
        }
      } else {
        debugPrint('BackgroundAudioDataSource: Reusing existing AudioService');
      }

      // Mevcut subscription'ları temizle
      _handlerSubscription?.cancel();
      _customEventSubscription?.cancel();

      // Handler state değişikliklerini dinle
      _handlerSubscription = _sharedAudioHandler!.playbackStateStream.listen(
            (state) {
          if (!_isDisposed) {
            _updateState(state);
          }
        },
        onError: (error) {
          if (!_isDisposed) {
            _updateState(_currentState.copyWith(
              status: PlaybackStatus.error,
              error: 'Background playback error: $error',
            ));
          }
        },
      );

      // Custom event'leri dinle (skip previous/next)
      _customEventSubscription = _sharedAudioHandler!.customEvent.listen(
            (event) {
          if (!_isDisposed) {
            _handleCustomEvent(event);
          }
        },
      );

      // **ÖNEMLİ:** Handler'da medyayı yükle
      await _sharedAudioHandler!.initializeMedia(mediaItem);

      _updateState(_currentState.copyWith(
        status: PlaybackStatus.paused,
        duration: _sharedAudioHandler!.currentState.duration,
        position: Duration.zero,
        error: null,
      ));

      debugPrint('BackgroundAudioDataSource: Initialized successfully');

    } catch (e) {
      _updateState(_currentState.copyWith(
        status: PlaybackStatus.error,
        error: 'Failed to initialize background audio: $e',
      ));
      rethrow;
    }
  }

  void _handleCustomEvent(dynamic event) {
    // Handle skip events from notification
    if (event == 'skipToPrevious' || event == 'skipToNext') {
      debugPrint('Background audio custom event: $event');
    }
  }

  void _updateState(PlaybackState newState) {
    if (_isDisposed || _stateController.isClosed) return;

    final oldState = _currentState;
    _currentState = newState;

    // Debug log for important changes
    if (oldState.status != newState.status) {
      debugPrint('BackgroundAudio state change: ${oldState.status} -> ${newState.status}');
    }

    _stateController.add(newState);
  }

  @override
  Future<void> play() async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');
    if (_sharedAudioHandler == null) throw PlayerFailure('Audio handler not initialized');

    debugPrint('BackgroundAudio: Play command received');
    await _sharedAudioHandler!.play();
  }

  @override
  Future<void> pause() async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');
    if (_sharedAudioHandler == null) throw PlayerFailure('Audio handler not initialized');

    debugPrint('BackgroundAudio: Pause command received');
    await _sharedAudioHandler!.pause();
  }

  @override
  Future<void> stop() async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');
    if (_sharedAudioHandler == null) throw PlayerFailure('Audio handler not initialized');

    await _sharedAudioHandler!.stop();
    _updateState(_currentState.copyWith(
      status: PlaybackStatus.stopped,
      position: Duration.zero,
    ));
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');
    if (_sharedAudioHandler == null) throw PlayerFailure('Audio handler not initialized');

    await _sharedAudioHandler!.seek(position);
    _updateState(_currentState.copyWith(position: position));
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');
    if (_sharedAudioHandler == null) throw PlayerFailure('Audio handler not initialized');

    final clampedVolume = volume.clamp(0.0, 1.0);
    await _sharedAudioHandler!.setVolume(clampedVolume);
    _updateState(_currentState.copyWith(volume: clampedVolume));
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');
    if (_sharedAudioHandler == null) throw PlayerFailure('Audio handler not initialized');

    final clampedSpeed = speed.clamp(0.25, 3.0);
    await _sharedAudioHandler!.setSpeed(clampedSpeed);
    _updateState(_currentState.copyWith(playbackSpeed: clampedSpeed));
  }

  // Additional methods for background playback controls
  Future<void> rewind() async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');
    if (_sharedAudioHandler == null) throw PlayerFailure('Audio handler not initialized');

    await _sharedAudioHandler!.rewind();
  }

  Future<void> fastForward() async {
    if (_isDisposed) throw PlayerFailure('Player already disposed');
    if (_sharedAudioHandler == null) throw PlayerFailure('Audio handler not initialized');

    await _sharedAudioHandler!.fastForward();
  }

  // Stream to listen for custom events from notification
  Stream<String> get customEventStream => _sharedAudioHandler?.customEvent.cast<String>()
      ?? const Stream.empty();

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    debugPrint('BackgroundAudioDataSource: Disposing...');

    // Sadece subscription'ları iptal et, handler'ı dispose etme
    await _handlerSubscription?.cancel();
    await _customEventSubscription?.cancel();
    await _stateController.close();

    // **ÖNEMLİ:** Handler'ı dispose etme, sadece DataSource'u temizle
    // _sharedAudioHandler = null; // BUNU YAPMA!

    debugPrint('BackgroundAudioDataSource: Disposed successfully');
  }

  // **YENİ:** Uygulama tamamen kapanırken çağrılacak static method
  static Future<void> disposeSharedResources() async {
    debugPrint('BackgroundAudioDataSource: Disposing shared resources');

    if (_sharedAudioHandler != null) {
      await _sharedAudioHandler!.dispose();
      _sharedAudioHandler = null;
    }

    _isAudioServiceInitialized = false;
  }
}
