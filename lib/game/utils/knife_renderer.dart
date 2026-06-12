import 'package:flutter/material.dart';
import 'board_theme.dart';

/// Shared art for the flying and stuck Rush Spike — thicker blade, premium metal + neon.
class KnifeRenderer {
  KnifeRenderer._();

  static void drawFlying(Canvas canvas, Size size, {required bool isBoss, BoardTheme? theme}) {
    if (isBoss) {
      _drawBoss(canvas, size, stuck: false);
    } else {
      _drawRushSpike(canvas, size, stuck: false, theme: theme);
    }
  }

  static void drawStuck(Canvas canvas, Size size, {required bool isBoss, BoardTheme? theme}) {
    if (isBoss) {
      _drawBoss(canvas, size, stuck: true);
    } else {
      _drawRushSpike(canvas, size, stuck: true, theme: theme);
    }
  }

  static void drawMini(Canvas canvas, Size size, {bool isBoss = false, bool used = false}) {
    if (used) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.30, 0, size.width * 0.40, size.height),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF1A1018).withValues(alpha: 0.5),
      );
      return;
    }
    if (isBoss) {
      _drawBoss(canvas, size, stuck: false, scale: 0.88);
    } else {
      _drawRushSpike(canvas, size, stuck: false, scale: 0.88);
    }
  }

  static void _drawRushSpike(
    Canvas canvas,
    Size size, {
    required bool stuck,
    BoardTheme? theme,
    double scale = 1.0,
  }) {
    final w = size.width * scale;
    final h = size.height * scale;
    final ox = (size.width - w) / 2;
    final oy = (size.height - h) / 2;
    canvas.save();
    canvas.translate(ox, oy);

    final cx = w / 2;
    final accent = theme?.guardColor ?? const Color(0xFFFF5A2E);
    final handleBase = theme?.handleColor ?? const Color(0xFF1A1420);
    final stripe = theme?.handleStripe ?? const Color(0xFFFF3B30);

    if (!stuck) {
      // Soft glow behind blade
      final bladeGlow = Path()
        ..moveTo(cx, -2)
        ..lineTo(cx - w * 0.36, h * 0.48)
        ..lineTo(cx, h * 0.42)
        ..lineTo(cx + w * 0.36, h * 0.48)
        ..close();
      canvas.drawPath(
        bladeGlow,
        Paint()
          ..color = accent.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Thicker diamond blade
      final blade = Path()
        ..moveTo(cx, 0)
        ..lineTo(cx - w * 0.34, h * 0.48)
        ..lineTo(cx, h * 0.41)
        ..lineTo(cx + w * 0.34, h * 0.48)
        ..close();

      canvas.drawPath(
        blade,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF1E2838),
              const Color(0xFF5A6A7A),
              const Color(0xFFD0DCE8),
              const Color(0xFFF4F8FC),
              const Color(0xFF8A9AAA),
              const Color(0xFF2A3444),
            ],
            stops: const [0.0, 0.2, 0.45, 0.55, 0.78, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, w, h * 0.48)),
      );

      // Neon edge
      canvas.drawPath(
        blade,
        Paint()
          ..color = accent.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );

      // Center ridge + shine
      canvas.drawLine(
        Offset(cx, 3),
        Offset(cx, h * 0.40),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.65)
          ..strokeWidth = 1.4,
      );
      canvas.drawLine(
        Offset(cx - w * 0.08, h * 0.12),
        Offset(cx - w * 0.14, h * 0.32),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 1.0,
      );
    } else {
      final stubW = w * 0.36;
      final stub = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - stubW / 2, h * 0.33, stubW, h * 0.12),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        stub,
        Paint()
          ..shader = LinearGradient(
            colors: [const Color(0xFF8A9AAA), const Color(0xFFD0DCE8), const Color(0xFF5A6A7A)],
          ).createShader(stub.outerRect),
      );
      canvas.drawRRect(
        stub,
        Paint()
          ..color = accent.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    // Collar — wider metallic band
    final collarRect = Rect.fromLTWH(cx - w * 0.62, h * 0.435, w * 1.24, h * 0.075);
    canvas.drawRRect(
      RRect.fromRectAndRadius(collarRect, const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent, accent.withValues(alpha: 0.7), const Color(0xFF2A2030)],
        ).createShader(collarRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.58, h * 0.438, w * 1.16, h * 0.022),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    // Thicker grip
    final gripTop = h * 0.505;
    final gripH = h * 0.36;
    final gripRect = Rect.fromLTWH(cx - w * 0.36, gripTop, w * 0.72, gripH);
    final gripRR = RRect.fromRectAndRadius(gripRect, const Radius.circular(5));
    canvas.drawRRect(gripRR, Paint()..color = handleBase);
    canvas.drawRRect(
      gripRR,
      Paint()
        ..color = accent.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.save();
    canvas.clipRRect(gripRR);
    for (int i = 0; i < 6; i++) {
      final slotY = gripTop + gripH * (0.10 + i * 0.15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.28, slotY, w * 0.56, h * 0.032),
          const Radius.circular(2),
        ),
        Paint()..color = stripe.withValues(alpha: 0.5 + (i % 2) * 0.25),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.14, gripTop + 2, w * 0.10, gripH - 4),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
    canvas.restore();

    // Energy cell — larger pommel
    final cellCy = h * 0.925;
    final cellR = w * 0.26;
    canvas.drawCircle(
      Offset(cx, cellCy),
      cellR + 3,
      Paint()
        ..color = accent.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      Offset(cx, cellCy),
      cellR,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.5), accent, accent.withValues(alpha: 0.4), handleBase],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cellCy), radius: cellR)),
    );
    canvas.drawCircle(
      Offset(cx - cellR * 0.28, cellCy - cellR * 0.28),
      cellR * 0.32,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    canvas.restore();
  }

  static void _drawBoss(Canvas canvas, Size size, {required bool stuck, double scale = 1.0}) {
    final w = size.width * scale;
    final h = size.height * scale;
    final ox = (size.width - w) / 2;
    final oy = (size.height - h) / 2;
    canvas.save();
    canvas.translate(ox, oy);
    final cx = w / 2;
    const gold = Color(0xFFFFD54F);
    const crimson = Color(0xFFFF3B30);

    if (!stuck) {
      final blade = Path()
        ..moveTo(cx, 0)
        ..lineTo(cx - w * 0.36, h * 0.50)
        ..lineTo(cx, h * 0.43)
        ..lineTo(cx + w * 0.36, h * 0.50)
        ..close();
      canvas.drawPath(
        blade,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFFDE7), Color(0xFFFFF176), Color(0xFFFFB300), Color(0xFFFF8F00)],
          ).createShader(Rect.fromLTWH(0, 0, w, h * 0.50)),
      );
      canvas.drawPath(
        blade,
        Paint()
          ..color = gold.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.18, h * 0.33, w * 0.36, h * 0.12),
          const Radius.circular(3),
        ),
        Paint()..color = gold,
      );
    }

    final collarRect = Rect.fromLTWH(cx - w * 0.65, h * 0.435, w * 1.30, h * 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(collarRect, const Radius.circular(4)),
      Paint()..color = crimson,
    );

    final gripRect = Rect.fromLTWH(cx - w * 0.36, h * 0.515, w * 0.72, h * 0.34);
    final gripRR = RRect.fromRectAndRadius(gripRect, const Radius.circular(5));
    canvas.drawRRect(gripRR, Paint()..color = const Color(0xFF3A0810));
    canvas.save();
    canvas.clipRRect(gripRR);
    final wrap = Paint()..color = gold..strokeWidth = h * 0.035;
    for (int i = 0; i < 6; i++) {
      final y = h * 0.515 + (h * 0.34 / 6) * i;
      canvas.drawLine(Offset(cx - w * 0.38, y), Offset(cx + w * 0.38, y + h * 0.02), wrap);
    }
    canvas.restore();

    canvas.drawCircle(Offset(cx, h * 0.925), w * 0.28, Paint()..color = gold);

    canvas.restore();
  }
}
