import 'package:flutter/material.dart';
import 'home_logo_footer.dart';
import 'knife_rush_logo.dart';

class HomeTitleBlock extends StatelessWidget {
  final int highScore;
  final Animation<double> glowAnim;

  const HomeTitleBlock({
    super.key,
    required this.highScore,
    required this.glowAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KnifeRushLogo(
          glowAnim: glowAnim,
          scale: KnifeRushLogoScale.home,
          highScore: highScore,
          showTagline: true,
        ),
        const HomeLogoFooter(),
      ],
    );
  }
}
