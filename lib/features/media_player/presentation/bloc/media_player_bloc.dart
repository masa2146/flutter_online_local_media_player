import 'dart:async';

import 'package:bltx_media/core/utils/result.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/media_player_repository_impl.dart';
import '../../domain/entities/player_state.dart';
import '../../domain/repositories/media_player_repository.dart';
import '../../domain/usecases/base_usecase.dart';
import '../../domain/usecases/play_media_usecase.dart';
import 'media_player_event.dart';

class MediaPlayerBloc extends Bloc<MediaPlayerEvent, MediaPlayerState> {
  final MediaPlayerRepository _repository;
  final PlayMediaUseCase _playMediaUseCase;
  final PlayUseCase _playUseCase;
  final PauseUseCase _pauseUseCase;
  final SeekToUseCase _seekToUseCase;

  StreamSubscription? _playbackSubscription;
  StreamSubscription? _mediaSubscription;
  Timer? _controlsHideTimer;

  // Expose repository for video controller access
  MediaPlayerRepository get repository => _repository;

  MediaPlayerBloc({
    required MediaPlayerRepository repository,
    required PlayMediaUseCase playMediaUseCase,
    required PlayUseCase playUseCase,
    required PauseUseCase pauseUseCase,
    required SeekToUseCase seekToUseCase,
  }) : _repository = repository,
        _playMediaUseCase = playMediaUseCase,
        _playUseCase = playUseCase,
        _pauseUseCase = pauseUseCase,
        _seekToUseCase = seekToUseCase,
        super(const MediaPlayerState()) {
    _setupEventHandlers();
  }

  void _setupEventHandlers() {
    on<LoadMediaEvent>(_onLoadMedia);
    on<SetPlaylistEvent>(_onSetPlaylist);
    on<PlayEvent>(_onPlay);
    on<PauseEvent>(_onPause);
    on<TogglePlayPauseEvent>(_onTogglePlayPause);
    on<StopEvent>(_onStop);
    on<SeekToEvent>(_onSeekTo);
    on<SetVolumeEvent>(_onSetVolume);
    on<SkipToNextEvent>(_onSkipToNext);
    on<SkipToPreviousEvent>(_onSkipToPrevious);
    on<ShowControlsEvent>(_onShowControls);
    on<HideControlsEvent>(_onHideControls);
    on<ToggleFullscreenEvent>(_onToggleFullscreen);
    on<SetPlayerModeEvent>(_onSetPlayerMode);
    on<SetBackgroundPlaybackEvent>(_onSetBackgroundPlayback);
    on<RewindEvent>(_onRewind);
    on<FastForwardEvent>(_onFastForward);
  }

  void _listenToRepositoryStreams() {
    _playbackSubscription?.cancel();
    _mediaSubscription?.cancel();

    _playbackSubscription = _repository.playbackStateStream.listen(
          (playbackState) {
        if (!isClosed) {
          emit(state.copyWith(playback: playbackState));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(
            state.copyWith(
              playback: state.playback.copyWith(
                status: PlaybackStatus.error,
                error: error.toString(),
              ),
            ),
          );
        }
      },
    );

    _mediaSubscription = _repository.currentMediaStream.listen(
          (mediaItem) {
        if (!isClosed) {
          emit(state.copyWith(currentMedia: mediaItem));
        }
      },
      onError: (error) {
        debugPrint('Media stream error: $error');
      },
    );
  }

  Future<void> _onLoadMedia(
      LoadMediaEvent event,
      Emitter<MediaPlayerState> emit,
      ) async {
    final result = await _playMediaUseCase(PlayMediaParams(event.mediaItem));

    result.fold(
          (failure) {
        debugPrint('Load media failed: ${failure.message}');
        emit(
          state.copyWith(
            playback: state.playback.copyWith(
              status: PlaybackStatus.error,
              error: failure.message,
            ),
          ),
        );
      },
          (_) {
        emit(
          state.copyWith(
            currentMedia: event.mediaItem,
            playlist: [event.mediaItem],
            currentIndex: 0,
            playback: state.playback.copyWith(
              status: PlaybackStatus.playing,
            ),
          ),
        );

        _listenToRepositoryStreams();
      },
    );
  }

