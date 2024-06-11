import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../core/mini_common.dart';
import '../scripting/mini_script_functions.dart';
import '../util/debug.dart';
import 'mini_enemy_kind.dart';

mixin MiniMakeEnemy on PositionComponent, MiniScriptFunctions {
  MiniEnemyKind get kind;

  abstract double life;

  makeEnemy() {
    final anim = switch (kind) {
      MiniEnemyKind.bonny => bonny(),
      MiniEnemyKind.looker => looker(),
      MiniEnemyKind.smiley => smiley(),
    };

    makeAnimXY(anim, 0, 0);

    final radius = kind == MiniEnemyKind.smiley ? 7.0 : 6.0;
    add(DebugCircleHitbox(radius: radius, anchor: Anchor.center));
    add(hitbox = CircleHitbox(radius: radius, anchor: Anchor.center, collisionType: CollisionType.passive));

    life = kind.life.toDouble();
  }

  late CircleHitbox hitbox;
}
