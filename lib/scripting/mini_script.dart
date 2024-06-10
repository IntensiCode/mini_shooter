import 'dart:async';

import '../util/auto_dispose.dart';
import 'mini_script_functions.dart';

class MiniScriptComponent extends AutoDisposeComponent with MiniScriptFunctions, MiniScript {}

mixin MiniScript on AutoDispose, MiniScriptFunctions {
  final script = <Future Function()>[];

  StreamSubscription? active;

  void clearScript() => script.clear();

  void at(double deltaSeconds, Function() execute) {
    script.add(() async {
      final millis = (deltaSeconds * 1000).toInt();
      await Future.delayed(Duration(milliseconds: millis)).then((_) async {
        if (!isMounted) return;
        return await execute();
      });
    });
  }

  StreamSubscription executeScript() {
    final it = Stream.fromIterable(script).asyncMap((it) async {
      if (!isMounted) return;
      return await it();
    });
    active = it.listen((it) {});
    return active!;
  }

  @override
  void onMount() {
    super.onMount();
    executeScript();
  }

  @override
  void onRemove() {
    super.onRemove();
    active?.cancel();
    active = null;
  }
}
