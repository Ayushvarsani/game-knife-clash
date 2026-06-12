import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import '../ads/services/rewarded_ad_service.dart';
// import '../ads/widgets/keep_playing_button.dart';
import '../data/mocks/milestones.dart';
import 'widgets/game_modal.dart';
import 'widgets/game_modal_icons.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  final int highScore;
  final bool isNewHighScore;
  final List<Milestone> newMilestones;
  final void Function(BuildContext context) onRetry;
  final void Function(BuildContext context) onHome;
  final void Function(BuildContext context)? onKeepPlaying;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.highScore,
    required this.onRetry,
    required this.onHome,
    this.onKeepPlaying,
    this.isNewHighScore = false,
    this.newMilestones = const [],
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _scaleAnim;
  late AnimationController _flashController;
  late Animation<double> _flashAnim;
  late AnimationController _counterController;
  late Animation<int> _counterAnim;

  @override
  void initState() {
    super.initState();
    // RewardedAdService.instance.preload();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scaleAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _flashAnim = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );

    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _counterAnim = IntTween(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _counterController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _counterController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _flashController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GameModalBackdrop(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: GameModalPanel(
                maxWidth: 300,
                accentColor: GameModalColors.titleRed,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const GameModalHeader(
                      icon: GameModalIconKind.gameOver,
                      color: GameModalColors.titleRed,
                      title: 'GAME OVER',
                      subtitle: 'Better luck on the next throw',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _counterAnim,
                      builder: (context, child) => GameModalScoreBlock(
                        score: _counterAnim.value,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(child: GameScoreBadge(highScore: widget.highScore)),
                    if (widget.isNewHighScore) ...[
                      const SizedBox(height: 12),
                      FadeTransition(
                        opacity: _flashAnim,
                        child: Text(
                          'NEW HIGH SCORE!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.rajdhani(
                            color: const Color(0xFFFFD700),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Keep Playing (rewarded ad) — disabled while ads are commented out.
                    // if (widget.onKeepPlaying != null) ...[
                    //   KeepPlayingButton(
                    //     onRewarded: () => widget.onKeepPlaying!(context),
                    //   ),
                    //   const SizedBox(height: 10),
                    // ],
                    GameModalButton(
                      label: 'RETRY',
                      color: GameModalColors.accentRed,
                      icon: GameModalIconKind.restart,
                      onTap: () => widget.onRetry(context),
                    ),
                    const SizedBox(height: 10),
                    GameModalButton(
                      label: 'HOME',
                      color: GameModalColors.accentBlue,
                      icon: GameModalIconKind.home,
                      style: GameModalButtonStyle.secondary,
                      onTap: () => widget.onHome(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
