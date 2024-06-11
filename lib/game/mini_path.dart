import 'package:flame/components.dart';

class MiniPath {
  MiniPath(this.points) {
    // make list of records for each point plus distance to next point:
    for (final (index, point) in points.indexed) {
      if (index + 1 < points.length) {
        segments.add((point, point.distanceTo(points[index + 1])));
      } else {
        segments.add((point, 0.0));
      }
    }
  }

  final List<Vector2> points;
  final segments = <(Vector2, double)>[];

  MiniPath get reversed => MiniPath(points.reversed.toList());

  void at(double t, Vector2 target) {
    for (final (index, (point, distance)) in segments.indexed) {
      if (t == 0.0 || point == points.last) {
        target.setFrom(point);
        return;
      } else if (t < distance) {
        final next = segments[index + 1].$1;
        target.x = point.x + (next.x - point.x) * (t / distance);
        target.y = point.y + (next.y - point.y) * (t / distance);
        return;
      }
      t -= distance;
    }
  }

  bool isAtEnd(Vector2 target) {
    if (points.last == target) return true;
    return false;
  }
}
