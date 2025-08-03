import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/player_state.dart';

abstract class MediaPlayerDataSource {
  Future<void> initialize(MediaItem mediaItem);

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  Future<void> seekTo(Duration position);

  Future<void> setVolume(double volume);

  Future<void> setSpeed(double speed);

  Stream<PlaybackState> get stateStream;

  Future<void> dispose();
}
