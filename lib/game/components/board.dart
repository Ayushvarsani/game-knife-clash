import 'dart:math';
import 'dart:ui' as ui show Image;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/board_theme.dart';
import '../utils/picture_raster.dart';
import '../utils/game_texture_cache.dart';
import 'board_rhythm.dart';

class Board extends PositionComponent {
  final bool isBoss;
  final BoardTheme theme;
  final List<double> bossSpikeAngles;
  double rotationSpeed;
  bool _reversing;
  double _directionTimer = 0;
  double _directionChangeInterval;
  final double _baseDirChangeInterval;
  final bool directionChanges;
  final bool hasSpeedBursts;
  final bool hasHalfSpinRhythm;
  final bool advancedRhythm;
  final double _halfSpinSpeedMultiplier;
  final BoardRhythmController _rhythmController;
  double _burstTimer = 0;
  double _burstInterval = 3.0;
  bool _inBurst = false;
  double _burstDuration = 0;
  final double _baseRotationSpeed;
  final Random _random = Random();
  double _rhythmTimer = 0;
  late double _rhythmInterval;
  bool _inHalfSpin = false;
  double _halfSpinRadiansDone = 0;

  bool _bossPhaseActive = false;
  double _bossPhaseCountdown = 0;
  bool _bossPhaseArmed = false;
  double _pulseTime = 0;
  double _crashFlashTimer = 0;
  double _crashWaveRadius = 0;
  static const double _crashFlashDuration = 0.6;

  /// Cached static board art, rasterized ONCE per board instance into a GPU
  /// texture. A Picture replays every draw command (dozens of gradients/blurs)
  /// on the GPU each frame; an Image is a single textured quad. Rasterizing it
  /// removes the sustained per-frame shader load that heated the device and
  /// caused the rotating-board stutter + input lag after a few minutes.
  ui.Image? _staticImage;

  /// Extra margin so the disc's outer glow/halo isn't clipped by the texture.
  static const double _staticPad = 48.0;

  /// Texture is rasterized at device pixel ratio so it stays crisp when scaled.
  double _staticScale = 1.0;

  final Paint _staticPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;

  Board({
    required Vector2 position,
    required this.rotationSpeed,
    required this.theme,
    this.isBoss = false,
    bool reverseDirection = false,
    this.directionChanges = false,
    this.bossSpikeAngles = const [],
    this.hasSpeedBursts = false,
    this.hasHalfSpinRhythm = false,
    this.advancedRhythm = false,
    double halfSpinInterval = 4.5,
    double halfSpinSpeedMultiplier = 1.5,
    double dirChangeInterval = 2.0,
    Random? rhythmRandom,
  })  : _reversing = reverseDirection,
        _baseRotationSpeed = rotationSpeed,
        _halfSpinSpeedMultiplier = halfSpinSpeedMultiplier,
        _rhythmController = BoardRhythmController(random: rhythmRandom),
        _rhythmInterval = halfSpinInterval,
        _directionChangeInterval = dirChangeInterval,
        _baseDirChangeInterval = dirChangeInterval,
        super(
          position: position,
          size: Vector2.all(GameConstants.boardRadius * 2),
          anchor: Anchor.center,
        );

  static const double _maxRotationSpeed = 5.0;
  static const double _telegraphDuration = 0.4;

  void triggerBossPhase() {
    if (_bossPhaseActive || _bossPhaseArmed) return;
    _bossPhaseArmed = true;
    _bossPhaseCountdown = _telegraphDuration;
  }

  /// Yellow shockwave when a knife collides with the board.
  void triggerCrashFlash() {
    _crashFlashTimer = _crashFlashDuration;
    _crashWaveRadius = GameConstants.boardRadius * 0.2;
  }

  double get crashFlashProgress =>
      _crashFlashTimer > 0 ? (_crashFlashTimer / _crashFlashDuration).clamp(0.0, 1.0) : 0.0;

  @override
  void onMount() {
    super.onMount();
    _buildStaticImage();
  }

  @override
  void onRemove() {
    _staticImage = null;
    super.onRemove();
  }

  void _buildStaticImage() {
    _staticScale = PictureRaster.deviceScale();
    final center = Offset(size.x / 2, size.y / 2);
    final r = GameConstants.boardRadius;
    final cacheKey = 'board_${theme.id.name}_$isBoss';
    _staticImage = GameTextureCache.getOrCreate(cacheKey, () {
      return PictureRaster.rasterize(
        width: size.x,
        height: size.y,
        pad: _staticPad,
        scale: _staticScale,
        paint: (canvas) {
          if (isBoss) {
            _drawBonusReactor(canvas, center, r, 0.5);
          } else {
            _drawReactorDisc(canvas, center, r, theme, 0.5, 0);
          }
        },
      );
    });
  }

