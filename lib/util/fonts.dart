import 'dart:ui';

import 'package:flame/cache.dart';

import '../core/mini_common.dart';
import 'bitmap_font.dart';

const textColor = Color(0xFFffcc80);
const successColor = Color(0xFF20ff10);
const errorColor = Color(0xFFff2010);

late BitmapFont fancyFont;
late BitmapFont menuFont;

loadFonts(AssetsCache assets) async {
  fancyFont = await BitmapFont.loadDst(
    images,
    assets,
    'fonts/fancyfont.png',
    charWidth: 12,
    charHeight: 10,
  );
  menuFont = await BitmapFont.loadDst(
    images,
    assets,
    'fonts/menufont.png',
    charWidth: 24,
    charHeight: 24,
  );
}
