import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_modal.dart';

/// Shared neon palette for home / splash branding.
abstract final class KnifeRushBrandColors {
  static const ember = Color(0xFFFF8A3D);
  static const flare = Color(0xFFFF3B30);
  static const gold = Color(0xFFFFB63D);
  static const panel = Color(0xFF1A1014);
  static const edge = Color(0xFF3D2228);
}

abstract final class AppAssets {
  static const knifeRushLogo = 'assets/images/logo.png';
}

enum KnifeRushLogoScale { splash, home }

/// Official Knife Rush logo image (transparent) with optional tagline / best score.
class KnifeRushLogo extends StatelessWidget {
  final Animation<double>? glowAnim;
  final KnifeRushLogoScale scale;
  final int? highScore;
  final bool showTagline;

  const KnifeRushLogo({
    super.key,
    this.glowAnim,
    this.scale = KnifeRushLogoScale.home,
    this.highScore,
    this.showTagline = false,
  });

  double get _logoWidth => scale == KnifeRushLogoScale.splash ? 300 : 268;

  @override
  Widget build(BuildContext context) {
    Widget buildContent(double glow) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _logoWidth,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: _logoWidth * 0.12,
                  child: Container(
                    width: _logoWidth * 0.72,
                    height: _logoWidth * 0.72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: KnifeRushBrandColors.flare.withValues(
                            alpha: 0.18 + glow * 0.22,
                          ),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                Image.asset(
                  AppAssets.knifeRushLogo,
                  width: _logoWidth,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ],
            ),
          ),
          if (showTagline) ...[
            const SizedBox(height: 18),
            Text(
              'STICK  ·  SPIN  ·  SURVIVE',
              style: GoogleFonts.rajdhani(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
          ],
          if (highScore != null && highScore! > 0) ...[
            const SizedBox(height: 16),
            GameScoreBadge(highScore: highScore!),
          ],
        ],
      );
    }

    if (glowAnim == null) {
      return buildContent(0.75);
    }

    return AnimatedBuilder(
      animation: glowAnim!,
      builder: (_, _) => buildContent(0.55 + glowAnim!.value * 0.45),
    );
  }
}
