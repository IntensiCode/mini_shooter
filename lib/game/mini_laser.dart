import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import 'mini_effects.dart';
import 'mini_state.dart';
import 'mini_target.dart';

class MiniLaser extends Component {
  MiniLaser(this.ship, this.shouldFire, this.level);

  final PositionComponent ship;
  final bool Function() shouldFire;
  final Component level;

  @override
  update(double dt) {
    super.update(dt);

    if (_coolDown > 0) _coolDown -= dt;
    if (_coolDown <= 0 && shouldFire()) {
      final it = _pool.isEmpty //
          ? MiniLaserShot(_recycle)
          : _pool.removeLast();
      it.visual.sprite = sprites.getSprite(8, 3 + state.charge);
      it.position.setFrom(ship.position);
      level.add(it);
      soundboard.play(MiniSound.laser);
      _coolDown = 0.2 + state.charge * 0.1;
    }
  }

  void _recycle(MiniLaserShot it) {
    it.removeFromParent();
    _pool.add(it);
  }

  final _pool = <MiniLaserShot>[];

  double _coolDown = 0;
}

class MiniLaserShot extends PositionComponent with CollisionCallbacks {
  MiniLaserShot(this._recycle) {
    add(RectangleHitbox(position: Vector2.zero(), size: Vector2.all(10), anchor: Anchor.center));
    add(visual = SpriteComponent(anchor: Anchor.center));
  }

  late final SpriteComponent visual;

  final void Function(MiniLaserShot) _recycle;

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 250 * dt;
    if (position.y < size.y) _recycle(this);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other case MiniTarget it) {
      final destroyed = it.applyDamage(laser: 1 + state.charge * 0.5);
      if (!destroyed) spawnEffect(MiniEffectKind.hit, position);
      _recycle(this);
    }
  }
}
