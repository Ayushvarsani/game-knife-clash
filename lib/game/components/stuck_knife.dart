import 'dart:math';
import 'dart:ui' as ui show Image;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/board_theme.dart';
import '../utils/knife_renderer.dart';
import '../utils/picture_raster.dart';
import '../utils/game_texture_cache.dart';

class StuckKnife extends PositionComponent {
  final double boardAngle;
  final Vector2 boardCenter;
  final double boardRadius;
  final bool isBossKnife;
  final BoardTheme theme;

  StuckKnife({
    required this.boardAngle,
    required this.boardCenter,
    required this.boardRadius,
    this.isBossKnife = false,
    BoardTheme? theme,
  })  : theme = theme ?? BoardTheme.classicWood,
        super(
          size: Vector2(GameConstants.knifeWidth * 2, GameConstants.knifeHeight * 1.4),
          anchor: Anchor.center,
        );

  void updatePosition(double currentBoardAngle) {
    final totalAngle = boardAngle + currentBoardAngle;
    position.setValues(
      boardCenter.x + boardRadius * sin(totalAngle),
      boardCenter.y - boardRadius * cos(totalAngle),
    );
    angle = totalAngle + pi;
  }

  static const double _pad = 12.0;
  ui.Image? _cachedImage;
  double _scale = 1.0;
  final Paint _paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;

  @override
  void onRemove() {
    _cachedImage = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (_cachedImage == null) {
      _scale = PictureRaster.deviceScale();
      final cacheKey = 'stuck_${theme.id.name}_$isBossKnife';
      _cachedImage = GameTextureCache.getOrCreate(cacheKey, () {
        return PictureRaster.rasterize(
          width: size.x,
          height: size.y,
          pad: _pad,
          scale: _scale,
          paint: (c) => KnifeRenderer.drawStuck(
            c,
            Size(size.x, size.y),
            isBoss: isBossKnife,
            theme: theme,
          ),
        );
      });
    }
    PictureRaster.drawTexture(
      canvas,
      _cachedImage!,
      pad: _pad,
      scale: _scale,
      paint: _paint,
    );
  }
}
