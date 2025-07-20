import 'package:equatable/equatable.dart';

enum MediaType { audio, video, videoWithSeparateAudio }
enum MediaSource { local, network, stream }

class MediaItem extends Equatable {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final Duration? duration;
  final String? thumbnailUrl;

  // Local file paths
  final String? localVideoPath;
  final String? localAudioPath;

  // Network URLs
  final String? videoUrl;
  final String? audioUrl;

  final MediaType type;
  final MediaSource source;
  final Map<String, dynamic>? metadata;

  const MediaItem({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.thumbnailUrl,
    this.localVideoPath,
    this.localAudioPath,
    this.videoUrl,
    this.audioUrl,
    required this.type,
    required this.source,
    this.metadata,
  });

  // Computed properties
  String get displayTitle => title;
  String get displaySubtitle => artist ?? album ?? 'Unknown';

  bool get hasVideo => videoUrl != null || localVideoPath != null;
  bool get hasAudio => audioUrl != null || localAudioPath != null;
  bool get hasSeparateStreams => hasVideo && hasAudio && type == MediaType.videoWithSeparateAudio;

  String? get playableVideoUrl => localVideoPath ?? videoUrl;
  String? get playableAudioUrl => localAudioPath ?? audioUrl;

  bool get hasValidSource {
    switch (type) {
      case MediaType.audio:
        return playableAudioUrl != null && playableAudioUrl!.isNotEmpty;
      case MediaType.video:
        return playableVideoUrl != null && playableVideoUrl!.isNotEmpty;
      case MediaType.videoWithSeparateAudio:
        return hasVideo && hasAudio;
    }
  }

  MediaItem copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? thumbnailUrl,
    String? localVideoPath,
    String? localAudioPath,
    String? videoUrl,
    String? audioUrl,
    MediaType? type,
    MediaSource? source,
    Map<String, dynamic>? metadata,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localVideoPath: localVideoPath ?? this.localVideoPath,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      type: type ?? this.type,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id, title, artist, album, duration, thumbnailUrl,
    localVideoPath, localAudioPath, videoUrl, audioUrl,
    type, source, metadata,
  ];
}
