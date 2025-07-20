import '../entities/media_item.dart';
import '../entities/player_state.dart';
import '../../../../core/utils/result.dart';

abstract class MediaPlayerRepository {
  // Media Management
  Future<Result<void>> loadMedia(MediaItem mediaItem);
  Future<Result<void>> setPlaylist(List<MediaItem> playlist, {int startIndex = 0});

  // Playback Control
  Future<Result<void>> play();
  Future<Result<void>> pause();
  Future<Result<void>> stop();
  Future<Result<void>> seekTo(Duration position);
  Future<Result<void>> setVolume(double volume);
  Future<Result<void>> setPlaybackSpeed(double speed);

  // Navigation
  Future<Result<void>> skipToNext();
  Future<Result<void>> skipToPrevious();
  Future<Result<void>> skipToIndex(int index);

  // State Streams
  Stream<PlaybackState> get playbackStateStream;
  Stream<MediaItem?> get currentMediaStream;

  // Resources
  Future<void> dispose();
}
