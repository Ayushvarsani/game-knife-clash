import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_modal.dart';
import 'game_modal_icons.dart';

/// Chamfered neon CTA — matches reactor / modal theme.
class RushPlayButton extends StatefulWidget {
  final VoidCallback onTap;
  final double width;

  const RushPlayButton({
    super.key,
    required this.onTap,
    this.width = 280,
  });

  @override
  State<RushPlayButton> createState() => _RushPlayButtonState();
}

class _RushPlayButtonState extends State<RushPlayButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _sheenController;
  late Animation<double> _sheenAnim;

  @override
  void initState() {
    super.initState();
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _sheenAnim = CurvedAnimation(parent: _sheenController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _sheenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTap: () {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _sheenAnim,
          builder: (_, _) {
            final pulse = 0.12 + _sheenAnim.value * 0.1;
            final pressedDim = _pressed ? 0.72 : 1.0;
            return SizedBox(
              width: widget.width,
              height: 76,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Ground shadow — depth anchor
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: -6,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55 * pressedDim),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Subtle warm rim glow
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: GameModalColors.accentOrange.withValues(
                              alpha: pulse * pressedDim,
                            ),
                            blurRadius: 12,
                            spreadRadius: -4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                      painter: _PlayButtonFramePainter(
                        sheen: _sheenAnim.value,
                        pressed: _pressed,
                      ),
                      child: SizedBox(
                        width: widget.width,
                        height: 76,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: GameModalColors.accentOrange.withValues(
                                        alpha: 0.18 * pulse,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: -3,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        GameModalColors.accentOrange.withValues(alpha: 0.32),
                                        GameModalColors.accentOrange.withValues(alpha: 0.14),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: GameModalColors.accentOrange.withValues(alpha: 0.62),
                                    ),
                                  ),
                                  child: const Center(
                                    child: GameModalIcon(
                                      kind: GameModalIconKind.play,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'PLAY',
                                style: GoogleFonts.rajdhani(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                  height: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: GameModalColors.accentOrange.withValues(
                                        alpha: 0.22 * pulse,
                                      ),
                                      blurRadius: 8,
                                    ),
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlayButtonFramePainter extends CustomPainter {
  final double sheen;
  final bool pressed;

  _PlayButtonFramePainter({required this.sheen, required this.pressed});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    canvas.drawRRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A1820),
            Color(0xFF120A0E),
            Color(0xFF1A1014),
          ],
        ).createShader(rect),
    );

    // Inner vignette for depth
    canvas.drawRRect(
      r.deflate(1),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 1.1,
          colors: [
            Colors.white.withValues(alpha: pressed ? 0.04 : 0.07),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Animated sheen sweep
    canvas.drawRRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-1 + sheen * 2, -1),
          end: Alignment(sheen * 2, 1),
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.09),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );

    // Top edge highlight
    final topHighlight = RRect.fromRectAndCorners(
      Rect.fromLTWH(6, 1, size.width - 12, size.height * 0.42),
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
    );
    canvas.drawRRect(
      topHighlight,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );

    // Gradient border
    canvas.drawRRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameModalColors.accentOrange,
            GameModalColors.accentRed,
            Color(0xFF8A2018),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Left accent bar with glow
    final accentRect = Rect.fromLTWH(0, 0, 5, size.height);
    canvas.drawRect(
      accentRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFB04A),
            GameModalColors.accentOrange,
            GameModalColors.accentRed,
          ],
        ).createShader(accentRect),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 6, size.height),
      Paint()
        ..color = GameModalColors.accentOrange.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant _PlayButtonFramePainter old) =>
      old.sheen != sheen || old.pressed != pressed;
}
