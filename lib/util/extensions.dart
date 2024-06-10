import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

extension ComponentExtensions on Component {
  T added<T extends Component>(T it) {
    add(it);
    return it;
  }

  void fadeIn({double seconds = 0.4, bool restart = true}) {
    if (this case OpacityProvider it) {
      if (it.opacity == 1 && !restart) return;
      it.opacity = 0;
    } else {
      throw ArgumentError('Component has to be an OpacityProvider');
    }
    add(OpacityEffect.to(1, EffectController(duration: seconds)));
  }

  void fadeOut({double seconds = 0.4, bool restart = true}) {
    if (this case OpacityProvider it) {
      if (it.opacity == 0 && !restart) return;
      it.opacity = 1;
    } else {
      throw ArgumentError('Component has to be an OpacityProvider');
    }
    add(OpacityEffect.to(0, EffectController(duration: seconds)));
  }

  void runScript(List<(int, void Function())> script) {
    for (final step in script) {
      _doAt(step.$1, () {
        if (!isMounted) return;
        step.$2();
      });
    }
  }

  void _doAt(int millis, Function() what) {
    Future.delayed(Duration(milliseconds: millis)).then((_) => what());
  }
}

extension DynamicListExtensions on List<dynamic> {
  List<T> mapToType<T>() => map((it) => it as T).toList();

  void rotateLeft() => add(removeAt(0));

  void rotateRight() => insert(0, removeLast());
}

extension ListExtensions<T> on List<T> {
  T? removeLastOrNull() {
    if (isEmpty) return null;
    return removeLast();
  }
}

extension RandomExtensions on Random {
  double nextDoubleLimit(double limit) => nextDouble() * limit;

  double nextDoublePM(double limit) => (nextDouble() - nextDouble()) * limit;
}

extension FragmentShaderExtensions on FragmentShader {
  setVec4(int index, Color color) {
    final r = color.red / 255 * color.opacity;
    final g = color.green / 255 * color.opacity;
    final b = color.blue / 255 * color.opacity;
    setFloat(index + 0, r);
    setFloat(index + 1, g);
    setFloat(index + 2, b);
    setFloat(index + 3, color.opacity);
  }
}
