# Modern Media Player 🎵🎬

A feature-rich, modern media player built with Flutter that supports both local and network media files with synchronized audio/video playback capabilities.

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-21+-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-12+-000000?style=for-the-badge&logo=apple&logoColor=white)

## ✨ Features

### 🎯 **Core Functionality**
- **Dual Media Support**: Play video-only, audio-only, or synchronized video+audio streams
- **Network Streaming**: Support for HTTP/HTTPS URLs
- **Local File Playback**: Play media files from device storage
- **Format Support**: MP4, AVI, MOV, MKV, WebM, MP3, AAC, WAV, FLAC, M4A
- **YouTube-Style Playback**: Separate video and audio stream synchronization

### 🎮 **Player Controls**
- **Full-Screen Player**: Immersive playback experience
- **Mini Player**: Persistent bottom player with essential controls
- **Gesture Controls**: Double-tap to seek (±10s), swipe to minimize
- **Auto-Hide UI**: Controls automatically hide after 4 seconds
- **Orientation Support**: Landscape and portrait modes
- **Volume Control**: Real-time volume adjustment with visual feedback

### 📱 **User Interface**
- **Material 3 Design**: Modern, clean interface
- **Dark Theme**: Eye-friendly dark mode
- **Smooth Animations**: 60fps transitions and interactions
- **Haptic Feedback**: Native iOS/Android feedback
- **Hero Animations**: Seamless screen transitions
- **Smart Permission Management**: User-friendly permission handling

### ⚡ **Performance Features**
- **Stream Synchronization**: ±100ms tolerance for separate audio/video streams
- **Optimized Rebuilds**: Selective UI updates for better performance
- **Resource Management**: Proper disposal to prevent memory leaks
- **Debounced Operations**: Smooth seeking and volume adjustments
- **Permission Caching**: Smart permission status caching

## 📱 Screenshots

```
[Home Page]     [Full Screen]     [Mini Player]
   📱              🎬               🎵
   ┌─────────┐    ┌─────────┐      ┌─────────┐
   │ URL/File│    │         │      │ ████████│
   │  Input  │    │  Video  │      │ ♪ Title │
   │         │    │  Player │      │ ⏮ ⏯ ⏭  │
   │ [Play]  │    │         │      └─────────┘
   └─────────┘    └─────────┘
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Dart SDK 3.0+
- Android Studio / VS Code
- iOS Simulator / Android Emulator

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/modern_media_player.git
cd modern_media_player
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
# For Android
flutter run

# For iOS
flutter run -d ios
```

## 🔧 Configuration

### Android Setup

#### 1. **Update `android/app/build.gradle`**
```gradle
android {
    compileSdk 34
    
    defaultConfig {
        minSdkVersion 21  // Required for modern media features
        targetSdkVersion 34
        
        // Enable multidex if needed
        multiDexEnabled true
    }
}

dependencies {
    implementation 'androidx.media:media:1.7.0'
    implementation 'androidx.work:work-runtime:2.8.1'
}
```

#### 2. **Add permissions to `android/app/src/main/AndroidManifest.xml`**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    
    <!-- Internet permissions for streaming -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Storage permissions for local files -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
        android:maxSdkVersion="28" />
    
    <!-- Android 13+ (API 33+) granular media permissions -->
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    
    <!-- Android 11+ (API 30+) manage external storage -->
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" 
        tools:ignore="ScopedStorage" />
    
    <!-- Media playback permissions -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
    
    <application
        android:label="Modern Media Player"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true"
        android:preserveLegacyExternalStorage="true"
        android:usesCleartextTraffic="true"
        android:hardwareAccelerated="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <!-- Standard app launch intent -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            
            <!-- Handle media file opening -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                
                <!-- Video file types -->
                <data android:mimeType="video/mp4" />
                <data android:mimeType="video/avi" />
                <data android:mimeType="video/mov" />
                <data android:mimeType="video/mkv" />
                <data android:mimeType="video/webm" />
                <data android:mimeType="video/m4v" />
                
                <!-- Audio file types -->
                <data android:mimeType="audio/mp3" />
                <data android:mimeType="audio/mp4" />
                <data android:mimeType="audio/mpeg" />
                <data android:mimeType="audio/aac" />
                <data android:mimeType="audio/wav" />
                <data android:mimeType="audio/flac" />
                <data android:mimeType="audio/m4a" />
            </intent-filter>
        </activity>

        <!-- File provider for sharing media files -->
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>
    </application>
    
    <!-- Declare queries for file types -->
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:mimeType="video/*" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:mimeType="audio/*" />
        </intent>
    </queries>
</manifest>
```

#### 3. **Create `android/app/src/main/res/xml/file_paths.xml`**
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-files-path name="external_files" path="."/>
    <external-cache-path name="external_cache" path="."/>
    <files-path name="files" path="."/>
    <cache-path name="cache" path="."/>
    <external-path name="external" path="."/>
    <external-media-path name="external_media" path="."/>
</paths>
```

#### 4. **Add Proguard rules (android/app/proguard-rules.pro)**
```pro
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Just Audio
-keep class com.ryanheise.just_audio.** { *; }

# Video Player
-keep class io.flutter.plugins.videoplayer.** { *; }

# ExoPlayer
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
```

