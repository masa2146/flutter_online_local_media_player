import 'package:flutter/material.dart';
import '../../domain/entities/player_state.dart';

class PlayerControls extends StatefulWidget {
  final PlaybackState playbackState;
  final Function(Duration) onSeekChanged;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final Function(double)? onVolumeChanged;
  final bool showVolumeControl;
  final bool isCompact;

  const PlayerControls({
    super.key,
    required this.playbackState,
    required this.onSeekChanged,
    required this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onVolumeChanged,
    this.showVolumeControl = true,
    this.isCompact = false,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  bool _isSeekingManually = false;
  Duration _seekPosition = Duration.zero;
  bool _showVolumeSlider = false;

  @override
  void initState() {
    super.initState();
    _seekPosition = widget.playbackState.position;
  }

  @override
  void didUpdateWidget(PlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSeekingManually) {
      _seekPosition = widget.playbackState.position;
    }
  }

  void _onSeekStart(double value) {
    setState(() {
      _isSeekingManually = true;
      _seekPosition = Duration(
        milliseconds: (value * widget.playbackState.duration.inMilliseconds).round(),
      );
    });
  }

  void _onSeekChanged(double value) {
    setState(() {
      _seekPosition = Duration(
        milliseconds: (value * widget.playbackState.duration.inMilliseconds).round(),
      );
    });
  }

  void _onSeekEnd(double value) {
    final position = Duration(
      milliseconds: (value * widget.playbackState.duration.inMilliseconds).round(),
    );

    widget.onSeekChanged(position);

    setState(() {
      _isSeekingManually = false;
    });
  }

  void _seek10SecondsBack() {
    final currentPosition = widget.playbackState.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    final clampedPosition = newPosition < Duration.zero
        ? Duration.zero
        : newPosition;
    widget.onSeekChanged(clampedPosition);
  }

  void _seek10SecondsForward() {
    final currentPosition = widget.playbackState.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    final clampedPosition = newPosition > widget.playbackState.duration
        ? widget.playbackState.duration
        : newPosition;
    widget.onSeekChanged(clampedPosition);
  }

  double get _sliderValue {
    if (widget.playbackState.duration.inMilliseconds == 0) return 0.0;

    final position = _isSeekingManually
        ? _seekPosition
        : widget.playbackState.position;

    return (position.inMilliseconds / widget.playbackState.duration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactControls();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress slider and time
          _buildProgressSection(),

          const SizedBox(height: 20),

          // Main controls
          _buildMainControls(),

          if (widget.showVolumeControl) ...[
            const SizedBox(height: 16),
            _buildVolumeControl(),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactControls() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Previous
          if (widget.onPrevious != null)
            IconButton(
              onPressed: widget.onPrevious,
              icon: const Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: 20,
              ),
            ),

          // Seek back
          IconButton(
            onPressed: _seek10SecondsBack,
            icon: const Icon(
              Icons.replay_10,
              color: Colors.white,
              size: 18,
            ),
          ),

          // Play/Pause
          IconButton(
            onPressed: widget.onPlayPause,
            icon: Icon(
              widget.playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 24,
            ),
          ),

          // Seek forward
          IconButton(
            onPressed: _seek10SecondsForward,
            icon: const Icon(
              Icons.forward_10,
              color: Colors.white,
              size: 18,
            ),
          ),

          // Next
          if (widget.onNext != null)
            IconButton(
              onPressed: widget.onNext,
              icon: const Icon(
                Icons.skip_next,
                color: Colors.white,
                size: 20,
              ),
            ),

          // Progress
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: _sliderValue,
                      onChangeStart: _onSeekStart,
                      onChanged: _onSeekChanged,
                      onChangeEnd: _onSeekEnd,
                      activeColor: Theme.of(context).primaryColor,
                      inactiveColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Volume
          if (widget.showVolumeControl && widget.onVolumeChanged != null)
            IconButton(
              onPressed: () {
                setState(() {
                  _showVolumeSlider = !_showVolumeSlider;
                });
              },
              icon: Icon(
                _getVolumeIcon(widget.playbackState.volume),
                color: Colors.white,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 16,
            ),
          ),
          child: Slider(
            value: _sliderValue,
            onChangeStart: _onSeekStart,
            onChanged: _onSeekChanged,
            onChangeEnd: _onSeekEnd,
            activeColor: Theme.of(context).primaryColor,
            inactiveColor: Colors.white.withOpacity(0.3),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSeekingManually
                    ? _formatDuration(_seekPosition)
                    : widget.playbackState.formattedPosition,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                widget.playbackState.formattedDuration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous
        IconButton(
          onPressed: widget.onPrevious,
          icon: Icon(
            Icons.skip_previous,
            color: widget.onPrevious != null ? Colors.white : Colors.grey,
            size: 32,
          ),
        ),

        // Seek back 10s
        IconButton(
          onPressed: _seek10SecondsBack,
          icon: const Icon(
            Icons.replay_10,
            color: Colors.white,
            size: 28,
          ),
        ),

        // Play/Pause
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: widget.onPlayPause,
            icon: Icon(
              widget.playbackState.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),

        // Seek forward 10s
        IconButton(
          onPressed: _seek10SecondsForward,
          icon: const Icon(
            Icons.forward_10,
            color: Colors.white,
            size: 28,
          ),
        ),

        // Next
        IconButton(
          onPressed: widget.onNext,
          icon: Icon(
            Icons.skip_next,
            color: widget.onNext != null ? Colors.white : Colors.grey,
            size: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeControl() {
    return Row(
      children: [
        Icon(
          _getVolumeIcon(widget.playbackState.volume),
          color: Colors.white,
          size: 24,
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                ),
              ),
              child: Slider(
                value: widget.playbackState.volume,
                onChanged: widget.onVolumeChanged,
                activeColor: Theme.of(context).primaryColor,
                inactiveColor: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        ),

        Text(
          '${(widget.playbackState.volume * 100).round()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  IconData _getVolumeIcon(double volume) {
    if (volume == 0) return Icons.volume_mute;
    if (volume < 0.5) return Icons.volume_down;
    return Icons.volume_up;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
