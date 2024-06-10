import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import 'mini_effects.dart';
import 'mini_state.dart';

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
    add(SpriteComponent(sprite: sprites.getSprite(10, 3), anchor: Anchor.center));
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
  }

  double _smoke = 0;

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other case MiniTarget it) {
      final destroyed = it.applyDamage(missile: 1 + state.charge * 0.5);
      if (!destroyed) spawnEffect(MiniEffectKind.hit, position);
      _recycle(this);
    }
  }
}
