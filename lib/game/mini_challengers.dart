import 'package:dart_minilog/dart_minilog.dart';

import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import '../scripting/mini_script.dart';
import '../util/extensions.dart';
import '../util/random.dart';
import 'mini_effects.dart';
import 'mini_extra_items.dart';
import 'mini_wave.dart';

class MiniChallengers extends MiniScriptComponent {
  MiniChallengers(this.level, this.waves);

  final int level;
  final List<MiniWave> waves;

  double spawnTime = 0.0;

  @override
  void update(double dt) {
    super.update(dt);

    if (waves.isNotEmpty) {
      _tickWaves(dt);
    } else if (children.isNotEmpty) {
      //
    } else {
      logInfo('challenge complete');
      sendMessage(ChallengeComplete());
      removeFromParent();
    }
  }

  double get spawnFactor => (1 + level * 0.02).clamp(1, 2);

  void _tickWaves(double dt) {
    final done = [...waves.where((it) => it.isDone)];
    for (final wave in done) {
      final allDefeated = wave.spawned.every((it) => it.defeatedAt != null);
      if (allDefeated && wave.spawned.isNotEmpty) {
        logInfo('wave defeated');
        _spawnBonusItems(wave);
      }
      waves.remove(wave);
    }

    for (final wave in waves) {
      final it = wave.at(spawnTime * spawnFactor);
      if (it == null) continue;
      wave.spawned.add(it);
      add(it);
    }
    spawnTime += dt;
  }

  void _spawnBonusItems(MiniWave wave) {
    // need to use parent because 'this' is being removed right after
    // last enemy defeated. then 'messaging' becomes unavailable!
    final context = parent;
    if (context == null) return;

    wave.spawned.sort((a, b) => a.defeatedAt!.compareTo(b.defeatedAt!));
    final lastDefeated = wave.spawned.last;
    wave.spawned.length.forEach((it) {
      final pos = lastDefeated.position + randomNormalizedVector() * 32;
      final delay = it * 0.1 + random.nextDoubleLimit(0.3);
      spawnEffect(MiniEffectKind.appear, pos, delaySeconds: delay, atHalfTime: () {
        context.spawnItem(pos, {MiniItemKind.score3});
      });
      soundboard.play(MiniSound.challenge);
    });
  }
}