  Future<void> _onSetPlaylist(
      SetPlaylistEvent event,
      Emitter<MediaPlayerState> emit,
      ) async {
    final result = await _repository.setPlaylist(
      event.playlist,
      startIndex: event.startIndex,
    );

    result.fold(
          (failure) => emit(
        state.copyWith(
          playback: state.playback.copyWith(
            status: PlaybackStatus.error,
            error: failure.message,
          ),
        ),
      ),
          (_) => emit(
        state.copyWith(
          playlist: event.playlist,
          currentIndex: event.startIndex,
        ),
      ),
    );
  }

  Future<void> _onPlay(PlayEvent event, Emitter<MediaPlayerState> emit) async {
    final result = await _playUseCase(const NoParams());

    result.fold(
          (failure) {
        debugPrint('Play failed: ${failure.message}');
        emit(
          state.copyWith(
            playback: state.playback.copyWith(
              status: PlaybackStatus.error,
              error: failure.message,
            ),
          ),
        );
      },
          (_) {
        emit(
          state.copyWith(
            playback: state.playback.copyWith(status: PlaybackStatus.playing),
          ),
        );
      },
    );
  }

  Future<void> _onPause(
      PauseEvent event,
      Emitter<MediaPlayerState> emit,
      ) async {
    final result = await _pauseUseCase(const NoParams());

    result.fold(
          (failure) {
        emit(
          state.copyWith(
            playback: state.playback.copyWith(
              status: PlaybackStatus.error,
              error: failure.message,
            ),
          ),
        );
      },
          (_) {
        emit(
          state.copyWith(
            playback: state.playback.copyWith(status: PlaybackStatus.paused),
          ),
        );
      },
    );
  }

  Future<void> _onTogglePlayPause(
      TogglePlayPauseEvent event,
      Emitter<MediaPlayerState> emit,
      ) async {
    if (state.playback.isPlaying) {
      add(const PauseEvent());
    } else {
      add(const PlayEvent());
    }
  }

  Future<void> _onStop(StopEvent event, Emitter<MediaPlayerState> emit) async {
    final result = await _repository.stop();

    result.fold(
          (failure) => emit(
        state.copyWith(
          playback: state.playback.copyWith(
            status: PlaybackStatus.error,
            error: failure.message,
          ),
        ),
      ),
          (_) {
        emit(
          state.copyWith(
            playback: state.playback.copyWith(
              status: PlaybackStatus.stopped,
              position: Duration.zero,
            ),
            currentMedia: null,
          ),
        );
      },
    );
  }

  Future<void> _onSeekTo(
      SeekToEvent event,
      Emitter<MediaPlayerState> emit,
      ) async {
    final result = await _seekToUseCase(SeekToParams(event.position));

    result.fold(
          (failure) => emit(
        state.copyWith(
          playback: state.playback.copyWith(error: failure.message),
        ),
      ),
          (_) {
        emit(
          state.copyWith(
            playback: state.playback.copyWith(position: event.position),
          ),
        );
      },
    );
  }

  Future<void> _onSetVolume(
      SetVolumeEvent event,
      Emitter<MediaPlayerState> emit,
      ) async {
    final result = await _repository.setVolume(event.volume);

    result.fold(
          (failure) => emit(
        state.copyWith(
          playback: state.playback.copyWith(error: failure.message),
        ),
      ),
          (_) {
        emit(
          state.copyWith(
            playback: state.playback.copyWith(volume: event.volume),
          ),
        );
      },
    );
  }

  Future<void> _onSkipToNext(
      SkipToNextEvent event,
      Emitter<MediaPlayerState> emit,
      ) async {
    if (!state.canGoNext) return;

    final result = await _repository.skipToNext();

    result.fold(
          (failure) => emit(
        state.copyWith(
          playback: state.playback.copyWith(error: failure.message),
        ),
      ),
          (_) => emit(state.copyWith(currentIndex: state.currentIndex + 1)),
    );
  }

