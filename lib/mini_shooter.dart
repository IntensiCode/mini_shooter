import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'components/web_play_screen.dart';
import 'core/mini_common.dart';
import 'core/mini_messaging.dart';
import 'core/mini_soundboard.dart';
import 'input/mini_shortcuts.dart';
import 'mini_world.dart';
import 'util/extensions.dart';
import 'util/fonts.dart';
import 'util/performance.dart';

class MiniShooter extends FlameGame<MiniWorld>
    with HasKeyboardHandlerComponents, MiniMessaging, MiniShortcuts, HasPerformanceTracker {
  //
  final _ticker = Ticker(ticks: 120);

  void _showInitialScreen() {
    if (kIsWeb) {
      world.add(WebPlayScreen());
    } else {
      logInfo('showSplash');
      world.showSplash();
      // world.showTitle();
      // world.showGame();
    }
  }

  MiniShooter() : super(world: MiniWorld()) {
    game = this;
    images = this.images;

    if (kIsWeb) logAnsi = false;
  }

  @override
  onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera = CameraComponent.withFixedResolution(
      width: gameWidth,
      height: gameHeight,
      hudComponents: [_ticks(), _frames()],
    );
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  _ticks() => RenderTps(
        scale: Vector2(0.25, 0.25),
        position: Vector2(0, 0),
        anchor: Anchor.topLeft,
      );

  _frames() => RenderFps(
        scale: Vector2(0.25, 0.25),
        position: Vector2(0, 8),
        anchor: Anchor.topLeft,
        time: () => renderTime,
      );

  @override
  onLoad() async {
    super.onLoad();

    await soundboard.preload();
    await loadFonts(assets);

    final spritesImage = await images.load('mini_shooter.png');
    sprites = SpriteSheet(image: spritesImage, srcSize: Vector2.all(16));

    _showInitialScreen();

    if (dev) {
      onKey('<C-d>', () => _toggleDebug());
      onKey('<C-m>', () => soundboard.toggleMute());
      onKey('<C-0>', () => showScreen(Screen.title));
      onKey('<C-1>', () => showScreen(Screen.game));
      onKey('<C-->', () => _slowDown());
      onKey('<C-=>', () => _speedUp());
      onKey('<C-S-+>', () => _speedUp());
    }
  }

  _toggleDebug() {
    debug = !debug;
    return KeyEventResult.handled;
  }

  _slowDown() {
    if (_timeScale > 0.125) _timeScale /= 2;
  }

  _speedUp() {
    if (_timeScale < 4.0) _timeScale *= 2;
  }

  @override
  update(double dt) => _ticker.generateTicksFor(dt * _timeScale, (it) => super.update(it));

  double _timeScale = 1;
}
