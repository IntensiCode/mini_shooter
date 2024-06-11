import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/animation.dart';
import 'package:signals_core/signals_core.dart';

import '../components/press_fire_to_start.dart';
import '../core/mini_common.dart';
import '../core/mini_messaging.dart';
import '../core/mini_soundboard.dart';
import '../util/auto_dispose.dart';
import '../util/bitmap_button.dart';
import '../util/bitmap_font.dart';
import '../util/bitmap_text.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';

// don't look here. at least not initially. none of this you should reuse. this
// is a mess. but the mess works for the case of this demo game. all of this
// should be replaced by what you need for your game.

mixin MiniScriptFunctions on Component, AutoDispose {
  int _autoDisposeCount = 0;

  @override
  onRemove() {
    super.onRemove();
    disposeAll();
  }

  void autoEffect(String hint, void Function() callback) {
    autoDispose(
      'autoEffect-$_autoDisposeCount-$hint',
      effect(
        () => callback(),
        debugLabel: hint,
        onDispose: () => logInfo('effect disposed: $hint'),
      ),
    );
    _autoDisposeCount++;
  }

  void sendMessage<T extends MiniMessage>(T message) => messaging.send(message);

  void onMessage<T extends MiniMessage>(void Function(T) callback) =>
      autoDispose('listen-$T', messaging.listen<T>(callback));

  void clearByType(List types) {
    final what = types.isEmpty ? children : children.where((it) => types.contains(it.runtimeType));
    removeAll(what);
  }

  void delay(double seconds) async {
    final millis = (seconds * 1000).toInt();
    await Stream.periodic(Duration(milliseconds: millis)).first;
  }

  T fadeIn<T extends Component>(T it, {double duration = 1}) {
    it.fadeIn(seconds: duration);
    return it;
  }

  BitmapFont? font;
  double? fontScale;

  fontSelect(BitmapFont? font, {double? scale = 1}) {
    this.font = font;
    fontScale = scale;
  }

  Future<Image> image(String filename) => images.load(filename);

  SpriteSheet sheet(Image image, int columns, int rows) =>
      SpriteSheet.fromColumnsAndRows(image: image, columns: columns, rows: rows);

  Future<SpriteComponent> sprite({
    required String filename,
    Vector2? position,
    Anchor? anchor,
  }) async =>
      added(await loadSprite(filename, position: position, anchor: anchor));

  Future<SpriteComponent> loadSprite(
    String filename, {
    Vector2? position,
    Vector2? size,
    Anchor? anchor,
  }) async {
    return SpriteComponent(
      sprite: await game.loadSprite(filename),
      position: position,
      size: size,
      anchor: anchor,
    );
  }

  SpriteComponent spriteSXY(Sprite sprite, double x, double y, [Anchor anchor = Anchor.center]) =>
      added(SpriteComponent(sprite: sprite, position: Vector2(x, y), anchor: anchor));

  SpriteComponent spriteIXY(Image image, double x, double y, [Anchor anchor = Anchor.center]) =>
      added(SpriteComponent(sprite: Sprite(image), position: Vector2(x, y), anchor: anchor));

  Future<SpriteComponent> spriteXY(String filename, double x, double y, [Anchor anchor = Anchor.center]) async =>
      added(await loadSprite(filename, position: Vector2(x, y), anchor: anchor));

  void fadeInByType<T extends Component>([bool reset = true]) async {
    children.whereType<T>().forEach((it) => it.fadeIn(restart: reset));
  }

  void fadeOutByType<T extends Component>([bool reset = true]) async {
    children.whereType<T>().forEach((it) => it.fadeOut());
  }

  void fadeOutAll([double duration = 1]) {
    for (final it in children) {
      if (it is! OpacityProvider) continue;
      it.add(OpacityEffect.fadeOut(EffectController(duration: duration)));
      it.add(RemoveEffect(delay: duration));
    }
  }

  Future<SpriteAnimation> loadAnimWH(
    String filename,
    int frameWidth,
    int frameHeight, [
    double stepTime = 0.1,
    bool loop = true,
  ]) async {
    final image = await images.load(filename);
    final columns = image.width ~/ frameWidth;
    if (columns * frameWidth != image.width) {
      throw ArgumentError('image width ${image.width} / frame width $frameWidth');
    }
    final rows = image.height ~/ frameHeight;
    if (rows * frameHeight != image.height) {
      throw ArgumentError('image height ${image.height} / frame height $frameHeight');
    }
    return SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: columns * rows,
          amountPerRow: columns,
          stepTime: stepTime,
          textureSize: Vector2(frameWidth.toDouble(), frameHeight.toDouble()),
          loop: loop,
        ));
  }

  Future<SpriteAnimation> loadAnim(
    String filename, {
    required int frames,
    required double stepTimeSeconds,
    required num frameWidth,
    required num frameHeight,
    bool loop = true,
  }) async {
    final frameSize = Vector2(frameWidth.toDouble(), frameHeight.toDouble());
    return game.loadSpriteAnimation(
      filename,
      SpriteAnimationData.sequenced(
        amount: frames.toInt(),
        stepTime: stepTimeSeconds.toDouble(),
        textureSize: frameSize,
        loop: loop,
      ),
    );
  }

  SpriteAnimationComponent makeAnimXY(SpriteAnimation animation, double x, double y, [Anchor anchor = Anchor.center]) =>
      makeAnim(animation, Vector2(x, y), anchor);

  SpriteAnimationComponent makeAnim(SpriteAnimation animation, Vector2 position, [Anchor anchor = Anchor.center]) =>
      added(SpriteAnimationComponent(
        animation: animation,
        position: position,
        anchor: anchor,
      ));

  Future<BitmapButton> menuButtonXY(
    String text,
    double x,
    double y, [
    Anchor? anchor,
    String? bgNinePatch,
    Function(BitmapButton)? onTap,
  ]) {
    return menuButton(text: text, pos: Vector2(x, y), anchor: anchor, bgNinePatch: bgNinePatch, onTap: onTap);
  }

  Future<BitmapButton> menuButton({
    required String text,
    Vector2? pos,
    Anchor? anchor,
    String? bgNinePatch,
    void Function(BitmapButton)? onTap,
  }) async {
    final button = await images.load(bgNinePatch ?? 'button_plain.png');
    final it = BitmapButton(
      bgNinePatch: button,
      text: text,
      font: menuFont,
      fontScale: 0.25,
      position: pos,
      anchor: anchor,
      onTap: onTap ?? (_) => {},
    );
    add(it);
    return it;
  }

  void backgroundMusic(String filename) async {
    filename = "background/$filename";

    dispose('afterTenSeconds');
    dispose('backgroundMusic');
    dispose('backgroundMusic_fadeIn');

    final AudioPlayer player = await soundboard.playBackgroundMusic(filename);
    if (dev) {
      // only in dev: stop music after 10 seconds, to avoid playing multiple times on hot restart.
      final afterTenSeconds = player.onPositionChanged.where((it) => it.inSeconds >= 10).take(1);
      autoDispose('afterTenSeconds', afterTenSeconds.listen((it) => player.stop()));
    }
    autoDispose('backgroundMusic', () => player.stop());
    autoDispose('backgroundMusic_fadeIn', player.fadeIn(musicVolume, seconds: 3));
  }

  void playAudio(String filename) async {
    final player = await soundboard.playAudio(filename);
    autoDispose('playAudio', () => player.stop());
  }

  void pressFireToStart() => add(PressFireToStart());

  void scaleTo(Component it, double scale, double duration, Curve? curve) {
    it.add(
      ScaleEffect.to(
        Vector2.all(scale.toDouble()),
        EffectController(duration: duration.toDouble(), curve: curve ?? Curves.decelerate),
      ),
    );
  }

  BitmapText textXY(String text, double x, double y, {Anchor anchor = Anchor.center, double? scale}) =>
      this.text(text: text, position: Vector2(x, y), anchor: anchor, scale: scale);

  BitmapText text({
    required String text,
    Vector2? position,
    Anchor? anchor,
    double? scale,
  }) {
    final it = BitmapText(
      text: text,
      position: position,
      anchor: anchor ?? Anchor.center,
      font: font,
      scale: scale ?? fontScale ?? 1,
    );
    add(it);
    return it;
  }
}

extension on AudioPlayer {
  StreamSubscription fadeIn(double targetVolume, {double seconds = 3}) {
    final steps = (seconds * 10).toInt();
    return Stream.periodic(const Duration(milliseconds: 100), (it) => targetVolume * it / steps)
        .take(steps)
        .listen((it) => setVolume(it), onDone: () => setVolume(targetVolume));
  }
}
