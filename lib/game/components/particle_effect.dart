import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../utils/board_theme.dart';
import '../utils/collectible_type.dart';

class WoodParticle {
  Vector2 position;
  Vector2 velocity;
  double life;
  double maxLife;
  double width;
  double length;
  double angle;
  double rotationSpeed;
  Color color;
  bool isDust; // small dust vs chunky splinter
  double drag;
  double gravity;
  double alphaScale;

  WoodParticle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.width,
    required this.length,
    required this.angle,
    required this.rotationSpeed,
    required this.color,
    this.isDust = false,
    this.drag = 0.90,
    this.gravity = 600,
    this.alphaScale = 1.0,
  }) : maxLife = life;
}

class ParticleEffect extends Component {
  static const _maxParticles = 32;

  final List<WoodParticle> _particles = [];
  final Random _random = Random();

  void clearAll() => _particles.clear();

  void _trimParticles() {
    if (_particles.length <= _maxParticles) return;
    _particles.removeRange(0, _particles.length - _maxParticles);
  }

  void spawnWoodParticles(Vector2 position, {Vector2? boardCenter}) {
    // Prefer emission away from board center so hit feels directional.
    Vector2 outward = Vector2(0, 1);
    if (boardCenter != null) {
      final dir = position - boardCenter;
      if (dir.length2 > 1e-3) {
        outward = dir.normalized();
      }
    }
    final baseAngle = atan2(outward.y, outward.x);

    // Chunky splinters: heavier, directional, and less uniform.
    // Count kept modest — each particle is an alpha-blended draw every frame,
    // so large bursts hurt fill rate on mobile during the busiest moments.
    for (int i = 0; i < 3; i++) {
      final spread = (_random.nextDouble() - 0.5) * 1.55;
      final angle = baseAngle + spread;
      final speed = 260 + _random.nextDouble() * 520;
      final len = 12 + _random.nextDouble() * 24;
      final w = 1.4 + _random.nextDouble() * 2.8;
      _particles.add(WoodParticle(
        position: position.clone() +
            Vector2((_random.nextDouble() - 0.5) * 6, (_random.nextDouble() - 0.5) * 6),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        life: 0.45 + _random.nextDouble() * 0.45,
        width: w,
        length: len,
        // Align shards roughly with flight direction for less "sticky" look.
        angle: angle + (_random.nextDouble() - 0.5) * 0.55,
        rotationSpeed: (_random.nextDouble() - 0.5) * 12,
        drag: 0.915,
        gravity: 720,
        color: [
          const Color(0xFFFF5A2E),
          const Color(0xFFFF8A3D),
          const Color(0xFFFFB63D),
          const Color(0xFF6A7A90),
          const Color(0xFFB8C8D8),
          const Color(0xFFFF3B30),
          const Color(0xFF3A3040),
          const Color(0xFFFF7043),
        ][_random.nextInt(8)],
      ));
    }

    // Fine dust cloud: wider spread and quick fade.
    for (int i = 0; i < 4; i++) {
      final angle = baseAngle + (_random.nextDouble() - 0.5) * 2.2;
      final speed = 40 + _random.nextDouble() * 210;
      _particles.add(WoodParticle(
        position: position.clone(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        life: 0.16 + _random.nextDouble() * 0.22,
        width: 1.1 + _random.nextDouble() * 1.9,
        length: 1.2 + _random.nextDouble() * 2.8,
        angle: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 16,
        drag: 0.83,
        gravity: 280,
        alphaScale: 0.7,
        color: const Color(0xFFFF8A3D).withValues(alpha: 0.5),
        isDust: true,
      ));
    }
    _trimParticles();
  }

  /// Yellow impact burst when a knife hits another knife on the board.
  void spawnCrashParticles(Vector2 position, {required BoardTheme theme}) {
    final accent = theme.boltHighlight;
    final sparkColors = [
      const Color(0xFFFFD700),
      const Color(0xFFFFB300),
      const Color(0xFFFFF176),
      accent,
      Color.lerp(accent, const Color(0xFFFFD700), 0.5)!,
    ];

    for (int i = 0; i < 8; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 180 + _random.nextDouble() * 420;
      _particles.add(WoodParticle(
        position: position.clone(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        life: 0.35 + _random.nextDouble() * 0.45,
        width: 2 + _random.nextDouble() * 3.5,
        length: 4 + _random.nextDouble() * 10,
        angle: angle,
        rotationSpeed: (_random.nextDouble() - 0.5) * 14,
        drag: 0.88,
        gravity: 520,
        color: sparkColors[_random.nextInt(sparkColors.length)],
      ));
    }

    for (int i = 0; i < 4; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 60 + _random.nextDouble() * 160;
      _particles.add(WoodParticle(
        position: position.clone(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        life: 0.2 + _random.nextDouble() * 0.25,
        width: 6 + _random.nextDouble() * 10,
        length: 6 + _random.nextDouble() * 10,
        angle: _random.nextDouble() * 2 * pi,
        rotationSpeed: 0,
        drag: 0.78,
        gravity: 120,
        alphaScale: 0.55,
        color: const Color(0xFFFFD700).withValues(alpha: 0.7),
        isDust: true,
      ));
    }
    _trimParticles();
  }

  void spawnCollectibleParticles(Vector2 position, {required CollectibleType type}) {
    final colors = [
      type.primary,
      type.secondary,
      Colors.white,
      Color.lerp(type.primary, const Color(0xFFFFD700), 0.4)!,
    ];
    for (int i = 0; i < 6; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 150 + _random.nextDouble() * 300;
      _particles.add(WoodParticle(
        position: position.clone(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        life: 0.35 + _random.nextDouble() * 0.3,
        width: 2.5 + _random.nextDouble() * 3,
        length: 6 + _random.nextDouble() * 10,
        angle: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 25,
        color: colors[_random.nextInt(colors.length)],
      ));
    }
    _trimParticles();
  }

  @override
  void update(double dt) {
    for (final p in _particles) {
      p.position += p.velocity * dt;
      p.velocity *= p.drag;
      p.velocity.y += p.gravity * dt;
      p.angle += p.rotationSpeed * dt;
      p.life -= dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    for (final p in _particles) {
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      final alpha = t * t * p.alphaScale;
      paint.color = p.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(p.position.x, p.position.y);
      canvas.rotate(p.angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-p.width / 2, -p.length / 2, p.width, p.length),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }
}
