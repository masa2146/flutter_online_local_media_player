import 'package:flutter/material.dart';

class MediaSourceInput extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool isRequired;

  const MediaSourceInput({
    Key? key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.isRequired = false,
  }) : super(key: key);

  @override
  State<MediaSourceInput> createState() => _MediaSourceInputState();
}

class _MediaSourceInputState extends State<MediaSourceInput> {
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = widget.controller.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.icon,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.isRequired)
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
        Focus(
          onFocusChange: (focused) {
            setState(() {
              _isFocused = focused;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? Theme.of(context).primaryColor
                    : _hasText
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: _isFocused ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: _hasText
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade400,
                  ),
                  onPressed: () {
                    widget.controller.clear();
                  },
                )
                    : null,
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
          ),
        ),
        if (_hasText && widget.controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  _isValidUrl(widget.controller.text)
                      ? Icons.check_circle
                      : Icons.error,
                  size: 16,
                  color: _isValidUrl(widget.controller.text)
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _isValidUrl(widget.controller.text)
                      ? 'Valid URL'
                      : 'Invalid URL format',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isValidUrl(widget.controller.text)
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool _isValidUrl(String url) {
    if (url.trim().isEmpty) return false;

    final uri = Uri.tryParse(url.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
