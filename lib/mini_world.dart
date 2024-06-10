import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import 'core/mini_common.dart';
import 'core/mini_messaging.dart';
import 'game/mini_level.dart';
import 'mini_splash.dart';
import 'mini_title.dart';

class MiniWorld extends World {
  int level = 1;

  @override
  void onLoad() {
    messaging.listen('nextLevel', (_) => nextLevel());
    messaging.listen('screen', (it) => _showScreen(it));
  }

  void _showScreen(Screen it) {
    logInfo(it);
    switch (it) {
      case Screen.game:
        showGame();
      case Screen.splash:
        showSplash();
      case Screen.title:
        showTitle();
    }
  }

  void showGame() {
    removeAll(children);
    add(MiniLevel(level));
  }

  void showSplash() {
    removeAll(children);
    add(MiniSplash());
  }

  void showTitle() {
    removeAll(children);
    add(MiniTitle());
  }

  void previousLevel() {
    if (level > 1) level--;
    showGame();
  }

  void nextLevel() {
    level++;
    logInfo('next level $level');
    showGame();
  }
}
