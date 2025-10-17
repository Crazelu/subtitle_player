import 'package:subtitle_player/subtitle_player.dart';
import 'package:test/test.dart';

void main() {
  const lrcContent = '''
[00:11.20]Your love is bright as ever
[00:17.20]Even in the shadows
[00:23.00]Baby kiss me
[00:27.50]Before they turn the lights out
''';

  group(
    'SubtitleController tests',
    () {
      test(
        'When SubtitleController is constructed, '
        'Verify that it\'s initial value is SubtitlePlayerValue.empty()',
        () {
          final subtitleController = SubtitleController();
          expect(subtitleController.value, SubtitlePlayerValue.empty());
        },
      );

      test(
        'When loadSubtitle is called, '
        'Verify that subtitle in the controller is set correctly',
        () {
          final subtitleController = SubtitleController();
          expect(subtitleController.subtitle, isNull);

          const subtitle = Subtitle(ranges: []);

          subtitleController.loadSubtitle(subtitle);
          expect(subtitleController.subtitle, subtitle);
        },
      );

      test(
        'When loadSubtitle is called, '
        'Verify that SubtitlePlayerValue is updated with the subtitle ranges',
        () {
          final subtitleController = SubtitleController();
          expect(subtitleController.value.subtitleRanges, isEmpty);

          final subtitleRanges = [
            SubtitleRange(
              start: Duration.zero,
              end: Duration.zero,
              subtitle: '',
            ),
          ];
          final subtitle = Subtitle(ranges: subtitleRanges);

          subtitleController.loadSubtitle(subtitle);
          expect(subtitleController.value.subtitleRanges, subtitleRanges);

          final lyricsSubtitle = Subtitle.fromLyrics(lrcContent);
          subtitleController.loadSubtitle(lyricsSubtitle);

          expect(subtitleController.value.subtitleRanges.length, 4);
          expect(subtitleController.value.currentSubtitleIndex, -1);
        },
      );

      test(
        'When setPlaybackSpeed is called with a positive number, '
        'verify that playback speed is set to the number',
        () {
          final subtitleController = SubtitleController();
          expect(subtitleController.playbackSpeed, 1);

          subtitleController.setPlaybackSpeed(2);

          expect(subtitleController.playbackSpeed, 2);
        },
      );

      test(
        'When setPlaybackSpeed is called with a negative number, '
        'verify that playback speed is set to 1',
        () {
          final subtitleController = SubtitleController();
          expect(subtitleController.playbackSpeed, 1);

          subtitleController.setPlaybackSpeed(2);
          expect(subtitleController.playbackSpeed, 2);

          subtitleController.setPlaybackSpeed(-3);
          expect(subtitleController.playbackSpeed, 1);
        },
      );

      test(
        'Given that a subtitle is loaded, '
        'When sync is called with a duration, '
        'Verify that the subtitle line for that duration is updated',
        () {
          final lyricsSubtitle = Subtitle.fromLyrics(lrcContent);
          final controller = SubtitleController();
          controller.loadSubtitle(lyricsSubtitle);

          controller.sync(const Duration(seconds: 23, milliseconds: 100));

          expect(controller.value.currentSubtitleIndex, 2);
          expect(controller.value.currentSubtitle, 'Baby kiss me');

          controller.sync(const Duration(seconds: 18, milliseconds: 200));

          expect(controller.value.currentSubtitleIndex, 1);
          expect(controller.value.currentSubtitle, 'Even in the shadows');
        },
      );

      test(
        'Given that a subtitle is loaded, '
        'When seekTo is called with a duration, '
        'Verify that the subtitle line for that duration is updated',
        () {
          final lyricsSubtitle = Subtitle.fromLyrics(lrcContent);
          final controller = SubtitleController();
          controller.loadSubtitle(lyricsSubtitle);

          controller.seekTo(const Duration(seconds: 27, milliseconds: 600));

          expect(controller.value.currentSubtitleIndex, 3);
          expect(
            controller.value.currentSubtitle,
            'Before they turn the lights out',
          );
        },
      );

      group(
        'Subtitle playing tests | '
        'Given that a subtitle is loaded, ',
        () {
          const lrcContent = '''
[00:00.10]A
[00:00.20]B
[00:00.30]C
[00:00.40]D
''';
          test(
            'When play is called without a duration, '
            'Verify that subtitle sync starts from '
            'the first subtitle range and appropriately moves '
            'to other ranges as time progresses',
            () async {
              final lyricsSubtitle = Subtitle.fromLyrics(lrcContent);
              final controller = SubtitleController();
              controller.loadSubtitle(lyricsSubtitle);

              final subtitleRanges = controller.value.subtitleRanges;

              expect(controller.value.currentSubtitleIndex, -1);
              expect(controller.value.currentSubtitle, '');

              controller.play();
              await Future.delayed(subtitleRanges.first.start);

              for (int i = 0; i < subtitleRanges.length; i++) {
                final range = subtitleRanges[i];

                expect(controller.value.currentSubtitleIndex, i);
                expect(controller.value.currentSubtitle, range.subtitle);

                final waitDuration = range.end - range.start;
                await Future.delayed(waitDuration);
              }

              expect(
                controller.value.currentSubtitleIndex,
                subtitleRanges.length - 1,
              );
              expect(
                controller.value.currentSubtitle,
                subtitleRanges.last.subtitle,
              );
            },
          );

          test(
            'When play is called with a duration, '
            'Verify that subtitle sync starts from '
            'the subtitle range at that duration and appropriately moves '
            'to other ranges as time progresses',
            () async {
              final lyricsSubtitle = Subtitle.fromLyrics(lrcContent);
              final controller = SubtitleController();
              controller.loadSubtitle(lyricsSubtitle);

              final subtitleRanges = controller.value.subtitleRanges;

              expect(controller.value.currentSubtitleIndex, -1);
              expect(controller.value.currentSubtitle, '');

              controller.play(const Duration(milliseconds: 20));

              // playing from 20ms should begin with the second range

              for (int i = 1; i < subtitleRanges.length; i++) {
                final range = subtitleRanges[i];

                expect(controller.value.currentSubtitleIndex, i);
                expect(controller.value.currentSubtitle, range.subtitle);

                final waitDuration = range.end - range.start;
                await Future.delayed(waitDuration);
              }

              expect(
                controller.value.currentSubtitleIndex,
                subtitleRanges.length - 1,
              );
              expect(
                controller.value.currentSubtitle,
                subtitleRanges.last.subtitle,
              );
            },
          );
        },
      );

      test(
        'Given that subtitle is loaded and played, '
        'When pause is called, '
        'Verify that subtitle sync does not progress with time',
        () async {
          const lrcContent = '''
[00:00.10]A
[00:00.20]B
[00:00.30]C
[00:00.40]D
''';

          final lyricsSubtitle = Subtitle.fromLyrics(lrcContent);
          final controller = SubtitleController();
          controller.loadSubtitle(lyricsSubtitle);

          final subtitleRanges = controller.value.subtitleRanges;

          controller.play(const Duration(milliseconds: 20));

          expect(controller.value.currentSubtitleIndex, 1);
          expect(controller.value.currentSubtitle, 'B');

          controller.pause();

          final range = subtitleRanges[1];
          final waitDuration = range.end - range.start;
          await Future.delayed(waitDuration);

          expect(controller.value.currentSubtitleIndex, 1);
          expect(controller.value.currentSubtitle, 'B');

          await Future.delayed(waitDuration);

          expect(controller.value.currentSubtitleIndex, 1);
          expect(controller.value.currentSubtitle, 'B');
        },
      );
    },
  );
}
