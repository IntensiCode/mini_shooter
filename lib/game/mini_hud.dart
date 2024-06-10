import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../core/mini_common.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import 'mini_effects.dart';
import 'mini_player.dart';
import 'mini_state.dart';

class MiniHud extends PositionComponent with AutoDispose, MiniScriptFunctions {
  MiniPlayer? player;

  @override
  void onMount() {
    super.onMount();
    onMessage('player-ready', (it) => player = it);
  }

  @override
  void onLoad() async {
    priority = 100;
    scoreFont = SpriteSheet(image: await image('scorefont.png'), srcSize: Vector2.all(8));

    const xBase = xCenter - 15;

    empty = scoreFont.getSprite(0, 11);
    while (scoreDigits.length < 7) {
      final it = SpriteComponent(sprite: empty);
      it.position.x = xBase - 10 * scoreDigits.length.toDouble();
      it.position.y = 4;
      scoreDigits.add(it);
      add(it);
    }

    _trackScore();

    final life = sprites.getSprite(0, 8);
    add(SpriteComponent(sprite: life, position: Vector2(xBase + 20, 0)));
    add(lives = SpriteComponent(sprite: empty, position: Vector2(xBase + 35, 4)));

    final shield = sprites.getSprite(9, 8);
    add(shieldsIcon = SpriteComponent(sprite: shield, position: Vector2(xBase + 45, 0)));
    add(shields = SpriteComponent(sprite: empty, position: Vector2(xBase + 60, 4)));

    final missile = sprites.getSprite(10, 3);
    add(missilesIcon = SpriteComponent(sprite: missile, position: Vector2(xBase + 70, 0)));
    add(missiles = SpriteComponent(sprite: empty, position: Vector2(xBase + 85, 4)));

    autoEffect('MiniHud.lives', () {
      final update = state.lives.clamp(0, 10);
      lives.sprite = scoreFont.getSprite(0, update);
      _highlight(lives.position);
    });
    autoEffect('MiniHud.missiles', () {
      final update = state.missiles.clamp(0, 10);
      missiles.sprite = scoreFont.getSprite(0, update);
      _highlight(missiles.position);
    });
    autoEffect('MiniHud.shields', () {
      final update = state.shields.clamp(0, 10);
      shields.sprite = scoreFont.getSprite(0, update);
      _highlight(shields.position);
    });

    _trackExtraLives();
  }

  void _trackScore() {
    autoEffect('MiniHud.score', () {
      int score = state.score;
      for (int i = 0; i < scoreDigits.length; i++) {
        final it = scoreDigits[i];
        final digit = score % 10;
        if (score == 0 && i > 0) {
          it.sprite = empty;
        } else {
          it.sprite = scoreFont.getSprite(0, digit);
        }
        score = score ~/ 10;
      }
    });
  }

  void _trackExtraLives() {
    autoEffect('MiniHud.extraLives', () {
      final score = state.data[MiniStateId.score]!;
      final now = score.value;
      final before = score.previousValue;
      if (before == null) return;
      final from = before ~/ 2000;
      final to = now ~/ 2000;
      if (from < to) {
        final lives = state.data[MiniStateId.lives]!;
        lives.value = lives.peek() + 1;
      }
    });
  }

  _highlight(Vector2 position) => spawnEffect(MiniEffectKind.appear, position.translated(4, 4));

  late SpriteSheet scoreFont;
  late Sprite empty;

  final scoreDigits = <SpriteComponent>[];

  late SpriteComponent lives;
  late SpriteComponent shields;
  late SpriteComponent missiles;

  late SpriteComponent shieldsIcon;
  late SpriteComponent missilesIcon;
}
