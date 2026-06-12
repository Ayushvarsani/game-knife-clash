import 'dart:math';
import 'dart:ui' as ui show Image;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/board_theme.dart';
import '../utils/knife_renderer.dart';
import '../utils/picture_raster.dart';
import '../utils/game_texture_cache.dart';

class _Piece {
  Vector2 position;
  Vector2 velocity;
  double angularVelocity;
  double angle;
  double life;
  final double maxLife;
  final Path shape;
  final Color color;
  final Color? rimColor;

  _Piece({
    required this.position,
    required this.velocity,
    required this.angularVelocity,
    required this.shape,
    required this.color,
    required this.maxLife,
    this.rimColor,
  })  : angle = 0,
        life = maxLife;
}

class _FlyingKnife {
  Vector2 position;
  Vector2 velocity;
  double angularVelocity;
  double angle;
  double life;
  final bool isBoss;
  final BoardTheme theme;

  _FlyingKnife({
    required this.position,
    required this.velocity,
    required this.angularVelocity,
    required this.angle,
    required this.isBoss,
    required this.theme,
  }) : life = 1.0;
}

class _Spark {
  Vector2 position;
  Vector2 velocity;
  double life;
  final double maxLife;
  final Color color;
  final double size;
  final bool streak;

  _Spark({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.maxLife,
    this.streak = false,
  }) : life = maxLife;
}

class BoardBreak extends Component {
  final Vector2 boardCenter;
  final bool isBoss;
  final BoardTheme theme;
  final List<double> stuckKnifeAngles;
  bool _done = false;
  final VoidCallback onComplete;
  final List<_Piece> _pieces = [];
  final List<_FlyingKnife> _knives = [];
  final List<_Spark> _sparks = [];
  final Random _random = Random();
  double _shockwaveLife = 0.55;
  double _shockwaveRadius = 18;

  BoardBreak({
    required this.boardCenter,
    required this.isBoss,
    required this.theme,
    required this.onComplete,
    this.stuckKnifeAngles = const [],
  });

  @override
  void onMount() {
    super.onMount();
    _spawnPieces();
    _spawnKnives();
    _spawnBurstSparks();
  }

  List<Color> get _pieceColors {
    if (isBoss) {
      return [
        const Color(0xFFFFD54F),
        const Color(0xFFFFB300),
        const Color(0xFFFF8F00),
        const Color(0xFFFFE082),
      ];
    }
    return [
      theme.ringColors.first,
      theme.centerColor,
      theme.ringColors[theme.ringColors.length > 1 ? 1 : 0],
      Color.lerp(theme.ringColors.first, theme.boltHighlight, 0.35)!,
    ];
  }

  void _spawnPieces() {
    final r = GameConstants.boardRadius;
    final chunkCount = 4 + _random.nextInt(2);
    final pieceColors = _pieceColors;
    final rimColor = isBoss ? const Color(0xFFFFD54F) : theme.boltHighlight;

    var cursor = -pi / 2;
    final sizes = List<double>.generate(
      chunkCount,
      (_) => 0.65 + _random.nextDouble() * 0.9,
    );
    final total = sizes.fold<double>(0.0, (a, b) => a + b);

    for (int i = 0; i < chunkCount; i++) {
      final sweep = (2 * pi) * (sizes[i] / total);
      final startAngle = cursor;
      final endAngle = cursor + sweep;
      final midAngle = (startAngle + endAngle) / 2;
      cursor = endAngle;

      final path = Path();
      path.moveTo(0, 0);
      const steps = 16;
      for (int s = 0; s <= steps; s++) {
        final a = startAngle + (endAngle - startAngle) * s / steps;
        path.lineTo(cos(a) * r, sin(a) * r);
      }
      path.close();

      final speed = 220.0 + _random.nextDouble() * 250;
      final angVel = (_random.nextDouble() - 0.5) * 5;
      _pieces.add(_Piece(
        position: boardCenter.clone(),
        velocity: Vector2(cos(midAngle) * speed, sin(midAngle) * speed),
        angularVelocity: angVel,
        shape: path,
        color: pieceColors[i % pieceColors.length],
        rimColor: rimColor,
        maxLife: 1.55,
      ));

      final rimPath = Path();
      const rimSteps = 8;
      for (int s = 0; s <= rimSteps; s++) {
        final a = startAngle + (endAngle - startAngle) * s / rimSteps;
        final pt = Offset(cos(a) * r, sin(a) * r);
        if (s == 0) {
          rimPath.moveTo(pt.dx, pt.dy);
        } else {
          rimPath.lineTo(pt.dx, pt.dy);
        }
      }
      for (int s = rimSteps; s >= 0; s--) {
        final a = startAngle + (endAngle - startAngle) * s / rimSteps;
        rimPath.lineTo(cos(a) * (r - 12), sin(a) * (r - 12));
      }
      rimPath.close();
      _pieces.add(_Piece(
        position: boardCenter.clone(),
        velocity: Vector2(cos(midAngle) * (speed + 30), sin(midAngle) * (speed + 30)),
        angularVelocity: angVel * 1.2,
        shape: rimPath,
        color: rimColor,
        maxLife: 1.3,
      ));
    }

    for (int i = 0; i < 20; i++) {
      final a = _random.nextDouble() * 2 * pi;
      final speed = 160 + _random.nextDouble() * 380;
      final sz = 4.0 + _random.nextDouble() * 12;
      _pieces.add(_Piece(
        position: boardCenter.clone() +
            Vector2((_random.nextDouble() - 0.5) * 30, (_random.nextDouble() - 0.5) * 30),
        velocity: Vector2(cos(a) * speed, sin(a) * speed),
        angularVelocity: (_random.nextDouble() - 0.5) * 15,
        shape: _randomChipPath(sz),
        color: pieceColors[_random.nextInt(pieceColors.length)],
        maxLife: 0.65 + _random.nextDouble() * 0.45,
      ));
    }

    for (int i = 0; i < 8; i++) {
      final a = _random.nextDouble() * 2 * pi;
      final speed = 90 + _random.nextDouble() * 240;
      final len = 10.0 + _random.nextDouble() * 14.0;
      final tipW = 0.8 + _random.nextDouble() * 0.9;
      final baseW = 2.2 + _random.nextDouble() * 2.4;
      final fiber = Path()
        ..moveTo(0, -len * 0.55)
        ..lineTo(tipW, -len * 0.15)
        ..lineTo(baseW, len * 0.5)
        ..lineTo(-baseW, len * 0.5)
        ..lineTo(-tipW, -len * 0.15)
        ..close();
      _pieces.add(_Piece(
        position: boardCenter.clone(),
        velocity: Vector2(cos(a) * speed, sin(a) * speed),
        angularVelocity: (_random.nextDouble() - 0.5) * 16,
        shape: fiber,
        color: Color.lerp(theme.boltHighlight, const Color(0xFFFFD700), 0.4)!,
        maxLife: 0.55 + _random.nextDouble() * 0.35,
      ));
    }
  }

