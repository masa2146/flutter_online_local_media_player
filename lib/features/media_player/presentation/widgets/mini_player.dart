import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/file_utils.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/player_state.dart';
import '../bloc/media_player_bloc.dart';
import '../bloc/media_player_event.dart';
import '../pages/full_screen_player_page.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isDismissing = false;
  bool _isDraggingSeeker = false;
  double _tempSeekPosition = 0.0; // Progress bar'da sürüklerken kullanılacak

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Animation'ı kaldırıyoruz, direkt gösterelim
    _slideController.value = 1.0;
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  void _expandToFullscreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const FullScreenPlayerPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _dismissPlayer() async {
    if (_isDismissing) return;
    _isDismissing = true;

    if (mounted) {
      // Player'ı durdur - bu otomatik olarak state'i temizleyecek
      context.read<MediaPlayerBloc>().add(const StopEvent());

      // Eğer PlayerMode.hidden yoksa, en azından normal mode'a geç
      try {
        context.read<MediaPlayerBloc>().add(
          const SetPlayerModeEvent(PlayerMode.background),
        );
      } catch (e) {
        // PlayerMode.hidden yoksa normal mode kullan
        print('PlayerMode.hidden not found, using alternative');
      }
    }

    // Animation'ı sıfırla
    _slideController.reset();
    _isDismissing = false;
  }

  void _seekBackward() {
    final state = context.read<MediaPlayerBloc>().state;
    final currentPosition = state.playback.position;
    final newPosition = currentPosition - const Duration(seconds: 10);

    context.read<MediaPlayerBloc>().add(
      SeekToEvent(newPosition.isNegative ? Duration.zero : newPosition),
    );
  }

  void _seekForward() {
    final state = context.read<MediaPlayerBloc>().state;
    final currentPosition = state.playback.position;
    final duration = state.playback.duration;
    final newPosition = currentPosition + const Duration(seconds: 10);

    // Duration'dan büyük olmasın
    final clampedPosition = newPosition > duration ? duration : newPosition;

    context.read<MediaPlayerBloc>().add(SeekToEvent(clampedPosition));
  }

  void _onSeekStart(double value, MediaPlayerState state) {
    setState(() {
      _isDraggingSeeker = true;
      _tempSeekPosition = value;
    });
  }

  void _onSeekChanged(double value, MediaPlayerState state) {
    setState(() {
      _tempSeekPosition = value;
    });
  }

  void _onSeekEnd(double value, MediaPlayerState state) {
    final duration = state.playback.duration;
    if (duration > Duration.zero) {
      final newPosition = Duration(
        milliseconds: (duration.inMilliseconds * value).round(),
      );
      context.read<MediaPlayerBloc>().add(SeekToEvent(newPosition));
    }

    setState(() {
      _isDraggingSeeker = false;
      _tempSeekPosition = 0.0;
    });
  }

  double _getCurrentProgress(MediaPlayerState state) {
    if (_isDraggingSeeker) {
      return _tempSeekPosition;
    }
    return state.playback.progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaPlayerBloc, MediaPlayerState>(
      builder: (context, state) {
        if (state.currentMedia == null) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar at the top - Enhanced with drag support
                Container(
                  height: 24, // Biraz daha büyük tap area
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Center(
                    child: Container(
                      height: 6, // Progress bar yüksekliği artırıldı
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.grey.shade800,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Stack(
                          children: [
                            // Background
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey.shade800,
                            ),
                            // Progress indicator
                            FractionallySizedBox(
                              widthFactor: _getCurrentProgress(state),
                              child: Container(
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).primaryColor,
                                      Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Invisible slider for gesture detection
                            Positioned.fill(
                              child: GestureDetector(
                                onTapUp: (details) {
                                  final RenderBox box =
                                      context.findRenderObject() as RenderBox;
                                  final tapPosition = details.localPosition.dx;
                                  final progressWidth = box.size.width;
                                  final progressRatio =
                                      (tapPosition / progressWidth).clamp(
                                        0.0,
                                        1.0,
                                      );

                                  final duration = state.playback.duration;
                                  if (duration > Duration.zero) {
                                    final newPosition = Duration(
                                      milliseconds:
                                          (duration.inMilliseconds *
                                                  progressRatio)
                                              .round(),
                                    );
                                    context.read<MediaPlayerBloc>().add(
                                      SeekToEvent(newPosition),
                                    );
                                  }
                                },
                                onPanStart: (details) {
                                  final RenderBox box =
                                      context.findRenderObject() as RenderBox;
                                  final tapPosition = details.localPosition.dx;
                                  final progressWidth = box.size.width;
                                  final progressRatio =
                                      (tapPosition / progressWidth).clamp(
                                        0.0,
                                        1.0,
                                      );
                                  _onSeekStart(progressRatio, state);
                                },
                                onPanUpdate: (details) {
                                  final RenderBox box =
                                      context.findRenderObject() as RenderBox;
                                  final tapPosition = details.localPosition.dx;
                                  final progressWidth = box.size.width;
                                  final progressRatio =
                                      (tapPosition / progressWidth).clamp(
                                        0.0,
                                        1.0,
                                      );
                                  _onSeekChanged(progressRatio, state);
                                },
                                onPanEnd: (details) {
                                  _onSeekEnd(_tempSeekPosition, state);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Drag handle - padding düzeltildi
                GestureDetector(
                  onTap: _expandToFullscreen,
                  onPanUpdate: (details) {
                    if (details.delta.dy > 5) {
                      _dismissPlayer();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade500,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),

                // Main content
                GestureDetector(
                  onTap: _expandToFullscreen,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        // Media artwork/icon with gradient background
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor.withOpacity(0.3),
                                Theme.of(context).primaryColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            _getMediaIcon(state.currentMedia!.type),
                            color: Theme.of(context).primaryColor,
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Media info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.currentMedia!.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getMediaTypeDescription(
                                  state.currentMedia!.type,
                                ),
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (FileUtils.formatDuration(
                                    state.playback.duration.inSeconds,
                                  ) !=
                                  "0:00") ...[
                                const SizedBox(height: 2),
                                Text(
                                  "${FileUtils.formatDuration(state.playback.position.inSeconds)} / ${FileUtils.formatDuration(state.playback.duration.inSeconds)}",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Control buttons - Yeniden düzenlendi
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Seek backward 10s button
                            _buildControlButton(
                              icon: Icons.replay_10_rounded,
                              onPressed: () => _seekBackward(),
                              size: 18,
                              tooltip: "10s geri",
                            ),

                            const SizedBox(width: 4),

                            // Previous button
                            _buildControlButton(
                              icon: Icons.skip_previous_rounded,
                              onPressed: state.canGoPrevious
                                  ? () {
                                      context.read<MediaPlayerBloc>().add(
                                        const SkipToPreviousEvent(),
                                      );
                                    }
                                  : null,
                              size: 20,
                              tooltip: "Önceki",
                            ),

                            const SizedBox(width: 4),

                            // Play/Pause button - main button
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: () {
                                    context.read<MediaPlayerBloc>().add(
                                      const TogglePlayPauseEvent(),
                                    );
                                  },
                                  child: Icon(
                                    state.playback.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 4),

                            // Next button
                            _buildControlButton(
                              icon: Icons.skip_next_rounded,
                              onPressed: state.canGoNext
                                  ? () {
                                      context.read<MediaPlayerBloc>().add(
                                        const SkipToNextEvent(),
                                      );
                                    }
                                  : null,
                              size: 20,
                              tooltip: "Sonraki",
                            ),

                            const SizedBox(width: 4),

                            // Seek forward 10s button
                            _buildControlButton(
                              icon: Icons.forward_10_rounded,
                              onPressed: () => _seekForward(),
                              size: 18,
                              tooltip: "10s ileri",
                            ),

                            const SizedBox(width: 8),

                            // Close button
                            _buildControlButton(
                              icon: Icons.close_rounded,
                              onPressed: _dismissPlayer,
                              size: 18,
                              color: Colors.grey.shade400,
                              backgroundColor: Colors.grey.shade800.withOpacity(
                                0.3,
                              ),
                              tooltip: "Kapat",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required double size,
    Color? color,
    Color? backgroundColor,
    String? tooltip,
  }) {
    final isEnabled = onPressed != null;
    final buttonColor =
        color ?? (isEnabled ? Colors.white : Colors.grey.shade600);

    Widget button = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Icon(icon, color: buttonColor, size: size),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }

    return button;
  }

  IconData _getMediaIcon(MediaType type) {
    switch (type) {
      case MediaType.video:
        return Icons.videocam_rounded;
      case MediaType.videoWithSeparateAudio:
        return Icons.video_library_rounded;
      case MediaType.audio:
        return Icons.music_note_rounded;
    }
  }

  String _getMediaTypeDescription(MediaType type) {
    switch (type) {
      case MediaType.video:
        return "Video";
      case MediaType.videoWithSeparateAudio:
        return "Video + Audio";
      case MediaType.audio:
        return "Audio";
    }
  }
}
