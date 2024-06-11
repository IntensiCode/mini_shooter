import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import '../core/mini_common.dart';
import '../core/mini_messaging.dart';
import '../core/mini_soundboard.dart';
import '../util/debug.dart';
import 'mini_effects.dart';
import 'mini_state.dart';
import 'mini_target.dart';

class MiniMissile extends Component {
  MiniMissile(this.ship, this.shouldFire, this.level);

  final PositionComponent ship;
  final bool Function() shouldFire;
  final Component level;

  double _triggerTime = 0;

  @override
  update(double dt) {
    super.update(dt);

    if (_coolDown > 0) {
      _coolDown -= dt;
      return;
    }

    if (state.missiles <= 0) {
      return;
    }

    final fire = shouldFire();
    if (fire) {
      _triggerTime += dt;
    } else if (!fire && _triggerTime > 0 && _triggerTime < 0.5) {
      _triggerTime = 0;
      _fire();
    } else if (!fire && _triggerTime >= 0.5) {
      _triggerTime = 0;
      _fire(false);
    } else if (!fire) {
      _triggerTime = 0;
    }
  }

  void _fire([bool homing = true]) {
    state.missiles--;

    final it = _pool.isEmpty ? MiniMissileShot(_recycle) : _pool.removeLast();
    it.homing = homing;
    it.position.setFrom(ship.position);
    level.add(it);
    soundboard.play(MiniSound.missile);

    _coolDown = 0.5;
  }

  void _recycle(MiniMissileShot it) {
    it.removeFromParent();
    _pool.add(it);
  }

  final _pool = <MiniMissileShot>[];

  double _coolDown = 0;
}

class MiniMissileShot extends PositionComponent with CollisionCallbacks {
  MiniMissileShot(this._recycle) {
    add(RectangleHitbox(position: Vector2.zero(), size: Vector2.all(10), anchor: Anchor.center));
    add(SpriteAnimationComponent(animation: missile(), anchor: Anchor.center));
  }

  bool homing = true;

  final void Function(MiniMissileShot) _recycle;

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 250 * dt;
    if (position.y < size.y) _recycle(this);
    if (_smoke <= 0) {
      spawnEffect(MiniEffectKind.smoke, position);
      _smoke = 0.025;
    } else {
      _smoke -= dt;
    }
    if (homing) {
      messaging.send(GetClosestEnemyPosition(position, (it) {
        final distance = position.distanceTo(it);
        final curveTime = (1 - distance / gameHeight).clamp(0, 1).toDouble();
        final ease = Curves.easeInOut.transform(curveTime);
        final xSpeed = min(5, ease * 10 * curveTime);
        final xDist = it.x - position.x;
        position.x += xDist * dt * xSpeed;
      }));
    }
  }

  double _smoke = 0;

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is MiniTarget) {
      parent!.add(Nuked(radius: 24, position: position));
      _recycle(this);
    }
  }
}

class Nuked extends CircleComponent with CollisionCallbacks {
  Nuked({required super.radius, required super.position}) : super(anchor: Anchor.center) {
    opacity = 0;
    add(DebugCircleHitbox(radius: radius, anchor: Anchor.topLeft));
    add(CircleHitbox(radius: radius, anchor: Anchor.topLeft, isSolid: true));
  }

  double _in = 0;
  double _out = 1;

  @override
  void update(double dt) {
    super.update(dt);
    if (_in < 1) {
      _in += dt * 5;
      opacity = _in.clamp(0, 1);
    } else if (_out > 0) {
      _out -= dt * 2;
      opacity = _out.clamp(0, 1);
    } else {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other case MiniTarget it) it.applyDamage(missile: 5);
  }
}
