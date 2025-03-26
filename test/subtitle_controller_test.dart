import 'package:subtitle_player/subtitle_player.dart';
import 'package:test/test.dart';

void main() {
  group(
    'SubtitleController tests',
    () {
      test(
        'When SubtitleController is constructed, '
        'verify that it\'s initial value is SubtitlePlayerValue.empty()',
        () {
          final subtitleController = SubtitleController();
          expect(subtitleController.value, SubtitlePlayerValue.empty());
        },
      );
      test(
        'When loadSubtitle is called, '
        'verify that subtitle in the controller is set correctly',
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
        'verify that SubtitlePlayerValue is updated with the subtitle ranges',
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
    },
  );
}
