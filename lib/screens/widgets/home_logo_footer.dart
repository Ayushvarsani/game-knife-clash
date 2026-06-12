import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'knife_rush_logo.dart';

/// Decorative hints and divider shown below the home logo.
class HomeLogoFooter extends StatelessWidget {
  const HomeLogoFooter({super.key});

  static const _hints = [
    _Hint(Icons.touch_app_rounded, 'TAP'),
    _Hint(Icons.rotate_right_rounded, 'SPIN'),
    _Hint(Icons.shield_rounded, 'SURVIVE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _emberLine(width: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'HOW TO PLAY',
                style: GoogleFonts.rajdhani(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.2,
                ),
              ),
            ),
            _emberLine(width: 48),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _hints.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              _HintChip(hint: _hints[i]),
            ],
          ],
        ),
      ],
    );
  }

  Widget _emberLine({required double width}) {
    return Container(
      width: width,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            KnifeRushBrandColors.ember.withValues(alpha: 0.55),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _Hint {
  final IconData icon;
  final String label;

  const _Hint(this.icon, this.label);
}

class _HintChip extends StatelessWidget {
  final _Hint hint;

  const _HintChip({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KnifeRushBrandColors.panel.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KnifeRushBrandColors.edge.withValues(alpha: 0.85),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hint.icon,
            size: 15,
            color: KnifeRushBrandColors.ember.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Text(
            hint.label,
            style: GoogleFonts.rajdhani(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
