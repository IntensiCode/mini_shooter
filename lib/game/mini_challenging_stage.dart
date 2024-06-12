import 'package:flame/components.dart';

import '../components/background_asteroids.dart';
import '../components/background_moons.dart';
import '../components/background_stars.dart';
import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import '../input/mini_game_keys.dart';
import '../input/mini_shortcuts.dart';
import '../scripting/mini_script.dart';
import '../util/extensions.dart';
import 'mini_challengers.dart';
import 'mini_effects.dart';
import 'mini_extra_items.dart';
import 'mini_player.dart';
import 'mini_wave.dart';

enum _State {
  playing,
  waiting_to_complete,
  complete,
}

class MiniChallengingStage extends MiniScriptComponent with KeyboardHandler, MiniGameKeys, HasCollisionDetection {
  MiniChallengingStage(this.level, List<MiniWave> waves) {
    _challengers = MiniChallengers(level, waves);
  }

  final int level;
  late final MiniChallengers _challengers;
  late final MiniExtraItems _items;
  late final MiniPlayer _player;

  _State _state = _State.playing;

  @override
  onLoad() async {
    super.onLoad();

    backgroundStars();
    backgroundMoons();
    backgroundAsteroids().maxAsteroids = 0;

    effects();
    _items = items();

    add(_player = MiniPlayer());
    at(1.0, () => add(_challengers));

    onMessage<ChallengeComplete>((_) => _state = _State.waiting_to_complete);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_state == _State.waiting_to_complete) {
      if (!_items.hasActiveItems) {
        _state = _State.complete;
        add(ChallengeCompleteOverlay());
        _player.vanish();
      }
    }
  }
}

class ChallengeCompleteOverlay extends MiniScriptComponent with HasAutoDisposeShortcuts {
  @override
  onLoad() {
    soundboard.play(MiniSound.game_over);
    at(0.0, () => fadeIn(textXY('Challenge complete!', xCenter, yCenter)));
    at(1.0, () => pressFireToStart());
    at(0.0, () => onKey('<Space>', _execute));
  }

  void _execute() {
    if (isRemoving || isRemoved) return;
    removeFromParent();
    nextLevel();
  }
}
