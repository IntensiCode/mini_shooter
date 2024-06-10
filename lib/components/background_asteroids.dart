import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

import '../core/mini_common.dart';
import '../scripting/mini_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/random.dart';

const _positionDistribution = Curves.easeInOutCubic;

const _frameSize = 48.0;

const _rotateBaseSeconds = 3.0;
const _rotateVariance = 3.0;

const _baseSpeed = 32;
const _speedVariance = 8.0;

BackgroundAsteroids? _instance;

extension ScriptFunctionsExtension on MiniScriptFunctions {
  BackgroundAsteroids backgroundAsteroids() {
    _instance ??= BackgroundAsteroids();
    if (_instance?.isMounted == true) _instance?.removeFromParent();
    return added(_instance!);
  }
}

class BackgroundAsteroids extends AutoDisposeComponent with MiniScriptFunctions {
  late FragmentProgram program;
  late FragmentShader shader;

  int maxAsteroids = 16;

  double lastEmission = 0;

  @override
  void onLoad() async {
    program = await FragmentProgram.fromAsset('assets/shaders/asteroid.frag');
    shader = program.fragmentShader();
  }

  @override
  void update(double dt) {
    super.update(dt);
    lastEmission += dt;
    final minReleaseInterval = 1 / sqrt(maxAsteroids);
    if (children.length < maxAsteroids && lastEmission >= minReleaseInterval) {
      add(BackgroundAsteroid(shader, _onReset));
      lastEmission = 0;
    }
  }

  void _onReset(BackgroundAsteroid it) {
    if (children.length > maxAsteroids) {
      it.removeFromParent();
    } else {
      it.reset();
    }
  }
}

class BackgroundAsteroid extends PositionComponent {
  final FragmentShader shader;

  final bgPaint = pixelPaint()..colorFilter = const ColorFilter.mode(Color(0xFF000000), BlendMode.srcATop);
  final shaderPaint = pixelPaint()..color = const Color(0x40ffffff);

  late CircleHitbox hitbox;

  late bool xFlipped;
  late Color color1;
  late Color color2;
  late Color color3;
  late double dx;
  late double dy;
  late double rotationSeconds;
  late double shaderSizeFactor;
  late double shaderSeed;

  final void Function(BackgroundAsteroid) _onReset;

  BackgroundAsteroid(this.shader, this._onReset) {
    bgPaint.shader = shader;
    shaderPaint.shader = shader;

    shader.setFloat(0, 48); // w
    shader.setFloat(1, 48); // h
    shader.setFloat(2, 48); // pixels
    shader.setFloat(18, 1); // should_dither

    anchor = Anchor.center;
    size.setAll(_frameSize.toDouble());

    // add(DebugCircleHitbox(radius: 20, anchor: Anchor.center));
    hitbox = added(CircleHitbox(radius: 20, anchor: Anchor.center));

    reset();
  }

  _pickFlipped() => xFlipped = random.nextBool();

  _pickScale() => scale.setAll(0.25 + random.nextDoubleLimit(0.75));

  _pickTint() {
    final tint = Color(random.nextInt(0x20000000));
    color1 = Color.alphaBlend(tint, const Color(0xFFa3a7c2));
    color2 = Color.alphaBlend(tint, const Color(0xFF4c6885));
    color3 = Color.alphaBlend(tint, const Color(0xFF3a3f5e));
  }

  _pickPosition() {
    final it = random.nextDouble();
    final curved = it < 0.5 //
        ? _positionDistribution.transform(it * 2) / 2
        : 1 - _positionDistribution.transform((1 - it) * 2) / 2;

    position.x = (curved * gameWidth) ~/ _frameSize * _frameSize.toDouble();
    position.y = -random.nextDoubleLimit(16) - _frameSize * scale.y;
  }

  _pickSpeed() {
    dx = random.nextDouble() - random.nextDouble();
    dx *= _speedVariance;
    dy = _baseSpeed + random.nextDoubleLimit(_speedVariance);
  }

  _pickRotation() => rotationSeconds = _rotateBaseSeconds + random.nextDoubleLimit(_rotateVariance);

  _pickShaderParams() {
    shaderSizeFactor = 1.5; //+ random.nextDoubleLimit(3);
    shaderSeed = 1 + random.nextDoubleLimit(9);
  }

  reset() {
    _pickFlipped();
    _pickScale();
    _pickTint();
    _pickPosition();
    _pickSpeed();
    _pickRotation();
    _pickShaderParams();
  }

  @override
  void update(double dt) {
    super.update(dt);

    shaderTime += dt / rotationSeconds * (xFlipped ? -1 : 1);

    position.x += dt * dx;
    position.y += dt * dy;

    bool remove = false;
    if (position.y > gameHeight + _frameSize * scale.y) remove = true;
    if (position.x < -_frameSize * scale.x) remove = true;
    if (position.x > gameWidth + _frameSize * scale.x) remove = true;
    if (remove) _onReset(this);
  }

  double shaderTime = 0;

  final rect = const Rect.fromLTWH(0, 0, _frameSize, _frameSize);

  @override
  render(Canvas canvas) {
    super.render(canvas);
    shader.setFloat(3, shaderTime);
    shader.setVec4(4, color1);
    shader.setVec4(8, color2);
    shader.setVec4(12, color3);
    shader.setFloat(16, shaderSizeFactor);
    shader.setFloat(17, shaderSeed);
    canvas.translate(-_frameSize / 2, -_frameSize / 2);
    canvas.drawRect(rect, bgPaint);
    canvas.drawRect(rect, shaderPaint);
    canvas.translate(_frameSize / 2, _frameSize / 2);
  }
}
