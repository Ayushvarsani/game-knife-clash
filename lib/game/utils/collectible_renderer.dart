import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'collectible_type.dart';

/// Fruit bonus pickup art for the game board and HUD.
class CollectibleRenderer {
  CollectibleRenderer._();

  /// Gold tally badge for lifetime / session fruit counters in Flutter UI.
  static void drawTallyBadge(Canvas canvas, Offset center, double radius) {
    _glow(canvas, center, radius, const Color(0xFFFFB63D));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: [
            Color(0xFFFFF4C2),
            Color(0xFFFFB63D),
            Color(0xFFE88A12),
            Color(0xFFB86500),
          ],
          stops: [0.0, 0.42, 0.78, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius * 0.82,
      Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.14,
    );
    final star = Path();
    const points = 5;
    for (int i = 0; i < points * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / points;
      final r = i.isEven ? radius * 0.42 : radius * 0.2;
      final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFC107)],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.5)),
    );
    _highlight(canvas, center, radius * 0.9);
  }

  static void draw(
    Canvas canvas,
    Offset center,
    double radius, {
    required CollectibleType type,
  }) {
    switch (type) {
      case CollectibleType.apple:
        _drawApple(canvas, center, radius, type);
      case CollectibleType.orange:
        _drawOrange(canvas, center, radius, type);
      case CollectibleType.grape:
        _drawGrape(canvas, center, radius, type);
      case CollectibleType.watermelon:
        _drawWatermelon(canvas, center, radius, type);
      case CollectibleType.banana:
        _drawBanana(canvas, center, radius, type);
      case CollectibleType.cherry:
        _drawCherry(canvas, center, radius, type);
      case CollectibleType.strawberry:
        _drawStrawberry(canvas, center, radius, type);
      case CollectibleType.lemon:
        _drawLemon(canvas, center, radius, type);
    }
  }

  static void _glow(Canvas canvas, Offset c, double r, Color color) {
    if (r > 10) {
      canvas.drawCircle(
        c,
        r * 1.25,
        Paint()
          ..color = color.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  static void _highlight(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      Offset(c.dx - r * 0.28, c.dy - r * 0.28),
      r * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  static void _drawApple(Canvas canvas, Offset c, double r, CollectibleType type) {
    _glow(canvas, c, r, type.primary);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [const Color(0xFFFF5B5B), type.primary, type.secondary],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      Offset(c.dx, c.dy - r * 0.88),
      r * 0.16,
      Paint()..color = type.secondary.withValues(alpha: 0.6),
    );
    _highlight(canvas, c, r);
    _stemAndLeaf(canvas, c, r, type.leafColor);
  }

  static void _drawOrange(Canvas canvas, Offset c, double r, CollectibleType type) {
    _glow(canvas, c, r, type.primary);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFB74D), type.primary, type.secondary],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawLine(
        c,
        Offset(c.dx + r * 0.7 * math.cos(a), c.dy + r * 0.7 * math.sin(a)),
        Paint()
          ..color = type.secondary.withValues(alpha: 0.25)
          ..strokeWidth = 0.8,
      );
    }
    canvas.drawCircle(
      Offset(c.dx, c.dy - r * 0.9),
      r * 0.12,
      Paint()..color = type.secondary.withValues(alpha: 0.5),
    );
    _highlight(canvas, c, r);
    _stem(canvas, c, r);
  }

  static void _drawGrape(Canvas canvas, Offset c, double r, CollectibleType type) {
    _glow(canvas, c, r, type.primary);
    final berries = [
      Offset(c.dx, c.dy - r * 0.35),
      Offset(c.dx - r * 0.42, c.dy - r * 0.05),
      Offset(c.dx + r * 0.42, c.dy - r * 0.05),
      Offset(c.dx - r * 0.22, c.dy + r * 0.38),
      Offset(c.dx + r * 0.22, c.dy + r * 0.38),
      Offset(c.dx, c.dy + r * 0.55),
    ];
    for (final b in berries) {
      canvas.drawCircle(
        b,
        r * 0.34,
        Paint()
          ..shader = RadialGradient(
            colors: [type.primary.withValues(alpha: 0.95), type.secondary],
          ).createShader(Rect.fromCircle(center: b, radius: r * 0.34)),
      );
    }
    _stem(canvas, c, r, stemTop: c.dy - r * 0.75);
  }

  static void _drawWatermelon(Canvas canvas, Offset c, double r, CollectibleType type) {
    _glow(canvas, c, r, type.primary);
    final slice = Path()
      ..moveTo(c.dx, c.dy - r)
      ..arcTo(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        math.pi,
        false,
      )
      ..close();
    canvas.drawPath(
      slice,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [type.primary, const Color(0xFF27AE60), type.secondary],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      slice,
      Paint()
        ..color = const Color(0xFF1E8449)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (int i = 0; i < 5; i++) {
      final seed = Offset(
        c.dx + (i - 2) * r * 0.22,
        c.dy + r * 0.15 + (i % 2) * r * 0.12,
      );
      canvas.drawOval(
        Rect.fromCenter(center: seed, width: r * 0.12, height: r * 0.2),
        Paint()..color = const Color(0xFF2C1810),
      );
    }
    _highlight(canvas, c, r * 0.85);
  }

  static void _drawBanana(Canvas canvas, Offset c, double r, CollectibleType type) {
    _glow(canvas, c, r, type.primary);
    final banana = Path()
      ..moveTo(c.dx - r * 0.15, c.dy + r * 0.75)
      ..quadraticBezierTo(
        c.dx - r * 1.1,
        c.dy - r * 0.1,
        c.dx + r * 0.35,
        c.dy - r * 0.85,
      )
      ..quadraticBezierTo(
        c.dx + r * 0.55,
        c.dy - r * 0.45,
        c.dx + r * 0.25,
        c.dy + r * 0.55,
      )
      ..quadraticBezierTo(
        c.dx - r * 0.05,
        c.dy + r * 0.95,
        c.dx - r * 0.15,
        c.dy + r * 0.75,
      );
    canvas.drawPath(
      banana,
      Paint()
        ..shader = LinearGradient(
          colors: [type.primary, type.secondary],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      banana,
      Paint()
        ..color = type.secondary.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    _highlight(canvas, Offset(c.dx + r * 0.1, c.dy - r * 0.2), r * 0.5);
  }

  static void _drawCherry(Canvas canvas, Offset c, double r, CollectibleType type) {
    _glow(canvas, c, r, type.primary);
    final left = Offset(c.dx - r * 0.38, c.dy + r * 0.2);
    final right = Offset(c.dx + r * 0.38, c.dy + r * 0.2);
    for (final b in [left, right]) {
      canvas.drawCircle(
        b,
        r * 0.48,
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xFFFF6090), type.primary, type.secondary],
          ).createShader(Rect.fromCircle(center: b, radius: r * 0.48)),
      );
      _highlight(canvas, b, r * 0.35);
    }
    final stem = Paint()
      ..color = const Color(0xFF5D3A1A)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx - r * 0.38, c.dy - r * 0.2), Offset(c.dx, c.dy - r * 0.95), stem);
    canvas.drawLine(Offset(c.dx + r * 0.38, c.dy - r * 0.2), Offset(c.dx, c.dy - r * 0.95), stem);
    canvas.drawLine(Offset(c.dx, c.dy - r * 0.95), Offset(c.dx + r * 0.15, c.dy - r * 1.15), stem);
  }

  static void _drawStrawberry(Canvas canvas, Offset c, double r, CollectibleType type) {
    _glow(canvas, c, r, type.primary);
    final body = Path()
      ..moveTo(c.dx, c.dy - r * 0.55)
      ..quadraticBezierTo(c.dx + r * 0.95, c.dy, c.dx, c.dy + r * 0.85)
      ..quadraticBezierTo(c.dx - r * 0.95, c.dy, c.dx, c.dy - r * 0.55);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFF6B7A), type.primary, type.secondary],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        canvas.drawCircle(
          Offset(
            c.dx + (col - 1) * r * 0.28,
            c.dy + row * r * 0.22 - r * 0.05,
          ),
          1.2,
          Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.85),
        );
      }
    }
    final leaves = Path()
      ..moveTo(c.dx, c.dy - r * 0.55)
      ..lineTo(c.dx - r * 0.45, c.dy - r * 0.95)
      ..lineTo(c.dx - r * 0.1, c.dy - r * 0.72)
      ..lineTo(c.dx, c.dy - r * 1.05)
      ..lineTo(c.dx + r * 0.1, c.dy - r * 0.72)
      ..lineTo(c.dx + r * 0.45, c.dy - r * 0.95)
      ..close();
    canvas.drawPath(leaves, Paint()..color = type.leafColor);
    _highlight(canvas, Offset(c.dx - r * 0.15, c.dy - r * 0.1), r * 0.4);
  }

  static void _drawLemon(Canvas canvas, Offset c, double r, CollectibleType type) {
    _glow(canvas, c, r, type.secondary);
    final lemon = Path()
      ..addOval(Rect.fromCenter(
        center: c,
        width: r * 1.5,
        height: r * 1.1,
      ));
    canvas.drawPath(
      lemon,
      Paint()
        ..shader = RadialGradient(
          colors: [type.primary, type.secondary, const Color(0xFFF9A825)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: r * 1.5, height: r * 1.1),
      Paint()
        ..color = type.secondary.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    _highlight(canvas, c, r);
    _stem(canvas, c, r, stemTop: c.dy - r * 0.62);
  }

  static void _stem(Canvas canvas, Offset c, double r, {double? stemTop}) {
    final top = stemTop ?? c.dy - r * 0.88;
    canvas.drawLine(
      Offset(c.dx + r * 0.05, top),
      Offset(c.dx + r * 0.18, top - r * 0.35),
      Paint()
        ..color = const Color(0xFF5D3A1A)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _stemAndLeaf(Canvas canvas, Offset c, double r, Color leaf) {
    _stem(canvas, c, r);
    final leafPath = Path()
      ..moveTo(c.dx + r * 0.18, c.dy - r * 1.05)
      ..quadraticBezierTo(
        c.dx + r * 0.55,
        c.dy - r * 1.45,
        c.dx + r * 0.85,
        c.dy - r * 1.15,
      )
      ..quadraticBezierTo(
        c.dx + r * 0.55,
        c.dy - r * 1.05,
        c.dx + r * 0.18,
        c.dy - r * 1.05,
      );
    canvas.drawPath(leafPath, Paint()..color = leaf);
  }
}
