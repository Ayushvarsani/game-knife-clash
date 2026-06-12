import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_routes.dart';
import 'game_screen.dart';
import 'home_screen.dart';
import 'widgets/stripe_background.dart';

class StageCompleteScreen extends StatefulWidget {
  final int stage;
  final int score;
  final int highScore;
  final int nextStage;
  final String skinId;
  final int bestCombo;

  const StageCompleteScreen({
    super.key,
    required this.stage,
    required this.score,
    required this.highScore,
    required this.nextStage,
    this.skinId = 'default',
    this.bestCombo = 0,
  });

  @override
  State<StageCompleteScreen> createState() => _StageCompleteScreenState();
}

class _StageCompleteScreenState extends State<StageCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _scaleAnim;

  late AnimationController _starController;
  late Animation<double> _starAnim;

  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.elasticOut);
    _entryController.forward();

    // Star spin & scale
    _starController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _starAnim = CurvedAnimation(parent: _starController, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _starController.forward();
    });

    // Confetti
    _confettiController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _starController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBoss = widget.stage % 5 == 0;
    final totalStages = 20;
    final progress = (widget.nextStage - 1) / totalStages;

    return Scaffold(
      backgroundColor: const Color(0xFF1C0709),
      body: StripeBackground(child: Stack(
        children: [
          // Confetti layer
          AnimatedBuilder(
            animation: _confettiController,
            builder: (_, w) => CustomPaint(
              painter: _ConfettiPainter(_confettiController.value),
              size: MediaQuery.of(context).size,
            ),
          ),

          // Radial gold glow
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Boss badge
                    if (isBoss) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                              width: 1.5),
                        ),
                        child: Text(
                          'BOSS STAGE',
                          style: GoogleFonts.rajdhani(
                            color: const Color(0xFFFFD700),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Animated star
                    ScaleTransition(
                      scale: _starAnim,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFFFD700).withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFD700),
                          size: 72,
                          shadows: [
                            Shadow(
                                color: Color(0xFFFFD700),
                                blurRadius: 24),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'STAGE ${widget.stage}',
                      style: GoogleFonts.rajdhani(
                        color: const Color(0xFFFFD700),
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        shadows: const [
                          Shadow(color: Color(0xFFFFD700), blurRadius: 14),
                        ],
                      ),
                    ),
                    Text(
                      'COMPLETE!',
                      style: GoogleFonts.rajdhani(
                        color: const Color(0xFFFF7A1A),
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: const [
                          Shadow(color: Color(0xFFFF7A1A), blurRadius: 12),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Score card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white12, width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${widget.score}',
                            style: GoogleFonts.rajdhani(
                              color: const Color(0xFFf39c12),
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'SCORE',
                            style: GoogleFonts.rajdhani(
                              color: Colors.white38,
                              fontSize: 11,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events_rounded,
                                  color: Color(0xFFf39c12), size: 16),
                              const SizedBox(width: 5),
                              Text(
                                'Best: ${widget.highScore}',
                                style: GoogleFonts.rajdhani(
                                  color: const Color(0xFFf39c12),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          if (widget.bestCombo >= 3) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department,
                                    color: Color(0xFFFF8C00), size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  'Combo ×${widget.bestCombo}',
                                  style: GoogleFonts.rajdhani(
                                    color: const Color(0xFFFF8C00),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stage progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PROGRESS',
                              style: GoogleFonts.rajdhani(
                                color: Colors.white38,
                                fontSize: 10,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Stage ${widget.nextStage} / $totalStages',
                              style: GoogleFonts.rajdhani(
                                color: Colors.white38,
                                fontSize: 10,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF7A1A)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    _TappableButton(
                      onTap: () => Navigator.of(context).pushReplacement(
                        fadeSlideRoute(
                          page: GameScreen(
                            startStage: widget.nextStage,
                            startScore: widget.score,
                            skinId: widget.skinId,
                          ),
                        ),
                      ),
                      child: Container(
                        width: 220,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A3D), Color(0xFFE0461A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8A3D)
                                  .withValues(alpha: 0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'NEXT STAGE',
                              style: GoogleFonts.rajdhani(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _TappableButton(
                      onTap: () => Navigator.of(context).pushReplacement(
                        fadeSlideRoute(
                          page: HomeScreen(
                            stage: widget.nextStage,
                            score: widget.score,
                          ),
                        ),
                      ),
                      child: Container(
                        width: 220,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3498db),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3498db)
                                  .withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'HOME',
                            style: GoogleFonts.rajdhani(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}

// Simple confetti particle painter
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> _particles;

  _ConfettiPainter(this.progress)
      : _particles = List.generate(60, (i) => _Particle(i));

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = ((progress + p.offset) % 1.0);
      final opacity = (1.0 - t).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      final x = p.startX * size.width +
          math.sin(t * math.pi * 2 + p.phase) * 30;
      final y = t * size.height * 1.2 - size.height * 0.1;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.85)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * math.pi * 4 + p.phase);
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.5),
          paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  final double startX;
  final double offset;
  final double phase;
  final double size;
  final Color color;

  static const _colors = [
    Color(0xFFFFD700),
    Color(0xFF2ecc71),
    Color(0xFFf39c12),
    Color(0xFF3498db),
    Color(0xFFe74c3c),
    Color(0xFFFFFFFF),
  ];

  _Particle(int seed)
      : startX = (seed * 0.0167 + math.sin(seed * 1.618) * 0.3 + 0.5)
            .clamp(0.0, 1.0),
        offset = (seed % 10) / 10.0,
        phase = seed * 0.9,
        size = 6.0 + (seed % 5) * 2.0,
        color = _colors[seed % _colors.length];
}

class _TappableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TappableButton({required this.child, required this.onTap});

  @override
  State<_TappableButton> createState() => _TappableButtonState();
}

class _TappableButtonState extends State<_TappableButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: widget.child,
      ),
    );
  }
}
