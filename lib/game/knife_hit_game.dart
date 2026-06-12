import 'dart:async';
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/board.dart';
import 'components/knife.dart';
import 'components/stuck_knife.dart';
import 'components/apple.dart';
import 'components/particle_effect.dart';
import 'components/board_break.dart';
import 'components/hud_overlay.dart';
import 'managers/score_manager.dart';
import 'managers/stage_manager.dart';
import 'managers/audio_manager.dart';
import 'utils/constants.dart';
import 'utils/collectible_type.dart';
import 'utils/angle_utils.dart';
import 'rules/collision_rules.dart';
import 'managers/feedback_controller.dart';
import 'managers/progress_manager.dart';
import 'managers/game_checkpoint.dart';
import 'managers/milestone_manager.dart';
import 'managers/session_goal_tracker.dart';
import 'logic/knife_throw_logic.dart';
import 'utils/game_session_cleanup.dart';

enum GameState { playing, paused, gameOver, stageComplete }

class KnifeHitGame extends FlameGame with TapCallbacks {
  final VoidCallback onGameOver;
  final VoidCallback onPause;

  late Board _board;
  late Knife _currentKnife;
  late ParticleEffect _particles;

  final List<StuckKnife> _stuckKnives = [];
  final List<Apple> _apples = [];
  final ScoreManager scoreManager = ScoreManager();
  final StageManager stageManager = StageManager();
  final AudioManager _audio = AudioManager();
  final FeedbackController _haptic = FeedbackController();
  final ProgressManager progressManager = ProgressManager();
  final MilestoneManager milestoneManager = MilestoneManager();
  final SessionGoalTracker goalTracker = SessionGoalTracker();
  final HudOverlay _hud = HudOverlay();
  double _animTime = 0;
  late final Vector2 _cameraCenter = Vector2.zero();

  GameState _state = GameState.playing;
  double _shakeTimer = 0;
  final Random _random = Random();
  final List<FloatingTextData> _floatingTexts = [];
  final List<double> _worldStuckAngleScratch = [];

  bool _knifeEverSpawned = false;
  /// True only when the knife sits at the bottom spawn point and may be launched.
  bool _knifeReadyAtSpawn = false;
  /// One buffered tap while the previous knife is still in the air.
  bool _bufferedThrow = false;
  /// Prevents double-processing board hits in the same frame.
  bool _resolvingKnifeHit = false;
  // True when the current knife is the last one in the stage
  bool _isLastKnife = false;
  double _prevKnifeDistToBoard = double.maxFinite; // overshoot detection
  // Apples marked collected during _checkCollisions — flushed at top of next update()
  final List<Apple> _pendingAppleRemovals = [];

  // Set in _triggerGameOver before saveIfBetter mutates in-memory high score.
  bool _gameOverIsNewHighScore = false;

  // Near-miss: board flashes amber briefly after a close-but-safe stick
  double _nearMissFlashTimer = 0;
  // Knife-on-knife crash: yellow flash on board
  double _crashFlashTimer = 0;

  // Golden ring: shown at stick position after a perfect throw
  GoldenRing? _goldenRing;

  // Session tracking for milestones and goals
  int _perfectThrowsThisRun = 0;
  bool _reachedBossThisRun = false;
  bool _spikeHitThisStage = false; // for clean-stage-clear goal

  // Selected knife skin ID (passed in from HomeScreen)
  final String skinId;

  final int startStage;
  final int startScore;

  KnifeHitGame({
    required this.onGameOver,
    required this.onPause,
    this.startStage = 1,
    this.startScore = 0,
    this.skinId = 'default',
  });

  // The first stage must not be built until the game has a real viewport size.
  // During onLoad() (and while its async loaders await) Flame may still report a
  // zero/stale `size`, so a board built there lands at the wrong center while the
  // thrown knives — which stick using the live size at throw time — appear to
  // float off the board. This only ever hit Stage 1, the one setup that runs from
  // onLoad; later stages are built from gameplay when size is already valid.
  bool _initialStageBuilt = false;
  bool _loadersDone = false;

