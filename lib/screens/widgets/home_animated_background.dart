import 'dart:math';
import 'package:flutter/material.dart';

/// Drifting ember sparks + soft radial glow for the home screen.
class HomeAnimatedBackground extends StatefulWidget {
  const HomeAnimatedBackground({super.key});

  @override
  State<HomeAnimatedBackground> createState() => _HomeAnimatedBackgroundState();
}

class _HomeAnimatedBackgroundState extends State<HomeAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Ember> _embers = List.generate(24, (i) => _Ember(i));

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _EmberPainter(_ctrl.value, _embers),
        size: Size.infinite,
      ),
    );
  }
}

class _Ember {
  final double seed;
  final double x;
  final double speed;
  final double size;
  final Color color;

  _Ember(int i)
      : seed = i * 0.37,
        x = (i * 0.083) % 1.0,
        speed = 0.08 + (i % 5) * 0.025,
        size = 1.5 + (i % 4) * 1.2,
        color = i.isEven ? const Color(0xFFFF5A2E) : const Color(0xFFFFB63D);
}

class _EmberPainter extends CustomPainter {
  final double t;
  final List<_Ember> embers;

  _EmberPainter(this.t, this.embers);

  @override
  void paint(Canvas canvas, Size size) {
    final glowRect = Rect.fromLTWH(0, size.height * 0.2, size.width, size.height * 0.5);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.7,
          colors: [
            const Color(0xFFFF3B30).withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ).createShader(glowRect),
    );

    for (final e in embers) {
      final phase = (t * e.speed + e.seed) % 1.0;
      final x = e.x * size.width + sin(phase * pi * 4 + e.seed) * 18;
      final y = size.height * (1.05 - phase);
      final alpha = sin(phase * pi).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(x, y),
        e.size,
        Paint()..color = e.color.withValues(alpha: alpha * 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter old) => old.t != t;
}