### iOS Setup

#### 1. **Update `ios/Runner/Info.plist`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing keys... -->
    
    <!-- Photo Library Access -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app needs photo library access to select media files and display album artwork</string>
    
    <!-- Camera Access (optional) -->
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to record videos</string>
    
    <!-- Microphone Access (optional) -->
    <key>NSMicrophoneUsageDescription</key>
    <string>This app needs microphone access to record audio</string>
    
    <!-- Files and Documents -->
    <key>LSSupportsOpeningDocumentsInPlace</key>
    <true/>
    <key>UIFileSharingEnabled</key>
    <true/>
    
    <!-- Supported file types -->
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Video Files</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.movie</string>
                <string>public.video</string>
                <string>com.apple.quicktime-movie</string>
                <string>public.mpeg-4</string>
            </array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Audio Files</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.audio</string>
                <string>public.mp3</string>
                <string>public.mpeg-4-audio</string>
                <string>com.apple.m4a-audio</string>
            </array>
        </dict>
    </array>
    
    <!-- Background audio playback -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
        <string>background-processing</string>
    </array>
    
    <!-- Network security for HTTP URLs -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
```

#### 2. **Update iOS deployment target**
In `ios/Podfile`:
```ruby
platform :ios, '12.0'  # Minimum iOS version
```

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Media Players
  just_audio: ^0.9.35
  video_player: ^2.7.2
  
  # Dependency Injection
  get_it: ^7.6.4
  injectable: ^2.3.2
  
  # File Operations
  file_picker: ^6.1.1
  path_provider: ^2.1.1
  permission_handler: ^11.0.1
  
  # UI & Caching
  cached_network_image: ^3.3.0
  flutter_svg: ^2.0.7
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  build_runner: ^2.4.7
  injectable_generator: ^2.4.1
  mockito: ^5.4.2
```

## 🏗️ Architecture

This project follows **Clean Architecture** principles with the following layers:

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── services/
│   └── utils/
├── features/
│   ├── media_player/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   └── permissions/
│       └── presentation/
│           ├── managers/
│           └── widgets/
└── injection_container.dart
```

### Key Components:

- **Domain Layer**: Business logic and entities
- **Data Layer**: External data sources and repository implementations
- **Presentation Layer**: UI components and state management (BLoC)
- **Core Layer**: Shared utilities and services

## 🎮 Usage

### Playing Media from URLs

```dart
// Single video URL (with embedded audio)
final videoMedia = MediaItem(
  id: '1',
  title: 'Sample Video',
  videoUrl: 'https://example.com/video.mp4',
  type: MediaType.video,
  source: MediaSource.network,
);

// Synchronized video + separate audio
final syncMedia = MediaItem(
  id: '2',
  title: 'YouTube-style Media',
  videoUrl: 'https://example.com/video-no-sound.mp4',
  audioUrl: 'https://example.com/audio.m4a',
  type: MediaType.videoWithSeparateAudio,
  source: MediaSource.network,
);
```

### Playing Local Files

```dart
// Local video file
final localVideo = MediaItem(
  id: '3',
  title: 'Local Video',
  localVideoPath: '/storage/emulated/0/video.mp4',
  type: MediaType.video,
  source: MediaSource.local,
);
```

### Gesture Controls

- **Single Tap**: Toggle controls visibility
- **Double Tap Left**: Seek backward 10 seconds
- **Double Tap Right**: Seek forward 10 seconds
- **Swipe Down**: Minimize to mini player
- **Pinch/Zoom**: Video scaling (future feature)

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Generate test coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 🚀 Building for Release

### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Build for iOS
flutter build ios --release

# Archive for App Store (in Xcode)
# Product > Archive
```

## 🐛 Troubleshooting

### Common Issues

#### **Android: Permission Denied**
- Ensure all permissions are added to AndroidManifest.xml
- Check if target SDK is 34 for Android 14 compatibility
- Test on physical device (emulator may have permission issues)

#### **iOS: File Access Issues**
- Verify Info.plist permissions are correctly set
- Test with iOS 12+ devices
- Check code signing for release builds

#### **Video Not Playing**
- Verify URL is accessible and format is supported
- Check network connectivity for streaming
- Enable hardware acceleration in AndroidManifest.xml

#### **Audio/Video Sync Issues**
- Ensure both streams have similar duration
- Check network stability for streaming
- Try local files to isolate network issues

### Debug Commands
```bash
# Check Flutter doctor
flutter doctor -v

# Clear build cache
flutter clean && flutter pub get

# Verbose logging
flutter run --verbose

# Profile build performance
flutter run --profile
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines

- Follow Flutter/Dart style guide
- Write unit tests for new features
- Update documentation for API changes
- Test on both Android and iOS
- Use conventional commits

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev) for the amazing framework
- [just_audio](https://pub.dev/packages/just_audio) for audio playback
- [video_player](https://pub.dev/packages/video_player) for video playback
- [flutter_bloc](https://pub.dev/packages/flutter_bloc) for state management

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/yourusername/modern_media_player/issues) page
2. Create a new issue with detailed information
3. Include device info, Flutter version, and error logs

---

**Made with ❤️ using Flutter**

For more Flutter resources and tutorials, visit [flutter.dev](https://flutter.dev)
