import 'dart:math';
import 'dart:ui' as ui show Image;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/collectible_type.dart';
import '../utils/collectible_renderer.dart';
import '../utils/picture_raster.dart';
import '../utils/game_texture_cache.dart';

/// Bonus pickup on the reactor rim — random fruit each spawn.
class Apple extends PositionComponent {
  final double boardAngle;
  final Vector2 boardCenter;
  final double boardRadius;
  final CollectibleType type;
  bool collected = false;

  Apple({
    required this.boardAngle,
    required this.boardCenter,
    required this.boardRadius,
    required this.type,
  }) : super(
          size: Vector2.all(GameConstants.appleRadius * 2),
          anchor: Anchor.center,
        );

  void updatePosition(double currentBoardAngle) {
    final totalAngle = boardAngle + currentBoardAngle;
    position.setValues(
      boardCenter.x + boardRadius * sin(totalAngle),
      boardCenter.y - boardRadius * cos(totalAngle),
    );
  }

  static const double _pad = 16.0;
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
    if (collected) return;
    if (_cachedImage == null) {
      final r = GameConstants.appleRadius;
      _scale = PictureRaster.deviceScale();
      final cacheKey = 'fruit_${type.name}';
      _cachedImage = GameTextureCache.getOrCreate(cacheKey, () {
        return PictureRaster.rasterize(
          width: size.x,
          height: size.y,
          pad: _pad,
          scale: _scale,
          paint: (c) => CollectibleRenderer.draw(c, Offset(r, r), r, type: type),
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
