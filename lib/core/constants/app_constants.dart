class AppConstants {
  // Player Settings
  static const Duration positionUpdateInterval = Duration(seconds: 1);
  static const Duration seekThreshold = Duration(milliseconds: 500);
  static const Duration autoHideControlsDelay = Duration(seconds: 3);

  // Performance
  static const int maxCachedThumbnails = 50;
  static const int maxRecentMediaItems = 100;

  // Error Retry
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // File Settings
  static const int maxFilenameLength = 100;
  static const double maxFileSizeGB = 2.0;
}
