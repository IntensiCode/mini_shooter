import 'package:dart_minilog/dart_minilog.dart';
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

enum MiniLevelState {
  awaiting_complete,
  awaiting_game_over,
  awaiting_retry,
  game_over,
  incoming,
  level_complete,
  level_retry,
  playing,
}

class MiniLevel extends MiniScriptComponent with KeyboardHandler, MiniGameKeys, HasCollisionDetection {
  MiniLevel(this.level);

  final int level;

  var _state = MiniLevelState.incoming;

  @override
  onLoad() async {
    super.onLoad();

    backgroundStars();
    backgroundMoons();
    backgroundAsteroids().maxAsteroids = 0;

    _enemies = MiniEnemies(level: level);
    await _enemies.preloadLevelWrapped();

    _items = items();
    _balls = balls(level);
    effects();

    soundboard.play(MiniSound.game_on);
    at(0.1, () async => fadeIn(textXY('Level $level', xCenter, yCenter)));
    at(1.0, () async => fadeIn(textXY('Game on!', xCenter, yCenter + lineHeight)));
    at(2.0, () async => fadeOutByType<BitmapText>());
    at(0.0, () async => add(_enemies));

    onMessage<FormationComplete>((_) {
      _state = MiniLevelState.playing;
      add(_player = MiniPlayer());
      add(MiniHud());
    });
    onMessage<EnemiesDefeated>((_) {
      switch (_state) {
        case MiniLevelState.playing:
        case MiniLevelState.awaiting_retry:
          _state = MiniLevelState.awaiting_complete;
          break;
        case MiniLevelState.awaiting_game_over:
          // game over wins even if last enemy got destroyed
          break;
        default:
          logWarn('unexpected _state $_state for EnemiesDefeated');
          break;
      }
    });
    onMessage<PlayerDestroyed>((_) {
      switch (_state) {
        case MiniLevelState.playing:
          _state = state.lives == 0 ? MiniLevelState.awaiting_game_over : MiniLevelState.awaiting_retry;
          break;
        case MiniLevelState.awaiting_retry:
        case MiniLevelState.awaiting_complete:
          // override level complete only in case of game over. otherwise accept the player's death.
          if (state.lives == 0) _state = MiniLevelState.awaiting_game_over;
          break;
        case MiniLevelState.awaiting_game_over:
          break;
        default:
          logWarn('unexpected _state $_state for PlayerDestroyed');
          break;
      }
    });
  }

  late MiniItems _items;
  late MiniBalls _balls;
  late MiniEnemies _enemies;
  late MiniPlayer _player;

  double check = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_state == MiniLevelState.awaiting_complete) {
      _onAwait(dt, MiniLevelState.level_complete, () {
        _player.vanish();
        add(LevelComplete());
      });
    }
    if (_state == MiniLevelState.awaiting_game_over) {
      _onAwait(dt, MiniLevelState.game_over, () => add(BackToTitle()));
    }
    if (_state == MiniLevelState.awaiting_retry) {
      _onAwait(dt, MiniLevelState.level_retry, () => add(RetryLevel(level, _executeRetry)));
    }
  }

  void _onAwait(double dt, MiniLevelState target, Function execute) {
    if (check <= 0) {
      check = 1;

      // TODO signals or messages instead
      final gotBalls = _balls.hasActiveBalls;
      final gotEnemies = _enemies.hasActiveEnemies;
      final gotItems = _items.hasActiveItems;
      logInfo('awaiting $_state => $target balls $gotBalls enemies $gotEnemies items ${gotItems}');
      if (gotBalls) return;
      if (gotEnemies) return;
      if (gotItems) return;
      _state = target;

      execute();
    } else {
      check -= dt;
    }
  }

  void _executeRetry() {
    _state = MiniLevelState.playing;
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
