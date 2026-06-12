import 'dart:math';
import 'dart:ui' as ui show Image;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/board_theme.dart';
import '../utils/knife_renderer.dart';
import '../utils/picture_raster.dart';
import '../utils/game_texture_cache.dart';

enum KnifeState { idle, flying, stuck, collided }

class Knife extends PositionComponent {
  KnifeState state = KnifeState.idle;
  double velocity = 0;
  bool isBossKnife;
  BoardTheme theme;

  double _idlePhase = 0;
  Vector2 _baseSpawn = Vector2.zero();

  Knife({required Vector2 position, this.isBossKnife = false, BoardTheme? theme})
      : theme = theme ?? BoardTheme.classicWood,
        super(
          position: position,
          size: Vector2(GameConstants.knifeWidth * 2, GameConstants.knifeHeight * 1.4),
          anchor: Anchor.center,
        ) {
    _baseSpawn = position.clone();
  }

  void throwKnife() {
    if (state == KnifeState.collided || state == KnifeState.flying) return;
    state = KnifeState.flying;
    velocity = -GameConstants.knifeSpeed;
  }

  double _gravity = 0;
  double _rotationSpeed = 0;

  void fallBack() {
    state = KnifeState.collided;
    velocity = -GameConstants.knifeSpeed * 0.6;
    _gravity = GameConstants.knifeSpeed * 6.5;
    _rotationSpeed = 6.0;
  }

  static const double _deceleration = 400.0;

  void resetToSpawn(Vector2 spawnPos, {bool isBossKnife = false, BoardTheme? theme}) {
    position = spawnPos.clone();
    _baseSpawn = spawnPos.clone();
    state = KnifeState.idle;
    velocity = 0;
    angle = 0;
    _gravity = 0;
    _rotationSpeed = 0;
    _idlePhase = 0;
    this.isBossKnife = isBossKnife;
    if (theme != null) this.theme = theme;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state == KnifeState.idle) {
      _idlePhase += dt;
      // Gentle bob + subtle glow pulse at spawn
      position.y = _baseSpawn.y + sin(_idlePhase * 4.5) * 3.5;
      scale.setValues(1.0 + sin(_idlePhase * 3.2) * 0.03, 1.0 + sin(_idlePhase * 3.2) * 0.03);
    } else {
      scale.setValues(1, 1);
    }

    if (state == KnifeState.flying) {
      if (velocity < -GameConstants.knifeMinSpeed) {
        velocity += _deceleration * dt;
      }
      position.y += velocity * dt;
    } else if (state == KnifeState.collided) {
      velocity += _gravity * dt;
      position.y += velocity * dt;
      angle += _rotationSpeed * dt;
    }
  }

  static const double _pad = 12.0;
  ui.Image? _cachedImage;
  double _scale = 1.0;
  bool? _cachedBoss;
  BoardTheme? _cachedTheme;
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
    if (state == KnifeState.collided) {
      final glow = Paint()
        ..color = theme.boltHighlight.withValues(alpha: 0.2);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.x / 2, size.y / 2),
          width: size.x * 1.2,
          height: size.y * 0.7,
        ),
        glow,
      );
    }

    if (_cachedImage == null ||
        _cachedBoss != isBossKnife ||
        _cachedTheme != theme) {
      _scale = PictureRaster.deviceScale();
      final cacheKey = 'flying_${theme.id.name}_$isBossKnife';
      _cachedImage = GameTextureCache.getOrCreate(cacheKey, () {
        return PictureRaster.rasterize(
          width: size.x,
          height: size.y,
          pad: _pad,
          scale: _scale,
          paint: (c) => KnifeRenderer.drawFlying(
            c,
            Size(size.x, size.y),
            isBoss: isBossKnife,
            theme: theme,
          ),
        );
      });
      _cachedBoss = isBossKnife;
      _cachedTheme = theme;
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
