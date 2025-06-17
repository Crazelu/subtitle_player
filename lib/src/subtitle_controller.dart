import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:subtitle_player/subtitle_player.dart';

/// Holds the subtitle ranges, current subtitle
/// and index of current subtitle at any given point
/// in the synchronization.
class SubtitlePlayerValue {
  const SubtitlePlayerValue({
    required this.subtitleRanges,
    required this.currentSubtitle,
    required this.currentSubtitleIndex,
  });

  factory SubtitlePlayerValue.empty() {
    return const SubtitlePlayerValue(
      subtitleRanges: [],
      currentSubtitle: '',
      currentSubtitleIndex: -1,
    );
  }

  final List<SubtitleRange> subtitleRanges;
  final String currentSubtitle;
  final int currentSubtitleIndex;

  SubtitlePlayerValue copyWith({
    List<SubtitleRange>? subtitleRanges,
    String? currentSubtitle,
    int? currentSubtitleIndex,
  }) {
    return SubtitlePlayerValue(
      subtitleRanges: subtitleRanges ?? this.subtitleRanges,
      currentSubtitle: currentSubtitle ?? this.currentSubtitle,
      currentSubtitleIndex: currentSubtitleIndex ?? this.currentSubtitleIndex,
    );
  }

  @override
  int get hashCode => Object.hashAll([
        subtitleRanges,
        currentSubtitle,
        currentSubtitleIndex,
      ]);

  @override
  bool operator ==(Object other) {
    return other is SubtitlePlayerValue &&
        currentSubtitle == other.currentSubtitle &&
        currentSubtitleIndex == other.currentSubtitleIndex &&
        other.subtitleRanges
            .every((element) => subtitleRanges.contains(element));
  }

  @override
  String toString() {
    return 'SubtitlePlayerValue(currentSubtitleIndex: $currentSubtitleIndex, currentSubtitle: $currentSubtitle, subtitleRanges: $subtitleRanges)';
  }
}

/// Controller for synchronizing song lyrics and subtitles
/// with audio and video players.
class SubtitleController extends ValueNotifier<SubtitlePlayerValue> {
  SubtitleController() : super(SubtitlePlayerValue.empty());

  bool _disposed = false;
  Timer? _timer;
  Timer? _seekTimer;

  Subtitle? _subtitle;

  /// Loaded subtitle for testing purposes.
  @visibleForTesting
  Subtitle? get subtitle => _subtitle;

  int _currentSubtitleRangeIndex = 0;

  num _playbackSpeed = 1;

  /// Playback speed for testing purposes.
  @visibleForTesting
  num get playbackSpeed => _playbackSpeed;

  bool get _abort => _currentSubtitleRangeIndex == -1;

  /// Whether subtitle controller is actively syncing subtitles.
  bool _isPlaying = false;

  /// Load subtitle content.
  ///
  /// Use:
  /// [Subtitle.fromWebVTT] for WebVTT (.vtt) subtitle files
  /// [Subtitle.fromSubRip] for SubRip (.srt) subtitle files
  /// [Subtitle.fromLyrics] for LRC (.lrc) subtitle files
  void loadSubtitle(Subtitle subtitle) {
    _subtitle = subtitle;
    _updateValueSafely(() {
      value = value.copyWith(
        subtitleRanges: subtitle.ranges,
        currentSubtitleIndex: -1,
        currentSubtitle: '',
      );
    });
  }

  /// Sets playback speed.
  ///
  /// Playback speed must not be negative or zero
  /// otherwise playback speed is set to the default value (1).
  void setPlaybackSpeed(num playbackSpeed) {
    if (playbackSpeed <= 0) {
      _playbackSpeed = 1;
    } else {
      _playbackSpeed = playbackSpeed;
    }
  }

