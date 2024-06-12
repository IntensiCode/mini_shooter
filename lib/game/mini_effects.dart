import 'package:flame/components.dart';

import '../core/mini_common.dart';
import '../core/mini_messaging.dart';
import '../core/mini_soundboard.dart';
import '../scripting/mini_script.dart';
import '../scripting/mini_script_functions.dart';
import '../util/extensions.dart';

extension ScriptFunctionsExtension on MiniScriptFunctions {
  MiniEffects effects() => added(MiniEffects());
}

extension ComponentExtensions on Component {
  void spawnEffect(MiniEffectKind kind, Vector2 position, [Function()? atHalfTime]) =>
      messaging.send(SpawnEffect(kind, position, atHalfTime));
}

class MiniEffects extends MiniScriptComponent {
  MiniEffects() {
    priority = 10;
  }

  late final animations = <MiniEffectKind, SpriteAnimation>{};

  @override
  void onLoad() async {
    animations[MiniEffectKind.appear] = appear();
    animations[MiniEffectKind.explosion] = explosion();
    animations[MiniEffectKind.hit] = hit();
    animations[MiniEffectKind.smoke] = smoke();
    animations[MiniEffectKind.sparkle] = sparkle();
  }

  @override
  void onMount() {
    super.onMount();
    onMessage<SpawnEffect>((data) {
      final it = _pool.removeLastOrNull() ?? MiniEffect(_recycle);
      it.kind = data.kind;
      it.animation = animations[data.kind]!;
      it.position.setFrom(data.position);
      it.atHalfTime = data.atHalfTime;
      add(it);
    });
  }

  void _recycle(MiniEffect it) {
    it.removeFromParent();
    _pool.add(it);
  }

  final _pool = <MiniEffect>[];
}

class MiniEffect extends SpriteAnimationComponent {
  MiniEffect(this._recycle) {
    anchor = Anchor.center;
  }

  final void Function(MiniEffect) _recycle;

  late MiniEffectKind kind;
  Function()? atHalfTime;

  @override
  void onMount() {
    animationTicker!.reset();
    animationTicker!.onComplete = () => _recycle(this);
    if (atHalfTime != null) {
      animationTicker!.onFrame = (it) {
        if (it >= animation!.frames.length ~/ 2) {
          atHalfTime!();
          animationTicker!.onFrame = null;
        }
      };
    }
    if (kind == MiniEffectKind.explosion) soundboard.play(MiniSound.explosion);
  }
}
