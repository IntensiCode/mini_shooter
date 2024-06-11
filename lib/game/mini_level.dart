import 'package:flame/components.dart';

import '../components/background_asteroids.dart';
import '../components/background_moons.dart';
import '../components/background_stars.dart';
import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import '../input/mini_game_keys.dart';
import '../input/mini_shortcuts.dart';
import '../scripting/mini_script.dart';
import '../util/bitmap_text.dart';
import '../util/extensions.dart';
import 'mini_balls.dart';
import 'mini_effects.dart';
import 'mini_enemies.dart';
import 'mini_extras.dart';
import 'mini_hud.dart';
import 'mini_player.dart';
import 'mini_state.dart';

class MiniLevel extends MiniScriptComponent with KeyboardHandler, MiniGameKeys, HasCollisionDetection {
  MiniLevel(this.level);

  final int level;

  @override
  onLoad() async {
    super.onLoad();

    backgroundStars();
    backgroundMoons();
    backgroundAsteroids().maxAsteroids = 0;

    _items = items();
    _balls = balls(level);
    effects();

    soundboard.play(MiniSound.game_on);
    at(0.1, () async => fadeIn(textXY('Level $level', xCenter, yCenter)));
    at(1.0, () async => fadeIn(textXY('Game on!', xCenter, yCenter + lineHeight)));
    at(2.0, () async => fadeOutByType<BitmapText>());
    at(0.0, () async => add(_enemies = MiniEnemies(level: level)));

    onMessage<FormationComplete>((_) {
      add(_player = MiniPlayer());
      add(MiniHud());
    });
    onMessage<EnemiesDefeated>((_) => _awaitComplete = true);
    onMessage<PlayerDestroyed>((_) => _awaitRetry = true);
  }

  late MiniItems _items;
  late MiniBalls _balls;
  late MiniEnemies _enemies;
  late MiniPlayer _player;

  bool _awaitComplete = false;
  bool _awaitRetry = false;

  double check = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_awaitComplete) _onAwaitComplete(dt);
    if (_awaitRetry) _onAwaitRetry(dt);
  }

  void _onAwaitComplete(double dt) {
    if (check <= 0) {
      check = 1;

      if (_balls.hasActiveBalls) return;
      if (_enemies.hasActiveEnemies) return;
      if (_items.hasActiveItems) return;
      _awaitComplete = false;

      if (!_awaitRetry || state.lives > 0) {
        _player.vanish();
        add(LevelComplete());
      }
    } else {
      check -= dt;
    }
  }

  void _onAwaitRetry(double dt) {
    if (check <= 0) {
      check = 1;

      if (_balls.hasActiveBalls) return;
      if (_enemies.hasActiveEnemies) return;
      if (_items.hasActiveItems) return;
      _awaitRetry = false;

      if (!_awaitComplete || state.lives == 0) _retry();
    } else {
      check -= dt;
    }
  }

  void _retry() {
    if (state.lives <= 0) {
      add(BackToTitle());
    } else {
      add(RetryLevel(level, _executeRetry));
    }
  }

  void _executeRetry() {
    _enemies.reactivate();
    state.shields = 3;
    state.missiles = 0;
    add(MiniPlayer());
  }
}

class LevelComplete extends MiniScriptComponent with HasAutoDisposeShortcuts {
  @override
  onLoad() {
    soundboard.play(MiniSound.game_over);
    at(0.0, () => fadeIn(textXY('Level complete!', xCenter, yCenter)));
    at(1.0, () => pressFireToStart());
    at(0.0, () => onKey('<Space>', _execute));
  }

  void _execute() {
    if (isRemoving || isRemoved) return;
    removeFromParent();
    nextLevel();
  }
}

class RetryLevel extends MiniScriptComponent with HasAutoDisposeShortcuts {
  RetryLevel(this.level, this.retry);

  final int level;
  final void Function() retry;

  @override
  onLoad() {
    soundboard.play(MiniSound.game_on);
    at(0.0, () => fadeIn(textXY('Level $level', xCenter, yCenter)));
    at(1.0, () => fadeIn(textXY('Game on!', xCenter, yCenter + lineHeight)));
    at(0.0, () => onKey('<Space>', () => _retry()));
    at(3.0, () => fadeOutByType<BitmapText>());
    at(0.0, () => _retry());
  }

  void _retry() {
    if (isRemoving || isRemoved) return;
    removeFromParent();
    retry();
  }
}

class BackToTitle extends MiniScriptComponent with HasAutoDisposeShortcuts {
  @override
  onLoad() {
    soundboard.play(MiniSound.game_over);
    at(0.0, () => fadeIn(textXY('Game over!', xCenter, yCenter)));
    at(1.0, () => pressFireToStart());
    at(0.0, () => onKey('<Space>', _execute));
  }

  void _execute() {
    if (isRemoving || isRemoved) return;
    removeFromParent();
    showScreen(Screen.title);
  }
}
