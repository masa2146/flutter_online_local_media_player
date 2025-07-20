import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/media_player/data/datasources/media_player_datasource.dart';
import 'features/media_player/data/repositories/media_player_repository_impl.dart';
import 'features/media_player/domain/entities/player_state.dart';
import 'features/media_player/domain/repositories/media_player_repository.dart';
import 'features/media_player/domain/usecases/play_media_usecase.dart';
import 'features/media_player/presentation/bloc/media_player_bloc.dart';
import 'features/media_player/presentation/pages/home_page.dart';
import 'features/media_player/presentation/widgets/mini_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MediaPlayerApp());
}

class MediaPlayerApp extends StatelessWidget {
  const MediaPlayerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MediaPlayerBloc>(
          create: (context) => _createMediaPlayerBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Media Player',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const MainScreen(),
      ),
    );
  }

  MediaPlayerBloc _createMediaPlayerBloc() {
    // Repository
    final MediaPlayerRepository repository = MediaPlayerRepositoryImpl();

    // Use cases
    final playMediaUseCase = PlayMediaUseCase(repository);
    final playUseCase = PlayUseCase(repository);
    final pauseUseCase = PauseUseCase(repository);
    final seekToUseCase = SeekToUseCase(repository);

    return MediaPlayerBloc(
      repository: repository,
      playMediaUseCase: playMediaUseCase,
      playUseCase: playUseCase,
      pauseUseCase: pauseUseCase,
      seekToUseCase: seekToUseCase,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primarySwatch: Colors.deepPurple,
      primaryColor: const Color(0xFF6366F1),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6366F1),
        secondary: Color(0xFF8B5CF6),
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
        error: Color(0xFFEF4444),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: Color(0xFF6366F1),
        inactiveTrackColor: Color(0xFF374151),
        thumbColor: Color(0xFF6366F1),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaPlayerBloc, MediaPlayerState>(
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              // Ana sayfa içeriği
              const HomePage(),

              // Mini Player - Stack içinde positioned olarak
              if (state.ui.mode == PlayerMode.minimized &&
                  state.hasMedia &&
                  state.currentMedia != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: const MiniPlayer(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