  Future<void> _onSkipToPrevious(
      SkipToPreviousEvent event,
      Emitter<MediaPlayerState> emit,
      ) async {
    if (!state.canGoPrevious) return;

    final result = await _repository.skipToPrevious();

    result.fold(
          (failure) => emit(
        state.copyWith(
          playback: state.playback.copyWith(error: failure.message),
        ),
      ),
          (_) => emit(
        state.copyWith(
          currentIndex: state.currentIndex == 0 ? 0 : state.currentIndex - 1,
        ),
      ),
    );
  }

  Future<void> _onRewind(
      RewindEvent event,
      Emitter<MediaPlayerState> emit,
      ) async {
    if (_repository is MediaPlayerRepositoryImpl) {
      final result = await (_repository as MediaPlayerRepositoryImpl).rewind();

      result.fold(
            (failure) => emit(
          state.copyWith(
            playback: state.playback.copyWith(error: failure.message),
          ),
        ),
            (_) {
          // State will be updated through playback stream
        },
      );
    }
  }

  Future<void> _onFastForward(
      FastForwardEvent event,
      Emitter<MediaPlayerState> emit,
      ) async {
    if (_repository is MediaPlayerRepositoryImpl) {
      final result = await (_repository as MediaPlayerRepositoryImpl).fastForward();

      result.fold(
            (failure) => emit(
          state.copyWith(
            playback: state.playback.copyWith(error: failure.message),
          ),
        ),
            (_) {
          // State will be updated through playback stream
        },
      );
    }
  }

  void _onShowControls(
      ShowControlsEvent event,
      Emitter<MediaPlayerState> emit,
      ) {
    _controlsHideTimer?.cancel();
    emit(state.copyWith(ui: state.ui.copyWith(showControls: true)));

    _controlsHideTimer = Timer(const Duration(seconds: 5), () {
      if (!isClosed) add(const HideControlsEvent());
    });
  }

  void _onHideControls(
      HideControlsEvent event,
      Emitter<MediaPlayerState> emit,
      ) {
    _controlsHideTimer?.cancel();
    emit(state.copyWith(ui: state.ui.copyWith(showControls: false)));
  }

  void _onToggleFullscreen(
      ToggleFullscreenEvent event,
      Emitter<MediaPlayerState> emit,
      ) {
    final newMode = state.ui.isFullscreen
        ? PlayerMode.minimized
        : PlayerMode.fullscreen;

    emit(
      state.copyWith(
        ui: state.ui.copyWith(
          mode: newMode,
          isFullscreen: newMode == PlayerMode.fullscreen,
        ),
      ),
    );
  }

  void _onSetPlayerMode(
      SetPlayerModeEvent event,
      Emitter<MediaPlayerState> emit,
      ) {
    emit(
      state.copyWith(
        ui: state.ui.copyWith(
          mode: event.mode,
          isFullscreen: event.mode == PlayerMode.fullscreen,
        ),
      ),
    );
  }

  void _onSetBackgroundPlayback(
      SetBackgroundPlaybackEvent event,
      Emitter<MediaPlayerState> emit,
      ) {
    if (_repository is MediaPlayerRepositoryImpl) {
      (_repository as MediaPlayerRepositoryImpl)
          .setBackgroundPlaybackEnabled(event.enabled);

      emit(state.copyWith(
        // Could add a backgroundPlaybackEnabled field to state if needed
      ));
    }
  }

  /// Check if current media is playing in background with notifications
  bool get isPlayingInBackground {
    if (_repository is MediaPlayerRepositoryImpl) {
      return (_repository as MediaPlayerRepositoryImpl).isPlayingInBackground;
    }
    return false;
  }

  @override
  Future<void> close() async {
    _controlsHideTimer?.cancel();
    await _playbackSubscription?.cancel();
    await _mediaSubscription?.cancel();
    await _repository.dispose();

    return super.close();
  }
}
