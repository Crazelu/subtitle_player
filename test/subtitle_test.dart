import 'package:subtitle_player/subtitle_player.dart';
import 'package:test/test.dart';

void main() {
  const lrcContent = '''[00:11.20]Your love is bright as ever
[00:17.20]Even in the shadows
[00:23.00]Baby kiss me
[00:27.50]Before they turn the lights out
''';

  const subRipContent = '''0
00:00:11,200 --> 00:00:17,200
Your love is bright as ever

1
00:00:17,200 --> 00:00:23,000
Even in the shadows

2
00:00:23,000 --> 00:00:27,500
Baby kiss me

3
00:00:27,500 --> 00:00:34,200
Before they turn the lights out
''';

  const webVTTContent = '''WEBVTT

00:00:11.200 --> 00:00:17.200
Your love is bright as ever

00:00:17.200 --> 00:00:23.000
Even in the shadows

00:00:23.000 --> 00:00:27.500
Baby kiss me

00:00:27.500 --> 00:00:34.200
Before they turn the lights out
''';

  group(
    'Subtitle tests',
    () {
      test(
        'Verify that subtitles from the same content in different formats '
        'have the same number of SubtitleRange',
        () {
          final lyricsSubtitle = Subtitle.fromLyrics(lrcContent);
          final subRipSubtitle = Subtitle.fromSubRip(subRipContent);
          final webVTTSubtitle = Subtitle.fromWebVTT(webVTTContent);

          expect(lyricsSubtitle.ranges.length, subRipSubtitle.ranges.length);
          expect(subRipSubtitle.ranges.length, webVTTSubtitle.ranges.length);
          expect(lyricsSubtitle.ranges.length, webVTTSubtitle.ranges.length);
        },
      );

      test(
        'Given that subtitles from the same content '
        'in SubRip and WebVTT formats are constructed, '
        'verify that findSubtitleRangeAt returns the same result '
        'on all subtitles given same input',
        () {
          final subRipSubtitle = Subtitle.fromSubRip(subRipContent);
          final webVTTSubtitle = Subtitle.fromWebVTT(webVTTContent);

          expect(
            subRipSubtitle
                .findSubtitleRangeAt(Duration(seconds: 30, milliseconds: 10)),
            webVTTSubtitle
                .findSubtitleRangeAt(Duration(seconds: 30, milliseconds: 10)),
          );
          expect(
            subRipSubtitle.findSubtitleRangeAt(Duration(hours: 1)),
            webVTTSubtitle.findSubtitleRangeAt(Duration(hours: 1)),
          );
        },
      );
      test(
        'Given a subtitle is constructed from LRC, '
        'when findSubtitleRangeAt is called with a duration greater '
        'than the last time stamp in the LRC content, '
        'verify that the last subtitle range is returned',
        () {
          final lyricsSubtitle = Subtitle.fromLyrics(lrcContent);

          expect(
            lyricsSubtitle.findSubtitleRangeAt(Duration(hours: 1)),
            SubtitleRangeSearchResult(
              index: lyricsSubtitle.ranges.length - 1,
              subtitleRange: lyricsSubtitle.ranges.last,
            ),
          );
        },
      );
    },
  );
}
