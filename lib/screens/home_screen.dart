import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../ads/widgets/banner_ad_widget.dart';
import 'app_routes.dart';
import 'game_screen.dart';
import '../game/managers/progress_manager.dart';
import '../services/app_update_service.dart';
import 'widgets/home_animated_background.dart';
import 'widgets/home_title_block.dart';
import 'widgets/more_games_sheet.dart';
import 'widgets/settings_bottom_sheet.dart';
import 'widgets/stripe_background.dart';
import 'widgets/collectible_icon.dart';
import 'widgets/knife_rush_logo.dart';
import 'widgets/force_update_modal.dart';
import 'widgets/rush_play_button.dart';

class HomeScreen extends StatefulWidget {
  final int stage;
  final int score;

  const HomeScreen({super.key, this.stage = 1, this.score = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  int _highScore = 0;
  int _lifetimeApples = 0;

  final ProgressManager _progress = ProgressManager();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);

    _loadData();
    _checkForAppUpdate();
  }

  Future<void> _checkForAppUpdate() async {
    final status = await AppUpdateService.checkForUpdate();
    if (!mounted || !status.needsUpdate) return;

    await ForceUpdateModal.show(context);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    await _progress.load();
    if (!mounted) return;
    setState(() {
      _highScore = prefs.getInt('high_score') ?? 0;
      _lifetimeApples = _progress.lifetimeApples;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _startGame() {
    Navigator.of(context).pushReplacement(
      fadeSlideRoute(page: const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StripeBackground(
              child: Stack(
                children: [
                  const Positioned.fill(child: HomeAnimatedBackground()),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                      child: Column(
                        children: [
                          _TopBar(
                            apples: _lifetimeApples,
                            onMoreGames: () => MoreGamesSheet.show(context),
                            onSettings: () => SettingsBottomSheet.show(context),
                          ),
                          const Spacer(flex: 2),
                          HomeTitleBlock(
                            highScore: _highScore,
                            glowAnim: _glowAnim,
                          ),
                          const Spacer(flex: 2),
                          ScaleTransition(
                            scale: _pulseAnim,
                            child: RushPlayButton(onTap: _startGame),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // const BannerAdWidget(),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int apples;
  final VoidCallback onMoreGames;
  final VoidCallback onSettings;

  const _TopBar({
    required this.apples,
    required this.onMoreGames,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _IconButton(
              icon: Icons.settings_rounded,
              onTap: onSettings,
            ),
            const SizedBox(width: 10),
            _IconButton(
              icon: Icons.apps_rounded,
              onTap: onMoreGames,
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: KnifeRushBrandColors.panel.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: KnifeRushBrandColors.gold.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$apples',
                style: GoogleFonts.rajdhani(
                  color: KnifeRushBrandColors.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const CollectibleIcon(size: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _pressed = false;

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
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: KnifeRushBrandColors.panel.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: KnifeRushBrandColors.edge.withValues(alpha: 0.9),
            ),
          ),
          child: Icon(
            widget.icon,
            color: Colors.white.withValues(alpha: 0.72),
            size: 22,
          ),
        ),
      ),
    );
  }
}

