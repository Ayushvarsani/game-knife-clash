import 'dart:math';
import 'package:flutter/material.dart';
import '../../game/utils/board_theme.dart';

/// Mini spinning reactor preview shown on the home screen.
class HomePreviewBoard extends StatefulWidget {
  const HomePreviewBoard({super.key});

  @override
  State<HomePreviewBoard> createState() => _HomePreviewBoardState();
}

class _HomePreviewBoardState extends State<HomePreviewBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spin,
      builder: (_, __) => CustomPaint(
        size: const Size(156, 156),
        painter: _PreviewPainter(_spin.value),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final double t;
  _PreviewPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    final theme = BoardTheme.classicWood;
    final pulse = 0.5 + 0.5 * sin(t * pi * 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * 2 * pi);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawCircle(
      center,
      r + 4,
      Paint()
        ..color = theme.boltHighlight.withValues(alpha: 0.15 + pulse * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawCircle(
      center,
      r,
      Paint()..color = theme.rimColor,
    );

    const segments = 8;
    for (int i = 0; i < segments; i++) {
      final start = i * 2 * pi / segments;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: r - 3),
          start,
          2 * pi / segments,
          false,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = (i.isEven ? theme.ringColors.first : theme.centerColor)
              .withValues(alpha: 0.9),
      );
    }

    canvas.drawCircle(
      center,
      r - 2,
      Paint()
        ..color = theme.boltHighlight.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.restore();

    // Hex hub (doesn't spin)
    final hex = Path();
    for (int i = 0; i < 6; i++) {
      final a = -pi / 2 + i * pi / 3;
      final p = Offset(center.dx + 14 * cos(a), center.dy + 14 * sin(a));
      if (i == 0) {
        hex.moveTo(p.dx, p.dy);
      } else {
        hex.lineTo(p.dx, p.dy);
      }
    }
    hex.close();
    canvas.drawPath(hex, Paint()..color = theme.centerColor);
    canvas.drawCircle(center, 5, Paint()..color = theme.boltHighlight);
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) => old.t != t;
}
