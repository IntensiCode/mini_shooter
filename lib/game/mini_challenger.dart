import 'package:flame/components.dart';

import '../core/mini_common.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import 'mini_enemy_kind.dart';
import 'mini_extra_items.dart';
import 'mini_make_enemy.dart';
import 'mini_path.dart';
import 'mini_target.dart';

class MiniChallenger extends PositionComponent with AutoDispose, MiniScriptFunctions, MiniTarget, MiniMakeEnemy {
  MiniChallenger(this.level, this.kind, this.path);

  final int level;

  @override
  final MiniEnemyKind kind;

  final MiniPath path;

  bool isDone = false;
  DateTime? defeatedAt;

  @override
  void whenDefeated() {
    spawnItem(position, {MiniItemKind.score3});
    defeatedAt = DateTime.timestamp();
    isDone = true;
  }

  @override
  onLoad() => makeEnemy();

  double pathTime = 0;

  late double speed = (60 + level / 5).clamp(60, 120);

  @override
  void update(double dt) {
    super.update(dt);

    pathTime += dt;
    path.at(pathTime * speed, position);

    if (path.isAtEnd(position)) {
      removeFromParent();
      isDone = true;
    }
  }
}
