import 'package:equatable/equatable.dart';
import 'permission_config.dart';

enum PermissionResultType {
  success,
  partiallyDenied,
  permanentlyDenied,
  error,
}

class PermissionResult extends Equatable {
  final PermissionResultType type;
  final List<PermissionType> grantedPermissions;
  final List<PermissionType> deniedPermissions;
  final String message;
  final bool canProceed;

  const PermissionResult({
    required this.type,
    this.grantedPermissions = const [],
    this.deniedPermissions = const [],
    required this.message,
    required this.canProceed,
  });

  factory PermissionResult.success({
    required List<PermissionType> grantedPermissions,
    required String message,
  }) {
    return PermissionResult(
      type: PermissionResultType.success,
      grantedPermissions: grantedPermissions,
      message: message,
      canProceed: true,
    );
  }

  factory PermissionResult.partiallyDenied({
    required List<PermissionType> grantedPermissions,
    required List<PermissionType> deniedPermissions,
    required String message,
  }) {
    return PermissionResult(
      type: PermissionResultType.partiallyDenied,
      grantedPermissions: grantedPermissions,
      deniedPermissions: deniedPermissions,
      message: message,
      canProceed: grantedPermissions.isNotEmpty,
    );
  }

  factory PermissionResult.permanentlyDenied({
    required List<PermissionType> deniedPermissions,
    required String message,
  }) {
    return PermissionResult(
      type: PermissionResultType.permanentlyDenied,
      deniedPermissions: deniedPermissions,
      message: message,
      canProceed: false,
    );
  }

  factory PermissionResult.error({
    required String message,
  }) {
    return PermissionResult(
      type: PermissionResultType.error,
      message: message,
      canProceed: false,
    );
  }

  bool get isSuccess => type == PermissionResultType.success;
  bool get hasErrors => type == PermissionResultType.error;
  bool get isPermanentlyDenied => type == PermissionResultType.permanentlyDenied;
  bool get isPartiallyDenied => type == PermissionResultType.partiallyDenied;

  @override
  List<Object?> get props => [
    type,
    grantedPermissions,
    deniedPermissions,
    message,
    canProceed,
  ];
}
