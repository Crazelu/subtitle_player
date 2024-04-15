# Subtitle Player
A Flutter package for synchronizing subtitles with video and audio playback.

## Features 📦

- [x] Load SubRip, WebVTT and LRC subtitles
- [x] Play, pause and seek support
- [x] Adjust playback speed

## Install 🚀

In the `pubspec.yaml` of your flutter project, add the `subtitle_player` dependency:

```yaml
dependencies:
    subtitle_player:
        git:
            url: https://github.com/Crazelu/subtitle_player.git
```

## Import the package in your project 📥

```dart
import 'package:subtitle_player/subtitle_player.dart';
```

## Usage 🏗️

Create a `SubtitleController` and load a subtitle file

```dart
final subtitleController = SubtitleController();
subtitleController.loadSubtitle(Subtitle.fromWebVTT(content));
```

Start playing subtitle with your audio/video

```dart
subtitleController.play();
```

Subscribe to `SubtitleController` for changes using `ValuelistenableBuilder`, `ListenableBuilder` or `AnimatedBuilder`

```dart
// From the video player example

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
            color: Colors.black.withOpacity(0.65),
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
)
```

Check the [example project](https://github.com/Crazelu/subtitle_player/tree/main/example) for more detailed usage examples both for video and audio playing.

## Demo 📷

<img src="https://raw.githubusercontent.com/Crazelu/subtitle_player/main/demos/video-player-demo.gif" width="280" alt="Example video subtitle demo"> <img src="https://raw.githubusercontent.com/Crazelu/subtitle_player/main/demos/audio-player-demo.gif" width="280" alt="Example live lyrics demo">

## Contributions 🫱🏾‍🫲🏼

Feel free to contribute to this project.

If you find a bug or want a feature, but don't know how to fix/implement it, please fill an [issue](https://github.com/Crazelu/subtitle_player/issues).  
If you fixed a bug or implemented a feature, please send a [pull request](https://github.com/Crazelu/subtitle_player/pulls).