  void _activateBossPhase() {
    _bossPhaseActive = true;
    _bossPhaseArmed = false;
    rotationSpeed = (_currentBaseSpeed).clamp(0.0, _maxRotationSpeed);
    _directionChangeInterval = 1.2 + _random.nextDouble() * 0.3;
    _directionTimer = 0;
  }

  double get _currentBaseSpeed =>
      _bossPhaseActive ? _baseRotationSpeed * 1.15 : _baseRotationSpeed;

  void _endHalfSpin() {
    _inHalfSpin = false;
    _halfSpinRadiansDone = 0;
    rotationSpeed = _currentBaseSpeed;
    _rhythmTimer = 0;
    _rhythmInterval = _jitterHalfSpinInterval(_rhythmInterval);
  }

  double _jitterHalfSpinInterval(double base) =>
      (base * (0.92 + _random.nextDouble() * 0.16)).clamp(2.4, 6.5);

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt;

    if (_crashFlashTimer > 0) {
      _crashFlashTimer -= dt;
      _crashWaveRadius += 520 * dt;
    }

    if (_bossPhaseArmed) {
      _bossPhaseCountdown -= dt;
      if (_bossPhaseCountdown <= 0) _activateBossPhase();
    }

    if (hasSpeedBursts && !_inHalfSpin) {
      _burstTimer += dt;
      if (_inBurst) {
        _burstDuration -= dt;
        if (_burstDuration <= 0) {
          _inBurst = false;
          rotationSpeed = _currentBaseSpeed;
          _burstTimer = 0;
          _burstInterval = 3.0 + _random.nextDouble() * 3.0;
          _directionTimer = 0;
          if (!_bossPhaseActive) {
            _directionChangeInterval = _baseDirChangeInterval *
                (0.9 + _random.nextDouble() * 0.2);
          }
        }
      } else if (_burstTimer >= _burstInterval) {
        _inBurst = true;
        rotationSpeed = (_currentBaseSpeed * (1.5 + _random.nextDouble() * 0.45))
            .clamp(0.0, _maxRotationSpeed);
        _burstDuration = 0.6 + _random.nextDouble() * 0.6;
        _burstTimer = 0;
      }
    }

    if (advancedRhythm && !_inBurst && !_bossPhaseArmed) {
      rotationSpeed = _rhythmController.tick(
        dt: dt,
        baseSpeed: _currentBaseSpeed,
        maxSpeed: _maxRotationSpeed,
      );
    } else if (hasHalfSpinRhythm && !_inBurst && !_bossPhaseArmed) {
      if (_inHalfSpin) {
        _halfSpinRadiansDone += rotationSpeed * dt;
        if (_halfSpinRadiansDone >= pi) {
          _endHalfSpin();
        }
      } else {
        rotationSpeed = _currentBaseSpeed;
        _rhythmTimer += dt;
        if (_rhythmTimer >= _rhythmInterval) {
          _inHalfSpin = true;
          _halfSpinRadiansDone = 0;
          rotationSpeed = (_currentBaseSpeed * _halfSpinSpeedMultiplier)
              .clamp(0.0, _maxRotationSpeed);
          _rhythmTimer = 0;
        }
      }
    }

    final rhythmBusy = advancedRhythm
        ? _rhythmController.isActive
        : _inHalfSpin;
    if ((directionChanges || _bossPhaseActive) && !_inBurst && !rhythmBusy) {
      _directionTimer += dt;
      if (_directionTimer >= _directionChangeInterval) {
        _reversing = !_reversing;
        _directionTimer = 0;
        if (_bossPhaseActive) {
          _directionChangeInterval = 1.2 + _random.nextDouble() * 0.6;
        } else {
          _directionChangeInterval = _baseDirChangeInterval *
              (0.9 + _random.nextDouble() * 0.2);
        }
      }
    }

