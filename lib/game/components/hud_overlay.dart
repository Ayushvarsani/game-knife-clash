import 'dart:ui' show Picture, PictureRecorder;
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/board_theme.dart';
import '../utils/knife_renderer.dart';
import '../utils/collectible_renderer.dart';

/// Plain data snapshot passed to HudOverlay each frame.
class HudData {
  final int score;
  final int apples;
  final int stage;
  final bool isBoss;
  final BoardTheme? theme;
  final int knivesLeft;
  final int totalKnives;
  final bool isLastKnife;
  final double nearMissFlashTimer;
  final double crashFlashTimer;
  final GoldenRingData? goldenRing;
  final List<FloatingTextData> floatingTexts;
  final double animTime;
  final bool knifeReady;
  final double boardCenterY;
  final double knifeSpawnY;

  const HudData({
    required this.score,
    required this.apples,
    required this.stage,
    required this.isBoss,
    required this.theme,
    required this.knivesLeft,
    required this.totalKnives,
    required this.isLastKnife,
    required this.nearMissFlashTimer,
    this.crashFlashTimer = 0,
    required this.goldenRing,
    required this.floatingTexts,
    this.animTime = 0,
    this.knifeReady = false,
    this.boardCenterY = 0,
    this.knifeSpawnY = 0,
  });
}

class FloatingTextData {
  final String text;
  final double x;
  double y;
  double life;
  final double maxLife;
  final Color color;
  final double size;
  FloatingTextData(this.text, this.x, this.y,
      {this.color = const Color(0xFFf39c12), this.size = 26, double lifetime = 0.8})
      : life = lifetime,
        maxLife = lifetime;
}

class GoldenRingData {
  final double x;
  final double y;
  final double radius;
  final double life;
  const GoldenRingData(this.x, this.y, this.radius, this.life);
}

/// Wraps a golden ring's mutable state — lives in KnifeHitGame, rendered via HudOverlay.
class GoldenRing {
  double x;
  double y;
  double radius;
  double life;
  GoldenRing(this.x, this.y) : radius = 10, life = 0.45;

  GoldenRingData get data => GoldenRingData(x, y, radius, life);
}

/// Shared geometry for the single-line top HUD bar and pause tap target.
class HudBarLayout {
  HudBarLayout._();

  static const barTop = 44.0;
  static const barHeight = 48.0;
  static const barMarginH = 12.0;
  static const barRadius = 20.0;
  static const pauseRadius = 16.0;

  static double get barCenterY => barTop + barHeight / 2;

  static double pauseCenterX(double screenW) =>
      screenW - barMarginH - pauseRadius - 8;

  static Rect pauseHitRect(double screenW) {
    final cx = pauseCenterX(screenW);
    final cy = barCenterY;
    return Rect.fromCircle(center: Offset(cx, cy), radius: pauseRadius + 4);
  }
}

/// Stateless canvas renderer — call [render] once per frame with fresh [HudData].
class HudOverlay {
  final TextPainter _floatingTextPainter = TextPainter(textDirection: TextDirection.ltr);
  final TextPainter _scoreTextPainter = TextPainter(textDirection: TextDirection.ltr);
  final TextPainter _applesTextPainter = TextPainter(textDirection: TextDirection.ltr);
  final TextPainter _centerTextPainter = TextPainter(textDirection: TextDirection.ltr);
  final Map<String, Picture> _knifeIconCache = {};
  Picture? _cachedBarChrome;
  double? _cachedBarChromeWidth;
  Picture? _cachedKnifeQueue;
  int? _queueKnivesLeft;
  int? _queueTotalKnives;
  bool? _queueIsBoss;
  double? _queueScreenHeight;
  Picture? _cachedHudCenter;
  int? _centerStage;
  bool? _centerIsBoss;
  double? _centerWidth;
  int? _cachedScore;
  int? _cachedApples;
  Color? _cachedAppleAccent;
  Picture? _cachedFruitBadge;
  Picture? _cachedPauseNormal;
  Picture? _cachedPauseBoss;

  /// Clears per-run HUD caches when restarting without a new game instance.
  void resetForNewRun() {
    _cachedScore = null;
    _cachedApples = null;
    _cachedAppleAccent = null;
    _queueKnivesLeft = null;
    _queueTotalKnives = null;
    _centerStage = null;
    _centerIsBoss = null;
    _centerWidth = null;
  }

