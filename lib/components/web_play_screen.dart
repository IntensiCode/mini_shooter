import 'package:flame/components.dart';

import '../../util/auto_dispose.dart';
import '../core/mini_common.dart';
import '../input/mini_shortcuts.dart';
import '../util/bitmap_button.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';

class WebPlayScreen extends AutoDisposeComponent with HasAutoDisposeShortcuts {
  @override
  void onMount() => onKey('<Space>', () => showScreen(Screen.splash));

  @override
  onLoad() async {
    final button = await images.load('button_plain.png');
    const scale = 0.5;
    add(BitmapButton(
      bgNinePatch: button,
      text: 'Start',
      font: menuFont,
      fontScale: scale,
      position: Vector2(gameWidth / 2, gameHeight / 2),
      anchor: Anchor.center,
      onTap: (_) => showScreen(Screen.splash),
    ));
  }
}
