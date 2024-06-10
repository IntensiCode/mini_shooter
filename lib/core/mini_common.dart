import 'package:flame/cache.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/mini_messaging.dart';

bool debug = kDebugMode;
bool dev = kDebugMode;

const double gameWidth = 256;
const double gameHeight = 256;
final Vector2 gameSize = Vector2(gameWidth, gameHeight);

const fontScale = gameHeight / 500;
const xCenter = gameWidth / 2;
const yCenter = gameHeight / 2;
const lineHeight = 24 * fontScale;

late Game game;
late Images images;
late CollisionDetection collisions;

// to avoid importing materials elsewhere (which causes clashes sometimes), some color values right here:
const transparent = Colors.transparent;
const black = Colors.black;
const white = Colors.white;

// for this simple game demo, all sprites will be in here after game's onLoad.
late SpriteSheet sprites;

SpriteAnimation player() => sprites.createAnimation(row: 0, stepTime: 0.1, from: 3, to: 6);

SpriteAnimation exhaust() => sprites.createAnimation(row: 1, stepTime: 0.1, from: 3, to: 9);

SpriteAnimation bonny() => sprites.createAnimation(row: 2, stepTime: 0.1, from: 3, to: 9);

SpriteAnimation looker() => sprites.createAnimation(row: 3, stepTime: 0.1, from: 3, to: 9);

SpriteAnimation smiley() => sprites.createAnimation(row: 4, stepTime: 0.1, from: 1, to: 9);

SpriteAnimation explosion() => sprites.createAnimation(row: 6, stepTime: 0.1, from: 3, to: 8)..loop = false;

SpriteAnimation sparkle() => sprites.createAnimation(row: 7, stepTime: 0.1, from: 3, to: 7)..loop = false;

SpriteAnimation hit() => sprites.createAnimation(row: 9, stepTime: 0.05, from: 3, to: 9)..loop = false;

SpriteAnimation energyBall() => sprites.createAnimation(row: 11, stepTime: 0.1, from: 3, to: 7);

SpriteAnimation appear() => sprites.createAnimation(row: 12, stepTime: 0.1, from: 0, to: 9)..loop = false;

SpriteAnimation shield() => sprites.createAnimation(row: 13, stepTime: 0.1, from: 3, to: 7);

SpriteAnimation smoke() => sprites.createAnimation(row: 14, stepTime: 0.05, from: 0, to: 11)..loop = false;

Paint pixelPaint() => Paint()
  ..isAntiAlias = false
  ..filterQuality = FilterQuality.none;

enum Screen {
  game,
  splash,
  title,
}

extension ComponentExtension on Component {
  void nextLevel() => messaging.send('nextLevel', null);

  void showScreen(Screen it) => messaging.send('screen', it);
}

enum MiniItemKind {
  laserCharge(0),
  shield(1),
  missile(2),
  score1(3),
  score2(4),
  score3(5),
  ;

  final int column;

  const MiniItemKind(this.column);
}

mixin Collector {
  void collect(MiniItemKind kind);
}

mixin Defender {
  bool onHit([int hits = 1]);
}

mixin MiniTarget {
  /// returns true when destroyed
  bool applyDamage({double? laser, double? missile});
}
