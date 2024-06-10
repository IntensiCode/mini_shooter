import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import '../input/mini_game_keys.dart';
import '../scripting/mini_script.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/debug.dart';
import '../util/input_acceleration.dart';
import 'mini_effects.dart';
import 'mini_laser.dart';
import 'mini_state.dart';

enum _PlayerState {
  incoming,
  playing,
  vanishing,
}

class MiniPlayer extends PositionComponent
    with AutoDispose, MiniScriptFunctions, MiniScript, KeyboardHandler, MiniGameKeys, Collector, Defender {
  //
  static const xBase = gameWidth / 2;
  static const yBase = gameHeight * 0.9;

  late final xMovement = InputAcceleration(
    goNegative: () => held[MiniGameKey.left] == true,
    goPositive: () => held[MiniGameKey.right] == true,
    positionLimit: 140,
  );

  late SpriteAnimationComponent ship;
  late SpriteAnimationComponent booster;

  var _state = _PlayerState.incoming;

  void vanish() {
    _state = _PlayerState.vanishing;
    removeAll(children);
    _showIncoming();
  }

  @override
  onRemove() {
    super.onRemove();
    logInfo('onRemove $runtimeType');
    disposeAll();
  }

  @override
  void onLoad() async {
    position.x = xBase;
    position.y = yBase;
    anchor = Anchor.center;

    at(0.0, () => _showIncoming());
    at(0.5, () => _showPlayer());
    at(0.5, () => _igniteEngine());
    at(0.0, () => _go());
  }

  SpriteAnimationComponent _showIncoming() {
    soundboard.play(MiniSound.incoming);
    return makeAnimXY(appear(), 0, 0)
      ..priority = 10
      ..removeOnFinish = true;
  }

  _showPlayer() {
    ship = makeAnimXY(player(), 0, 0)..playing = false;

    _frame = 1;

    add(DebugCircleHitbox(radius: 6, anchor: Anchor.center)..priority = 20);
    add(CircleHitbox(radius: 6, anchor: Anchor.center, collisionType: CollisionType.passive));

    shielded = SpriteAnimationComponent(animation: shield(), anchor: Anchor.center);
    shielded.scale.setAll(1.5);

    autoEffect(() {
      final it = state.shields;
      if (it == 0 && shielded.isMounted) shielded.removeFromParent();
      if (it > 0 && !shielded.isMounted) add(shielded);
    });
  }

  late SpriteAnimationComponent shielded;

  int get _frame => ship.animationTicker?.currentIndex ?? 0;

  set _frame(int it) => ship.animationTicker?.currentIndex = it;

  _igniteEngine() => booster = makeAnimXY(exhaust(), 0, 15);

  _go() {
    add(MiniLaser(this, () => primaryFire, parent!));
    _state = _PlayerState.playing;
  }

  @override
  void onMount() {
    super.onMount();
    sendMessage('player-ready', this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_state == _PlayerState.playing) _onPlaying(dt);
  }

  void _onPlaying(double dt) {
    xMovement.update(dt);
    position.x = xBase + xMovement.position;
    _frame = 1 + xMovement.targetFrame.sign;
    booster.scale.x = _frame == 1 ? 1 : 0.8;
  }

  @override
  void collect(MiniItemKind kind) {
    logInfo('collect $kind');
    switch (kind) {
      case MiniItemKind.laserCharge:
        state.charge++;
        break;
      case MiniItemKind.missile:
        state.missiles++;
        break;
      case MiniItemKind.shield:
        state.shields++;
        break;
      case MiniItemKind.score1:
        state.score += 10;
        break;
      case MiniItemKind.score2:
        state.score += 20;
        break;
      case MiniItemKind.score3:
        state.score += 30;
        break;
    }
  }

  @override
  bool onHit() {
    if (state.shields > 0) {
      shielded.animationTicker?.reset();
      soundboard.play(MiniSound.block);
      state.shields--;
      return false;
    } else {
      state.lives--;
      state.shields = 3;
      state.missiles = 0;
      sendMessage('player-destroyed', null);
      spawnEffect(MiniEffectKind.explosion, position);
      soundboard.play(MiniSound.explosion);
      removeFromParent();
      return true;
    }
  }
}
