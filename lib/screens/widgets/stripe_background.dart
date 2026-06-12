import 'package:flutter/material.dart';

class StripeBackground extends StatelessWidget {
  final Widget child;
  const StripeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C0709),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _StripeBgPainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _StripeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stripeCount = 12;
    final stripeW = size.width / stripeCount;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRect(rect, Paint()..color = const Color(0xFF1C0709));

    for (int i = 0; i < stripeCount; i++) {
      final x = i * stripeW;
      final stripeRect = Rect.fromLTWH(x, 0, stripeW, size.height);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.black.withValues(alpha: 0.18),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.18),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(stripeRect);
      canvas.drawRect(stripeRect, paint);
    }

    // Top vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
          stops: const [0.0, 0.35],
        ).createShader(rect),
    );

    // Bottom vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
          stops: const [0.0, 0.28],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
