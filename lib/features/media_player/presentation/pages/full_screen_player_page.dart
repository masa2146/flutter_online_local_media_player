import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/media_item.dart';
import '../../domain/entities/player_state.dart';
import '../bloc/media_player_bloc.dart';
import '../bloc/media_player_event.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/player_controls.dart';
import '../widgets/video_display.dart';

class FullScreenPlayerPage extends StatefulWidget {
  const FullScreenPlayerPage({super.key});

  @override
  State<FullScreenPlayerPage> createState() => _FullScreenPlayerPageState();
}

class _FullScreenPlayerPageState extends State<FullScreenPlayerPage>
    with TickerProviderStateMixin {
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsOpacity;

  Timer? _hideControlsTimer;
  bool _isDragging = false;
  bool _controlsVisible = true;

  // Tap handling variables
  Offset? _lastTapPosition;
  int _tapCount = 0;
  Timer? _tapTimer;
  DateTime? _lastTapTime;

  // Drag handling variables
  double _initialDragY = 0;
  static const double _dragThreshold = 80.0;

  // Orientation state
  bool _isLandscapeMode = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _enterFullscreen();
    _startControlsTimer();
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    _hideControlsTimer?.cancel();
    _tapTimer?.cancel();
    _exitFullscreen();
    super.dispose();
  }

  void _setupAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _controlsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Controls başlangıçta görünür olsun
    _controlsAnimationController.value = 1.0;
  }

  void _startControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isDragging) {
        _hideControls();
      }
    });
  }

  void _showControls() {
    if (!_controlsVisible) {
      setState(() {
        _controlsVisible = true;
      });
      _controlsAnimationController.forward();
      context.read<MediaPlayerBloc>().add(const ShowControlsEvent());
    }
    _startControlsTimer();
  }

  void _hideControls() {
    if (_controlsVisible) {
      setState(() {
        _controlsVisible = false;
      });
      _controlsAnimationController.reverse();
      context.read<MediaPlayerBloc>().add(const HideControlsEvent());
    }
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideControls();
    } else {
      _showControls();
    }
  }

  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    context.read<MediaPlayerBloc>().add(
      const SetPlayerModeEvent(PlayerMode.fullscreen),
    );
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void _minimizePlayer() {
    _exitFullscreen();

    context.read<MediaPlayerBloc>().add(
      const SetPlayerModeEvent(PlayerMode.minimized),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _closePlayer() {
    _exitFullscreen();
    context.read<MediaPlayerBloc>().add(const StopEvent());

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscapeMode = !_isLandscapeMode;
    });

    if (_isLandscapeMode) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    final now = DateTime.now();
    final position = details.globalPosition;

    // Reset timer
    _tapTimer?.cancel();

    // Check if this is a double tap
    bool isDoubleTap = false;
    if (_lastTapTime != null && _lastTapPosition != null) {
      final timeDiff = now.difference(_lastTapTime!).inMilliseconds;
      final distance = (position - _lastTapPosition!).distance;

      if (timeDiff < 300 && distance < 50) {
        isDoubleTap = true;
      }
    }

    if (isDoubleTap) {
      _handleDoubleTap(position);
      _lastTapTime = null;
      _lastTapPosition = null;
      _tapCount = 0;
    } else {
      _lastTapTime = now;
      _lastTapPosition = position;
      _tapCount = 1;

      _tapTimer = Timer(const Duration(milliseconds: 300), () {
        if (_tapCount == 1) {
          _toggleControls();
        }
        _tapCount = 0;
        _lastTapTime = null;
        _lastTapPosition = null;
      });
    }
  }

  void _handleDoubleTap(Offset position) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLeftSide = position.dx < screenWidth / 2;
    final currentPosition = _getCurrentPosition();

    if (isLeftSide) {
      final newPosition = currentPosition - const Duration(seconds: 10);
      context.read<MediaPlayerBloc>().add(
        SeekToEvent(newPosition.isNegative ? Duration.zero : newPosition),
      );
      _showSeekFeedback(false);
    } else {
      final newPosition = currentPosition + const Duration(seconds: 10);
      context.read<MediaPlayerBloc>().add(SeekToEvent(newPosition));
      _showSeekFeedback(true);
    }

    _showControls();
  }

  Duration _getCurrentPosition() {
    final state = context.read<MediaPlayerBloc>().state;
    return state.playback.position;
  }

  void _showSeekFeedback(bool forward) {
    // TODO: Show seek feedback animation
    // You can implement a temporary overlay showing +10s or -10s
  }

  void _handlePanStart(DragStartDetails details) {
    _isDragging = true;
    _initialDragY = details.globalPosition.dy;
    _hideControlsTimer?.cancel();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final currentY = details.globalPosition.dy;
    final dragDistance = currentY - _initialDragY;

    if (dragDistance > _dragThreshold) {
      _isDragging = false; // Prevent multiple calls
      _minimizePlayer();
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    _isDragging = false;

    if (details.velocity.pixelsPerSecond.dy > 300) {
      _minimizePlayer();
    } else {
      _startControlsTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaPlayerBloc, MediaPlayerState>(
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) {
              _minimizePlayer();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _handleTapUp,
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              child: Stack(
                children: [
                  // Main content area
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: _buildMediaContent(state),
                  ),

                  // Controls overlay
                  if (_controlsVisible)
                    AnimatedBuilder(
                      animation: _controlsOpacity,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _controlsOpacity.value,
                          child: _buildControlsOverlay(state),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaContent(MediaPlayerState state) {
    if (state.currentMedia == null) {
      return const Center(
        child: Text(
          'No media loaded',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    switch (state.currentMedia!.type) {
      case MediaType.video:
      case MediaType.videoWithSeparateAudio:
        return const VideoDisplay();
      case MediaType.audio:
        return AudioVisualizer(
          isPlaying: state.playback.isPlaying,
          title: state.currentMedia!.title,
          artist: state.currentMedia!.artist,
        );
    }
  }

  Widget _buildControlsOverlay(MediaPlayerState state) {
    return Stack(
      children: [
        Column(
          children: [
            // Top controls bar
            Container(
              color: Colors.transparent,
              child: SafeArea(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _minimizePlayer(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.expand_more,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.currentMedia?.title ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (state.currentMedia?.artist != null)
                                Text(
                                  state.currentMedia!.artist!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _toggleOrientation(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              _isLandscapeMode
                                  ? Icons.screen_lock_portrait
                                  : Icons.screen_lock_landscape,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _closePlayer(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Bottom controls bar
            Container(
              color: Colors.transparent,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: PlayerControls(
                    playbackState: state.playback,
                    onSeekChanged: (position) {
                      Duration clampedPosition = _clampPosition(
                        position,
                        state.playback.duration,
                      );
                      context.read<MediaPlayerBloc>().add(
                        SeekToEvent(clampedPosition),
                      );
                      _showControls();
                    },
                    onPlayPause: () {
                      context.read<MediaPlayerBloc>().add(
                        const TogglePlayPauseEvent(),
                      );
                      _showControls();
                    },
                    onNext: state.canGoNext
                        ? () {
                            context.read<MediaPlayerBloc>().add(
                              const SkipToNextEvent(),
                            );
                            _showControls();
                          }
                        : null,
                    onPrevious: state.canGoPrevious
                        ? () {
                            context.read<MediaPlayerBloc>().add(
                              const SkipToPreviousEvent(),
                            );
                            _showControls();
                          }
                        : null,
                    onVolumeChanged: (volume) {
                      context.read<MediaPlayerBloc>().add(
                        SetVolumeEvent(volume),
                      );
                      _showControls();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Duration _clampPosition(Duration position, Duration duration) {
    if (duration == Duration.zero) return Duration.zero;

    return Duration(
      milliseconds: position.inMilliseconds.clamp(0, duration.inMilliseconds),
    );
  }
}
