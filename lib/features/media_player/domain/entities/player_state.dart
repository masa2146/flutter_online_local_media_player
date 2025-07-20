import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/file_utils.dart';
import 'media_item.dart';

enum PlaybackStatus { idle, loading, playing, paused, stopped, error }
enum PlayerMode { minimized, fullscreen, background }

class PlaybackState extends Equatable {
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final double volume;
  final double playbackSpeed;
  final bool isBuffering;
  final String? error;

  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.isBuffering = false,
    this.error,
  });

  // Computed properties
  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isLoading => status == PlaybackStatus.loading;
  bool get hasError => error != null;
  bool get canSeek => duration > Duration.zero && !isBuffering;

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  String get formattedPosition => FileUtils.formatDuration(position.inSeconds);
  String get formattedDuration => FileUtils.formatDuration(duration.inSeconds);
  String get formattedRemaining => FileUtils.formatDuration(duration.inSeconds - position.inSeconds);



  PlaybackState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    double? volume,
    double? playbackSpeed,
    bool? isBuffering,
    String? error,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isBuffering: isBuffering ?? this.isBuffering,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status, position, duration, volume,
    playbackSpeed, isBuffering, error,
  ];
}

class UIState extends Equatable {
  final PlayerMode mode;
  final bool showControls;
  final bool isFullscreen;
  final Size? videoSize;
  final double? aspectRatio;

  const UIState({
    this.mode = PlayerMode.minimized,
    this.showControls = true,
    this.isFullscreen = false,
    this.videoSize,
    this.aspectRatio,
  });

  UIState copyWith({
    PlayerMode? mode,
    bool? showControls,
    bool? isFullscreen,
    Size? videoSize,
    double? aspectRatio,
  }) {
    return UIState(
      mode: mode ?? this.mode,
      showControls: showControls ?? this.showControls,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      videoSize: videoSize ?? this.videoSize,
      aspectRatio: aspectRatio ?? this.aspectRatio,
    );
  }

  @override
  List<Object?> get props => [
    mode, showControls, isFullscreen, videoSize, aspectRatio,
  ];
}

class MediaPlayerState extends Equatable {
  final MediaItem? currentMedia;
  final List<MediaItem> playlist;
  final int currentIndex;
  final PlaybackState playback;
  final UIState ui;

  const MediaPlayerState({
    this.currentMedia,
    this.playlist = const [],
    this.currentIndex = 0,
    this.playback = const PlaybackState(),
    this.ui = const UIState(),
  });

  bool get hasMedia => currentMedia != null;
  bool get hasPlaylist => playlist.isNotEmpty;
  bool get canGoNext => currentIndex < playlist.length - 1;
  bool get canGoPrevious => currentIndex > 0;

  MediaPlayerState copyWith({
    MediaItem? currentMedia,
    List<MediaItem>? playlist,
    int? currentIndex,
    PlaybackState? playback,
    UIState? ui,
  }) {
    return MediaPlayerState(
      currentMedia: currentMedia ?? this.currentMedia,
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      playback: playback ?? this.playback,
      ui: ui ?? this.ui,
    );
  }

  @override
  List<Object?> get props => [
    currentMedia, playlist, currentIndex, playback, ui,
  ];
}
