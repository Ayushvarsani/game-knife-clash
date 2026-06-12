import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_modal_icons.dart';

/// Shared palette for pause / game-over overlays.
abstract final class GameModalColors {
  static const titleRed = Color(0xFFFF6255);
  static const scoreGold = Color(0xFFFCB231);
  static const accentOrange = Color(0xFFFF7A1A);
  static const accentRed = Color(0xFFFF5A2E);
  static const accentBlue = Color(0xFF3C9BE4);
  static const accentPurple = Color(0xFF9B59B6);
  static const panelFill = Color(0xFF1A1014);
  static const panelEdge = Color(0xFF2A1820);
}

/// Frosted backdrop over live gameplay.
class GameModalBackdrop extends StatelessWidget {
  final Widget child;
  final double blur;

  const GameModalBackdrop({
    super.key,
    required this.child,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.58),
              const Color(0xFF1C0709).withValues(alpha: 0.72),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Glass card used by pause and game-over modals.
class GameModalPanel extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color accentColor;

  const GameModalPanel({
    super.key,
    required this.child,
    this.maxWidth = 320,
    this.accentColor = GameModalColors.accentOrange,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    GameModalColors.panelFill.withValues(alpha: 0.97),
                    const Color(0xFF0E080A).withValues(alpha: 0.96),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact header row — icon + title + optional subtitle.
class GameModalHeader extends StatelessWidget {
  final GameModalIconKind icon;
  final Color color;
  final String title;
  final String? subtitle;

  const GameModalHeader({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Center(
            child: GameModalIcon(kind: icon, color: color, size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.rajdhani(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  height: 1.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.rajdhani(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class GameModalScoreBlock extends StatelessWidget {
  final int score;
  final String label;

  const GameModalScoreBlock({
    super.key,
    required this.score,
    this.label = 'SCORE',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.rajdhani(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$score',
            style: GoogleFonts.rajdhani(
              color: GameModalColors.scoreGold,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class GameScoreBadge extends StatelessWidget {
  final int highScore;

  const GameScoreBadge({super.key, required this.highScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: GameModalColors.scoreGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GameModalColors.scoreGold.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GameModalColors.scoreGold.withValues(alpha: 0.12),
            ),
            child: const Center(
              child: GameModalIcon(
                kind: GameModalIconKind.trophy,
                color: GameModalColors.scoreGold,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'BEST  $highScore',
            style: GoogleFonts.rajdhani(
              color: GameModalColors.scoreGold,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

enum GameModalButtonStyle { primary, secondary }

class GameModalButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final GameModalButtonStyle style;
  final GameModalIconKind? icon;
  final bool loading;

  const GameModalButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.style = GameModalButtonStyle.primary,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = style == GameModalButtonStyle.primary;

    return GameModalTappable(
      onTap: loading ? () {} : onTap,
      child: Container(
        width: double.infinity,
        height: isPrimary ? 48 : 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? color : color.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    GameModalIcon(
                      kind: icon!,
                      color: isPrimary ? Colors.white : color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.rajdhani(
                      color: isPrimary ? Colors.white : color,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class GameModalTappable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const GameModalTappable({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<GameModalTappable> createState() => _GameModalTappableState();
}

class _GameModalTappableState extends State<GameModalTappable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTap: () {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
