import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import '../core/mini_common.dart';
import '../core/mini_messaging.dart';
import '../scripting/mini_script.dart';
import '../scripting/mini_script_functions.dart';
import '../util/debug.dart';
import '../util/extensions.dart';
import '../util/random.dart';
import 'mini_effects.dart';

extension ScriptFunctionsExtension on MiniScriptFunctions {
  MiniItems items() => added(MiniItems());
}

extension ComponentExtensions on Component {
  void spawnItem(MiniSpawnItem data) => messaging.send('spawn-item', data);
}

class MiniSpawnItem {
  MiniSpawnItem(this.position, [this.speed, this.kind]);

  final Vector2 position;
  final double? speed;
  final Set<MiniItemKind>? kind;
}

class MiniItems extends MiniScriptComponent {
  bool get hasActiveItems => children.isNotEmpty;

  @override
  void onMount() {
    super.onMount();
    onMessage('spawn-item', (message) {
      final data = message as MiniSpawnItem;
      final which = data.kind?.toList() ?? MiniItemKind.values;
      _spawn(data.position, which.random(random), data.speed ?? 50);
    });
  }

  void _spawn(Vector2 position, MiniItemKind kind, [double speed = 50]) {
    final it = _pool.removeLastOrNull() ?? MiniItem(_recycle);
    it.sprite.sprite = sprites.getSprite(5, 3 + kind.column);
    it.kind = kind;
    it.speed = speed;
    it.position.setFrom(position);
    add(it);
  }

  void _recycle(MiniItem it) {
    it.removeFromParent();
    _pool.add(it);
  }

  final _pool = <MiniItem>[];
}

class MiniItem extends PositionComponent with CollisionCallbacks {
  MiniItem(this._recycle) {
    anchor = Anchor.center;
    add(sprite = SpriteComponent(anchor: Anchor.center));
    add(debug = DebugCircleHitbox(radius: 6, anchor: Anchor.center));
    add(hitbox = CircleHitbox(radius: 6, anchor: Anchor.center));
  }

  final void Function(MiniItem it) _recycle;

  late SpriteComponent sprite;
  late DebugCircleHitbox debug;
  late CircleHitbox hitbox;
  late MiniItemKind kind;
  late double speed;

  @override
  void onMount() {
    super.onMount();
    final radius = kind.name.startsWith('score') ? 4.0 : 6.0;
    hitbox.radius = radius;
    debug.radius = radius;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    if (position.y > gameHeight + size.y) _recycle(this);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other case Collector it) {
      spawnEffect(MiniEffectKind.sparkle, other.position);
      it.collect(kind);
      _recycle(this);
    }
  }
}
