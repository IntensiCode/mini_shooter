import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import 'mini_effects.dart';
import 'mini_enemy_kind.dart';
import 'mini_state.dart';

mixin MiniTarget on Component {
  NotifyingVector2 get position;

  MiniEnemyKind get kind;

  void whenDefeated();

  double life = 3;

  /// returns true when destroyed
  bool applyDamage({double? laser, double? missile}) {
    life -= (laser ?? 0) + (missile ?? 0);
    if (life <= 0) {
      spawnEffect(MiniEffectKind.explosion, position);
      removeFromParent();
      soundboard.play(MiniSound.death);
      whenDefeated();
      return true;
    } else {
      soundboard.play(MiniSound.hit);
      state.score++;
      return false;
    }
  }
}
