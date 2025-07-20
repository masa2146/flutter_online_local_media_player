import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/permission_config.dart';
import '../../../../core/models/permission_result.dart';
import '../../../../core/services/permission_service.dart';

class PermissionDialog extends StatefulWidget {
  final List<PermissionType> requiredPermissions;
  final List<PermissionType> optionalPermissions;
  final String title;
  final String subtitle;
  final VoidCallback? onComplete;
  final Function(PermissionResult)? onResult;

  const PermissionDialog({
    super.key,
    required this.requiredPermissions,
    this.optionalPermissions = const [],
    this.title = 'Permissions Required',
    this.subtitle = 'Please grant the following permissions to continue',
    this.onComplete,
    this.onResult,
  });

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();

  static Future<PermissionResult?> show({
    required BuildContext context,
    required List<PermissionType> requiredPermissions,
    List<PermissionType> optionalPermissions = const [],
    String title = 'Permissions Required',
    String subtitle = 'Please grant the following permissions to continue',
  }) {
    return showDialog<PermissionResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionDialog(
        requiredPermissions: requiredPermissions,
        optionalPermissions: optionalPermissions,
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}

class _PermissionDialogState extends State<PermissionDialog> {
  final PermissionService _permissionService = PermissionServiceImpl();
  bool _isLoading = false;
  PermissionResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    final allPermissions = [
      ...widget.requiredPermissions,
      ...widget.optionalPermissions,
    ];

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              if (widget.requiredPermissions.isNotEmpty) ...[
                const Text(
                  'Required Permissions:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...widget.requiredPermissions.map(
                      (permission) => _buildPermissionItem(permission, isRequired: true),
                ),
              ],

              if (widget.optionalPermissions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Optional Permissions:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...widget.optionalPermissions.map(
                      (permission) => _buildPermissionItem(permission, isRequired: false),
                ),
              ],

              if (_lastResult != null && !_lastResult!.canProceed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastResult!.message,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (_lastResult?.isPermanentlyDenied == true)
            TextButton(
              onPressed: _openSettings,
              child: const Text('Open Settings'),
            ),

          TextButton(
            onPressed: _isLoading ? null : _handleCancel,
            child: const Text('Cancel'),
          ),

          ElevatedButton(
            onPressed: _isLoading ? null : _handleAllow,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text('Allow'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(PermissionType permission, {required bool isRequired}) {
    final config = PermissionConfig.getConfig(permission);
    if (config == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isRequired
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                config.icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        config.title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (!isRequired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  config.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAllow() async {
    setState(() => _isLoading = true);

    try {
      HapticFeedback.lightImpact();

      final allPermissions = [
        ...widget.requiredPermissions,
        ...widget.optionalPermissions,
      ];

      final result = await _permissionService.requestPermissions(allPermissions);

      setState(() {
        _lastResult = result;
        _isLoading = false;
      });

      widget.onResult?.call(result);

      if (result.canProceed) {
        widget.onComplete?.call();
        if (mounted) {
          Navigator.of(context).pop(result);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to request permissions: $e');
    }
  }

  void _handleCancel() {
    HapticFeedback.lightImpact();
    final result = PermissionResult.error(
      message: 'Permission request cancelled by user',
    );
    widget.onResult?.call(result);
    Navigator.of(context).pop(result);
  }

  Future<void> _openSettings() async {
    HapticFeedback.mediumImpact();
    await _permissionService.openAppSettings();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}
