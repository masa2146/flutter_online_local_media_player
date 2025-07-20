import '../entities/media_item.dart';
import '../repositories/media_player_repository.dart';
import '../../../../core/utils/result.dart';
import 'base_usecase.dart';

class PlayMediaUseCase extends UseCase<void, PlayMediaParams> {
  final MediaPlayerRepository repository;

  PlayMediaUseCase(this.repository);

  @override
  Future<Result<void>> call(PlayMediaParams params) async {
    final loadResult = await repository.loadMedia(params.mediaItem);
    if (loadResult.isError) return loadResult;

    return await repository.play();
  }
}

class PlayMediaParams {
  final MediaItem mediaItem;

  const PlayMediaParams(this.mediaItem);
}

class PlayUseCase extends UseCase<void, NoParams> {
  final MediaPlayerRepository repository;

  PlayUseCase(this.repository);

  @override
  Future<Result<void>> call(NoParams params) => repository.play();
}

class PauseUseCase extends UseCase<void, NoParams> {
  final MediaPlayerRepository repository;

  PauseUseCase(this.repository);

  @override
  Future<Result<void>> call(NoParams params) => repository.pause();
}

class SeekToUseCase extends UseCase<void, SeekToParams> {
  final MediaPlayerRepository repository;

  SeekToUseCase(this.repository);

  @override
  Future<Result<void>> call(SeekToParams params) => repository.seekTo(params.position);
}

class SeekToParams {
  final Duration position;

  const SeekToParams(this.position);
}
