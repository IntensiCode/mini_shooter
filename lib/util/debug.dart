import 'dart:ui';

import 'package:flame/components.dart';

import '../core/mini_common.dart';

Color? debugHitboxColor = const Color(0x80ff0000);

class DebugCircleHitbox extends CircleComponent with HasVisibility {
  DebugCircleHitbox({
    super.radius,
    super.position,
    super.scale,
    super.angle,
    super.anchor = Anchor.center,
    super.children,
    super.priority,
    super.paint,
    super.paintLayers,
  }) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    if (debugHitboxColor != null) paint.color = debugHitboxColor!;
    priority = 20;
  }

  @override
  bool get isVisible => debug;
}