  void _queueNextSubtitleRange([bool wait = true]) async {
    final subtitleRanges = _subtitle?.ranges ?? <SubtitleRange>[];

    if (_currentSubtitleRangeIndex >= subtitleRanges.length) {
      _updateValueSafely(() {
        value = value.copyWith(
          currentSubtitle: '',
          currentSubtitleIndex: -1,
        );
      });

      return;
    }

    final subtitleRange = subtitleRanges[_currentSubtitleRangeIndex];

    if (_currentSubtitleRangeIndex == 0 &&
        subtitleRange.start != Duration.zero &&
        wait) {
      await Future.delayed(
        Duration(
          microseconds: subtitleRange.start.inMicroseconds ~/ _playbackSpeed,
        ),
      );
    }

    if (_abort) return;

    _updateValueSafely(() {
      value = value.copyWith(
        currentSubtitle: subtitleRange.subtitle,
        currentSubtitleIndex: _currentSubtitleRangeIndex,
      );
    });

    _timer?.cancel();
    final duration = (subtitleRange.end - subtitleRange.start).abs();

    _timer = Timer(
      Duration(
        microseconds: duration.inMicroseconds ~/ _playbackSpeed,
      ),
      () {
        if (_abort) return;
        _currentSubtitleRangeIndex++;
        _queueNextSubtitleRange();
      },
    );
  }

  /// Starts synchronizing the loaded subtitle.
  ///
  /// If [position] is not `null` or [Duration.zero],
  /// [SubtitleController] seeks to [position] and starts
  /// synchronizing from there.
  void play([Duration? position]) {
    _isPlaying = true;
    if (position != null && position != Duration.zero) {
      seekTo(position);
      return;
    }

    _reset();
    _currentSubtitleRangeIndex = 0;
    _queueNextSubtitleRange();
  }

  /// Pauses subtitle synchronization.
  void pause() {
    _isPlaying = false;
    _reset();
  }

  /// Resets synchronization state and cancels pending timers.
  /// This effectively pauses subtitle synchronizations.
  void _reset() {
    _currentSubtitleRangeIndex = -1;
    _timer?.cancel();
    _seekTimer?.cancel();
  }

  /// Syncs subtitle completely based on playing [position].
  void sync(Duration position) {
    for (int i = 0; i < value.subtitleRanges.length; i++) {
      final range = value.subtitleRanges[i];

      if (position >= range.start && position <= range.end) {
        _updateValueSafely(
          () {
            value = value.copyWith(
              currentSubtitle: range.subtitle,
              currentSubtitleIndex: i,
            );
          },
        );
        return;
      }
    }

    final index = value.subtitleRanges.indexWhere(
      (range) => range.start > position,
    );
    if (index > 0) {
      _updateValueSafely(
        () {
          value = value.copyWith(
            currentSubtitle: value.subtitleRanges[index].subtitle,
            currentSubtitleIndex: index,
          );
        },
      );
    }
  }

  /// Sets the current subtitle synchronization to be at [position].
  void seekTo(Duration position) {
    _reset();

    _updateValueSafely(() {
      value = value.copyWith(
        currentSubtitle: '',
        currentSubtitleIndex: -1,
      );
    });

    final result = _subtitle?.findSubtitleRangeAt(position);
    if (result == null || result.subtitleRange == null) return;

    final subtitleRange = result.subtitleRange!;

    if (subtitleRange.start <= position) {
      _updateValueSafely(() {
        value = value.copyWith(
          currentSubtitle: subtitleRange.subtitle,
          currentSubtitleIndex: result.index,
        );
      });

      if (!_isPlaying) return;

      _seekTimer = Timer(
        Duration(
          microseconds:
              (subtitleRange.end - position).inMicroseconds ~/ _playbackSpeed,
        ),
        () {
          _currentSubtitleRangeIndex = result.index + 1;
          _queueNextSubtitleRange();
        },
      );
    } else {
      if (!_isPlaying) return;
      _seekTimer = Timer(
        Duration(
          microseconds:
              (subtitleRange.start - position).inMicroseconds ~/ _playbackSpeed,
        ),
        () {
          _currentSubtitleRangeIndex = result.index;
          _queueNextSubtitleRange(false);
        },
      );
    }
  }

  /// Only allows updates to [value] when
  ///  [SubtitleController] hasn't been disposed.
  void _updateValueSafely(Function updateCallback) {
    if (!_disposed) updateCallback.call();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _seekTimer?.cancel();
    super.dispose();
  }
}
