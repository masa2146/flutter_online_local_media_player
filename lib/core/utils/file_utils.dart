import 'dart:io';

import '../constants/app_constants.dart';

class FileUtils {
  static String sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'\.+'), '.')
        .replaceAll(RegExp(r'[^\w\s.-]'), '_') // Remove special characters
        .trim()
        .substring(0, fileName.length > AppConstants.maxFilenameLength ? AppConstants.maxFilenameLength : fileName.length);
  }

  static String formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  static String formatDuration(int seconds) {
    if (seconds >= 3600) {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      final remainingSeconds = seconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      final minutes = (seconds / 60).floor();
      final remainingSeconds = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  static String formatViewCount(int count) {
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    } else if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  static String getFileExtension(String filename) {
    return filename.split('.').last.toLowerCase();
  }

  static String getFileNameWithoutExtension(String filename) {
    final parts = filename.split('.');
    if (parts.length > 1) {
      parts.removeLast();
    }
    return parts.join('.');
  }

  static bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    return uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority;
  }


  static double calculateDownloadProgress(int downloaded, int total) {
    if (total <= 0) return 0.0;
    return (downloaded / total).clamp(0.0, 1.0);
  }

  static String formatDownloadSpeed(double bytesPerSecond) {
    if (bytesPerSecond >= 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    } else if (bytesPerSecond >= 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${bytesPerSecond.toStringAsFixed(0)} B/s';
  }

  static String formatTimeRemaining(int seconds) {
    if (seconds >= 3600) {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      return '${hours}sa ${minutes}dk';
    } else if (seconds >= 60) {
      final minutes = (seconds / 60).floor();
      return '${minutes}dk';
    }
    return '${seconds}sn';
  }

  static bool isFileSizeValid(int bytes) {
    final maxSizeBytes = (AppConstants.maxFileSizeGB * 1024 * 1024 * 1024).toInt();
    return bytes <= maxSizeBytes;
  }

  static bool fileExists(String filePath) {
    return File(filePath).existsSync();
  }
}
