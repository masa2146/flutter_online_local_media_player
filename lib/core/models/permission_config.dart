enum PermissionType {
  storage,
  manageExternalStorage,
  videos,
  audio,
  photos,
  camera,
  microphone,
  notification,
}

class PermissionConfig {
  final PermissionType type;
  final String title;
  final String description;
  final String rationale;
  final String icon;
  final bool isRequired;

  const PermissionConfig({
    required this.type,
    required this.title,
    required this.description,
    required this.rationale,
    required this.icon,
    this.isRequired = true,
  });

  static const Map<PermissionType, PermissionConfig> configs = {
    PermissionType.storage: PermissionConfig(
      type: PermissionType.storage,
      title: 'Storage Access',
      description: 'Access local files for media playback',
      rationale: 'We need storage access to play your local media files and save downloaded content.',
      icon: '📁',
    ),
    PermissionType.manageExternalStorage: PermissionConfig(
      type: PermissionType.manageExternalStorage,
      title: 'File Management',
      description: 'Manage all files for better media organization',
      rationale: 'We need file management access to organize and play your media files efficiently.',
      icon: '🗂️',
    ),
    PermissionType.videos: PermissionConfig(
      type: PermissionType.videos,
      title: 'Video Access',
      description: 'Access video files on your device',
      rationale: 'We need access to your videos to play them in the media player.',
      icon: '🎬',
    ),
    PermissionType.audio: PermissionConfig(
      type: PermissionType.audio,
      title: 'Audio Access',
      description: 'Access audio files on your device',
      rationale: 'We need access to your audio files to play them in the media player.',
      icon: '🎵',
    ),
    PermissionType.photos: PermissionConfig(
      type: PermissionType.photos,
      title: 'Photos Access',
      description: 'Access photos for thumbnails and album art',
      rationale: 'We need access to your photos to display album art and video thumbnails.',
      icon: '🖼️',
    ),
    PermissionType.camera: PermissionConfig(
      type: PermissionType.camera,
      title: 'Camera Access',
      description: 'Record videos and take photos',
      rationale: 'We need camera access to record videos that you can play in the media player.',
      icon: '📸',
      isRequired: false,
    ),
    PermissionType.microphone: PermissionConfig(
      type: PermissionType.microphone,
      title: 'Microphone Access',
      description: 'Record audio for your media',
      rationale: 'We need microphone access to record audio that you can play in the media player.',
      icon: '🎙️',
      isRequired: false,
    ),
    PermissionType.notification: PermissionConfig(
      type: PermissionType.notification,
      title: 'Notifications',
      description: 'Show media playback controls',
      rationale: 'We need notification access to show media controls while playing in the background.',
      icon: '🔔',
      isRequired: false,
    ),
  };

  static PermissionConfig? getConfig(PermissionType type) => configs[type];
}
