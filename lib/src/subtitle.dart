class Subtitle {
  const Subtitle({required this.ranges});

  factory Subtitle.empty() {
    return const Subtitle(ranges: []);
  }

  /// Constructs [Subtitle] from WebVTT [content]
  factory Subtitle.fromWebVTT(String content) {
    List<String> splits = content.split('\n');
    if (splits[0] != 'WEBVTT' && splits[1].trim().isNotEmpty) {
      return Subtitle.empty();
    }

    splits.removeAt(0);
    splits.removeWhere((e) => e.trim().isEmpty);

    if (splits.length.isOdd) return Subtitle.empty();

    List<SubtitleRange> ranges = [];

    for (int i = 0; i < splits.length; i += 2) {
      ranges.add(SubtitleRange.fromWebVTT(splits[i], splits[i + 1]));
    }

    return Subtitle(ranges: ranges);
  }

  /// Constructs [Subtitle] from SubRip [content]
  factory Subtitle.fromSubRip(String content) {
    List<String> splits = content.split('\n');
    if (!RegExp(r'^[01]$').hasMatch(splits[0])) {
      return Subtitle.empty();
    }

    splits.removeWhere((e) => e.trim().isEmpty);

    if (splits.length % 3 != 0) return Subtitle.empty();

    List<SubtitleRange> ranges = [];

    for (int i = 0; i < splits.length; i += 3) {
      ranges.add(SubtitleRange.fromSubRip(splits[i + 1], splits[i + 2]));
    }

    return Subtitle(ranges: ranges);
  }

  /// Constructs [Subtitle] from LRC [content]
  factory Subtitle.fromLyrics(String content) {
    final matches = RegExp(r'\[\d{2}:\d{2}.\d{2}\].+').allMatches(content);

    List<SubtitleRange> ranges = [];
    for (int i = 0; i < matches.length; i++) {
      ranges.add(
        SubtitleRange.fromLyrics(
          matches.elementAt(i).group(0)!,
          i != matches.length - 1 ? matches.elementAt(i + 1).group(0)! : null,
        ),
      );
    }

    return Subtitle(ranges: ranges);
  }

  final List<SubtitleRange> ranges;

  SubtitleRangeSearchResult findSubtitleRangeAt(Duration position) {
    if (position >= Duration.zero && ranges.first.start > position) {
      return SubtitleRangeSearchResult(
        index: 0,
        subtitleRange: ranges.first,
      );
    }

    if (position > ranges.last.start && ranges.last.end == Duration.zero) {
      return SubtitleRangeSearchResult(
        index: ranges.length - 1,
        subtitleRange: ranges.last,
      );
    }

    if (position == Duration.zero) {
      return SubtitleRangeSearchResult(
        index: 0,
        subtitleRange: ranges.first,
      );
    }

    final a = ranges.indexWhere((range) => range.start == position);
    if (a >= 0) {
      return SubtitleRangeSearchResult(
        index: a,
        subtitleRange: ranges[a],
      );
    }

    final b = ranges.indexWhere(
      (range) => range.start < position && range.end >= position,
    );
    if (b >= 0) {
      return SubtitleRangeSearchResult(
        index: b,
        subtitleRange: ranges[b],
      );
    }

    for (int i = 0; i < ranges.length - 2; i++) {
      final rangeA = ranges[i];
      final rangeB = ranges[i + 1];

      if (rangeA.end <= position && rangeB.start > position) {
        return SubtitleRangeSearchResult(
          index: i + 1,
          subtitleRange: rangeB,
        );
      }
    }

    return SubtitleRangeSearchResult.empty();
  }

  @override
  int get hashCode => Object.hashAll(ranges);

  @override
  bool operator ==(Object other) {
    return other is Subtitle &&
        other.ranges.every((element) => ranges.contains(element));
  }

  @override
  String toString() {
    return 'Subtitle(ranges: $ranges)';
  }
}

class SubtitleRangeSearchResult {
  const SubtitleRangeSearchResult({
    required this.index,
    this.subtitleRange,
  });

  factory SubtitleRangeSearchResult.empty() {
    return SubtitleRangeSearchResult(index: -1);
  }