  void dispose() {
    _cachedBackground?.dispose();
    _cachedBackground = null;
    _cachedBarChrome?.dispose();
    _cachedBarChrome = null;
    _cachedKnifeQueue?.dispose();
    _cachedKnifeQueue = null;
    _cachedHudCenter?.dispose();
    _cachedHudCenter = null;
    _cachedFruitBadge?.dispose();
    _cachedFruitBadge = null;
    _cachedPauseNormal?.dispose();
    _cachedPauseNormal = null;
    _cachedPauseBoss?.dispose();
    _cachedPauseBoss = null;
    for (final picture in _knifeIconCache.values) {
      picture.dispose();
    }
    _knifeIconCache.clear();
  }

  /// Renders background, effects, floating texts, and the full HUD.
  void render(Canvas canvas, Size screenSize, HudData d) {
    _renderBackground(canvas, screenSize, d.isLastKnife, isBoss: d.isBoss);
    _renderEffects(canvas, screenSize, d);
    _renderFloatingTexts(canvas, d.floatingTexts);
    _renderHUD(canvas, screenSize, d);
  }

  // ── Background ─────────────────────────────────────────────────────────────

  // The background (12 striped gradients + vignettes) depends only on screen
  // size, yet was rebuilding ~14 GPU shaders on every single frame — the biggest
  // single contributor to in-game lag. Record it into a Picture once per size and
  // replay it. (isBoss/isLastKnife don't change the background, so they're not
  // part of the cache key.)
  Picture? _cachedBackground;
  Size? _cachedBgSize;

  void _renderBackground(Canvas canvas, Size s, bool isLastKnife, {bool isBoss = false}) {
    if (_cachedBackground != null && _cachedBgSize == s) {
      canvas.drawPicture(_cachedBackground!);
      return;
    }
    _cachedBackground?.dispose();
    final recorder = PictureRecorder();
    final canvasRec = Canvas(recorder);
    _drawBackground(canvasRec, s, isBoss: isBoss);
    _cachedBackground = recorder.endRecording();
    _cachedBgSize = s;
    canvas.drawPicture(_cachedBackground!);
  }

  void _drawBackground(Canvas canvas, Size s, {bool isBoss = false}) {
    final bgRect = Rect.fromLTWH(0, 0, s.width, s.height);
    if (isBoss) {
      // Boss stages share the same dark red striped base background.
      canvas.drawRect(bgRect, Paint()..color = const Color(0xFF1C0709));

      const stripeCount = 12;
      final stripeW = s.width / stripeCount;
      for (int i = 0; i < stripeCount; i++) {
        final stripeRect = Rect.fromLTWH(i * stripeW, 0, stripeW, s.height);
        canvas.drawRect(
          stripeRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.18),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.18),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(stripeRect),
        );
      }

