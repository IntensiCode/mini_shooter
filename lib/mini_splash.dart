import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import 'core/mini_common.dart';
import 'input/mini_shortcuts.dart';
import 'scripting/mini_script.dart';
import 'util/extensions.dart';
import 'util/fonts.dart';

class MiniSplash extends MiniScriptComponent with HasAutoDisposeShortcuts {
  late final SpriteAnimation psychocell;

  @override
  void onMount() {
    super.onMount();
    onKey('<Space>', () => showScreen(Screen.title));
  }

  @override
  void onLoad() async {
    super.onLoad();

    fontSelect(menuFont, scale: fontScale);

    late SpriteAnimationComponent anim;

    at(0.5, () => fadeIn(textXY('An', xCenter, yCenter - lineHeight)));
    at(1.0, () => fadeIn(textXY('IntensiCode', xCenter, yCenter)));
    at(1.0, () => fadeIn(textXY('Presentation', xCenter, yCenter + lineHeight)));
    at(2.5, () => fadeOutAll());
    at(1.0, () => playAudio('swoosh.ogg'));
    at(0.1, () async {
      anim = makeAnimXY(await _loadSplashAnim(), xCenter, yCenter);
      anim.size.setAll(lineHeight * 6);
    });
    at(0.0, () => fadeIn(textXY('A', xCenter, yCenter - lineHeight * 3)));
    at(0.0, () => fadeIn(textXY('Game', xCenter, yCenter + lineHeight * 4)));
    at(2.0, () => scaleTo(anim, 10, 1, Curves.decelerate));
    at(0.0, () => fadeOutAll());
    at(1.0, () => showScreen(Screen.title));
  }

  Future<SpriteAnimation> _loadSplashAnim() =>
      loadAnim('splash_anim.png', frames: 13, stepTimeSeconds: 0.05, frameWidth: 120, frameHeight: 90, loop: false);

  late final SpriteAnimationComponent psychocellComponent;
}
