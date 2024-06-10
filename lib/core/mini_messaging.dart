import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../util/auto_dispose.dart';

// there are better solutions available than this. but this works for the
// simple game demo at hand.

extension ComponentExtension on Component {
  MiniMessaging get messaging {
    Component? probed = this;
    while (probed is! MiniMessaging) {
      probed = probed?.parent;
      if (probed == null) throw StateError('no messaging mixin found');
    }
    return probed;
  }
}

mixin MiniMessaging on Component {
  final listeners = <String, List<Function(dynamic)>>{};

  Disposable listen(String key, void Function(dynamic) callback) {
    listeners[key] ??= [];
    listeners[key]!.add(callback);
    return Disposable.wrap(() => listeners[key]?.remove(callback));
  }

  void send(String key, dynamic message) {
    final listener = listeners[key];
    if (listener == null || listener.isEmpty) {
      logWarn('no listener for $key');
    } else {
      listener.forEach((it) => it(message));
    }
  }

  @override
  void onRemove() => listeners.clear();
}
