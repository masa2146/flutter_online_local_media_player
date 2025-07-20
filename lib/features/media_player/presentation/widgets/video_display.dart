import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../data/repositories/media_player_repository_impl.dart';
import '../../domain/entities/player_state.dart';
import '../bloc/media_player_bloc.dart';

class VideoDisplay extends StatefulWidget {
  final bool showLoadingIndicator;
  final BoxFit fit;

  const VideoDisplay({
    Key? key,
    this.showLoadingIndicator = true,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  State<VideoDisplay> createState() => _VideoDisplayState();
}

class _VideoDisplayState extends State<VideoDisplay> {
  VideoPlayerController? _controller;
  bool _isControllerInitialized = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaPlayerBloc, MediaPlayerState>(
      builder: (context, state) {
        final repository = context.read<MediaPlayerBloc>().repository;

        if (repository is MediaPlayerRepositoryImpl) {
          _controller = repository.getVideoController();
          _isControllerInitialized = repository.isVideoInitialized;
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: _buildVideoContent(state),
        );
      },
    );
  }

  Widget _buildVideoContent(MediaPlayerState state) {
    if (state.playback.hasError) {
      return _buildErrorWidget(state.playback.error!);
    }

    if (_controller == null || !_isControllerInitialized) {
      return _buildLoadingWidget(state);
    }

    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),

        if (state.playback.isBuffering)
          _buildBufferingOverlay(),
      ],
    );
  }

  Widget _buildLoadingWidget(MediaPlayerState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.showLoadingIndicator) ...[
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
          ],

          Text(
            _getLoadingMessage(state),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),

          if (state.currentMedia != null) ...[
            const SizedBox(height: 8),
            Text(
              state.currentMedia!.title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: 64,
            ),

            const SizedBox(height: 16),

            const Text(
              'Playback Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                // Retry logic would go here
                final bloc = context.read<MediaPlayerBloc>();
                if (bloc.state.currentMedia != null) {
                  // Could implement retry functionality
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBufferingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).primaryColor,
                ),
              ),

              const SizedBox(width: 12),

              const Text(
                'Buffering...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLoadingMessage(MediaPlayerState state) {
    switch (state.playback.status) {
      case PlaybackStatus.loading:
        return 'Loading video...';
      case PlaybackStatus.idle:
        return 'Initializing player...';
      default:
        return 'Preparing video...';
    }
  }
}
