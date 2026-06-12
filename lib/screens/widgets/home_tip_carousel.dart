import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _tips = [
  ('PERFECT THROWS', 'Land dead-center for bonus rings'),
  ('COLLECT APPLES', 'Hit red apples on the reactor for bonus points'),
  ('BONUS STAGES', 'Every 5th stage is a gold reactor rush'),
  ('COMBO STREAK', 'Chain sticks without missing to multiply score'),
];

class HomeTipCarousel extends StatefulWidget {
  const HomeTipCarousel({super.key});

  @override
  State<HomeTipCarousel> createState() => _HomeTipCarouselState();
}

class _HomeTipCarouselState extends State<HomeTipCarousel> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      setState(() => _index = (_index + 1) % _tips.length);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_index];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_index),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(
              tip.$1,
              style: GoogleFonts.rajdhani(
                color: const Color(0xFFFF7A1A),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tip.$2,
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
