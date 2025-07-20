import 'package:equatable/equatable.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/player_state.dart';

abstract class MediaPlayerEvent extends Equatable {
  const MediaPlayerEvent();

  @override
  List<Object?> get props => [];
}

class LoadMediaEvent extends MediaPlayerEvent {
  final MediaItem mediaItem;

  const LoadMediaEvent(this.mediaItem);

  @override
  List<Object?> get props => [mediaItem];
}

class SetPlaylistEvent extends MediaPlayerEvent {
  final List<MediaItem> playlist;
  final int startIndex;

  const SetPlaylistEvent(this.playlist, {this.startIndex = 0});

  @override
  List<Object?> get props => [playlist, startIndex];
}

class PlayEvent extends MediaPlayerEvent {
  const PlayEvent();
}

class PauseEvent extends MediaPlayerEvent {
  const PauseEvent();
}

class TogglePlayPauseEvent extends MediaPlayerEvent {
  const TogglePlayPauseEvent();
}

class StopEvent extends MediaPlayerEvent {
  const StopEvent();
}

class SeekToEvent extends MediaPlayerEvent {
  final Duration position;

  const SeekToEvent(this.position);

  @override
  List<Object?> get props => [position];
}

class SetVolumeEvent extends MediaPlayerEvent {
  final double volume;

  const SetVolumeEvent(this.volume);

  @override
  List<Object?> get props => [volume];
}

class SkipToNextEvent extends MediaPlayerEvent {
  const SkipToNextEvent();
}

class SkipToPreviousEvent extends MediaPlayerEvent {
  const SkipToPreviousEvent();
}

class ShowControlsEvent extends MediaPlayerEvent {
  const ShowControlsEvent();
}

class HideControlsEvent extends MediaPlayerEvent {
  const HideControlsEvent();
}

class ToggleFullscreenEvent extends MediaPlayerEvent {
  const ToggleFullscreenEvent();
}

class SetPlayerModeEvent extends MediaPlayerEvent {
  final PlayerMode mode;

  const SetPlayerModeEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

class SetBackgroundPlaybackEvent extends MediaPlayerEvent {
  final bool enabled;

  const SetBackgroundPlaybackEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class RewindEvent extends MediaPlayerEvent {
  const RewindEvent();
}

class FastForwardEvent extends MediaPlayerEvent {
  const FastForwardEvent();
}
