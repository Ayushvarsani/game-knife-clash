import 'package:flutter/material.dart';

import 'game_modal.dart';
import 'knife_rush_logo.dart';

class SplashProgressBar extends StatelessWidget {
  final double progress;

  const SplashProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.08)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            KnifeRushBrandColors.ember,
                            GameModalColors.accentRed,
                            KnifeRushBrandColors.gold,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GameModalColors.accentOrange.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'LOADING  $pct%',
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              color: Color(0x99FFB63D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
