import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import '../scripting/mini_script.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/random.dart';
import 'mini_enemy_kind.dart';
import 'mini_enemy_state.dart';
import 'mini_extra_items.dart';
import 'mini_make_enemy.dart';
import 'mini_state.dart';
import 'mini_target.dart';

class MiniEnemy extends PositionComponent
    with AutoDispose, MiniScriptFunctions, MiniScript, MiniTarget, MiniMakeEnemy, CollisionCallbacks {
  //
  MiniEnemy(this.kind, this.level, Vector2 position) {
    this.position.setFrom(position);
  }

  @override
  final MiniEnemyKind kind;

  final int level;

  late final void Function() onDefeated;

  MiniEnemyState _state = MiniEnemyState.incoming;

  bool get isDefeated => _state == MiniEnemyState.defeated;

  bool get isActive => _state != MiniEnemyState.waiting;

  bool get isWaiting => _state == MiniEnemyState.waiting;

  void startAttackRun() {
    logInfo('attack run');
    size.setAll(8);
    _state = MiniEnemyState.launching;
    _launching = 0;
    _launchDir = random.nextBool() ? 1 : -1;
    if (position.x < gameWidth / 4) _launchDir = -1;
    if (position.x > gameWidth * 3 / 4) _launchDir = 1;
    _launched.setFrom(position);
    soundboard.play(MiniSound.launch);
  }

  void startFollowing(MiniEnemy leader, int side) {
    _leader = leader;
    _followSide = side;
    _state = MiniEnemyState.preparing_to_follow;
  }

  MiniEnemy? _leader;
  late int _followSide;

  late double _launching;
  late double _launchDir;
  final _launched = Vector2.zero();

  @override
  void onLoad() {
    at(0.0, () async => _showIncoming());
    at(0.5, () async => makeEnemy());
    at(1.5, () async => _activate());
    _basePos.setFrom(position);
  }

  final _basePos = Vector2.zero();

  _showIncoming() {
    makeAnimXY(appear()..loop = false, 0, 0)
      ..priority = 100
      ..removeOnFinish = true;
  }

  _activate() => _state = MiniEnemyState.waiting;

  static const _launchDistance = 32.0;

  double get _launchSpeedInRad => (1.0 + level / 10).clamp(1, 2.5);

  double get _attackSpeed => (50.0 + level).clamp(50, 100);

  late double _attackDx;

  _moveTowards(Vector2 target, double dt, [double xOffset = 0]) {
    final moveSpeedMultiplier = 1 + (level * 0.01).clamp(0, 2.5);
    if ((position.x - target.x).abs() > 0.5) {
      final dx = target.x + xOffset - position.x;
      var todo = dx.sign * dt * _attackSpeed * 1.25 * moveSpeedMultiplier;
      if (todo.abs() > dx.abs()) todo = dx;
      position.x += todo;
    } else {
      position.x = target.x + xOffset;
    }
    if ((position.y - target.y).abs() > 0.5) {
      final dy = target.y - position.y;
      var todo = dy.sign * dt * _attackSpeed * 1.25 * moveSpeedMultiplier;
      if (todo.abs() > dy.abs()) todo = dy;
      position.y += todo;
    } else {
      position.y = target.y;
    }
  }

  @override
  update(double dt) {
    super.update(dt);

    if (_state == MiniEnemyState.preparing_to_follow) {
      _moveTowards(_leader!.position, dt, _followSide * 20);
      if (_leader?.isMounted != true) {
        // if leader is destroyed, we go back to base:
        _state = MiniEnemyState.return_to_base;
      } else if (_leader?._state == MiniEnemyState.attacking) {
        // when leader is attacking, we clone its direction and follow independently:
        _state = MiniEnemyState.attacking;
        _attackDx = _leader!._attackDx;
        hitbox.collisionType = CollisionType.active;
      }
    }

    if (_state == MiniEnemyState.return_to_base) {
      _moveTowards(_basePos, dt, sin(_wandering) * 8);
      if (position.distanceTo(_basePos) < 1) {
        _state = MiniEnemyState.settling;
      }
    }

    if (_state == MiniEnemyState.attacking) {
      position.x += _attackDx * dt;
      position.y += dt * _attackSpeed;
      if (position.y > gameHeight + size.y) {
        position.x = _basePos.x;
        position.y = -size.y;
        _state = MiniEnemyState.settling;

        // after attack run, we go passive again. bullets are active. so
        // nothing for the enemy to do outside the attack run.
        hitbox.collisionType = CollisionType.passive;
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
        hitbox.collisionType = CollisionType.active;
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

  @override
  void whenDefeated() {
    if (random.nextInt(3) == 0) spawnItem(position);
    state.score += kind.life * 10;
    _state = MiniEnemyState.defeated;
    onDefeated();
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
