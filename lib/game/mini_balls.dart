import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../core/mini_common.dart';
import '../core/mini_messaging.dart';
import '../core/mini_soundboard.dart';
import '../scripting/mini_script.dart';
import '../scripting/mini_script_functions.dart';
import '../util/debug.dart';
import '../util/extensions.dart';
import '../util/random.dart';

extension ScriptFunctionsExtension on MiniScriptFunctions {
  MiniBalls balls(int level) => added(MiniBalls(level));
}

extension ComponentExtensions on Component {
  void spawnBall(Vector2 position) => messaging.send(SpawnBall(position));
}

class MiniBalls extends MiniScriptComponent {
  MiniBalls(this.level);

  final int level;

  bool get hasActiveBalls => children.isNotEmpty;

  @override
  void onMount() {
    super.onMount();
    onMessage<SpawnBall>((it) => _spawn(it.position));
  }

  void _spawn(Vector2 position) {
    final it = _pool.removeLastOrNull() ?? MiniBall(_recycle);
    final hVariance = (10 + level).clamp(10, 30).toDouble();
    it.dx = random.nextDoubleLimit(hVariance) * (xCenter - position.x).sign;
    if (random.nextBool()) it.dx = -it.dx;
    it.dy = (50 + level * 5).clamp(50, 200).toDouble();
    it.position.setFrom(position);
    add(it);
  }

  void _recycle(MiniBall it) {
    it.removeFromParent();
    _pool.add(it);
  }

  final _pool = <MiniBall>[];
}

class MiniBall extends PositionComponent with CollisionCallbacks {
  MiniBall(this._recycle) {
    anchor = Anchor.center;
    add(SpriteAnimationComponent(animation: energyBall(), anchor: Anchor.center));
    add(debug = DebugCircleHitbox(radius: 3, anchor: Anchor.center));
    add(hitbox = CircleHitbox(radius: 3, anchor: Anchor.center));
  }

  final void Function(MiniBall it) _recycle;

  late DebugCircleHitbox debug;
  late CircleHitbox hitbox;

  late double dx;
  late double dy;

  @override
  void update(double dt) {
    super.update(dt);
    position.x += dx * dt;
    position.y += dy * dt;
    if (position.y > gameHeight + size.y) _recycle(this);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other case Defender it) {
      final destroyed = it.onHit();
      if (!destroyed) soundboard.play(MiniSound.hit);
      _recycle(this);
    }
  }
}
