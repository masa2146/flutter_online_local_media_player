import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/permission_result.dart';
import '../models/permission_config.dart';

abstract class PermissionService {
  Future<PermissionResult> requestPermissions(List<PermissionType> permissions);
  Future<PermissionResult> requestSinglePermission(PermissionType permission);
  Future<bool> hasPermission(PermissionType permission);
  Future<bool> hasAllPermissions(List<PermissionType> permissions);
  Future<bool> shouldShowRationale(PermissionType permission);
  Future<void> openAppSettings();
}

class PermissionServiceImpl implements PermissionService {
  static final PermissionServiceImpl _instance = PermissionServiceImpl._internal();
  factory PermissionServiceImpl() => _instance;
  PermissionServiceImpl._internal();

  // Cache for Android version to avoid multiple calls
  int? _cachedAndroidVersion;

  // Cache for permission status to avoid unnecessary checks
  final Map<PermissionType, bool> _permissionCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  final Map<PermissionType, Permission> _permissionMap = {
    PermissionType.storage: Permission.storage,
    PermissionType.manageExternalStorage: Permission.manageExternalStorage,
    PermissionType.videos: Permission.videos,
    PermissionType.audio: Permission.audio,
    PermissionType.photos: Permission.photos,
    PermissionType.camera: Permission.camera,
    PermissionType.microphone: Permission.microphone,
    PermissionType.notification: Permission.notification,
  };

  @override
  Future<PermissionResult> requestPermissions(List<PermissionType> permissions) async {
    try {
      debugPrint('PermissionService: Requesting permissions: $permissions');

      // Filter permissions based on platform
      final filteredPermissions = await _filterPermissionsForPlatform(permissions);

      if (filteredPermissions.isEmpty) {
        return PermissionResult.success(
          grantedPermissions: permissions,
          message: 'No platform-specific permissions required',
        );
      }

      // Check current status for all permissions
      final statusChecks = await Future.wait(filteredPermissions.map((type) async => await _checkSinglePermissionStatus(type)));

      final alreadyGranted = <PermissionType>[];
      final needsRequest = <PermissionType>[];
      final permanentlyDenied = <PermissionType>[];

      for (int i = 0; i < filteredPermissions.length; i++) {
        final type = filteredPermissions[i];
        final status = statusChecks[i];

        switch (status) {
          case PermissionStatus.granted:
            alreadyGranted.add(type);
            break;
          case PermissionStatus.permanentlyDenied:
            permanentlyDenied.add(type);
            break;
          case PermissionStatus.denied:
          case PermissionStatus.restricted:
          case PermissionStatus.limited:
          case PermissionStatus.provisional:
            needsRequest.add(type);
            break;
        }
      }

      // Handle permanently denied permissions
      if (permanentlyDenied.isNotEmpty) {
        debugPrint('PermissionService: Permanently denied permissions: $permanentlyDenied');
        return PermissionResult.permanentlyDenied(
          deniedPermissions: permanentlyDenied,
          message: 'Some permissions are permanently denied. Please enable them in app settings.',
        );
      }

      // If all permissions are already granted, return success
      if (needsRequest.isEmpty) {
        _updatePermissionCache(alreadyGranted, true);
        return PermissionResult.success(
          grantedPermissions: alreadyGranted,
          message: 'All permissions already granted',
        );
      }

      // Request needed permissions
      final permissionsToRequest = needsRequest
          .map((type) => _permissionMap[type]!)
          .toList();

      final results = await permissionsToRequest.request();

      // Process results
      final granted = <PermissionType>[];
      final denied = <PermissionType>[];

      // Add already granted permissions
      granted.addAll(alreadyGranted);

      // Process newly requested permissions
      for (int i = 0; i < permissionsToRequest.length; i++) {
        final permission = permissionsToRequest[i];
        final status = results[permission] ?? PermissionStatus.denied;
        final type = needsRequest[i];

        if (status == PermissionStatus.granted) {
          granted.add(type);
        } else {
          denied.add(type);
        }
      }

      // Update cache with results
      _updatePermissionCache(granted, true);
      _updatePermissionCache(denied, false);

      if (denied.isEmpty) {
        debugPrint('PermissionService: All permissions granted successfully');
        return PermissionResult.success(
          grantedPermissions: granted,
          message: 'All permissions granted successfully',
        );
      } else {
        debugPrint('PermissionService: Some permissions denied: $denied');
        return PermissionResult.partiallyDenied(
          grantedPermissions: granted,
          deniedPermissions: denied,
          message: 'Some permissions were denied',
        );
      }

    } catch (e) {
      debugPrint('PermissionService: Error requesting permissions: $e');
      return PermissionResult.error(
        message: 'Failed to request permissions: $e',
      );
    }
  }

