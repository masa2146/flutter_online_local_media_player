import 'package:bltx_media/core/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'dart:io';


class FilePickerButton extends StatelessWidget {
  final String label;
  final String? selectedPath;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final IconData icon;
  final bool isOptional;

  const FilePickerButton({
    super.key,
    required this.label,
    required this.selectedPath,
    required this.onTap,
    required this.onClear,
    required this.icon,
    this.isOptional = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isOptional)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedPath != null
                    ? Theme.of(context).primaryColor
                    : Colors.white.withOpacity(0.1),
                width: selectedPath != null ? 2 : 1,
              ),
            ),
            child: selectedPath != null
                ? _buildSelectedFile(context)
                : _buildPlaceholder(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFile(BuildContext context) {
    final fileName = selectedPath!.split('/').last;
    final file = File(selectedPath!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<FileStat>(
                    future: file.stat(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final size = FileUtils.formatFileSize(snapshot.data!.size);
                        return Text(
                          size,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClear,
              icon: Icon(
                Icons.close,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.add,
            color: Colors.grey.shade400,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tap to select file',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isOptional ? 'Optional' : 'Required',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.folder_open,
          color: Colors.grey.shade400,
          size: 20,
        ),
      ],
    );
  }
}
