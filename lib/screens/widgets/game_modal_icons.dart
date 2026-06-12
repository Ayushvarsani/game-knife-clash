import 'dart:math' as math;
import 'package:flutter/material.dart';

enum GameModalIconKind {
  gameOver,
  paused,
  play,
  restart,
  home,
  trophy,
  keepPlaying,
  update,
}

/// Custom neon-styled icons for game modals.
class GameModalIcon extends StatelessWidget {
  final GameModalIconKind kind;
  final Color color;
  final double size;

  const GameModalIcon({
    super.key,
    required this.kind,
    required this.color,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GameModalIconPainter(kind: kind, color: color),
    );
  }
}

class _GameModalIconPainter extends CustomPainter {
  final GameModalIconKind kind;
  final Color color;

  _GameModalIconPainter({required this.kind, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case GameModalIconKind.gameOver:
        _paintGameOver(canvas, size);
      case GameModalIconKind.paused:
        _paintPaused(canvas, size);
      case GameModalIconKind.play:
        _paintPlay(canvas, size);
      case GameModalIconKind.restart:
        _paintRestart(canvas, size);
      case GameModalIconKind.home:
        _paintHome(canvas, size);
      case GameModalIconKind.trophy:
        _paintTrophy(canvas, size);
      case GameModalIconKind.keepPlaying:
        _paintKeepPlaying(canvas, size);
      case GameModalIconKind.update:
        _paintUpdate(canvas, size);
    }
  }

  void _paintGameOver(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final arm = size.width * 0.28;
    final stroke = size.width * 0.11;
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - arm, cy - arm), Offset(cx + arm, cy + arm), paint);
    canvas.drawLine(Offset(cx + arm, cy - arm), Offset(cx - arm, cy + arm), paint);
  }

  void _paintPaused(Canvas canvas, Size size) {
    final barW = size.width * 0.18;
    final barH = size.height * 0.52;
    final gap = size.width * 0.14;
    final top = (size.height - barH) / 2;
    final left = (size.width - barW * 2 - gap) / 2;
    final r = Radius.circular(barW * 0.35);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top, barW, barH), r),
      Paint()..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left + barW + gap, top, barW, barH), r),
      Paint()..color = color,
    );
  }

  void _paintPlay(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.36, size.height * 0.22)
      ..lineTo(size.width * 0.36, size.height * 0.78)
      ..lineTo(size.width * 0.78, size.height * 0.50)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintRestart(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.30;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi * 0.85,
      math.pi * 1.35,
      false,
      paint,
    );
    final tip = Offset(
      cx + r * math.cos(math.pi * 0.85),
      cy + r * math.sin(math.pi * 0.85),
    );
    final arrow = Path()
      ..moveTo(tip.dx - size.width * 0.14, tip.dy - size.width * 0.06)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + size.width * 0.06, tip.dy - size.width * 0.14);
    canvas.drawPath(arrow, paint);
  }

  void _paintHome(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final roof = Path()
      ..moveTo(w * 0.5, h * 0.18)
      ..lineTo(w * 0.82, h * 0.44)
      ..lineTo(w * 0.18, h * 0.44)
      ..close();
    canvas.drawPath(roof, Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.26, h * 0.44, w * 0.48, h * 0.40),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.42, h * 0.58, w * 0.16, h * 0.26),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = color.withValues(alpha: 0.35),
    );
  }

  void _paintTrophy(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cup = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.22, w * 0.44, h * 0.38),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(cup, Paint()..color = color);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.44, h * 0.58, w * 0.12, h * 0.14),
      Paint()..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.70, w * 0.40, h * 0.08),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = color,
    );
    canvas.drawArc(
      Rect.fromLTWH(w * 0.12, h * 0.28, w * 0.18, h * 0.22),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.07
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromLTWH(w * 0.70, h * 0.28, w * 0.18, h * 0.22),
      -math.pi / 2,
      -math.pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.07
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintKeepPlaying(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.24, w * 0.76, h * 0.52),
      Radius.circular(w * 0.10),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.08,
    );
    final play = Path()
      ..moveTo(w * 0.40, h * 0.34)
      ..lineTo(w * 0.40, h * 0.66)
      ..lineTo(w * 0.68, h * 0.50)
      ..close();
    canvas.drawPath(play, Paint()..color = color);
    canvas.drawCircle(Offset(w * 0.22, h * 0.34), w * 0.04, Paint()..color = color);
    canvas.drawCircle(Offset(w * 0.22, h * 0.66), w * 0.04, Paint()..color = color);
  }

  void _paintUpdate(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Upward arrow shaft.
    canvas.drawLine(Offset(cx, h * 0.66), Offset(cx, h * 0.20), stroke);

    // Arrow head.
    final head = Path()
      ..moveTo(cx - w * 0.20, h * 0.38)
      ..lineTo(cx, h * 0.18)
      ..lineTo(cx + w * 0.20, h * 0.38);
    canvas.drawPath(head, stroke);

    // Base tray (download/install hint).
    final tray = Path()
      ..moveTo(w * 0.22, h * 0.74)
      ..lineTo(w * 0.22, h * 0.82)
      ..lineTo(w * 0.78, h * 0.82)
      ..lineTo(w * 0.78, h * 0.74);
    canvas.drawPath(tray, stroke);
  }

  @override
  bool shouldRepaint(covariant _GameModalIconPainter old) =>
      old.kind != kind || old.color != color;
}
