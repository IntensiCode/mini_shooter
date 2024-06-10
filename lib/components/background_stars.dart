import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import '../core/mini_common.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/random.dart';

final _count = gameWidth.toInt() ~/ 4;
final _slotWidth = gameWidth / _count;
final _blinkiness = 0.001 / _count;

// length have to match animations length. see note below.
final _baseSpeeds = [1.5, 1.75, 1, 0.5, 1.25, 3, 0.75, 0.75, 0.75];

BackgroundStars? _instance;

extension ScriptFunctionsExtension on MiniScriptFunctions {
  BackgroundStars backgroundStars() {
    _instance ??= BackgroundStars();
    if (_instance?.isMounted == true) _instance?.removeFromParent();
    return added(_instance!);
  }
}

class BackgroundStars extends AutoDisposeComponent with MiniScriptFunctions {
  //
  late final List<Star> stars;

  @override
  void onLoad() async {
    final animations = await _createAnimations();
    stars = List.generate(_count, (it) {
      final slot = it * _slotWidth;
      return added(Star(animations, slot)..priority = -100);
    });
  }

  Future<List<SpriteAnimation>> _createAnimations() async {
    final times = [0.1, 0.1, 0.1, 0.1];
    final sheet = this.sheet(await image('stars.png'), 4, 4);
    final blue = sheet.createAnimationWithVariableStepTimes(row: 0, stepTimes: times, loop: false);
    final yellow = sheet.createAnimationWithVariableStepTimes(row: 1, stepTimes: times, loop: false);
    final white = sheet.createAnimationWithVariableStepTimes(row: 2, stepTimes: times, loop: false);
    final red = sheet.createAnimationWithVariableStepTimes(row: 3, stepTimes: times, loop: false);

    // TODO ?
    blue.frames.rotateLeft();
    yellow.frames.rotateLeft();
    white.frames.rotateLeft();
    red.frames.rotateLeft();

    // less of the red one. therefore, only once. and more of the white ones.
    return [blue, yellow, white, red, blue, yellow, white, white, white];
  }

  @override
  void update(double dt) {
    super.update(dt);
    stars.forEach((it) => it.update(dt));
  }
}

class Star extends SpriteAnimationComponent {
  final List<SpriteAnimation> animations;
  late double speed;

  Star(this.animations, double slot) {
    // the initial position determines the star's slot. for this initial
    // position the y is anything across the screen. reset would place all
    // stars above the screen. not what we want initially.
    position.x = slot + random.nextDoubleLimit(_slotWidth);
    position.y = random.nextDoubleLimit(gameHeight);

    // reset to assign animation, speed, opacity randomly:
    reset(resetPosition: false);

    // "play once" hack:
    animationTicker?.onComplete = () {
      // TODO reset? without rotate?
      playing = false;

      // blinky sets opacity to 1. therefore we have to pick a new random
      // opacity when blinky animation is done:
      _setRandomOpacity();
    };
  }

  @override
  void update(double dt) {
    _update(dt);
    super.update(dt);
  }

  void _update(double dt) {
    position.y += speed * dt;
    if (position.y > gameHeight + random.nextInt(16)) {
      reset();
    }
    if (!isActive && random.nextDouble() < _blinkiness) {
      opacity = 1;
      playing = true;
      animationTicker?.reset(); // TODO?
    }
  }

  void reset({bool resetPosition = true}) {
    // for some variation in speed and opacity:
    final variation = random.nextDouble();

    // change star color:
    final which = random.nextInt(animations.length);
    animation = animations[which];

    if (resetPosition) {
      // choose new x in the star's slot. does not matter much with 320 stars
      // on 320 pixels. but still, in case count is reduced... also, reset y
      // to random start above screen.
      final slot = position.x ~/ _slotWidth;
      position.x = slot * _slotWidth + random.nextDoubleLimit(_slotWidth);
      position.y = -random.nextDoubleLimit(16);
    }

    // stop and reset any running animation:
    playing = false;
    animationTicker?.reset();
    animationTicker?.setToLast();

    // apply random opacity, using a non-linear curve.
    _setRandomOpacity(variation);

    // random, somewhat variable speed, on top of the base speed:
    final baseSpeed = _baseSpeeds[which % _baseSpeeds.length];
    final variableSpeed = variation * baseSpeed;
    speed = baseSpeed + variableSpeed;
  }

  void _setRandomOpacity([double? zeroToOne]) {
    final variable = zeroToOne ?? random.nextDouble();
    final opacityCurve = Curves.bounceIn.transform(1 - variable);
    opacity = 0.1 + opacityCurve * 0.4;
  }
}

extension on SpriteAnimationComponent {
  bool get isActive => playing || animationTicker?.done() == false;
}
