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
    },
  );
}
