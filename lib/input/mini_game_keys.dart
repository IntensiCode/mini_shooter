import 'package:flame/components.dart';
import 'package:flutter/services.dart';

enum MiniGameKey {
  left,
  right,
  up,
  down,
  primaryFire,
  secondaryFire,
  inventory,
  useOrExecute,
}

mixin MiniGameKeys on KeyboardHandler {
  // just guessing for now what i may need... doesn't matter.. just to have something for now..

  static final leftKeys = ['Arrow Left', 'A'];
  static final rightKeys = ['Arrow Right', 'D'];
  static final downKeys = ['Arrow Down', 'S'];
  static final upKeys = ['Arrow Up', 'W'];
  static final primaryFireKeys = ['Control', 'Space', 'J'];
  static final secondaryFireKeys = ['Shift', 'K'];
  static final inventoryKeys = ['Tab', 'Home', 'I'];
  static final useOrExecuteKeys = ['End', 'U'];

  static final mapping = {
    MiniGameKey.left: leftKeys,
    MiniGameKey.right: rightKeys,
    MiniGameKey.up: upKeys,
    MiniGameKey.down: downKeys,
    MiniGameKey.primaryFire: primaryFireKeys,
    MiniGameKey.secondaryFire: secondaryFireKeys,
    MiniGameKey.inventory: inventoryKeys,
    MiniGameKey.useOrExecute: useOrExecuteKeys,
  };

  // held states

  final held = <MiniGameKey, bool>{}..addEntries(MiniGameKey.values.map((it) => MapEntry(it, false)));

  bool get left => held[MiniGameKey.left] == true;

  bool get right => held[MiniGameKey.right] == true;

  bool get up => held[MiniGameKey.up] == true;

  bool get down => held[MiniGameKey.down] == true;

  bool get primaryFire => held[MiniGameKey.primaryFire] == true;

  bool get secondaryFire => held[MiniGameKey.secondaryFire] == true;

  bool isHeld(MiniGameKey key) => held[key] == true;

  String label(LogicalKeyboardKey key) {
    final s = key.synonyms.singleOrNull;
    if (s != null) return label(s);

    final check = key.keyLabel;
    if (check == ' ') return 'Space';
    return check;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyRepeatEvent) {
      return true; // super.onKeyEvent(event, keysPressed);
    }
    if (event case KeyDownEvent it) {
      final check = label(it.logicalKey);
      for (final entry in mapping.entries) {
        final key = entry.key;
        final keys = entry.value;
        if (keys.contains(check)) {
          held[key] = true;
        }
      }
    }
    if (event case KeyUpEvent it) {
      final check = label(it.logicalKey);
      for (final entry in mapping.entries) {
        final key = entry.key;
        final keys = entry.value;
        if (keys.contains(check)) {
          held[key] = false;
        }
      }
    }
    return super.onKeyEvent(event, keysPressed);
  }
}