    angle += (_reversing ? -1 : 1) * rotationSpeed * dt;
  }

  double get bossPhaseProgress =>
      _bossPhaseArmed ? 1.0 - (_bossPhaseCountdown / _telegraphDuration).clamp(0.0, 1.0) : 0.0;

  @override
  void render(Canvas canvas) {
    if (_staticImage == null) _buildStaticImage();

    final center = Offset(size.x / 2, size.y / 2);
    final r = GameConstants.boardRadius;
    final telegraph = bossPhaseProgress;
    final crashT = crashFlashProgress;
    final accent = theme.boltHighlight;

    // Single textured draw (was dozens of gradient/blur shader calls per frame).
    PictureRaster.drawTexture(
      canvas,
      _staticImage!,
      pad: _staticPad,
      scale: _staticScale,
      paint: _staticPaint,
    );

    // Only draw overlays when an effect is active — keeps per-frame work near zero.
    if (telegraph > 0) {
      canvas.drawCircle(
        center,
        r + telegraph * 18,
        Paint()
          ..color = const Color(0xFFFF3B30).withValues(alpha: (1 - telegraph) * 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5,
      );
    }
    if (crashT > 0) _drawCrashFlash(canvas, center, r, crashT, accent);
  }

  void _drawReactorDisc(
    Canvas canvas,
    Offset center,
    double r,
    BoardTheme t,
    double pulse,
    double telegraph,
  ) {
    final glowAlpha = 0.22 + pulse * 0.14 + telegraph * 0.28;
    final accent = t.boltHighlight;
    final sweep = _pulseTime * 1.8;

    // Drop shadow
    canvas.drawCircle(
      Offset(center.dx + 4, center.dy + 6),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Dual outer halo
    canvas.drawCircle(
      center,
      r + 16,
      Paint()
        ..color = accent.withValues(alpha: glowAlpha * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      center,
      r + 8,
      Paint()
        ..color = accent.withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Dark metal base with depth
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            t.ringColors.first.withValues(alpha: 0.9),
            t.rimColor,
            const Color(0xFF120A0E),
            const Color(0xFF060304),
          ],
          stops: const [0.15, 0.5, 0.82, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // 8 wedge segments — gradient turbine blades
    const segments = 8;
    for (int i = 0; i < segments; i++) {
      final start = i * 2 * pi / segments;
      final end = start + 2 * pi / segments;
      final segPath = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: r - 8), start, end - start, false)
        ..close();
      final baseColor = i.isEven ? t.ringColors[i % t.ringColors.length] : t.centerColor;
      final segPulse = 0.08 * sin(_pulseTime * 4.2 + i * 0.9);
      final litColor = Color.lerp(baseColor, t.boltHighlight, (0.12 + segPulse).clamp(0.0, 0.35))!;
      canvas.drawPath(
        segPath,
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              litColor.withValues(alpha: 0.95),
              baseColor.withValues(alpha: 0.55),
              const Color(0xFF0E0A0C).withValues(alpha: 0.9),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
      // Segment edge highlight
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r - 10),
        start + 0.04,
        (end - start) - 0.08,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: i.isEven ? 0.08 : 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Metallic shine sweep
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r - 4),
      sweep - 0.6,
      1.0,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: sweep - 0.6,
          endAngle: sweep + 0.4,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r))
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.55,
    );

    // Inner groove ring
    canvas.drawCircle(
      center,
      r - 42,
      Paint()
        ..color = const Color(0xFF080506).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    canvas.drawCircle(
      center,
      r - 42,
      Paint()
        ..color = accent.withValues(alpha: 0.12 + pulse * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Outer bevel rim — double neon ring
    canvas.drawCircle(
      center,
      r - 1,
      Paint()
        ..color = const Color(0xFF1A1218)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawCircle(
      center,
      r - 2,
      Paint()
        ..color = accent.withValues(alpha: 0.45 + pulse * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawCircle(
      center,
      r - 6,
      Paint()
        ..color = accent.withValues(alpha: 0.2 + pulse * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner energy arcs
    for (int i = 0; i < 6; i++) {
      final a = i * pi / 3 + _pulseTime * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r - 30),
        a + 0.10,
        pi / 3 - 0.20,
        false,
        Paint()
          ..color = accent.withValues(alpha: 0.3 + pulse * 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round,
      );
    }

    // LED nodes on rim — jewel style
    for (int i = 0; i < 12; i++) {
      final nodeAngle = i * pi / 6;
      final nx = center.dx + (r - 9) * cos(nodeAngle);
      final ny = center.dy + (r - 9) * sin(nodeAngle);
      final lit = (i + (_pulseTime * 4).floor()) % 3 == 0;
      if (lit) {
        canvas.drawCircle(
          Offset(nx, ny),
          9,
          Paint()
            ..color = accent.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
      canvas.drawCircle(
        Offset(nx, ny),
        5,
        Paint()
          ..shader = RadialGradient(
            colors: lit
                ? [Colors.white, accent, accent.withValues(alpha: 0.6)]
                : [t.boltColor.withValues(alpha: 0.8), const Color(0xFF1A1018)],
          ).createShader(Rect.fromCircle(center: Offset(nx, ny), radius: 5)),
      );
      canvas.drawCircle(
        Offset(nx - 1.5, ny - 1.5),
        1.8,
        Paint()..color = lit ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.15),
      );
    }

    _drawHexHub(canvas, center, 24, t.centerColor, t.centerDotColor, accent, pulse);

    if (telegraph > 0) {
      canvas.drawCircle(
        center,
        r + telegraph * 18,
        Paint()
          ..color = const Color(0xFFFF3B30).withValues(alpha: (1 - telegraph) * 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5,
      );
    }
  }

  void _drawBonusReactor(Canvas canvas, Offset center, double r, double pulse) {
    canvas.drawCircle(
      center,
      r + 14,
      Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.22 + pulse * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFD54F), Color(0xFFFF8F00), Color(0xFFE65100)],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    const segments = 10;
    for (int i = 0; i < segments; i++) {
      final start = i * 2 * pi / segments;
      final end = start + 2 * pi / segments;
      final segPath = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: r - 4), start, end - start, false)
        ..close();
      final segPulse = sin(_pulseTime * 4.2 + i * 0.7) * 0.12;
      canvas.drawPath(
        segPath,
        Paint()
          ..color = (i.isEven ? const Color(0xFFFFE082) : const Color(0xFFFFB300))
              .withValues(alpha: 0.62 + pulse * 0.18 + segPulse),
      );
    }

    canvas.drawCircle(
      center,
      r - 2,
      Paint()
        ..color = const Color(0xFFFFF176).withValues(alpha: 0.65 + pulse * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    for (int i = 0; i < 16; i++) {
      final ba = i * pi / 8;
      final bx = center.dx + (r - 7) * cos(ba);
      final by = center.dy + (r - 7) * sin(ba);
      canvas.drawCircle(Offset(bx, by), 4.5, Paint()..color = const Color(0xFFE65100));
      canvas.drawCircle(Offset(bx, by), 2.5, Paint()..color = const Color(0xFFFFF176));
    }

    for (int i = 0; i < 8; i++) {
      final sa = i * pi / 4;
      final sx = center.dx + (r - 22) * cos(sa);
      final sy = center.dy + (r - 22) * sin(sa);
      _drawStar(canvas, Offset(sx, sy), 5, const Color(0xFFFFFFFF));
    }

    _drawHexHub(
      canvas,
      center,
      26,
      const Color(0xFFFFB300),
      const Color(0xFFFFF9C4),
      const Color(0xFFFFD54F),
      pulse,
    );
  }

  void _drawCrashFlash(
    Canvas canvas,
    Offset center,
    double r,
    double progress,
    Color accent,
  ) {
    const yellow = Color(0xFFFFD700);
    const amber = Color(0xFFFFB300);
    final fade = (1 - progress).clamp(0.0, 1.0);

    canvas.drawCircle(
      center,
      r + 6,
      Paint()..color = yellow.withValues(alpha: fade * 0.38),
    );

    for (int i = 0; i < 3; i++) {
      final wave = (_crashWaveRadius + i * 22) * (0.85 + i * 0.08);
      canvas.drawCircle(
        center,
        wave,
        Paint()
          ..color = Color.lerp(yellow, accent, 0.3)!
              .withValues(alpha: fade * (0.5 - i * 0.12))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 - i.toDouble(),
      );
    }

    canvas.drawCircle(
      center,
      r * 0.4,
      Paint()
        ..color = amber.withValues(alpha: fade * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  void _drawHexHub(
    Canvas canvas,
    Offset center,
    double radius,
    Color base,
    Color core,
    Color accent,
    double pulse,
  ) {
    canvas.drawCircle(
      center,
      radius + 6,
      Paint()
        ..color = accent.withValues(alpha: 0.15 + pulse * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final hex = Path();
    for (int i = 0; i < 6; i++) {
      final a = -pi / 2 + i * pi / 3;
      final p = Offset(center.dx + radius * cos(a), center.dy + radius * sin(a));
      if (i == 0) {
        hex.moveTo(p.dx, p.dy);
      } else {
        hex.lineTo(p.dx, p.dy);
      }
    }
    hex.close();
    canvas.drawPath(
      hex,
      Paint()
        ..shader = RadialGradient(
          colors: [base.withValues(alpha: 0.95), base, const Color(0xFF0A0608)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawPath(
      hex,
      Paint()
        ..color = accent.withValues(alpha: 0.55 + pulse * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    for (int i = 0; i < 6; i++) {
      final a = -pi / 2 + i * pi / 3;
      final px = center.dx + radius * 0.72 * cos(a);
      final py = center.dy + radius * 0.72 * sin(a);
      canvas.drawCircle(Offset(px, py), 2.2, Paint()..color = accent.withValues(alpha: 0.5));
    }
    canvas.drawCircle(
      center,
      radius * 0.48,
      Paint()
        ..shader = RadialGradient(
          colors: [core, core.withValues(alpha: 0.7), accent.withValues(alpha: 0.3)],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.48)),
    );
    canvas.drawCircle(
      Offset(center.dx - radius * 0.14, center.dy - radius * 0.14),
      radius * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerA = -pi / 2 + i * 2 * pi / 5;
      final innerA = outerA + pi / 5;
      final ox = center.dx + r * cos(outerA);
      final oy = center.dy + r * sin(outerA);
      final ix = center.dx + (r * 0.45) * cos(innerA);
      final iy = center.dy + (r * 0.45) * sin(innerA);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.85));
  }
}
