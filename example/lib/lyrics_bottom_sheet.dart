import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:subtitle_player/subtitle_player.dart';

class LyricsBottomSheet extends StatefulWidget {
  const LyricsBottomSheet({
    super.key,
    required this.player,
    required this.subtitleController,
  });

  final AudioPlayer player;
  final SubtitleController subtitleController;

  @override
  State<LyricsBottomSheet> createState() => _LyricsBottomSheetState();
}

class _LyricsBottomSheetState extends State<LyricsBottomSheet> {
  List<GlobalKey> _keys = [];
  static const _paddingCount = 8;

  void _createKeys(int length) {
    if (length > 0 && length != _keys.length - _paddingCount) {
      _keys = List.generate(
        length + _paddingCount,
        (index) => GlobalKey(debugLabel: '$index'),
      );
    }
  }

  void _onSubtitleChanged(int index) {
    Future.microtask(
      () async {
        if (_keys.isEmpty || index == -1) return;

        final nextIndex = index + _paddingCount;
        if (_keys.length - 1 < nextIndex) return;

        GlobalKey key;

        if (index <= _paddingCount) {
          key = _keys[index];
        } else {
          key = _keys[nextIndex];
        }

        final renderObject =
            key.currentContext?.findRenderObject() as RenderBox?;

        renderObject?.showOnScreen(
          duration: const Duration(milliseconds: 350),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.9,
      width: MediaQuery.sizeOf(context).width,
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
        top: 8,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        child: ValueListenableBuilder<SubtitlePlayerValue>(
          valueListenable: widget.subtitleController,
          builder: (context, subtitlePlayerValue, _) {
            _createKeys(subtitlePlayerValue.subtitleRanges.length);
            _onSubtitleChanged(subtitlePlayerValue.currentSubtitleIndex);
            return Column(
              children: [
                for (int i = 0;
                    i < subtitlePlayerValue.subtitleRanges.length;
                    i++) ...{
                  LyricsWidget(
                    key: _keys[i],
                    lyrics: subtitlePlayerValue.subtitleRanges[i].subtitle,
                    active: i == subtitlePlayerValue.currentSubtitleIndex,
                    onTap: () {
                      widget.player
                          .seek(subtitlePlayerValue.subtitleRanges[i].start)
                          .then(
                            (value) => widget.subtitleController.seekTo(
                                subtitlePlayerValue.subtitleRanges[i].start),
                          );
                    },
                  ),
                  const SizedBox(height: 16),
                },
                for (int i = 0; i < _paddingCount; i++) ...{
                  LyricsWidget(
                    key: _keys[subtitlePlayerValue.subtitleRanges.length + i],
                    lyrics: '',
                    active: false,
                    onTap: () {},
                  ),
                }
              ],
            );
          },
        ),
      ),
    );
  }
}

class LyricsWidget extends StatelessWidget {
  const LyricsWidget({
    super.key,
    required this.lyrics,
    required this.active,
    required this.onTap,
  });

  final String lyrics;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 650),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            lyrics,
            style: TextStyle(
              fontSize: 24,
              fontWeight: active ? FontWeight.bold : FontWeight.w700,
              color: active ? Colors.black : Colors.black.withValues(alpha: .4),
            ),
          ),
        ),
      ),
    );
  }
}
