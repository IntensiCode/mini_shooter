import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:mini_shooter/util/extensions.dart';

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

  bool get hasActiveEnemies => _active && _attackers.isNotEmpty;

  Iterable<MiniEnemy> get _attackers => _enemies.where(_isActive);

  bool _isActive(MiniEnemy it) => it._state != MiniEnemyState.waiting;

  bool _isWaiting(MiniEnemy it) => it._state == MiniEnemyState.waiting;

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

  void reactivate() => _active = true;

  bool _active = false;
  double _fireAtWillCoolDown = 0;
  late double _sendAttackerCoolDown = _attackerCoolDown();

  @override
  void onMount() {
    super.onMount();
    onMessage('player-destroyed', (_) => _active = false);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_active) _onFireAtWill(dt);
    if (_active) _sendAttacker(dt);
  }

  Iterable<MiniEnemy> get _enemies => children.whereType<MiniEnemy>();

  void _onFireAtWill(double dt) {
    if (_fireAtWillCoolDown <= 0) {
      final it = _enemies.toList();
      if (it.isNotEmpty) {
        spawnBall(it.random(random).position);
        _fireAtWillCoolDown = (2 - level / 10).clamp(0.2, 2);
      }
    } else if (_fireAtWillCoolDown > 0) {
      _fireAtWillCoolDown -= dt;
    }
  }

  void _sendAttacker(double dt) {
    final attackers = _attackers;
    if (_sendAttackerCoolDown <= 0 && attackers.length < _maxAttackers) {
      final it = _waiting.where(_notSmiley).toList();
      if (it.isNotEmpty) {
        it.random(random).startAttackRun();
        _sendAttackerCoolDown = _attackerCoolDown();
      }
    } else if (_sendAttackerCoolDown > 0) {
      _sendAttackerCoolDown -= dt;
    }
  }

  bool _notSmiley(MiniEnemy it) => it.kind != MiniEnemyKind.smiley;

  Iterable<MiniEnemy> get _waiting => _enemies.where(_isWaiting);

  double _attackerCoolDown() => (8 - level / 4).clamp(2, 8);

  int get _maxAttackers => (level / 5).clamp(1, 3).toInt();
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
  launching,
  settling,
  waiting,
}

class MiniEnemy extends PositionComponent
    with AutoDispose, MiniScriptFunctions, MiniScript, MiniTarget, CollisionCallbacks {
  //
  MiniEnemy(this.kind, this.level, this.onDefeated);

  final MiniEnemyKind kind;
  final int level;
  final void Function() onDefeated;

  MiniEnemyState _state = MiniEnemyState.incoming;

  void startAttackRun() {
    logInfo('attack run');
    size.setAll(8);
    _state = MiniEnemyState.launching;
    _launching = 0;
    _launchDir = random.nextBool() ? 1 : -1;
    _launched.setFrom(position);
    soundboard.play(MiniSound.launch);
  }

  late double _launching;
  late double _launchDir;
  final _launched = Vector2.zero();

  @override
  void onLoad() {
    life = kind.life.toDouble();
    at(0.0, () async => _showIncoming());
    at(0.5, () async => _showEnemy());
    at(1.5, () async => _activate());
    _basePos.setFrom(position);
  }

  final _basePos = Vector2.zero();

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
    add(_hitbox = CircleHitbox(radius: radius, anchor: Anchor.center, collisionType: CollisionType.passive));
  }

  late CircleHitbox _hitbox;

  _activate() => _state = MiniEnemyState.waiting;

  static const _launchDistance = 32.0;

  double get _launchSpeedInRad => (1.0 + level / 10).clamp(1, 5);

  double get _attackSpeed => (50.0 + level).clamp(50, 100);

  late double _attackDx;

  @override
  update(double dt) {
    super.update(dt);
    if (_state == MiniEnemyState.attacking) {
      position.x += _attackDx * dt;
      position.y += dt * _attackSpeed;
      if (position.y > gameHeight + size.y) {
        position.x = _basePos.x;
        position.y = -size.y;
        _state = MiniEnemyState.settling;

        // after attack run, we go passive again. bullets are active. so
        // nothing for the enemy to do outside the attack run.
        _hitbox.collisionType = CollisionType.passive;
      }
    }
    if (_state == MiniEnemyState.launching) {
      _launching += dt * _launchSpeedInRad;
      if (_launching.abs() >= pi) {
        _launching = pi * _launching.sign;
        _attackDx = position.x < gameWidth / 2 ? 1 : -1;
        _attackDx *= 5 + random.nextDoubleLimit(5);
        _state = MiniEnemyState.attacking;

        // to collide with player, we switch to active during the attack run:
        _hitbox.collisionType = CollisionType.active;
      }
      position.x = _launched.x + cos(_launching) * _launchDistance * _launchDir - _launchDistance * _launchDir;
      position.y = _launched.y - sin(_launching).abs() * _launchDistance;
    }
    if (_state == MiniEnemyState.settling) {
      position.x = _basePos.x + sin(_wandering) * 8;
      position.y += dt * _attackSpeed;
      if (position.y >= _basePos.y) {
        position.y = _basePos.y;
        _state = MiniEnemyState.waiting;
      }
    }

    // we do this always, unless incoming, to keep in sync:
    if (_state != MiniEnemyState.incoming) {
      _wandering += dt * 2;
      if (_wandering > _maxWandering) {
        _wandering -= _maxWandering;
      }
    }

    // but we apply it only when in waiting state:
    if (_state == MiniEnemyState.waiting) {
      position.x = _basePos.x + sin(_wandering) * 8;
    }
  }

  double _wandering = 0;
  static const _maxWandering = pi * 2;

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

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other case Defender it) {
      it.onHit(kind == MiniEnemyKind.smiley ? 2 : 1);
      applyDamage(laser: life);
    }
  }
}