  // The board center for the CURRENT stage, captured once in _setupStage from the
  // live viewport size. Everything anchored to the board for this stage — the
  // Board component, every stuck knife, every apple, and all collision math — must
  // read THIS value, never recompute `size.y * 0.38` on its own. The viewport size
  // can change mid-stage (the AdMob banner mounting/resizing the Flutter view is
  // the common trigger), and when it does, the Board component stays at its
  // original position while any freshly recomputed center drifts. That drift is
  // what made later-thrown Stage 1 knives stick on a different circle than the
  // board — the "knives floating off the board" bug. One captured center per stage
  // keeps board, knives, apples and hit-testing perfectly co-located.
  late Vector2 _boardCenter;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await Future.wait([
      scoreManager.loadHighScore(),
      progressManager.load(),
      milestoneManager.load(),
      _haptic.load(),
      _audio.init(),
    ]);
    _audio.startBgMusic();
    for (int i = 1; i < startStage; i++) {
      stageManager.nextStage();
    }
    scoreManager.addStartScore(startScore);
    _loadersDone = true;
    _maybeBuildInitialStage();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // A real viewport size has arrived. If onLoad already finished, this is what
    // unblocks the first stage build; if it fires before, the onLoad path will.
    _maybeBuildInitialStage();
  }

  /// Builds Stage 1 exactly once, and only after both the async loaders have run
  /// (high score etc.) and a real viewport size is known. Either onLoad finishing
  /// or onGameResize delivering a valid size can be the trigger — whichever is
  /// last. This prevents building the board against a zero/stale size, which made
  /// Stage 1's knives stick off the board.
  void _maybeBuildInitialStage() {
    if (_initialStageBuilt) return;
    if (!_loadersDone) return;
    if (size.x <= 0 || size.y <= 0) return;
    _initialStageBuilt = true;
    _setupStage();
  }

  void _setupStage() {
    // Remove all existing game components (skip orphans — e.g. cleared in _triggerStageComplete)
    for (final sk in _stuckKnives.toList()) {
      if (sk.isMounted) sk.removeFromParent();
    }
    for (final apple in _apples.toList()) {
      if (apple.isMounted) apple.removeFromParent();
    }
    _stuckKnives.clear();
    _apples.clear();
    _floatingTexts.clear();
    _pendingAppleRemovals.clear();
    _isLastKnife = false;
    _knifeReadyAtSpawn = false;
    _bufferedThrow = false;
    _resolvingKnifeHit = false;
    scoreManager.resetCombo(); // combo must not carry over into a new stage
    _spikeHitThisStage = false;
    if (stageManager.currentStageData.isBoss) _reachedBossThisRun = true;

    for (final c in children.whereType<Board>().toList()) { remove(c); }
    for (final c in children.whereType<BoardBreak>().toList()) { remove(c); }
    // Don't remove Knife — we reuse it. Just park it off-screen until _spawnKnife resets it.
    if (_knifeEverSpawned && _currentKnife.isMounted) {
      _parkThrowerKnife();
    }
    for (final c in children.whereType<ParticleEffect>().toList()) {
      c.clearAll();
      remove(c);
    }

    final stageData = stageManager.currentStageData;
    // Capture the board center ONCE for this stage. All knives/apples/collisions
    // below use _boardCenter so a mid-stage viewport resize can't desync them.
    _boardCenter = Vector2(size.x / 2, size.y * 0.38);
    final boardCenter = _boardCenter;

    _board = Board(
      position: boardCenter,
      rotationSpeed: stageData.rotationSpeed,
      isBoss: stageData.isBoss,
      reverseDirection: stageData.reverseDirection,
      directionChanges: stageData.directionChanges,
      theme: stageData.theme,
      bossSpikeAngles: stageData.bossSpikeAngles,
      hasSpeedBursts: stageData.hasSpeedBursts,
      hasHalfSpinRhythm: stageData.hasHalfSpinRhythm,
      advancedRhythm: stageData.advancedRhythm,
      halfSpinInterval: stageData.halfSpinInterval,
      halfSpinSpeedMultiplier: stageData.halfSpinSpeedMultiplier,
      dirChangeInterval: stageData.dirChangeInterval,
    );
    add(_board);

    // Resolve apple angles first so pre-stuck knife placement can avoid them.
    // Bonus stages: precomputed in stage data (gaps between spikes).
    // Normal stages: generated randomly on an empty board (no pre-stuck yet).
    const appleGap = 0.7;
    final appleAnglesToPlace = stageData.appleAngles.isNotEmpty
        ? stageData.appleAngles
        : _randomAppleAngles(
            count: stageData.applesCount,
            blockedAngles: const [],
            minGap: appleGap,
          );

    // Bonus stage: pre-stuck knives from bossSpikeAngles (replaces spikes).
    // Normal stages: randomly placed pre-stuck knives — avoid both each other
    // AND apple positions so knives and apples never overlap.
    if (stageData.isBoss && stageData.bossSpikeAngles.isNotEmpty) {
      for (final preAngle in stageData.bossSpikeAngles) {
        final preKnife = StuckKnife(
          boardAngle: preAngle,
          boardCenter: boardCenter,
          boardRadius: GameConstants.stuckKnifeRadius,
          isBossKnife: true,
          theme: stageData.theme,
        );
        preKnife.updatePosition(0);
        _stuckKnives.add(preKnife);
        add(preKnife);
      }
    } else if (!stageData.isBoss && stageData.preStuckKnivesCount > 0) {
      // All blocked angles: apples + knives already placed
      final blocked = List<double>.from(appleAnglesToPlace);
      for (int i = 0; i < stageData.preStuckKnivesCount; i++) {
        double preAngle = 0;
        bool placed = false;
        for (int attempt = 0; attempt < 100; attempt++) {
          preAngle = _random.nextDouble() * 2 * pi;
          if (!isAngleTooClose(preAngle, blocked, GameConstants.minAngleBetweenKnives)) {
            placed = true;
            break;
          }
        }
        if (!placed) break; // board too crowded — skip remaining pre-stuck knives

        blocked.add(preAngle);
        final preKnife = StuckKnife(
          boardAngle: preAngle,
          boardCenter: boardCenter,
          boardRadius: GameConstants.stuckKnifeRadius,
          isBossKnife: false,
          theme: stageData.theme,
        );
        preKnife.updatePosition(0);
        _stuckKnives.add(preKnife);
        add(preKnife);
      }
    }

    for (final appleAngle in appleAnglesToPlace) {
      final apple = Apple(
        boardAngle: appleAngle,
        boardCenter: boardCenter,
        boardRadius: GameConstants.boardRadius,
        type: CollectibleTypeX.random(_random),
      );
      apple.updatePosition(0);
      _apples.add(apple);
      add(apple);
    }

    _particles = ParticleEffect();
    add(_particles);

    _spawnKnife();
    _state = GameState.playing;
  }


  Vector2 get _knifeSpawnPosition => Vector2(size.x / 2, size.y * 0.82);

  void _placeKnifeAtSpawn() {
    final stageData = stageManager.currentStageData;
    final spawnPos = _knifeSpawnPosition;
    if (_knifeEverSpawned && _currentKnife.isMounted) {
      _currentKnife.resetToSpawn(
        spawnPos,
        isBossKnife: stageData.isBoss,
        theme: stageData.theme,
      );
    } else {
      _currentKnife = Knife(
        position: spawnPos,
        isBossKnife: stageData.isBoss,
        theme: stageData.theme,
      );
      add(_currentKnife);
      _knifeEverSpawned = true;
    }
    _knifeReadyAtSpawn = true;
    _prevKnifeDistToBoard = double.maxFinite;
    _isLastKnife = stageManager.isLastKnife;
  }

  void _parkThrowerKnife() {
    if (!_knifeEverSpawned) return;
    _currentKnife.position = Vector2(-9999, -9999);
    _currentKnife.state = KnifeState.idle;
    _currentKnife.velocity = 0;
    _knifeReadyAtSpawn = false;
  }

  void _spawnKnife() {
    if (_knifeEverSpawned && _currentKnife.state == KnifeState.flying) return;

    // Never load a knife the player can't throw. If all throws are used up but
    // the stage hasn't completed (e.g. a thrown knife was lost to a desync),
    // finish the stage instead of parking an un-throwable knife — which would
    // otherwise deadlock the game (knife visible at spawn, taps do nothing).
    if (stageManager.knivesRemaining <= 0) {
      if (_knifeEverSpawned && _currentKnife.isMounted) _parkThrowerKnife();
      if (_state == GameState.playing) _triggerStageComplete();
      return;
    }

    _placeKnifeAtSpawn();

    if (_bufferedThrow && stageManager.knivesRemaining > 0) {
      _throwKnife();
    }
  }

  // Pause tap target — must match HudBarLayout.pauseHitRect / _drawPauseButton.
  bool _isTapOnPauseButton(TapDownEvent event) {
    final tap = event.canvasPosition;
    return HudBarLayout.pauseHitRect(size.x).contains(Offset(tap.x, tap.y));
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Pause button always intercepted first, even mid-game
    if (_state == GameState.playing && _isTapOnPauseButton(event)) {
      pauseGame();
      return;
    }
    if (_state != GameState.playing) return;
    if (!_knifeEverSpawned) return;
    if (stageManager.knivesRemaining <= 0) return;

    if (_canThrowNow()) {
      _throwKnife();
    } else if (_shouldBufferTap()) {
      _bufferedThrow = true;
    }
  }

  bool _canThrowNow() => KnifeThrowLogic.canThrowNow(
        isPlaying: _state == GameState.playing,
        knivesRemaining: stageManager.knivesRemaining,
        knifeState: _currentKnife.state,
        knifeReadyAtSpawn: _knifeReadyAtSpawn,
      );

  bool _shouldBufferTap() => KnifeThrowLogic.shouldBufferTap(
        isPlaying: _state == GameState.playing,
        knivesRemaining: stageManager.knivesRemaining,
        knifeState: _currentKnife.state,
      );

  void _throwKnife() {
    if (stageManager.knivesRemaining <= 0) return;
    if (_currentKnife.state == KnifeState.flying) return;
    if (_currentKnife.state == KnifeState.collided) return;

    if (!_knifeReadyAtSpawn) {
      if (_currentKnife.state != KnifeState.idle ||
          !KnifeThrowLogic.isAtSpawn(_currentKnife.position, _knifeSpawnPosition)) {
        _placeKnifeAtSpawn();
      } else {
        _knifeReadyAtSpawn = true;
      }
    }
    if (!_knifeReadyAtSpawn) return;

    _bufferedThrow = false;
    _knifeReadyAtSpawn = false;
    stageManager.knifeThrown();
    _audio.playThrow();
    _currentKnife.throwKnife();
    _haptic.light();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // _board/_currentKnife are `late` and only exist after the first stage is
    // built (deferred until a valid size is known). Skip until then.
    if (!_initialStageBuilt) return;

    _animTime += dt;

    if (_nearMissFlashTimer > 0) _nearMissFlashTimer -= dt;
    if (_crashFlashTimer > 0) _crashFlashTimer -= dt;

    if (_goldenRing != null && _state == GameState.playing) {
      _goldenRing!.life -= dt;
      _goldenRing!.radius += 80 * dt;
      if (_goldenRing!.life <= 0) _goldenRing = null;
    }

    _cameraCenter.setValues(size.x / 2, size.y / 2);
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      final intensity = _crashFlashTimer > 0 ? 14.0 : 10.0;
      final dx = (_random.nextDouble() - 0.5) * intensity;
      final dy = (_random.nextDouble() - 0.5) * intensity;
      camera.viewfinder.position.setValues(
        _cameraCenter.x + dx,
        _cameraCenter.y + dy,
      );
    } else {
      camera.viewfinder.position.setFrom(_cameraCenter);
    }

    if (_state != GameState.playing) return;

    // Flush apples collected last frame — safe to remove from _apples now
    if (_pendingAppleRemovals.isNotEmpty) {
      for (final a in _pendingAppleRemovals) {
        _apples.remove(a);
      }
      _pendingAppleRemovals.clear();
    }

    // Floating texts
    for (final t in _floatingTexts) {
      t.y -= 60 * dt;
      t.life -= dt;
    }
    _floatingTexts.removeWhere((t) => t.life <= 0);

    // Sync stuck knives and apples to board rotation
    for (final sk in _stuckKnives) {
      sk.updatePosition(_board.angle);
    }
    for (final apple in _apples) {
      apple.updatePosition(_board.angle);
    }

    // Show last-knife warning when the last knife is waiting OR flying.
    // knivesRemaining==1 → knife sitting at spawn ready to throw.
    // knivesRemaining==0 + knife flying → last knife is in the air.
    final lastKnifeWaiting = stageManager.knivesRemaining == 1 && _knifeReadyAtSpawn;
    final lastKnifeFlying = stageManager.knivesRemaining == 0 &&
        _knifeEverSpawned &&
        _currentKnife.state == KnifeState.flying;
    _isLastKnife = _state == GameState.playing && (lastKnifeWaiting || lastKnifeFlying);

    if (_knifeEverSpawned && _currentKnife.state == KnifeState.flying) {
      _checkCollisions(dt);
    }
  }

  void _checkCollisions(double dt) {
    final boardCenter = _boardCenter;
    final knifePos = _currentKnife.position;
    final distToBoard = knifePos.distanceTo(boardCenter);

    // Overshoot guard: if knife flew past the board entirely (dist now growing
    // after having been closer) or escaped off the top of the screen, treat it
    // as a forced board hit so the game never gets stuck — but flag it as forced
    // so it does not award score or count toward stage completion.
    // Generous window: a fast knife can move ~20px/frame, so allow the guard to
    // fire any time the knife was within a comfortable band of the hit radius on
    // the previous frame. This prevents a knife ever slipping past unresolved
    // (which would consume a throw without sticking and could stall the stage).
    final overshotBoard = distToBoard > _prevKnifeDistToBoard &&
        _prevKnifeDistToBoard <= GameConstants.knifeBoardHitRadius + 40;
    final offScreen = knifePos.y < -50;
    if (overshotBoard || offScreen) {
      _onKnifeHitBoard(forced: true);
      return;
    }
    _prevKnifeDistToBoard = distToBoard;

    // Apple collection — mark collected immediately so no double-collect,
    // but defer removal from _apples until end of frame to avoid mid-frame
    // list mutation while update() may still be iterating _apples.
    for (final apple in _apples) {
      if (apple.collected) continue;
      if (knifePos.distanceTo(apple.position) < GameConstants.appleRadius + 16) {
        apple.collected = true;
        scoreManager.addAppleScore();
        _audio.playApple();
        _particles.spawnCollectibleParticles(apple.position.clone(), type: apple.type);
        _floatingTexts.add(FloatingTextData('+5', apple.position.x, apple.position.y));
        apple.removeFromParent();
        _pendingAppleRemovals.add(apple);
        // Session goal + lifetime progress tracking
        goalTracker.onAppleCollected();
        progressManager.addApples(1);
      }
    }

    // Knife tip reaches the board surface at the exact stuck-knife placement radius
    if (distToBoard <= GameConstants.knifeBoardHitRadius) {
      _onKnifeHitBoard();
    }
  }

  void _onKnifeHitBoard({bool forced = false}) {
    if (_resolvingKnifeHit) return;
    if (_currentKnife.state != KnifeState.flying) return;
    _resolvingKnifeHit = true;

    final boardCenter = _boardCenter;
    final knifeAngle = atan2(
      _currentKnife.position.x - boardCenter.x,
      boardCenter.y - _currentKnife.position.y,
    );

    // Check collision with existing stuck knives (reuse scratch list — no per-hit alloc).
    _worldStuckAngleScratch.clear();
    for (final sk in _stuckKnives) {
      _worldStuckAngleScratch.add(sk.boardAngle + _board.angle);
    }
    if (knifeCollidesWithStuck(
      knifeAngle,
      _worldStuckAngleScratch,
      difficultyMultiplier: 0.88,
    )) {
      _spikeHitThisStage = true;
      _resolvingKnifeHit = false;
      _board.triggerCrashFlash();
      _crashFlashTimer = 0.6;
      _particles.spawnCrashParticles(
        boardCenter,
        theme: stageManager.currentStageData.theme,
      );
      _currentKnife.fallBack();
      _triggerGameOver();
      return;
    }

    // Near-miss detection: within 0.08 rad beyond the safe threshold
    bool wasNearMiss = false;
    if (_stuckKnives.isNotEmpty) {
      final minAngle = effectiveMinAngle(_stuckKnives.length);
      for (final worldAngle in _worldStuckAngleScratch) {
        final diff = shortestAngleDiff(knifeAngle, worldAngle);
        if (diff >= minAngle && diff < minAngle + 0.08) {
          wasNearMiss = true;
          break;
        }
      }
    }

    // Perfect throw detection
    final stuckRelAngles = _stuckKnives.map((sk) => sk.boardAngle).toList();
    final isPerfect = isPerfectThrow(knifeAngle, stuckRelAngles, _board.angle);

    // Forced hit (overshoot): reset combo, show MISSED, don't stick the knife or count the throw.
    if (forced) {
      scoreManager.resetCombo();
      stageManager.rollbackThrow();
      _parkThrowerKnife();
      _resolvingKnifeHit = false;
      _spawnKnife();
      return;
    }

    // Knife sticks to board
    _audio.playHit();
    final stuckPos = _currentKnife.position.clone();

    _parkThrowerKnife();

    final relativeAngle = knifeAngle - _board.angle;
    final stuckKnife = StuckKnife(
      boardAngle: relativeAngle,
      boardCenter: boardCenter,
      boardRadius: GameConstants.stuckKnifeRadius,
      isBossKnife: stageManager.currentStageData.isBoss,
      theme: stageManager.currentStageData.theme,
    );
    stuckKnife.updatePosition(_board.angle);
    _stuckKnives.add(stuckKnife);
    add(stuckKnife);

    stageManager.knifeStuck();

    scoreManager.addKnifeScore();
    _haptic.light();

    if (isPerfect) {
      _perfectThrowsThisRun++;
      _goldenRing = GoldenRing(stuckPos.x, stuckPos.y);
      goalTracker.onPerfectThrow();
    }

    if (wasNearMiss) {
      _nearMissFlashTimer = 0.25;
      _haptic.medium();
    }

    // Bonus-stage escalation: once threshold is reached, trigger phase 2.
    final threshold = stageManager.currentStageData.bossPhaseThreshold;
    if (threshold > 0 && stageManager.knivesStuck >= threshold) {
      _board.triggerBossPhase();
    }

    _particles.spawnWoodParticles(stuckPos, boardCenter: boardCenter);

    _resolvingKnifeHit = false;

    if (stageManager.isStageComplete) {
      _triggerStageComplete();
    } else {
      _spawnKnife();
    }
  }

  void _triggerGameOver() {
    _state = GameState.gameOver;
    // Stop the engine as soon as the player dies — the game-over UI is Flutter
    // overlay. Leaving Flame running underneath wasted GPU on every retry cycle.
    pauseEngine();
    _currentKnife.state = KnifeState.collided;
    _shakeTimer = 0.5;
    _bufferedThrow = false;
    _knifeReadyAtSpawn = false;
    _resolvingKnifeHit = false;
    scoreManager.resetCombo();
    _haptic.heavy();
    _audio.playGameOver();
    // Must compare before checkpoint updates in-memory high score.
    _gameOverIsNewHighScore =
        scoreManager.score > 0 && scoreManager.score > scoreManager.highScore;
    unawaited(_persistCheckpoint());
    // Evaluate milestones asynchronously — result shown by GameScreen after navigation
    milestoneManager.evaluate(
      lifetimeApples: progressManager.lifetimeApples,
      perfectThrowsThisRun: _perfectThrowsThisRun,
      currentStage: stageManager.currentStage,
      comboStreak: scoreManager.comboStreak,
      reachedBoss: _reachedBossThisRun,
    );
    Future.delayed(const Duration(milliseconds: 1000), onGameOver);
  }

  void _triggerStageComplete() {
    _state = GameState.stageComplete;
    _bufferedThrow = false;
    _knifeReadyAtSpawn = false;
    _resolvingKnifeHit = false;
    unawaited(_persistCheckpoint());
    _audio.playStageComplete();
    // Clean-stage-clear goal: no spike hit this stage
    if (!_spikeHitThisStage) {
      goalTracker.onCleanStageClear();
    }

    // Collect knife angles before removing
    final knifeAngles = _stuckKnives.map((sk) => sk.boardAngle + _board.angle).toList();

    // Hide board, knives, apples (clear lists so _setupStage won't double-remove)
    _board.removeFromParent();
    for (final sk in _stuckKnives) {
      sk.removeFromParent();
    }
    _stuckKnives.clear();
    for (final apple in _apples) {
      apple.removeFromParent();
    }
    _apples.clear();
    if (_knifeEverSpawned && _currentKnife.isMounted) {
      _parkThrowerKnife();
    }

    final boardCenter = _boardCenter;
    _audio.playBoardBreak();
    final stageTheme = stageManager.currentStageData.theme;
    _crashFlashTimer = 0.5;
    _particles.spawnCrashParticles(boardCenter, theme: stageTheme);

    final boardBreak = BoardBreak(
      boardCenter: boardCenter,
      isBoss: stageManager.currentStageData.isBoss,
      theme: stageTheme,
      onComplete: _onBoardBreakFinished,
      stuckKnifeAngles: knifeAngles,
    );
    add(boardBreak);
  }

  void _onBoardBreakFinished() {
    if (_state != GameState.stageComplete) return;
    // Defer so we don't mutate the component tree during BoardBreak.update().
    Future.microtask(_advanceToNextStage);
  }

  void _advanceToNextStage() {
    if (_state != GameState.stageComplete) return;

    for (final c in children.whereType<BoardBreak>().toList()) {
      if (c.isMounted) c.removeFromParent();
    }

    stageManager.nextStage();
    _setupStage();

  }

  bool get isPlaying => _state == GameState.playing;
  bool get isEnginePaused => _state == GameState.paused;

  void pauseGame() {
    if (_state == GameState.gameOver || _state == GameState.stageComplete) {
      return;
    }
    if (_state == GameState.playing) {
      _state = GameState.paused;
      unawaited(_persistCheckpoint());
      _audio.pauseBgMusic();
      pauseEngine();
      onPause();
      return;
    }
    // Already paused (e.g. app switch) — keep engine/audio stopped.
    if (_state == GameState.paused) {
      _audio.pauseBgMusic();
      if (!paused) pauseEngine();
    }
  }

  void resumeGame() {
    if (_state != GameState.paused) return;
    _state = GameState.playing;
    resumeEngine();
    _audio.resumeBgMusic();
  }

  /// Batched disk save — never blocks the throw loop; runs at checkpoints only.
  Future<void> _persistCheckpoint() => GameCheckpoint.persist(
        progress: progressManager,
        highScore: scoreManager.highScoreManager,
        score: scoreManager.score,
        stage: stageManager.currentStage,
      );

  @override
  void onRemove() {
    unawaited(_persistCheckpoint());
    progressManager.dispose();
    _hud.dispose();
    _audio.dispose();
    GameSessionCleanup.afterSession();
    super.onRemove();
  }

  void nextStage() {
    stageManager.nextStage();
    _setupStage();
  }

  /// Full reset to stage 1 on the same game instance — no new GPU surface.
  void restartRun() {
    _gameOverIsNewHighScore = false;
    _perfectThrowsThisRun = 0;
    _reachedBossThisRun = false;
    _spikeHitThisStage = false;
    _goldenRing = null;
    _shakeTimer = 0;
    _nearMissFlashTimer = 0;
    _crashFlashTimer = 0;
    _floatingTexts.clear();
    _pendingAppleRemovals.clear();
    _bufferedThrow = false;
    _resolvingKnifeHit = false;
    _isLastKnife = false;
    stageManager.reset();
    scoreManager.reset();
    _hud.resetForNewRun();
    _setupStage();
  }

  void restartGame() => restartRun();

  /// Spend [reviveCost] lifetime apples to replay the current stage with score kept.
  /// Returns false if the player cannot afford it.
  static const int reviveCost = 5;

  Future<bool> continueRun() async {
    if (progressManager.lifetimeApples < reviveCost) return false;
    await progressManager.spendApples(reviveCost);
    _revive();
    return true;
  }

  /// Revive for free after the player watches a rewarded ad. Same in-place
  /// continue as [continueRun] but with no apple cost.
  void reviveFromAd() => _revive();

  /// Shared revive: resume the EXACT board the player died on — same wheel and
  /// its current rotation, same stuck knives, same apples, and the same number
  /// of knives remaining. We do NOT rebuild the stage; we only clear the death
  /// state and hand the player a fresh throwable knife where the fatal one was.
  void _revive() {
    _gameOverIsNewHighScore = false;
    // Keep _perfectThrowsThisRun — the player earned those throws before dying,
    // wiping them would make the Sharpshooter milestone impossible on revival.
    // _reachedBossThisRun / _spikeHitThisStage describe the in-progress stage,
    // so they must NOT be reset here (we're continuing the same stage).

    // Clear the death shake (frozen while paused on game over) and recenter the
    // camera so the revived board doesn't jitter for half a second.
    _shakeTimer = 0;
    _cameraCenter.setValues(size.x / 2, size.y / 2);
    camera.viewfinder.position.setFrom(_cameraCenter);

    // The fatal knife was thrown (knivesThrown was incremented) but never stuck.
    // Give that throw back so the player resumes with the same count the HUD
    // showed before the deadly throw — e.g. "2 left" stays "2 left".
    stageManager.rollbackThrow();

    // Remove the dead (collided) thrower knife and clear the flags the throw
    // path checks, then drop a fresh idle knife at the spawn point. The board,
    // stuck knives and apples are left untouched — nothing is rebuilt.
    _resolvingKnifeHit = false;
    _bufferedThrow = false;
    if (_knifeEverSpawned && _currentKnife.isMounted) {
      _parkThrowerKnife();
    }

    _state = GameState.playing;
    _spawnKnife();
  }

  /// True when the last game over beat the previous best score (not a tie).
  bool get gameOverIsNewHighScore => _gameOverIsNewHighScore;

  /// Milestones unlocked during the last run — consumed by GameOverScreen.
  List<dynamic> get pendingMilestoneToasts => milestoneManager.pendingToasts;

  /// Session goal progress — used by HUD and end screens.
  List<dynamic> get sessionGoals => goalTracker.goals;

  List<double> _randomAppleAngles({
    required int count,
    required List<double> blockedAngles,
    required double minGap,
  }) {
    final placed = <double>[];
    final blocked = List<double>.from(blockedAngles);
    for (int i = 0; i < count; i++) {
      for (int attempt = 0; attempt < 200; attempt++) {
        final candidate = _random.nextDouble() * 2 * pi;
        if (!isAngleTooClose(candidate, blocked, minGap) &&
            !isAngleTooClose(candidate, placed, minGap)) {
          placed.add(candidate);
          blocked.add(candidate);
          break;
        }
      }
    }
    return placed;
  }

  @override
  void render(Canvas canvas) {
    _hud.render(
      canvas,
      Size(size.x, size.y),
      HudData(
        score: scoreManager.score,
        apples: scoreManager.apples,
        stage: stageManager.currentStage,
        isBoss: stageManager.currentStageData.isBoss,
        theme: stageManager.currentStageData.theme,
        knivesLeft: stageManager.knivesRemaining,
        totalKnives: stageManager.currentStageData.knivesCount,
        isLastKnife: _isLastKnife,
        nearMissFlashTimer: _nearMissFlashTimer,
        crashFlashTimer: _crashFlashTimer,
        goldenRing: _goldenRing?.data,
        floatingTexts: _floatingTexts,
        animTime: _animTime,
        knifeReady: _knifeReadyAtSpawn && _knifeEverSpawned,
        boardCenterY: _initialStageBuilt ? _boardCenter.y : size.y * 0.38,
        knifeSpawnY: size.y * 0.82,
      ),
    );
    super.render(canvas);
  }
}
