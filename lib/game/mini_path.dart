import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

class MiniPath {
  MiniPath(this.points) {
    // make list of records for each point plus distance to next point:
    for (final (index, point) in points.indexed) {
      if (index + 1 < points.length) {
        length += point.distanceTo(points[index + 1]);
      }
    }

    final offsets = points.map((it) => it.toOffset()).toList();
    spline = CatmullRomSpline.precompute(offsets);
  }

  var length = 0.0;
  final List<Vector2> points;
  late final CatmullRomSpline spline;

  MiniPath get reversed => MiniPath(points.reversed.toList());

  void at(double t, Vector2 target) {
    final out = spline.transform((t / length).clamp(0.0, 1.0));
    target.x = out.dx;
    target.y = out.dy;
  }

  bool isAtEnd(double t) {
    if (t >= length) return true;
    return false;
  }
}
