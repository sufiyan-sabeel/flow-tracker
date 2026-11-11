import 'dart:io';

import 'package:flutter/material.dart';

const focusVideoScenes = <String>[
  'cabin_rain',
  'fireplace_room',
  'girl_study',
  'cat_fireplace',
];

bool get hasVideoScenes => Platform.isWindows || Platform.isLinux;

const focusVideoExtensions = ['mp4', 'mov', 'webm', 'mkv'];

bool isFocusVideo(String path) =>
    hasVideoScenes &&
    focusVideoExtensions.contains(path.split('.').last.toLowerCase());

String get _scenesDir =>
    '${File(Platform.resolvedExecutable).parent.path}/data/scenes';

File focusVideoFile(String name) => File('$_scenesDir/$name.mp4');

File focusVideoPoster(String name) => File('$_scenesDir/$name.jpg');

class FocusVideoPoster extends StatelessWidget {
  const FocusVideoPoster({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final poster = focusVideoPoster(name);
    if (!poster.existsSync()) {
      return const ColoredBox(color: Colors.black);
    }
    return Image.file(poster, fit: BoxFit.cover);
  }
}

/// A focus scene background.
///
/// This used to play an `.mp4` through the `video_player_win` plugin. That
/// plugin links against Media Foundation, so on Windows editions without it
/// (the "N" editions, and stripped images) the whole app failed to start with a
/// system error before any Dart code ran. The repository never shipped the
/// video files — only the `.jpg` posters — so the still is what was on screen in
/// practice. Rendering the poster directly keeps the scene UI and removes the
/// startup dependency.
class FocusVideoScene extends StatelessWidget {
  const FocusVideoScene({super.key, required this.file, required this.poster});

  final File file;
  final Widget poster;

  @override
  Widget build(BuildContext context) => poster;
}
