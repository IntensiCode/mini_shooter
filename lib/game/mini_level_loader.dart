import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../scripting/mini_script.dart';
import '../util/tiled_extensions.dart';
import 'mini_enemy.dart';
import 'mini_enemy_kind.dart';
import 'mini_path.dart';
import 'mini_wave.dart';

// TODO set when tilemap is loaded
// required to be correct to map the tile id onto an enemy kind:
const _tileSetWidth = 11;

// lookup table: row in tile map to enemy kind:
final _lookup = <int, MiniEnemyKind>{
  2: MiniEnemyKind.bonny,
  3: MiniEnemyKind.looker,
  4: MiniEnemyKind.smiley,
};

// this will be set the first time a non-existing level is encountered:
int? _wrapLevelAt;

// same but for challenges:
int? _wrapChallengeAt;

// challenger y coordinate factor to use full height of level:
const yFactor = 1.5;

class MiniLevelLoader extends MiniScriptComponent {
  MiniLevelLoader({required this.level});

  final int level;

  late TiledComponent map;

  Future<void> loadLevelData() async {
    final challenge = (level % 5) == 0;
    logInfo('challenge: $challenge');
    if (challenge) {
      await _loadChallengeData();
    } else {
      await _loadLevelData();
    }
  }

  Future<void> _loadChallengeData() async {
    final challenge = level ~/ 5;
    logInfo('load challenge $level => actual $challenge (wrap at $_wrapChallengeAt)');

    final wrap = _wrapChallengeAt;
    if (wrap != null) {
      final actual = ((challenge - 1) % wrap) + 1;
      logInfo('preload challenge $actual instead of $level with wrap $wrap');
      map = await TiledComponent.load('challenge$actual.tmx', Vector2(16.0, 16.0));
    } else {
      try {
        map = await TiledComponent.load('challenge$challenge.tmx', Vector2(16.0, 16.0));
      } catch (e, t) {
        logError('failed to load challenge $challenge: $e', t);
        _wrapChallengeAt = challenge - 1;
        logInfo('wrap at challenge $_wrapChallengeAt');
        await loadLevelData();
      }
    }
  }

  Future<void> _loadLevelData() async {
    final which = level - (level - 1) ~/ 5;
    logInfo('load level $level => actual $which');

    final wrap = _wrapLevelAt;
    if (wrap != null) {
      final actual = ((which - 1) % wrap) + 1;
      logInfo('preload level $actual instead of $level with wrap $wrap');
      map = await TiledComponent.load('level$actual.tmx', Vector2(16.0, 16.0));
    } else {
      try {
        map = await TiledComponent.load('level$level.tmx', Vector2(16.0, 16.0));
      } catch (e, t) {
        logError('failed to load level $which: $e', t);
        _wrapLevelAt = which - 1;
        logInfo('wrap at level $_wrapLevelAt');
        await loadLevelData();
      }
    }
  }

  bool get isChallengingStage => map.getLayer('Challenge') != null;

  Iterable<MiniEnemy> formation() {
    final attackers = (map.getLayer('Attackers') as ObjectGroup).objects;
    return attackers.map((it) => MiniEnemy(it.kind, level, Vector2(it.x, it.y + 16)));
  }

  List<MiniWave> challenge() => _challenge().toList();

  Iterable<MiniWave> _challenge() sync* {
    final data = (map.getLayer('Challenge') as ObjectGroup).objects;
    final paths = _paths(data);
    for (final it in data.where((it) => !it.isPolyline)) {
      final pos = Vector2(it.x + 8, (it.y - 8) * yFactor);
      final path = _pickPath(pos, paths);
      if (path == null) continue;
      yield MiniWave(level, it.kind, path, it.spawnAt ?? 0);
    }
  }

  Iterable<MiniPath> _paths(List<TiledObject> data) {
    final paths = data.where((it) => it.isPolyline);
    final result = <MiniPath>[];
    for (final path in paths) {
      final points = <Vector2>[];
      for (final it in path.polyline) {
        points.add(Vector2(it.x + path.x, (it.y + path.y) * yFactor));
      }
      result.add(MiniPath(points));
    }
    return result;
  }

  MiniPath? _pickPath(Vector2 position, Iterable<MiniPath> paths) {
    for (final p in paths) {
      final d1 = p.points.first.distanceTo(position);
      final d2 = p.points.last.distanceTo(position);
      if (d1 == 0) return p;
      if (d2 == 0) return p.reversed;
    }
    logError('no path found for $position');
    return null;
  }
}

extension on TiledObject {
  MiniEnemyKind get kind => _lookup[(gid! - 1) ~/ _tileSetWidth]!;
}