      canvas.drawRect(
        bgRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
            stops: const [0.0, 0.35],
          ).createShader(bgRect),
      );

      canvas.drawRect(
        bgRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
            stops: const [0.0, 0.28],
          ).createShader(bgRect),
      );
    } else {
      // Match the app's shared dark red striped background style.
      canvas.drawRect(bgRect, Paint()..color = const Color(0xFF1C0709));

      const stripeCount = 12;
      final stripeW = s.width / stripeCount;
      for (int i = 0; i < stripeCount; i++) {
        final stripeRect = Rect.fromLTWH(i * stripeW, 0, stripeW, s.height);
        canvas.drawRect(
          stripeRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.18),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.18),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(stripeRect),
        );
      }

      // Top vignette
      canvas.drawRect(
        bgRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
            stops: const [0.0, 0.35],
          ).createShader(bgRect),
      );

      // Bottom vignette
      canvas.drawRect(
        bgRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
            stops: const [0.0, 0.28],
          ).createShader(bgRect),
      );
    }

    canvas.drawLine(
      Offset(s.width / 2, s.height * 0.38 + GameConstants.boardRadius),
      Offset(s.width / 2, s.height * 0.82 - 35),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 1,
    );
  }

  // ── Effects (near-miss flash, golden ring) ─────────────────────────────────

  void _renderEffects(Canvas canvas, Size s, HudData d) {
    if (d.crashFlashTimer > 0) {
      final t = (d.crashFlashTimer / 0.6).clamp(0.0, 1.0);
      final alpha = t * 0.45;
      final center = Offset(
        s.width / 2,
        d.boardCenterY > 0 ? d.boardCenterY : s.height * 0.38,
      );
      canvas.drawCircle(
        center,
        GameConstants.boardRadius + 12,
        Paint()..color = const Color(0xFFFFD700).withValues(alpha: alpha * 0.35),
      );
    } else if (d.nearMissFlashTimer > 0) {
      final alpha = (d.nearMissFlashTimer / 0.25).clamp(0.0, 1.0) * 0.22;
      canvas.drawCircle(
        Offset(s.width / 2, d.boardCenterY > 0 ? d.boardCenterY : s.height * 0.38),
        GameConstants.boardRadius + 24,
        Paint()..color = const Color(0xFFFFAA00).withValues(alpha: alpha),
      );
    }
    if (d.goldenRing != null) {
      final ring = d.goldenRing!;
      final alpha = (ring.life / 0.45).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(ring.x, ring.y),
        ring.radius,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: alpha * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }
  }

  // ── Floating texts ─────────────────────────────────────────────────────────

  void _renderFloatingTexts(Canvas canvas, List<FloatingTextData> texts) {
    for (final t in texts) {
      final alpha = (t.life / t.maxLife).clamp(0.0, 1.0);
      _floatingTextPainter.text = TextSpan(
        text: t.text,
        style: TextStyle(
          color: t.color.withValues(alpha: alpha),
          fontSize: t.size,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: alpha * 0.7),
              blurRadius: 6,
              offset: const Offset(1, 2),
            ),
          ],
        ),
      );
      _floatingTextPainter.layout();
      _floatingTextPainter.paint(
        canvas,
        Offset(t.x - _floatingTextPainter.width / 2, t.y),
      );
    }
  }

  // ── HUD ────────────────────────────────────────────────────────────────────

  void _renderHUD(Canvas canvas, Size s, HudData d) {
    _drawHudBar(canvas, s, d);
    _drawKnifeQueue(canvas, s, d);
  }

  void _drawKnifeQueue(Canvas canvas, Size s, HudData d) {
    const kw = 12.0, kh = 28.0, kSpacing = 4.0;
    const knifeAngle = -0.785;
    final displayTotal = d.totalKnives.clamp(0, 12);
    final usedCount = displayTotal - d.knivesLeft.clamp(0, displayTotal);

    final needsRebuild = _cachedKnifeQueue == null ||
        _queueKnivesLeft != d.knivesLeft ||
        _queueTotalKnives != displayTotal ||
        _queueIsBoss != d.isBoss ||
        _queueScreenHeight != s.height;

    if (needsRebuild) {
      _cachedKnifeQueue?.dispose();
      final totalListH = displayTotal * kh + (displayTotal - 1) * kSpacing;
      final qY = s.height - totalListH - 32;
      final recorder = PictureRecorder();
      final queueCanvas = Canvas(recorder);
      for (int i = 0; i < displayTotal; i++) {
        final kx = 36.0;
        final ky = qY + i * (kh + kSpacing);
        queueCanvas.save();
        queueCanvas.translate(kx, ky);
        queueCanvas.rotate(knifeAngle);
        _drawQueueKnife(
          queueCanvas,
          Offset.zero,
          kw,
          kh,
          isBoss: d.isBoss,
          used: i < usedCount,
          theme: d.theme,
        );
        queueCanvas.restore();
      }
      _cachedKnifeQueue = recorder.endRecording();
      _queueKnivesLeft = d.knivesLeft;
      _queueTotalKnives = displayTotal;
      _queueIsBoss = d.isBoss;
      _queueScreenHeight = s.height;
    }

    if (_cachedKnifeQueue != null) {
      canvas.drawPicture(_cachedKnifeQueue!);
    }
  }

  void _ensureBarChrome(double screenWidth) {
    if (_cachedBarChrome != null && _cachedBarChromeWidth == screenWidth) {
      return;
    }
    _cachedBarChrome?.dispose();
    final barLeft = HudBarLayout.barMarginH;
    final barW = screenWidth - HudBarLayout.barMarginH * 2;
    final barTop = HudBarLayout.barTop;
    final barH = HudBarLayout.barHeight;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barLeft, barTop, barW, barH),
      const Radius.circular(HudBarLayout.barRadius),
    );
    final recorder = PictureRecorder();
    final chromeCanvas = Canvas(recorder);
    chromeCanvas.drawRRect(
      barRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF22161A).withValues(alpha: 0.92),
            const Color(0xFF120A0E).withValues(alpha: 0.95),
          ],
        ).createShader(barRect.outerRect),
    );
    chromeCanvas.drawRRect(
      barRect,
      Paint()
        ..color = const Color(0xFFFF5A2E).withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    _cachedBarChrome = recorder.endRecording();
    _cachedBarChromeWidth = screenWidth;
  }

  void _drawHudBar(Canvas canvas, Size s, HudData d) {
    final barLeft = HudBarLayout.barMarginH;
    _ensureBarChrome(s.width);
    canvas.drawPicture(_cachedBarChrome!);

    final cy = HudBarLayout.barCenterY;
    final accent = d.isBoss ? const Color(0xFFFFD54F) : const Color(0xFFFF7A1A);

    // ── Left: score ──
    if (_cachedScore != d.score) {
      _cachedScore = d.score;
      _scoreTextPainter.text = TextSpan(
        text: '${d.score}',
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: -0.5,
        ),
      );
      _scoreTextPainter.layout();
    }
    _scoreTextPainter.paint(canvas, Offset(barLeft + 16, cy - _scoreTextPainter.height / 2));

    // ── Right: pause ──
    final pauseCx = HudBarLayout.pauseCenterX(s.width);
    _drawPauseButton(canvas, Offset(pauseCx, cy), d.isBoss);

    // ── Right: fruit count ──
    if (_cachedApples != d.apples || _cachedAppleAccent != accent) {
      _cachedApples = d.apples;
      _cachedAppleAccent = accent;
      _applesTextPainter.text = TextSpan(
        text: '${d.apples}',
        style: TextStyle(
          color: accent,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      );
      _applesTextPainter.layout();
    }
    const fruitR = 9.0;
    final fruitBlockW = fruitR * 2 + 6 + _applesTextPainter.width;
    final fruitLeft = pauseCx - HudBarLayout.pauseRadius - 14 - fruitBlockW;
    _ensureFruitBadge();
    canvas.save();
    canvas.translate(fruitLeft, cy - fruitR);
    canvas.drawPicture(_cachedFruitBadge!);
    canvas.restore();
    _applesTextPainter.paint(
      canvas,
      Offset(fruitLeft + fruitR * 2 + 6, cy - _applesTextPainter.height / 2),
    );

    // ── Center: stage chip + segment bar + rush knife ──
    final centerLeft = barLeft + 72;
    final centerRight = fruitLeft - 12;
    final centerW = centerRight - centerLeft;
    if (centerW > 80) {
      _drawHudCenter(canvas, d, cy, centerLeft, centerW, accent);
    }
  }

  void _drawHudCenter(
    Canvas canvas,
    HudData d,
    double cy,
    double startX,
    double maxW,
    Color accent,
  ) {
    final needsRebuild = _cachedHudCenter == null ||
        _centerStage != d.stage ||
        _centerIsBoss != d.isBoss ||
        _centerWidth != maxW;

    if (needsRebuild) {
      _cachedHudCenter?.dispose();
      final stageLabel = d.isBoss ? 'BONUS' : 'STAGE ${d.stage}';

      const chipPadH = 10.0;
      const chipH = 22.0;
      const segW = 16.0;
      const segH = 5.0;
      const segGap = 4.0;
      const knifeW = 9.0;
      const knifeH = 20.0;
      const bossEvery = 5;
      const cycleSegs = bossEvery - 1;
      final completedInCycle = d.isBoss ? cycleSegs : (d.stage % bossEvery) - 1;

      _centerTextPainter.text = TextSpan(
        text: stageLabel,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          height: 1,
        ),
      );
      _centerTextPainter.layout();

      final chipW = _centerTextPainter.width + chipPadH * 2;
      final progressW = cycleSegs * segW + (cycleSegs - 1) * segGap;
      final totalW = chipW + 10 + progressW + 8 + knifeW;
      var x = startX + (maxW - totalW) / 2;

      final recorder = PictureRecorder();
      final centerCanvas = Canvas(recorder);
      final chipRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + chipW / 2, cy), width: chipW, height: chipH),
        const Radius.circular(11),
      );
      centerCanvas.drawRRect(chipRect, Paint()..color = accent.withValues(alpha: 0.14));
      centerCanvas.drawRRect(
        chipRect,
        Paint()
          ..color = accent.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      _centerTextPainter.paint(
        centerCanvas,
        Offset(x + chipPadH, cy - _centerTextPainter.height / 2),
      );
      x += chipW + 10;

      for (int i = 0; i < cycleSegs; i++) {
        final filled = i < completedInCycle || d.isBoss;
        final segRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + segW / 2, cy),
            width: segW,
            height: segH,
          ),
          const Radius.circular(2.5),
        );
        centerCanvas.drawRRect(
          segRect,
          Paint()
            ..color = filled
                ? accent
                : Colors.white.withValues(alpha: 0.12),
        );
        x += segW + segGap;
      }

      x += 8;
      _drawHudKnifeIcon(
        centerCanvas,
        Offset(x + knifeW / 2, cy),
        knifeW,
        knifeH,
        isBoss: d.isBoss,
        theme: d.theme,
      );

      _cachedHudCenter = recorder.endRecording();
      _centerStage = d.stage;
      _centerIsBoss = d.isBoss;
      _centerWidth = maxW;
    }

    if (_cachedHudCenter != null) {
      canvas.drawPicture(_cachedHudCenter!);
    }
  }

  void _ensureFruitBadge() {
    if (_cachedFruitBadge != null) return;
    const fruitR = 9.0;
    final recorder = PictureRecorder();
    CollectibleRenderer.drawTallyBadge(
      Canvas(recorder),
      const Offset(fruitR, fruitR),
      fruitR,
    );
    _cachedFruitBadge = recorder.endRecording();
  }

  void _ensurePauseButton(bool isBoss) {
    if (isBoss) {
      if (_cachedPauseBoss != null) return;
    } else {
      if (_cachedPauseNormal != null) return;
    }
    const r = HudBarLayout.pauseRadius;
    final accent = isBoss ? const Color(0xFFFFD54F) : const Color(0xFFFF7A1A);
    final recorder = PictureRecorder();
    final c = Canvas(recorder);
    final center = Offset(r, r);
    c.drawCircle(center, r, Paint()..color = accent.withValues(alpha: 0.12));
    c.drawCircle(
      center,
      r,
      Paint()
        ..color = accent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final barPaint = Paint()..color = accent;
    const barW = 3.0;
    const barH = 12.0;
    const gap = 3.5;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - gap - barW, center.dy - barH / 2, barW, barH),
        const Radius.circular(1.5),
      ),
      barPaint,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx + gap, center.dy - barH / 2, barW, barH),
        const Radius.circular(1.5),
      ),
      barPaint,
    );
    if (isBoss) {
      _cachedPauseBoss = recorder.endRecording();
    } else {
      _cachedPauseNormal = recorder.endRecording();
    }
  }

  void _drawPauseButton(Canvas canvas, Offset center, bool isBoss) {
    _ensurePauseButton(isBoss);
    const r = HudBarLayout.pauseRadius;
    canvas.save();
    canvas.translate(center.dx - r, center.dy - r);
    canvas.drawPicture(isBoss ? _cachedPauseBoss! : _cachedPauseNormal!);
    canvas.restore();
  }

  /// Single vertical Rush Spike — matches in-game knife art.
  void _drawHudKnifeIcon(
    Canvas canvas,
    Offset center,
    double w,
    double h, {
    required bool isBoss,
    BoardTheme? theme,
  }) {
    canvas.save();
    canvas.translate(center.dx - w / 2, center.dy - h / 2);
    if (theme != null && !isBoss) {
      final key = '${theme.id.name}_${w}x$h';
      final cached = _knifeIconCache.putIfAbsent(key, () {
        final recorder = PictureRecorder();
        KnifeRenderer.drawFlying(
          Canvas(recorder),
          Size(w, h),
          isBoss: false,
          theme: theme,
        );
        return recorder.endRecording();
      });
      canvas.drawPicture(cached);
    } else {
      KnifeRenderer.drawMini(
        canvas,
        Size(w, h),
        isBoss: isBoss,
      );
    }
    canvas.restore();
  }

  void _drawQueueKnife(Canvas canvas, Offset center, double w, double h,
      {bool isBoss = false, bool used = false, BoardTheme? theme}) {
    canvas.save();
    canvas.translate(center.dx - w / 2, center.dy - h / 2);
    KnifeRenderer.drawMini(
      canvas,
      Size(w, h),
      isBoss: isBoss,
      used: used,
    );
    canvas.restore();
  }
}
