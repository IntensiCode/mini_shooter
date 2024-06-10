import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import '../core/mini_common.dart';
import '../core/mini_messaging.dart';
import '../core/mini_soundboard.dart';
import '../scripting/mini_script.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/debug.dart';
import '../util/random.dart';
import 'mini_balls.dart';
import 'mini_effects.dart';
import 'mini_extras.dart';
import 'mini_state.dart';

final formations = <List<(double, MiniEnemyKind, List<int>)>>[
  [
    (0.0, MiniEnemyKind.smiley, [-3, -2, -1, 0, 1, 2, 3]),
    (0.5, MiniEnemyKind.looker, [3, 2, 1, 0, -1, -2, -3]),
    (0.5, MiniEnemyKind.bonny, [-3, -2, -1, 0, 1, 2, 3]),
  ],
  [
    (0.0, MiniEnemyKind.smiley, [0, -1, 1, -2, 2, -3, 3]),
    (0.5, MiniEnemyKind.looker, [0, -1, 1, -2, 2, -3, 3]),
    (0.5, MiniEnemyKind.bonny, [0, -1, 1, -2, 2, -3, 3]),
    (0.5, MiniEnemyKind.bonny, [0, -1, 1, -3, 3]),
  ],
];

class MiniEnemies extends MiniScriptComponent {
  MiniEnemies({required this.level});

  final int level;

  bool get hasActiveEnemies => _fireAtWill && children.whereType<MiniEnemy>().where(_isActive).isNotEmpty;

  bool _isActive(MiniEnemy it) => it._state == MiniEnemyState.attacking;

  @override
  void onLoad() {
    logInfo('load level $level');

    final formation = formations[(level - 1) % formations.length];
    for (final (line, data) in formation.indexed) {
      final delay = data.$1;
      at(delay, () => soundboard.play(MiniSound.strangeness));
      for (final pos in data.$3) {
        final xy = Vector2(xCenter + pos * 24, 32 + line * 24);
        at(0.1, () => add(MiniEnemy(data.$2, level, _onDefeated)..position.setFrom(xy)));
      }
    }
    at(0.5, () => messaging.send('formation-complete', null));
    at(0.5, () => reactivate());
  }

  void _onDefeated() {
    logInfo('enemy defeated ${children.length}');
    if (children.length <= 1) sendMessage('enemies-defeated', null);
  }

  void reactivate() => _fireAtWill = true;

  bool _fireAtWill = false;
  double _coolDown = 0;

  @override
  void onMount() {
    super.onMount();
    onMessage('player-destroyed', (_) => _fireAtWill = false);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_fireAtWill) _onFireAtWill(dt);
  }

  void _onFireAtWill(double dt) {
    if (_coolDown <= 0) {
      final it = children.whereType<MiniEnemy>().toList();
      if (it.isNotEmpty) {
        spawnBall(it.random(random).position);
        _coolDown = (2 - level / 10).clamp(0.2, 2);
      }
    } else if (_coolDown > 0) {
      _coolDown -= dt;
    }
  }
}

enum MiniEnemyKind {
  bonny(2),
  looker(3),
  smiley(4),
  ;

  final int life;

  const MiniEnemyKind(this.life);
}

enum MiniEnemyState {
  attacking,
  incoming,
  waiting,
}

class MiniEnemy extends PositionComponent with AutoDispose, MiniScriptFunctions, MiniScript, MiniTarget {
  //
  MiniEnemy(this.kind, this.level, this.onDefeated);

  final MiniEnemyKind kind;
  final int level;
  final void Function() onDefeated;

  MiniEnemyState _state = MiniEnemyState.incoming;

  @override
  void onLoad() {
    life = kind.life.toDouble();
    at(0.0, () async => _showIncoming());
    at(0.5, () async => _showEnemy());
    at(1.5, () async => _activate());
  }

  _showIncoming() {
    makeAnimXY(appear()..loop = false, 0, 0)
      ..priority = 100
      ..removeOnFinish = true;
  }

  _showEnemy() {
    final anim = switch (kind) {
      MiniEnemyKind.bonny => bonny(),
      MiniEnemyKind.looker => looker(),
      MiniEnemyKind.smiley => smiley(),
    };

    makeAnimXY(anim, 0, 0);

    final radius = kind == MiniEnemyKind.smiley ? 7.0 : 6.0;
    add(DebugCircleHitbox(radius: radius, anchor: Anchor.center));
    add(CircleHitbox(radius: radius, anchor: Anchor.center, collisionType: CollisionType.passive));
  }

  _activate() => _state = MiniEnemyState.waiting;

  double life = 3;

  @override
  bool applyDamage({double? laser, double? missile}) {
    life -= (laser ?? 0) + (missile ?? 0);
    if (life <= 0) {
      spawnEffect(MiniEffectKind.explosion, position);
      if (random.nextInt(3) == 0) {
        spawnItem(MiniSpawnItem(position));
      }
      removeFromParent();
      soundboard.play(MiniSound.death);
      state.score += kind.life * 10;
      onDefeated();
      return true;
    } else {
      soundboard.play(MiniSound.hit);
      state.score++;
      return false;
    }
  }
}
