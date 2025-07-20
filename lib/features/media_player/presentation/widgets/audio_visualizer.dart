import 'dart:math';
import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final String title;
  final String? artist;

  const AudioVisualizer({
    Key? key,
    required this.isPlaying,
    required this.title,
    this.artist,
  }) : super(key: key);

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _visualizerController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  final List<AnimationController> _barControllers = [];
  final List<Animation<double>> _barAnimations = [];

  static const int numberOfBars = 20;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupBarAnimations();

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startAnimations();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _stopAnimations();
    }
  }

  @override
  void dispose() {
    _visualizerController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();

    for (final controller in _barControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _setupAnimations() {
    _visualizerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
  }

  void _setupBarAnimations() {
    for (int i = 0; i < numberOfBars; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 300 + (i * 50)),
        vsync: this,
      );

      final animation = Tween<double>(
        begin: 0.1,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));

      _barControllers.add(controller);
      _barAnimations.add(animation);
    }
  }

  void _startAnimations() {
    _visualizerController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();

    for (final controller in _barControllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stopAnimations() {
    _visualizerController.stop();
    _pulseController.stop();
    _rotationController.stop();

    for (final controller in _barControllers) {
      controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Colors.black.withOpacity(0.8),
            Colors.black,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Album artwork placeholder / music icon
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 2 * pi,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.8),
                          Theme.of(context).primaryColor.withOpacity(0.4),
                          Theme.of(context).primaryColor.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Audio visualizer bars
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(numberOfBars, (index) {
                return AnimatedBuilder(
                  animation: _barAnimations[index],
                  builder: (context, child) {
                    final height = 20 + (_barAnimations[index].value * 60);
                    return Container(
                      width: 4,
                      height: widget.isPlaying ? height : 20,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(
                          0.5 + (_barAnimations[index].value * 0.5),
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ),

          const SizedBox(height: 40),

          // Track information
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (widget.artist != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.artist!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 20),

                // Playing indicator
                AnimatedOpacity(
                  opacity: widget.isPlaying ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isPlaying ? Icons.music_note : Icons.pause,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isPlaying ? 'Now Playing' : 'Paused',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
