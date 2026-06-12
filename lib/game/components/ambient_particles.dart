import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Floating ember sparks that drift across the play area.
class AmbientParticles extends Component {
  static const _maxSparks = 18;
  static const _spawnInterval = 0.32;

  final List<_Spark> _sparks = [];
  final Random _rng = Random();
  double _spawnTimer = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _spawnTimer += dt;
    if (_spawnTimer > _spawnInterval &&
        _sparks.length < _maxSparks &&
        parent != null) {
      _spawnTimer = 0;
      _spawnSpark();
    }
    for (final s in _sparks) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.life -= dt;
      s.alpha = (s.life / s.maxLife).clamp(0.0, 1.0);
    }
    _sparks.removeWhere((s) => s.life <= 0);
  }

  void _spawnSpark() {
    final game = findGame();
    if (game == null) return;
    final w = game.size.x;
    final h = game.size.y;
    if (w <= 0 || h <= 0) return;

    _sparks.add(_Spark(
      x: _rng.nextDouble() * w,
      y: h + 8,
      vx: (_rng.nextDouble() - 0.5) * 30,
      vy: -40 - _rng.nextDouble() * 60,
      size: 1.5 + _rng.nextDouble() * 2.5,
      life: 2.0 + _rng.nextDouble() * 1.5,
      color: _rng.nextBool()
          ? const Color(0xFFFF5A2E)
          : const Color(0xFFFFB63D),
    ));
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    for (final s in _sparks) {
      paint.color = s.color.withValues(alpha: s.alpha * 0.55);
      canvas.drawCircle(Offset(s.x, s.y), s.size, paint);
    }
  }
}

class _Spark {
  double x;
  double y;
  final double vx;
  final double vy;
  final double size;
  double life;
  final double maxLife;
  final Color color;
  double alpha = 1;

  _Spark({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.color,
  }) : maxLife = life;
}