  @override
  Future<PermissionResult> requestSinglePermission(PermissionType permission) async {
    return requestPermissions([permission]);
  }

  @override
  Future<bool> hasPermission(PermissionType permission) async {
    try {
      // Check cache first
      if (_isCacheValid() && _permissionCache.containsKey(permission)) {
        return _permissionCache[permission]!;
      }

      if (!await _isPermissionRequiredForPlatform(permission)) {
        _permissionCache[permission] = true;
        return true;
      }

      final platformPermission = _permissionMap[permission];
      if (platformPermission == null) {
        _permissionCache[permission] = false;
        return false;
      }

      final status = await platformPermission.status;
      final hasPermission = status == PermissionStatus.granted;

      _permissionCache[permission] = hasPermission;
      _lastCacheUpdate = DateTime.now();

      return hasPermission;
    } catch (e) {
      debugPrint('PermissionService: Error checking permission $permission: $e');
      return false;
    }
  }

  @override
  Future<bool> hasAllPermissions(List<PermissionType> permissions) async {
    try {
      // Check cache for all permissions first
      if (_isCacheValid()) {
        final allCached = permissions.every((p) => _permissionCache.containsKey(p));
        if (allCached) {
          return permissions.every((p) => _permissionCache[p] == true);
        }
      }

      // Check permissions individually
      for (final permission in permissions) {
        if (!await hasPermission(permission)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('PermissionService: Error checking permissions: $e');
      return false;
    }
  }

  @override
  Future<bool> shouldShowRationale(PermissionType permission) async {
    try {
      if (!Platform.isAndroid) return false;

      final platformPermission = _permissionMap[permission];
      if (platformPermission == null) return false;

      final status = await platformPermission.status;
      return status == PermissionStatus.denied;
    } catch (e) {
      debugPrint('PermissionService: Error checking rationale for $permission: $e');
      return false;
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      // Clear cache when opening settings as user might change permissions
      _clearCache();
      await openAppSettings();
    } catch (e) {
      debugPrint('PermissionService: Error opening app settings: $e');
    }
  }

  // Helper method to check single permission status
  Future<PermissionStatus> _checkSinglePermissionStatus(PermissionType permission) async {
    if (!await _isPermissionRequiredForPlatform(permission)) {
      return PermissionStatus.granted;
    }

    final platformPermission = _permissionMap[permission];
    if (platformPermission == null) return PermissionStatus.denied;

    return await platformPermission.status;
  }

  // Cache management methods
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  void _updatePermissionCache(List<PermissionType> permissions, bool granted) {
    for (final permission in permissions) {
      _permissionCache[permission] = granted;
    }
    _lastCacheUpdate = DateTime.now();
  }

  void _clearCache() {
    _permissionCache.clear();
    _lastCacheUpdate = null;
  }

  Future<List<PermissionType>> _filterPermissionsForPlatform(List<PermissionType> permissions) async {
    final List<PermissionType> filtered = [];

    for (final permission in permissions) {
      if (await _isPermissionRequiredForPlatform(permission)) {
        filtered.add(permission);
      }
    }

    return filtered;
  }

  Future<bool> _isPermissionRequiredForPlatform(PermissionType permission) async {
    if (Platform.isIOS) {
      switch (permission) {
        case PermissionType.storage:
        case PermissionType.manageExternalStorage:
          return false; // Not needed on iOS
        case PermissionType.photos:
        case PermissionType.camera:
        case PermissionType.microphone:
        case PermissionType.notification:
          return true;
        case PermissionType.videos:
        case PermissionType.audio:
          return false; // Photos permission covers these on iOS
      }
    } else if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();

      switch (permission) {
        case PermissionType.storage:
          return androidVersion < 33; // Not needed on Android 13+
        case PermissionType.manageExternalStorage:
          return androidVersion >= 30; // Android 11+
        case PermissionType.videos:
        case PermissionType.audio:
          return androidVersion >= 33; // Android 13+
        case PermissionType.photos:
          return androidVersion >= 33; // Android 13+
        case PermissionType.camera:
        case PermissionType.microphone:
        case PermissionType.notification:
          return true;
      }
    }

    return false;
  }

  Future<int> _getAndroidVersion() async {
    if (_cachedAndroidVersion != null) {
      return _cachedAndroidVersion!;
    }

    if (!Platform.isAndroid) {
      return 0;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _cachedAndroidVersion = androidInfo.version.sdkInt;

      debugPrint('PermissionService: Detected Android SDK version: $_cachedAndroidVersion');
      return _cachedAndroidVersion!;
    } catch (e) {
      debugPrint('Error getting Android version: $e');
      _cachedAndroidVersion = 33; // Default to Android 13
      return _cachedAndroidVersion!;
    }
  }

  // Method to invalidate cache when app comes to foreground
  void invalidateCache() {
    _clearCache();
  }
}