  Path _randomChipPath(double size) {
    final sides = 3 + _random.nextInt(3);
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final a = (2 * pi / sides) * i + _random.nextDouble() * 0.4;
      final dist = size * (0.6 + _random.nextDouble() * 0.4);
      final pt = Offset(cos(a) * dist, sin(a) * dist);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    return path;
  }

  void _spawnKnives() {
    for (final knifeAngle in stuckKnifeAngles) {
      final outDir = knifeAngle;
      final speed = 250.0 + _random.nextDouble() * 180;
      _knives.add(_FlyingKnife(
        position: boardCenter.clone() +
            Vector2(sin(outDir) * GameConstants.boardRadius * 0.6,
                -cos(outDir) * GameConstants.boardRadius * 0.6),
        velocity: Vector2(sin(outDir) * speed, -cos(outDir) * speed),
        angularVelocity: (_random.nextDouble() - 0.5) * 8,
        angle: outDir,
        isBoss: isBoss,
        theme: theme,
      ));
    }
  }

  void _spawnBurstSparks() {
    final accent = theme.boltHighlight;
    final sparkColors = [
      const Color(0xFFFFD700),
      const Color(0xFFFFB300),
      const Color(0xFFFFF176),
      accent,
      Color.lerp(accent, const Color(0xFFFFD700), 0.45)!,
    ];

    for (int i = 0; i < 24; i++) {
      final a = _random.nextDouble() * 2 * pi;
      final speed = 220 + _random.nextDouble() * 560;
      _sparks.add(_Spark(
        position: boardCenter.clone(),
        velocity: Vector2(cos(a) * speed, sin(a) * speed),
        color: sparkColors[_random.nextInt(sparkColors.length)],
        size: 2.0 + _random.nextDouble() * 4.5,
        maxLife: 0.35 + _random.nextDouble() * 0.55,
        streak: _random.nextDouble() < 0.4,
      ));
    }
    for (int i = 0; i < 12; i++) {
      final a = _random.nextDouble() * 2 * pi;
      final speed = 300 + _random.nextDouble() * 400;
      _sparks.add(_Spark(
        position: boardCenter.clone(),
        velocity: Vector2(cos(a) * speed, sin(a) * speed),
        color: Colors.white.withValues(alpha: 0.9),
        size: 1.5,
        maxLife: 0.2 + _random.nextDouble() * 0.35,
        streak: true,
      ));
    }
  }

