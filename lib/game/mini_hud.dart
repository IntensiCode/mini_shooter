import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:signals_core/signals_core.dart';

import '../core/mini_common.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import 'mini_effects.dart';
import 'mini_state.dart';

class MiniHud extends PositionComponent with AutoDispose, MiniScriptFunctions {
  static const xBase = xCenter - 15;

  @override
  void onLoad() async {
    priority = 100;
    scoreFont = SpriteSheet(image: await image('scorefont.png'), srcSize: Vector2.all(8));

    empty = scoreFont.getSprite(0, 11);
    while (scoreDigits.length < 7) {
      final it = SpriteComponent(sprite: empty);
      it.position.x = xBase - 10 * scoreDigits.length.toDouble();
      it.position.y = 4;
      scoreDigits.add(it);
      add(it);
    }

    _trackScore();

    lives = _place(0, 8, 20, state.data[MiniStateId.lives]!, 'lives');
    shields = _place(9, 8, 45, state.data[MiniStateId.shields]!, 'shields');
    missiles = _place(10, 3, 70, state.data[MiniStateId.missiles]!, 'missiles');

    _trackExtraLives();

    fadeInDeep(restart: true);
  }

  SpriteComponent _place(int row, int column, int offset, Signal<int> signal, String hint) {
    final sprite = sprites.getSprite(row, column);
    add(SpriteComponent(sprite: sprite, position: Vector2(xBase + offset, 0)));
    late final SpriteComponent it;
    add(it = SpriteComponent(sprite: empty, position: Vector2(xBase + offset + 15, 4)));
    autoEffect('MiniHud.$hint', () {
      final update = signal.value.clamp(0, 10);
      it.sprite = scoreFont.getSprite(0, update);
      _highlight(it.position);
    });
    return it;
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
