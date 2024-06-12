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
      for (final it in children) {
        if (it is! PositionComponent) continue;
        it.fadeOutDeep(seconds: 0.5);
      }
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

    at(0.1, () async => fadeIn(await spriteXY('title.png', xCenter, yCenter, Anchor.center)));
    at(0.1, () async => fadeIn(await spriteXY('flame.png', xCenter, lineHeight, Anchor.topCenter)));
    at(0.1, () async => fadeIn(textXY('GALAXINA', xCenter, lineHeight * 3, anchor: Anchor.topCenter)));
    at(0.1, () => pressFireToStart());

    loopAt(0.0, () {
      Component? showing;
      at(1.0, () => add(showing = fadeIn(Credits())));
      at(15.0, () => showing?.fadeOutDeep(andRemove: true));
      at(1.0, () => add(showing = fadeIn(Controls())));
      at(15.0, () => showing?.fadeOutDeep(andRemove: true));
      at(1.0, () => add(showing = fadeIn(Entities())));
      at(8.0, () => showing?.fadeOutDeep(andRemove: true));
      at(1.0, () => add(showing = fadeIn(Projectiles())));
      at(8.0, () => showing?.fadeOutDeep(andRemove: true));
      at(1.0, () => add(showing = fadeIn(Items())));
      at(12.0, () => showing?.fadeOutDeep(andRemove: true));
    });
  }
}

abstract class InfoScreen extends MiniScriptComponent {
  void addText(String text) {
    at(0.1, () async => fadeIn(textXY(text, _addPos.x - 16, _addPos.y, scale: 1)));
    at(0.1, () => _addPos.y += lineHeight);
  }

  void addEntry(SpriteAnimation anim, String label) {
    at(0.1, () async => fadeIn(makeAnimXY(anim, _addPos.x - _spriteOffset, _addPos.y)));
    at(0.1, () async => fadeIn(textXY(label, _addPos.x, _addPos.y, scale: 1)));
    at(0.1, () => _addPos.y += lineHeight * 2);
  }

  void addItem(MiniItemKind kind, String label) {
    final sprite = sprites.getSprite(5, 3 + kind.index);
    at(0.1, () async => fadeIn(spriteSXY(sprite, _addPos.x - _spriteOffset, _addPos.y)));
    at(0.1, () async => fadeIn(textXY(label, _addPos.x, _addPos.y, scale: 1)));
    at(0.1, () => _addPos.y += lineHeight * 2);
  }

  final _addPos = Vector2(gameWidth / 2 + 16, lineHeight * 8);

  static const _spriteOffset = 64;
}

class Entities extends InfoScreen {
  @override
  onLoad() async {
    super.onLoad();
    addEntry(bonny(), 'Bonny');
    addEntry(looker(), 'Looker');
    addEntry(smiley(), 'Smiley');
    addYou(sprites.getSprite(0, 4));
  }

  void addYou(Sprite you) {
    at(0.1, () => _addPos.y += lineHeight * 2);
    at(0.1, () async => fadeIn(spriteSXY(you, _addPos.x - InfoScreen._spriteOffset, _addPos.y)));
    at(0.1, () async => fadeIn(textXY('You', _addPos.x, _addPos.y, scale: 1)));
  }
}

class Projectiles extends InfoScreen {
  @override
  onLoad() async {
    super.onLoad();
    addEntry(energyBall(), 'Energy Ball');
    addEntry(laser(), 'Laser Types');
    addEntry(missile(), 'Atomic Missile');
    addEntry(shield(), 'Shield');
  }
}

class Items extends InfoScreen {
  @override
  onLoad() async {
    super.onLoad();
    _addPos.y -= lineHeight;
    addItem(MiniItemKind.laserCharge, 'Switch Laser');
    addItem(MiniItemKind.shield, '+ 1 Shield');
    addItem(MiniItemKind.missile, '+ 1 Missile');
    addItem(MiniItemKind.score1, '+ 10 Score');
    addItem(MiniItemKind.score2, '+ 20 Score');
    addItem(MiniItemKind.score3, '+ 50 Score');
  }
}

class Controls extends InfoScreen {
  @override
  onLoad() async {
    super.onLoad();
    _addPos.y -= lineHeight;
    addText('Move your ship:');
    addText('Cursor Left/Right or a/d');
    addText('');
    addText('Fire laser:');
    addText('Space or Control or j');
    addText('');
    addText('Fire missile:');
    addText('Shift or k');
    addText('');
    addText('Toggle mute: m');
    addText('Back to title: t');
  }
}

class Credits extends InfoScreen {
  @override
  onLoad() async {
    super.onLoad();
    _addPos.y -= lineHeight * 2;
    addText('Gfx By:');
    addText('GrafxKid (itch.io)');
    addText('&');
    addText('The.French.DJ');
    addText('');
    addText('Background music By:');
    addText('Suno.com');
    addText('');
    addText('Sfx By:');
    addText('sfxr.me & The.French.DJ');
    addText('');
    addText('Asteroid Shader By;');
    addText('Deep-Fold (itch.io)');
  }
}