  @override
  void update(double dt) {
    if (_done) return;

    bool allDone = true;

    for (final p in _pieces) {
      if (p.life > 0) {
        p.position += p.velocity * dt;
        p.velocity *= 0.966;
        p.velocity.y += 420 * dt;
        p.angle += p.angularVelocity * dt;
        p.angularVelocity *= 0.98;
        p.life -= dt;
        allDone = false;
      }
    }

    for (final k in _knives) {
      if (k.life > 0) {
        k.position += k.velocity * dt;
        k.velocity *= 0.972;
        k.velocity.y += 360 * dt;
        k.angle += k.angularVelocity * dt;
        k.life -= dt;
        allDone = false;
      }
    }

    for (final s in _sparks) {
      if (s.life > 0) {
        s.position += s.velocity * dt;
        s.velocity *= s.streak ? 0.91 : 0.86;
        s.life -= dt;
      }
    }
    if (_shockwaveLife > 0) {
      _shockwaveLife -= dt;
      _shockwaveRadius += 560 * dt;
    }

    if (allDone) {
      _done = true;
      Future.microtask(onComplete);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_done) return;

    if (_shockwaveLife > 0) {
      final t = (_shockwaveLife / 0.55).clamp(0.0, 1.0);
      final accent = theme.boltHighlight;
      for (int i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(boardCenter.x, boardCenter.y),
          _shockwaveRadius + i * 20,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5 - i
            ..color = Color.lerp(const Color(0xFFFFD700), accent, 0.3)!
                .withValues(alpha: t * (0.5 - i * 0.12)),
        );
      }
      canvas.drawCircle(
        Offset(boardCenter.x, boardCenter.y),
        GameConstants.boardRadius * 0.5,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: t * 0.2),
      );
    }

    for (final s in _sparks) {
      if (s.life <= 0) continue;
      final alpha = (s.life / s.maxLife).clamp(0.0, 1.0);
      final sparkPaint = Paint()..color = s.color.withValues(alpha: alpha);
      if (s.streak) {
        final n = s.velocity.length2 > 0.001 ? s.velocity.normalized() : Vector2(1, 0);
        final len = 9 + 18 * alpha;
        canvas.drawLine(
          Offset(s.position.x, s.position.y),
          Offset(s.position.x - n.x * len, s.position.y - n.y * len),
          sparkPaint..strokeWidth = 1.2 + s.size * 0.3,
        );
      } else {
        canvas.drawCircle(
          Offset(s.position.x, s.position.y),
          s.size * alpha,
          sparkPaint,
        );
      }
    }

    for (final p in _pieces) {
      if (p.life <= 0) continue;
      final alpha = (p.life / p.maxLife).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(p.position.x, p.position.y);
      canvas.rotate(p.angle);
      canvas.drawPath(
        p.shape,
        Paint()..color = Colors.black.withValues(alpha: alpha * 0.3),
      );
      canvas.drawPath(p.shape, Paint()..color = p.color.withValues(alpha: alpha));
      if (p.rimColor != null) {
        canvas.drawPath(
          p.shape,
          Paint()
            ..color = p.rimColor!.withValues(alpha: alpha * 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      canvas.restore();
    }

    for (final k in _knives) {
      if (k.life <= 0) continue;
      final alpha = k.life.clamp(0.0, 1.0);
      final n = k.velocity.length2 > 0.001 ? k.velocity.normalized() : Vector2.zero();
      canvas.drawLine(
        Offset(k.position.x, k.position.y),
        Offset(k.position.x - n.x * 18, k.position.y - n.y * 18),
        Paint()
          ..color = k.theme.boltHighlight.withValues(alpha: alpha * 0.35)
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round,
      );
      canvas.save();
      canvas.translate(k.position.x, k.position.y);
      canvas.rotate(k.angle + pi);
      _renderFlyingKnife(canvas, k, alpha);
      canvas.restore();
    }
  }

  static const double _knifePad = 12.0;
  static final Paint _knifePaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;

  ui.Image _knifeTexture(_FlyingKnife k) {
    final w = GameConstants.knifeWidth * 2;
    final h = GameConstants.knifeHeight * 1.4;
    final cacheKey = 'break_knife_${k.theme.id.name}_${k.isBoss}';
    return GameTextureCache.getOrCreate(cacheKey, () {
      final scale = PictureRaster.deviceScale();
      return PictureRaster.rasterize(
        width: w,
        height: h,
        pad: _knifePad,
        scale: scale,
        paint: (c) => KnifeRenderer.drawFlying(
          c,
          Size(w, h),
          isBoss: k.isBoss,
          theme: k.theme,
        ),
      );
    });
  }

  void _renderFlyingKnife(Canvas canvas, _FlyingKnife k, double alpha) {
    final w = GameConstants.knifeWidth * 2;
    final h = GameConstants.knifeHeight * 1.4;
    final scale = PictureRaster.deviceScale();
    final image = _knifeTexture(k);
    canvas.save();
    canvas.translate(-w / 2, -h / 2);
    canvas.scale(alpha);
    PictureRaster.drawTexture(
      canvas,
      image,
      pad: _knifePad,
      scale: scale,
      paint: _knifePaint,
    );
    canvas.restore();
  }
}
