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
  void spawnEffect(MiniEffectKind kind, Vector2 position) => messaging.send('spawn-effect', (kind, position));
}

enum MiniEffectKind {
  appear,
  explosion,
  hit,
  smoke,
  sparkle,
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
    onMessage('spawn-effect', (data) {
      final anim = animations[data.$1]!;
      final it = _pool.removeLastOrNull() ?? MiniEffect(_recycle);
      it.kind = data.$1;
      it.animation = anim;
      it.position.setFrom(data.$2);
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

  @override
  void onMount() {
    animationTicker!.reset();
    animationTicker!.onComplete = () => _recycle(this);
    if (kind == MiniEffectKind.explosion) soundboard.play(MiniSound.explosion);
  }
}
