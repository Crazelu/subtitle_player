import 'package:example/audio_player_screen.dart';
import 'package:example/video_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Example app test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(TextButton), findsNWidgets(2));
  });

  testWidgets(
    'Test navigation to audio player example',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      expect(find.byType(AudioPlayerScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Test navigation to video player example',
    (WidgetTester tester) async {
      VideoPlayerPlatform.instance = MockVideoPlatform();
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byType(TextButton).first);
      await tester.pump();
      await tester.pump();

      expect(find.byType(VideoPlayerScreen), findsOneWidget);
    },
  );
}

class MockVideoPlatform
    with MockPlatformInterfaceMixin
    implements VideoPlayerPlatform {
  @override
  Future<void> init() {
    return Future.value();
  }

  @override
  Widget buildView(int textureId) {
    return const SizedBox.shrink();
  }

  @override
  Future<int?> create(DataSource dataSource) {
    return Future.value();
  }

  @override
  Future<void> dispose(int textureId) {
    return Future.value();
  }

  @override
  Future<Duration> getPosition(int textureId) {
    return Future.value(Duration.zero);
  }

  @override
  Future<void> pause(int textureId) {
    return Future.value();
  }

  @override
  Future<void> play(int textureId) {
    return Future.value();
  }

  @override
  Future<void> seekTo(int textureId, Duration position) {
    return Future.value();
  }

  @override
  Future<void> setLooping(int textureId, bool looping) {
    return Future.value();
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) {
    return Future.value();
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) {
    return Future.value();
  }

  @override
  Future<void> setVolume(int textureId, double volume) {
    return Future.value();
  }

  @override
  Future<void> setWebOptions(int textureId, VideoPlayerWebOptions options) {
    return Future.value();
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return const Stream.empty();
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    return const SizedBox.shrink();
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) {
    return Future.value(1);
  }

  @override
  Future<void> setAllowBackgroundPlayback(bool allowBackgroundPlayback) {
    return Future.value();
  }
}
