import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/media_item.dart';
import '../bloc/media_player_bloc.dart';
import '../bloc/media_player_event.dart';
import '../widgets/file_picker_button.dart';
import '../widgets/media_source_input.dart';
import 'full_screen_player_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _audioUrlController = TextEditingController();

  String? _selectedVideoPath;
  String? _selectedAudioPath;

  bool _isUrlMode = true;

  @override
  void dispose() {
    _videoUrlController.dispose();
    _audioUrlController.dispose();
    super.dispose();
  }

  void _playMedia() {
    context.read<MediaPlayerBloc>().add(SetBackgroundPlaybackEvent(true));
    MediaItem? mediaItem;

    if (_isUrlMode) {
      mediaItem = _createMediaItemFromUrls();
    } else {
      mediaItem = _createMediaItemFromFiles();
    }

    if (mediaItem != null) {
      context.read<MediaPlayerBloc>().add(LoadMediaEvent(mediaItem));
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const FullScreenPlayerPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least one media source'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  MediaItem? _createMediaItemFromUrls() {
    final videoUrl = _videoUrlController.text.trim();
    final audioUrl = _audioUrlController.text.trim();

    if (videoUrl.isEmpty && audioUrl.isEmpty) return null;

    MediaType type;
    if (videoUrl.isNotEmpty && audioUrl.isNotEmpty) {
      type = MediaType.videoWithSeparateAudio;
    } else if (videoUrl.isNotEmpty) {
      type = MediaType.video;
    } else {
      type = MediaType.audio;
    }

    return MediaItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _getTitleFromUrl(videoUrl.isNotEmpty ? videoUrl : audioUrl),
      type: type,
      source: MediaSource.network,
      videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
      audioUrl: audioUrl.isNotEmpty ? audioUrl : null,
    );
  }

  MediaItem? _createMediaItemFromFiles() {
    if (_selectedVideoPath == null && _selectedAudioPath == null) return null;

    MediaType type;
    if (_selectedVideoPath != null && _selectedAudioPath != null) {
      type = MediaType.videoWithSeparateAudio;
    } else if (_selectedVideoPath != null) {
      type = MediaType.video;
    } else {
      type = MediaType.audio;
    }

    final mainPath = _selectedVideoPath ?? _selectedAudioPath!;

    return MediaItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _getTitleFromPath(mainPath),
      type: type,
      source: MediaSource.local,
      localVideoPath: _selectedVideoPath,
      localAudioPath: _selectedAudioPath,
    );
  }

  String _getTitleFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'Media';
    }
    return 'Media';
  }

  String _getTitleFromPath(String path) {
    return path.split('/').last;
  }

  Future<void> _pickVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedVideoPath = result.files.single.path!;
      });
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedAudioPath = result.files.single.path!;
      });
    }
  }

  void _clearSelections() {
    setState(() {
      _videoUrlController.clear();
      _audioUrlController.clear();
      _selectedVideoPath = null;
      _selectedAudioPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Media Player',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Toggle
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUrlMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isUrlMode
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'URL Mode',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isUrlMode ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isUrlMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: !_isUrlMode
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Local Files',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isUrlMode ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content based on mode
            if (_isUrlMode) ...[
              MediaSourceInput(
                label: 'Video URL',
                hint: 'Enter video URL (optional)',
                controller: _videoUrlController,
                icon: Icons.video_library,
              ),
              const SizedBox(height: 20),
              MediaSourceInput(
                label: 'Audio URL',
                hint: 'Enter audio URL (optional)',
                controller: _audioUrlController,
                icon: Icons.audio_file,
              ),
            ] else ...[
              FilePickerButton(
                label: 'Select Video File',
                selectedPath: _selectedVideoPath,
                onTap: _pickVideoFile,
                onClear: _clearSelections,
                icon: Icons.video_file,
                isOptional: true,
              ),
              const SizedBox(height: 20),
              FilePickerButton(
                label: 'Select Audio File',
                selectedPath: _selectedAudioPath,
                onTap: _pickAudioFile,
                onClear: _clearSelections,
                icon: Icons.audio_file,
                isOptional: true,
              ),
            ],

            const SizedBox(height: 40),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearSelections,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _playMedia,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Play Media',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How to use:',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Provide video URL only: plays video with audio\n'
                    '• Provide audio URL only: plays audio\n'
                    '• Provide both URLs: synced video + separate audio\n'
                    '• Local files work the same way\n'
                    '• At least one media source is required',
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
