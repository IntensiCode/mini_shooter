import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../scripting/mini_script.dart';
import '../util/tiled_extensions.dart';
import 'mini_enemy.dart';
import 'mini_enemy_kind.dart';

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
int? _wrapAt;

class MiniLevelLoader extends MiniScriptComponent {
  MiniLevelLoader({required this.level});

  final int level;

  late TiledComponent map;

  Future<void> loadLevelData() async {
    final wrap = _wrapAt;
    if (wrap != null) {
      final actual = ((level - 1) % wrap) + 1;
      logInfo('preload level $actual instead of $level with wrap $wrap');
      map = await TiledComponent.load('level$actual.tmx', Vector2(16.0, 16.0));
    } else {
      try {
        map = await TiledComponent.load('level$level.tmx', Vector2(16.0, 16.0));
      } catch (e, t) {
        logError('failed to load level $level: $e', t);
        _wrapAt = level - 1;
        logInfo('wrap at level $_wrapAt');
        await loadLevelData();
      }
    }
  }

  bool get isChallengingStage => map.getLayer('Challengers') != null;

  Iterable<MiniEnemy> makeFormation() {
    final layer = map.getLayer('Attackers') as ObjectGroup;
    final attackers = layer.objects;

    final lookup = <int, MiniEnemyKind>{
      2: MiniEnemyKind.bonny,
      3: MiniEnemyKind.looker,
      4: MiniEnemyKind.smiley,
    };
    final result = <MiniEnemy>[];
    for (final it in attackers) {
      final xy = Vector2(it.x, it.y + 16);
      final tile = it.gid;
      if (tile == null) continue;
      final kindId = (tile - 1) ~/ _tileSetWidth;
      final kind = lookup[kindId];
      if (kind == null) continue;
      result.add(MiniEnemy(kind, level, xy));
    }
    return result;
  }

// TODO challenging stage
}
