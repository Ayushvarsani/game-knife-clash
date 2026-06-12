import 'package:flame/game.dart';
import 'package:flutter/material.dart';
// import '../ads/widgets/banner_ad_widget.dart';
import '../game/knife_hit_game.dart';
import '../game/utils/constants.dart';
import '../game/utils/game_session_cleanup.dart';
import '../data/mocks/milestones.dart';
import 'app_routes.dart';
import 'game_over_screen.dart';
import 'home_screen.dart';
import 'widgets/game_modal.dart';
import 'widgets/game_modal_icons.dart';

class GameScreen extends StatefulWidget {
  final int startStage;
  final int startScore;
  final String skinId;
  final bool isDailyChallenge;
  final String? dailyDateKey;

  const GameScreen({
    super.key,
    this.startStage = 1,
    this.startScore = 0,
    this.skinId = 'default',
    this.isDailyChallenge = false,
    this.dailyDateKey,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver {
  KnifeHitGame? _game;
  bool _paused = false;
  bool _gameReady = false;

  // Game-over overlay state. Shown on top of the live game (instead of a pushed
  // screen) so "Keep Playing" can revive the same game instance in place.
  bool _gameOver = false;
  int _gameOverScore = 0;
  int _gameOverHighScore = 0;
  bool _gameOverIsNewHighScore = false;
  List<Milestone> _gameOverMilestones = const [];
  bool _autoPausedByApp = false;
  final Key _gameWidgetKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDifficultyAndInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game?.pauseEngine();
    GameSessionCleanup.afterSession();
    super.dispose();
  }

  // App switch / screen off: stop the engine immediately and show the pause
  // modal when the player comes back. setState must run here directly because
  // callbacks fired while backgrounded may not rebuild the overlay.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final game = _game;
    if (game == null) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        game.pauseEngine();
        if (_gameOver) return;
        _autoPausedByApp = true;
        game.pauseGame();
        if (mounted) setState(() => _paused = true);
      case AppLifecycleState.resumed:
        if (_gameOver) return;
        if (_autoPausedByApp || game.isEnginePaused) {
          game.pauseGame();
          if (mounted) setState(() => _paused = true);
        }
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _loadDifficultyAndInit() async {
    if (!mounted) return;
    setState(() {
      _game = KnifeHitGame(
        startStage: widget.startStage,
        startScore: widget.startScore,
        skinId: widget.skinId,
        onGameOver: _handleGameOver,
        onPause: _handlePause,
      );
      _gameReady = true;
    });
  }

  void _handlePause() {
    if (!mounted) return;
    setState(() => _paused = true);
  }

  void _handleResume() {
    _autoPausedByApp = false;
    setState(() => _paused = false);
    _game!.resumeGame();
  }

  void _handleRestart() {
    _autoPausedByApp = false;
    setState(() => _paused = false);
    _game!.restartRun();
    _game!.resumeEngine();
  }

  void _handleHome() {
    _autoPausedByApp = false;
    _leaveSession(nextPage: const HomeScreen());
  }

  void _handleGameOver() {
    if (!mounted) return;
    final game = _game!;
    final score = game.scoreManager.score;
    final milestones = List<Milestone>.from(
        game.pendingMilestoneToasts.whereType<Milestone>());
    game.milestoneManager.clearToasts();

    if (widget.isDailyChallenge && widget.dailyDateKey != null) {
      game.progressManager.saveDailyScore(widget.dailyDateKey!, score);
    }

    // Show the game-over UI as an overlay on the still-alive game so the
    // rewarded-ad "Keep Playing" can revive this exact instance in place.
    game.pauseEngine();
    setState(() {
      _gameOver = true;
      _paused = false;
      _autoPausedByApp = false;
      _gameOverScore = score;
      _gameOverHighScore = game.scoreManager.highScore;
      _gameOverIsNewHighScore = game.gameOverIsNewHighScore;
      _gameOverMilestones = milestones;
    });
  }

  // Keep Playing (rewarded ad) — disabled while ads are commented out.
  // void _handleKeepPlaying() {
  //   if (!mounted) return;
  //   setState(() => _gameOver = false);
  //   _game!.reviveFromAd();
  //   _game!.resumeEngine();
  // }

  Future<void> _leaveSession({required Widget nextPage}) async {
    _game?.pauseEngine();
    // Cleanup runs in KnifeHitGame.onRemove / GameScreen.dispose — not here,
    // while the old game may still be mounted and holding texture references.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeSlideRoute(page: nextPage));
  }

  void _handleGameOverRetry() {
    // Reuse the same Flame instance — avoids stacking GPU surfaces/textures
    // that caused run 2/3 to lag and run 4 to hang on stage 1.
    setState(() {
      _gameOver = false;
      _paused = false;
      _autoPausedByApp = false;
    });
    _game!.restartRun();
    _game!.resumeEngine();
  }

  void _handleGameOverHome() {
    _leaveSession(nextPage: const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameReady || _game == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1C0709),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFFf39c12))),
      );
    }
    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    RepaintBoundary(
                      child: GameWidget(
                        key: _gameWidgetKey,
                        game: _game!,
                        backgroundBuilder: (context) => Container(
                          color: GameConstants.backgroundColor,
                        ),
                      ),
                    ),
                    // Milestone toasts disabled
                    // if (_pendingMilestones.isNotEmpty)
                    //   MilestoneToastQueue(milestones: _pendingMilestones),
                    if (_paused)
                      _PauseMenuOverlay(
                        onResume: _handleResume,
                        onRestart: _handleRestart,
                        onHome: _handleHome,
                      ),
                  ],
                ),
              ),
              // const BannerAdWidget(),
            ],
          ),
          // Game-over overlay sits above everything, including the banner, and
          // keeps the live game mounted underneath so reviveFromAd() can resume.
          if (_gameOver)
            Positioned.fill(
              child: GameOverScreen(
                score: _gameOverScore,
                highScore: _gameOverHighScore,
                isNewHighScore: _gameOverIsNewHighScore,
                newMilestones: _gameOverMilestones,
                // onKeepPlaying: (_) => _handleKeepPlaying(),
                onRetry: (_) => _handleGameOverRetry(),
                onHome: (_) => _handleGameOverHome(),
              ),
            ),
        ],
      ),
    );
  }
}

class _PauseMenuOverlay extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const _PauseMenuOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  @override
  State<_PauseMenuOverlay> createState() => _PauseMenuOverlayState();
}

class _PauseMenuOverlayState extends State<_PauseMenuOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _scaleAnim =
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic);
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameModalBackdrop(
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: GameModalPanel(
            maxWidth: 280,
            accentColor: GameModalColors.accentOrange,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const GameModalHeader(
                  icon: GameModalIconKind.paused,
                  color: GameModalColors.accentOrange,
                  title: 'PAUSED',
                  subtitle: 'Game is on hold',
                ),
                const SizedBox(height: 18),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 16),
                GameModalButton(
                  label: 'RESUME',
                  color: GameModalColors.accentOrange,
                  icon: GameModalIconKind.play,
                  onTap: widget.onResume,
                ),
                const SizedBox(height: 10),
                GameModalButton(
                  label: 'RESTART',
                  color: GameModalColors.accentOrange,
                  icon: GameModalIconKind.restart,
                  style: GameModalButtonStyle.secondary,
                  onTap: widget.onRestart,
                ),
                const SizedBox(height: 10),
                GameModalButton(
                  label: 'HOME',
                  color: GameModalColors.accentBlue,
                  icon: GameModalIconKind.home,
                  style: GameModalButtonStyle.secondary,
                  onTap: widget.onHome,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
