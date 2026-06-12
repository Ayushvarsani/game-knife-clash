import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'app_routes.dart';
import 'widgets/knife_rush_logo.dart';
import 'widgets/splash_progress_bar.dart';
import 'widgets/stripe_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryAnim;
  late AnimationController _progressController;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  static const _splashDuration = Duration(milliseconds: 2800);

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entryAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );
    _entryController.forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);

    _progressController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          fadeSlideRoute(page: const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C0709),
      body: StripeBackground(
        child: Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, __) => Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFFF3B30).withValues(alpha: 0.08 + _glowAnim.value * 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _entryAnim,
                    child: ScaleTransition(
                      scale: _entryAnim,
                      child: KnifeRushLogo(
                        glowAnim: _glowAnim,
                        scale: KnifeRushLogoScale.splash,
                        showTagline: true,
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (_, __) => SplashProgressBar(
                      progress: _progressController.value,
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

