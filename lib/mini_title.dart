import 'package:flame/components.dart';

import '../components/background_asteroids.dart';
import '../components/background_moons.dart';
import '../components/background_stars.dart';
import '../input/mini_shortcuts.dart';
import '../util/fonts.dart';
import 'core/mini_common.dart';
import 'game/mini_state.dart';
import 'scripting/mini_script.dart';
import 'util/extensions.dart';

class MiniTitle extends MiniScriptComponent with HasAutoDisposeShortcuts {
  @override
  void onMount() {
    super.onMount();
    onKey('<Space>', () {
      clearScript();
      fadeOutAll(0.5);
      at(0.5, () => showScreen(Screen.game));
      executeScript();
    });

    state = MiniState();
  }

  @override
  onLoad() async {
    super.onLoad();

    backgroundMusic('galactic_dreamers.mp3');
    backgroundStars();
    backgroundMoons();
    backgroundAsteroids();
    backgroundAsteroids().maxAsteroids = 16;

    fontSelect(fancyFont, scale: fontScale * 4);

    at(0.1, () async => fadeIn(await spriteXY('flame.png', xCenter, lineHeight, Anchor.topCenter)));
    at(0.1, () async => fadeIn(textXY('Mini Shooter', xCenter, lineHeight * 3, anchor: Anchor.topCenter)));
    at(0.1, () => pressFireToStart());

    _addEntry(bonny(), 'Bonny');
    _addEntry(looker(), 'Looker');
    _addEntry(smiley(), 'Smiley');
    _addYou(sprites.getSprite(0, 4));
  }

  void _addEntry(SpriteAnimation anim, String label) {
    at(0.1, () async => fadeIn(makeAnimXY(anim, _addPos.x - _spriteOffset, _addPos.y)));
    at(0.1, () async => fadeIn(textXY(label, _addPos.x, _addPos.y, scale: 1)));
    at(0.1, () => _addPos.y += lineHeight * 2);
  }

  void _addYou(Sprite you) {
    at(0.1, () => _addPos.y += lineHeight * 2);
    at(0.1, () async => fadeIn(spriteSXY(you, _addPos.x - _spriteOffset, _addPos.y)));
    at(0.1, () async => fadeIn(textXY('You', _addPos.x, _addPos.y, scale: 1)));
  }

  final _addPos = Vector2(gameWidth / 2 + 16, lineHeight * 8);

  static const _spriteOffset = 64;
}
