import 'package:flame/components.dart';

import '../components/background_asteroids.dart';
import '../components/background_moons.dart';
import '../components/background_stars.dart';
import '../core/mini_common.dart';
import '../core/mini_soundboard.dart';
import '../input/mini_game_keys.dart';
import '../scripting/mini_script.dart';
import '../util/bitmap_text.dart';
import 'mini_formation_stage.dart';
import 'mini_level_loader.dart';

class MiniLevel extends MiniScriptComponent with KeyboardHandler, MiniGameKeys, HasCollisionDetection {
  MiniLevel(this.level);

  final int level;

  @override
  onLoad() async {
    super.onLoad();

    backgroundStars();
    backgroundMoons();
    backgroundAsteroids().maxAsteroids = 0;

    // TODO differentiate challenging stage

    final loader = MiniLevelLoader(level: level);
    await loader.loadLevelData();
    final formation = loader.makeFormation();

    soundboard.play(MiniSound.game_on);
    at(0.1, () async => fadeIn(textXY('Level $level', xCenter, yCenter)));
    at(1.0, () async => fadeIn(textXY('Game on!', xCenter, yCenter + lineHeight)));
    at(2.0, () async => fadeOutByType<BitmapText>());
    at(0.0, () async => add(MiniFormationStage(level, formation)));
  }
}
