import '../util/extensions.dart';
import 'mini_challenger.dart';
import 'mini_enemy_kind.dart';
import 'mini_path.dart';

class MiniWave {
  MiniWave(this.level, this.kind, this.path, double spawnAt, [double spawnRate = 0.5, int count = 8]) {
    count.forEach((it) => remainingSpawnTimes.add(spawnAt + spawnRate * it));
  }

  final int level;
  final MiniEnemyKind kind;
  final MiniPath path;

  final remainingSpawnTimes = <double>[];

  final spawned = <MiniChallenger>[];

  bool get isDone => remainingSpawnTimes.isEmpty && spawned.every((it) => it.isDone);

  MiniChallenger? at(double time) {
    if (remainingSpawnTimes.isEmpty) return null;
    if (remainingSpawnTimes.first > time) return null;
    remainingSpawnTimes.removeAt(0);
    return MiniChallenger(level, kind, path);
  }
}
