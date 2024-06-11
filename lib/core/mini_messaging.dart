import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/mini_common.dart';
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
  final listeners = <Type, List<dynamic>>{};

  Disposable listen<T extends MiniMessage>(void Function(T) callback) {
    listeners[T] ??= [];
    listeners[T]!.add(callback);
    return Disposable.wrap(() {
      listeners[T]?.remove(callback);
    });
  }

  void send<T extends MiniMessage>(T message) {
    final listener = listeners[T];
    if (listener == null || listener.isEmpty) {
      logWarn('no listener for $T in $listeners');
    } else {
      listener.forEach((it) => it(message));
    }
  }

  @override
  void onRemove() => listeners.clear();
}