  final int index;
  final SubtitleRange? subtitleRange;

  @override
  int get hashCode => Object.hashAll([index, subtitleRange]);

  @override
  bool operator ==(Object other) {
    return other is SubtitleRangeSearchResult &&
        other.index == index &&
        other.subtitleRange == subtitleRange;
  }

  @override
  String toString() {
    return 'SubtitleRangeSearchResult(index: $index, subtitleRange: $subtitleRange)';
  }
}

class SubtitleRange {
  const SubtitleRange({
    required this.start,
    required this.end,
    required this.subtitle,
  });

  factory SubtitleRange.fromSubRip(String time, String subtitleText) {
    final split = time.split('-->');
    return SubtitleRange(
      start: _parseSubRipTimestamp(split.first),
      end: _parseSubRipTimestamp(split.last),
      subtitle: subtitleText,
    );
  }

  factory SubtitleRange.fromWebVTT(String time, String subtitleText) {
    final split = time.split('-->');
    return SubtitleRange(
      start: _parseWebVTTTimestamp(split.first),
      end: _parseWebVTTTimestamp(split.last),
      subtitle: subtitleText,
    );
  }

  factory SubtitleRange.fromLyrics(String line, String? nextLine) {
    final lyricsRegex = RegExp(r'(\[\d{2}:\d{2}.\d{2}\])(.+)');
    final match = lyricsRegex.firstMatch(line)!;
    final startTime = match.group(1)!.replaceAll(RegExp('\\[|\\]'), '');

    final startTimeSplits = startTime.split(':');
    final startMinutes = int.parse(startTimeSplits.first);

    final otherTimeSegment = startTimeSplits.last.split('.');
    final startSeconds = int.parse(otherTimeSegment.first);
    final startMilliseconds = int.parse(otherTimeSegment.last);

    Duration end = Duration.zero;

    if (nextLine != null) {
      final match = lyricsRegex.firstMatch(nextLine)!;
      final endTime = match.group(1)!.replaceAll(RegExp('\\[|\\]'), '');

      final endTimeSplits = endTime.split(':');
      final endMinutes = int.parse(endTimeSplits.first);

      final otherTimeSegment = endTimeSplits.last.split('.');
      final endSeconds = int.parse(otherTimeSegment.first);
      final endMilliseconds = int.parse(otherTimeSegment.last);

      end = Duration(
        minutes: endMinutes,
        seconds: endSeconds,
        milliseconds: endMilliseconds,
      );
    }

    return SubtitleRange(
      start: Duration(
        minutes: startMinutes,
        seconds: startSeconds,
        milliseconds: startMilliseconds,
      ),
      end: end,
      subtitle: match.group(2)!,
    );
  }

  final Duration start;
  final Duration end;
  final String subtitle;

  static Duration _parseWebVTTTimestamp(String timestamp) {
    final millisecSegment = timestamp.split('.');
    final otherSegment = millisecSegment.first.split(':');

    return Duration(
      hours: int.tryParse(otherSegment[0]) ?? 0,
      minutes: int.tryParse(otherSegment[1]) ?? 0,
      seconds: int.tryParse(otherSegment[2]) ?? 0,
      milliseconds: int.tryParse(millisecSegment.last) ?? 0,
    );
  }

  static Duration _parseSubRipTimestamp(String timestamp) {
    final millisecSegment = timestamp.split(',');
    final otherSegment = millisecSegment.first.split(':');

    return Duration(
      hours: int.tryParse(otherSegment[0]) ?? 0,
      minutes: int.tryParse(otherSegment[1]) ?? 0,
      seconds: int.tryParse(otherSegment[2]) ?? 0,
      milliseconds: int.tryParse(millisecSegment.last) ?? 0,
    );
  }

  @override
  int get hashCode => Object.hashAll([start, end, subtitle]);

  @override
  bool operator ==(Object other) {
    return other is SubtitleRange &&
        other.start == start &&
        other.end == end &&
        other.subtitle == subtitle;
  }

  @override
  String toString() {
    return 'SubtitleRange(start: $start, end: $end, subtitle: $subtitle)';
  }
}
