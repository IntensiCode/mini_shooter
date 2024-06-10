import 'package:signals_core/signals_core.dart';

MiniState state = MiniState();

enum MiniStateId {
  charge,
  lives,
  missiles,
  score,
  shields,
}

class MiniState {
  final data = {
    MiniStateId.charge: signal(0),
    MiniStateId.lives: signal(3),
    MiniStateId.missiles: signal(0),
    MiniStateId.score: signal(0),
    MiniStateId.shields: signal(3),
  };

  operator [](MiniStateId id) => data[id]!.value;

  operator []=(MiniStateId id, int value) => data[id]!.value = value;

  int get charge => data[MiniStateId.charge]!.value;

  int get lives => data[MiniStateId.lives]!.value;

  int get missiles => data[MiniStateId.missiles]!.value;

  int get score => data[MiniStateId.score]!.value;

  int get shields => data[MiniStateId.shields]!.value;

  set charge(int value) => data[MiniStateId.charge]!.value = value;

  set lives(int value) => data[MiniStateId.lives]!.value = value;

  set missiles(int value) => data[MiniStateId.missiles]!.value = value;

  set score(int value) => data[MiniStateId.score]!.value = value;

  set shields(int value) => data[MiniStateId.shields]!.value = value;
}
