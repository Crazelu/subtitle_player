import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:subtitle_player/subtitle_player.dart';
import 'package:video_player/video_player.dart';

/// Adapted to example from video_player
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  VideoPlayerScreenState createState() => VideoPlayerScreenState();
}

class VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late SubtitleController _subtitleController;

  @override
  void initState() {
    super.initState();
    _subtitleController = SubtitleController();
    rootBundle.loadString('assets/demo.vtt').then((value) {
      return _subtitleController.loadSubtitle(Subtitle.fromWebVTT(value));
    });

    _controller = VideoPlayerController.asset('assets/demo.mp4');

    _controller.addListener(() {
      // handle looping
      if (_controller.value.isPlaying &&
          _controller.value.position.inMinutes == 0 &&
          _controller.value.position.inSeconds == 0) {
        _subtitleController.play(_controller.value.position);
      }
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _subtitleController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              VideoPlayer(_controller),
              _ControlsOverlay(
                controller: _controller,
                subtitleController: _subtitleController,
              ),
              VideoProgressIndicator(_controller, allowScrubbing: true),
              Align(
                alignment: Alignment.bottomCenter,
                child: ValueListenableBuilder<SubtitlePlayerValue>(
                  valueListenable: _subtitleController,
                  builder: (context, subtitleValue, _) {
                    if (subtitleValue.currentSubtitle.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      constraints: BoxConstraints(
                          maxWidth: (MediaQuery.sizeOf(context).height *
                                  _controller.value.aspectRatio) *
                              0.5),
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                      child: Text(
                        subtitleValue.currentSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({
    required this.controller,
    required this.subtitleController,
  });

  final VideoPlayerController controller;
  final SubtitleController subtitleController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : const ColoredBox(
                  color: Colors.black26,
                  child: Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.position.then(
              (position) {
                if (position != null && position != Duration.zero) {
                  position = position.copyWith(
                    milliseconds: position.milliseconds + 200,
                  );
                }

                if (controller.value.isPlaying) {
                  controller.pause();
                  subtitleController.pause();
                } else {
                  controller.play().then(
                        (_) => subtitleController.play(position),
                      );
                }
              },
            );
          },
        ),
      ],
    );
  }
}

extension DurationExt on Duration {
  Duration copyWith({int? milliseconds}) {
    return Duration(
      hours: inMilliseconds ~/ 3600000,
      minutes: inMilliseconds ~/ 60000,
      seconds: inMilliseconds ~/ 1000,
      milliseconds: milliseconds ?? this.milliseconds,
    );
  }

  int get milliseconds {
    int totalMilliseconds = inMilliseconds;

    final minutes = totalMilliseconds ~/ 60000;

    totalMilliseconds = inMilliseconds - (minutes * 60000);
    final seconds = totalMilliseconds ~/ 1000;

    return totalMilliseconds - (seconds * 1000);
  }
}
