import 'package:flutter/material.dart';
import '../../../../core/models/permission_config.dart';
import '../../../../core/models/permission_result.dart';
import '../../../../core/services/permission_service.dart';
import '../widgets/permission_dialog.dart';

class MediaPermissionManager {
  static final PermissionService _permissionService = PermissionServiceImpl();

  /// Request permissions required for media playback
  static Future<bool> requestMediaPermissions(BuildContext context) async {
    try {
      // Check if permissions are already granted
      final hasPermissions = await _hasRequiredMediaPermissions();
      if (hasPermissions) return true;

      // Show permission dialog
      final result = await PermissionDialog.show(
        context: context,
        requiredPermissions: _getRequiredMediaPermissions(),
        optionalPermissions: _getOptionalMediaPermissions(),
        title: 'Media Access Required',
        subtitle: 'To play your media files, we need access to your device storage',
      );

      return result?.canProceed ?? false;
    } catch (e) {
      debugPrint('MediaPermissionManager: Error requesting permissions: $e');
      return false;
    }
  }

  /// Request permissions for file picker
  static Future<bool> requestFilePickerPermissions(BuildContext context) async {
    try {
      final hasPermissions = await _hasFilePickerPermissions();
      if (hasPermissions) return true;

      final result = await PermissionDialog.show(
        context: context,
        requiredPermissions: _getFilePickerPermissions(),
        title: 'File Access Required',
        subtitle: 'Please grant access to select media files from your device',
      );

      return result?.canProceed ?? false;
    } catch (e) {
      debugPrint('MediaPermissionManager: Error requesting file picker permissions: $e');
      return false;
    }
  }

  /// Request permissions for media recording (optional feature)
  static Future<bool> requestRecordingPermissions(BuildContext context) async {
    try {
      final result = await PermissionDialog.show(
        context: context,
        requiredPermissions: [PermissionType.camera, PermissionType.microphone],
        title: 'Recording Permissions',
        subtitle: 'To record videos and audio, we need access to your camera and microphone',
      );

      return result?.canProceed ?? false;
    } catch (e) {
      debugPrint('MediaPermissionManager: Error requesting recording permissions: $e');
      return false;
    }
  }

  /// Check if app has all required media permissions
  static Future<bool> hasMediaPermissions() => _hasRequiredMediaPermissions();

  /// Check if app has file picker permissions
  static Future<bool> hasFilePickerPermissions() => _hasFilePickerPermissions();

  static List<PermissionType> _getRequiredMediaPermissions() {
    return [
      PermissionType.videos,
      PermissionType.audio,
      PermissionType.storage,
      PermissionType.manageExternalStorage,
    ];
  }

  static List<PermissionType> _getOptionalMediaPermissions() {
    return [
      PermissionType.photos, // For album art
      PermissionType.notification, // For media controls
    ];
  }

  static List<PermissionType> _getFilePickerPermissions() {
    return [
      PermissionType.videos,
      PermissionType.audio,
      PermissionType.storage,
    ];
  }

  static Future<bool> _hasRequiredMediaPermissions() async {
    final requiredPermissions = _getRequiredMediaPermissions();
    return await _permissionService.hasAllPermissions(requiredPermissions);
  }

  static Future<bool> _hasFilePickerPermissions() async {
    final filePickerPermissions = _getFilePickerPermissions();
    return await _permissionService.hasAllPermissions(filePickerPermissions);
  }
}
